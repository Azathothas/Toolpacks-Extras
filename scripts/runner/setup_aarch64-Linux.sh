#!/usr/bin/env bash

# VERSION=0.0.1
#-------------------------------------------------------#
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Setup Build Machine
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/setup_aarch64-Linux.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/runner/setup_$(uname -m)-$(uname -s).sh")
###-----------------------------------------------------###
### Setups Essential Tools & Preps Sys Environ for Deps ###
### This Script must be run as `root` (passwordless)    ###
### Assumptions: Arch: AMD_64 | OS: Debian 64bit        ###
###-----------------------------------------------------###

#-------------------------------------------------------#
##ENV
if [ -z "${SYSTMP+x}" ] || [ -z "${SYSTMP##*[[:space:]]}" ]; then
 SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
fi
USER="$(whoami)" && export USER="${USER}"
HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
if command -v awk >/dev/null 2>&1 && command -v sed >/dev/null 2>&1; then
 PATH="$(echo "${PATH}" | awk 'BEGIN{RS=":";ORS=":"}{gsub(/\n/,"");if(!a[$0]++)print}' | sed 's/:*$//')" ; export PATH
fi
#-------------------------------------------------------#
##Sanity Checks
##Check if it was recently initialized
 # +360  --> 06 Hrs
 # +720  --> 12 HRs
 # +1440 --> 24 HRs
find "${SYSTMP}/INITIALIZED" -type f -mmin +720 -exec rm -rvf "{}" \; 2>/dev/null
if [ -s "${SYSTMP}/INITIALIZED" ]; then
    echo -e "\n[+] Recently Initialized... (Skipping!)\n"
    export CONTINUE="YES"
    return 0 || exit 0
else
 ##Sane Configs
 #In case of removed/privated GH repos
  # https://git-scm.com/docs/git#Documentation/git.txt-codeGITTERMINALPROMPTcode
  export GIT_TERMINAL_PROMPT="0"
  #https://git-scm.com/docs/git#Documentation/git.txt-codeGITASKPASScode
  export GIT_ASKPASS="/bin/echo"
 #Eget
 EGET_TIMEOUT="timeout -k 1m 2m" && export EGET_TIMEOUT="${EGET_TIMEOUT}"
 ##Check for apt
  if ! command -v apt &> /dev/null; then
     echo -e "\n[-] apt NOT Found"
     echo -e "\n[+] Maybe not on Debian (Debian Based Distro) ?\n"
     #Fail & exit
     export CONTINUE="NO"
     return 1 || exit 1
  else
    #Export as noninteractive
    export DEBIAN_FRONTEND="noninteractive"
    export CONTINUE="YES"
  fi
 ##Check for sudo
  if [ "${CONTINUE}" == "YES" ]; then
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
       export CONTINUE="NO"
       return 1 || exit 1
     fi
   fi
  fi 
 ##Check for passwordless sudo
  if [ "${CONTINUE}" == "YES" ]; then
   if sudo -n true 2>/dev/null; then
       echo -e "\n[+] Passwordless sudo is Configured"
       sudo grep -E '^\s*[^#]*\s+ALL\s*=\s*\(\s*ALL\s*\)\s+NOPASSWD:' "/etc/sudoers" 2>/dev/null
   else
       echo -e "\n[-] Passwordless sudo is NOT Configured"
       echo -e "\n[-] READ: https://web.archive.org/web/20230614212916/https://linuxhint.com/setup-sudo-no-password-linux/\n"
       #exit
       export CONTINUE="NO"
       return 1 || exit 1
   fi
  fi
 ##Install Needed CMDs
  bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/devscripts/main/Linux/install_bins_curl.sh")
 ##Check Needed CMDs
 for DEP_CMD in eget gh glab oras rclone soar; do
    case "$(command -v "${DEP_CMD}" 2>/dev/null)" in
        "") echo -e "\n[✗] FATAL: ${DEP_CMD} is NOT INSTALLED\n"
           export CONTINUE="NO"
            return 1 || exit 1 ;;
    esac
 done
 ##Check for GITHUB_TOKEN
  if [ -n "${GITHUB_TOKEN+x}" ] && [ -n "${GITHUB_TOKEN##*[[:space:]]}" ]; then
   echo -e "\n[+] GITHUB_TOKEN is Exported"
   ##gh-cli (uses ${GITHUB_TOKEN} env var)
    #echo "${GITHUB_TOKEN}" | gh auth login --with-token
    gh auth status
   ##eget
    #5000 req/minute (80 req/minute)
    eget --rate
  else
   #60 req/hr
    echo -e "\n[-] GITHUB_TOKEN is NOT Exported"
    echo -e "Export it to avoid ratelimits\n"
    eget --rate
   export CONTINUE="NO"
   return 1 || exit 1
  fi
 ##Check for GHCR_TOKEN
  if [ -n "${GHCR_TOKEN+x}" ] && [ -n "${GHCR_TOKEN##*[[:space:]]}" ]; then
   echo -e "\n[+] GHCR_TOKEN is Exported"
   #echo "${GHCR_TOKEN}" | oras login --username "Azathothas" --password-stdin "ghcr.io"
    oras login --username "Azathothas" --password "${GHCR_TOKEN}" "ghcr.io"
  else
    echo -e "\n[-] GHCR_TOKEN is NOT Exported"
    echo -e "Export it to avoid ghcr\n"
   export CONTINUE="NO"
   return 1 || exit 1
  fi
 ##Check for Gitlab Token
  if [ -n "${GITLAB_TOKEN+x}" ] && [ -n "${GITLAB_TOKEN##*[[:space:]]}" ]; then
   echo -e "\n[+] GITLAB is Exported"
   glab auth status
  else
   echo -e "\n[-] GITLAB_TOKEN is NOT Exported"
   echo -e "Export it to avoid ratelimits\n"
  fi
