#!/usr/bin/env bash

#-------------------------------------------------------#
# This should be run on Debian (Debian Based) Distros with apt, coreutils, curl, dos2unix & passwordless sudo
# sudo apt-get update -y && sudo apt-get install coreutils curl dos2unix moreutils -y
# OR (without sudo): apt-get update -y && apt-get install coreutils curl dos2unix moreutils sudo -y
#
# Hardware : At least 2vCPU + 8GB RAM + 50GB SSD
# Once requirement is satisfied, simply:
# export GITHUB_TOKEN="NON_PRIVS_READ_ONLY_TOKEN"
# bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/$(uname -m)-$(uname -s)/build_debian.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV:$PATH
 HOST_TRIPLET="$(uname -m)-$(uname -s)" && export HOST_TRIPLET="${HOST_TRIPLET}"
 HF_REPO_DL="https://huggingface.co/datasets/Azathothas/Toolpacks-Extras/resolve/main/${HOST_TRIPLET}" && export HF_REPO_DL="${HF_REPO_DL}"
 #export NIX_SETUP_MODE="EXPENSIVE"
 source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/env.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##Init
 #Get
 INITSCRIPT="$(mktemp --tmpdir=${SYSTMP} XXXXX_init.sh)" && export INITSCRIPT="$INITSCRIPT"
 curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/init_debian.sh" -o "$INITSCRIPT"
 chmod +xwr "$INITSCRIPT" && source "$INITSCRIPT"
 #Check
 if [ "$CONTINUE" != "YES" ]; then
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
##Sanity Checks
#GH
if [[ -n "${GITHUB_TOKEN}" ]]; then
   echo -e "\n[+] GITHUB_TOKEN is Exported"
  ##gh-cli (uses ${GITHUB_TOKEN} env var)
   #echo "${GITHUB_TOKEN}" | gh auth login --with-token
   gh auth status
  ##eget
   # 5000 req/minute (80 req/minute)
   eget --rate
else
   # 60 req/hr
   echo -e "\n[-] GITHUB_TOKEN is NOT Exported"
   echo -e "Export it to avoid ratelimits\n"
   eget --rate
   exit 1
fi
#GL
if [[ -n "${GITLAB_TOKEN}" ]]; then
   echo -e "\n[+] GITLAB is Exported"
   glab auth status
else
   echo -e "\n[-] GITLAB_TOKEN is NOT Exported"
   echo -e "Export it to avoid ratelimits\n"
fi
#hf
if ! command -v huggingface-cli &> /dev/null; then
    echo -e "\n[-] huggingface-cli is NOT Installed"
  exit 1
fi
if [[ -n "${HF_TOKEN}" ]]; then
   echo -e "\n[+] HF_TOKEN is Exported"
   git config --global "credential.helper" store
   git config --global "user.email" "AjamX101@gmail.com"
   git config --global "user.name" "Azathothas"
   huggingface-cli login --token "${HF_TOKEN}" --add-to-git-credential
else
   echo -e "\n[-] HF_TOKEN is NOT Exported"
   echo -e "Export it to use huggingface-cli\n"
   exit 1
fi
#-------------------------------------------------------#


#-------------------------------------------------------#
##ENV (In Case of ENV Resets)
#TMPDIRS
 #For build-cache
 TMPDIRS="mktemp -d --tmpdir=${SYSTMP}/toolpacks XXXXXXX_$(uname -m)_$(uname -s)" && export TMPDIRS="$TMPDIRS"
 rm -rf "${SYSTMP}/toolpacks" 2>/dev/null ; mkdir -p "${SYSTMP}/toolpacks"
 #For Bins
 BINDIR="${SYSTMP}/toolpack_$(uname -m)" && export BINDIR="${BINDIR}"
 rm -rf "${BINDIR}" 2>/dev/null ; mkdir -p "${BINDIR}"
