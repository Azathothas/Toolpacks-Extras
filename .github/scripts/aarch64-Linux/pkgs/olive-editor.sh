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
#olive-editor : Free open-source non-linear video editor
export BIN="olive-editor"
export SOURCE_URL="https://github.com/olive-editor/olive"
export BUILD_NIX_APPIMAGE="NO" #gl issues
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
      ##Fetch
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="olive"
       export PKG_NAME="${APP}-editor.AppImage"
       DOWNLOAD_URL="$(curl -qfsSL "https://api.github.com/repos/olive-editor/olive/actions/artifacts?per_page=100" -H "Authorization: Bearer ${GITHUB_TOKEN}" | jq --arg ARCH "$(uname -s)-$(uname -m)" -r '[.artifacts[] | select(.name | test($ARCH))] | sort_by(.created_at) | .[].archive_download_url' | tail -n 1)" && export DOWNLOAD_URL="${DOWNLOAD_URL}"
       RELEASE_TAG="$(curl -qfsSL "https://api.github.com/repos/olive-editor/olive/actions/artifacts?per_page=100" -H "Authorization: Bearer ${GITHUB_TOKEN}" | jq -r --arg url "${DOWNLOAD_URL}" '.artifacts[] | select(.archive_download_url == $url) | .created_at')" && export RELEASE_TAG="${RELEASE_TAG}"
       curl -qfsSL "${DOWNLOAD_URL}" -H "Authorization: Bearer ${GITHUB_TOKEN}" -o "${OWD}/${APP}.zip"
       ouch decompress "./"* --yes
       find "${OWD}" -type f -iname "*${APP%%-*}*.AppImage" -exec rsync -achL "{}" "${OWD}/${PKG_NAME}" \;
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
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f,l \( -iname "*.[pP][nN][gG]" -o -iname "*.[sS][vV][gG]" \) -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} magick {} -resize "256x256" -gravity "center" -background "none" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           if [[ ! -f "${APPIMAGE_EXTRACT}/${APP}.png" || $(stat -c%s "${APPIMAGE_EXTRACT}/${APP}.png") -le 3 ]]; then
             find "${APPIMAGE_EXTRACT}" -regex ".*\(128x128/apps\|256x256\)/.*${APP}.*\.\(png\|svg\)" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} magick {} -resize "256x256" -gravity "center" -background "none" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
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
     #-------------------------------------------------------#
    if [ "${BUILD_NIX_APPIMAGE}" == "YES" ]; then
      ##Create NixAppImage   
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="olive"
       export NIX_PKGNAME="olive-editor"
       export PKG_NAME="${NIX_PKGNAME}.NixAppImage"
       #If local repo, use
       if [ -d "/opt/nixpkgs" ] && [ $(du -s "/opt/nixpkgs" | cut -f1) -gt 100 ]; then
         pushd "/opt/nixpkgs" >/dev/null 2>&1 && git reset --hard "origin/master" && popd >/dev/null 2>&1
         PKG_NIX_DIR="$(find "/opt/nixpkgs/pkgs" -type d -name "${NIX_PKGNAME}" -print -quit | xargs realpath)" && export PKG_NIX_DIR="${PKG_NIX_DIR}"
         PKG_NIX_TMP="$(find "${PKG_NIX_DIR}" -maxdepth 1 -type f -name "*.nix" | head -n 1)" && export PKG_NIX_TMP="${PKG_NIX_TMP}"
         pushd "${PKG_NIX_DIR}" >/dev/null 2>&1
         curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/assets/nix-flakes/numtide_nix-gl-host.nix" -o "${PKG_NIX_DIR}/flake.nix"
         sed "s/PKG_NAME/${NIX_PKGNAME}/g" -i "${PKG_NIX_DIR}/flake.nix"
         sed "s/PKG_ARCH/$(uname -m)/g" -i "${PKG_NIX_DIR}/flake.nix"
         git add "${PKG_NIX_DIR}/"* >/dev/null 2>&1 && git commit -m "[+] NixAppImage ${NIX_PKGNAME}" >/dev/null 2>&1
         git stash ; nix flake update ; popd >/dev/null 2>&1
         nix bundle --bundler "github:ralismark/nix-appimage" "${PKG_NIX_DIR}" -o "${OWD}/${APP}.AppImage" --log-format bar-with-logs
         pushd "/opt/nixpkgs" >/dev/null 2>&1 && git reset --hard "origin/master" && popd >/dev/null 2>&1
         unset PKG_NIX_DIR PKG_NIX_TMP
       else
         nix bundle --bundler "github:ralismark/nix-appimage" "nixpkgs#${NIX_PKGNAME}" --log-format bar-with-logs
       fi
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
           cd "${APPIMAGE_EXTRACT}"
           mkdir -p "${APPIMAGE_EXTRACT}/usr/share/applications" && mkdir -p "${APPIMAGE_EXTRACT}/usr/share/metainfo"
           SHARE_DIR="$(find "${APPIMAGE_EXTRACT}" -path "*share/*applications*${APP%%-*}*" -print -quit | sed 's|/share/applications.*||')/share" && export SHARE_DIR="${SHARE_DIR}"
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
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f,l \( -iname "*.[pP][nN][gG]" -o -iname "*.[sS][vV][gG]" \) -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} magick {} -resize "256x256" -gravity "center" -background "none" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           if [[ ! -f "${APPIMAGE_EXTRACT}/${APP}.png" || $(stat -c%s "${APPIMAGE_EXTRACT}/${APP}.png") -le 3 ]]; then
             find "${APPIMAGE_EXTRACT}" -regex ".*\(128x128/apps\|256x256\)/.*${APP}.*\.\(png\|svg\)" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} magick {} -resize "256x256" -gravity "center" -background "none" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           fi
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${APPIMAGE_EXTRACT}/.DirIcon"
          #Desktop
           find "${APPIMAGE_EXTRACT}" -path "*${APP%%-*}*.desktop" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} sh -c 'rsync -achL "{}" "${APPIMAGE_EXTRACT}/${APP}.desktop"'
           sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
          #Perms
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
          #Purge Bloatware
           echo -e "\n[+] Purging Bloatware...\n"
            O_SIZE="$(du -sh "${APPIMAGE_EXTRACT}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "O_SIZE=${O_SIZE}"
            #Headers
            find "${APPIMAGE_EXTRACT}" -type d -path "*/include*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
            #docs & manpages
            find "${APPIMAGE_EXTRACT}" -type d -path "*doc/share*" ! -name "*${APP%%-*}*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
            find "${APPIMAGE_EXTRACT}" -type d -path "*/share/docs*" ! -name "*${APP%%-*}*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
            find "${APPIMAGE_EXTRACT}" -type d -path "*/share/man*" ! -name "*${APP%%-*}*" -print -exec rm -rf {} 2>/dev/null \; 2>/dev/null
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