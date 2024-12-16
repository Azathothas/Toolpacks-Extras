#!/usr/bin/env bash

# VERSION=0.0.1

#-------------------------------------------------------#
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Build & Upload All our Packages
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/builder.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/builder.sh")
#-------------------------------------------------------#


#-------------------------------------------------------#
##ENV:$PATH
HOST_TRIPLET="$(uname -m)-$(uname -s)"
PKG_REPO="bincache"
SYSTMP="$(dirname "$(mktemp -u)")"
TMPDIRS="mktemp -d --tmpdir=${SYSTMP}/pkgforge XXXXXXX_SBUILD"
export HOST_TRIPLET PKG_REPO SYSTMP TMPDIRS ; mkdir -pv "${SYSTMP}/pkgforge"
#-------------------------------------------------------#

#-------------------------------------------------------#
##Init
 INITSCRIPT="$(mktemp --tmpdir=${SYSTMP} XXXXX_init.sh)" && export INITSCRIPT="${INITSCRIPT}"
 curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/${HOST_TRIPLET}/init_debian.sh" -o "${INITSCRIPT}"
 chmod +xwr "${INITSCRIPT}" && source "${INITSCRIPT}"
 #Check
 if [ "${CONTINUE}" != "YES" ]; then
   echo -e "\n[+] Failed To Initialize\n"
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
 #ENV
  BUILDSCRIPT="$(mktemp --tmpdir="${SYSTMP}/pkgforge" XXXXX_build.yaml)" && export BUILDSCRIPT="${BUILDSCRIPT}"
 #Get URlS
  curl -qfsSL "https://raw.githubusercontent.com/pkgforge/bincache/refs/heads/main/SBUILD_LIST.json" -o "${SYSTMP}/pkgforge/SBUILD_LIST.json"
  jq -r '.[] | select(._disabled == false) | .build_script' "${SYSTMP}/pkgforge/SBUILD_LIST.json" | sort -u -o "${SYSTMP}/pkgforge/SBUILD_URLS"
  echo -e "\n\n[+] Started Building at :: $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
  readarray -t RECIPES < "${SYSTMP}/pkgforge/SBUILD_URLS"
  TOTAL_RECIPES="${#RECIPES[@]}" && export TOTAL_RECIPES="${TOTAL_RECIPES}"
  echo -e "\n[+] Total RECIPES :: ${TOTAL_RECIPES}\n"
   for ((i=0; i<${#RECIPES[@]}; i++)); do
    pushd "$($TMPDIRS)" >/dev/null 2>&1
    OCWD="$(realpath .)" ; export OCWD
    unset CONTINUE_SBUILD KEEP_LOGS LOGPATH PUSH_SUCCESSFUL SBUILD_SUCCESSFUL
    TEMP_LOG="./BUILD.log"
    #Init
     START_TIME="$(date +%s)" && export START_TIME="${START_TIME}"
     RECIPE="${RECIPES[i]}"
     CURRENT_RECIPE=$((i+1))
     echo -e "\n[+] Fetching : ${RECIPE} (${CURRENT_RECIPE}/${TOTAL_RECIPES})\n"
    #Fetch
     curl -qfsSL "${RECIPE}" -o "${BUILDSCRIPT}" ; chmod +xwr "${BUILDSCRIPT}"
    #Run
    if [[ -s "${BUILDSCRIPT}" && $(stat -c%s "${BUILDSCRIPT}") -gt 10 ]]; then
     SBUILD_SCRIPT="${RECIPE}" && export SBUILD_SCRIPT
     PKG_FAMILY="$(jq -r '.[] | select(.build_script == env.SBUILD_SCRIPT) | .pkg_family' "${SYSTMP}/pkgforge/SBUILD_LIST.json" | tr -d '[:space:]')" && export PKG_FAMILY
     #Main
      {
       setup_env "${BUILDSCRIPT}"
       check_sane_env
       gen_json_from_sbuild
       build_progs
       if [ -d "${SBUILD_OUTDIR}" ] && [ "$(du -s "${SBUILD_OUTDIR}" | cut -f1)" -gt 100 ]; then
         generate_json 
       #Upload
         #upload_to_ghcr
         if [[ "${PUSH_SUCCESSFUL}" != "YES" ]]; then
           echo 'KEEP_LOGS="YES"' >> "${OCWD}/ENVPATH"
         fi
       else
         echo 'KEEP_LOGS="YES"' >> "${OCWD}/ENVPATH"
       fi
      #} 2>&1 | ts '[%Y-%m-%dT%Hh%Mm%Ss]➜ ' | tee "${TEMP_LOG}"
      } 2>&1 | ts -s '[%H:%M:%S]➜ ' | tee "${TEMP_LOG}"
      source "${OCWD}/ENVPATH"
      sanitize_logs
      attach_to_ghcr
      cleanup_env
    fi
    if [[ "${KEEP_LOGS}" != "YES" ]]; then
     rm "$(realpath .)" && popd >/dev/null 2>&1
    else
     popd >/dev/null 2>&1
    fi 
    END_TIME="$(date +%s)" && export END_TIME="${END_TIME}"
    ELAPSED_TIME="$(date -u -d@"$((END_TIME - START_TIME))" "+%H(Hr):%M(Min):%S(Sec)")" 
   done
   echo -e "\n\n [+] Finished Building at :: $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
 popd >/dev/null 2>&1
##Finish
#-------------------------------------------------------#