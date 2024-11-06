#!/usr/bin/env bash
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_debian.sh")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${DEBIAN_PKG}" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${BIN}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
fi
#CMD
if ! command -v apt-get &> /dev/null; then
    echo -e "\n[-] apt-get is NOT Installed"
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
   apt-get download "${DEBIAN_PKG}" -y
   unset DEB_PKG ; DEB_PKG="$(find "." -maxdepth 1 -type f -name "*.deb" 2>/dev/null)" && export DEB_PKG="${DEB_PKG}"
   if [[ -f "${DEB_PKG}" ]] && [[ $(stat -c%s "${DEB_PKG}") -gt 1024 ]]; then
    #Extract
     find "." -name "*.deb" -exec 7z x -mmt="$(($(nproc)+1))" -bd -y -o"./data" "{}" 2>/dev/null \;
     find "./data" -type f -exec tar -xvf "{}" 2>/dev/null \;
    #Copy
     find "." -type f -regex ".*\.appdata\.xml$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.debian.appdata.xml" 2>/dev/null
     find "." -type f -regex ".*\.metainfo\.xml$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.debian.metainfo.xml" 2>/dev/null
     find "." -type f -regex ".*\.desktop$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.debian.desktop" 2>/dev/null
     find "." -type f -regex ".*\.png$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.debian.icon.png" 2>/dev/null
     find "." -type f -regex ".*\.svg$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.debian.icon.svg" 2>/dev/null
    #Enrich
     if [[ ! -f "${BINDIR}/${BIN}.icon.png" ]] || [[ $(stat -c%s "${BINDIR}/${BIN}.icon.png") -le 1024 ]]; then
        rsync -achLv "${BINDIR}/${BIN}.debian.icon.png" "${BINDIR}/${BIN}.icon.png"
        rsync -achLv "${BINDIR}/${BIN}.debian.icon.png" "${BINDIR}/${BIN}.DirIcon"
     fi
     if [[ ! -f "${BINDIR}/${BIN}.icon.svg" ]] || [[ $(stat -c%s "${BINDIR}/${BIN}.icon.svg") -le 1024 ]]; then
        rsync -achLv "${BINDIR}/${BIN}.debian.icon.svg" "${BINDIR}/${BIN}.icon.svg"
     fi
    ##Screens
     if [[ ! -f "${BINDIR}/${BIN}.screens.txt" || $(stat -c%s "${BINDIR}/${BIN}.screens.txt") -le 3 ]]; then
       source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_screens_appstream.sh") || true
      #AppData
       if [[ -f "${BINDIR}/${BIN}.debian.appdata.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.debian.appdata.xml") -gt 1024 ]]; then
          if xq --xpath "//id" "${BINDIR}/${BIN}.debian.appdata.xml" | grep -qi "${APP}"; then
            #xq --xpath "//screenshot" "${BINDIR}/${BIN}.debian.appdata.xml" | enrich_screens_appstream
             cat "${BINDIR}/${BIN}.debian.appdata.xml" | enrich_screens_appstream || true
          fi
       fi
      #Metainfo 
       if [[ -f "${BINDIR}/${BIN}.debian.metainfo.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.debian.metainfo.xml") -gt 1024 ]]; then
          if xq --xpath "//id" "${BINDIR}/${BIN}.debian.metainfo.xml" | grep -qi "${APP}"; then
            #xq --xpath "//screenshot" "${BINDIR}/${BIN}.debian.metainfo.xml" | enrich_screens_appstream
             cat "${BINDIR}/${BIN}.debian.metainfo.xml" | enrich_screens_appstream || true
          fi
       fi
      #Cleanup
       unset DEBIAN_PKG DEB_PKG enrich_screens_appstream
     fi
   fi
   rm -rf "$(realpath .)" && popd >/dev/null 2>&1 ; set +x
#-------------------------------------------------------#