#!/usr/bin/env bash
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/enrich_metadata_alpine.sh")
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
   pushd "$($TMPDIRS)" >/dev/null 2>&1
   apk-static fetch "${ALPINE_PKG}" --allow-untrusted --no-cache --no-interactive --verbose --output="$(realpath .)"
   unset APK_PKG ; APK_PKG="$(find "." -maxdepth 1 -type f -name "*.apk" 2>/dev/null)" && export APK_PKG="${APK_PKG}"
   if [[ -f "${APK_PKG}" ]] && [[ $(stat -c%s "${APK_PKG}") -gt 1024 ]]; then
    #Extract
     find "." -name "*.apk" -exec tar -xvf "{}" "usr/share" 2>/dev/null \;
    #Copy
     find "." -type f -regex ".*\.appdata\.xml$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.appdata.xml" \; 2>/dev/null
     find "." -type f -regex ".*\.desktop$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.desktop" \; 2>/dev/null
     find "." -type f -regex ".*\.png$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.icon.png" 2>/dev/null
     find "." -type f -regex ".*\.svg$" -print | sort -V | tail -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.alpine.icon.svg" 2>/dev/null
    #Cleanup
     unset ALPINE_PKG APK_PKG
   fi
   rm -rf "$(realpath .)" && popd >/dev/null 2>&1
#-------------------------------------------------------#