#!/usr/bin/env bash
#self source: 
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/${HOST_TRIPLET}/pkgs/nvtop.appimage.sh") 
set +x
#-------------------------------------------------------#
#Sanity Checks
if [ "${BUILD}" != "YES" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${GIT_TERMINAL_PROMPT}" ] || \
   [ -z "${GIT_ASKPASS}" ] || \
   [ -z "${GITHUB_TOKEN}" ] || \
   [ -z "${GITLAB_TOKEN}" ] || \
   [ -z "${HF_REPO_DL}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+] Skipping Builds...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
set -x ; export TZ="UTC"
export SKIP_BUILD="NO"
#nvtop : GPU & Accelerator process monitoring for AMD, Apple, Huawei, Intel, NVIDIA and Qualcomm
export BIN="nvtop.appimage"
export BIN_ID="xxx.nvtop"
export ARCHLINUX_PKG="nvtop"
export REPOLOGY_PKG="nvtop"
export SOURCE_URL="https://github.com/Syllo/nvtop"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="nvtop"
       export PKG_NAME="${APP}.appimage"
       RELEASE_TAG="$(gh release list --repo "${SOURCE_URL}" --order "desc" --exclude-drafts --exclude-pre-releases --json "tagName" | jq -r '.[0].tagName | gsub("\\s+"; "")' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       timeout 3m eget "${SOURCE_URL}" --tag "${RELEASE_TAG}" --asset ".AppImage" --asset "^aarch64" --asset "^arm" --asset "^.zsync" --to "${OWD}/${PKG_NAME}"
      #HouseKeeping 
       if [[ -f "${OWD}/${PKG_NAME}" ]] && [[ $(stat -c%s "${OWD}/${PKG_NAME}") -gt 1024 ]]; then
       #Version
         PKG_VERSION="$(echo ${RELEASE_TAG})" && export PKG_VERSION="${PKG_VERSION}"
         echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
       #Extract
         APPIMAGE="${OWD}/${PKG_NAME}" && export APPIMAGE="${APPIMAGE}" && chmod +x "${APPIMAGE}"
         "${APPIMAGE}" --appimage-extract >/dev/null && rm -f "${APPIMAGE}"
         APPIMAGE_EXTRACT="$(realpath "${OWD}/squashfs-root")" && export APPIMAGE_EXTRACT="${APPIMAGE_EXTRACT}"
       #Repack  
         if [ -d "${APPIMAGE_EXTRACT}" ] && [ $(du -s "${APPIMAGE_EXTRACT}" | cut -f1) -gt 100 ]; then
          #Fix Media & Copy
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f,l \( -iname "*.[pP][nN][gG]" -o -iname "*.[sS][vV][gG]" \) -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" magick "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           if [[ ! -f "${APPIMAGE_EXTRACT}/${APP}.png" || $(stat -c%s "${APPIMAGE_EXTRACT}/${APP}.png") -le 3 ]]; then
             find "${APPIMAGE_EXTRACT}" -regex ".*\(128x128/apps\|256x256\)/.*${APP}.*\.\(png\|svg\)" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" magick "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           fi
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${APPIMAGE_EXTRACT}/.DirIcon"
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${BINDIR}/${BIN}.icon.png"
           rsync -achL "${APPIMAGE_EXTRACT}/.DirIcon" "${BINDIR}/${BIN}.DirIcon"
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 \( -type f -o -type l \) -iname "*.desktop" -exec rsync -achL "{}" "${APPIMAGE_EXTRACT}/${APP}.desktop" \;
           if [[ ! -f "${APPIMAGE_EXTRACT}/${APP}.desktop" || $(stat -c%s "${APPIMAGE_EXTRACT}/${APP}.desktop") -le 3 ]]; then
             find "${APPIMAGE_EXTRACT}" -path "*${APP%%-*}*.desktop" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" sh -c 'rsync -achL "{}" "${APPIMAGE_EXTRACT}/${APP}.desktop"'
           fi
           sed -E 's/\s+setup\s+/ /Ig' -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
           sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.desktop" "${BINDIR}/${BIN}.desktop"
           find "${APPIMAGE_EXTRACT}" -type f,l -iname "*appdata.xml" -print | head -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.appdata.xml" 2>/dev/null
           find "${APPIMAGE_EXTRACT}" -type f,l -iname "*metainfo.xml" -print | head -n 1 | xargs -I "{}" rsync -achLv "{}" "${BINDIR}/${BIN}.metainfo.xml" 2>/dev/null
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
           ls -lah "${APPIMAGE_EXTRACT}"
          #Pack
           cd "${OWD}" && ARCH="$(uname -m)" appimagetool --comp "zstd" \
           --mksquashfs-opt -root-owned \
           --mksquashfs-opt -no-xattrs \
           --mksquashfs-opt -noappend \
           --mksquashfs-opt -b --mksquashfs-opt "1M" \
           --mksquashfs-opt -mkfs-time --mksquashfs-opt "0" \
           --mksquashfs-opt -Xcompression-level --mksquashfs-opt "22" \
           --updateinformation "zsync|${HF_REPO_DL}/${PKG_NAME}.zsync" \
           --no-appstream "${APPIMAGE_EXTRACT}" "${BINDIR}/${PKG_NAME}"
           find "${OWD}" -maxdepth 1 -name "*.zsync" -exec rsync -achL "{}" "${BINDIR}" \;
           rm -rf "${OWD}" && popd >/dev/null 2>&1
         fi
       #Info
         find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
       fi
    #Enrichments
     pushd "$($TMPDIRS)" >/dev/null 2>&1 ; bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata.sh") || true ; popd >/dev/null 2>&1
fi
#Log
 wait ; LOG_PATH="${BINDIR}/${BIN}.log" && export LOG_PATH="${LOG_PATH}"
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset ALPINE_PKG APPBUNLE_ROOTFS APP AR ARCHLINUX_PKG APPIMAGE APPIMAGE_EXTRACT BIN_ID BUILD_FIMG BUILD_NIX_APPIMAGE CC CFLAGS CGO_ENABLED CGO_CFLAGS CXX CPPFLAGS CXXFLAGS DEBIAN_PKG DOWNLOAD_URL DLLTOOL ENTRYPOINT_DIR EXEC FIMG_BASE FLATPAK_PKG GOARCH GOOS HOST_CC HOST_CXX LDFLAGS LIBS NIX_PKGNAME OBJCOPY OFFSET OWD PKG_CONFIG_LIBDIR PKG_CONFIG_PATH PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH PKG_NAME RANLIB RELEASE_TAG REPOLOGY_PKG ROOTFS_DIR SHARE_DIR
unset SKIP_BUILD ; export BUILT="YES" ; set +x
#-------------------------------------------------------#