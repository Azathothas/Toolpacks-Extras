#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/imagemagick.sh")
set -x
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
  echo -e "\n[+]Skipping Builds...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
export SKIP_BUILD="YES" #Keep Stable
#imagemagick : FOSS suite for editing and manipulating Digital Images & Files
export BIN="imagemagick"
export BIN_ID=""
export SOURCE_URL="https://github.com/ImageMagick/ImageMagick"
export BUILD_APPBUNDLE="NO" #Keep stable
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="magick"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(git ls-remote --tags "${SOURCE_URL}" | awk -F/ '/tags/ && !/{}$/ {print $NF}' | tr -d "[:alpha:]" | sed 's/^[^0-9]*//; s/[^0-9]*$//' | sort --version-sort | tail -n 1 | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       #https://github.com/ImageMagick/ImageMagick/issues/7689
       #Official binary is gcc: https://imagemagick.org/archive/binaries/magick
       #timeout 3m eget "${SOURCE_URL}" --tag "${RELEASE_TAG}" --asset "gcc" --asset "aarch64" --asset ".AppImage" --asset "^x86_64" --asset "^.zsync" --to "${OWD}/${PKG_NAME}"
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
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
           ls -lah "${APPIMAGE_EXTRACT}"
          #Pack
           #find "${APPIMAGE_EXTRACT}" -type f -iname "*${APP%%-*}*appdata.xml" -delete
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
         unset APPBUNLE_ROOTFS APPIMAGE APPIMAGE_EXTRACT ENTRYPOINT_DIR EXEC FIMG_BASE NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
       fi
     #-------------------------------------------------------#
    if [ "${BUILD_APPBUNDLE}" == "YES" ]; then
      ##Build AppBundle
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="magick"
       export PKG_NAME="${APP}.dwfs.AppBundle"
       APPDIR="$(realpath .)/${APP}.AppDir" && export APPDIR="${APPDIR}"
       export ROOTFS_DIR="${APPDIR}/rootfs" && mkdir -p "${ROOTFS_DIR}"
       RELEASE_TAG="$(curl -qfsSL "https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/community/imagemagick/APKBUILD" | sed -n 's/^pkgver=//p' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       BIN_ID="$(echo "${APP}_${RELEASE_TAG:-$(date +%Y_%m_%d)}_${PKG_NAME}" | tr -d '[:space:]')" && export BIN_ID="${BIN_ID}"
      #Setup Bundle
       curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/setup_appbundles_alpine.sh" | bash
      #Prep AppDir 
       if [ -d "${APPDIR}" ] && [ $(du -s "${APPDIR}" | cut -f1) -gt 100 ]; then
         #Bootstrap
           "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk update && apk upgrade --no-interactive 2>/dev/null
         #Packages
           "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk add imagemagick --no-interactive 2>/dev/null
           "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- magick --version 2>/dev/null
         #Entrypoint
           echo "magick" > "${ROOTFS_DIR}/entrypoint" && chmod +x "${ROOTFS_DIR}/entrypoint"
         #Fix Symlinks
           find "${ROOTFS_DIR}/bin" -type l -lname '/bin/busybox' -exec sh -c 'ln -sf "${ROOTFS_DIR}/bin/busybox" "$(dirname "$1")/$(basename "$1")"' _ {} \;
           find "${ROOTFS_DIR}/usr/bin" -type l -lname '/bin/busybox' -exec sh -c 'ln -sf "${ROOTFS_DIR}/bin/busybox" "$(dirname "$1")/$(basename "$1")"' _ {} \;
         #Media
           curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/desktops/imagemagick.desktop" -o "${APPDIR}/${APP}.desktop"
           sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPDIR}/${APP}.desktop"
           curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/icons/imagemagick.png" -o "${APPDIR}/${APP}.icon.png"
           magick "${APPDIR}/${APP}.icon.png" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPDIR}/${APP}.icon.png"
           rsync -achLv "${APPDIR}/${APP}.icon.png" "${APPDIR}/${APP}.DirIcon"
         #Copy Media
           [ ! -e "${BINDIR}/${BIN}.desktop" ] && rsync -achLv "${APPDIR}/${APP}.desktop" "${BINDIR}/${BIN}.desktop"
           [ ! -e "${BINDIR}/${BIN}.icon.png" ] && rsync -achLv "${APPDIR}/${APP}.icon.png" "${BINDIR}/${BIN}.icon.png"
           [ ! -e "${BINDIR}/${BIN}.DirIcon" ] && rsync -achLv "${APPDIR}/${APP}.DirIcon" "${BINDIR}/${BIN}.DirIcon"
         #Version
           PKG_VERSION="$(echo ${RELEASE_TAG})" && export PKG_VERSION="${PKG_VERSION}"
           echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
         #Perms
           find "${APPDIR}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
         #Pack
          if [ -d "/opt/STATIC_TOOLS" ] && [ $(du -s "/opt/STATIC_TOOLS" | cut -f1) -gt 100 ]; then
              "/opt/STATIC_TOOLS/pelf-dwfs" --add-appdir "${APPDIR}" "${BIN_ID}" --output-to "${OWD}/${PKG_NAME}" --embed-static-tools --static-tools-dir "/opt/STATIC_TOOLS" \
              --compression "--max-lookback-blocks=5 --categorize=pcmaudio --compression pcmaudio/waveform::flac:level=8"
          fi
         #Copy
           rsync -achLv "${OWD}/${PKG_NAME}" "${BINDIR}/${PKG_NAME}"
           popd >/dev/null 2>&1
       #Info
         find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPBUNLE_ROOTFS APPIMAGE APPIMAGE_EXTRACT ENTRYPOINT_DIR EXEC FIMG_BASE NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
       fi
    fi
fi
#Enrichments
pushd "$($TMPDIRS)" >/dev/null 2>&1
#alpine enrichment: https://pkgs.alpinelinux.org/packages --> apk search ${ALPINE_PKG}
 ALPINE_PKG="${BIN}" bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/enrich_metadata_alpine.sh") || true &
#arch enrichment: https://archlinux.org/packages/ --> pacman -Ss ${ARCHLINUX_PKG}
 ARCHLINUX_PKG="${BIN}" bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/enrich_metadata_arch.sh") || true &
#debian enrichment: https://packages.debian.org/ --> apt search ${DEBIAN_PKG}
 DEBIAN_PKG="${BIN}" bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/enrich_metadata_debian.sh") || true &
#flatpack enrichment
if [ -n "${BIN_ID+x}" ] && [ -n "${BIN_ID}" ]; then
 curl -qfsSL "https://flathub.org/api/v2/appstream/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.appstream.json" &
 curl -qfsSL "https://flathub.org/api/v2/stats/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.stats.json" &
 curl -qfsSL "https://flathub.org/api/v2/summary/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.info.json" &
 flatpak --user remote-info flathub "${BIN_ID}" | tee "${BINDIR}/${BIN}.flatpak.txt" &
fi
#Log
 wait ; LOG_PATH="${BINDIR}/${BIN}.log" && export LOG_PATH="${LOG_PATH}"
rm -rvf "$(realpath .)" 2>/dev/null && popd >/dev/null 2>&1
#-------------------------------------------------------#
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset APPBUNLE_ROOTFS APP BIN_ID APPIMAGE APPIMAGE_EXTRACT BUILD_FIMG BUILD_NIX_APPIMAGE DOWNLOAD_URL EXEC NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
unset SKIP_BUILD ; export BUILT="YES"
#In case of zig polluted env
unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS LIBS OBJCOPY RANLIB
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
set +x
#-------------------------------------------------------#