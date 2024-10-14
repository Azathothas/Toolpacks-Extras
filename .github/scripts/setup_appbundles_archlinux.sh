#!/usr/bin/env bash

##THIS IS BROKEN


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
   if [ -f "/opt/ROOTFS/archlinux.ROOTFS.tar.zst" ] && [ $(du -s "/opt/ROOTFS/archlinux.ROOTFS.tar.zst" | cut -f1) -gt 100 ]; then
   #Extract
     pushd "$(mktemp -d)" >/dev/null 2>&1
     bsdtar -x -f "/opt/ROOTFS/archlinux.ROOTFS.tar.zst" -p -C "./" 2>/dev/null
     ROOTFS_TMPEXT="$(find . -maxdepth 1 -type d -exec basename {} \; | grep -Ev '^\.$' | xargs -I {} realpath {})" && export ROOTFS_TMPEXT="${ROOTFS_TMPEXT}" ; mkdir -p "${ROOTFS_DIR}"
     [ -n "${ROOTFS_TMPEXT+x}" ] && [[ "${ROOTFS_TMPEXT}" == "/tmp"* ]] && rsync -achq --delete "${ROOTFS_TMPEXT}/." "${ROOTFS_DIR}" ; popd >/dev/null 2>&1
     if [ -d "${ROOTFS_DIR}" ] && [ $(du -s "${ROOTFS_DIR}" | cut -f1) -gt 100 ]; then
       realpath "${ROOTFS_DIR}" && ls "${ROOTFS_DIR}" -lah && du -sh "${ROOTFS_DIR}"
     else
       echo -e "\n[+] AppBundle ROOTFS Setup Failed\n"
       exit 1
     fi
   #AppRun
     curl -qfsSL "${APPRUN_URL}" -o "${APPDIR}/AppRun" && chmod +x "${APPDIR}/AppRun"
   #Deps for ROOTFS
     mkdir -p "${APPDIR}/usr/bin"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bash" -o "${ROOTFS_DIR}/bin/bash"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bwrap" -o "${APPDIR}/usr/bin/bwrap"
     echo "bash" > "${ROOTFS_DIR}/entrypoint" && chmod +x "${ROOTFS_DIR}/entrypoint"
     chmod +x "${APPDIR}/usr/bin/bwrap" "${ROOTFS_DIR}/bin/bash"
     ln --symbolic --force "../../bin/bash" "${ROOTFS_DIR}/usr/bin/bash"
    ##DO NOT DO THIS 
     #sudo chmod u+s "${APPDIR}/usr/bin/bwrap"
    #Fix ID
     unlink "${ROOTFS_DIR}/var/lib/dbus/machine-id" 2>/dev/null
     rm -rvf "${ROOTFS_DIR}/etc/machine-id"
     "${APPDIR}/AppRun" --uid "0" --gid "0" systemd-machine-id-setup --print 2>/dev/null | tee "${ROOTFS_DIR}/var/lib/dbus/machine-id"
     ln --symbolic --force --relative "${ROOTFS_DIR}/var/lib/dbus/machine-id" "${ROOTFS_DIR}/etc/machine-id"
    #Fix NameServers
     unlink "${ROOTFS_DIR}/etc/resolv.conf" 2>/dev/null
     echo -e "nameserver 8.8.8.8\nnameserver 2620:0:ccc::2" > "${ROOTFS_DIR}/etc/resolv.conf"
     echo -e "nameserver 1.1.1.1\nnameserver 2606:4700:4700::1111" >> "${ROOTFS_DIR}/etc/resolv.conf"
    #Fix locale
     echo "LANG=en_US.UTF-8" > "${ROOTFS_DIR}/etc/locale.conf"
     echo "LANG=en_US.UTF-8" >> "${ROOTFS_DIR}/etc/locale.conf"
     echo "LANGUAGE=en_US:en" >> "${ROOTFS_DIR}/etc/locale.conf"
     echo "LC_ALL=en_US.UTF-8" >> "${ROOTFS_DIR}/etc/locale.conf"
     echo "en_US.UTF-8 UTF-8" >> "${ROOTFS_DIR}/etc/locale.gen"
     echo "LC_ALL=en_US.UTF-8" >> "${ROOTFS_DIR}/etc/environment"
     "${APPDIR}/AppRun" --uid "0" --gid "0" locale-gen
     "${APPDIR}/AppRun" --uid "0" --gid "0" locale-gen "en_US.UTF-8"
    #Fix os-release
     ln --symbolic --force --relative "${ROOTFS_DIR}/usr/lib/os-release" "${ROOTFS_DIR}/etc/os-release"
    #SysUpdate
     rm -rvf "${ROOTFS_DIR}/var/lib/pacman/sync/"*
     rm -rvf "${ROOTFS_DIR}/etc/pacman.d/gnupg/"*
     sed '/DownloadUser/d' -i "${ROOTFS_DIR}/etc/pacman.conf"
     sed 's/^.*Architecture\s*=.*$/Architecture = auto/' -i "${ROOTFS_DIR}/etc/pacman.conf"
     sed 's/^.*SigLevel\s*=.*$/SigLevel = Never/' -i "${ROOTFS_DIR}/etc/pacman.conf"
     #echo "Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch" >> "${ROOTFS_DIR}/etc/pacman.d/mirrorlist"
     curl -qfsSL "https://archlinux.org/mirrorlist/all/https/" | sed '/\(pkgbuild\.com\|rackspace\.com\)/s/^#//' > "${ROOTFS_DIR}/etc/pacman.d/mirrorlist"
     "${APPDIR}/AppRun" --uid "0" --gid "0" pacman -Syy archlinux-keyring pacutils --noconfirm
     "${APPDIR}/AppRun" --uid "0" --gid "0" pacman-key --init
     "${APPDIR}/AppRun" --uid "0" --gid "0" pacman-key --populate "archlinux"
     "${APPDIR}/AppRun" --uid "0" --gid "0" pacman -y --sync --refresh --refresh --sysupgrade --noconfirm --debug
     "${APPDIR}/AppRun" --uid "0" --gid "0" pacman -Scc --noconfirm
   #SysUpdate
     rm -rvf "${ROOTFS_DIR}/var/lib/pacman/sync/"*
     rm -rvf "${ROOTFS_DIR}/etc/pacman.d/gnupg/"*
     sed 's/^.*Architecture\s*=.*$/Architecture = auto/' -i "${ROOTFS_DIR}/etc/pacman.conf"
     sed 's/^.*SigLevel\s*=.*$/SigLevel = Never/' -i "${ROOTFS_DIR}/etc/pacman.conf"
     echo "Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch" >> "${ROOTFS_DIR}/etc/pacman.d/mirrorlist"
     #curl -qfsSL "https://archlinux.org/mirrorlist/all/https/" | sed '/\(pkgbuild\.com\|rackspace\.com\)/s/^#//' > "${ROOTFS_DIR}/etc/pacman.d/mirrorlist"
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman-key --init
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman-key --populate "archlinux"
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman -Syyu --debug

     touch "${ROOTFS_DIR}/var/lib/pacman/sync/extra.db"
     touch "${ROOTFS_DIR}/var/lib/pacman/sync/core.db"
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman -Sy archlinux-keyring pacutils --noconfirm

     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- reflector

     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman -Syy
     
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman -Scc --noconfirm
    #"${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman-key --refresh-keys 2>/dev/null
     sed 's/^.*SigLevel\s*=.*$/SigLevel = Never/' -i "${ROOTFS_DIR}/etc/pacman.conf"
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- pacman -Syu --noconfirm 2>/dev/null
   #Upgrade
     "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk update && apk upgrade --no-interactive 2>/dev/null
   #Static Tools (embed + host)
     sudo mkdir -p "/opt/STATIC_TOOLS" && sudo chown -R "$(whoami):$(whoami)" "/opt/STATIC_TOOLS" && sudo chmod -R 755 "/opt/STATIC_TOOLS"
     curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bwrap" -o "/opt/STATIC_TOOLS/bwrap"
     #sudo rsync -achL "/opt/STATIC_TOOLS/bwrap" "/usr/bin/bwrap" && sudo chmod +x "/usr/bin/bwrap"
     #sudo chmod u+s "/usr/bin/bwrap"
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
fi
#-------------------------------------------------------#