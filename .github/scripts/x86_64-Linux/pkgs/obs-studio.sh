#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/obs-studio.sh")
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
#obs-studio : FOSS cross-platform screencasting and streaming app
export BIN="obs-studio"
export BIN_ID="com.obsproject.Studio"
export SOURCE_URL="https://github.com/obsproject/obs-studio"
export BUILD_NIX_APPIMAGE="NO" #egl issues
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) $BIN :: $SOURCE_URL\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="obs-studio"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(curl -qfsSL "https://gitlab.archlinux.org/archlinux/packaging/packages/obs-studio/-/raw/main/PKGBUILD" | sed -n 's/^pkgver=//p' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       timeout 3m eget "https://github.com/ivan-hc/OBS-Studio-appimage" --tag "continuous" --asset "$(uname -m)" --asset ".AppImage" --asset "^.zsync" --to "${OWD}/${PKG_NAME}"
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
    if [ "${BUILD_NIX_APPIMAGE}" == "YES" ]; then
      ##Create NixAppImage   
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="obs"
       export NIX_PKGNAME="obs-studio"
       export PKG_NAME="${NIX_PKGNAME}.NixAppImage"
       nix bundle --bundler "github:ralismark/nix-appimage" "nixpkgs#${NIX_PKGNAME}" --log-format bar-with-logs
      #Copy
       sudo rsync -achL "${OWD}/${APP}.AppImage" "${OWD}/${PKG_NAME}.tmp"
       sudo chown -R "$(whoami):$(whoami)" "${OWD}/${PKG_NAME}.tmp" && chmod -R 755 "${OWD}/${PKG_NAME}.tmp"
       du -sh "${OWD}/${PKG_NAME}.tmp" && file "${OWD}/${PKG_NAME}.tmp"
      #HouseKeeping
       if [[ -f "${OWD}/${PKG_NAME}.tmp" ]] && [[ $(stat -c%s "${OWD}/${PKG_NAME}.tmp") -gt 1024 ]]; then
       #Version
         PKG_VERSION="$(nix derivation show "nixpkgs#${NIX_PKGNAME}" 2>&1 | grep '"version"' | awk -F': ' '{print $2}' | tr -d '"')" && export PKG_VERSION="${PKG_VERSION}"
         echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
       #Extract
         APPIMAGE="${OWD}/${PKG_NAME}.tmp" && export APPIMAGE="${APPIMAGE}" && chmod +x "${APPIMAGE}"
         "${APPIMAGE}" --appimage-extract >/dev/null && rm -f "${APPIMAGE}"
         APPIMAGE_EXTRACT="$(realpath "${OWD}/squashfs-root")" && export APPIMAGE_EXTRACT="${APPIMAGE_EXTRACT}"
       #Repack
         if [ -d "${APPIMAGE_EXTRACT}" ] && [ $(du -s "${APPIMAGE_EXTRACT}" | cut -f1) -gt 100 ]; then
          #Get Media
           pushd "${APPIMAGE_EXTRACT}" >/dev/null 2>&1
           mkdir -p "${APPIMAGE_EXTRACT}/usr/share/applications" && mkdir -p "${APPIMAGE_EXTRACT}/usr/share/metainfo"
           ENTRYPOINT_DIR="$(readlink -f entrypoint | sed -E 's|^(/nix/store/[^/]+).*|\1|' | tr -d '[:space:]')"
           ENTRYPOINT_DIR="$(echo "${APPIMAGE_EXTRACT}/${ENTRYPOINT_DIR}" | sed 's|//|/|g')" && export ENTRYPOINT_DIR="${ENTRYPOINT_DIR}"
           [ -d "${ENTRYPOINT_DIR}" ] && [[ "${ENTRYPOINT_DIR}" == "/tmp/"*"/nix/store/"* ]] || exit 1
           #usr/{applications,bash-completion,icons,metainfo,zsh}
            rsync -achLv --mkpath \
                --include="*/" \
                --include="*/applications/*.{desktop,png,svg,xml}" \
                --include="*/icons/*.{desktop,png,svg,xml}" \
                --include="*/metainfo/*.{desktop,png,svg,xml}" \
                --exclude="*" \
                "${ENTRYPOINT_DIR}/share/." "./usr/share/" && ls "./usr/share/"
          #Icon
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f,l \( -iname "*.[pP][nN][gG]" -o -iname "*.[sS][vV][gG]" \) -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" magick "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           if [[ ! -f "${APPIMAGE_EXTRACT}/${APP}.png" || $(stat -c%s "${APPIMAGE_EXTRACT}/${APP}.png") -le 3 ]]; then
             find "${APPIMAGE_EXTRACT}" -regex ".*\(128x128/apps\|256x256\)/.*${APP}.*\.\(png\|svg\)" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" magick "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           fi
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${APPIMAGE_EXTRACT}/.DirIcon"
          #Desktop
           find "${APPIMAGE_EXTRACT}" -path "*${APP%%-*}*.desktop" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} sh -c 'rsync -achL "{}" "${APPIMAGE_EXTRACT}/${APP}.desktop"'
           sed -E 's/\s+setup\s+/ /Ig' -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
           sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
          #Perms
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
          #Purge Bloatware
           echo -e "\n[+] Purging Bloatware...\n"
            O_SIZE="$(du -sh "${APPIMAGE_EXTRACT}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "O_SIZE=${O_SIZE}"
            #Locale
            find "${APPIMAGE_EXTRACT}" -type d -regex '.*share/locale*' | xargs -I {} sh -c 'rm -rvf "{}" && ln -s "/usr/share/locale" "{}"'
            rm -rvf "${APPIMAGE_EXTRACT}/usr/share/locale" 2>/dev/null
            mkdir -p "${APPIMAGE_EXTRACT}/usr/share" && ln -s "/usr/share/locale" "${APPIMAGE_EXTRACT}/usr/share/locale"
            #Static Files
            find "${APPIMAGE_EXTRACT}" -type f -regex ".*\.\(a\|cmake\|jmod\|gz\|md\|mk\|prf\|rar\|tar\|xz\|zip\)$" -print -exec rm -rvf "{}" 2>/dev/null \;
            find "${APPIMAGE_EXTRACT}" -type f -regex '.*\(LICENSE\|LICENSE\.md\|Makefile\)' -print -exec rm -rvf "{}" 2>/dev/null \;
            #Static Dirs
            find "${APPIMAGE_EXTRACT}" -type d -regex ".*\(doc/share\|/include\|llvm\|share/docs\|share/man\).*" ! -name "*${APP%%-*}*" -print -exec rm -rvf {} + 2>/dev/null
            find "${APPIMAGE_EXTRACT}" -type d -regex '.*/\(ensurepip\|example\|examples\|gcc\|i18n\|mkspecs\|__pycache__\|__pyinstaller\|test\|tests\|translation\|translations\|unit_test\|unit_tests\)' -print -exec rm -rvf "{}" 2>/dev/null \;
            #systemd (need .so)
            find "${APPIMAGE_EXTRACT}" -type d -name "*systemd*" -exec find {} -type f ! -name "*.so*" -delete \;
            P_SIZE="$(du -sh "${APPIMAGE_EXTRACT}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "P_SIZE=${P_SIZE}"
           echo -e "\n[+] Shaved off ${O_SIZE} --> ${P_SIZE}\n"
          #Copy Media
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${BINDIR}/${BIN}.icon.png"
           rsync -achL "${APPIMAGE_EXTRACT}/.DirIcon" "${BINDIR}/${BIN}.DirIcon"
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.desktop" "${BINDIR}/${BIN}.desktop"
          #Create (+Zsync)
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
      #End
       popd >/dev/null 2>&1
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