#!/usr/bin/env bash

# VERSION=0.0.8+3

#-------------------------------------------------------#
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Set Env for Build
# FUNCS:
#  --> setup_env "/path/to/sbuild"
#  --> check_sane_env
#  --> gen_json_from_sbuild
#  --> build_progs
#  --> generate_json
#  --> upload_to_ghcr
#  --> cleanup_env
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/functions.sh
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/functions.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##Sets Dirs & Vars
setup_env()
{
 INPUT_SBUILD="${1:-$(echo "$@" | tr -d '[:space:]')}"
 INPUT_SBUILD_PATH="$(realpath ${INPUT_SBUILD})" ; export INPUT_SBUILD="${INPUT_SBUILD_PATH}"
 if [[ ! -s "${INPUT_SBUILD}" || $(stat -c%s "${INPUT_SBUILD}") -le 10 ]]; then
   echo -e "\n[✗] FATAL: SBUILD (${INPUT_SBUILD}) seems Broken\n"
   export CONTINUE_SBUILD="NO"
  return 1 || exit 1 
 fi
 BUILD_DIR="$(mktemp -d --tmpdir=${SYSTMP}/pkgforge XXXXXXX_$(basename ${INPUT_SBUILD}))"
 SBUILD_OUTDIR="${BUILD_DIR}/SBUILD_OUTDIR"
 SBUILD_TMPDIR="${SBUILD_OUTDIR}/SBUILD_TMPDIR"
 mkdir -pv "${SBUILD_TMPDIR}"
 export BUILD_DIR INPUT_SBUILD SBUILD_OUTDIR SBUILD_TMPDIR
 echo -e "\n[+] Building ${INPUT_SBUILD} --> ${SBUILD_OUTDIR}"
}
export -f setup_env
#-------------------------------------------------------#

#-------------------------------------------------------#
##Checks if needed vars,files & dirs exist
check_sane_env()
{
  unset CONTINUE_SBUILD
  if [[ -z "${INPUT_SBUILD//[[:space:]]/}" ]] || \
   [[ ! -d "${SBUILD_TMPDIR}" ]]; then
   echo -e "\n[✗] FATAL: CAN NOT CONTINUE\n"
   export CONTINUE_SBUILD="NO"
   return 1 || exit 1
  else
   export CONTINUE_SBUILD="YES"
  fi
}
export -f check_sane_env
#-------------------------------------------------------#

