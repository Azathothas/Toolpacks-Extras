#!/usr/bin/env bash
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_alpine.sh")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${ALPINE_PKG}" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${BIN}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
fi
#CMD
if ! command -v apk-static &> /dev/null; then
    echo -e "\n[-] apk-static is NOT Installed"
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
   apk-static fetch "${ALPINE_PKG}" --allow-untrusted --no-cache --no-interactive --verbose --output="$(realpath .)"
   unset APK_PKG ; APK_PKG="$(find "." -maxdepth 1 -type f -name "*.apk" 2>/dev/null)" && export APK_PKG="${APK_PKG}"
   if [[ -f "${APK_PKG}" ]] && [[ $(stat -c%s "${APK_PKG}") -gt 1024 ]]; then
    #Extract
     find "." -name "*.apk" -exec 7z x -mmt="$(($(nproc)+1))" -bd -y -o"./data" "{}" 2>/dev/null \;
     find "./data" -type f -exec tar -xvf "{}" 2>/dev/null \;
    #Copy
     find "." -type f -regex ".*\.appdata\.xml$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.appdata.xml" 2>/dev/null
     find "." -type f -regex ".*\.metainfo\.xml$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.metainfo.xml" 2>/dev/null
     find "." -type f -regex ".*\.desktop$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.desktop" 2>/dev/null
     find "." -type f -iname '*.pkginfo' -print | sort -V | tail -n 1 | xargs -I "{}" cat "{}" > "${BINDIR}/${BIN}.alpine.info.txt" 2>/dev/null
     find "." -type f -regex ".*\.png$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.icon.png" 2>/dev/null
     find "." -type f -regex ".*\.svg$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.icon.svg" 2>/dev/null
    #Enrich
     if [[ ! -f "${BINDIR}/${BIN}.icon.png" ]] || [[ $(stat -c%s "${BINDIR}/${BIN}.icon.png") -le 1024 ]]; then
        rsync -achLv "${BINDIR}/${BIN}.alpine.icon.png" "${BINDIR}/${BIN}.icon.png"
        rsync -achLv "${BINDIR}/${BIN}.alpine.icon.png" "${BINDIR}/${BIN}.DirIcon"
     fi
     if [[ ! -f "${BINDIR}/${BIN}.icon.svg" ]] || [[ $(stat -c%s "${BINDIR}/${BIN}.icon.svg") -le 1024 ]]; then
        rsync -achLv "${BINDIR}/${BIN}.alpine.icon.svg" "${BINDIR}/${BIN}.icon.svg"
     fi
    ##Screens
     if [[ ! -f "${BINDIR}/${BIN}.screens.txt" || $(stat -c%s "${BINDIR}/${BIN}.screens.txt") -le 3 ]]; then
       source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_screens_appstream.sh") || true
       #AppData
        if [[ -f "${BINDIR}/${BIN}.alpine.appdata.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.alpine.appdata.xml") -gt 1024 ]]; then
           if xq --xpath "//id" "${BINDIR}/${BIN}.alpine.appdata.xml" | grep -qi "${APP}"; then
             #xq --xpath "//screenshot" "${BINDIR}/${BIN}.alpine.appdata.xml" | enrich_screens_appstream
              cat "${BINDIR}/${BIN}.alpine.appdata.xml" | enrich_screens_appstream || true
           fi
        fi
       #Metainfo 
        if [[ -f "${BINDIR}/${BIN}.alpine.metainfo.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.alpine.metainfo.xml") -gt 1024 ]]; then
           if xq --xpath "//id" "${BINDIR}/${BIN}.alpine.metainfo.xml" | grep -qi "${APP}"; then
             #xq --xpath "//screenshot" "${BINDIR}/${BIN}.alpine.metainfo.xml" | enrich_screens_appstream
              cat "${BINDIR}/${BIN}.alpine.metainfo.xml" | enrich_screens_appstream || true
           fi
        fi
       #Cleanup
        unset ALPINE_PKG APK_PKG enrich_screens_appstream
     fi
   fi
   rm -rf "$(realpath .)" && popd >/dev/null 2>&1 ; set +x
#-------------------------------------------------------#