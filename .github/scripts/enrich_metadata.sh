#!/usr/bin/env bash
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata.sh")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${APP}" ] || \
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
 pushd "$($TMPDIRS)" >/dev/null 2>&1 ; set -x
 #alpine enrichment: https://pkgs.alpinelinux.org/packages --> apk search ${ALPINE_PKG}
   if [[ ! -f "${BINDIR}/${BIN}.alpine.desktop" ]]; then
    ALPINE_PKG="${ALPINE_PKG:-${APP}}" bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_alpine.sh") || true &
   fi
 #arch enrichment: https://archlinux.org/packages/ --> pacman -Ss ${ARCHLINUX_PKG}
   if [[ ! -f "${BINDIR}/${BIN}.arch.desktop" ]]; then
    ARCHLINUX_PKG="${ARCHLINUX_PKG:-${APP}}" bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_arch.sh") || true &
   fi
 #debian enrichment: https://packages.debian.org/ --> apt search ${DEBIAN_PKG}
   if [[ ! -f "${BINDIR}/${BIN}.debian.desktop" ]]; then
    DEBIAN_PKG="${DEBIAN_PKG:-${APP}}" bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_debian.sh") || true &
   fi
 #flatpack enrichment
   if [[ ! -f "${BINDIR}/${BIN}.flatpak.txt" ]]; then
    bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_flatpak.sh") || true &
   fi
 #Repology
   if [[ ! -f "${BINDIR}/${BIN}.repology.json" ]]; then
    REPOLOGY_PKG="${REPOLOGY_PKG:-${APP}}" bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_repology.sh") || true &
   fi
 #Screens
   if [[ ! -f "${BINDIR}/${BIN}.screens.txt" || $(stat -c%s "${BINDIR}/${BIN}.screens.txt") -le 3 ]]; then
    #AppData
     if [[ -f "${BINDIR}/${BIN}.appdata.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.appdata.xml") -gt 1024 ]]; then
         source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_screens_appstream.sh") || true
         cat "${BINDIR}/${BIN}.appdata.xml" | enrich_screens_appstream || true
         unset enrich_screens_appstream
     fi
    #MetaInfo
     if [[ -f "${BINDIR}/${BIN}.metainfo.xml" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.metainfo.xml") -gt 1024 ]]; then
         source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_screens_appstream.sh") || true
         cat "${BINDIR}/${BIN}.metainfo.xml" | enrich_screens_appstream || true
         unset enrich_screens_appstream
     fi
   fi
##Cleanup
 find "${BINDIR}" -type f -size -3c -delete
 wait ; rm -rvf "$(realpath .)" 2>/dev/null && popd >/dev/null 2>&1 ; set +x
#-------------------------------------------------------# 