#!/usr/bin/env bash
#self source: 
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/setup_imagemagick.sh")
set -x
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
USER="$(whoami)" && export USER="${USER}"
HOME="$(getent passwd ${USER} | cut -d: -f6)" && export HOME="${HOME}"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
USER_AGENT="$(curl -qfsSL 'https://pub.ajam.dev/repos/Azathothas/Wordlists/Misc/User-Agents/ua_chrome_macos_latest.txt')" && export USER_AGENT="${USER_AGENT}"
#-------------------------------------------------------#

#-------------------------------------------------------#
#Get Src           
 pushd "$(mktemp -d)" >/dev/null 2>&1 && git clone --filter "blob:none" --depth="1" "https://github.com/ImageMagick/ImageMagick" && cd "./ImageMagick"
#Install Deps
 packages="imagemagick intltool libbz2-dev libdjvulibre-dev libdmr-dev libfftw3-dev libfontconfig-dev libfreetype6-dev libfribidi-dev libgraphviz-dev libharfbuzz-dev libheif-dev libjbig-dev libjpeg-dev libjxl-dev liblcms-dev liblcms2-dev liblqr-1-0-dev liblzma-dev libmagick++-dev libmagickcore-dev libopenexr-dev libopenjp2-7-dev libpng-dev liblqr-dev libraqm-dev libraw-dev librsvg2-dev libtiff-dev libturbojpeg0-dev libwebp-dev libwmf-dev libx11-dev libxml2-dev zlib1g-dev libzstd-dev libgs-dev libpstoedit-dev libzip-dev pstoedit"
 sudo apt update -y -qq
 for pkg in $packages; do DEBIAN_FRONTEND="noninteractive" sudo apt install -y -qq --ignore-missing "$pkg"; done ; unset packages
 sudo add-apt-repository "ppa:strukturag/libheif" -y
 sudo add-apt-repository "ppa:strukturag/libde265" -y
 sudo apt install libheif-dev -y -qq
 make dest clean 2>/dev/null ; make clean 2>/dev/null
 export CFLAGS="-O2 -flto=auto -w -pipe"
 export CPPFLAGS="${CFLAGS}"
 export CXXFLAGS="${CFLAGS}"
 export LDFLAGS="-s -Wl,-S -Wl,--build-id=none"
 "./configure" --enable-pipes --with-autotrace --with-dps --with-flif --with-fpx --with-fftw --with-gslib --with-gvc --with-rsvg --with-modules --with-perl --with-wmf --with-utilities --with-security-policy="open"
 sudo make --jobs="$(($(nproc)+1))" --keep-going install
 unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS packages
 set +x ; rm -rf "$(realpath .)" 2>/dev/null ; popd >/dev/null 2>&1
#-------------------------------------------------------#