#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Generate Web Metadata for the Store
## Files:
#   "${SYSTMP}/aarch64-Linux.METADATA.WEB.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/gen_meta_aio_aarch64-Linux_web.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/gen_meta_aio_aarch64-Linux_web.sh")
#-------------------------------------------------------#


#-------------------------------------------------------#
##ENV
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Fetch Files
rm -rvf "${SYSTMP}/METADATA.WEB.json" 2>/dev/null
curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/metadata/BREW_CASK.json" -o "${TMPDIR}/BREW_CASK.json"
curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/metadata/BREW_FORMULA.json" -o "${TMPDIR}/BREW_FORMULA.json"
curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/metadata/FLATPAK_APPS_INFO.json" -o "${TMPDIR}/FLATPAK_APPS_INFO.json"
curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/metadata/FLATPAK_POPULAR.json" -o "${TMPDIR}/FLATPAK_POPULAR.json"
curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/metadata/FLATPAK_TRENDING.json" -o "${TMPDIR}/FLATPAK_TRENDING.json"
curl -qfsSL "https://bin.pkgforge.dev/aarch64-Linux/METADATA.AIO.json" -o "${TMPDIR}/METADATA.AIO.json"
#-------------------------------------------------------#


#-------------------------------------------------------#
merge_from_brew_formula()
{
 pushd "$(mktemp -d)" >/dev/null 2>&1
 echo -e "\n[+] Syncing with Brew (Formula)\n"
 rm -rvf "${TMPDIR}/merged.json" "${TMPDIR}/output_base.json" "${TMPDIR}/output_bin.json" "${TMPDIR}/output_pkg.json" 2>/dev/null
 echo '{"base": [], "bin": [], "pkg": []}' > "${TMPDIR}/merged.json"
 process_array()
 {
   local array=$1
   local output_file="${TMPDIR}/output_${array}.json"
   jq -c ".${array}[]" "${TMPDIR}/METADATA.AIO.json" | while read -r pkg; do
    pkg_name="$(echo "$pkg" | jq -r '.pkg_family')"
   #Add Description
    description="$(echo "$pkg" | jq -r '.description // ""')"
    if [ "$description" == "" ] || [ "$description" == "null" ]; then
     description="$(jq -r --arg pkg "$pkg_name" '.[] | select(.pkg == $pkg) | .description // "No description available"' ${TMPDIR}/BREW_FORMULA.json)"
    fi
   #Add rank    
    current_rank="$(echo "$pkg" | jq -r 'if has("rank") and (.rank == "") then null else .rank end')"
    rank="$(jq -r --arg pkg "$pkg_name" '.[] | select(.pkg == $pkg) | .rank // null' ${TMPDIR}/BREW_FORMULA.json)"
   #Append 
    if [ "$rank" != "null" ] && [ "$current_rank" == "null" ]; then
        echo "$pkg" | jq --arg rank "$rank" --arg description "$description" '. + {rank: $rank, description: $description}'
    else
        echo "$pkg"
    fi
   done | jq -s '.' > "$output_file"
 }
 for array in base bin pkg; do
   process_array "$array" &
 done
 wait
 jq -s '.[0] * {"base": .[1], "bin": .[2], "pkg": .[3]}' \
   "${TMPDIR}/merged.json" \
   "${TMPDIR}/output_base.json" \
   "${TMPDIR}/output_bin.json" \
   "${TMPDIR}/output_pkg.json" > "${TMPDIR}/merged.json.tmp"
 if jq --exit-status . "${TMPDIR}/merged.json.tmp" >/dev/null 2>&1; then
  unset PKG_COUNT ; PKG_COUNT="$(cat "${TMPDIR}/merged.json.tmp" | jq -r '(.base[], .bin[], .pkg[]) | .pkg' | wc -l | tr -d '[:space:]')"
  if [[ "${PKG_COUNT}" -gt 2900 ]]; then
    cp -fv "${TMPDIR}/merged.json.tmp" "${TMPDIR}/METADATA.AIO.json"
  else
    echo -e "\n[+] Fatal: Failed to Sync with Brew (Formula)\n"
  fi
 fi
}
export -f merge_from_brew_formula
#-------------------------------------------------------#


