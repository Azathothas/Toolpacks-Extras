#!/usr/bin/env bash
## <RUN AFTER: Building something>
## <CALLS: hf_gen_meta_src --> hf_gen_meta_temp --> hf_gen_meta_main
## <RUN BEFORE: hf_gen_meta_main>
#
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_git_ops.sh")
# source <(curl -qfsSL "https://l.ajam.dev/hf-git-ops")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${BINDIR}" ] || \
   [ -z "${GIT_TERMINAL_PROMPT}" ] || \
   [ -z "${GIT_ASKPASS}" ] || \
   [ -z "${GITHUB_TOKEN}" ] || \
   [ -z "${GITLAB_TOKEN}" ] || \
   [ -z "${HF_TOKEN}" ] || \
   [ -z "${HF_REPO_DL}" ] || \
   [ -z "${HOST_TRIPLET}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
fi
#Size
BINDIR_SIZE="$(du -sh "${BINDIR}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "BINDIR_SIZE=${BINDIR_SIZE}"
if [ ! -d "${BINDIR}" ] || [ -z "$(ls -A "${BINDIR}")" ] || [ -z "${BINDIR_SIZE}" ] || [[ "${BINDIR_SIZE}" == *K* ]]; then
     echo -e "\n[+] Broken/Empty Built "${BINDIR}" Found\n"
     exit 1
else
     echo -e "\n[+] Built "${BINDIR}" :: ${BINDIR_SIZE}\n"
     find "${BINDIR}" -maxdepth 1 -type f -exec sudo chmod +xwr {} \; 2>/dev/null
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Git OPS
hf_git_ops()
{
#Configure GIT
pushd "$(mktemp -d)" >/dev/null 2>&1
 git config --global "credential.helper" store
 git config --global "user.email" "AjamX101@gmail.com"
 git config --global "user.name" "Azathothas"
 huggingface-cli login --token "${HF_TOKEN}" --add-to-git-credential
popd >/dev/null 2>&1
#Setup Repo
pushd "$(mktemp -d)" >/dev/null 2>&1 && git clone --depth="1" --filter="blob:none" --no-checkout "https://huggingface.co/datasets/Azathothas/Toolpacks-Extras" && cd "./Toolpacks-Extras"
 git lfs install
 huggingface-cli lfs-enable-largefiles "."
 HF_REPO_LOCAL="$(realpath .)" && export HF_REPO_LOCAL="${HF_REPO_LOCAL}"
 HF_REPO_PKGDIR="$(realpath ${HF_REPO_LOCAL})/${HOST_TRIPLET}" && export HF_REPO_PKGDIR="${HF_REPO_PKGDIR}"
 mkdir -p "${HF_REPO_PKGDIR}" ; git fetch origin main ; git lfs track "./${HOST_TRIPLET}/**"
 git sparse-checkout disable
 git sparse-checkout set --no-cone --sparse-index "/METADATA.json" \
 "${HOST_TRIPLET}/*.json" "${HOST_TRIPLET}/*.log" "${HOST_TRIPLET}/*.temp" "${HOST_TRIPLET}/*.tmp" "${HOST_TRIPLET}/*.txt" "${HOST_TRIPLET}/*.yaml" "${HOST_TRIPLET}/*.yml"
 git checkout ; ls -lah "." "./${HOST_TRIPLET}"
 git sparse-checkout list
#Fetch Bins
 rsync -av --checksum --copy-links --human-readable --remove-source-files --exclude="*/" "${BINDIR}/." "${HF_REPO_PKGDIR}/"
#Sync Repo (I)
 git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
 find "${HF_REPO_PKGDIR}" -type f -size -3c -delete
 git sparse-checkout add "${HOST_TRIPLET}/**"
 git sparse-checkout list
 BINDIR_SIZE="$(du -sh "${HF_REPO_PKGDIR}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "BINDIR_SIZE=${BINDIR_SIZE}"
 git add --all --verbose && git commit -m "[+] PKG Built (${HOST_TRIPLET}) [${BINDIR_SIZE}B $(TZ='UTC' date +'%Y_%m_%d')]" ; df -h "/" 2>/dev/null
 git pull origin main ; git push origin main
popd >/dev/null 2>&1
#Gen_meta_src
 source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_gen_meta_src.sh")
 hf_gen_meta_src
#Sync Repo (II)
pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
 git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
 git pull origin main --force || git reset --hard "origin/main"
 find "${HF_REPO_PKGDIR}" -type f -size -3c -delete
 git sparse-checkout list
 git add --all --verbose && git commit -m "[+] METADATA SRC (${HOST_TRIPLET}) [Meta $(TZ='UTC' date +'%Y_%m_%d')]" ; df -h "/" 2>/dev/null
 git branch -a || git show-branch
 git push origin main
popd >/dev/null 2>&1
#Temp Metadata
source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_gen_meta_temp.sh")
hf_gen_meta_temp
#Sync Repo (III)
pushd "${HF_REPO_LOCAL}" >/dev/null 
 git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
 git add --all --verbose && git commit -m "[+] METADATA TEMP (${HOST_TRIPLET}) [$(TZ='UTC' date +'%Y_%m_%d')]" ; df -h "/" 2>/dev/null
 git branch -a || git show-branch
 git pull origin main ; git push origin main
popd >/dev/null 2>&1
##END & Cleanup
 echo -e "\n\n[+] Size ${HF_REPO_PKGDIR} --> $(du -sh ${HF_REPO_PKGDIR} | awk '{print $1}')"
 #Purge Files
 echo -e "\n[+] PURGING Logs & Output in 180 Seconds... (Hit Ctrl + C)\n" ; sleep 180
 rm -rf "${HF_REPO_LOCAL}" 2>/dev/null
}
export -f hf_git_ops
#-------------------------------------------------------#