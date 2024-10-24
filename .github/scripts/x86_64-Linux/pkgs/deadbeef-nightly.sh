#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/deadbeef-nightly.sh")
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
export SKIP_BUILD="NO"
#deadbeef : A Modular (Extensible with Plugins) Audio Player that can play & convert almost all Audio Formats
export BIN="deadbeef"
export BIN_ID=""
export SOURCE_URL="https://github.com/DeaDBeeF-Player/deadbeef"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="deadbeef"
       export PKG_NAME="${APP}-nightly.AppImage"
       export ARCH="$(uname -m)"
       export EXEC="${APP}"
       export APPIMAGE="${OWD}/${PKG_NAME}"
       export APPIMAGE_EXTRACT="${OWD}/${APP}/${APP}.APPIMAGE_EXTRACT"
       RELEASE_TAG="$(curl -qfsSL "https://sourceforge.net/projects/deadbeef/rss?path=/travis/linux/master" | grep -oP '(?<=<pubDate>).*?(?=</pubDate>)' | xargs -I {} date -d "{}" +"%Y_%m_%d" | sort | uniq -d | head -n 1 | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
      #Build APPIMAGE_EXTRACT
       pushd "$(mktemp -d)" >/dev/null 2>&1
         mkdir -p "${APPIMAGE_EXTRACT}"
         DL_LINK="$(curl -qfsSL "https://sourceforge.net/projects/deadbeef/files/travis/linux/master/" | grep -o 'href="[^"]*"' | sed 's/href="//;s/"$//' | grep 'static.*\.tar\.bz2' | grep -E '^https.*x86_64' | sort | tail -n 1 | tr -d "[:space:]")" && export DL_LINK="${DL_LINK}"
         curl -qfsSL "${DL_LINK}" -o "./deadbeef.tar.bz2"
         [ ! -f "./deadbeef.tar.bz2" ] || [ $(stat -c%s "./deadbeef.tar.bz2") -le 10240 ] && exit 1
         ouch decompress "./"* --yes
         EXT_DIR="$(find "." -maxdepth 1 -type d ! -name "." ! -name ".." -print -quit | xargs realpath)"
         [ ! -d "${EXT_DIR}" ] || [[ "${EXT_DIR}" == "/" ]] && exit 1
         rsync -achLv --mkpath "${EXT_DIR}/." "${APPIMAGE_EXTRACT}/usr/bin/"
         ls "${APPIMAGE_EXTRACT}/usr/bin/" -lah ; unset ARCH DL_LINK EXT_DIR
       popd "$(mktemp -d)" >/dev/null 2>&1 ; cd "${OWD}/${APP}"
       #Version
         PKG_VERSION="$(echo ${RELEASE_TAG})" && export PKG_VERSION="${PKG_VERSION}"
         echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
       #Repack
         if [ -d "${APPIMAGE_EXTRACT}" ] && [ $(du -s "${APPIMAGE_EXTRACT}" | cut -f1) -gt 100 ]; then
          #Get Assets
           curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/appruns/deadbeef-stable.AppRun" -o "${APPIMAGE_EXTRACT}/AppRun"
           #https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in
           curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/desktops/deadbeef-stable.desktop" -o "${APPIMAGE_EXTRACT}/${APP}.desktop"
           rsync -achLv --mkpath "${APPIMAGE_EXTRACT}/${APP}.desktop" "${APPIMAGE_EXTRACT}/usr/share/applications/${APP}.desktop"
           #https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg
           curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/icons/deadbeef-stable.png" -o "${APPIMAGE_EXTRACT}/${APP}.png"
           rsync -achLv "${APPIMAGE_EXTRACT}/${APP}.png" "${APPIMAGE_EXTRACT}/.DirIcon"
          #Fix Media & Copy
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 \( -type f -o -type l \) -iname "*.png" -exec rsync -achL "{}" "${APPIMAGE_EXTRACT}/${APP}.png" \;
           if [[ ! -f "${APPIMAGE_EXTRACT}/${APP}.png" || $(stat -c%s "${APPIMAGE_EXTRACT}/${APP}.png") -le 3 ]]; then
             find "${APPIMAGE_EXTRACT}" \( -path "*/128x128/apps/*${APP%%-*}*.png" -o -path "*/256x256/*${APP%%-*}*.png" \) -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" magick "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
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
          #Fix Shell Scripts
           find "${APPIMAGE_EXTRACT}/usr" -type f -exec grep -l "^#\\!.*sh" {} + | xargs dos2unix
          #Perms 
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec sudo chmod "u=rx,go=rx" {} +
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
       #End
       popd >/dev/null 2>&1
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