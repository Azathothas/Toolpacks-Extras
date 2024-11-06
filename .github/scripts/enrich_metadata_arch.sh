#!/usr/bin/env bash
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_arch.sh")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${ARCHLINUX_PKG}" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${BIN}" ] || \
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
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
 #Fetch
   pushd "$($TMPDIRS)" >/dev/null 2>&1 ; set -x
   dl_from_arch(){
     curl -qfsSL "https://archlinux.org/packages/core/$(uname -m)/${ARCHLINUX_PKG}/download/" -o "${ARCHLINUX_PKG}.tar.zst" ||\
     curl -qfsSL "https://archlinux.org/packages/extra/$(uname -m)/${ARCHLINUX_PKG}/download/" -o "${ARCHLINUX_PKG}.tar.zst" ||\
     curl -qfsSL "https://aur.archlinux.org/cgit/aur.git/snapshot//${ARCHLINUX_PKG}.tar.gz" -o "${ARCHLINUX_PKG}.tar.zst"
   }
   export -f dl_from_arch
   if [ "$(uname  -m)" == "x86_64" ]; then
     dl_from_arch
   elif [ "$(uname  -m)" == "aarch64" ]; then
     DL_URL="$(curl -kqfsSL "https://archlinuxarm.org/packages/aarch64/${ARCHLINUX_PKG}" | grep -oP 'https?://.*?\.pkg\.tar(\.gz|\.xz|\.zst)?' | grep -i "http" | tr -d '[:space:]')" && export DL_URL="${DL_URL}"
     if [ -z "${DL_URL+x}" ] || [ -z "${DL_URL}" ]; then
       dl_from_arch
     else
       curl -kqfsSL "${DL_URL}" -o "${ARCHLINUX_PKG}.tar.zst" || dl_from_arch
     fi
    fi
   unset ARCH_PKG DL_URL dl_from_arch ; ARCH_PKG="$(find "." -maxdepth 1 -type f -name "*.zst" 2>/dev/null)" && export ARCH_PKG="${ARCH_PKG}"
   if [[ -f "${ARCH_PKG}" ]] && [[ $(stat -c%s "${ARCH_PKG}") -gt 1024 ]]; then
    #Extract
     find "." -name "*.zst" -exec 7z x -mmt="$(($(nproc)+1))" -bd -y -o"./data" "{}" 2>/dev/null \;
     find "./data" -type f -exec tar -xvf "{}" 2>/dev/null \;
    #Copy
     find "." -type f -regex ".*\.appdata\.xml$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.arch.appdata.xml" 2>/dev/null
     find "." -type f -regex ".*\.metainfo\.xml$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.arch.metainfo.xml" 2>/dev/null
     find "." -type f -regex ".*\.desktop$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.arch.desktop" 2>/dev/null
     find "." -type f -iname '*.pkginfo' -print | sort -V | tail -n 1 | xargs -I "{}" cat "{}" > "${BINDIR}/${BIN}.arch.info.txt" 2>/dev/null
     find "." -type f -regex ".*\.png$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.arch.icon.png" 2>/dev/null
     find "." -type f -regex ".*\.svg$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.arch.icon.svg" 2>/dev/null
    #Enrich
     if [[ ! -f "${BINDIR}/${BIN}.icon.png" ]] || [[ $(stat -c%s "${BINDIR}/${BIN}.icon.png") -le 1024 ]]; then
        rsync -achLv "${BINDIR}/${BIN}.arch.icon.png" "${BINDIR}/${BIN}.icon.png"
        rsync -achLv "${BINDIR}/${BIN}.arch.icon.png" "${BINDIR}/${BIN}.DirIcon"
     fi
     if [[ ! -f "${BINDIR}/${BIN}.icon.svg" ]] || [[ $(stat -c%s "${BINDIR}/${BIN}.icon.svg") -le 1024 ]]; then
        rsync -achLv "${BINDIR}/${BIN}.arch.icon.svg" "${BINDIR}/${BIN}.icon.svg"
     fi
    ##Screens
     if [[ ! -f "${BINDIR}/${BIN}.screens.txt" || $(stat -c%s "${BINDIR}/${BIN}.screens.txt") -le 3 ]]; then
       source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_screens_appstream.sh") || true
       #AppData
        if [[ -f "${BINDIR}/${BIN}.arch.appdata.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.arch.appdata.xml") -gt 1024 ]]; then
           if xq --xpath "//id" "${BINDIR}/${BIN}.arch.appdata.xml" | grep -qi "${APP}"; then
               #xq --xpath "//screenshot" "${BINDIR}/${BIN}.arch.appdata.xml" | enrich_screens_appstream
                cat "${BINDIR}/${BIN}.arch.appdata.xml" | enrich_screens_appstream || true
           fi
        fi
       #Metainfo 
        if [[ -f "${BINDIR}/${BIN}.arch.metainfo.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.arch.metainfo.xml") -gt 1024 ]]; then
           if xq --xpath "//id" "${BINDIR}/${BIN}.arch.metainfo.xml" | grep -qi "${APP}"; then
               #xq --xpath "//screenshot" "${BINDIR}/${BIN}.arch.metainfo.xml" | enrich_screens_appstream
                cat "${BINDIR}/${BIN}.arch.metainfo.xml" | enrich_screens_appstream || true
           fi
        fi
       #Cleanup
        unset ARCHLINUX_PKG ARCH_PKG enrich_screens_appstream
     fi
   fi
   rm -rf "$(realpath .)" && popd >/dev/null 2>&1 ; set +x
#-------------------------------------------------------#