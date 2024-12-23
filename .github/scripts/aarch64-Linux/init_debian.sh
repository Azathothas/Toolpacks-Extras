#!/usr/bin/env bash

###-------------------------------------------------------###
### Setups Essential Tools & Preps Sys Environ for Deps   ###
### This Script must be run as `root` (passwordless)      ###
### Assumptions: Arch: (arm64) | OS: Debian 64bit         ###
###-------------------------------------------------------###

#-------------------------------------------------------#
## Init Script for toolpacks builder
# This should be run on Debian (Debian Based) Distros with apt, coreutils, curl, dos2unix & passwordless sudo
# sudo apt-get update -y && sudo apt-get install coreutils curl dos2unix moreutils -y
# OR (without sudo): apt-get update -y && apt-get install coreutils curl dos2unix moreutils sudo -y
#
# Hardware : At least 2vCPU + 8GB RAM + 50GB SSD
# Once requirement is satisfied, simply:
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/.github/scripts/$(uname -m)-Linux/init_debian.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
 SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="$SYSTMP"
 USER="$(whoami)" && export USER="${USER}"
 HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
 HOST_TRIPLET="$(uname -m)-$(uname -s)" && export HOST_TRIPLET="${HOST_TRIPLET}"
 USER_AGENT="$(curl -qfsSL 'https://pub.ajam.dev/repos/Azathothas/Wordlists/Misc/User-Agents/ua_chrome_macos_latest.txt')" && export USER_AGENT="${USER_AGENT}"
