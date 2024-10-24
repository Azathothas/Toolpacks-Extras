#!/usr/bin/env bash
#self: source 
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/${HOST_TRIPLET}/pkgs/imagemagick.sh")
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
export SKIP_BUILD="YES" #currently for demo & future ref only
#imagemagick : Portable single-file linux container (ArchLinux ROOTFS)
export BIN="runimage-archlinux"
export SOURCE_URL="https://github.com/VHSgunzo/runimage"
export BUILD_RUNIMAGE="YES"
#-------------------------------------------------------#
if [ "${SKIP_BUILD}" == "NO" ]; then
     echo -e "\n\n [+] (Building | Fetching) ${BIN} :: ${SOURCE_URL} [$(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)') UTC]\n"
     #-------------------------------------------------------#
    if [ "${BUILD_RUNIMAGE}" == "YES" ]; then
      ##Build RunImage
       pushd "$($TMPDIRS)" >/dev/null 2>&1
       OWD="$(realpath .)" && export OWD="${OWD}"
       export APP="runimage-archlinux"
       export PKG_NAME="${APP}.RunImage"
       APPDIR="$(realpath .)/RunDir" && export APPDIR="${APPDIR}"
       export ROOTFS_DIR="${APPDIR}/rootfs" && mkdir -p "${ROOTFS_DIR}"
       RELEASE_TAG="$(gh release list --repo "${SOURCE_URL}" --order "desc" --exclude-drafts --exclude-pre-releases --json "tagName" | jq -r '.[0].tagName | gsub("\\s+"; "")' | tr -d '[:space:]')" && export RELEASE_TAG="${RELEASE_TAG}"
      ##Get ROOTFS 
       pushd "$(mktemp -d)" >/dev/null 2>&1
       bsdtar -x -f "/opt/ROOTFS/archlinux.ROOTFS.tar.zst" -p -C "./" 2>/dev/null
       ROOTFS_TMPEXT="$(find . -maxdepth 1 -type d -exec basename {} \; | grep -Ev '^\.$' | xargs -I {} realpath {})" && export ROOTFS_TMPEXT="${ROOTFS_TMPEXT}" ; mkdir -p "${ROOTFS_DIR}"
       [ -n "${ROOTFS_TMPEXT+x}" ] && [[ "${ROOTFS_TMPEXT}" == "/tmp"* ]] && rsync -achq --delete "${ROOTFS_TMPEXT}/." "${ROOTFS_DIR}" ; popd >/dev/null 2>&1
       if [ -d "${ROOTFS_DIR}" ] && [ $(du -s "${ROOTFS_DIR}" | cut -f1) -gt 100 ]; then
         realpath "${ROOTFS_DIR}" && ls "${ROOTFS_DIR}" -lah && du -sh "${ROOTFS_DIR}"
       else
         echo -e "\n[+] RunImage (archlinux) ROOTFS Setup Failed\n"
         exit 1
       fi
       unset ROOTFS_TMPEXT
      ##Download RunImage-ROOTFS
       pushd "$(mktemp -d)" >/dev/null 2>&1
       git clone --filter="blob:none" --depth="1" "https://github.com/VHSgunzo/runimage" && cd "./runimage"
       RUNIMAGE_REPO="$(realpath ".")" && export RUNIMAGE_REPO="${RUNIMAGE_REPO}"
       RUNIMAGE_RFS="$(realpath "./rootfs")" && export RUNIMAGE_RFS="${RUNIMAGE_RFS}"
       if [ -d "${RUNIMAGE_RFS}" ] && [ $(du -s "${RUNIMAGE_RFS}" | cut -f1) -gt 100 ]; then
          realpath "${RUNIMAGE_RFS}" && ls "${RUNIMAGE_RFS}" -lah && du -sh "${RUNIMAGE_RFS}"
       else
         echo -e "\n[+] RunImage (git-source) ROOTFS Setup Failed\n"
         exit 1
       fi
       popd >/dev/null 2>&1
      ##Sync & Seed ROOTFS : https://github.com/VHSgunzo/runimage/tree/main/rootfs
       curl -qfsSL "https://bin.ajam.dev/$(uname -m)/runimage-run" -o "${APPDIR}/Run" && chmod +x "${APPDIR}/Run"
       #curl -qfsSL "https://raw.githubusercontent.com/VHSgunzo/runimage/refs/heads/main/rootfs/var/RunDir/Run.sh" -o "${APPDIR}/Run.sh" && chmod +x "${APPDIR}/Run.sh"
       rsync -achv --mkpath "${RUNIMAGE_RFS}/var/RunDir/." "${APPDIR}"
       rsync -achv --mkpath "${RUNIMAGE_RFS}/usr/bin/." "${ROOTFS_DIR}/usr/bin"
       rsync -achv --mkpath --delete "${RUNIMAGE_RFS}/usr/share/libalpm/." "${ROOTFS_DIR}/usr/share/libalpm"
       ls "${ROOTFS_DIR}/usr/bin/" && ls "${ROOTFS_DIR}/usr/share/libalpm" && tree "${APPDIR}" -L 2
      #Prep AppDir 
       if [ -d "${APPDIR}" ] && [ $(du -s "${APPDIR}" | cut -f1) -gt 100 ]; then
         #Static Binaries
          mkdir -p "${APPDIR}/static"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/gawk/awk" -o "${APPDIR}/static/awk"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/basename" -o "${APPDIR}/static/basename"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bash" -o "${APPDIR}/static/bash"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/bwrap" -o "${APPDIR}/static/bwrap"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/cat" -o "${APPDIR}/static/cat"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/chmod" -o "${APPDIR}/static/chmod"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/cp" -o "${APPDIR}/static/cp"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/curl" -o "${APPDIR}/static/curl"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/cut" -o "${APPDIR}/static/cut"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/date" -o "${APPDIR}/static/date"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/dd" -o "${APPDIR}/static/dd"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/dirname" -o "${APPDIR}/static/dirname"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/du" -o "${APPDIR}/static/du"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/echo" -o "${APPDIR}/static/echo"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/findutils/find" -o "${APPDIR}/static/find"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/util-linux/flock" -o "${APPDIR}/static/flock"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/grep/grep" -o "${APPDIR}/static/grep"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/gzip/gzip" -o "${APPDIR}/static/gzip"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/head" -o "${APPDIR}/static/head"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/id" -o "${APPDIR}/static/id"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/importenv" -o "${APPDIR}/static/importenv"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/procps/kill" -o "${APPDIR}/static/kill"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/kmod/kmod" -o "${APPDIR}/static/kmod"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/ln" -o "${APPDIR}/static/ln"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/logname" -o "${APPDIR}/static/logname"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/ls" -o "${APPDIR}/static/ls"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/kmod/lsmod" -o "${APPDIR}/static/lsmod"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/lsof" -o "${APPDIR}/static/lsof"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/mkdir" -o "${APPDIR}/static/mkdir"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/mkfifo" -o "${APPDIR}/static/mkfifo"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/mknod" -o "${APPDIR}/static/mknod"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/squashfstools/mksquashfs" -o "${APPDIR}/static/mksquashfs"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/kmod/modinfo" -o "${APPDIR}/static/modinfo"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/mv" -o "${APPDIR}/static/mv"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/notify-send-rs" -o "${APPDIR}/static/notify-send"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/util-linux/nsenter" -o "${APPDIR}/static/nsenter"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/procps/pgrep" -o "${APPDIR}/static/pgrep"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/procps/ps" -o "${APPDIR}/static/ps"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/ptyspawn" -o "${APPDIR}/static/ptyspawn"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/pwd" -o "${APPDIR}/static/pwd"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/realpath" -o "${APPDIR}/static/realpath"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/rm" -o "${APPDIR}/static/rm"
          curl -qfsSL "https://github.com/VHSgunzo/runimage-runtime-static/releases/download/continuous/runtime-fuse2-all-$(uname -m)-Linux" -o "${APPDIR}/static/runtime-fuse2-all"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/sed" -o "${APPDIR}/static/sed"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/util-linux/setsid" -o "${APPDIR}/static/setsid"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/sleep" -o "${APPDIR}/static/sleep"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/slirp4netns" -o "${APPDIR}/static/slirp4netns"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/socat" -o "${APPDIR}/static/socat"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/sort" -o "${APPDIR}/static/sort"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/squashfuse" -o "${APPDIR}/static/squashfuse"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/squashfuse_ll" -o "${APPDIR}/static/squashfuse_ll"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/squashfuse" -o "${APPDIR}/static/squashfuse3"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/tail" -o "${APPDIR}/static/tail"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/tar/tar" -o "${APPDIR}/static/tar"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/tee" -o "${APPDIR}/static/tee"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/touch" -o "${APPDIR}/static/touch"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/tr" -o "${APPDIR}/static/tr"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/tty" -o "${APPDIR}/static/tty"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/uname" -o "${APPDIR}/static/uname"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/unionfs-fuse/unionfs" -o "${APPDIR}/static/unionfs"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/unionfs-fuse3/unionfs" -o "${APPDIR}/static/unionfs3"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/uniq" -o "${APPDIR}/static/uniq"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/squashfstools/unsquashfs" -o "${APPDIR}/static/unsquashfs"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils/wc" -o "${APPDIR}/static/wc"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/which" -o "${APPDIR}/static/which"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/coreutils-glibc/who" -o "${APPDIR}/static/who"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/xhost" -o "${APPDIR}/static/xhost"
          curl -qfsSL "https://bin.ajam.dev/$(uname -m)/Baseutils/xz/xz" -o "${APPDIR}/static/xz"
         #chmod
          find "${APPDIR}/static/" -type f -exec chmod +x {} \;
         #Bootstrap
          #export UNSHARE_MODULES="1"
         #Fix ID
          unlink "${ROOTFS_DIR}/var/lib/dbus/machine-id" 2>/dev/null
          rm -rvf "${ROOTFS_DIR}/etc/machine-id"
          "${APPDIR}/Run" --uid "0" --gid "0" systemd-machine-id-setup --print 2>/dev/null | tee "${ROOTFS_DIR}/var/lib/dbus/machine-id"
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
          "${APPDIR}/Run" --uid "0" --gid "0" locale-gen
          "${APPDIR}/Run" --uid "0" --gid "0" locale-gen "en_US.UTF-8"
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
          "${APPDIR}/Run" --uid "0" --gid "0" pacman -Syy archlinux-keyring pacutils --noconfirm
          "${APPDIR}/Run" --uid "0" --gid "0" pacman-key --init
          "${APPDIR}/Run" --uid "0" --gid "0" pacman-key --populate "archlinux"
          "${APPDIR}/Run" --uid "0" --gid "0" pacman -y --sync --refresh --refresh --sysupgrade --noconfirm --debug
          "${APPDIR}/Run" --uid "0" --gid "0" pacman -Scc --noconfirm
         #Install Fake-Sudo
          curl -A "${USER_AGENT}" -qfsSL "https://api.github.com/repos/VHSgunzo/runimage-fake-sudo-pkexec/releases/latest" -H "Authorization: Bearer ${GITHUB_TOKEN}" | \
            jq -r '.assets[] | select(.name | test("fake-sudo-pkexec-.*-any.pkg.tar.zst")) | .browser_download_url' | \
            xargs curl -A "${USER_AGENT}" -qfsSL -o "${ROOTFS_DIR}/tmp/fake-sudo-pkexec-any.pkg.tar.zst"
          "${APPDIR}/Run" --uid "0" --gid "0" pacman -Sy fakeroot fakechroot --noconfirm
          "${APPDIR}/Run" --uid "0" --gid "0" pac -Uddd "${ROOTFS_DIR}/tmp/fake-sudo-pkexec-any.pkg.tar.zst" --noconfirm
          "${APPDIR}/Run" --uid "0" --gid "0" pac -Rsndd lib32-glibc lib32-fakeroot lib32-fakechroot --noconfirm 2>/dev/null
         #Replace Systemd with fake-systemd
          curl -A "${USER_AGENT}" -qfsSL "https://api.github.com/repos/VHSgunzo/runimage-fake-systemd/releases/latest" -H "Authorization: Bearer ${GITHUB_TOKEN}" | \
             jq -r '.assets[] | select(.name | test("fake-systemd-.*-any.pkg.tar.zst")) | .browser_download_url' | \
             xargs curl -A "${USER_AGENT}" -qfsSL -o "${ROOTFS_DIR}/tmp/fake-systemd-any.pkg.tar.zst"
          "${APPDIR}/Run" --uid "0" --gid "0" pac -Rdd systemd --noconfirm
          "${APPDIR}/Run" --uid "0" --gid "0" pac -Rdd systemd-sysvcompat --noconfirm
          "${APPDIR}/Run" --uid "0" --gid "0" pac -Uddd "${ROOTFS_DIR}/tmp/fake-systemd-any.pkg.tar.zst" --noconfirm --overwrite '*'
         #Update base runimage
          "${APPDIR}/Run" --uid "0" --gid "0" pacman -Sy fakeroot fakechroot --noconfirm
          "${APPDIR}/Run" sudo pacman -Syu --noconfirm --debug
         #Install and Fix pacstrap
          "${APPDIR}/Run" sudo sh -c \
            "pac -S arch-install-scripts --noconfirm --needed && \
            sed -i 's|\$setup \"\$newroot\"|# &|' /bin/pacstrap"
         #Bootstrap new runimage rootfs with base packages
          "${APPDIR}/Run" sudo pacman -Rddd iptables --noconfirm
          "${APPDIR}/Run" sudo pacstrap -P "${ROOTFS_DIR}" base dbus less fakeroot fakechroot lib32-glibc iputils iptables-nft nftables openresolv which --needed --noconfirm --overwrite "*"
         #Remove Bloatware: https://github.com/VHSgunzo/runimage/blob/main/runshrink
          pushd "${ROOTFS_TMP}" >/dev/null 2>&1
          curl -qfsSL "https://raw.githubusercontent.com/VHSgunzo/runimage/main/runshrink" -o "./runshrink" && chmod +x "./runshrink"
          "./runshrink" 2>/dev/null ; popd >/dev/null 2>&1
          find "${ROOTFS_DIR}/boot" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/dev" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/proc" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/run" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/sys" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/tmp" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/usr/include" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/usr/lib" -type f -name "*.a" -print -exec rm -f {} 2>/dev/null \; 2>/dev/null
          find "${ROOTFS_DIR}/usr/lib32" -type f -name "*.a" -print -exec rm -f {} 2>/dev/null \; 2>/dev/null
          find "${ROOTFS_DIR}/etc/pacman.d/gnupg" -type f -name "S.*" -print -exec rm -f {} 2>/dev/null \; 2>/dev/null
          find "${ROOTFS_DIR}/usr/share/doc" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/usr/share/gtk-doc" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/usr/share/help" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/usr/share/info" -mindepth 1 -delete 2>/dev/null
          find "${ROOTFS_DIR}/usr/share/man" -mindepth 1 -delete 2>/dev/null
          "${APPDIR}/Run" pac -Rsndd perl --noconfirm 2>/dev/null
          "${APPDIR}/Run" pac -Rsndd python --noconfirm 2>/dev/null
         #List Installed pkgs
          "${APPDIR}/Run" sudo pacman -Qq
         #Build New Runimage
          #"${APPDIR}/Run" --run-build "${OWD}/${PKG_NAME}" -zstd 22
          "${APPDIR}/Run" --run-build "${OWD}/${PKG_NAME}" -lz4
         #Copy
          rsync -achLv "${OWD}/${PKG_NAME}" "${BINDIR}/${PKG_NAME}"
          popd >/dev/null 2>&1
       #Info
         find "${BINDIR}" -type f -iname "*${APP%%-*}*" -print | xargs -I {} sh -c 'file {}; b3sum {}; sha256sum {}; du -sh {}'
         unset APPBUNLE_ROOTFS APPIMAGE APPIMAGE_EXTRACT ENTRYPOINT_DIR EXEC FIMG_BASE NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
       fi
    fi
