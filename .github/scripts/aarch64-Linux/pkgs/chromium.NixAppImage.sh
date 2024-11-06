#!/usr/bin/env bash
#self source: 
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/${HOST_TRIPLET}/pkgs/chromium.nixappimage.sh") 
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
  echo -e "\n[+]Skipping Builds...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
set -x ; export TZ="UTC"
export SKIP_BUILD="NO"
#chromium : Open source web browser from Google
export BIN="chromium.nixappimage"
export BIN_ID="org.chromium.Chromium"
export REPOLOGY_PKG="chromium"
export SOURCE_URL="https://chromium.googlesource.com/chromium/src.git"
export BUILD_NIX_APPIMAGE="YES"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
    if [ "${BUILD_NIX_APPIMAGE}" == "YES" ]; then
      ##Create NixAppImage   
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="chromium"
       export NIX_PKGNAME="chromium"
       export PKG_NAME="${APP}.nixappimage"
       nix bundle --bundler "github:Azathothas/nix-appimage?ref=main" "nixpkgs#${NIX_PKGNAME}" --out-link "${OWD}/${APP}.appimage" --log-format bar-with-logs
      #Copy
       sudo rsync -achL "${OWD}/${APP}.appimage" "${OWD}/${PKG_NAME}.tmp"
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
          #De-Nix
           pushd "${APPIMAGE_EXTRACT}" >/dev/null 2>&1
           mkdir -p "${APPIMAGE_EXTRACT}/usr/share/applications" && mkdir -p "${APPIMAGE_EXTRACT}/usr/share/metainfo"
           ENTRYPOINT_DIR="$(readlink -f "${APPIMAGE_EXTRACT}/entrypoint" | sed -E 's|^(/nix/store/[^/]+).*|\1|' | tr -d '[:space:]')"
           ENTRYPOINT_DIR="$(echo "${APPIMAGE_EXTRACT}/${ENTRYPOINT_DIR}" | sed 's|//|/|g')" && export ENTRYPOINT_DIR="${ENTRYPOINT_DIR}"
           [ -d "${ENTRYPOINT_DIR}" ] && [[ "${ENTRYPOINT_DIR}" == "/tmp/"*"/nix/store/"* ]] || exit 1
           rm -rf "${APPIMAGE_EXTRACT}/usr" 2>/dev/null
           ln -sfn "$(realpath --relative-to="$(dirname "${APPIMAGE_EXTRACT}/usr")" "$ENTRYPOINT_DIR")" "${APPIMAGE_EXTRACT}/usr"
          #Fix Symlinks
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type l ! -name '*entrypoint*' -exec test -f "{}" \; -exec rsync -achvL --remove-source-files "{}" "{}.tmp" \; -exec mv "{}.tmp" "{}" \;
          #Icon
           find -L "${APPIMAGE_EXTRACT}/usr" -type f,l \
           -regex '.*\.\(png\|svg\)' \
           -not -regex '.*\(favicon\|/\(16x16\|22x22\|24x24\|32x32\|36x36\|48x48\|64x64\|72x72\|96x96\)/\).*' \
           | awk '{print length, $0}' | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" magick "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           if [[ ! -f "${APPIMAGE_EXTRACT}/${APP}.png" || $(stat -c%s "${APPIMAGE_EXTRACT}/${APP}.png") -le 3 ]]; then
             find -L "${APPIMAGE_EXTRACT}/usr" -regex ".*\(128x128/apps\|256x256\)/.*${APP}.*\.\(png\|svg\)" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I "{}" magick "{}" -background "none" -density "1000" -resize "256x256" -gravity "center" -extent "256x256" -verbose "${APPIMAGE_EXTRACT}/${APP}.png"
           fi
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${APPIMAGE_EXTRACT}/.DirIcon"
          #Desktop
           find -L "${APPIMAGE_EXTRACT}/usr" -name "*.desktop" -printf "%s %p\n" -quit | sort -n | awk 'NR==1 {print $2}' | xargs -I {} sh -c 'rsync -achL "{}" "${APPIMAGE_EXTRACT}/${APP}.desktop"'
           sed -E 's/\s+setup\s+/ /Ig' -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
           sed "s/Icon=[^ ]*/Icon=${APP}/" -i "${APPIMAGE_EXTRACT}/${APP}.desktop"
          #Perms
           find "${APPIMAGE_EXTRACT}" -maxdepth 1 -type f -exec chmod "u=rx,go=rx" {} +
          #Purge Bloatware
           echo -e "\n[+] Purging Bloatware...\n"
            O_SIZE="$(du -sh "${APPIMAGE_EXTRACT}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "O_SIZE=${O_SIZE}"
            #Locale/fonts/man
            find "${APPIMAGE_EXTRACT}" -type d -regex '.*share/\(locale\(s\)?\|font\(s\)?\|man\).*' | xargs -I {} sh -c 'rm -rvf "{}" 2>/dev/null && ln -s "/usr/share/locale" "{}" 2>/dev/null'
            mkdir -p "${APPIMAGE_EXTRACT}/usr/share"
            for dir in font fonts locale man; do
               rm -rvf "${APPIMAGE_EXTRACT}/usr/share/${dir}" 2>/dev/null
               ln -sfv "/usr/share/${dir}" "${APPIMAGE_EXTRACT}/usr/share/${dir}" 2>/dev/null
            done
            #Static Files
            find "${APPIMAGE_EXTRACT}" -type f -regex ".*\.\(a\|cmake\|jmod\|gz\|md\|mk\|prf\|rar\|tar\|xz\|zip\)$" -print -exec rm -rvf "{}" 2>/dev/null \;
            find "${APPIMAGE_EXTRACT}" -type f -regex '.*\(LICENSE\|LICENSE\.md\|Makefile\)' -print -exec rm -rvf "{}" 2>/dev/null \;
            #Static Dirs
            find "${APPIMAGE_EXTRACT}" -type d -regex ".*\(doc/share\|/include\|/nix-support\|share/docs\|share/locale\|share/locales\|share/man\).*" ! -name "*${APP%%-*}*" -print -exec rm -rvf {} + 2>/dev/null
            find "${APPIMAGE_EXTRACT}" -type d -regex '.*/\(ensurepip\|example\|examples\|gcc\|i18n\|mkspecs\|__pycache__\|__pyinstaller\|test\|tests\|translation\|translations\|unit_test\|unit_tests\)' -print -exec rm -rvf "{}" 2>/dev/null \;
            #llvm (need .so)
            find "${APPIMAGE_EXTRACT}" -type d -name "*llvm*" -exec find {} -type f ! -name "*.so*" -delete \;
            #perl (need .so)
            find "${APPIMAGE_EXTRACT}" -type d -name "*perl*" -exec find {} -type f ! -name "*.so*" -delete \;
            #systemd (need .so)
            find "${APPIMAGE_EXTRACT}" -type d -name "*systemd*" -exec find {} -type f ! -name "*.so*" -delete \;
            P_SIZE="$(du -sh "${APPIMAGE_EXTRACT}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "P_SIZE=${P_SIZE}"
           echo -e "\n[+] Shaved off ${O_SIZE} --> ${P_SIZE}\n"
          #Copy Media
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.png" "${BINDIR}/${BIN}.icon.png"
           rsync -achL "${APPIMAGE_EXTRACT}/.DirIcon" "${BINDIR}/${BIN}.DirIcon"
           rsync -achL "${APPIMAGE_EXTRACT}/${APP}.desktop" "${BINDIR}/${BIN}.desktop"
          #Create (+Zsync)
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
         fi
       #Info
         find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         rm -rvf "$(realpath .)" 2>/dev/null ; rm -rvf "${OWD}" 2>/dev/null ; popd >/dev/null 2>&1
      fi
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