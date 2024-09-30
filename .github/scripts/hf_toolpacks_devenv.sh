#!/usr/bin/env bash
##
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_toolpacks_devenv.sh")
# source <(curl -qfsSL "https://l.ajam.dev/hf-devenv")
##
#-------------------------------------------------------#
USER="$(whoami)" && export USER="${USER}"
HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV_VARS [CHANGE HERE]
#Name of HF Dataset/Repo, appended like: https://huggingface.co/datasets/${HF_DATASET}
HF_DATASET="Azathothas/Toolpacks-Extras" && export HF_DATASET="${HF_DATASET}"
#Where it will be cloned
HF_REPO_LOCAL="${HOME}/Toolpacks-Extras" && export HF_REPO_LOCAL="${HF_REPO_LOCAL}" 
#Usually autodetermined, bbut can be changed
HOST_TRIPLET="$(uname -m)-$(uname -s)" && export HOST_TRIPLET="${HOST_TRIPLET}"
#The direct/raw url for fetching scripts etc
HF_REPO_DL="https://huggingface.co/datasets/${HF_DATASET}/resolve/main/${HOST_TRIPLET}" && export HF_REPO_DL="${HF_REPO_DL}"
#-------------------------------------------------------#

#-------------------------------------------------------#
#Source ENV
hf_setup_env()
{
 source <(curl -qfsSL "https://raw.githubusercontent.com/${HF_DATASET}/main/.github/scripts/${HOST_TRIPLET}/env.sh")
}
export -f hf_setup_env
#hf_build_all
hf_build_all()
{
 hf_setup_env
 echo -e "\n[+] If everything looks good, Build Will continue in 10 Seconds\n" ; sleep 10 
 bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/build_debian.sh")
}
export -f hf_build_all
#check Bin dir
hf_check_bindir()
{
 echo -e "\n[+] BINDIR set --> ${BINDIR}\n"
 ls -lah "${BINDIR}"
 find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
}
export -f hf_check_bindir
#generate metadata
hf_gen_metadata()
{
  source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/$(uname -m)-$(uname -s)/gen_meta.sh")
}
export -f hf_gen_metadata
#-------------------------------------------------------#