#-------------------------------------------------------#
merge_from_brew_cask()
{
 pushd "$(mktemp -d)" >/dev/null 2>&1
 echo -e "\n[+] Syncing with Brew (Cask)\n"
 rm -rvf "${TMPDIR}/merged.json" "${TMPDIR}/output_base.json" "${TMPDIR}/output_bin.json" "${TMPDIR}/output_pkg.json" 2>/dev/null
 echo '{"base": [], "bin": [], "pkg": []}' > "${TMPDIR}/merged.json"
 process_array()
 {
   local array=$1
   local output_file="${TMPDIR}/output_${array}.json"
   jq -c ".${array}[]" "${TMPDIR}/METADATA.AIO.json" | while read -r pkg; do
    pkg_name="$(echo "$pkg" | jq -r '.pkg_family')"
   #Add Description
    description="$(echo "$pkg" | jq -r '.description // ""')"
    if [ "$description" == "" ] || [ "$description" == "null" ]; then
     description="$(jq -r --arg pkg "$pkg_name" '.[] | select(.pkg == $pkg) | .description // "No description available"' ${TMPDIR}/BREW_CASK.json)"
    fi
   #Add Rank
    current_rank="$(echo "$pkg" | jq -r 'if has("rank") and (.rank == "") then null else .rank end')"
    rank="$(jq -r --arg pkg "$pkg_name" '.[] | select(.pkg == $pkg) | .rank // null' ${TMPDIR}/BREW_CASK.json)"
   #Append 
    if [ "$rank" != "null" ] && [ "$current_rank" == "null" ]; then
        echo "$pkg" | jq --arg rank "$rank" --arg description "$description" '. + {rank: $rank, description: $description}'
    else
        echo "$pkg"
    fi
   done | jq -s '.' > "$output_file"
 }
 for array in base bin pkg; do
   process_array "$array" &
 done
 wait
 jq -s '.[0] * {"base": .[1], "bin": .[2], "pkg": .[3]}' \
   "${TMPDIR}/merged.json" \
   "${TMPDIR}/output_base.json" \
   "${TMPDIR}/output_bin.json" \
   "${TMPDIR}/output_pkg.json" > "${TMPDIR}/merged.json.tmp"
 if jq --exit-status . "${TMPDIR}/merged.json.tmp" >/dev/null 2>&1; then
  unset PKG_COUNT ; PKG_COUNT="$(cat "${TMPDIR}/merged.json.tmp" | jq -r '(.base[], .bin[], .pkg[]) | .pkg' | wc -l | tr -d '[:space:]')"
  if [[ "${PKG_COUNT}" -gt 2900 ]]; then
    cp -fv "${TMPDIR}/merged.json.tmp" "${TMPDIR}/METADATA.AIO.json"
  else
    echo -e "\n[+] Fatal: Failed to Sync with Brew (Casks)\n"
  fi
 fi
}
export -f merge_from_brew_cask
#-------------------------------------------------------#


#-------------------------------------------------------#
merge_from_flatpak_popular()
{
 pushd "$(mktemp -d)" >/dev/null 2>&1
 echo -e "\n[+] Syncing with Flatpak (Popular)\n"
 rm -rvf "${TMPDIR}/merged.json" "${TMPDIR}/output_base.json" "${TMPDIR}/output_bin.json" "${TMPDIR}/output_pkg.json" 2>/dev/null
 echo '{"base": [], "bin": [], "pkg": []}' > "${TMPDIR}/merged.json"
 process_array()
 {
   local array=$1
   local output_file="${TMPDIR}/output_${array}.json"
   jq -c ".${array}[]" "${TMPDIR}/METADATA.AIO.json" | while read -r pkg; do
   ##SWITCH TO APP_ID LATER
    app_id="$(echo "$pkg" | jq -r '.pkg_id')"
   #Add Description
    description="$(echo "$pkg" | jq -r '.description // ""')"
    if [ "$description" == "" ] || [ "$description" == "null" ]; then
     description="$(jq -r --arg app_id "$app_id" '.[] | select(.app_id == $app_id) | .description_long // "No description available"' ${TMPDIR}/FLATPAK_POPULAR.json)"
    fi
   #Add flaticon
    flaticon="$(jq -r --arg app_id "$app_id" '.[] | select(.app_id == $app_id) | .icon // null' ${TMPDIR}/FLATPAK_POPULAR.json)"
   #Add Rank
    current_rank="$(echo "$pkg" | jq -r 'if has("rank") and (.rank == "") then null else .rank end')"
    rank="$(jq -r --arg app_id "$app_id" '.[] | select(.app_id == $app_id) | .rank // null' ${TMPDIR}/FLATPAK_POPULAR.json)"
   #Append 
    if [ "$rank" != "null" ] && [ "$current_rank" == "null" ]; then
        echo "$pkg" | jq --arg description "$description" --arg flaticon "$flaticon" --arg rank "$rank" '. + {rank: $rank, flaticon: $flaticon, description: $description}'
    else
        echo "$pkg"
    fi
   done | jq -s '.' > "$output_file"
 }
 for array in base bin pkg; do
   process_array "$array" &
 done
 wait
 jq -s '.[0] * {"base": .[1], "bin": .[2], "pkg": .[3]}' \
   "${TMPDIR}/merged.json" \
   "${TMPDIR}/output_base.json" \
   "${TMPDIR}/output_bin.json" \
   "${TMPDIR}/output_pkg.json" > "${TMPDIR}/merged.json.tmp"
 if jq --exit-status . "${TMPDIR}/merged.json.tmp" >/dev/null 2>&1; then
  unset PKG_COUNT ; PKG_COUNT="$(cat "${TMPDIR}/merged.json.tmp" | jq -r '(.base[], .bin[], .pkg[]) | .pkg' | wc -l | tr -d '[:space:]')"
  if [[ "${PKG_COUNT}" -gt 2900 ]]; then
    cp -fv "${TMPDIR}/merged.json.tmp" "${TMPDIR}/METADATA.AIO.json"
  else
    echo -e "\n[+] Fatal: Failed to Sync with Flatpak (Popular)\n"
  fi
 fi
}
export -f merge_from_flatpak_popular
#-------------------------------------------------------#


