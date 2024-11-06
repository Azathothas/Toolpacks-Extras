#!/usr/bin/env bash
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_flatpak.sh")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${BIN_ID}" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${BIN}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
fi
#CMD
if ! command -v flatpak &> /dev/null; then
    echo -e "\n[-] flatpak is NOT Installed"
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
pushd "$($TMPDIRS)" >/dev/null 2>&1 ; set -x
if [[ ! "${BIN_ID}" == xxx* ]]; then
    ##https://github.com/flathub-infra/website/blob/main/frontend/src/env.ts
    ##https://github.com/flathub-infra/website/blob/main/backend/tests/main.py
    ##https://www.postman.com/spacecraft-geoscientist-32119982/flatpak-v2/documentation/1hw9cob/flathub-v2
    curl -A "${USER_AGENT}" -qfsSL "https://flathub.org/api/v2/appstream/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.appstream.json"
    curl -A "${USER_AGENT}" -qfsSL "https://flathub.org/api/v2/stats/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.stats.json"
    curl -A "${USER_AGENT}" -qfsSL "https://flathub.org/api/v2/summary/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.info.json"
    flatpak --user remote-info flathub "${BIN_ID}" | tee "${BINDIR}/${BIN}.flatpak.txt"
   ##Screenshots
     if [[ ! -f "${BINDIR}/${BIN}.screens.txt" || $(stat -c%s "${BINDIR}/${BIN}.screens.txt") -le 3 ]]; then
       flatpak --user search "${APP}" 2>/dev/null
       FLATPAK_APPSTREAM="$(find "${HOME}/.local" -type f -name "appstream.xml" -print 2>/dev/null | xargs realpath | head -n 1)" && export FLATPAK_APPSTREAM="${FLATPAK_APPSTREAM}"
       source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_screens_appstream.sh") || true
       if [[ -f "${FLATPAK_APPSTREAM}" ]] && [[ $(stat -c%s "${FLATPAK_APPSTREAM}") -gt 10000 ]]; then
          xq --xpath "//component[id='${BIN_ID}']" "${FLATPAK_APPSTREAM}" | enrich_screens_appstream || true
       fi
     fi
fi
##Cleanup
unset FLATPAK_APPSTREAM enrich_screens_appstream ; rm -rf "$(realpath .)" && popd >/dev/null 2>&1 ; set +x
#-------------------------------------------------------#