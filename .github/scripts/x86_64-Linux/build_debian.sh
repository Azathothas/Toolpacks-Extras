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
     sed -e '/.*github_pat.*/d' \
        -e '/.*ghp_.*/d' \
        -e '/.*hf_.*/d' \
        -e '/.*access_key_id.*/d' \
        -e '/.*secret_access_key.*/d' \
        -e '/.*cloudflarestorage.*/d' "${TEMP_LOG}" | tee "${LOG_PATH}"
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
#Cleanup [${BINDIR}]
 #Chmod +xwr
 find "${BINDIR}" -maxdepth 1 -type f -exec sudo chmod +xwr {} \; 2>/dev/null
#-------------------------------------------------------#
##Sync to https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/${HOST_TRIPLET}
#Setup Repo
pushd "$(mktemp -d)" >/dev/null 2>&1 && git clone --depth="1" --filter="blob:none" --no-checkout "https://huggingface.co/datasets/Azathothas/Toolpacks-Extras" && cd "./Toolpacks-Extras"
 git lfs install
 huggingface-cli lfs-enable-largefiles "."
 HF_REPO_LOCAL="$(realpath .)" && export HF_REPO_LOCAL="${HF_REPO_LOCAL}"
 HF_REPO_PKGDIR="$(realpath ${HF_REPO_LOCAL})/${HOST_TRIPLET}" && export HF_REPO_PKGDIR="${HF_REPO_PKGDIR}"
 mkdir -p "${HF_REPO_PKGDIR}" ; git fetch origin main ; git lfs track "./${HOST_TRIPLET}/**"
 git sparse-checkout disable
 git sparse-checkout set --no-cone --sparse-index "/METADATA.json" \
 "${HOST_TRIPLET}/*.json" "${HOST_TRIPLET}/*.log" "${HOST_TRIPLET}/*.temp" "${HOST_TRIPLET}/*.tmp" "${HOST_TRIPLET}/*.txt"
 git checkout ; ls -lah "." "./${HOST_TRIPLET}"
 git sparse-checkout list
popd >/dev/null 2>&1
#-------------------------------------------------------#


#-------------------------------------------------------#
##Fetch Bins
pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
 rsync -av --checksum --copy-links --human-readable --remove-source-files --exclude="*/" "${BINDIR}/." "${HF_REPO_PKGDIR}/"
popd >/dev/null 2>&1
#Sync Repo (I)
pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
 git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
 find "${HF_REPO_PKGDIR}" -type f -size -3c -delete
 git sparse-checkout add "${HOST_TRIPLET}/**"
 git sparse-checkout list
 BINDIR_SIZE="$(du -sh "${HF_REPO_PKGDIR}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "BINDIR_SIZE=${BINDIR_SIZE}"
 git add --all --verbose && git commit -m "[+] PKG Built (${HOST_TRIPLET}) [${BINDIR_SIZE}B $(TZ='UTC' date +'%Y_%m_%d')]" ; df -h "/" 2>/dev/null
 git pull origin main ; git push origin main 
popd >/dev/null 2>&1
#-------------------------------------------------------#


