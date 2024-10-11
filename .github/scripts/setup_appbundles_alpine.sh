#!/usr/bin/env bash
## DO NOT RUN STANDALONE (DIRECTLY)
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/setup_appbundles_alpine.sh")
##
set -x
#-------------------------------------------------------#

#-------------------------------------------------------#
##setup_appbundles_alpine
setup_appbundles_alpine()
{
 #https://github.com/xplshn/pelf/blob/pelf-ng/assets/AppRun.rootfs-based
  export APPRUN_URL="https://raw.githubusercontent.com/xplshn/pelf/refs/heads/pelf-ng/assets/AppRun.rootfs-based.stable"
   if [ -f "/opt/rootfs/alpine-mini.ROOTFS.tar.gz" ] && [ $(du -s "/opt/rootfs/alpine-mini.ROOTFS.tar.gz" | cut -f1) -gt 100 ]; then
   #Extract
     bsdtar -x -f "/opt/rootfs/alpine-mini.ROOTFS.tar.gz" -p -C "${ROOTFS_DIR}" 2>/dev/null
   #AppRun
     curl -qfsSL "${APPRUN_URL}" -o "${APPDIR}/AppRun" && chmod +x "${APPDIR}/AppRun"
   #Deps for ROOTFS
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bash" -o "${ROOTFS_DIR}/usr/bin/bash" && chmod +x "${ROOTFS_DIR}/usr/bin/bash"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bwrap" -o "${APPDIR}/usr/bin/bwrap"
     sudo chmod u+s "${APPDIR}/usr/bin/bwrap"
   #fix /bin/bbsuid ---s--x--x
     sudo chmod 755 "${ROOTFS_DIR}/bin/bbsuid" 2>/dev/null
   #Fix NameServers
     echo -e "nameserver 8.8.8.8\nnameserver 2620:0:ccc::2" > "${ROOTFS_DIR}/etc/resolv.conf"
     echo -e "nameserver 1.1.1.1\nnameserver 2606:4700:4700::1111" >> "${ROOTFS_DIR}/etc/resolv.conf"
     unlink "${ROOTFS_DIR}/etc/resolv.conf" 2>/dev/null
   #Fix locale
     echo "LANG=en_US.UTF-8" > "${ROOTFS_DIR}/etc/locale.conf"
     echo "LANG=en_US.UTF-8" >> "${ROOTFS_DIR}/etc/locale.conf"
     echo "LANGUAGE=en_US:en" >> "${ROOTFS_DIR}/etc/locale.conf"
     echo "LC_ALL=en_US.UTF-8" >> "${ROOTFS_DIR}/etc/locale.conf"
   #Fix Symlinks
     find "${ROOTFS_DIR}/bin" -type l -lname '/bin/busybox' -exec sh -c 'ln -sf "${ROOTFS_DIR}/bin/busybox" "$(dirname "$1")/$(basename "$1")"' _ {} \;
     find "${ROOTFS_DIR}/usr/bin" -type l -lname '/bin/busybox' -exec sh -c 'ln -sf "${ROOTFS_DIR}/bin/busybox" "$(dirname "$1")/$(basename "$1")"' _ {} \;
   #Add Repos
     echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main" > "${ROOTFS_DIR}/etc/apk/repositories"
     echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> "${ROOTFS_DIR}/etc/apk/repositories"
   #Install Base
     #"${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk -X "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main" -U --allow-untrusted -p "${ROOTFS_DIR}" --initdb add "alpine-base"
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk -X "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main" -U --allow-untrusted --initdb add "alpine-base"
   #Upgrade
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk update && apk upgrade --no-interactive 2>/dev/null
   #Static Tools (embed + host)
     sudo mkdir -p "/opt/STATIC_TOOLS" && sudo chown -R "$(whoami):$(whoami)" "/opt/STATIC_TOOLS" && sudo chmod -R 755 "/opt/STATIC_TOOLS"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bwrap" -o "/opt/STATIC_TOOLS/bwrap"
     sudo rsync -achL "/opt/STATIC_TOOLS/bwrap" "/usr/bin/bwrap" && sudo chmod +x "/usr/bin/bwrap"
     sudo chmod u+s "/usr/bin/bwrap"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/dwarfs-tools" -o "/opt/STATIC_TOOLS/dwarfs"
     sudo rsync -achL "/opt/STATIC_TOOLS/dwarfs" "/usr/bin/dwarfs" && sudo chmod +x "/usr/bin/dwarfs"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/fuse3/fusermount3" -o "/opt/STATIC_TOOLS/fusermount"
     sudo rsync -achL "/opt/STATIC_TOOLS/fusermount" "/usr/bin/fusermount" && sudo chmod +x "/usr/bin/fusermount"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/dwarfs-tools" -o "/opt/STATIC_TOOLS/mkdwarfs"
     sudo rsync -achL "/opt/STATIC_TOOLS/mkdwarfs" "/usr/bin/mkdwarfs" && sudo chmod +x "/usr/bin/mkdwarfs"
   #Packer
     curl -qfsSL "https://raw.githubusercontent.com/xplshn/pelf/refs/heads/pelf-ng/pelf-dwfs" -o "/opt/STATIC_TOOLS/pelf-dwfs"
     dos2unix --quiet "/opt/STATIC_TOOLS/pelf-dwfs" ; chmod +x "/opt/STATIC_TOOLS/pelf-dwfs"
   fi
  ##END
  set +x
}
export -f setup_appbundles_alpine
#-------------------------------------------------------#

#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${OWD}" ] || \
   [ -z "${APP}" ] || \
   [ -z "${APPDIR}" ] || \
   [ -z "${ROOTFS_DIR}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
else
  #call
  setup_appbundles_alpine
#-------------------------------------------------------#