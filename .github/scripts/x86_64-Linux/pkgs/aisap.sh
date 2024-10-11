#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/aisap.sh")
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
#aisap : Tool to make sandboxing AppImages easy
export BIN="aisap"
export SOURCE_URL="https://github.com/mgord9518/aisap"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="aisap"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(git ls-remote --tags "${SOURCE_URL}" | awk -F/ '/tags/ && !/{}$/ {print $NF}' | grep -iv "continuous" | sort --version-sort | tail -n 1 | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
      ##Build
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder" 2>/dev/null
       docker run --privileged --net="host" --name "alpine-builder" -e GITHUB_TOKEN="${GITHUB_TOKEN}" -e RELEASE_TAG="${RELEASE_TAG}" --pull="always" "azathothas/alpine-builder:latest" \
        bash -l -c '
        #Install Deps
         apk update --no-interactive 2>/dev/null
         apk add desktop-file-utils --latest --upgrade --no-interactive 2>/dev/null
         apk add findutils --latest --upgrade --no-interactive 2>/dev/null
         eget "https://bin.ajam.dev/$(uname -m)/go-appimagetool.no_strip" --to "/usr/local/bin/go-appimagetool" && chmod +x "/usr/local/bin/go-appimagetool"
         curl -qfsSL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$(uname -m).AppImage" -o "/usr/local/bin/appimagetool" && chmod +x "/usr/local/bin/appimagetool"
        #Build
         if command -v appimagetool >/dev/null 2>&1 && command -v go-appimagetool >/dev/null 2>&1; then
          #Setup VARS
           mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
           mkdir -p "${OWD}/${APP}/${APP}.AppDir" && export APPDIR="${OWD}/${APP}/${APP}.AppDir"
           export ARCH="$(uname -m)"
           export APP="aisap"
           export APPDIR="${APP}.AppDir"
           export EXEC="${APP}"
           export OWD="$(realpath .)"
           mkdir -p "${OWD}/${APP}/${APP}.AppDir" && export APPDIR="${OWD}/${APP}/${APP}.AppDir"
           mkdir -p "${APPDIR}/usr/bin" "${APPDIR}/usr/share/metainfo" "${APPDIR}/usr/share/icons/hicolor/scalable/apps"
          #Get Src & Build
           pushd "$(mktemp -d)" >/dev/null 2>&1 && git clone --quiet --filter "blob:none" "https://github.com/mgord9518/aisap" && cd "./aisap/cmd/aisap"
           export VERSION="$(git tag --sort=-creatordate | grep -iv "continuous" | head -n 1)" ; [ -z "${VERSION}" ] && export VERSION="${RELEASE_TAG}"
           rm -rf "./go.mod" 2>/dev/null ; go mod init "github.com/mgord9518/aisap/cmd/aisap" ; go mod tidy -v
           #aisap
           #pushd "../../" >/dev/null 2>&1 && rm -rf "./go.mod" 2>/dev/null
           #go mod init "github.com/mgord9518/aisap" ; go mod tidy -v ; popd >/dev/null 2>&1
           echo "replace github.com/mgord9518/aisap => ../../" >> "./go.mod"
           #aisap/permissions
           #pushd "../../permissions" >/dev/null 2>&1 && rm -rf "./go.mod" 2>/dev/null
           #go mod init "github.com/mgord9518/aisap/permissions" ; go mod tidy -v ; popd >/dev/null 2>&1
           echo "replace github.com/mgord9518/aisap/permissions => ../../permissions" >> "./go.mod"
           #aisap/profiles 
           #pushd "../../profiles" >/dev/null 2>&1 && rm -rf "./go.mod" 2>/dev/null
           #go mod init "github.com/mgord9518/aisap/profiles" ; go mod tidy -v ; popd >/dev/null 2>&1
           echo "replace github.com/mgord9518/aisap/profiles => ../../profiles" >> "./go.mod"
           #aisap/spooky
           #pushd "../../spooky" >/dev/null 2>&1 && rm -rf "./go.mod" 2>/dev/null
           #go mod init "github.com/mgord9518/aisap/spooky" ; go mod tidy -v ; popd >/dev/null 2>&1
           echo "replace github.com/mgord9518/aisap/spooky => ../../spooky" >> "./go.mod"
           #aisap/helpers
           #pushd "../../helpers" >/dev/null 2>&1 && rm -rf "./go.mod" 2>/dev/null
           #go mod init "github.com/mgord9518/aisap/helpers" ; go mod tidy -v ; popd >/dev/null 2>&1
           echo "replace github.com/mgord9518/aisap/helpers => ../../helpers" >> "./go.mod"
           go mod tidy
           #tmpfix: https://github.com/mgord9518/aisap/issues/18
           curl -qfsSL "https://raw.githubusercontent.com/xplshn/aisap/refs/heads/main/spooky/isspooky.go" -o "../../spooky/isspooky.go"
           GOOS="linux" GOARCH="amd64" CGO_ENABLED="1" CGO_CFLAGS="-O2 -flto=auto -fPIE -fpie -static -w -pipe" go build -v -trimpath -buildmode="pie" -ldflags="-s -w -buildid= -linkmode=external -extldflags '\''-s -w -static-pie -Wl,--build-id=none'\'' -X github.com/mgord9518/aisap.Version=${VERSION}" -o "${APPDIR}/usr/bin/aisap"
           if [[ -f "${APPDIR}/usr/bin/aisap" ]] && [[ $(stat -c%s "${APPDIR}/usr/bin/aisap") -gt 100 ]]; then
             file "${APPDIR}/usr/bin/aisap" && du -sh "${APPDIR}/usr/bin/aisap"
           else
             exit 1
           fi
           popd >/dev/null 2>&1
          #Get Extra Bins
           eget "https://bin.ajam.dev/$(uname -m)/bwrap" --to "${APPDIR}/usr/bin/bwrap"
           eget "https://bin.ajam.dev/$(uname -m)/squashfuse" --to "${APPDIR}/usr/bin/squashfuse"
          #Prep AppDir 
           if [ -d "${APPDIR}" ] && [ $(du -s "${APPDIR}" | cut -f1) -gt 100 ] && [ -n "${VERSION}" ]; then
            #Assets
             cd "${APPDIR}"
             curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/appruns/aisap.AppRun" -o "${APPDIR}/AppRun"
             curl -qfsSL "https://raw.githubusercontent.com/mgord9518/aisap/refs/heads/main/resources/aisap.desktop" -o "${APPDIR}/${APP}.desktop"
             sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPDIR}/${APP}.desktop"
             sed "s/X-AppImage-Architecture=[^ ]*/X-AppImage-Architecture=$(uname -m)/" -i "${APPDIR}/${APP}.desktop"
             sed "s/X-AppImage-Version=[^ ]*/X-AppImage-Version=${VERSION}/" -i "${APPDIR}/${APP}.desktop"
             rsync -achLv "${APPDIR}/${APP}.desktop" "${APPDIR}/io.github.mgord9518.aisap.desktop"
             rsync -achLv --mkpath "${APPDIR}/${APP}.desktop" "${APPDIR}/usr/share/applications/${APP}.desktop"
             curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/icons/aisap.png" -o "${APPDIR}/${APP}.png"
             rsync -achLv "${APPDIR}/${APP}.png" "${APPDIR}/.DirIcon"
             rsync -achLv --mkpath "${APPDIR}/${APP}.png" "${APPDIR}/usr/share/icons/hicolor/scalable/apps/io.github.mgord9518.aisap.svg"
            #Perms 
             find "${APPDIR}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} + ; ls -lah "${APPDIR}"
            #Create
             cd "${OWD}" && appimagetool --comp zstd "${APPDIR}" "./${APP}.AppImage"
           fi
          #Copy
             find "." -maxdepth 1 -type f -iregex ".*\.AppImage" | xargs realpath | xargs -I {} rsync -achvL "{}" "/build-bins/${APP}.AppImage"
             file "/build-bins/"* && du -sh "/build-bins/"*
         fi
           popd >/dev/null 2>&1 ; ldd --version | head -n 1
       '
       #Copy & Meta
       docker cp "alpine-builder:/build-bins/." "$(pwd)/"
       docker stop "alpine-builder" 2>/dev/null ; docker rm "alpine-builder"
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
           sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.desktop" "${BINDIR}/${BIN}.desktop"
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
           ls -lah "${APPIMAGE_EXTRACT}"
          #Pack
           find "${APPIMAGE_EXTRACT}" -type f -iname "*${APP%%-*}*appdata.xml" -delete
           cd "${OWD}" && ARCH="$(uname -m)" appimagetool --comp "zstd" \
           --mksquashfs-opt -root-owned \
           --mksquashfs-opt -no-xattrs \
           --mksquashfs-opt -noappend \
           --mksquashfs-opt -b --mksquashfs-opt "1M" \
           --mksquashfs-opt -mkfs-time --mksquashfs-opt "0" \
           --mksquashfs-opt -Xcompression-level --mksquashfs-opt "22" \
           --updateinformation "zsync|${HF_REPO_DL}/${PKG_NAME}.zsync" \
           "${APPIMAGE_EXTRACT}" "${BINDIR}/${PKG_NAME}"
           find "${OWD}" -maxdepth 1 -name "*.zsync" -exec rsync -achL "{}" "${BINDIR}" \;
           rm -rf "${OWD}" && popd >/dev/null 2>&1
         fi
       #Info
         find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPBUNLE_ROOTFS APPIMAGE APPIMAGE_EXTRACT EXEC NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
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