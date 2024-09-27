#!/usr/bin/env bash
## <CAN BE RUN STANDALONE>
## <REQUIRES: hf_setup_env>
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_build_standalone.sh")
# source <(curl -qfsSL "https://l.ajam.dev/hf-build-standalone")
##
#-------------------------------------------------------#


#-------------------------------------------------------#
##Main
hf_build_temp_pkg() 
{
   #Set local env
    local GH_REPO_DL="https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts"
    local LOCAL_SCRIPT="false"
    local REMOTE_SCRIPT="false"
    local TEMP_LOG="${SYSTMP}/BUILD.log.tmp"
    local ARG
   #Parse flags 
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --local)
                LOCAL_SCRIPT="true"
                shift
                ;;
            --remote)
                REMOTE_SCRIPT="true"
                shift
                ;;
            *)
                ARG="$1"
                shift
                ;;
        esac
    done
   #Strip nonsense
    ARG="${ARG#"${ARG%%[![:space:]]*}"}"
    ARG="${ARG%"${ARG##*[![:space:]]}"}"
   #Check if locally exists
    if [[ -f "${ARG}" ]] && [[ "${REMOTE_SCRIPT}" != true ]]; then
      echo -e "\n[+]INFO: Running Locally (--local) $(realpath "${ARG}")\n"
      export LOCAL_SCRIPT="true"
    elif [[ -f "${ARG}" ]] && [[ "${REMOTE_SCRIPT}" == true ]]; then
      echo -e "\n[+]INFO: File exists, locally $(realpath "${ARG}") [Forcing (--remote)]\n"
      export REMOTE_SCRIPT="true"
    fi
   ##Run
   #Locally
    if [[ "${LOCAL_SCRIPT}" == true ]] || [[ "${ARG}" == *.sh ]]; then
      echo "\n[+] (--local) --> $(realpath ${ARG})\n"
      { 
        source "$(realpath "${ARG}")"
      } > "${TEMP_LOG}" 2>&1
   #Remote    
    elif [[ "${REMOTE_SCRIPT}" == true ]]; then
        if [[ "${ARG}" != *.sh ]]; then
         echo "\n[+] (--remote) --> ${GH_REPO_DL}/${HOST_TRIPLET}/pkgs/${ARG}.sh\n"
         { 
           source <(curl -qfsSL "${GH_REPO_DL}/${HOST_TRIPLET}/pkgs/${ARG}.sh")
         } > "${TEMP_LOG}" 2>&1
        else
         echo "\n[+] (--remote) --> ${GH_REPO_DL}/${HOST_TRIPLET}/pkgs/${ARG}\n"
         { 
           source <(curl -qfsSL "${GH_REPO_DL}/${HOST_TRIPLET}/pkgs/${ARG}")
         } > "${TEMP_LOG}" 2>&1
        fi
    #Exit
    else
       echo "\n[+] hf_build_temp_pkg LOCAL_FILE_OR_REMOTE_SCRIPT (--local | --remote)\n"
       return 1
    fi
    #Parse Log
     if [[ -f "${TEMP_LOG}" && $(stat -c%s "${TEMP_LOG}") -gt 3 ]]; then
       sed -e '/.*github_pat.*/Id' \
        -e '/.*ghp_.*/Id' \
        -e '/.*glpat.*/Id' \
        -e '/.*hf_.*/Id' \
        -e '/.*token.*/Id' \
        -e '/.*access_key_id.*/Id' \
        -e '/.*secret_access_key.*/Id' \
        -e '/.*cloudflarestorage.*/Id' "${TEMP_LOG}" | tee "${LOG_PATH}"
        echo -e "\n[+] LOG: $(realpath ${LOG_PATH})\n"
     else
        cat "${TEMP_LOG}" ; realpath "${TEMP_LOG}"
     fi
   #Revert set -x
    set +x ; unset LOCAL_SCRIPT REMOTE_SCRIPT TEMP_LOG
}
#-------------------------------------------------------#

#-------------------------------------------------------#
#Sanity Checks
if [ "${BUILD}" != "YES" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${GIT_TERMINAL_PROMPT}" ] || \
   [ -z "${GIT_ASKPASS}" ] || \
   [ -z "${GITHUB_TOKEN}" ] || \
   [ -z "${GITLAB_TOKEN}" ] || \
   [ -z "${HF_REPO_DL}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS NOT Set... Skipping Builds...\n"
 exit 1 
else
  export -f hf_build_temp_pkg
fi
#-------------------------------------------------------#