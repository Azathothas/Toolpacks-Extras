#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/pacman.sh")
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
#pacman : ArchLinux's package manager combining a simple binary package format with an easy-to-use build system
export BIN="pacman"
export SOURCE_URL="https://gitlab.archlinux.org/pacman/pacman"
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="pacman"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(git ls-remote --tags "${SOURCE_URL}" | awk -F/ '/tags/ && !/{}$/ {print $NF}' | tr -d "[:alpha:]" | sed 's/^[^0-9]*//; s/[^0-9]*$//' | sort --version-sort | tail -n 1 | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
      ##Build
       docker stop "archlinux-builder" 2>/dev/null ; docker rm "archlinux-builder" 2>/dev/null
       docker run --privileged --net="host" --name "archlinux-builder" -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
       -e RELEASE_TAG="${RELEASE_TAG}" --pull="always" -u "runner" "azathothas/archlinux-builder:latest" \
       bash -l -c '
        #Build
         #Setup
          sudo pacman desktop-file-utils fuse3 --sync --needed --noconfirm
         #Setup VARS
          mkdir -p "/tmp/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
          export OWD="$(realpath .)"
          export ARCH="$(uname -m)"
          export APP="pacman"
          export APPDIR="${OWD}/${APP}.AppDir" && mkdir -p "${APPDIR}/tmp_bins"
         #Get Bins
          pushd "${APPDIR}" >/dev/null 2>&1
          sudo rsync -achLv "$(which makepkg)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which makepkg-template)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which pacman)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which pacman-conf)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which pacman-db-upgrade)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which pacman-key)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which repo-add)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which repo-elephant)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which repo-remove)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which testpkg)" "${APPDIR}/tmp_bins"
          sudo rsync -achLv "$(which vercmp)" "${APPDIR}/tmp_bins"
          sudo chown -R "$(whoami):$(whoami)" "${APPDIR}/tmp_bins" && chmod -R 755 "${APPDIR}/tmp_bins"
          ls -lah "${APPDIR}/tmp_bins" && du -sh "${APPDIR}/tmp_bins"
          popd >/dev/null 2>&1
         #Prep AppDir 
          [ -z "${VERSION}" ] && export VERSION="${RELEASE_TAG}"
          if [ -d "${APPDIR}" ] && [ $(du -s "${APPDIR}" | cut -f1) -gt 100 ] && [ -n "${VERSION}" ]; then
            pushd "${APPDIR}" >/dev/null 2>&1
           #Assets
            curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/appruns/sharun-generic.AppRun" -o "${APPDIR}/AppRun"
            #curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/appruns/pacman.AppRun" -o "${APPDIR}/AppRun.default"
            #sed "s/PKG_VERSION/${VERSION}/g" -i "${APPDIR}/AppRun.default"
            curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/desktops/pacman.desktop" -o "${APPDIR}/${APP}.desktop"
            sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPDIR}/${APP}.desktop"
            rsync -achLv --mkpath "${APPDIR}/${APP}.desktop" "${APPDIR}/usr/share/applications/${APP}.desktop"
            curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/icons/pacman.png" -o "${APPDIR}/${APP}.png"
            rsync -achLv "${APPDIR}/${APP}.png" "${APPDIR}/.DirIcon"
           #Fix Shell Scripts
            find "${APPDIR}" -type f -exec grep -l "^#\\!.*sh" {} + | xargs dos2unix
           #Perms
            find "${APPDIR}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} + ; ls -lah "${APPDIR}"
           #Pack
            curl -qfsSL "https://bin.ajam.dev/$(uname -m)/sharun" -o "${APPDIR}/sharun" && chmod +x "${APPDIR}/sharun"
            curl -qfsSL "https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin" -o "${APPDIR}/lib4bin" && chmod +x "${APPDIR}/lib4bin"
            if [[ -f "${APPDIR}/lib4bin" ]] && [[ -f "${APPDIR}/sharun" ]]; then
             find "${APPDIR}" -mindepth 2 -type f ! -name "sharun" -exec file -i "{}" \; | grep "application/.*executable" | cut -d":" -f1 | xargs realpath | xargs -n 1 -I "{}" "${APPDIR}/lib4bin" "{}"
            fi
           #Extras
            mkdir -p "${APPDIR}/usr/bin"
            curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/busybox/busybox" -o "${APPDIR}/bin/busybox" && chmod +x "${APPDIR}/bin/busybox"
            "${APPDIR}/bin/busybox" --install -s "${APPDIR}/bin"
            find ${APPDIR}/bin -type l -lname */bin/busybox -exec sh -c "ln -sf ./busybox $(basename {})" {} \;
            curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bash" -o "${APPDIR}/usr/bin/bash"
            find "${APPDIR}/tmp_bins" -type f -exec grep -l "^#\\!.*sh" {} + | xargs -I{} rsync -achLv --remove-source-files --mkpath "{}" "${APPDIR}/bin"
            find "${APPDIR}/bin" -type f -exec chmod +x {} \; ; ls "${APPDIR}/bin" -lah
            find "${APPDIR}/usr/bin" -type f -exec chmod +x {} \; ; ls "${APPDIR}/usr/bin" -lah
           #Create
            pushd "${OWD}" >/dev/null 2>&1
            rm -rvf "${APPDIR}/tmp_bins" 2>/dev/null
            appimagetool --comp "zstd" --no-appstream "${APPDIR}" "/tmp/build-bins/${APP}.AppImage"
            file "/tmp/build-bins/"* && du -sh "/tmp/build-bins/"*
            popd >/dev/null 2>&1 ; ldd --version | head -n 1
          fi
       '
      #Copy & Meta
       docker cp "archlinux-builder:/build-bins/." "$(pwd)/"
       docker stop "archlinux-builder" 2>/dev/null ; docker rm "archlinux-builder"
       find "." -maxdepth 1 -type f -iregex ".*\.AppImage" | xargs realpath | xargs -I {} rsync -achvL "{}" "${OWD}/${PKG_NAME}"
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
             find "${APPIMAGE_EXTRACT}" \( -path "*/128x128/apps/*${APP%%-*}*.png" -o -path "*/256x256/*${APP%%-*}*.png" \) -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" pacman "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
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
         unset APPBUNLE_ROOTFS APPIMAGE APPIMAGE_EXTRACT ENTRYPOINT_DIR EXEC NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
       fi
       #End
       popd >/dev/null 2>&1
fi
LOG_PATH="${BINDIR}/${BIN}.log" && export LOG_PATH="${LOG_PATH}"
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset APPBUNLE_ROOTFS APP APPIMAGE APPIMAGE_EXTRACT BUILD_NIX_APPIMAGE DOWNLOAD_URL EXEC NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
unset SKIP_BUILD ; export BUILT="YES"
#In case of zig polluted env
unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS LIBS OBJCOPY RANLIB
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
set +x
#-------------------------------------------------------#