#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/dunst.sh")
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
#dunst : Lightweight and customizable notification daemon
export BIN="dunst"
export SOURCE_URL="https://github.com/dunst-project/dunst"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="dunst"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(git ls-remote --tags "${SOURCE_URL}" | awk -F/ '/tags/ && !/{}$/ {print $NF}' | tr -d "[:alpha:]" | sed 's/^[^0-9]*//; s/[^0-9]*$//' | sort --version-sort | tail -n 1 | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
      ##Build
       docker stop "holy-build-box" 2>/dev/null ; docker rm "holy-build-box" 2>/dev/null
       docker run --privileged --net="host" --name "holy-build-box" -e GITHUB_TOKEN="${GITHUB_TOKEN}" -e RELEASE_TAG="${RELEASE_TAG}" "ghcr.io/phusion/holy-build-box:edge-amd64" \
       bash -l -c '
        #Update & Setup Base
         USER="$(whoami)" && export USER="${USER}"
         HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
         SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
         yum clean all ; yum check-update
         yum install --skip-broken -y clang clang-devel clang-tools coreutils curl desktop-file-utils dos2unix findutils gettext gettext-devel git intltool moreutils python3 python3-pip.noarch tar util-linux xz wget zip
         curl -qfsSL "https://bootstrap.pypa.io/pip/$(python3 -c "import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")")/get-pip.py" -o "${SYSTMP}/get-pip.py" && python3 "${SYSTMP}/get-pip.py"
         pip install meson ninja --upgrade
        #Static Bins
         curl -qfsSL "https://bin.ajam.dev/$(uname -m)/eget" -o "/usr/local/bin/eget" && chmod +x "/usr/local/bin/eget"
         eget "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$(uname -m).AppImage" --to "/usr/local/bin/appimagetool" && chmod +x "/usr/local/bin/appimagetool"
         eget "https://bin.ajam.dev/$(uname -m)/go-appimagetool.no_strip" --to "/usr/local/bin/go-appimagetool" && chmod +x "/usr/local/bin/go-appimagetool"
         eget "https://bin.ajam.dev/$(uname -m)/gdu" --to "/usr/local/bin/gdu" && chmod +x "/usr/local/bin/gdu"
         eget "https://bin.ajam.dev/$(uname -m)/jq" --to "/usr/local/bin/jq" && chmod +x "/usr/local/bin/jq"
         eget "https://bin.ajam.dev/$(uname -m)/linuxdeploy.no_strip" --to "/usr/local/bin/linuxdeploy" && chmod +x "/usr/local/bin/linuxdeploy"
         eget "https://bin.ajam.dev/$(uname -m)/ouch" --to "/usr/local/bin/ouch" && chmod +x "/usr/local/bin/ouch"
         eget "https://bin.ajam.dev/$(uname -m)/rsync" --to "/usr/local/bin/rsync" && chmod +x "/usr/local/bin/rsync"
        #Install PKG Releated Deps
         yum install --skip-broken -y autoconf automake cairo cairo-devel dbus-devel fuse-libs gdk-pixbuf2-devel glib2-devel gtk3-devel libX11-devel libXinerama libXinerama-devel libnotify libnotify-devel libXrandr-devel libXScrnSaver libXScrnSaver-devel pango pango-devel wayland-devel
        #Activate env
         "/hbb_exe/activate-exec"
        #Build
         if command -v appimagetool >/dev/null 2>&1 && command -v go-appimagetool >/dev/null 2>&1; then
          #Setup VARS
           mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
           export ARCH="$(uname -m)"
           export APP="dunst"
           export APPDIR="${APP}.AppDir"
           export EXEC="${APP}"
           export OWD="$(realpath .)"
           mkdir -p "${OWD}/${APP}/${APP}.AppDir" && export APPDIR="${OWD}/${APP}/${APP}.AppDir"
          #Get Src & Build
           cd "${APPDIR}" && git clone --filter="blob:none" --depth="1" --quiet "https://github.com/dunst-project/dunst" && cd "./dunst"
           #git checkout "$(git tag --sort=-creatordate | grep -iv "continuous" | head -n 1)"
           export VERSION="$(git log --oneline --format="%h" | head -n 1)" ; [ -z "${VERSION}" ] && export VERSION="${RELEASE_TAG}"
           COMPLETIONS=0 SYSTEMD=0 WAYLAND=0 make PREFIX="${APPDIR}/usr" --jobs="$(($(nproc)+1))" --keep-going
           make install PREFIX="${APPDIR}/usr"
           cd "$(dirname "${APPDIR}")" && rm -rvf "${APPDIR}/dunst" "${APPDIR}/usr/share"
          #Prep AppDir 
           if [ -d "${APPDIR}" ] && [ $(du -s "${APPDIR}" | cut -f1) -gt 100 ] && [ -n "${VERSION}" ]; then
            #Assets
             curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/appruns/dunst.AppRun" -o "${APPDIR}/AppRun"
             curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/desktops/dunst.desktop" -o "${APPDIR}/${APP}.desktop"
             sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPDIR}/${APP}.desktop"
             rsync -achLv --mkpath "${APPDIR}/${APP}.desktop" "${APPDIR}/usr/share/applications/${APP}.desktop"
             curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/icons/dunst.png" -o "${APPDIR}/${APP}.png"
             rsync -achLv "${APPDIR}/${APP}.png" "${APPDIR}/.DirIcon"
            #Perms 
             find "${APPDIR}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} + ; ls -lah "${APPDIR}"
            #Temp Move Shell scripts
             find "${APPDIR}/usr" -type f -exec grep -l "^#\\!.*sh" {} + | xargs dos2unix
             rsync -achLv --remove-source-files "${APPDIR}/usr/bin/dunstctl" "./dunstctl.tmp"
            #Deploy
             #linuxdeploy --appdir="${APPDIR}" --executable="${APPDIR}/usr/bin/${EXEC}"
             go-appimagetool --standalone deploy "${APPDIR}/usr/share/applications/${APP}.desktop"
             LD_LIBRARY_PATH="" find "${APPDIR}" -type f -exec ldd "{}" 2>&1 \; | grep "=>" | grep -v "${APPDIR}"
            #Restore Shell Scripts
             rsync -achLv --remove-source-files "./dunstctl.tmp" "${APPDIR}/usr/bin/dunstctl"
            #Create
             if [ -z "${VERSION}" ]; then
                export VERSION="latest"
             fi
             go-appimagetool --standalone --overwrite "${APPDIR}"
           fi
          #Copy
             find "." -maxdepth 1 -type f -iregex ".*\.AppImage" | xargs realpath | xargs -I {} rsync -achvL "{}" "/build-bins/${APP}.AppImage"
             file "/build-bins/"* && du -sh "/build-bins/"*
           popd >/dev/null 2>&1 ; ldd --version | head -n 1
         fi
       '
      #Copy & Meta
       docker cp "holy-build-box:/build-bins/." "$(pwd)/"
       docker stop "holy-build-box" 2>/dev/null ; docker rm "holy-build-box"
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