#-------------------------------------------------------#
merge_from_flatpak_trending()
{
 pushd "$(mktemp -d)" >/dev/null 2>&1
 echo -e "\n[+] Syncing with Flatpak (Trending)\n"
 rm -rvf "${TMPDIR}/merged.json" "${TMPDIR}/output_base.json" "${TMPDIR}/output_bin.json" "${TMPDIR}/output_pkg.json" 2>/dev/null
 echo '{"base": [], "bin": [], "pkg": []}' > "${TMPDIR}/merged.json"
 process_array()
 {
   local array=$1
   local output_file="${TMPDIR}/output_${array}.json"
   jq -c ".${array}[]" "${TMPDIR}/METADATA.AIO.json" | while read -r pkg; do
   ##SWITCH TO APP_ID LATER
    app_id="$(echo "$pkg" | jq -r '.pkg_id')"
   #Add Description
    description="$(echo "$pkg" | jq -r '.description // ""')"
    if [ "$description" == "" ] || [ "$description" == "null" ]; then
     description="$(jq -r --arg app_id "$app_id" '.[] | select(.app_id == $app_id) | .description_long // "No description available"' ${TMPDIR}/FLATPAK_TRENDING.json)"
    fi
   #Add flaticon
    flaticon="$(jq -r --arg app_id "$app_id" '.[] | select(.app_id == $app_id) | .icon // null' ${TMPDIR}/FLATPAK_TRENDING.json)"
   #Add Rank
    current_rank="$(echo "$pkg" | jq -r 'if has("rank") and (.rank == "") then null else .rank end')"
    rank="$(jq -r --arg app_id "$app_id" '.[] | select(.app_id == $app_id) | .rank // null' ${TMPDIR}/FLATPAK_TRENDING.json)"
   #Append 
    if [ "$rank" != "null" ] && [ "$current_rank" == "null" ]; then
        echo "$pkg" | jq --arg description "$description" --arg flaticon "$flaticon" --arg rank "$rank" '. + {rank: $rank, flaticon: $flaticon, description: $description}'
    else
        echo "$pkg"
    fi
   done | jq -s '.' > "$output_file"
 }
 for array in base bin pkg; do
   process_array "$array" &
 done
 wait
 jq -s '.[0] * {"base": .[1], "bin": .[2], "pkg": .[3]}' \
   "${TMPDIR}/merged.json" \
   "${TMPDIR}/output_base.json" \
   "${TMPDIR}/output_bin.json" \
   "${TMPDIR}/output_pkg.json" > "${TMPDIR}/merged.json.tmp"
 if jq --exit-status . "${TMPDIR}/merged.json.tmp" >/dev/null 2>&1; then
  unset PKG_COUNT ; PKG_COUNT="$(cat "${TMPDIR}/merged.json.tmp" | jq -r '(.base[], .bin[], .pkg[]) | .pkg' | wc -l | tr -d '[:space:]')"
  if [[ "${PKG_COUNT}" -gt 2900 ]]; then
    cp -fv "${TMPDIR}/merged.json.tmp" "${TMPDIR}/METADATA.AIO.json"
  else
    echo -e "\n[+] Fatal: Failed to Sync with Flatpak (Trending)\n"
  fi
 fi
}
export -f merge_from_flatpak_trending
#-------------------------------------------------------#


#-------------------------------------------------------#
pushd "${TMPDIR}" >/dev/null 2>&1
merge_from_brew_formula
merge_from_brew_cask
merge_from_flatpak_popular
merge_from_flatpak_trending
#Final cleanup
if jq --exit-status . "${TMPDIR}/merged.json.tmp" >/dev/null 2>&1; then
unset PKG_COUNT ; PKG_COUNT="$(cat "${TMPDIR}/merged.json.tmp" | jq -r '(.base[], .bin[], .pkg[]) | .pkg' | wc -l | tr -d '[:space:]')"
  if [[ "${PKG_COUNT}" -gt 2900 ]]; then
    jq 'walk(if type == "object" then with_entries(select(.value != null and .value != "")) else . end)' "${TMPDIR}/merged.json.tmp" | jq . > "${SYSTMP}/aarch64-Linux.METADATA.WEB.json"
  else
    echo -e "\n[+] Fatal: Failed to Generate Web Metadata\n"
  fi
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#