#!/usr/bin/env bash
## DO NOT SOURCE or RUN DIRECTLY
#Needs: bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
#And more
#self:
# bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main/.github/scripts/setup_appbundles_archlinux.sh")
set -x
#https://github.com/xplshn/pelf/blob/pelf-ng/assets/AppRun.rootfs-based
export APPRUN_URL="https://raw.githubusercontent.com/xplshn/pelf/refs/heads/pelf-ng/assets/AppRun.rootfs-based.stable"
#export APPRUN_URL="https://raw.githubusercontent.com/xplshn/pelf/ec1b6f05fca47ef93b67eda606fa249296b24f56/assets/AppRun.rootfs-based"
export ENTRYPOINT="bash"
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
USER="$(whoami)" && export USER="${USER}"
HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
USER_AGENT="$(curl -qfsSL 'https://pub.ajam.dev/repos/Azathothas/Wordlists/Misc/User-Agents/ua_chrome_macos_latest.txt')" && export USER_AGENT="${USER_AGENT}"
#-------------------------------------------------------#

#-------------------------------------------------------#
##ArchLinux ROOTFS
 pushd "$(mktemp -d)" >/dev/null 2>&1
 APPDIR="/opt/rootfs/AppBundles/archlinux.AppDir" && export APPDIR="${APPDIR}" ; sudo mkdir -p "${APPDIR}/usr/bin"
 export ROOTFS_DIR="${APPDIR}/rootfs" ; sudo rm -rvf "${ROOTFS_DIR}" ; sudo mkdir -p "${ROOTFS_DIR}"
 sudo chown -R "$(whoami):$(whoami)" "/opt/rootfs" && sudo chmod -R 755 "/opt/rootfs"
##Get RootFS
 if [ "$(uname  -m)" == "aarch64" ]; then
   aria2c "https://pub.ajam.dev/utils/archlinuxarm-$(uname -m)/rootfs.tar.gz" \
       --split="16" --max-connection-per-server="16" --min-split-size="1M" \
       --check-certificate="false" --console-log-level="error" --user-agent="${USER_AGENT}" \
       --download-result="default" --allow-overwrite --out="./ROOTFS.tar.gz" 2>/dev/null
   bsdtar -x -f "./ROOTFS.tar.gz" -p -C "${ROOTFS_DIR}" 2>/dev/null
   ls "${ROOTFS_DIR}" -lah ; popd >/dev/null 2>&1
 elif [ "$(uname  -m)" == "x86_64" ]; then
   aria2c "https://pub.ajam.dev/utils/archlinux-$(uname -m)/rootfs.tar.gz" \
       --split="16" --max-connection-per-server="16" --min-split-size="1M" \
       --check-certificate="false" --console-log-level="error" --user-agent="${USER_AGENT}" \
       --download-result="default" --allow-overwrite --out="./ROOTFS.tar.gz" 2>/dev/null
   bsdtar -x -f "./ROOTFS.tar.gz" -p -C "${ROOTFS_DIR}" 2>/dev/null
   ls "${ROOTFS_DIR}" -lah ; popd >/dev/null 2>&1
 fi
##Bootstrap
 if [ -d "${ROOTFS_DIR}" ] && [ $(du -s "${ROOTFS_DIR}" | cut -f1) -gt 100 ]; then
 #AppRun
   curl -qfsSL "${APPRUN_URL}" -o "${APPDIR}/AppRun" && chmod +x "${APPDIR}/AppRun"
 #Deps for ROOTFS
   curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bash" -o "${ROOTFS_DIR}/usr/bin/bash" && chmod +x "${ROOTFS_DIR}/usr/bin/bash"
   curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bwrap" -o "${APPDIR}/usr/bin/bwrap"
   sudo chmod u+s "${APPDIR}/usr/bin/bwrap"
 #Entrypoint
   echo "${ENTRYPOINT}" > "${ROOTFS_DIR}/entrypoint" && chmod +x "${ROOTFS_DIR}/entrypoint"
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
 #Add Repos
   echo "https://dl-cdn.archlinuxlinux.org/archlinux/latest-stable/main" > "${ROOTFS_DIR}/etc/apk/repositories"
   echo "https://dl-cdn.archlinuxlinux.org/archlinux/latest-stable/community" >> "${ROOTFS_DIR}/etc/apk/repositories"
 #Install Base
   #"${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk -X "https://dl-cdn.archlinuxlinux.org/archlinux/latest-stable/main" -U --allow-untrusted -p "${ROOTFS_DIR}" --initdb add "archlinux-base"
   "${APPDIR}/AppRun" --Xbwrap --uid "0" --gid "0" -- apk -X "https://dl-cdn.archlinuxlinux.org/archlinux/latest-stable/main" -U --allow-untrusted --initdb add "archlinux-base"
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
set +x ; unset APPDIR APPRUN_URL ROOTFS_DIR
##-------------------------------------------------------#