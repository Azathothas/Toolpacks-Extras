#!/usr/bin/env bash
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
#ryujinx : Tool to make sandboxing AppImages easy
export BIN="ryujinx"
export SOURCE_URL="https://github.com/ryujinx-mirror/ryujinx"
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       export OWD="${PWD}"
       export APP="ryujinx"
       export PKG_NAME="${APP}.AppImage"
       export RELEASE_TAG="$(gh release list --repo "${SOURCE_URL}" --order "desc" --exclude-drafts --json "tagName" | jq -r '.[0].tagName | gsub("\\s+"; "")' | tr -d '[:space:]')"
       timeout 1m eget "${SOURCE_URL}" --tag "${RELEASE_TAG}" --asset "x64" --asset "AppImage" --asset "^arm64" --asset "^.zsync" --to "${OWD}/${PKG_NAME}"
      #HouseKeeping
       if [[ -f "${OWD}/${PKG_NAME}" ]] && [[ $(stat -c%s "${OWD}/${PKG_NAME}") -gt 1024 ]]; then
       #Version
         export PKG_VERSION="${RELEASE_TAG}"
         echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
       #Copy
         rsync -achL "${OWD}/${PKG_NAME}" "${BINDIR}/${PKG_NAME}"
       #Info
         find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPIMAGE APPIMAGE_EXTRACT EXEC NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG SHARE_DIR
       fi
fi
export LOG_PATH="${BINDIR}/${BIN}.log"
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset APP APPIMAGE APPIMAGE_EXTRACT BUILD_NIX_APPIMAGE DOWNLOAD_URL OFFSET OWD PKG_NAME RELEASE_TAG SHARE_DIR
unset SKIP_BUILD ; export BUILT="YES"
#In case of zig polluted env
unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS LIBS OBJCOPY RANLIB
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
set +x
#-------------------------------------------------------#
