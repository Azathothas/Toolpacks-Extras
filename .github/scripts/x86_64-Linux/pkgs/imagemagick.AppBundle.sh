#!/usr/bin/env bash
#self source:
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/${HOST_TRIPLET}/pkgs/imagemagick.appbundle.sh") 
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
#imagemagick : FOSS suite for editing and manipulating Digital Images & Files
export BIN="imagemagick.appbundle"
export BIN_ID="org.imagemagick"
export ARCHLINUX_PKG="imagemagick"
export APK_PKG="imagemagick"
export DEB_PKG="imagemagick"
export REPOLOGY_PKG="imagemagick"
export SOURCE_URL="https://github.com/ImageMagick/ImageMagick"
export BUILD_APPBUNDLE="YES"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
    #-------------------------------------------------------#
    if [ "${BUILD_APPBUNDLE}" == "YES" ]; then
      ##Build AppBundle
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="imagemagick"
       export ALPINE_PKG="imagemagick"
       export PKG_NAME="${APP}.dwfs.appbundle"
       RELEASE_TAG="$(curl -qfsSL "https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/community/imagemagick/APKBUILD" | sed -n 's/^pkgver=//p' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
      ##Bundle
       docker stop "appbundler-alpine" 2>/dev/null ; docker rm "appbundler-alpine" 2>/dev/null
       docker run --privileged --net="host" --name "appbundler-alpine" -e ALPINE_PKG="${ALPINE_PKG}" -e PKG_NAME="${PKG_NAME}" "appbundler-alpine" bash -l -c '
        #Setup ENV
         LOCAL_PATH="/work/APP_BUNDLES" && export PATH="${LOCAL_PATH}:${PATH}"
        #Pack 
         if [ -d "${LOCAL_PATH}" ] && [ $(du -s "${LOCAL_PATH}" | cut -f1) -gt 1000 ] && [ -n "${ALPINE_PKG}" ]; then
           mkdir -p "/build-bins" && pushd "$(mktemp -d)" >/dev/null 2>&1
           #https://github.com/xplshn/AppBundleHUB/blob/master/recipes/generic/imagemagick.sh
           pelfCreator --maintainer "toolpacks-extra" --name "${ALPINE_PKG}" --pkg-add "${ALPINE_PKG}" --entrypoint "magick" -x "usr/bin/animate usr/bin/compare usr/bin/composite usr/bin/conjure usr/bin/convert usr/bin/display usr/bin/identify usr/bin/import usr/bin/magick usr/bin/magick-script usr/bin/mogrify usr/bin/montage usr/bin/stream"
           find "." -maxdepth 1 -type f -regex ".*[Bb]undle.*" | cut -d":" -f1 | xargs realpath | xargs -I "{}" rsync -achvL "{}" "/build-bins/${PKG_NAME}"
           if [[ -f "/build-bins/${PKG_NAME}" ]] && [[ $(stat -c%s "/build-bins/${PKG_NAME}") -gt 1024 ]]; then
            apk update --no-interactive
            apk info "${ALPINE_PKG}" --all | tee "/build-bins/${PKG_NAME}.info.txt"
            timeout 10 "/build-bins/${PKG_NAME}" --pbundle_link sh -c "cp -r \$SELF_TEMPDIR/.DirIcon /build-bins/${PKG_NAME}.icon.png"
           fi
         fi
       '
      #Copy & Meta
       docker cp "appbundler-alpine:/build-bins/." "$(pwd)/"
       if [[ -f "${OWD}/${PKG_NAME}" ]] && [[ $(stat -c%s "${OWD}/${PKG_NAME}") -gt 1024 ]]; then
         find "." -maxdepth 1 -type f -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         rsync -achLv "${OWD}/${PKG_NAME}" "${BINDIR}/${PKG_NAME}"
         rsync -achLv "${OWD}/${PKG_NAME}.icon.png" "${BINDIR}/${PKG_NAME}.icon.png"
         rsync -achLv "${OWD}/${PKG_NAME}.info.txt" "${BINDIR}/${PKG_NAME}.info.txt"
         PKG_VERSION="$(echo ${RELEASE_TAG})" && export PKG_VERSION="${PKG_VERSION}"
         echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
       fi
      #Delete Containers
       docker stop "appbundler-alpine" 2>/dev/null ; docker rm "appbundler-alpine"
      #Info
       find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
       rm -rvf "$(realpath .)" 2>/dev/null ; rm -rvf "${OWD}" 2>/dev/null ; popd >/dev/null 2>&1
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