##Build
set +x
 BUILD="YES" && export BUILD="${BUILD}"
 #ENV
 BUILDSCRIPT="$(mktemp --tmpdir=${SYSTMP} XXXXX_build.sh)" && export BUILDSCRIPT="${BUILDSCRIPT}"
 #Get URlS
 curl -qfsSL "https://api.github.com/repos/Azathothas/Toolpacks-Extras/contents/.github/scripts/${HOST_TRIPLET}/pkgs" \
 -H "Authorization: Bearer ${GITHUB_TOKEN}" | jq -r '.[] | select(.download_url | endswith(".sh")) | .download_url' |\
 grep -i "\.sh$" | sort -u -o "${SYSTMP}/BUILDURLS"
 #Run
  echo -e "\n\n [+] Started Building at :: $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"  
  readarray -t RECIPES < "${SYSTMP}/BUILDURLS"
  unset TOTAL_RECIPES ; TEMP_LOG="$(mktemp)" && export TEMP_LOG="${TEMP_LOG}"
  TOTAL_RECIPES="${#RECIPES[@]}" && export TOTAL_RECIPES="${TOTAL_RECIPES}" ; echo -e "\n[+] Total RECIPES :: ${TOTAL_RECIPES}\n"
    for ((i=0; i<${#RECIPES[@]}; i++)); do
    {
      #Init
        START_TIME="$(date +%s)" && export START_TIME="${START_TIME}"
        RECIPE="${RECIPES[i]}"
        CURRENT_RECIPE=$((i+1))
        echo -e "\n[+] Fetching : ${RECIPE} (${CURRENT_RECIPE}/${TOTAL_RECIPES})\n"
      #Fetch
        curl -qfsSL "${RECIPE}" -o "${BUILDSCRIPT}"
        chmod +xwr "${BUILDSCRIPT}"
      #Run 
        source "${BUILDSCRIPT}" || true
      #Clean & Purge
        sudo rm -rf "${SYSTMP}/toolpacks" 2>/dev/null
        mkdir -p "${SYSTMP}/toolpacks"
      #Finish
        END_TIME="$(date +%s)" && export END_TIME="${END_TIME}"
        ELAPSED_TIME="$(date -u -d@"$((END_TIME - START_TIME))" "+%H(Hr):%M(Min):%S(Sec)")"
      echo -e "\n[+] Completed (Building|Fetching) ${BIN} [${SOURCE_URL}] :: ${ELAPSED_TIME} ==> ${LOG_PATH}\n"
    } > "${TEMP_LOG}" 2>&1
     sed -e '/.*github_pat.*/Id' \
        -e '/.*ghp_.*/Id' \
        -e '/.*glpat.*/Id' \
        -e '/.*hf_.*/Id' \
        -e '/.*token.*/Id' \
        -e '/.*access_key_id.*/Id' \
        -e '/.*secret_access_key.*/Id' \
        -e '/.*cloudflarestorage.*/Id' "${TEMP_LOG}" | tee "${LOG_PATH}"
    done
    rm "${TEMP_LOG}" 2>/dev/null
  echo -e "\n\n [+] Finished Building at :: $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
 #Check
 BINDIR_SIZE="$(du -sh "${BINDIR}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "BINDIR_SIZE=${BINDIR_SIZE}"
 if [ ! -d "${BINDIR}" ] || [ -z "$(ls -A "${BINDIR}")" ] || [ -z "${BINDIR_SIZE}" ] || [[ "${BINDIR_SIZE}" == *K* ]]; then
      echo -e "\n[+] Broken/Empty Built "${BINDIR}" Found\n"
      exit 1
 else
      echo -e "\n[+] Built "${BINDIR}" :: ${BINDIR_SIZE}\n"
 fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Push to HF
pushd "$(mktemp -d)" >/dev/null 2>&1
 source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_git_ops.sh")
 hf_git_ops
popd >/dev/null 2>&1
##Generate Metadata (MAIN)
pushd "$(mktemp -d)" >/dev/null 2>&1
 source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_gen_meta_main.sh")
 hf_gen_meta_main
popd >/dev/null 2>&1
#-------------------------------------------------------#