#-------------------------------------------------------#
##Gen Json (SBUILD)
gen_json_from_sbuild()
{
 #Env
  check_sane_env
  if [[ "${CONTINUE_SBUILD}" == "YES" ]]; then
   TMPXVER="${BUILD_DIR}/SBUILD_VER.sh"
   TMPXRUN="${BUILD_DIR}/SBUILD_RUN.sh"
   TMPJSON="${BUILD_DIR}/SBUILD_RAW.json"
   export TMPJSON TMPXVER TMPXRUN
  #Gen
   yq eval "." "${INPUT_SBUILD}" --output-format "json" | jq 'del(.x_exec)' > "${TMPJSON}"
   if jq --exit-status . "${TMPJSON}" >/dev/null 2>&1; then
    ##Check & Set
     if [[ "$(yq '._disabled' "${INPUT_SBUILD}")" == "true" ]]; then
       echo -e "\n[✗] FATAL: SBUILD (${INPUT_SBUILD}) is Disabled ('_disabled: true')\n"
       exit 1
     else
       pkg="$(jq -r '"\(.pkg | select(. != "null") // "")"' "${TMPJSON}" | sed 's/\.$//' | tr -d '[:space:]')" ; export PKG="${pkg}"
       pkg_id="$(jq -r '"\(.pkg_id | select(. != "null") // "")"' "${TMPJSON}" | sed 's/\.$//' | tr -d '[:space:]')" ; export PKG_ID="${pkg_id}"
       pkg_type="$(jq -r '"\(.pkg_type | select(. != "null") // "")"' "${TMPJSON}" | sed 's/\.$//' | tr -d '[:space:]')" ; export PKG_TYPE="${pkg_type}"
       SBUILD_PKG="$(echo "${pkg}.${pkg_type}" | sed 's/\.$//' | tr -d '[:space:]')"
       export pkg pkg_id pkg_type SBUILD_PKG
       if [ "$(echo "${SBUILD_PKG}" | tr -d '[:space:]' | wc -c | tr -cd '0-9')" -le 1 ]; then
         echo -e "\n[✗] FATAL: ${SBUILD_PKG} ('.pkg+.pkg_type') is less than 1 Character\n"
         export CONTINUE_SBUILD="NO"
         return 1 || exit 1
       fi
     fi
     #Shell
      SBUILD_SHELL="$(yq '.x_exec.shell' "${INPUT_SBUILD}")"
     #Version 
      if yq eval '.pkgver | length > 0' "${INPUT_SBUILD}" | grep -q true; then
       SBUILD_PKGVER="$(yq eval '.pkgver' "${INPUT_SBUILD}" | tr -d '[:space:]')" ; export SBUILD_PKGVER
       echo "${SBUILD_PKGVER}" > "${SBUILD_OUTDIR}/${SBUILD_PKG}.version"
       echo "[+] Version: ${SBUILD_PKGVER} [${SBUILD_OUTDIR}/${SBUILD_PKG}.version]"
       export CONTINUE_SBUILD="YES"
      else
       echo -e '#!/usr/bin/env '"${SBUILD_SHELL}"'\n\n' > "${TMPXVER}"
       if [[ "${DEBUG_BUILD}" != "NO" ]]; then
         echo 'set -x' >> "${TMPXVER}"
       fi
       yq '.x_exec.pkgver' "${INPUT_SBUILD}" >> "${TMPXVER}"
       if [[ -s "${TMPXVER}" && $(stat -c%s "${TMPXVER}") -gt 10 ]]; then
         chmod +x "${TMPXVER}"
         {
          timeout -k 10s 5s "${TMPXVER}"
         } > "${SBUILD_OUTDIR}/${SBUILD_PKG}.version" 2>&1
         if [[ ! -s "${SBUILD_OUTDIR}/${SBUILD_PKG}.version" || $(stat -c%s "${SBUILD_OUTDIR}/${SBUILD_PKG}.version") -le 3 ]]; then
           echo -e "\n[✗] FATAL: Failed to Fetch Version ('x_exec.pkgver')\n"
           cat "${TMPXVER}" ; echo ; cat "${SBUILD_OUTDIR}/${SBUILD_PKG}.version"
           export CONTINUE_SBUILD="NO"
           return 1 || exit 1
         else
           SBUILD_PKGVER="$(cat "${SBUILD_OUTDIR}/${SBUILD_PKG}.version" | tr -d '[:space:]')" ; export SBUILD_PKGVER
           echo "[+] Version: ${SBUILD_PKGVER} [${SBUILD_OUTDIR}/${SBUILD_PKG}.version]"
           export CONTINUE_SBUILD="YES"
         fi
       else
         echo -e "\n[✗] FATAL: Failed to Extract ('x_exec.pkgver')\n"
         cat "${INPUT_SBUILD}" ; echo ; cat "${TMPXVER}"
         export CONTINUE_SBUILD="NO"
         return 1 || exit 1
       fi
      fi
     #Run      
      echo -e '#!/usr/bin/env '"${SBUILD_SHELL}"'\n\n' > "${TMPXRUN}"
      yq '.x_exec.run' "${INPUT_SBUILD}" >> "${TMPXRUN}"
      if [[ -s "${TMPXRUN}" && $(stat -c%s "${TMPXRUN}") -gt 10 ]]; then
       chmod +x "${TMPXRUN}"
      else
        echo -e "\n[✗] FATAL: Failed to Extract ('x_exec.run')\n"
        cat "${INPUT_SBUILD}" ; echo ; cat "${TMPXRUN}"
        export CONTINUE_SBUILD="NO"
        return 1 || exit 1
      fi
   else
    echo -e "\n[✗] FATAL: Could NOT parse ${INPUT_SBUILD} ==> ${TMPJSON}\n"
    return 1 || exit 1
    export CONTINUE_SBUILD="NO"
   fi
  fi
}
export -f gen_json_from_sbuild
#-------------------------------------------------------#

#-------------------------------------------------------#
##Build Progs
build_progs()
{
if [[ "${CONTINUE_SBUILD}" == "YES" ]]; then
 if jq --exit-status . "${TMPJSON}" >/dev/null 2>&1; then
 #Get Progs
  if jq -e '.provides // empty' "${TMPJSON}" > /dev/null; then
   SBUILD_PKGS=()
   SBUILD_PKGS=($(jq -r '.provides[]' "${TMPJSON}"))
   SBUILD_PKGS+=("${PKG}")
   SBUILD_PKGS=($(printf "%s\n" "${SBUILD_PKGS[@]}" | sort | uniq)) ; export SBUILD_PKGS
   echo -e "[+] Progs: ${SBUILD_PKGS[*]}"
  else
   SBUILD_PKGS=("${PKG}") ; export SBUILD_PKGS
   echo -e "[+] Progs: ${SBUILD_PKGS[*]}"
  fi
 #Run
   check_sane_env
   pushd "${SBUILD_OUTDIR}" >/dev/null 2>&1
     timeout -k 60m 5m "${TMPXRUN}"
     if [ -d "${SBUILD_OUTDIR}" ] && [ $(du -s "${SBUILD_OUTDIR}" | cut -f1) -gt 100 ]; then
      #Perms
       sudo chown -R "$(whoami):$(whoami)" "${SBUILD_OUTDIR}"
       find "${SBUILD_OUTDIR}" -type f -exec sudo chmod +xwr "{}" \;
      #Strip
       find "${SBUILD_OUTDIR}" -maxdepth 1 -type f -exec file -i "{}" \; |\
       grep "application/.*executable" | cut -d":" -f1 | xargs realpath |\
       xargs -I "{}" bash -c '
         base=$(basename "{}")
         if [[ "$base" != *.no_strip ]]; then 
             objcopy --remove-section=".comment" --remove-section=".note.*" "{}"
             strip --strip-debug --strip-dwo --strip-unneeded "{}"
         fi
       '
      #Sanity
       find "${SBUILD_OUTDIR}" -type f -exec touch "{}" \;
       find "${SBUILD_OUTDIR}" -maxdepth 1 -type f -print | xargs -I "{}" sh -c 'printf "\nFile: {}\n  Type: $(file -b {})\n  B3sum: $(b3sum {} | cut -d" " -f1)\n  SHA256sum: $(sha256sum {} | cut -d" " -f1)\n  Size: $(du -sh {} | cut -f1)\n"'
      #End
       export SBUILD_SUCCESSFUL="YES"
       echo -e "[✓] SuccessFully Built ${SBUILD_PKG} using ${INPUT_SBUILD} [${SBUILD_SCRIPT}]"
     else
       echo -e "\n[✗] FATAL: Could NOT Build ${SBUILD_PKG} using ${INPUT_SBUILD} [${SBUILD_SCRIPT}]\n"
       ls "${SBUILD_OUTDIR}" -lah
       return 1 || exit 1
       export SBUILD_SUCCESSFUL="NO"
     fi
   popd >/dev/null 2>&1
 else
   echo -e "\n[✗] FATAL: Could NOT parse ${INPUT_SBUILD} ==> ${TMPJSON}\n"
   return 1 || exit 1
   export SBUILD_SUCCESSFUL="NO"
 fi
fi
}
export -f build_progs
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Json
generate_json()
{
if [[ "${SBUILD_SUCCESSFUL}" == "YES" ]]; then
 #Generate Json for each $progs
 for PROG in "${SBUILD_PKGS[@]}"; do
  if [[ -s "${SBUILD_OUTDIR}/${PROG}" && $(stat -c%s "${SBUILD_OUTDIR}/${PROG}") -gt 10 ]]; then
   export PROG SBUILD_PKGVER
   GHCR_PKG="$(realpath ${SBUILD_OUTDIR}/${PROG})"
   PKG_DATE="$(date --utc +%Y-%m-%dT%H:%M:%S)Z"
   PKG_DESCRIPTION="$(jq -r 'if (.description | has(env.PROG) and .description[env.PROG] != "") then .description[env.PROG] else (.description // "") end' ${TMPJSON})"
   PKG_BSUM="$(b3sum "${GHCR_PKG}" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]')"
   PKG_SHASUM="$(sha256sum "${GHCR_PKG}" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]')"
   PKG_SIZE_RAW="$(stat --format="%s" "${GHCR_PKG}" | tr -d '[:space:]')"
   #PKG_SIZE="$(echo "${PKG_SIZE_RAW}" | awk '{byte=$1; if (byte<1024) printf "%.2f B\n", byte; else if (byte<1024**2) printf "%.2f KB\n", byte/1024; else if (byte<1024**3) printf "%.2f MB\n", byte/(1024**2); else printf "%.2f GB\n", byte/(1024**3)}')"
   PKG_SIZE="$(du -sh "${GHCR_PKG}" | awk '{unit=substr($1,length($1)); sub(/[BKMGT]$/,"",$1); print $1 " " unit "B"}')"
   SBUILD_PKGVER="$(cat "${SBUILD_OUTDIR}/${SBUILD_PKG}.version" | tr -d '[:space:]')" ; export SBUILD_PKGVER
   export GHCR_PKG PROG PKG_BSUM PKG_DATE PKG_SIZE PKG_SIZE_RAW PKG_SHASUM SBUILD_PKGVER
   echo "[+] Generating Json for ${SBUILD_PKG} (PROG=${PROG}) ==> ${SBUILD_OUTDIR}/${PROG}.json"
   cat "${TMPJSON}" | jq -r \
   '{
    "_disabled": (._disabled | tostring // "unknown"),
    "host": (env.HOST_TRIPLET // ""),
    "pkg": (env.PROG // .pkg // ""),
    "pkg_family": (env.PKG_FAMILY // ""),
    "pkg_id": (.pkg_id // ""),
    "pkg_name": (env.PROG // .pkg // ""),
    "app_id": (.app_id // ""),
    "appstream": (.appstream // ""),
    "category": (.category // []),
    "description": (env.PKG_DESCRIPTION // (.description[env.PROG] // .description // "")),
    "desktop": (.desktop // ""),
    "homepage": (.homepage // []),
    "icon": (.icon // ""),
    "license": (.license // []),
    "maintainer": (.maintainer // []),
    "note": (
      if (.note | length > 0) then 
        [.note[] | select(. == "" or (. | ascii_downcase | contains("ci only") | not))]
      else 
        []
      end
    ),
    "provides": (
      if (.provides | length > 0) then 
        .provides 
      else 
        [env.PKG // .pkg // ""]
      end
    ),
    "repology": (.repology // []),
    "screenshots": (.screenshot // []),
    "src_url": (.src_url // []),
    "tag": (.tag // []),
    "version": (env.SBUILD_PKGVER // ""),
    "bsum": (env.PKG_BSUM // ""),
    "build_date": (env.PKG_DATE // ""),
    "build_script": (env.SBUILD_SCRIPT // ""),
    "download_url": (env.DOWNLOAD_URL // ""),
    "shasum": (env.PKG_SHASUM // ""),
    "size": (env.PKG_SIZE // ""),
    "size_raw": (env.PKG_SIZE_RAW // ""),
    "rank": (env.RANK // "")
  }' | jq . > "${SBUILD_OUTDIR}/${PROG}.json"
  fi
 done
fi
}
export -f generate_json
#-------------------------------------------------------#

#-------------------------------------------------------#
##Upload Func
upload_to_ghcr()
{
local PROG="$1"
if [[ "${SBUILD_SUCCESSFUL}" == "YES" ]]; then
 #Clear ENV
  unset ARCH BUILD_LOG BUILD_SCRIPT DOWNLOAD_URL GHCR_PKG GHCR_PKGVER PKG_BSUM PKG_CATEGORY PKG_DATE PKG_DESCRIPTION PKG_FAMILY PKG_HOMEPAGE PKG_ICON PKG_NAME PKG_NOTE PKG_ORIG PKG_REPOLOGY PKG_SCREENSHOT PKG_SHASUM PKG_SIZE PKG_SIZE_RAW PKG_SRCURL PKG_TAG PKG_VERSION REPO VERSION TMPJSON
 #Parse
  if jq --exit-status . "${SBUILD_OUTDIR}/${PROG}.json" >/dev/null 2>&1; then
   DOWNLOAD_URL="$(jq -r '.download_url' "${SBUILD_OUTDIR}/${PROG}.json" | tr -d '[:space:]')"
  #Download
   if [[ -n "${DOWNLOAD_URL}" ]]; then
     if echo "${DOWNLOAD_URL}" | grep -q -m 1 'aarch64'; then
       ARCH="aarch64"
     elif echo "${DOWNLOAD_URL}" | grep -q -m 1 'x86_64'; then
       ARCH="x86_64"
     fi
     if echo "${DOWNLOAD_URL}" | grep -q -m 1 'bin.pkgforge.dev' || 
       echo "${DOWNLOAD_URL}" | grep -q -m 1 'huggingface.co/datasets/pkgforge/bincache'; then
       REPO="bincache"
     elif echo "${DOWNLOAD_URL}" | grep -q -m 1 'pkgcache.pkgforge.dev' || 
       echo "${DOWNLOAD_URL}" | grep -q -m 1 'huggingface.co/datasets/pkgforge/pkgcache'; then
       REPO="pkgcache"
     fi
     PKG_BSUM="$(jq -r '.bsum' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_CATEGORY="$(jq -r 'if .category | type == "array" then .category[0] else .category end' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     [[ "${PKG_CATEGORY}" == "null" ]] && PKG_CATEGORY=""
     PKG_DATE="$(jq -r '.build_date' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_DATE="${PKG_DATE:-$(date --utc +%Y-%m-%dT%H:%M:%S)}Z"
     PKG_DESCRIPTION="$(jq -r '.description' "${TMPDIR}/${TMPJSON}")"
     PKG_FAMILY="$(jq -r '.pkg_family' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_HOMEPAGE="$(jq -r 'if .homepage | type == "array" then .homepage[0] else .homepage end' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     [[ "${PKG_HOMEPAGE}" == "null" ]] && PKG_HOMEPAGE=""
     PKG_ICON="$(jq -r 'if .icon | type == "array" then .icon[0] else .icon end' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     [[ "${PKG_ICON}" == "null" ]] && PKG_ICON=""
     PKG_NAME="$(jq -r '.pkg_name' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_NOTE="$(jq -r 'if .note | type == "array" then .note[0] else .note end' "${TMPDIR}/${TMPJSON}")"
     [[ "${PKG_NOTE}" == "null" ]] && PKG_NOTE=""
     PKG_ORIG="$(jq -r '.pkg' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_REPOLOGY="$(jq -r 'if .repology | type == "array" then .repology[0] else .repology end' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     [[ "${PKG_REPOLOGY}" == "null" ]] && PKG_REPOLOGY=""
     PKG_SCREENSHOT="$(jq -r 'if .screenshots | type == "array" then .screenshots[0] else .screenshots end' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     [[ "${PKG_SCREENSHOT}" == "null" ]] && PKG_SCREENSHOT=""
     PKG_SHASUM="$(jq -r '.shasum' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_SRCURL="$(jq -r 'if .src_url | type == "array" then .src_url[0] else .src_url end' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     [[ "${PKG_SRCURL}" == "null" ]] && PKG_SRCURL=""
     if [[ -n "${PKG_SRCURL}" ]]; then
       [ -z "${PKG_HOMEPAGE}" ] && PKG_HOMEPAGE="${PKG_SRCURL}"
     elif [[ -n "${PKG_HOMEPAGE}" ]]; then
       PKG_SRCURL="${PKG_HOMEPAGE}"
     fi
     PKG_TAG="$(jq -r 'if .tag | type == "array" then .tag[0] else .tag end' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     [[ "${PKG_TAG}" == "null" ]] && PKG_TAG=""
     PKG_VERSION="$(jq -r '.version' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     if [[ "${PKG_VERSION}" == "latest" ]]; then
       if [[ -n "${PKG_DATE}" ]]; then
         PKG_VERSION="$(echo ${PKG_DATE} | tr -cd '0-9')"
       else
         PKG_VERSION="$(date --utc +'%y%m%dT%H%M%S')"
       fi
     fi
     BUILD_SCRIPT="$(jq -r '.build_script' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     BUILD_LOG="$(jq -r '.build_log' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     GHCR_PKG="$(realpath .)/${PKG_NAME}"
     curl -qfsSL "${DOWNLOAD_URL}" -o "${GHCR_PKG}"
   else
     echo -e "\n[-] No \$DOWNLOAD_URL was parsed"
     return
   fi
  #Upload
   if [[ -s "${GHCR_PKG}" && $(stat -c%s "${GHCR_PKG}") -gt 100 ]]; then
     PKG_SIZE_RAW="$(stat --format="%s" "${GHCR_PKG}" | tr -d '[:space:]')"
     #PKG_SIZE="$(echo "${PKG_SIZE_RAW}" | awk '{byte=$1; if (byte<1024) printf "%.2f B\n", byte; else if (byte<1024**2) printf "%.2f KB\n", byte/1024; else if (byte<1024**3) printf "%.2f MB\n", byte/(1024**2); else printf "%.2f GB\n", byte/(1024**3)}')"
     PKG_SIZE="$(du -sh "${GHCR_PKG}" | awk '{unit=substr($1,length($1)); sub(/[BKMGT]$/,"",$1); print $1 " " unit "B"}')"
     [ -z "${PKG_BSUM}" ] && PKG_BSUM="$(b3sum "${GHCR_PKG}" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]')"
     [ -z "${PKG_SHASUM}" ] && PKG_SHASUM="$(sha256sum "${GHCR_PKG}" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]')"
     GHCR_PKGVER="${PKG_VERSION:-$(date --utc +"%y%m%dT%H%M%S")}"
     echo -e "\n[+] Parsing/Uploading ${PKG_FAMILY}/${PKG_NAME} --> https://github.com/orgs/pkgforge/packages/container/package/${REPO}%2F${PKG_FAMILY:-PKG_NAME}%2F${PKG_NAME} [${ARCH}]"
     oras push --concurrency "100" --disable-path-validation \
     --config "/dev/null:application/vnd.oci.empty.v1+json" \
     --annotation "com.github.package.type=soar_pkg" \
     --annotation "dev.pkgforge.discord=https://discord.gg/djJUs48Zbu" \
     --annotation "dev.pkgforge.soar.build_date=${PKG_DATE}" \
     --annotation "dev.pkgforge.soar.build_log=${BUILD_LOG}" \
     --annotation "dev.pkgforge.soar.build_script=${BUILD_SCRIPT}" \
     --annotation "dev.pkgforge.soar.bsum=${PKG_BSUM}" \
     --annotation "dev.pkgforge.soar.category=${PKG_CATEGORY}" \
     --annotation "dev.pkgforge.soar.description=${PKG_DESCRIPTION}" \
     --annotation "dev.pkgforge.soar.download_url=ghcr.io/pkgforge/${REPO}/${PKG_FAMILY:-PKG_NAME}/${PKG_NAME}:${ARCH}" \
     --annotation "dev.pkgforge.soar.homepage=${PKG_HOMEPAGE:-PKG_SRCURL}" \
     --annotation "dev.pkgforge.soar.icon=${PKG_ICON}" \
     --annotation "dev.pkgforge.soar.json=$(jq . ${TMPDIR}/${TMPJSON})" \
     --annotation "dev.pkgforge.soar.note=${PKG_NOTE}" \
     --annotation "dev.pkgforge.soar.pkg=${PKG_ORIG}" \
     --annotation "dev.pkgforge.soar.pkg_family=${PKG_FAMILY}" \
     --annotation "dev.pkgforge.soar.pkg_name=${PKG_NAME}" \
     --annotation "dev.pkgforge.soar.pkg_webindex=https://pkgs.pkgforge.dev/stable/${ARCH}-Linux/${PKG_FAMILY:-PKG_NAME}/${PKG_NAME}" \
     --annotation "dev.pkgforge.soar.repology=${PKG_REPOLOGY}" \
     --annotation "dev.pkgforge.soar.screenshot=${PKG_SCREENSHOT}" \
     --annotation "dev.pkgforge.soar.shasum=${PKG_SHASUM}" \
     --annotation "dev.pkgforge.soar.size=${PKG_SIZE}" \
     --annotation "dev.pkgforge.soar.size_raw=${PKG_SIZE_RAW}" \
     --annotation "dev.pkgforge.soar.src_url=${PKG_SRCURL:-PKG_HOMEPAGE}" \
     --annotation "org.opencontainers.image.authors=https://docs.pkgforge.dev/contact/chat" \
     --annotation "org.opencontainers.image.created=${PKG_DATE}" \
     --annotation "org.opencontainers.image.description=${PKG_DESCRIPTION}" \
     --annotation "org.opencontainers.image.documentation=https://pkgs.pkgforge.dev/stable/${ARCH}-Linux/${PKG_FAMILY:-PKG_NAME}/${PKG_NAME}" \
     --annotation "org.opencontainers.image.licenses=blessing" \
     --annotation "org.opencontainers.image.ref.name=${GHCR_PKGVER}" \
     --annotation "org.opencontainers.image.revision=${PKG_SHASUM:-GHCR_PKGVER}" \
     --annotation "org.opencontainers.image.source=https://github.com/pkgforge/${REPO}" \
     --annotation "org.opencontainers.image.title=${PKG_NAME}" \
     --annotation "org.opencontainers.image.url=${PKG_SRCURL}" \
     --annotation "org.opencontainers.image.vendor=pkgforge" \
     --annotation "org.opencontainers.image.version=${GHCR_PKGVER}" \
     "ghcr.io/pkgforge/${REPO}/${PKG_FAMILY:-PKG_NAME}/${PKG_NAME}:${GHCR_PKGVER},${ARCH}" "${GHCR_PKG}"
     echo -e "\n[+] Registry --> ghcr.io/pkgforge/${REPO}/${PKG_FAMILY:-PKG_NAME}/${PKG_NAME}\n"
     rm -rf "${GHCR_PKG}" "${TMPDIR}/${TMPJSON}" 2>/dev/null
   else
     echo -e "\n[-] FAILED to Download ${PKG_FAMILY}/${PKG_NAME} <-- ${DOWNLOAD_URL} [${ARCH}]\n"
     cat "${TMPDIR}/${TMPJSON}"
     return
   fi
  fi
fi   
}
export -f upload_to_ghcr
popd >/dev/null 2>&1
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
cleanup_env()
{
#Cleanup Dir  
 if [[ "${KEEP_LOGS}" != "YES" ]]; then
  echo -e "\n[-] Removing ALL Logs & Files\n"
  rm -rvf "${BUILD_DIR}" 2>/dev/null
 fi
#Cleanup Env
 unset BUILD_DIR INPUT_SBUILD INPUT_SBUILD_PATH pkg PKG pkg_id PKG_ID pkg_type PKG_TYPE SBUILD_OUTDIR SBUILD_PKG SBUILD_PKGS SBUILD_PKGVER SBUILD_SCRIPT SBUILD_SUCCESSFUL SBUILD_TMPDIR TMPJSON TMPXVER TMPXRUN
}
export -f cleanup_env
#-------------------------------------------------------#