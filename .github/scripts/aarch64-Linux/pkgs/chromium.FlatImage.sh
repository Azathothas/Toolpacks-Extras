#!/usr/bin/env bash
#self source:
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/${HOST_TRIPLET}/pkgs/chromium.flatimage.sh") 
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
export BIN="chromium.flatimage"
export BIN_ID="org.chromium.Chromium"
export REPOLOGY_PKG="chromium"
export SOURCE_URL="https://chromium.googlesource.com/chromium/src.git"
export BUILD_FIMG="YES"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
    if [ "${BUILD_FIMG}" == "YES" ]; then   
      ##Create (Alpine FlatImage)
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="chromium-alpine"
       export PKG_NAME="${APP}.flatimage"
       RELEASE_TAG="$(curl -qfsSL "https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/community/chromium/APKBUILD" | sed -n 's/^pkgver=//p' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
       rsync -achLv "/opt/FLATIMAGE/alpine" "${OWD}/alpine"
       export FIMG_BASE="${OWD}/alpine"
       if [[ -f "${FIMG_BASE}" ]] && [[ $(stat -c%s "${FIMG_BASE}") -gt 1024 ]]; then
       pushd "$(mktemp -d)" >/dev/null 2>&1
        #Bootstrap
         "${FIMG_BASE}" fim-perms set "network"
         "${FIMG_BASE}" fim-perms list
        #Build
         "${FIMG_BASE}" fim-root bash -c '
         #Sync
         apk update --no-interactive
         apk upgrade --no-interactive
         #Install Deps
         #packages="fontconfig font-awesome font-inconsolata font-noto font-terminus font-unifont"
         for pkg in $packages; do apk add "$pkg" --latest --upgrade --no-interactive ; done
         #Install
         apk add chromium --latest --upgrade --no-interactive
         apk info -L chromium
         #Cleanup
         chmod 755 "/bin/bbsuid"
         rm -rfv "/var/cache/apk/"* 2>/dev/null
         rm -rfv "/usr/share/fonts/"* 2>/dev/null
         rm -rfv "/usr/share/licenses/"* 2>/dev/null
         rm -rfv "/usr/share/locale/"* 2>/dev/null
         rm -rfv "/usr/share/man/"* 2>/dev/null
         apk cache clean
         '
        #ENV
         "${FIMG_BASE}" fim-env add 'PATH=${PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}'
         "${FIMG_BASE}" fim-env add 'USER=${USER:-$(whoami)}'
         "${FIMG_BASE}" fim-env add 'HOME=${HOME:-$(getent passwd ${USER} | cut -d: -f6)}'
         "${FIMG_BASE}" fim-env add 'XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}' \
         'XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}' \
         'XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}' \
         'XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}' \
         'XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}'
         "${FIMG_BASE}" fim-env list
         "${FIMG_BASE}" fim-bind add ro '/usr/share/fonts' '/usr/share/fonts'
         "${FIMG_BASE}" fim-bind add ro '/usr/share/fontconfig' '/usr/share/fontconfig'
         "${FIMG_BASE}" fim-bind add ro '/usr/share/icons' '/usr/share/icons'
         "${FIMG_BASE}" fim-bind add ro '/usr/share/locale' '/usr/share/locale'
         "${FIMG_BASE}" fim-bind add ro '/usr/share/themes' '/usr/share/themes'
         "${FIMG_BASE}" fim-bind list
         "${FIMG_BASE}" fim-boot "/usr/bin/chromium"
        #Create
         "${FIMG_BASE}" fim-perms add "audio,dbus_user,dbus_system,gpu,home,input,media,network,udev,usb,xorg,wayland"
         "${FIMG_BASE}" fim-perms list
         "${FIMG_BASE}" fim-env add "FIM_DIST=${APP}"
         "${FIMG_BASE}" fim-commit
        #Copy
         rsync -achLv "${FIMG_BASE}" "${BINDIR}/${PKG_NAME}"
        #Version
         if [[ -f "${BINDIR}/${PKG_NAME}" ]] && [[ $(stat -c%s "${BINDIR}/${PKG_NAME}") -gt 1024 ]]; then
           PKG_VERSION="$(echo ${RELEASE_TAG})" && export PKG_VERSION="${PKG_VERSION}"
           echo "${PKG_VERSION}" > "${BINDIR}/${PKG_NAME}.version"
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