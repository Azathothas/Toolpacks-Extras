#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/steam.sh")
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
#steam : A video game digital distribution service and storefront from Valve
export BIN="steam"
export BIN_ID="com.valvesoftware.Steam"
export SOURCE_URL="https://github.com/ivan-hc/Steam-appimage"
export BUILD_NIX_APPIMAGE="NO" #egl issues
export BUILD_FIMG="YES"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="steam"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(curl -qfsSL "https://gitlab.archlinux.org/archlinux/packaging/packages/steam/-/raw/main/PKGBUILD" | sed -n 's/^pkgver=//p' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       timeout 3m eget "${SOURCE_URL}" --asset "x86_64" --asset ".AppImage" --asset "^aarch64" --asset "^.zsync" --to "${OWD}/${PKG_NAME}"
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
    if [ "${BUILD_FIMG}" == "YES" ]; then
      ##Build (FlatImage)
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="steam"
       export PKG_NAME="${APP}.FlatImage"
       RELEASE_TAG="$(curl -qfsSL "https://gitlab.archlinux.org/archlinux/packaging/packages/steam/-/raw/main/PKGBUILD" | sed -n 's/^pkgver=//p' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
      #Arch FlatImage: https://github.com/ruanformigoni/flatimage/blob/master/examples/steam.sh
       rsync -achLv "/opt/FLATIMAGE/cachyos" "${OWD}/cachyos"
       export FIMG_BASE="${OWD}/cachyos"
       if [[ -f "${FIMG_BASE}" ]] && [[ $(stat -c%s "${FIMG_BASE}") -gt 1024 ]]; then
       pushd "$(mktemp -d)" >/dev/null 2>&1
       #Bootstrap
         "${FIMG_BASE}" fim-perms add "audio,dbus_user,dbus_system,gpu,home,input,media,network,udev,usb,xorg,wayland"
         "${FIMG_BASE}" fim-perms list
         "${FIMG_BASE}" fim-root pacman -Syu --noconfirm
       #Install Dependencies
         "${FIMG_BASE}" fim-root pacman freetype2 gcc-libs glxinfo lib32-freetype2 lib32-mesa lib32-gcc-libs mesa pcre xorg-server -Sy --noconfirm
         "${FIMG_BASE}" fim-root pacman xf86-video-amdgpu xf86-video-intel vulkan-intel vulkan-radeon lib32-vulkan-intel lib32-vulkan-radeon vulkan-tools -Sy --noconfirm
       #Install steam
         "${FIMG_BASE}" fim-root pacman steam -Sy --noconfirm
       #Cleanup
         "${FIMG_BASE}" fim-root pacman -Scc --noconfirm
       #ENV
         "${FIMG_BASE}" fim-exec mkdir -p "/home/steam"
         "${FIMG_BASE}" fim-env add 'USER=steam' 'HOME=/home/steam' 'XDG_CONFIG_HOME=/home/steam/.config' 'XDG_DATA_HOME=/home/steam/.local/share'
         "${FIMG_BASE}" fim-env list
         "${FIMG_BASE}" fim-boot "/usr/bin/steam"
       #Create
         "${FIMG_BASE}" fim-commit
       #Copy
         rsync -achLv "${FIMG_BASE}" "${BINDIR}/${PKG_NAME}"
       #Version
         if [[ -f "${BINDIR}/${PKG_NAME}" ]] && [[ $(stat -c%s "${BINDIR}/${PKG_NAME}") -gt 1024 ]]; then
           PKG_VERSION="$(echo ${RELEASE_TAG})" && export PKG_VERSION="${PKG_VERSION}"
           echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
         fi
       #End           
         rm -rf "$(realpath .)" && popd >/dev/null 2>&1
       fi
       #Info
         find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPBUNLE_ROOTFS APPIMAGE APPIMAGE_EXTRACT ENTRYPOINT_DIR EXEC FIMG_BASE NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
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