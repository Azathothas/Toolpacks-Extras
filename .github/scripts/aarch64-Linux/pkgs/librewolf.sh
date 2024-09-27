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
#librewolf : LibreWolf Web Browser is a fork of Firefox, focused on privacy, security and freedom
export BIN="librewolf"
export SOURCE_URL="https://gitlab.com/librewolf-community/browser"
if [ "$SKIP_BUILD" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL}\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="librewolf"
       export PKG_NAME="${APP}.AppImage"
       RELEASE_TAG="$(curl -qfsSL "https://gitlab.com/api/v4/projects/24386000/releases/" | jq -r '.[0].tag_name' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       curl -qfsSL "https://gitlab.com/api/v4/projects/24386000/releases/${RELEASE_TAG}" | jq --arg ARCH "$(uname -m)" \
       -r '.assets | (.sources[]?.url, .links[]?.url) | select(. | contains($ARCH) and endswith(".AppImage"))' | tr -d '[:space:]'|\
       xargs -I "{}" curl -qfsSL "{}" -o "${OWD}/${PKG_NAME}"
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
         if [ -d "${APPIMAGE_EXTRACT}" ] && [ "$(find "${APPIMAGE_EXTRACT}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
           find "${APPIMAGE_EXTRACT}" -type f -iname "*${APP}*appdata.xml" -delete
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
         find "${BINDIR}" -type f -iname "*${APP}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPIMAGE APPIMAGE_EXTRACT OFFSET OWD PKG_NAME RELEASE_TAG SHARE_DIR
       fi
     #-------------------------------------------------------#
    export BUILD_NIX_APPIMAGE="YES"
    if [ "${BUILD_NIX_APPIMAGE}" == "YES" ]; then
      ##Create NixAppImage   
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export PKG_NAME="${APP}.NixAppImage"
       nix bundle --bundler "github:ralismark/nix-appimage" "nixpkgs#${APP}" --log-format bar-with-logs
      #Copy
       sudo rsync -achL "${OWD}/${APP}.AppImage" "${OWD}/${PKG_NAME}.tmp"
       sudo chown -R "$(whoami):$(whoami)" "${OWD}/${PKG_NAME}.tmp" && chmod -R 755 "${OWD}/${PKG_NAME}.tmp"
       du -sh "${OWD}/${PKG_NAME}.tmp" && file "${OWD}/${PKG_NAME}.tmp"
      #HouseKeeping
       if [[ -f "${OWD}/${PKG_NAME}.tmp" ]] && [[ $(stat -c%s "${OWD}/${PKG_NAME}.tmp") -gt 1024 ]]; then
       #Version
         PKG_VERSION="$(nix derivation show "nixpkgs#${APP}" 2>&1 | grep '"version"' | awk -F': ' '{print $2}' | tr -d '"')" && export PKG_VERSION="${PKG_VERSION}"
         echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
       #Extract
         APPIMAGE="${OWD}/${PKG_NAME}.tmp" && export APPIMAGE="${APPIMAGE}" && chmod +x "${APPIMAGE}"
         "${APPIMAGE}" --appimage-extract >/dev/null && rm -f "${APPIMAGE}"
         APPIMAGE_EXTRACT="$(realpath "${OWD}/squashfs-root")" && export APPIMAGE_EXTRACT="${APPIMAGE_EXTRACT}"
       #Repack
         if [ -d "${APPIMAGE_EXTRACT}" ] && [ "$(find "${APPIMAGE_EXTRACT}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
          #Get Media
           cd "${APPIMAGE_EXTRACT}"
           mkdir -p "${APPIMAGE_EXTRACT}/usr/share/applications" && mkdir -p "${APPIMAGE_EXTRACT}/usr/share/metainfo"
           SHARE_DIR="$(find "${APPIMAGE_EXTRACT}" -path "*share/*applications*${APP}*" -print -quit | sed 's|/share/applications.*||')/share" && export SHARE_DIR="${SHARE_DIR}"
           #usr/{applications,bash-completion,icons,metainfo,zsh}
            rsync -av --copy-links \
                      --include="*/" \
                      --include="*.desktop" \
                      --include="*.png" \
                      --include="*.svg" \
                      --include="*.xml" \
                      --exclude="*" \
                     "${SHARE_DIR}/" "./usr/share/" && ls "./usr/share/"
          #Icon
           find "${APPIMAGE_EXTRACT}" \( -path "*/128x128/apps/*${APP}*.png" -o -path "*/256x256/*${APP}*.png" \) -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} convert {} -resize "128x128" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           cp "${APPIMAGE_EXTRACT}/${APP}.png" "${APPIMAGE_EXTRACT}/.DirIcon"
          #Desktop
           find "${APPIMAGE_EXTRACT}" -path "*${APP}*.desktop" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} sh -c 'cp {} "${APPIMAGE_EXTRACT}/${APP}.desktop"'
           sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
          #Perms
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
          #Purge Bloatware
           echo -e "\n[+] Purging Bloatware...\n"
            O_SIZE="$(du -sh "${APPIMAGE_EXTRACT}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "O_SIZE=${O_SIZE}"
            #Headers
            find "${APPIMAGE_EXTRACT}" -type d -path "*/include*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
            #docs & manpages
            find "${APPIMAGE_EXTRACT}" -type d -path "*doc/share*" ! -name "*${APP}*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
            find "${APPIMAGE_EXTRACT}" -type d -path "*/share/docs*" ! -name "*${APP}*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
            find "${APPIMAGE_EXTRACT}" -type d -path "*/share/man*" ! -name "*${APP}*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
            #static libs
            find "${APPIMAGE_EXTRACT}" -type f -name "*.a" -print -exec rm -f {} 2>/dev/null \; 2>/dev/null
            #systemd (need .so)
            find "${APPIMAGE_EXTRACT}" -type d -name "*systemd*" -exec find {} -type f ! -name "*.so*" -delete \;
            P_SIZE="$(du -sh "${APPIMAGE_EXTRACT}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "P_SIZE=${P_SIZE}"
           echo -e "\n[+] Shaved off ${O_SIZE} --> ${P_SIZE}\n"
          #Copy Media
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${BINDIR}/${BIN}.icon.png"
           rsync -achL "${APPIMAGE_EXTRACT}/.DirIcon" "${BINDIR}/${BIN}.DirIcon"
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.desktop" "${BINDIR}/${BIN}.desktop"
          #Create (+Zsync)
           find "${APPIMAGE_EXTRACT}" -type f -iname "*${APP}*appdata.xml" -delete
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
         find "${BINDIR}" -type f -iname "*${APP}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPIMAGE APPIMAGE_EXTRACT OFFSET OWD PKG_NAME RELEASE_TAG SHARE_DIR
       fi
      #End
       popd >/dev/null 2>&1
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