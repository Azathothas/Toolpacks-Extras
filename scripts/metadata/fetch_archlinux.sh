#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch ArchLinux data
## Files:
#   "${SYSTMP}/ARCHLINUX.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_archlinux.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_archlinux.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
sudo pacman -Syy --noconfirm
sudo pacman -S coreutils curl findutils jq grep pacman-contrib sed --noconfirm
#sudo curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/7z" -o "/usr/bin/7z" && sudo chmod +x "/usr/bin/7z"
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/ARCHLINUX.json" 2>/dev/null
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Main
pushd "${TMPDIR}" >/dev/null 2>&1
#num_pages="$(curl -qfsSL "https://archlinux.org/packages/search/json/?repo=Extra&page=1" | jq -r ".num_pages")"
#seq 1 "$num_pages" | xargs -n1 -P0 -I"{}" curl -qfsSL "https://archlinux.org/packages/search/json/?repo=Extra&page={}" 2>/dev/null | jq -Rsc '[inputs | try fromjson catch null] | map(select(. != null))' > "${TMPDIR}/extra.json"
#Process pkg
process_package()
{
 #Fetch
  pkg="$1"
  pkg_info=$(pacman -Sii "$pkg" 2>/dev/null)
  package_data=$(echo "$pkg_info" | awk -v pkg="$pkg" '
   BEGIN {
       repo=""; version=""; description=""; url=""; size=""; license=""; 
       installed_size=""; description_full=""
   }
   /^Repository\s*:/ {
       repo = $NF
   }
   /^Name\s*:/ {
       gsub(/^Name\s*:\s*/, "", $0)
       pkg = $0
   }
   /^Version\s*:/ {
       version = $NF
   }
   /^Description\s*:/ {
       # Capture full description, removing leading ":"
       description_full = $0
       sub(/^Description\s*:\s*/, "", description_full)
   }
   /^URL\s*:/ {
       url = $NF
   }
   /^Licenses\s*:/ {
       license = $NF
   }
   /^Download Size\s*:/ {
    size = $(NF-1) " " $NF
   }
   END {
       #Clean description
       gsub(/["\\]/, "", repo)
       gsub(/["\\]/, "", pkg)
       gsub(/["\\]/, "", description_full)
       gsub(/["\\]/, "", version)
       gsub(/["\\]/, "", url)
       gsub(/["\\]/, "", size)
       gsub(/["\\]/, "", license)
       print repo "|" pkg "|" description_full "|" version "|" size "|" url "|" license
   }' 2>/dev/null)
  #Cleanup
  {
    build_date="$(echo "$pkg_info" | grep "^Build Date" | sed -E 's/^Build Date\s*:\s*//' | xargs -I "{}" date -d "{}" +"%Y-%m-%dT%H:%M:%S")"
    shasum="$(echo "$pkg_info" | grep "^SHA-256 Sum" | awk '{print $NF}')"
    #Merge
    IFS='|' read -r repo pkg description version size url license <<< "$package_data"
    size_value="$(echo "$size" | awk '{print $1}')"
    size_unit="$(echo "$size" | awk '{print $2}')"
    human_size=$(case "$size_unit" in
      KiB) printf "%.2f KB" $(echo "$size_value" | awk '{print $1/1}') ;;
      MiB) printf "%.2f MB" "$size_value" ;;
      GiB) printf "%.2f GB" "$size_value" ;;
      *) echo "$size" ;;
    esac)
  } >/dev/null 2>&1
  #Json
  jq -n \
    --arg repo "$repo" \
    --arg pkg "$pkg" \
    --arg description "$description" \
    --arg version "$version" \
    --arg size "$human_size" \
    --arg homepage "$url" \
    --arg license "$license" \
    --arg build_date "$build_date" \
    --arg shasum "$shasum" \
    '{
      "repo": $repo,
      "pkg": $pkg,
      "description": $description,
      "version": $version,
      "download_url": ("https://archlinux.org/packages/" + $repo + "/x86_64/" + $pkg + "/download/"),
      "size": $size,
      "homepage": $homepage,
      "license": $license,
      "build_date": $build_date,
      "build_script": ("https://gitlab.archlinux.org/archlinux/packaging/packages/" + $pkg + "/-/raw/main/PKGBUILD?ref_type=heads"),
      "shasum": $shasum
    }'
}
export -f process_package
#Generate
pacman -Ss '' | awk -F'/' '/\// {split($2, pkg, " "); print pkg[1]}' | grep -v '^\s*$' | sort -u | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'process_package "$@"' _ "{}" >> "${TMPDIR}/ARCH.json.raw"
if jq --exit-status . "${TMPDIR}/ARCH.json.raw" >/dev/null 2>&1; then
  jq -s 'map(select(.repo and .version)) | .' "${TMPDIR}/ARCH.json.raw" > "${TMPDIR}/ARCH.json.tmp"
fi
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/ARCH.json.tmp" | wc -l)" -gt 10000 ]]; then
  cp -fv "${TMPDIR}/ARCH.json.tmp" "${TMPDIR}/ARCH.json"
else
  echo -e "\n[-] FATAL: Failed to Generate ArchLinux Metadata\n"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate AUR
pushd "${TMPDIR}" >/dev/null 2>&1
curl -qfsSL "https://aur.archlinux.org/packages-meta-ext-v1.json.gz" -o "./aur.json.gz"
7z e "./aur.json.gz" -o. -y
find "." -type f -iname "*packages*.json" -print0 | xargs -0 jq '.[] | {
  repo: ("aur"),
  pkg: .Name,
  pkg_family: .PackageBase,
  description: .Description,
  version: .Version,
  download_url: ("https://aur.archlinux.org" + (.URLPath // "")),
  build_date: (.LastModified | if . then (todateiso8601 | sub("Z$"; "")) else "" end),
  build_script: ("https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=" + (.Name // "")),
  homepage: .URL,
  license: [.License // []],
  src_url: ("https://aur.archlinux.org/packages/" + (.Name // "")),
  tag: [.Keywords // []],
  rank: (if (.Popularity | type) == "string" then (.Popularity | gsub(","; "")) | tonumber else .Popularity end)
}' | jq -s 'sort_by(-.rank) | [range(length) as $i | .[$i] | .rank = ($i + 1)] | sort_by(.pkg) | .[] | .rank = (.rank | tostring)' | jq -s '.' > "${TMPDIR}/ARCHLINUXAUR.json.tmp"
#Copy
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/ARCHLINUXAUR.json.tmp" | wc -l)" -gt 10000 ]]; then
  cp -fv "${TMPDIR}/ARCHLINUXAUR.json.tmp" "${TMPDIR}/ARCHLINUXAUR.json"
else
  echo -e "\n[-] FATAL: Failed to Generate ArchLinux (Aur) Metadata\n"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#


#-------------------------------------------------------#
if [[ -s "${TMPDIR}/ARCH.json" && $(stat -c%s "${TMPDIR}/ARCH.json") -gt 1024 ]] && \
[[ -s "${TMPDIR}/ARCHLINUXAUR.json" && $(stat -c%s "${TMPDIR}/ARCHLINUXAUR.json") -gt 1024 ]]; then
 jq -n 'reduce inputs[] as $i ([]; . + [$i | select(.repo // "" != "")])' "${TMPDIR}/ARCH.json" "${TMPDIR}/ARCHLINUXAUR.json" | jq . > "${TMPDIR}/ARCHLINUX.json"
 if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/ARCHLINUX.json"| wc -l)" -gt 10000 ]]; then
   cp -fv "${TMPDIR}/ARCHLINUX.json" "${SYSTMP}/ARCHLINUX.json"
 else
   echo -e "\n[-] FATAL: Failed to Generate ArchLinux (Merged) Metadata\n"
 fi
fi
#-------------------------------------------------------#