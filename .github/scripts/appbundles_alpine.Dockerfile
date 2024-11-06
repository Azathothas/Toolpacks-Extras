# syntax=docker/dockerfile:1
#SELF: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/.github/scripts/appbundles_alpine.Dockerfile
#------------------------------------------------------------------------------------#
#https://github.com/xplshn/AppBundleHUB/tree/master/.github/workflows
FROM alpine:edge
#Allows to pass -e | --env="LOCAL_PELFDIR=$VALUE" otherwise sets /work/APP_BUNDLES as default
ARG LOCAL_PELFDIR="/work/APP_BUNDLES"
ENV LOCAL_PATH="${LOCAL_PELFDIR}"
#------------------------------------------------------------------------------------#
##Base Deps :: https://pkgs.alpinelinux.org/packages
RUN <<EOS
  set +e
  apk update && apk upgrade --no-interactive 2>/dev/null
  DEPS="7zip aria2 b3sum bash binutils build-base croc curl desktop-file-utils diffutils dos2unix file findutils fuse fuse3 gawk git go grep jq libarchive-tools libxi-dev libxcursor-dev libxinerama-dev libxrandr-dev linux-headers mesa-dev nano rsync tar tree upx wget xz"
  for pkg in $DEPS; do apk add "$pkg" --latest --upgrade --no-interactive ; done
EOS
#------------------------------------------------------------------------------------#
##PELF DEPS
RUN <<EOS
  #PELF DEPS
  set +e
 #Static Tools
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/bwrap" -o "/usr/bin/bwrap"
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/bwrap-patched" -o "/usr/bin/bwrap-patched"
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/dbin" -o "/usr/bin/dbin"
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/dwarfs-tools" -o "/usr/bin/dwarfs-tools"
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/eget" -o "/usr/bin/eget"
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/micro" -o "/usr/bin/micro"
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/sharun" -o "/usr/bin/sharun"
  curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/yq" -o "/usr/bin/yq"
  chmod -v +x "/usr/bin/bwrap" "/usr/bin/bwrap-patched" "/usr/bin/dbin" "/usr/bin/dwarfs-tools" "/usr/bin/eget" "/usr/bin/sharun" "/usr/bin/yq"
  ln -sfTv "/usr/bin/dwarfs-tools" "/usr/bin/dwarfs"
  ln -sfTv "/usr/bin/dwarfs-tools" "/usr/bin/dwarfsextract"
  ln -sfTv "/usr/bin/eget" "/usr/bin/eget2"
  ln -sfTv "/usr/bin/dwarfs-tools" "/usr/bin/mkdwarfs"
 #Build
  cd "$(mktemp -d)" >/dev/null 2>&1
  #git clone --depth="1" --filter="blob:none" --quiet "https://github.com/xplshn/pelf" --branch "dev" && cd "./pelf"
  git clone --depth="1" --filter="blob:none" --quiet "https://github.com/xplshn/pelf" && cd "./pelf"
  rsync -achLv "./cmd/misc/." "/usr/bin"
  cp -fv "./pelfCreator" "/usr/bin/pelfCreator"
  cp -fv "./pelf-dwfs" "/usr/bin/pelf-dwfs"
  cp -fv "./pelf-dwfs_extract" "/usr/bin/pelf-dwfs_extract"
  cp -fv "./pelf_linker" "/usr/bin/pelf_linker"
  cd "./cmd/dynexec" && rm -rvf "./go.mod"
  go mod init "github.com/xplshn/pelf/cmd/dynexec" ; go mod tidy
  CGO_ENABLED="1" CGO_CFLAGS="-O2 -flto=auto -fPIE -fpie -static -w -pipe" go build -v -trimpath -buildmode="pie" -ldflags="-s -w -buildid= -linkmode=external -extldflags '-s -w -static-pie -Wl,--build-id=none'" -o "/usr/bin/lib4bin" "./lib4bin"
  rm -rf "$(realpath .)" 2>/dev/null ; cd "/" >/dev/null 2>&1
  find "/usr/bin" -type f -exec chmod +x "{}" \;
EOS
#------------------------------------------------------------------------------------#
##Prep ENV
RUN <<EOS
  #Prep ENV
  set +e
 #Configure ENV
  curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/.bashrc" -o "/etc/bash.bashrc"
  ln -svf "/etc/bash.bashrc" "/root/.bashrc" 2>/dev/null || true
  ln -svf "/etc/bash.bashrc" "/home/alpine/.bashrc" 2>/dev/null || true
  ln -svf "/etc/bash.bashrc" "/etc/bash/bashrc" 2>/dev/null || true
 #Prep LOCAL_PATH 
  rm -rvf "${LOCAL_PATH}" 2>/dev/null || true
  mkdir -pv "${LOCAL_PATH}"
  chown -R "$(whoami):$(whoami)" "${LOCAL_PATH}"
  chmod -R 755 "${LOCAL_PATH}"
 #Get Required Files
  curl -qfsSL "https://pub.ajam.dev/utils/alpine-mini-$(uname -m)/rootfs.tar.gz" -o "${LOCAL_PATH}/rootfs.tgz"
  rsync -achLv "/usr/bin/bwrap-patched" "${LOCAL_PATH}/bwrap"
 #Sanity Check
  if [ ! -f "${LOCAL_PATH}/rootfs.tgz" ] || [ "$(stat -c %s "${LOCAL_PATH}/rootfs.tgz")" -le 10000 ]; then
     echo "${LOCAL_PATH}/rootfs.tgz DOES NOT Exist or is Broken"
     exit 1
  fi
EOS
ENV PATH="${LOCAL_PATH}:${PATH}"
#------------------------------------------------------------------------------------#