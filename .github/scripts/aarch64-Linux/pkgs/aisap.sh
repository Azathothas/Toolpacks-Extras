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
#aisap : Tool to make sandboxing AppImages easy
export BIN="aisap"
export SOURCE_URL="https://github.com/mgord9518/aisap"
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL}\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="aisap"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(gh release list --repo "${SOURCE_URL}" --order "desc" --exclude-drafts --json "tagName" | jq -r '.[0].tagName | gsub("\\s+"; "")' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       timeout 1m eget "${SOURCE_URL}" --tag "${RELEASE_TAG}" --asset "^.shImg" --asset "aarch64" --asset "AppImage" --asset "^x86_64" --asset "^amd" --asset "^.zsync" --to "${OWD}/${PKG_NAME}"
       timeout 1m eget "${SOURCE_URL}" --tag "${RELEASE_TAG}" --asset "shImg" --asset "^.zsync" --to "${OWD}/${APP}.shimg"
      #HouseKeeping 
       if [[ -f "${OWD}/${PKG_NAME}" ]] && [[ $(stat -c%s "${OWD}/${PKG_NAME}") -gt 1024 ]]; then
       #Version
         PKG_VERSION="$(echo ${RELEASE_TAG})" && export PKG_VERSION="${PKG_VERSION}"
         echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
       #Copy
         rsync -achL "${OWD}/${PKG_NAME}" "${BINDIR}/${PKG_NAME}"
         rsync -achL "${OWD}/${APP}.shimg" "${BINDIR}/${APP}.shimg"
       #Info
         find "${BINDIR}" -type f -iname "*${APP}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPIMAGE APPIMAGE_EXTRACT OFFSET OWD PKG_NAME RELEASE_TAG SHARE_DIR
       fi
fi
LOG_PATH="${BINDIR}/${BIN}.log" && export LOG_PATH="${LOG_PATH}"
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