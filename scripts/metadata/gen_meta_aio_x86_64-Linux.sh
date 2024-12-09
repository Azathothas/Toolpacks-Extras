#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to generate METADATA AIO for x86_64-Linux
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/gen_meta_aio_x86_64-Linux.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/gen_meta_aio_x86_64-Linux.sh")
#-------------------------------------------------------#


#-------------------------------------------------------#
if [ -d "${GITHUB_WORKSPACE}" ] && [ "$(find "${GITHUB_WORKSPACE}" -mindepth 1 -print -quit 2>/dev/null)" ]; then
 ##Main (bin.pkgforge.dev)
  curl -qfsSL "https://bin.pkgforge.dev/x86_64/METADATA.json" -o "${SYSTMP}/METADATA.json.src"
  if [ "$(jq '. | length' "${SYSTMP}/METADATA.json.src")" -gt 1000 ]; then
     cat "${SYSTMP}/METADATA.json.src" |\
     jq -r '
       .[] | 
       "[[bin]]\n" +
       "pkg = \"\(.name)\"\n" +
       "pkg_family = \"\(.pkg_family // .name | gsub("\\.no_strip"; ""))\"\n" +
       "pkg_name = \"\(.name | gsub("\\.no_strip"; ""))\"\n" +
       "description = \"\(.description)\"\n" +
       "note = \"\(.note)\"\n" +
       "version = \"" + (if has("repo_version") then (if .repo_version == "" then "latest" else .repo_version end) else "latest" end) + "\"\n" +
       "download_url = \"" + (.download_url | sub("https://bin.ajam.dev/x86_64_Linux/"; "https://bin.pkgforge.dev/x86_64/")) + "\"\n" +
       "size = \"\(.size | ascii_upcase)\"\n" +
       "bsum = \"\(.b3sum)\"\n" +
       "shasum = \"\(.sha256)\"\n" +
       "build_date = \"\(.build_date)\"\n" +
       "src_url = \"\(.repo_url)\"\n" +
       "homepage = \"\(.web_url)\"\n" +
       "build_script = \"\(.build_script)\"\n" +
       "build_log = \"https://bin.pkgforge.dev/x86_64/\(.name).log.txt\"\n" +
       "category = \"" + (if .repo_topics == "" then "utility" else .repo_topics end) + "\"\n" +
       "icon = \"" + (if .icon == null or .icon == "" then "https://bin.pkgforge.dev/x86_64/bin.default.png" else .icon end) + "\"\n" +
       "provides = \"\(.extra_bins)\"\n"
     ' 2>/dev/null > "${SYSTMP}/x86_64-Linux-METADATA.toml"
     validtoml "${SYSTMP}/x86_64-Linux-METADATA.toml"
     ##BaseUtils (bin.pkgforge.dev)
     curl -qfsSL "https://bin.pkgforge.dev/x86_64/Baseutils/METADATA.json" |\
     jq -r '
       .[] | 
       "[[base]]\n" +
       "pkg = \"\(.name)\"\n" +
       "pkg_family = \"\( if (.build_script | type) == "string" and (.build_script | length > 0) then (.build_script | split("/") | .[-1] | split(".") | .[0] ) else (.name | gsub("\\.no_strip"; "")) end )\"\n" +
       "pkg_name = \"\(.name | gsub("\\.no_strip"; ""))\"\n" +
       "description = \"\(.description)\"\n" +
       "note = \"\(.note)\"\n" +
       "version = \"" + (if has("repo_version") then (if .repo_version == "" then "latest" else .repo_version end) else "latest" end) + "\"\n" +
       "download_url = \"" + (.download_url | sub("https://bin.ajam.dev/x86_64_Linux/"; "https://bin.pkgforge.dev/x86_64/")) + "\"\n" +
       "size = \"\(.size | ascii_upcase)\"\n" +
       "bsum = \"\(.b3sum)\"\n" +
       "shasum = \"\(.sha256)\"\n" +
       "build_date = \"\(.build_date)\"\n" +
       "src_url = \"\(.repo_url)\"\n" +
       "homepage = \"\(.web_url)\"\n" +
       "build_script = \"\(.build_script)\"\n" +
       "build_log = \"https://bin.pkgforge.dev/x86_64/" + (if (.build_script | type) == "string" and (.build_script | test(".*/.*\\..+")) then (.build_script | split("/") | last | split(".") | .[0]) else .name end) + ".log\"\n" +
       "category = \"" + (if .repo_topics == "" then "utility" else .repo_topics end) + "\"\n" +
       "icon = \"" + (if .icon == null or .icon == "" then "https://bin.pkgforge.dev/x86_64/base.default.png" else .icon end) + "\"\n" +
       "provides = \"\(.extra_bins)\"\n"
     ' 2>/dev/null >> "${SYSTMP}/x86_64-Linux-METADATA.toml"
     validtoml "${SYSTMP}/x86_64-Linux-METADATA.toml"
     ##Main (pkgcache.pkgforge.dev)
     curl -qfsSL "https://pkgcache.pkgforge.dev/x86_64/METADATA.min.json" |\
     jq -r '
       .[] |
       "[[pkg]]\n" +
       "pkg = \"\(.name)\"\n" +
       "pkg_family = \"\(.pkg_family // .name)\"\n" +
       "pkg_id = \"\(.bin_id)\"\n" +
       "pkg_name = \"\(.bin_name)\"\n" +
       "description = \"\(.description)\"\n" +
       "note = \"\(.note)\"\n" +
       "version = \"\(.version)\"\n" +
       "download_url = \"\(.download_url)\"\n" +
       "size = \"\(.size | ascii_upcase)\"\n" +
       "bsum = \"\(.bsum)\"\n" +
       "shasum = \"\(.shasum)\"\n" +
       "build_date = \"\(.build_date)\"\n" +
       "repology = \"\(.repology)\"\n" +
       "src_url = \"\(.src_url)\"\n" +
       "homepage = \"\(.web_url)\"\n" +
       "build_script = \"\(.build_script)\"\n" +
       "build_log = \"\(.build_log)\"\n" +
       "appstream = \"\(.appstream)\"\n" +
       "category = \"\(.category)\"\n" +
       "desktop = \"\(.desktop)\"\n" +
       "icon = \"" + (if .icon == null or .icon == "" then "https://pkgcache.pkgforge.dev/x86_64/pkg.default.png" else .icon end) + "\"\n" +
       "screenshots = [" +
         ( .screenshots // [] | map("\"" + . + "\"") | join(", ")) +
       "]\n" +
       "provides = \"\(.provides)\"\n" +
       "snapshots = [" +
         ( .snapshots // [] | map("\"" + . + "\"") | join(", ")) +
       "]\n"
     ' 2>/dev/null >> "${SYSTMP}/x86_64-Linux-METADATA.toml"
     #TOML
     taplo check "${SYSTMP}/x86_64-Linux-METADATA.toml" && cp "${SYSTMP}/x86_64-Linux-METADATA.toml" "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.bsum"
     7z a -t7z -mx="9" -mmt="$(($(nproc)+1))" -bsp1 -bt "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.xz" "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml" 2>/dev/null
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.xz" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.xz.bsum"
     zstd --ultra -22 --force "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml" -o "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.zstd"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.zstd" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml.zstd.bsum"
     #JSON
     cat "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml" | yj -tj | jq 'to_entries | sort_by(.key) | from_entries' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.bsum"
     7z a -t7z -mx="9" -mmt="$(($(nproc)+1))" -bsp1 -bt "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.xz" "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" 2>/dev/null
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.xz" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.xz.bsum"
     zstd --ultra -22 --force "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" -o "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.zstd"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.zstd" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json.zstd.bsum"
     #JSON (capnp)
     #to-capnp -i "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" -o "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp"
     #b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.bsum"
     #7z a -t7z -mx="9" -mmt="$(($(nproc)+1))" -bsp1 -bt "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.xz" "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp" 2>/dev/null
     #b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.xz" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.xz.bsum"
     #zstd --ultra -22 --force "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp" -o "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.zstd"
     #b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.zstd" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.soar.capnp.zstd.bsum"
     #JSON (MIN)
     cat "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" | jq -r tostring > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.bsum"
     7z a -t7z -mx="9" -mmt="$(($(nproc)+1))" -bsp1 -bt "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.xz" "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json" 2>/dev/null
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.xz" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.xz.bsum"
     zstd --ultra -22 --force "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json" -o "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.zstd"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.zstd" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.min.json.zstd.bsum"
     #YAML
     cat "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.toml" | yj -ty | yq . > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.bsum"
     7z a -t7z -mx="9" -mmt="$(($(nproc)+1))" -bsp1 -bt "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.xz" "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml" 2>/dev/null
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.xz" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.xz.bsum"
     zstd --ultra -22 --force "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml" -o "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.zstd"
     b3sum "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.zstd" | grep -oE '^[a-f0-9]{64}' | tr -d '[:space:]' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.yaml.zstd.bsum"
     #AM
     cat "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" | jq -r '.bin[] | "| \(.pkg) | \(.description) | \((.src_url | select(. != "")) // .homepage) | \(.download_url) | \((.bsum // "latest")[:12]) |"' > "${GITHUB_WORKSPACE}/main/x86_64-Linux/AM.txt"
     #cat "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" | jq -r '.base[] | "| \(.pkg) | \(.description) | \((.src_url | select(. != "")) // .homepage) | \(.download_url) | \((.bsum // "latest")[:12]) |"' >> "${GITHUB_WORKSPACE}/main/x86_64-Linux/AM.txt"
     cat "${GITHUB_WORKSPACE}/main/x86_64-Linux/METADATA.AIO.json" | jq -r '.pkg[] | "| \(.pkg) | \(.description) | \((.src_url | select(. != "")) // .homepage) | \(.download_url) | \(if .version and ((.version|tostring) | test("^[a-zA-Z0-9.-]+$")) then .version else (.bsum // "latest")[:12] end) |"' >> "${GITHUB_WORKSPACE}/main/x86_64-Linux/AM.txt"
     sort -u "${GITHUB_WORKSPACE}/main/x86_64-Linux/AM.txt" -o "${GITHUB_WORKSPACE}/main/x86_64-Linux/AM.txt"
     sed '/|[[:space:]]*|/d' -i "${GITHUB_WORKSPACE}/main/x86_64-Linux/AM.txt"
  fi
fi
#-------------------------------------------------------#