#-------------------------------------------------------# 
##Sanity Checks
##Check if it was recently initialized
 # +360  --> 06 Hrs
 # +720  --> 12 HRs
 # +1440 --> 24 HRs
 find "$SYSTMP/INITIALIZED" -type f -mmin +720 -exec rm {} \; 2>/dev/null
 if [ -s "$SYSTMP/INITIALIZED" ]; then
    echo -e "\n[+] Recently Initialized... (Skipping!)\n"
    export CONTINUE="YES"
 else
    ##Sane Configs
    #In case of removed/privated GH repos
     # https://git-scm.com/docs/git#Documentation/git.txt-codeGITTERMINALPROMPTcode
     export GIT_TERMINAL_PROMPT="0"
     #https://git-scm.com/docs/git#Documentation/git.txt-codeGITASKPASScode
     export GIT_ASKPASS="/bin/echo"
    #-------------------------------------------------------# 
    ##Check for apt
     if ! command -v apt &> /dev/null; then
        echo -e "\n[-] apt NOT Found"
        echo -e "\n[+] Maybe not on Debian (Debian Based Distro) ?\n"
        #Fail & exit
        export CONTINUE="NO" && exit 1
     else
       #Export as noninteractive
       export DEBIAN_FRONTEND="noninteractive"
       export CONTINUE="YES"
     fi
    ##Check for sudo
    if [ "$CONTINUE" == "YES" ]; then
       if ! command -v sudo &> /dev/null; then
          echo -e "\n[-] sudo NOT Installed"
          echo -e "\n[+] Trying to Install\n"
          #Try to install
           apt-get update -y 2>/dev/null ; apt-get dist-upgrade -y 2>/dev/null ; apt-get upgrade -y 2>/dev/null
           apt install sudo -y 2>/dev/null
          #Fail if it didn't work
             if ! command -v sudo &> /dev/null; then
               echo -e "[-] Failed to Install sudo (Maybe NOT root || NOT enough perms)\n"
               #exit
               export CONTINUE="NO" && exit 1
             fi
       fi
    fi 
    ##Check for passwordless sudo
    if [ "$CONTINUE" == "YES" ]; then
       if sudo -n true 2>/dev/null; then
           echo -e "\n[+] Passwordless sudo is Configured"
           sudo grep -E '^\s*[^#]*\s+ALL\s*=\s*\(\s*ALL\s*\)\s+NOPASSWD:' "/etc/sudoers" 2>/dev/null
       else
           echo -e "\n[-] Passwordless sudo is NOT Configured"
           echo -e "\n[-] READ: https://web.archive.org/web/20230614212916/https://linuxhint.com/setup-sudo-no-password-linux/\n"
           #exit
           export CONTINUE="NO" && exit 1
       fi
    fi
    #-------------------------------------------------------#
    
    #-------------------------------------------------------#
     echo -e "\n\n [+] Started Initializing $(uname -mnrs) :: at $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
     echo -e "[+] USER = ${USER}"
     echo -e "[+] HOME = ${HOME}"
     echo -e "[+] PATH = ${PATH}\n"
    #-------------------------------------------------------#
    ## If On Github Actions, remove bloat to get space (~ 30 GB) [DANGEROUS]
    if [ "$CONTINUE" == "YES" ]; then
       if [ "${USER}" = "runner" ] || [ "$(whoami)" = "runner" ] && [ -s "/opt/runner/provisioner" ]; then
          ##Debloat:https://github.com/Azathothas/Arsenal/blob/main/misc/Github/Runners/Ubuntu/debloat.sh
           bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Github/Runners/Ubuntu/debloat.sh")
           bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Github/Runners/Ubuntu/debloat.sh") 2>/dev/null
       fi
    fi
    #-------------------------------------------------------#
    
    #-------------------------------------------------------#
    ## Main
    #TMPDIRS
     #For build-cache
     TMPDIRS="mktemp -d --tmpdir=${SYSTMP}/toolpacks XXXXXXX_$(uname -m)_$(uname -s)" && export TMPDIRS="$TMPDIRS"
     rm -rf "$SYSTMP/init_Debian" 2>/dev/null ; mkdir -p "$SYSTMP/init_Debian"
     pushd "$($TMPDIRS)" >/dev/null 2>&1 
    if [ "$CONTINUE" == "YES" ]; then
         #Install CoreUtils & Deps
          sudo apt-get update -y 2>/dev/null
          packages="apt-transport-https apt-utils ca-certificates coreutils gnupg2 moreutils software-properties-common util-linux"
          for pkg in $packages; do DEBIAN_FRONTEND="noninteractive" sudo apt install -y --ignore-missing "$pkg"; done
          #Install Build Des
          packages="aria2 automake bc binutils b3sum build-essential ca-certificates ccache diffutils dos2unix gawk git-lfs imagemagick lzip jq libtool libtool-bin make musl musl-dev musl-tools p7zip-full rsync texinfo tree wget"
          for pkg in $packages; do DEBIAN_FRONTEND="noninteractive" sudo apt install -y --ignore-missing "$pkg"; done
          for pkg in $packages; do DEBIAN_FRONTEND="noninteractive" sudo apt install -y --ignore-missing "$pkg"; done
          packages="autoconf automake autopoint binutils bison build-essential byacc ca-certificates clang flex file jq libtool libtool-bin patch patchelf pkg-config qemu-user-static scons wget"
          for pkg in $packages; do DEBIAN_FRONTEND="noninteractive" sudo apt install -y --ignore-missing "$pkg"; done
          for pkg in $packages; do DEBIAN_FRONTEND="noninteractive" sudo apt install -y --ignore-missing "$pkg"; done
          sudo apt-get install devscripts -y --no-install-recommends 2>/dev/null
          sudo apt-get install cmake -y
          sudo apt-get install jc git-lfs -y
          #Install Build Dependencies (arm64)
          sudo apt install binutils-$(uname -m)-linux-gnu -y 2>/dev/null
          sudo apt-get install "g++-arm-linux-gnueabi" "g++-arm-linux-gnueabihf" "g++-$(uname -m)-linux-gnu" qemu-user-static -y 2>/dev/null
         #libpcap
          sudo apt-get install 'libpcap*' -y 2>/dev/null
         #libsqlite3
          sudo apt-get install libsqlite3-dev sqlite3 sqlite3-pcre sqlite3-tools -y 2>/dev/null
         #lzma
          sudo apt-get install liblz-dev librust-lzma-sys-dev lzma lzma-dev -y 
         #musl
          #Source
          pushd "$($TMPDIRS)" >/dev/null 2>&1 && git clone --filter "blob:none" "https://git.musl-libc.org/git/musl" && cd "./musl"
          #Flags
          unset AR CC CFLAGS CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LDFLAGS OBJCOPY RANLIB
          #Configure
          make dest clean 2>/dev/null ; make clean 2>/dev/null
          bash "./configure" --prefix="/usr/local/musl"
          sudo make --jobs="$(($(nproc)+1))" --keep-going install ; popd >/dev/null 2>&1
          sudo ldconfig && sudo ldconfig -p
          find "$SYSTMP" -type d -name "*musl*" 2>/dev/null -exec rm -rf {} \; >/dev/null 2>&1
         #Networking
          sudo apt-get install dnsutils 'inetutils*' net-tools netcat-traditional -y 2>/dev/null
          sudo apt-get install 'iputils*' -y 2>/dev/null
          sudo setcap cap_net_raw+ep "$(which ping)" 2>/dev/null
         #Install PythonUtils & Deps (StaticX)
          sudo apt install python3-pip python3-venv -y 2>/dev/null
         #Upgrade pip
          pip --version
          pip install --break-system-packages --upgrade pip || pip install --upgrade pip
          pip --version
         #Deps 
          sudo apt install lm-sensors pciutils procps python3-distro python3-netifaces sysfsutils virt-what -y 2>/dev/null
          sudo apt-get install libxcb1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev scons xcb -y 2>/dev/null
          pip install build cffi scons scuba pytest --upgrade --force 2>/dev/null ; pip install ansi2txt pipx scons py2static typer --upgrade --force 2>/dev/null
          pip install build cffi scons scuba pytest --break-system-packages --upgrade --force 2>/dev/null ; pip install ansi2txt pipx scons py2static typer --break-system-packages --upgrade --force 2>/dev/null
          #pyinstaller
          pip install "git+https://github.com/pyinstaller/pyinstaller" --break-system-packages --force-reinstall --upgrade ; pyinstaller --version
         ##Addons:https://github.com/Azathothas/Arsenal/blob/main/misc/Github/Runners/Ubuntu/debloat.sh
          bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
         ##Appimage tools
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/go-appimagetool.no_strip" -o "/usr/local/bin/go-appimagetool" && sudo chmod +x "/usr/local/bin/go-appimagetool"
          sudo curl -qfsSL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$(uname -m).AppImage" -o "/usr/local/bin/appimagetool" && sudo chmod +x "/usr/local/bin/appimagetool"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/linuxdeploy.no_strip" -o "/usr/local/bin/linuxdeploy" && sudo chmod +x "/usr/local/bin/linuxdeploy"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/mkappimage" -o "/usr/local/bin/mkappimage" && sudo chmod +x "/usr/local/bin/mkappimage"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/squashfstools/mksquashfs" -o "/usr/local/bin/mksquashfs" && sudo chmod +x "/usr/local/bin/mksquashfs"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/squashfstools/sqfscat" -o "/usr/local/bin/sqfscat" && sudo chmod +x "/usr/local/bin/sqfscat"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/squashfstools/sqfstar" -o "/usr/local/bin/sqfstar" && sudo chmod +x "/usr/local/bin/sqfstar"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/squashfstools/unsquashfs" -o "/usr/local/bin/unsquashfs" && sudo chmod +x "/usr/local/bin/unsquashfs"
          ##It doesn't work, it changes the shasums, and updates despite no delta diff
          sudo apt install zsync -y -qq
          #zsyncmake2 requires libfuse: https://github.com/AppImageCommunity/zsync2/issues/76
          #sudo apt install fuse -y -qq
          #sudo eget "https://github.com/AppImageCommunity/zsync2" --pre-release --tag "continuous" --asset "zsync2" --asset "$(uname -m)" --asset "^zsyncmake" --asset "^.zsync" --to "/usr/local/bin/zsync"
          #sudo eget "https://github.com/AppImageCommunity/zsync2" --pre-release --tag "continuous" --asset "zsyncmake2" --asset "$(uname -m)" --asset "^.zsync" --to "/usr/local/bin/zsyncmake"
          #sudo chattr +i "/usr/local/bin/appimagetool" "/usr/local/bin/zsync" "/usr/local/bin/zsyncmake"
         ##ImageMagick
          #sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/magick.no_strip" -o "/usr/local/bin/magick" && sudo chmod +x "/usr/local/bin/magick"
          bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/setup_imagemagick.sh")
          if ! command -v magick &> /dev/null; then
             echo -e "\n[-] ImageMagick NOT Found\n"
             export CONTINUE="NO" && exit 1
          else
             magick --version
          fi
    fi
    #-------------------------------------------------------#
    
    #-------------------------------------------------------#
    ##Langs
    if [ "$CONTINUE" == "YES" ]; then
         #----------------------#
         ##Setup alpine (apk)
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/apk-static" -o "/usr/local/bin/apk-static" && sudo chmod +x "/usr/local/bin/apk-static"
         #----------------------#
         ##Setup AppBundle
          pushd "$($TMPDIRS)" >/dev/null 2>&1
           curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/.github/scripts/appbundles_alpine.Dockerfile" -o "./Dockerfile"
           docker build --no-cache --tag "appbundler-alpine" --file "./Dockerfile" "."
          popd >/dev/null 2>&1
         #----------------------#
         ##Setup RootFS
          sudo rm -rvf "/opt/ROOTFS" 2>/dev/null ; sudo mkdir -p "/opt/ROOTFS"
          sudo chown -R "$(whoami):$(whoami)" "/opt/ROOTFS" && sudo chmod -R 755 "/opt/ROOTFS"
          #alpine-mini
           pushd "$(mktemp -d)" >/dev/null 2>&1
           aria2c "https://pub.ajam.dev/utils/alpine-mini-$(uname -m)/rootfs.tar.gz" \
           --split="16" --max-connection-per-server="16" --min-split-size="1M" \
           --check-certificate="false" --console-log-level="error" --user-agent="${USER_AGENT}" \
           --max-tries="10" --retry-wait="5" --connect-timeout="60" --timeout="600" \
           --download-result="default" --allow-overwrite --out="./ROOTFS.tar.gz" 2>/dev/null
           rsync -achLv "./ROOTFS.tar.gz" "/opt/ROOTFS/alpine-mini.ROOTFS.tar.gz" ; popd >/dev/null 2>&1
           #Test
             if [ ! -f "/opt/ROOTFS/alpine-mini.ROOTFS.tar.gz" ] || [ $(du -s "/opt/ROOTFS/alpine-mini.ROOTFS.tar.gz" | cut -f1) -le 100 ]; then
                echo -e "\n[-] RootFS (alpine-mini) Setup Failed\n"
                export CONTINUE="NO" && exit 1
             else
                find "/opt/ROOTFS/alpine-mini.ROOTFS.tar.gz" -exec sh -c 'file "{}" && du -sh "{}"' \;
             fi
          #archlinuxarm
           pushd "$(mktemp -d)" >/dev/null 2>&1
           aria2c "https://pub.ajam.dev/utils/archlinuxarm-$(uname -m)/rootfs.tar.gz" \
           --split="16" --max-connection-per-server="16" --min-split-size="1M" \
           --check-certificate="false" --console-log-level="error" --user-agent="${USER_AGENT}" \
           --max-tries="10" --retry-wait="5" --connect-timeout="60" --timeout="600" \
           --download-result="default" --allow-overwrite --out="./ROOTFS.tar.gz" 2>/dev/null
           rsync -achLv "./ROOTFS.tar.gz" "/opt/ROOTFS/archlinuxarm.ROOTFS.tar.gz" ; popd >/dev/null 2>&1
           #Test
             if [ ! -f "/opt/ROOTFS/archlinuxarm.ROOTFS.tar.gz" ] || [ $(du -s "/opt/ROOTFS/archlinuxarm.ROOTFS.tar.gz" | cut -f1) -le 100 ]; then
                echo -e "\n[-] AppBundle (archlinuxarm) Setup Failed\n"
                export CONTINUE="NO" && exit 1
             else
                find "/opt/ROOTFS/archlinuxarm.ROOTFS.tar.gz" -exec sh -c 'file "{}" && du -sh "{}"' \;
             fi
         #----------------------#
         #Docker
         install_docker ()
         {
            #Install 
             curl -qfsSL "https://get.docker.com" | sed 's/sleep 20//g' | sudo bash
             sudo groupadd docker 2>/dev/null ; sudo usermod -aG docker "${USER}" 2>/dev/null
             sudo service docker restart 2>/dev/null && sleep 10
             sudo service docker status 2>/dev/null
             unset DOCKER_HOST
            #Test
             if ! command -v docker &> /dev/null; then
                echo -e "\n[-] docker NOT Found\n"
                export CONTINUE="NO" && exit 1
             else
                docker --version ; sudo docker run hello-world
                #newgrp 2>/dev/null
             fi
         }
         export -f install_docker
         if command -v docker &> /dev/null; then
          if [ "$(curl -s https://endoflife.date/api/docker-engine.json | jq -r '.[0].latest')" != "$(docker --version | grep -oP '(?<=version )(\d+\.\d+\.\d+)')" ]; then
             install_docker
          else
             echo -e "\n[+] Latest Docker seems to be already Installed"
             docker --version
          fi
         else    
             install_docker
         fi
         #----------------------# 
         #Dockerc
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/dockerc" -o "/usr/local/bin/dockerc" && sudo chmod +x "/usr/local/bin/dockerc"
         ##Setup FlatImage:: https://github.com/ruanformigoni/flatimage/issues/16
         # sudo rm -rvf "/opt/FLATIMAGE" 2>/dev/null ; sudo mkdir -p "/opt/FLATIMAGE"
         # sudo chown -R "$(whoami):$(whoami)" "/opt/FLATIMAGE" && sudo chmod -R 755 "/opt/FLATIMAGE"
         # curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/alpine-flatimage.no_strip" -o "/opt/FLATIMAGE/alpine"
         # curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/archlinux-flatimage.no_strip" -o "/opt/FLATIMAGE/archlinux"
         # curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/blueprint-flatimage.no_strip" -o "/opt/FLATIMAGE/blueprint"
         # if [ -d "/opt/FLATIMAGE" ] && [ "$(find "/opt/FLATIMAGE" -mindepth 1 -print -quit 2>/dev/null)" ]; then
         #    find "/opt/FLATIMAGE" -maxdepth 1 -type f -exec chmod +x "{}" \;
         #    ls "/opt/FLATIMAGE" -lah ; du -sh "/opt/FLATIMAGE"
         # else
         #    echo -e "\n[-] FlatImage Base Images NOT Found: /opt/FLATIMAGE\n"
         #    export CONTINUE="NO" && exit 1
         # fi
         #----------------------#
         ##Setup FlatImage
          sudo rm -rvf "/opt/FLATIMAGE" 2>/dev/null ; sudo mkdir -p "/opt/FLATIMAGE"
          sudo chown -R "$(whoami):$(whoami)" "/opt/FLATIMAGE" && sudo chmod -R 755 "/opt/FLATIMAGE"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/alpine.flatimage" -o "/opt/FLATIMAGE/alpine"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/archlinux.flatimage" -o "/opt/FLATIMAGE/archlinux"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/artix.flatimage" -o "/opt/FLATIMAGE/artix"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/blueprint.flatimage" -o "/opt/FLATIMAGE/blueprint"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/cachyos.flatimage" -o "/opt/FLATIMAGE/cachyos"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/debian.flatimage" -o "/opt/FLATIMAGE/debian"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/ubuntu.flatimage" -o "/opt/FLATIMAGE/ubuntu"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/void-glibc.flatimage" -o "/opt/FLATIMAGE/void-glibc"
          curl -qfsSL "https://github.com/Azathothas/flatimage-base/releases/download/$(uname -m)/void-musl.flatimage" -o "/opt/FLATIMAGE/void-musl"
          find "/opt/FLATIMAGE" -type f -exec chmod +x "{}" \; 2>/dev/null
          if [ -d "/opt/FLATIMAGE" ] && [ "$(find "/opt/FLATIMAGE" -mindepth 1 -print -quit 2>/dev/null)" ]; then
             find "/opt/FLATIMAGE" -maxdepth 1 -type f -exec chmod +x "{}" \;
             ls "/opt/FLATIMAGE" -lah ; du -sh "/opt/FLATIMAGE"
          else
             echo -e "\n[-] FlatImage Base Images NOT Found: /opt/FLATIMAGE\n"
             export CONTINUE="NO" && exit 1
          fi
         #----------------------#
         ##Install Flatpak
          sudo apt install flatpak -y
          sudo flatpak remote-add --if-not-exists flathub "https://dl.flathub.org/repo/flathub.flatpakrepo"
          flatpak --user remote-add --if-not-exists flathub "https://dl.flathub.org/repo/flathub.flatpakrepo"
          #Test
          if ! command -v flatpak &> /dev/null; then
             echo -e "\n[-] flatpak NOT Found\n"
             export CONTINUE="NO" && exit 1
          else
             flatpak remotes
             flatpak --version
          fi
         #----------------------#
         ##Install golang 
          pushd "$($TMPDIRS)" >/dev/null 2>&1
          echo "yes" | bash <(curl -qfsSL "https://git.io/go-installer")
          popd >/dev/null 2>&1
          #Test
          if ! command -v go &> /dev/null; then
             echo -e "\n[-] go NOT Found\n"
             export CONTINUE="NO" && exit 1
          else
             go version
          fi
         #------------------------------# 
         ##Install Meson & Ninja
          #Install
          sudo rm "/usr/bin/meson" "/usr/bin/ninja" 2>/dev/null
          pip install meson ninja --upgrade 2>/dev/null
          pip install meson ninja --break-system-packages --upgrade 2>/dev/null
          #python3 -m pip install meson ninja --upgrade
          sudo ln -s "${HOME}/.local/bin/meson" "/usr/bin/meson" 2>/dev/null
          sudo ln -s "${HOME}/.local/bin/ninja" "/usr/bin/ninja" 2>/dev/null
          sudo chmod +xwr "/usr/bin/meson" "/usr/bin/ninja"
          #version
          meson --version ; ninja --version
         #----------------------# 
         ##Nix
          ##Official Installers break
          #curl -qfsSL "https://nixos.org/nix/install" | bash -s -- --no-daemon
          #source "${HOME}/.bash_profile" ; source "${HOME}/.nix-profile/etc/profile.d/nix.sh" ; . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
          ##https://github.com/DeterminateSystems/nix-installer
          "/nix/nix-installer" uninstall --no-confirm 2>/dev/null
          #curl -qfsSL "https://install.determinate.systems/nix" | bash -s -- install linux --init none --no-confirm
          curl -qfsSL "https://install.determinate.systems/nix" | bash -s -- install linux --init none --extra-conf "filter-syscalls = false" --no-confirm
          #Source
          source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
          #Fix perms: could not set permissions on '/nix/var/nix/profiles/per-user' to 755: Operation not permitted
          #sudo chown --recursive "${USER}" "/nix"
          sudo chown --recursive "runner" "/nix"
          echo "root    ALL=(ALL:ALL) ALL" | sudo tee -a "/etc/sudoers"
          #Test
          if ! command -v nix &> /dev/null; then
             echo -e "\n[-] nix NOT Found\n"
             export CONTINUE="NO" && exit 1
          else
             nix --version
             nix-channel --add "https://nixos.org/channels/nixos-unstable" "nixedge"
             nix-channel --list && nix-channel --update
             nix registry add "nixpkgs" "github:NixOS/nixpkgs/nixpkgs-unstable" ; nix registry list
             nix derivation show "nixpkgs#hello"
            if [ "${NIX_SETUP_MODE}" == "EXPENSIVE" ]; then
                #Setup NixPkgs Repo [Latest Packages but EXPENSIVE]
                 sudo rm -rvf "/opt/nixpkgs" 2>/dev/null ; sudo mkdir -p "/opt" && pushd "/opt" >/dev/null 2>&1
                 sudo git clone --filter="blob:none" --depth="1" --quiet "https://github.com/NixOS/nixpkgs.git"
                 sudo chown -R "$(whoami):$(whoami)" "/opt/nixpkgs" && sudo chmod -R 755 "/opt/nixpkgs"
                 nix registry add "nixpkgs" "/opt/nixpkgs" ; nix registry list
                 nix derivation show "nixpkgs#hello"
                 popd >/dev/null 2>&1
                 if [ -d "/opt/nixpkgs" ] && [ "$(find "/opt/nixpkgs" -mindepth 1 -print -quit 2>/dev/null)" ]; then
                    ls "/opt/nixpkgs" -lah ; du -sh "/opt/nixpkgs"
                 else
                    echo -e "\n[-] nixpkgs REPO NOT Found: /opt/nixpkgs\n"
                    export CONTINUE="NO" && exit 1
                 fi
            fi
          fi
         ##Nix-Auxs
          sudo rm -rvf "/opt/nix/nix-bundle" 2>/dev/null ; sudo mkdir -p "/opt/nix"
          sudo chown -R "$(whoami):$(whoami)" "/opt/nix" && sudo chmod -R 755 "/opt/nix"
          pushd "/opt/nix" >/dev/null 2>&1 && \
          git clone --filter="blob:none" --depth="1" --quiet "https://github.com/nix-community/nix-bundle"
          find "/opt/nix/nix-bundle" -maxdepth 1 -type f -exec chmod +x "{}" \; 2>/dev/null
          popd >/dev/null 2>&1
          if [ -d "/opt/nix/nix-bundle" ] && [ "$(find "/opt/nix/nix-bundle" -mindepth 1 -print -quit 2>/dev/null)" ]; then
             ls "/opt/nix/nix-bundle" -lah ; du -sh "/opt/nix/nix-bundle"
          else
             echo -e "\n[-] nix-bundle REPO NOT Found: /opt/nix/nix-bundle\n"
             export CONTINUE="NO" && exit 1
          fi
         #----------------------# 
         ##Install rust & cargo
          bash <(curl -qfsSL "https://sh.rustup.rs") -y
          #Test: PATH="${HOME}/.cargo/bin:${HOME}/.cargo/env:${PATH}" 
          if ! command -v cargo &> /dev/null; then
             echo -e "\n[-] cargo (rust) NOT Found\n"
             export CONTINUE="NO" && exit 1
          else
             rustup default stable
             rustc --version && cargo --version
          fi
         #----------------------#
         #staticx: https://github.com/JonathonReinhart/staticx/blob/main/.github/workflows/build-test.yml
          pushd "$($TMPDIRS)" >/dev/null 2>&1
          #Switch to default: https://github.com/JonathonReinhart/staticx/pull/284
          git clone --filter "blob:none" "https://github.com/JonathonReinhart/staticx" --branch "add-type-checking" && cd "./staticx"
          #https://github.com/JonathonReinhart/staticx/blob/main/build.sh
          pip install -r "./requirements.txt" --break-system-packages --upgrade --force
          sudo apt-get update -y
          sudo apt-get install -y busybox musl-tools scons
          export BOOTLOADER_CC="musl-gcc"
          rm -rf "./build" "./dist" "./scons_build" "./staticx/assets"
          python "./setup.py" sdist bdist_wheel
          find "dist/" -name "*.whl" | xargs -I {} sh -c 'newname=$(echo {} | sed "s/none-[^/]*\.whl$/none-any.whl/"); mv "{}" "$newname"'
          find "dist/" -name "*.whl" | xargs pip install --break-system-packages --upgrade --force
          staticx --version || pip install staticx --break-system-packages --force-reinstall --upgrade ; unset BOOTLOADER_CC
          popd >/dev/null 2>&1
         #----------------------#
         ##Setup Void (xbps)
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-alternatives" -o "/usr/local/bin/xbps-alternatives" && sudo chmod +x "/usr/local/bin/xbps-alternatives"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-checkvers" -o "/usr/local/bin/xbps-checkvers" && sudo chmod +x "/usr/local/bin/xbps-checkvers"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-create" -o "/usr/local/bin/xbps-create" && sudo chmod +x "/usr/local/bin/xbps-create"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-dgraph" -o "/usr/local/bin/xbps-dgraph" && sudo chmod +x "/usr/local/bin/xbps-dgraph"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-digest" -o "/usr/local/bin/xbps-digest" && sudo chmod +x "/usr/local/bin/xbps-digest"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-fbulk" -o "/usr/local/bin/xbps-fbulk" && sudo chmod +x "/usr/local/bin/xbps-fbulk"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-fetch" -o "/usr/local/bin/xbps-fetch" && sudo chmod +x "/usr/local/bin/xbps-fetch"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-install" -o "/usr/local/bin/xbps-install" && sudo chmod +x "/usr/local/bin/xbps-install"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-pkgdb" -o "/usr/local/bin/xbps-pkgdb" && sudo chmod +x "/usr/local/bin/xbps-pkgdb"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-query" -o "/usr/local/bin/xbps-query" && sudo chmod +x "/usr/local/bin/xbps-query"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-reconfigure" -o "/usr/local/bin/xbps-reconfigure" && sudo chmod +x "/usr/local/bin/xbps-reconfigure"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-remove" -o "/usr/local/bin/xbps-remove" && sudo chmod +x "/usr/local/bin/xbps-remove"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-rindex" -o "/usr/local/bin/xbps-rindex" && sudo chmod +x "/usr/local/bin/apk-static"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-uchroot" -o "/usr/local/bin/xbps-uchroot" && sudo chmod +x "/usr/local/bin/xbps-uchroot"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-uhelper" -o "/usr/local/bin/xbps-uhelper" && sudo chmod +x "/usr/local/bin/xbps-uhelper"
          sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/Baseutils/xbps/xbps-uunshare" -o "/usr/local/bin/xbps-uunshare" && sudo chmod +x "/usr/local/bin/xbps-uunshare"
    fi
    #-------------------------------------------------------#
    
    #-------------------------------------------------------#
    ##Clean
    echo "INITIALIZED" > "$SYSTMP/INITIALIZED"
    rm -rf "$SYSTMP/init_Debian" 2>/dev/null
    #-------------------------------------------------------#
    ##END
    echo -e "\n\n [+] Finished Initializing $(uname -mnrs) :: at $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
    #In case of polluted env 
    unset ANDROID_TARGET AR AS CC CFLAGS CPP CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LD LDFLAGS LIBS NM OBJCOPY OBJDUMP RANLIB READELF SIZE STRINGS STRIP SYSROOT
    #-------------------------------------------------------#
  #EOF
fi
popd >/dev/null 2>&1
echo -e "\n[+] Continue : $CONTINUE\n"
#-------------------------------------------------------#
