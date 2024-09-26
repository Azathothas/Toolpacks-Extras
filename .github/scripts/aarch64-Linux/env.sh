#!/usr/bin/env bash
##
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/$(uname -m)-$(uname -s)/env.sh")
##

#-------------------------------------------------------#
USER="$(whoami)" && export USER="${USER}"
HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
HF_REPO_DL="https://huggingface.co/datasets/Azathothas/Toolpacks-Extras/resolve/main/$(uname -m)-$(uname -s)" && export HF_REPO_DL="${HF_REPO_DL}"
export PATH="${HOME}/bin:${HOME}/.cargo/bin:${HOME}/.cargo/env:${HOME}/.go/bin:${HOME}/go/bin:${HOME}/.local/bin:${HOME}/miniconda3/bin:${HOME}/miniconda3/condabin:/usr/local/zig:/usr/local/zig/lib:/usr/local/zig/lib/include:/usr/local/musl/bin:/usr/local/musl/lib:/usr/local/musl/include:$PATH"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIRS="mktemp -d --tmpdir=${SYSTMP}/toolpacks XXXXXXX_$(uname -m)_$(uname -s)" && export TMPDIRS="$TMPDIRS"
rm -rf "${SYSTMP}/toolpacks" 2>/dev/null ; mkdir -p "${SYSTMP}/toolpacks"
BINDIR="${SYSTMP}/toolpack_$(uname -m)" && export BINDIR="${BINDIR}"
rm -rf "${BINDIR}" 2>/dev/null ; mkdir -p "${BINDIR}"
export GIT_TERMINAL_PROMPT="0"
export GIT_ASKPASS="/bin/echo"
EGET_TIMEOUT="timeout -k 1m 2m" && export EGET_TIMEOUT="${EGET_TIMEOUT}"
USER_AGENT="$(curl -qfsSL 'https://pub.ajam.dev/repos/Azathothas/Wordlists/Misc/User-Agents/ua_chrome_macos_latest.txt')" && export USER_AGENT="${USER_AGENT}"
BUILD="YES" && export BUILD="${BUILD}"
sudo groupadd docker 2>/dev/null ; sudo usermod -aG docker "${USER}" 2>/dev/null
if ! sudo systemctl is-active --quiet docker; then
   sudo service docker restart >/dev/null 2>&1 ; sleep 10
fi
sudo systemctl status "docker.service" --no-pager
#Nix
source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
#sg docker newgrp "$(id -gn)"
cd "${HOME}" ; clear
##Sanity Checks
if [[ ! -n "${GITHUB_TOKEN}" ]]; then
   echo -e "\n[-] GITHUB_TOKEN is NOT Exported"
   echo -e "Export it to Use GH\n"
fi
if ! command -v git-lfs &> /dev/null; then
   echo -e "\n[-] git-lfs is NOT Installed\n"
fi
#huggingface-cli
if [[ ! -n "${HF_TOKEN}" ]]; then
   echo -e "\n[-] HF_TOKEN is NOT Exported"
   echo -e "Export it to Use huggingface-cli\n"
fi
if ! command -v huggingface-cli &> /dev/null; then
   echo -e "\n[-] huggingface-cli is NOT Installed\n"
fi
#-------------------------------------------------------#
history -c 2>/dev/null ; rm -rf "${HOME}/.bash_history" ; pushd "$(mktemp -d)" >/dev/null 2>&1
#-------------------------------------------------------#