#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Sync All our Prebuilts to ghcr
## The metadata for the pkg to-be-added must already exist in the AIO files
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/ghcr/add_to_ghcr.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/ghcr/add_to_ghcr.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
TZ="UTC"
export ARCH REPO TZ
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#-------------------------------------------------------#

#-------------------------------------------------------#
##Fetch Metadata
pushd "${TMPDIR}" >/dev/null 2>&1
curl -qfsSL "https://bin.pkgforge.dev/aarch64/METADATA.AIO.json" -o "${TMPDIR}/aarch64.json"
curl -qfsSL "https://bin.pkgforge.dev/x86_64/METADATA.AIO.json" -o "${TMPDIR}/x86_64.json"
jq -r '.. | objects | .download_url? // empty' "${TMPDIR}/aarch64.json" > "${TMPDIR}/URLs.txt"
jq -r '.. | objects | .download_url? // empty' "${TMPDIR}/x86_64.json" >> "${TMPDIR}/URLs.txt"
sort -u "${TMPDIR}/URLs.txt" -o "${TMPDIR}/URLs.txt"
readarray -t URLS < "${TMPDIR}/URLs.txt"
##Upload Func
upload_to_ghcr()
{
 local URL="$1"
 #Clear ENV
  unset ARCH BUILD_LOG BUILD_SCRIPT DOWNLOAD_URL GHCR_PKG GHCR_PKGVER PKG_BSUM PKG_CATEGORY PKG_DATE PKG_DESCRIPTION PKG_FAMILY PKG_HOMEPAGE PKG_ICON PKG_NAME PKG_NOTE PKG_ORIG PKG_REPOLOGY PKG_SCREENSHOT PKG_SHASUM PKG_SIZE PKG_SIZE_RAW PKG_SRCURL PKG_TAG PKG_VERSION REPO VERSION TMPJSON
  TMPJSON="$(basename $(mktemp -u)).json"
 #Fetch 
  if echo "${URL}" | grep -q -m 1 '/aarch64'; then
   jq --arg URL "$URL" 'recurse | objects | select(.download_url == $URL)' "${TMPDIR}/aarch64.json" > "${TMPDIR}/${TMPJSON}"
  elif echo "${URL}" | grep -q -m 1 '/x86_64'; then
   jq --arg URL "$URL" 'recurse | objects | select(.download_url == $URL)' "${TMPDIR}/x86_64.json" > "${TMPDIR}/${TMPJSON}"
  fi
 #Parse
  if jq --exit-status . "${TMPDIR}/${TMPJSON}" >/dev/null 2>&1; then
   DOWNLOAD_URL="$(jq -r '.download_url' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
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
}
export -f upload_to_ghcr
popd >/dev/null 2>&1
#-------------------------------------------------------#

#-------------------------------------------------------#
##Upload
pushd "${TMPDIR}" >/dev/null 2>&1
if [[ -n "${PARALLEL_LIMIT}" ]]; then
 printf '%s\n' "${URLS[@]}" | xargs -P "${PARALLEL_LIMIT}" -I "{}" bash -c 'upload_to_ghcr "$@" 2>/dev/null' _ "{}"
else 
 printf '%s\n' "${URLS[@]}" | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'upload_to_ghcr "$@" 2>/dev/null' _ "{}"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#