#-------------------------------------------------------#
##Generate Metadata
#Chmod +xwr
 find "${HF_REPO_PKGDIR}" -maxdepth 1 -type f -exec chmod +xwr {} \; 2>/dev/null
 #File 
 cd "${HF_REPO_PKGDIR}" && find "./" -maxdepth 1 -type f |\
    grep -v -E '\.desktop$|\.DirIcon$|\.jq$|\.png$|\.txt$|\.upx$|\.version$|\.zsync$' |\
    sort | xargs file | jc --monochrome --pretty --file | jq . > "${SYSTMP}/${HOST_TRIPLET}_FILE"
    if [[ -f "${HF_REPO_PKGDIR}/FILE.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/FILE.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.type=$a_dict[.filename].type else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_FILE" "${HF_REPO_PKGDIR}/FILE.json" | jq . > "${SYSTMP}/${HOST_TRIPLET}_FILE.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_FILE.json" | jq . > "${HF_REPO_PKGDIR}/FILE.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_FILE" | jq . > "${HF_REPO_PKGDIR}/FILE.json"
    fi
#Size (stat)
 cd "${HF_REPO_PKGDIR}" && curl -qfsSL "https://pub.ajam.dev/utils/devscripts/jq/to_human_bytes.jq" -o "./sizer.jq"
    find "." -maxdepth 1 -exec stat {} \; | jc --monochrome --pretty --stat | jq \
    'include "./sizer"; .[] | select(.size != 0 and .size != -1 and (.file | test("\\.(jq|json|md|tmp|txt)$") | not))
    | {filename: (.file), size: (.size | tonumber | bytes)}' | jq -s 'sort_by(.filename)' | jq . > "${SYSTMP}/${HOST_TRIPLET}_SIZE"
    if [[ -f "${HF_REPO_PKGDIR}/SIZE.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/SIZE.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.size=$a_dict[.filename].size else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_SIZE" "${HF_REPO_PKGDIR}/SIZE.json" | jq . > "${SYSTMP}/${HOST_TRIPLET}_SIZE.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_SIZE.json" | jq . > "${HF_REPO_PKGDIR}/SIZE.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_SIZE" | jq . > "${HF_REPO_PKGDIR}/SIZE.json"
    fi
    rm "./sizer.jq"
#BLAKE3SUM
 cd "${HF_REPO_PKGDIR}" && find "./" -maxdepth 1 -type f |\
    grep -v -E '\.desktop$|\.DirIcon$|\.jq$|\.png$|\.txt$|\.upx$|\.version$|\.zsync$' | sort | xargs b3sum |\
    jq -R -s 'split("\n") | map(select(length > 0) | split(" +"; "g") | {filename: .[1], sum: .[0]}) | sort_by(.filename)' |\
    jq . > "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM"
    if [[ -f "${HF_REPO_PKGDIR}/BLAKE3SUM.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/BLAKE3SUM.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.sum=$a_dict[.filename].sum else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM" "${HF_REPO_PKGDIR}/BLAKE3SUM.json" | jq . > "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM.json" | jq . > "${HF_REPO_PKGDIR}/BLAKE3SUM.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM" | jq . > "${HF_REPO_PKGDIR}/BLAKE3SUM.json"
    fi
#SHA256SUM
 cd "${HF_REPO_PKGDIR}" && find "./" -maxdepth 1 -type f |\
    grep -v -E '\.desktop$|\.DirIcon$|\.jq$|\.png$|\.txt$|\.upx$|\.version$|\.zsync$' | sort | xargs sha256sum |\
    jq -R -s 'split("\n") | map(select(length > 0) | split(" +"; "g") |{filename: .[1],sum: .[0]}) | sort_by(.filename)' |\
    jq . > "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM"
    if [[ -f "${HF_REPO_PKGDIR}/SHA256SUM.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/SHA256SUM.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.sum=$a_dict[.filename].sum else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM" "${HF_REPO_PKGDIR}/SHA256SUM.json" > "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM.json" | jq . > "${HF_REPO_PKGDIR}/SHA256SUM.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM" | jq . > "${HF_REPO_PKGDIR}/SHA256SUM.json"
    fi
#Logs
pushd "$(mktemp -d)" >/dev/null
 find "${HF_REPO_PKGDIR}" -type f -regex ".*\.log$" -exec sh -c 'echo -e "\n\n" >> merged_logs.log && cat "$1" >> merged_logs.log' sh {} \;
 rsync -av --checksum --copy-links --human-readable --remove-source-files --exclude="*/" "./merged_logs.log" "${HF_REPO_PKGDIR}/BUILD.log.txt"
 sed -e '/.*github_pat.*/d' -e '/.*ghp_.*/d' -e '/.*hf_.*/d' -e '/.*access_key_id.*/d' -e '/.*secret_access_key.*/d' -e '/.*cloudflarestorage.*/d' -i "${HF_REPO_PKGDIR}/BUILD.log.txt"
popd >/dev/null 2>&1
#Sync Repo (II)
pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
 git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
 git pull origin main --force || git reset --hard "origin/main"
 find "${HF_REPO_PKGDIR}" -type f -size -3c -delete
 git sparse-checkout list
 git add --all --verbose && git commit -m "[+] PKG Built (${HOST_TRIPLET}) [Meta $(TZ='UTC' date +'%Y_%m_%d')]" ; df -h "/" 2>/dev/null
 git branch -a || git show-branch
 git push origin main
popd >/dev/null 2>&1
#-------------------------------------------------------#


#-------------------------------------------------------#
##Generate Metadata (TEMP)
pushd "${HF_REPO_PKGDIR}" >/dev/null && curl -qfsSL "https://pub.ajam.dev/utils/devscripts/jq/to_human_bytes.jq" -o "./sizer.jq"
#Generate Template
 rclone lsjson --fast-list "." | jq -r \
   --arg HOST_TRIPLET "${HOST_TRIPLET}" \
   'include "./sizer"; 
    .[] | select(.Size != 0 and .Size != -1 and (.Name | test("\\.(jq|json|md|tmp|txt)$") | not)) | 
    {
      name: (.Name),
      bin_name,
      description,
      note,
      version,
      download_url: "https://huggingface.co/datasets/Azathothas/Toolpacks-Extras/resolve/main/\($HOST_TRIPLET)/\(.Path)", 
      size: (.Size | tonumber | bytes), 
      bsum,
      shasum, 
      build_date: (.ModTime | split(".")[0]),
      src_url, 
      web_url,
      build_script,
      build_log,
      category,
      extra_bins
    }' | jq -s 'sort_by(.name)' | jq '.[]' > "${SYSTMP}/${HOST_TRIPLET}-metadata.json.tmp"
 echo "[" $(cat "${SYSTMP}/${HOST_TRIPLET}-metadata.json.tmp" | tr '\n' ' ' | sed 's/}/},/g' | sed '$ s/,$//') "]" | sed '$s/,[[:space:]]*\]/\]/' | jq . | tee "${HF_REPO_PKGDIR}/METADATA.json.tmp"
 rm "./sizer.jq"
popd >/dev/null 2>&1 
#Sync to Upstream
pushd "${HF_REPO_LOCAL}" >/dev/null 
 git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
 git add --all --verbose && git commit -m "[+] METADATA TEMP (${HOST_TRIPLET}) [$(TZ='UTC' date +'%Y_%m_%d')]" ; df -h "/" 2>/dev/null
 git branch -a || git show-branch
 git pull origin main ; git push origin main
popd >/dev/null 2>&1
#-------------------------------------------------------#

#-------------------------------------------------------#
##END & Cleanup
 echo -e "\n\n[+] Size ${HF_REPO_PKGDIR} --> $(du -sh ${HF_REPO_PKGDIR} | awk '{print $1}')"
#GH Runner
 if [ "$USER" = "runner" ] || [ "$(whoami)" = "runner" ]; then
   #Preserve Files for Artifacts
     echo -e "\n[+] Detected GH Actions... Preserving Logs & Output\n"
 else
   #Purge Files
     echo -e "\n[+] PURGING Logs & Output in 180 Seconds... (Hit Ctrl + C)\n" ; sleep 180
     rm -rf "${HF_REPO_PKGDIR}" 2>/dev/null
 fi
#VARS
unset GIT_ASKPASS GIT_TERMINAL_PROMPT
unset AR CC CXX DLLTOOL HOST_CC HOST_CXX OBJCOPY RANLIB
#EOF
#-------------------------------------------------------#


#-------------------------------------------------------#
##Generate Metadata (MAIN)
pushd "$(mktemp -d)" >/dev/null 2>&1
 curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/scripts/${HOST_TRIPLET}/gen_meta.sh" -o "./gen_meta.sh"
 dos2unix --quiet "./gen_meta.sh" ; chmod +x "./gen_meta.sh"
 bash "./gen_meta.sh"
popd >/dev/null 2>&1
#-------------------------------------------------------#