fi
#Enrichments
pushd "$($TMPDIRS)" >/dev/null 2>&1
#alpine enrichment: https://pkgs.alpinelinux.org/packages --> apk search ${ALPINE_PKG}
 ALPINE_PKG="${BIN}" bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/enrich_metadata_alpine.sh") || true &
#arch enrichment: https://archlinux.org/packages/ --> pacman -Ss ${ARCHLINUX_PKG}
 ARCHLINUX_PKG="${BIN}" bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/enrich_metadata_arch.sh") || true &
#debian enrichment: https://packages.debian.org/ --> apt search ${DEBIAN_PKG}
 DEBIAN_PKG="${BIN}" bash <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/enrich_metadata_debian.sh") || true &
#flatpack enrichment
if [ -n "${BIN_ID+x}" ] && [ -n "${BIN_ID}" ]; then
 curl -qfsSL "https://flathub.org/api/v2/appstream/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.appstream.json" &
 curl -qfsSL "https://flathub.org/api/v2/stats/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.stats.json" &
 curl -qfsSL "https://flathub.org/api/v2/summary/${BIN_ID}" | jq . > "${BINDIR}/${BIN}.flatpak.info.json" &
 flatpak --user remote-info flathub "${BIN_ID}" | tee "${BINDIR}/${BIN}.flatpak.txt" &
fi
#Log
 wait ; LOG_PATH="${BINDIR}/${BIN}.log" && export LOG_PATH="${LOG_PATH}"
rm -rvf "$(realpath .)" 2>/dev/null && popd >/dev/null 2>&1
#-------------------------------------------------------#
#-------------------------------------------------------#

#-------------------------------------------------------#
##Cleanup
unset APPBUNLE_ROOTFS APP BIN_ID APPIMAGE APPIMAGE_EXTRACT BUILD_FIMG BUILD_NIX_APPIMAGE DOWNLOAD_URL EXEC NIX_PKGNAME OFFSET OWD PKG_NAME RELEASE_TAG ROOTFS_DIR SHARE_DIR
unset SKIP_BUILD ; export BUILT="YES"
#In case of zig polluted env
unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS LIBS OBJCOPY RANLIB
#In case of go polluted env
unset GOARCH GOOS CGO_ENABLED CGO_CFLAGS
#PKG Config
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH
set +x
#-------------------------------------------------------#