fi
#-------------------------------------------------------#


#-------------------------------------------------------#
##Main
pushd "$(mktemp -d)" >/dev/null 2>&1
 echo -e "\n\n [+] Started Initializing $(uname -mnrs) :: at $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
 echo -e "[+] USER = ${USER}"
 echo -e "[+] HOME = ${HOME}"
 echo -e "[+] PATH = ${PATH}\n"
## If On Github Actions, remove bloat to get space (~ 30 GB) [DANGEROUS]
if [ "${CONTINUE}" == "YES" ]; then
 if [ "${USER}" = "runner" ] || [ "$(whoami)" = "runner" ] && [ -s "/opt/runner/provisioner" ]; then
  ##Debloat: https://github.com/pkgforge/devscripts/blob/main/Github/Runners/debloat_ubuntu.sh
   bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/devscripts/main/Github/Runners/debloat_ubuntu.sh")
   bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/devscripts/main/Github/Runners/debloat_ubuntu.sh") 2>/dev/null
 fi
#----------------------# 
##Install CoreUtils & Deps
#----------------------#
  sudo apt-get update -y 2>/dev/null
  sudo apt-get install apt-transport-https apt-utils ca-certificates coreutils gnupg2 moreutils software-properties-common util-linux -y 2>/dev/null ; sudo apt-get update -y 2>/dev/null
 #Install Build Des
  sudo apt-get install aria2 automake bc binutils b3sum build-essential ca-certificates ccache diffutils dos2unix gawk git-lfs imagemagick lzip jq libtool libtool-bin make musl musl-dev musl-tools p7zip-full rsync texinfo wget -y 2>/dev/null
  sudo apt-get install -y --no-install-recommends autoconf automake autopoint binutils bison build-essential byacc ca-certificates clang flex file jq libtool libtool-bin patch patchelf pkg-config qemu-user-static scons tree wget 2>/dev/null
  sudo apt-get install devscripts -y --no-install-recommends 2>/dev/null
  sudo apt-get install cmake -y
 #Re
  sudo apt-get install aria2 automake bc binutils b3sum build-essential ca-certificates ccache diffutils dos2unix gawk git-lfs imagemagick lzip jq libtool libtool-bin make musl musl-dev musl-tools p7zip-full rsync texinfo wget -y 2>/dev/null
  sudo apt-get install -y --no-install-recommends autoconf automake autopoint binutils bison build-essential byacc ca-certificates clang flex file jq libtool libtool-bin patch patchelf pkg-config qemu-user-static scons tree wget 2>/dev/null
  sudo apt-get install devscripts -y --no-install-recommends 2>/dev/null
  sudo apt-get install cmake -y
 #Install Build Dependencies (arm64)
  sudo apt install binutils-aarch64-linux-gnu -y 2>/dev/null
  sudo apt-get install "g++-arm-linux-gnueabi" "g++-arm-linux-gnueabihf" "g++-aarch64-linux-gnu" qemu-user-static -y 2>/dev/null
 #libpcap
  sudo apt install libpcap-dev pcaputils -y 2>/dev/null
 #libsqlite3
  sudo apt-get install libsqlite3-dev sqlite3 sqlite3-pcre sqlite3-tools -y 2>/dev/null
 #lzma
  sudo apt-get install liblz-dev librust-lzma-sys-dev lzma lzma-dev -y
 #Networking
  sudo apt-get install dnsutils 'inetutils*' net-tools netcat-traditional -y 2>/dev/null
  sudo apt-get install 'iputils*' -y 2>/dev/null
  sudo setcap cap_net_raw+ep "$(which ping)" 2>/dev/null
 #python
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
#----------------------#
##Langs
#----------------------#
 #Docker
 install_docker ()
 {
  #Install 
   curl -qfsSL "https://get.docker.com" | sed 's/sleep 20//g' | sudo bash
   sudo groupadd docker 2>/dev/null ; sudo usermod -aG docker "${USER}" 2>/dev/null
   sudo service docker restart 2>/dev/null && sleep 10
   sudo service docker status 2>/dev/null
   sudo systemctl status "docker.service" --no-pager
  #Test
   if ! command -v docker &> /dev/null; then
     echo -e "\n[-] docker NOT Found\n"
     export CONTINUE="NO"
     return 1 || exit 1
   else
     if ! sudo systemctl is-active --quiet docker; then
      sudo service docker restart >/dev/null 2>&1 ; sleep 10
     fi
     sudo systemctl status "docker.service" --no-pager
     docker --version ; sudo docker run hello-world
     sudo ldconfig && sudo ldconfig -p
     #newgrp 2>/dev/null
   fi
 }
 export -f install_docker
 if command -v docker &> /dev/null; then
  if [ "$(curl -qfsSL "https://endoflife.date/api/docker-engine.json" | jq -r '.[0].latest')" != "$(docker --version | grep -oP '(?<=version )(\d+\.\d+\.\d+)')" ]; then
   install_docker
  else
   echo -e "\n[+] Latest Docker seems to be already Installed"
   docker --version
   if ! sudo systemctl is-active --quiet docker; then
    sudo service docker restart >/dev/null 2>&1 ; sleep 10
   fi
   sudo systemctl status "docker.service" --no-pager
  fi
 else    
   install_docker
 fi
 #----------------------# 
 #Crystal
  curl -qfsSL "https://crystal-lang.org/install.sh" | sudo bash
  #Test
  if ! command -v crystal &> /dev/null; then
   echo -e "\n[-] crystal NOT Found\n"
   export CONTINUE="NO"
   return 1 || exit 1
  else
   crystal --version ; shards --version
   sudo ldconfig && sudo ldconfig -p
  fi
 #----------------------# 
 #Dockerc
  sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/dockerc" -o "/usr/local/bin/dockerc" && sudo chmod +x "/usr/local/bin/dockerc"
 #----------------------#          
 ##Install golang 
  echo "yes" | bash <(curl -qfsSL "https://git.io/go-installer")
  #Test
  if ! command -v go &> /dev/null; then
   echo -e "\n[-] go NOT Found\n"
   export CONTINUE="NO"
   return 1 || exit 1
  else
   go version
   sudo ldconfig && sudo ldconfig -p
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
  sudo ldconfig && sudo ldconfig -p          
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
     export CONTINUE="NO"
     return 1 || exit 1
  else
     nix --version && nix-channel --list && nix-channel --update
  fi
 ##Purge:
 #sudo rm -rf "/etc/bash.bashrc.backup-before-nix" "/etc/nix" "/nix" "/root/.nix-profile" "/root/.nix-defexpr" "/root/.nix-channels" "/root/.local/state/nix" "/root/.cache/nix" "${HOME}/.nix-profile" "${HOME}/.nix-defexpr" "${HOME}/.nix-channels" "${HOME}/.local/state/nix" "${HOME}/.cache/nix" 2>/dev/null
 #----------------------# 
 #rust & cargo
  bash <(curl -qfsSL "https://sh.rustup.rs") -y
  #Test: PATH="${HOME}/.cargo/bin:${HOME}/.cargo/env:${PATH}" 
  if ! command -v cargo &> /dev/null; then
   echo -e "\n[-] cargo (rust) NOT Found\n"
   export CONTINUE="NO"
   return 1 || exit 1
  else
   rustup default stable
   rustc --version && cargo --version
   #Cross-rs
   #cargo install cross --git "https://github.com/cross-rs/cross"
   sudo ldconfig && sudo ldconfig -p
  fi
##Clean
 if [ "${CONTINUE}" == "YES" ]; then
   echo "INITIALIZED" > "${SYSTMP}/INITIALIZED"
   rm -rf "${SYSTMP}/init_Debian" 2>/dev/null
   #-------------------------------------------------------#
   ##END
   echo -e "\n\n [+] Finished Initializing $(uname -mnrs) :: at $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
   #In case of polluted env 
   unset AR AS CC CFLAGS CPP CXX CPPFLAGS CXXFLAGS DLLTOOL HOST_CC HOST_CXX LD LDFLAGS LIBS NM OBJCOPY OBJDUMP RANLIB READELF SIZE STRINGS STRIP SYSROOT
 fi
fi
rm -rf "$(realpath .)" && popd >/dev/null 2>&1
echo -e "\n[+] Continue : ${CONTINUE}\n"
#-------------------------------------------------------#