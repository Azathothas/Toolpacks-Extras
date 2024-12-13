#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Update our R2
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/upload_to_r2.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/upload_to_r2.sh")
#-------------------------------------------------------#


#-------------------------------------------------------#
if command -v rclone &> /dev/null && [ -s "${HOME}/.rclone.conf" ] && [ -d "${GITHUB_WORKSPACE}" ] && [ "$(find "${GITHUB_WORKSPACE}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
   #chdir to Repo
   cd "${GITHUB_WORKSPACE}/main"
   #Git pull
   git pull origin main --no-edit 2>/dev/null
   #Del Bloat
   rm -rf "$(pwd)/.git"
   #Upload to Pub
   echo -e "[+] Syncing ${GITHUB_REPOSITORY} to pub.ajam.dev/repos/${GITHUB_REPOSITORY} \n"
   rclone sync "." "r2:/pub/repos/${GITHUB_REPOSITORY}/" --user-agent="${USER_AGENT}" --buffer-size="100M" --s3-upload-concurrency="500" --s3-chunk-size="100M" --multi-thread-streams="500" --checkers="2000" --transfers="1000" --check-first --checksum --copy-links --fast-list --progress
   #Upload AIO files (aarch64-Linux) ==> (https://bin.ajam.dev/aarch64_arm64_Linux/)
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/ALPINE_GIT.json" "r2:/bin/aarch64_arm64_Linux/ALPINE_GIT.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/ALPINE_PKG.json" "r2:/bin/aarch64_arm64_Linux/ALPINE_PKG.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/ARCHLINUX.json" "r2:/bin/aarch64_arm64_Linux/ARCHLINUX.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/BREW_FORMULA.json" "r2:/bin/aarch64_arm64_Linux/BREW_FORMULA.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/BREW_CASK.json" "r2:/bin/aarch64_arm64_Linux/BREW_CASK.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/DEBIAN.json" "r2:/bin/aarch64_arm64_Linux/DEBIAN.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APPSTREAM.xml" "r2:/bin/aarch64_arm64_Linux/FLATPAK_APPSTREAM.xml" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APPS_INFO.txt" "r2:/bin/aarch64_arm64_Linux/FLATPAK_APPS_INFO.txt" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APPS_INFO.json" "r2:/bin/aarch64_arm64_Linux/FLATPAK_APPS_INFO.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APP_IDS.txt" "r2:/bin/aarch64_arm64_Linux/FLATPAK_APP_IDS.txt" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_POPULAR.json" "r2:/bin/aarch64_arm64_Linux/FLATPAK_POPULAR.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_TRENDING.json" "r2:/bin/aarch64_arm64_Linux/FLATPAK_TRENDING.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/NIXPKGS.json" "r2:/bin/aarch64_arm64_Linux/NIXPKGS.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/PKGSRC.json" "r2:/bin/aarch64_arm64_Linux/PKGSRC.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/AM.txt" "r2:/bin/aarch64_arm64_Linux/AM.txt" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/LATEST.json" "r2:/bin/aarch64_arm64_Linux/LATEST.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/POPULAR.json" "r2:/bin/aarch64_arm64_Linux/POPULAR.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/TRENDING.json" "r2:/bin/aarch64_arm64_Linux/TRENDING.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.db" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.db" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.db.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.db.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.db.xz" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.db.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.db.xz.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.db.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.db.zstd" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.db.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.db.zstd.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.db.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.json" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.WEB.json" "r2:/bin/aarch64_arm64_Linux/METADATA.WEB.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.json.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.json.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.json.xz" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.json.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.json.xz.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.json.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.json.zstd" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.json.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.json.zstd.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.json.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.min.json" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.min.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.min.json.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.min.json.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.min.json.xz" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.min.json.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.min.json.xz.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.min.json.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.min.json.zstd" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.min.json.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.min.json.zstd.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.min.json.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.soar.capnp" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.soar.capnp" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.soar.capnp.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.soar.capnp.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.soar.capnp.xz" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.soar.capnp.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.soar.capnp.xz.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.soar.capnp.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.soar.capnp.zstd" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.soar.capnp.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.soar.capnp.zstd.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.soar.capnp.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.toml" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.toml" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.toml.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.toml.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.toml.xz" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.toml.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.toml.xz.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.toml.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.toml.zstd" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.toml.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.toml.zstd.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.toml.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.yaml" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.yaml" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.yaml.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.yaml.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.yaml.xz" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.yaml.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.yaml.xz.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.yaml.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.yaml.zstd" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.yaml.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/aarch64-Linux/METADATA.AIO.yaml.zstd.bsum" "r2:/bin/aarch64_arm64_Linux/METADATA.AIO.yaml.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   wait
   #Upload AIO files (x86_64-Linux) ==> (https://bin.ajam.dev/x86_64_Linux/)
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/ALPINE_GIT.json" "r2:/bin/x86_64_Linux/ALPINE_GIT.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/ALPINE_PKG.json" "r2:/bin/x86_64_Linux/ALPINE_PKG.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/ARCHLINUX.json" "r2:/bin/x86_64_Linux/ARCHLINUX.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/BREW_FORMULA.json" "r2:/bin/x86_64_Linux/BREW_FORMULA.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/BREW_CASK.json" "r2:/bin/x86_64_Linux/BREW_CASK.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/DEBIAN.json" "r2:/bin/x86_64_Linux/DEBIAN.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APPSTREAM.xml" "r2:/bin/x86_64_Linux/FLATPAK_APPSTREAM.xml" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APPS_INFO.txt" "r2:/bin/x86_64_Linux/FLATPAK_APPS_INFO.txt" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APPS_INFO.json" "r2:/bin/x86_64_Linux/FLATPAK_APPS_INFO.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_APP_IDS.txt" "r2:/bin/x86_64_Linux/FLATPAK_APP_IDS.txt" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_POPULAR.json" "r2:/bin/x86_64_Linux/FLATPAK_POPULAR.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/FLATPAK_TRENDING.json" "r2:/bin/x86_64_Linux/FLATPAK_TRENDING.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/NIXPKGS.json" "r2:/bin/x86_64_Linux/NIXPKGS.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/metadata/PKGSRC.json" "r2:/bin/x86_64_Linux/PKGSRC.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/AM.txt" "r2:/bin/x86_64_Linux/AM.txt" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/LATEST.json" "r2:/bin/x86_64_Linux/LATEST.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/POPULAR.json" "r2:/bin/x86_64_Linux/POPULAR.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/TRENDING.json" "r2:/bin/x86_64_Linux/TRENDING.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.db" "r2:/bin/x86_64_Linux/METADATA.AIO.db" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.db.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.db.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.db.xz" "r2:/bin/x86_64_Linux/METADATA.AIO.db.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.db.xz.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.db.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.db.zstd" "r2:/bin/x86_64_Linux/METADATA.AIO.db.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.db.zstd.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.db.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" "r2:/bin/x86_64_Linux/METADATA.AIO.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.WEB.json" "r2:/bin/x86_64_Linux/METADATA.WEB.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.json.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.xz" "r2:/bin/x86_64_Linux/METADATA.AIO.json.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.xz.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.json.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.zstd" "r2:/bin/x86_64_Linux/METADATA.AIO.json.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.zstd.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.json.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json" "r2:/bin/x86_64_Linux/METADATA.AIO.min.json" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.min.json.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.xz" "r2:/bin/x86_64_Linux/METADATA.AIO.min.json.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.xz.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.min.json.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.zstd" "r2:/bin/x86_64_Linux/METADATA.AIO.min.json.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.zstd.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.min.json.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp" "r2:/bin/x86_64_Linux/METADATA.AIO.soar.capnp" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.soar.capnp.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.xz" "r2:/bin/x86_64_Linux/METADATA.AIO.soar.capnp.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.xz.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.soar.capnp.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.zstd" "r2:/bin/x86_64_Linux/METADATA.AIO.soar.capnp.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   #rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.zstd.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.soar.capnp.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml" "r2:/bin/x86_64_Linux/METADATA.AIO.toml" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.toml.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.xz" "r2:/bin/x86_64_Linux/METADATA.AIO.toml.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.xz.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.toml.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.zstd" "r2:/bin/x86_64_Linux/METADATA.AIO.toml.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.zstd.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.toml.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml" "r2:/bin/x86_64_Linux/METADATA.AIO.yaml" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.yaml.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.xz" "r2:/bin/x86_64_Linux/METADATA.AIO.yaml.xz" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.xz.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.yaml.xz.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.zstd" "r2:/bin/x86_64_Linux/METADATA.AIO.yaml.zstd" --checksum --check-first --user-agent="${USER_AGENT}" &
   rclone copyto "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.zstd.bsum" "r2:/bin/x86_64_Linux/METADATA.AIO.yaml.zstd.bsum" --checksum --check-first --user-agent="${USER_AGENT}" &
   wait
fi
#-------------------------------------------------------#