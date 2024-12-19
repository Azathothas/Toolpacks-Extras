#!/usr/bin/env bash

#-------------------------------------------------------#
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Build & Upload All our Packages
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/builder.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/builder.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
sbuild_builder()
 {
  ##Version
   SBB_VERSION="0.0.3" && echo -e "[+] SBUILD Builder Version: ${SBB_VERSION}" ; unset SBB_VERSION 
  ##Enable Debug 
   if [ "${DEBUG}" = "1" ] || [ "${DEBUG}" = "ON" ]; then
      set -x
   fi
  ##Get/Set ENVS (from Host)
   #User
   case "${USER}" in
     "" )
       echo "WARNING: \$USER is Unknown"
       USER="$(whoami)"
       export USER
       if [ -z "${USER}" ]; then
         echo -e "[-] INFO: Setting USER --> ${USER}"
       else
         echo -e "[-] WARNING: FAILED to find \$USER"
       fi
       ;;
   esac
  ##ENV:$PATH
   HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
   export PATH="${HOME}/bin:${HOME}/.cargo/bin:${HOME}/.cargo/env:${HOME}/.go/bin:${HOME}/go/bin:${HOME}/.local/bin:${HOME}/miniconda3/bin:${HOME}/miniconda3/condabin:/usr/local/zig:/usr/local/zig/lib:/usr/local/zig/lib/include:/usr/local/musl/bin:/usr/local/musl/lib:/usr/local/musl/include:${PATH}"
   if command -v awk >/dev/null 2>&1 && command -v sed >/dev/null 2>&1; then
    PATH="$(echo "${PATH}" | awk 'BEGIN{RS=":";ORS=":"}{gsub(/\n/,"");if(!a[$0]++)print}' | sed 's/:*$//')" ; export PATH
   fi
   HOST_TRIPLET="$(uname -m)-$(uname -s)"
   PKG_REPO="pkgcache"
   if [ -z "${SYSTMP+x}" ] || [ -z "${SYSTMP##*[[:space:]]}" ]; then
    SYSTMP="$(dirname $(realpath $(mktemp -u)))" && export SYSTMP="${SYSTMP}"
    mkdir -p "${SYSTMP}" 2>/dev/null
   fi
   TMPDIRS="mktemp -d --tmpdir=${SYSTMP}/pkgforge XXXXXXX_SBUILD"
   USER_AGENT="$(curl -qfsSL 'https://pub.ajam.dev/repos/Azathothas/Wordlists/Misc/User-Agents/ua_chrome_macos_latest.txt')"
   export HOST_TRIPLET PKG_REPO SYSTMP TMPDIRS USER_AGENT
   if [[ "${KEEP_PREVIOUS}" != "YES" ]]; then
    rm -rf "${SYSTMP}/pkgforge"
    find "${SYSTMP}" -mindepth 1 \( -type f -o -type d \) -empty -not -path "$(pwd)" -not -path "$(pwd)/*" -delete 2>/dev/null
   fi
   mkdir -p "${SYSTMP}/pkgforge"
  ##Get Initial Inputs
   BUILDSCRIPT="$(mktemp --tmpdir="${SYSTMP}/pkgforge" XXXXX_build.yaml)" && export BUILDSCRIPT="${BUILDSCRIPT}"
   INPUT_FILE="${1:-$(echo "$@" | tr -d '[:space:]')}"
   if [ -n "${INPUT_FILE+x}" ] && [ -n "${INPUT_FILE##*[[:space:]]}" ]; then
     INPUT_FILE="$(realpath ${INPUT_FILE})" ; export INPUT_FILE
     SELF_NAME="${ARGV0:-${0##*/}}" ; export SELF_NAME
   else
     SELF_NAME="sbuild-builder" ; export SELF_NAME
   fi
   if [[ -z "${INPUT_FILE}" ]]; then
    echo -e "\n[+] Building Everything (Rerun: ${SELF_NAME} /path/to/SBUILD_FILE , if you are building a Single Prog)\n"
   else
    if [ -f "${INPUT_FILE}" ] && [ -s "${INPUT_FILE}" ]; then
      echo -e "\n[+] Building [${INPUT_FILE}] Locally\n"
      cp -fv "${INPUT_FILE}" "${BUILDSCRIPT}"
      if [[ -s "${BUILDSCRIPT}" && $(stat -c%s "${BUILDSCRIPT}") -gt 10 ]]; then
        export LOCAL_SBUILD="YES"
      else
        echo -e "\n[✗] FATAL: ${INPUT_FILE} is NOT a Valid file\n"
      fi
    else
      echo -e "\n[✗] FATAL: ${INPUT_FILE} is NOT a file\n"
      export CONTINUE_SBUILD="NO"
      return 1 || exit 1
    fi
   fi
  #Clean
   unset INPUT_FILE SELF_NAME
  #-------------------------------------------------------#

  #-------------------------------------------------------#
  ##Init
   INITSCRIPT="$(mktemp --tmpdir=${SYSTMP} XXXXX_init.sh)" && export INITSCRIPT="${INITSCRIPT}"
   curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/setup_${HOST_TRIPLET}.sh" -o "${INITSCRIPT}"
   chmod +xwr "${INITSCRIPT}" && source "${INITSCRIPT}"
   #Check
   if [ "${CONTINUE}" != "YES" ]; then
     echo -e "\n[✗] Failed To Initialize\n"
    exit 1
   fi
  ##Ulimits
  #(-n) Open File Descriptors
   echo -e "[+] ulimit -n (open file descriptors) :: [Soft --> $(ulimit -n -S)] [Hard --> $(ulimit -n -H)] [Total --> $(cat '/proc/sys/fs/file-max')]"
   ulimit -n "$(ulimit -n -H)"
  #Stack Size
   ulimit -s unlimited
  #-------------------------------------------------------#
  
  #-------------------------------------------------------#
  ##Functions
  source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/functions.sh")
  sanitize_logs()
  {
  if [[ -s "${TEMP_LOG}" && $(stat -c%s "${TEMP_LOG}") -gt 10 && -n "${LOGPATH}" ]]; then
   echo -e "[+] Sanitizing $(realpath "${TEMP_LOG}") ==> ${LOGPATH}"
   if command -v trufflehog &> /dev/null; then
     trufflehog filesystem "${TEMP_LOG}" --no-fail --no-verification --no-update --json 2>/dev/null | jq -r '.Raw' | sed '/{/d' | xargs -I "{}" sh -c 'echo "{}" | tr -d " \t\r\f\v"' | xargs -I "{}" sed "s/{}/ /g" -i "${TEMP_LOG}"
   fi
   sed -e '/.*github_pat.*/Id' \
      -e '/.*ghp_.*/Id' \
      -e '/.*glpat.*/Id' \
      -e '/.*hf_.*/Id' \
      -e '/.*token.*/Id' \
      -e '/.*access_key_id.*/Id' \
      -e '/.*secret_access_key.*/Id' \
      -e '/.*cloudflarestorage.*/Id' -i "${TEMP_LOG}"
   sed '/.*\[+\] Total Size.*/I,$ { /.*\[+\] Total Size.*/I p; d }' -i "${TEMP_LOG}"
      #grep -viE 'github_pat|ghp_|glpat|hf_|token|access_key_id|secret_access_key|cloudflarestorage' "${TEMP_LOG}" | tee "${LOGPATH}" && rm "${TEMP_LOG}" 2>/dev/null
      grep -viE 'github_pat|ghp_|glpat|hf_|token|access_key_id|secret_access_key|cloudflarestorage' "${TEMP_LOG}" > "${LOGPATH}" && rm "${TEMP_LOG}" 2>/dev/null
      #mv -fv "${TEMP_LOG}" "${LOGPATH}" && rm "${TEMP_LOG}" 2>/dev/null
  fi
  }
  export -f sanitize_logs
   #Check
   if ! (declare -F setup_env &>/dev/null && \
     declare -F check_sane_env &>/dev/null && \
     declare -F gen_json_from_sbuild &>/dev/null && \
     declare -F build_progs &>/dev/null && \
     declare -F generate_json &>/dev/null && \
     declare -F upload_to_ghcr &>/dev/null && \
     declare -F sanitize_logs &>/dev/null && \
     declare -F cleanup_env &>/dev/null); then
       echo -e "\n[✗] FATAL: Required Functions could NOT BE Found\n"
      exit 1
   fi
  #-------------------------------------------------------#

  #-------------------------------------------------------#
  ##Build
  pushd "$($TMPDIRS)" >/dev/null 2>&1
   #If local
   if [[ "${LOCAL_SBUILD}" == "YES" ]]; then
    echo "$(realpath ${BUILDSCRIPT})" > "${SYSTMP}/pkgforge/SBUILD_URLS"
   else
   #Get URlS
    curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/SBUILD_LIST.json" -o "${SYSTMP}/pkgforge/SBUILD_LIST.json"
    jq -r '.[] | select(._disabled == false) | .build_script' "${SYSTMP}/pkgforge/SBUILD_LIST.json" | sort -u -o "${SYSTMP}/pkgforge/SBUILD_URLS"
   fi
  #Build
   echo -e "\n==> [+] Started Building at :: $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n"
   readarray -t RECIPES < "${SYSTMP}/pkgforge/SBUILD_URLS"
   TOTAL_RECIPES="${#RECIPES[@]}" && export TOTAL_RECIPES="${TOTAL_RECIPES}"
   echo -e "\n[+] Total RECIPES :: ${TOTAL_RECIPES}\n"
    for ((i=0; i<${#RECIPES[@]}; i++)); do
     pushd "$($TMPDIRS)" >/dev/null 2>&1
     OCWD="$(realpath .)" ; export OCWD
     unset CONTINUE_SBUILD GHCRPKG KEEP_LOGS LOGPATH PKG_FAMILY PUSH_SUCCESSFUL RECIPE SBUILD_REBUILD SBUILD_SUCCESSFUL
     TEMP_LOG="./BUILD.log"
     #Init
      START_TIME="$(date +%s)" && export START_TIME="${START_TIME}"
      RECIPE="${RECIPES[i]}" ; export RECIPE
      CURRENT_RECIPE=$((i+1))
      echo -e "\n[+] Fetching : ${RECIPE} (${CURRENT_RECIPE}/${TOTAL_RECIPES})\n"
     #Fetch
      if echo "${RECIPE}" | grep -E -q '^https?://'; then
       curl -qfsSL "${RECIPE}" -o "${BUILDSCRIPT}" ; chmod +xwr "${BUILDSCRIPT}"
      elif [ -s "${BUILDSCRIPT}" ]; then
       realpath "${BUILDSCRIPT}"
      fi
     #Run
     if [[ -s "${BUILDSCRIPT}" && $(stat -c%s "${BUILDSCRIPT}") -gt 10 ]]; then
      SBUILD_SCRIPT="${RECIPE}" && export SBUILD_SCRIPT
      if [[ "${LOCAL_SBUILD}" == "YES" ]]; then
       if [ -n "${GHCRPKG_LOCAL+x}" ] && [ -n "${GHCRPKG_LOCAL##*[[:space:]]}" ]; then
         GHCRPKG="${GHCRPKG_LOCAL}" ; unset GHCRPKG_LOCAL ; export GHCRPKG
         echo "[+] Setting '.ghcrpkg' --> ${GHCRPKG} [Provided]"
       fi
       if [ -n "${PKG_FAMILY_LOCAL+x}" ] && [ -n "${PKG_FAMILY_LOCAL##*[[:space:]]}" ]; then
         PKG_FAMILY="${PKG_FAMILY_LOCAL}" ; unset PKG_FAMILY_LOCAL ; export PKG_FAMILY
         echo "[+] Setting '.pkg_family' --> ${PKG_FAMILY} [Provided]"
       else
         PKG_FAMILY="$(yq eval '.pkg' "${BUILDSCRIPT}" | tr -d '[:space:]')" ; export PKG_FAMILY
         echo "[+] Setting '.pkg_family' --> ${PKG_FAMILY} [Guessed]"
       fi
       SBUILD_REBUILD="true" ; export SBUILD_REBUILD
       unset LOCAL_SBUILD
      elif [[ -s "${SYSTMP}/pkgforge/SBUILD_LIST.json" && $(stat -c%s "${SYSTMP}/pkgforge/SBUILD_LIST.json") -gt 10 ]]; then
       GHCRPKG="$(jq -r '.[] | select(.build_script == env.SBUILD_SCRIPT) | .ghcrpkg' "${SYSTMP}/pkgforge/SBUILD_LIST.json" | tr -d '[:space:]')" && export GHCRPKG
       PKG_FAMILY="$(jq -r '.[] | select(.build_script == env.SBUILD_SCRIPT) | .pkg_family' "${SYSTMP}/pkgforge/SBUILD_LIST.json" | tr -d '[:space:]')" && export PKG_FAMILY
       SBUILD_REBUILD="$(jq -r '.[] | select(.build_script == env.SBUILD_SCRIPT) | .rebuild' "${SYSTMP}/pkgforge/SBUILD_LIST.json" | tr -d '[:space:]')" && export SBUILD_REBUILD
      else
       echo -e "\n[✗] FATAL: No Local SBUILD was Supplied & Remote ${SYSTMP}/pkgforge/SBUILD_LIST.json Does Not Exist\n"
      fi
      #Main
       {
        setup_env "${BUILDSCRIPT}"
        check_sane_env
        gen_json_from_sbuild
        build_progs
        if [ -d "${SBUILD_OUTDIR}" ] && [ "$(du -s "${SBUILD_OUTDIR}" | cut -f1)" -gt 100 ]; then
          generate_json
        else
          echo 'KEEP_LOGS="YES"' >> "${OCWD}/ENVPATH"
        fi
       #} 2>&1 | ts '[%Y-%m-%dT%Hh%Mm%Ss]➜ ' | tee "${TEMP_LOG}"
       } 2>&1 | ts -s '[%H:%M:%S]➜ ' | tee "${TEMP_LOG}"
       source "${OCWD}/ENVPATH" ; SBUILD_PKGS=($SBUILD_PKGS)
       sanitize_logs
       printf '%s\n' "${SBUILD_PKGS[@]}" | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'upload_to_ghcr "$@"' _ "{}"
       if [[ "${PUSH_SUCCESSFUL}" != "YES" ]]; then
        export KEEP_LOGS="YES"
       fi
       cleanup_env
     fi
     if [[ "${KEEP_LOGS}" != "YES" ]]; then
      rm -rf "$(realpath .)" && popd >/dev/null 2>&1
     else
      popd >/dev/null 2>&1
     fi
     END_TIME="$(date +%s)" && export END_TIME="${END_TIME}"
     ELAPSED_TIME="$(date -u -d@"$((END_TIME - START_TIME))" "+%H(Hr):%M(Min):%S(Sec)")"
     echo -e "\n[+] Completed (Building|Fetching) ${RECIPE} :: ${ELAPSED_TIME}\n"
    done
    echo -e "\n==> [+] Finished Building at :: $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n"
   popd >/dev/null 2>&1
  ##Finish
  #Disable Debug
  if [ "${DEBUG}" = "1" ] || [ "${DEBUG}" = "ON" ]; then
    set +x
  fi
}
export -f sbuild_builder
alias sbuild-builder="sbuild_builder"
#Call func directly if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
   sbuild_builder "$@" <&0
fi
#-------------------------------------------------------#