#-------------------------------------------------------#
##Git Helpers
#clone repo
hf_clone_repo()
{
 #Configure GIT   
  git config --global "credential.helper" store
  git config --global "user.email" "AjamX101@gmail.com"
  git config --global "user.name" "Azathothas"
  huggingface-cli login --token "${HF_TOKEN}" --add-to-git-credential
 #Clone 
 pushd "${HOME}" >/dev/null 2>&1 && git clone --depth="1" --filter="blob:none" --no-checkout "https://huggingface.co/datasets/${HF_DATASET}" && cd "./Toolpacks-Extras"
 #Set Configs 
  git lfs install
  huggingface-cli lfs-enable-largefiles "."
 #Set New ENV_VARS 
  HF_REPO_LOCAL="$(realpath .)" && export HF_REPO_LOCAL="${HF_REPO_LOCAL}"
  HF_REPO_PKGDIR="$(realpath ${HF_REPO_LOCAL})/${HOST_TRIPLET}" && export HF_REPO_PKGDIR="${HF_REPO_PKGDIR}"
  mkdir -p "${HF_REPO_PKGDIR}" ; git fetch origin main ; git lfs track "./${HOST_TRIPLET}/**"
 #Fetch REQUIRED Files 
  git sparse-checkout disable
  git sparse-checkout set --no-cone --sparse-index \
  "/METADATA.json" \
  "${HOST_TRIPLET}/*.json" \
  "${HOST_TRIPLET}/*.log" \
  "${HOST_TRIPLET}/*.temp" \
  "${HOST_TRIPLET}/*.tmp" \
  "${HOST_TRIPLET}/*.txt"
  git sparse-checkout list
  git checkout ; ls -lah "." "./${HOST_TRIPLET}"
 #Exit
  popd >/dev/null 2>&1
  echo -e "\n[+] Hugging Face Upstream Repo (${HF_DATASET}) has been setup in ${HF_REPO_LOCAL}"
  echo -e "[+] Copy: rsync rsync -achL --exclude=\"*/\" \"\${BINDIR}/.\" \"\${HF_REPO_LOCAL}\""
  echo -e "[+] Sync: hf_toolpacks_devenv hf_sync_repo_cp\n"
}
export -f hf_clone_repo
#reset Repo
hf_hard_reset()
{
  pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
    git pull origin main --ff-only 2>/dev/null
    git reset --hard "origin/main"
  popd >/dev/null 2>&1
}
export -f hf_hard_reset
#Setup Repo
hf_setup_repo()
{
  if [ -d "${HF_REPO_LOCAL}" ] && [ "$(find "${HF_REPO_LOCAL}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
     #purge it
      rm -rvf "${HF_REPO_LOCAL}"
     #Reclone
      hf_clone_repo
     #Reset
      hf_hard_reset
  else
    #clone
      hf_clone_repo
    #Reset
      hf_hard_reset    
  fi
}
export -f hf_setup_repo
#Sync Repo
#Copy PKGs
hf_copy_pkgs(){
   pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
     rsync -av --checksum --copy-links --human-readable  --exclude="*/" "${BINDIR}/." "${HF_REPO_PKGDIR}/"
   popd >/dev/null 2>&1
}
export -f hf_copy_pkgs
#Move PKGs
hf_move_pkgs(){
   pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
     rsync -av --checksum --copy-links --human-readable --remove-source-files --exclude="*/" "${BINDIR}/." "${HF_REPO_PKGDIR}/"
   popd >/dev/null 2>&1
}
export -f hf_move_pkgs
#hf_sync_repo_cp
hf_sync_repo_cp()
{
   pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
     git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
     hf_copy_pkgs
     find "${HF_REPO_PKGDIR}" -type f -size -3c -delete
     git sparse-checkout add "${HOST_TRIPLET}/**"
     git sparse-checkout list
     git add --all --verbose && git commit -m "[+] Testing Dev Builds $(TZ='UTC' date +'%Y_%m_%d')]"
     git pull origin main ; git push origin main
     ls -lah "." "./${HOST_TRIPLET}"
   popd >/dev/null 2>&1
}
export -f hf_sync_repo_cp
#hf_sync_repo_mv
hf_sync_repo_mv()
{
   pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
     git pull origin main --ff-only ; git merge --no-ff -m "Merge & Sync"
     hf_move_pkgs
     find "${HF_REPO_PKGDIR}" -type f -size -3c -delete
     git add --all --verbose && git commit -m "[+] Testing Dev Builds $(TZ='UTC' date +'%Y_%m_%d')]"
     git pull origin main ; git push origin main
     ls -lah "." "./${HOST_TRIPLET}"
   popd >/dev/null 2>&1
}
export -f hf_sync_repo_mv
#cleanup& purge
hf_cleanup_purge(){
  find "${BINDIR}" -type d | xargs rm -rvf 2>/dev/null
  find "${HF_REPO_LOCAL}" -type d | xargs rm -rvf 2>/dev/null
  find "/tmp" -type d -iname "*toolpacks-extras*" 2>/dev/null -exec rm -rfv {} \; 2>/dev/null
  rm -rfv "/tmp/toolpacks" 2>/dev/null
}
export -f hf_cleanup_purge
#-------------------------------------------------------#

#-------------------------------------------------------#
hf_help()
{
  #GH 
  if [[ -n "${GITHUB_TOKEN}" ]]; then
     echo -e "\n[+] GITHUB_TOKEN is Exported"
     gh auth status
     eget --rate
  else
     echo -e "\n[-] GITHUB_TOKEN is NOT Exported"
     echo -e "Export it to avoid ratelimits\n"
     eget --rate
  fi
  #GL
  if [[ -n "${GITLAB_TOKEN}" ]]; then
     echo -e "\n[+] GITLAB_TOKEN is Exported"
     gh auth status
  else
     echo -e "\n[-] GITLAB_TOKEN is NOT Exported"
     echo -e "Export it to avoid ratelimits\n"
  fi
  #hf
  if ! command -v huggingface-cli &> /dev/null; then
      echo -e "\n[-] huggingface-cli is NOT Installed"
  fi
  if [[ -n "${HF_TOKEN}" ]]; then
     echo -e "\n[+] HF_TOKEN is Exported"
     huggingface-cli env
  else
     echo -e "\n[-] HF_TOKEN is NOT Exported"
     echo -e "Export it to use huggingface-cli\n"
  fi
  #help
  echo -e "\n ---USAGE---\n"
  echo "hf_setup_env --> (Re)Setups env & Performs Checks [Main Entrypoint]"
  echo "hf_build_all --> Run Main Build Script to Rebuild All Packages [REQUIRES: hf_setup_env]"
  echo "hf_check_bindir --> Check, List \${BINDIR} [REQUIRES: hf_setup_env]"
  echo "hf_gen_metadata --> Generate Metadata [REQUIRES: hf_setup_env]"
  echo "hf_setup_repo --> (Re)Clones Repo & Hard Resets [REQUIRES: hf_setup_env]"
  echo "hf_hard_reset --> (Re)Hard Resets Repo to Remote [REQUIRES: hf_setup_repo]"
  echo "hf_cleanup_purge --> DELETE \${BINDIR} \${HF_REPO_LOCAL} [DANGEOURS]"
  echo "hf_sync_repo_cp --> Copies All Bins to Repo & Pushes Upstream [REQUIRES: hf_setup_repo]"
  echo "hf_sync_repo_mv --> Moves All Bins to Repo & Pushes Upstream [REQUIRES: hf_setup_repo]"
  echo -e "\n ---LINKS---\n"
  echo -e "[+] Github: https://github.com/Azathothas/Toolpacks-Extras"
  echo -e "[+] HF Hub: https://huggingface.co/datasets/${HF_DATASET}"
  echo -e "[+] HF DL: ${HF_REPO_DL}/\${PATH}"
  echo -e "[+] Scripts: https://github.com/Azathothas/Toolpacks-Extras/tree/main/.github/scripts/${HOST_TRIPLET}"
  echo -e "[+] Self: https://github.com/Azathothas/Toolpacks-Extras/tree/main/.github/scripts/hf_toolpacks_devenv.sh"
  echo -e "\n"
}
export -f hf_help
if [ $# -gt 0 ]; then
    if declare -f "$1" > /dev/null; then
        "$1"
    else
        echo -e "\n[-] Function '$1' NOT Defined\n"
        hf_help
    fi
else
    hf_help
fi
#-------------------------------------------------------#