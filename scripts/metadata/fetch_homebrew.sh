#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch homebrew data
## Files:
#   ${SYSTMP}/BREW_FORMULA.json
#   ${SYSTMP}/BREW_CASK.json
#
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_homebrew.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_homebrew.sh")
#-------------------------------------------------------#


#-------------------------------------------------------#
##ENV
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#cleanup
rm -rvf "${SYSTMP}/BREW_FORMULA.json" "${SYSTMP}/BREW_CASK.json" 2>/dev/null
#-------------------------------------------------------#

#-------------------------------------------------------#
##Analytics
curl -A "${USER_AGENT}" -qfsSL "https://formulae.brew.sh/api/analytics/install/30d.json" | jq -r '.items[] | {rank: (if (.number | type) == "string" then (.number | gsub(","; "")) else .number end), pkg: .formula}' | jq -s . > "${TMPDIR}/FORMULA_ANALYTICS.json"
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/FORMULA_ANALYTICS.json" | wc -l)" -le 7000 ]]; then
   echo -e "\n[-] FATAL: Something is wrong with Formula Analytics Data\n"
   echo "${TMPDIR}/FORMULA_ANALYTICS.json" | xargs -I {} sh -c 'realpath "{}"; file "{}"; du -sh "{}"; jq . "{}"'
  exit 1
fi
##Formula
#Fetch
func_formula(){
 curl -A "${USER_AGENT}" -qfsSL "https://formulae.brew.sh/api/formula.json" | jq '
   map({
     pkg: (.name // ""),
     pkg_family: (.full_name // ""),
     description: (.desc // ""),
     download_url: (.bottle.stable.files.x86_64_linux.url // ""),
     version: (.versions.stable // ""),
     homepage: (.homepage // ""),
     license: (.license // "")
   })
 ' > "${TMPDIR}/BREW_FORMULA.json"
 #Copy
 if jq --exit-status . "${TMPDIR}/BREW_FORMULA.json" >/dev/null 2>&1; then
    echo -e "\n[+] Fetched Formula ==> $(realpath ${TMPDIR}/BREW_FORMULA.json)\n"
    cp -fv "${TMPDIR}/BREW_FORMULA.json" "${TMPDIR}/BREW_FORMULA.json.raw"
   #Generate Ranked 
    echo -e "\n[+] Generating Ranked Formulae...\n"
    rank_map=$(jq -r 'map({(.pkg): .rank}) | add' "${TMPDIR}/FORMULA_ANALYTICS.json")
    jq -c '.[]' "${TMPDIR}/BREW_FORMULA.json.raw" | while read -r formula; do
        pkg_name="$(echo "$formula" | jq -r '.pkg')"
        rank="$(echo "$rank_map" | jq -r --arg pkg "$pkg_name" '.[$pkg]')"
        if [ -n "$rank" ]; then
            formula=$(echo "$formula" | jq --argjson rank "$rank" '. + {rank: ($rank // "")}')
        fi
        echo "$formula" >> "${TMPDIR}/BREW_FORMULA.json.rank"
    done
    jq -s '.' "${TMPDIR}/BREW_FORMULA.json.rank" > "${TMPDIR}/BREW_FORMULA.json.tmp"
   #Copy
   if [[ "$( jq -r '.[] | .pkg' "${TMPDIR}/BREW_FORMULA.json.tmp" | wc -l)" -gt 7000 ]]; then
      cp -fv "${TMPDIR}/BREW_FORMULA.json.tmp" "${SYSTMP}/BREW_FORMULA.json"
   else
     echo -e "\n[-] FATAL: Failed to Generate Ranked Formulae\n"   
   fi
 fi
}
export -f func_formula
#-------------------------------------------------------#

#-------------------------------------------------------#
##Gui Apps (https://formulae.brew.sh/cask/)
##Analytics
curl -A "${USER_AGENT}" -qfsSL "https://formulae.brew.sh/api/analytics/cask-install/homebrew-cask/30d.json" | jq -r '.formulae[] | .[] | {rank: (if (.count | type) == "string" then (.count | gsub(","; "")) | tonumber else .count end), pkg: .cask}' | jq -s 'sort_by(-.rank) | [range(length) as $i | .[$i] | .rank = ($i + 1)] | sort_by(.pkg)' > "${TMPDIR}/CASK_ANALYTICS.json"
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/CASK_ANALYTICS.json" | wc -l)" -le 5000 ]]; then
   echo -e "\n[-] FATAL: Something is wrong with Cask Analytics Data\n"
   echo "${TMPDIR}/CASK_ANALYTICS.json" | xargs -I {} sh -c 'realpath "{}"; file "{}"; du -sh "{}"; jq . "{}"'
  exit 1
fi
#Fetch
func_casks(){
 curl -A "${USER_AGENT}" -qfsSL "https://formulae.brew.sh/api/cask.json" | jq '
   map({
     pkg: (.token // ""),
     pkg_family: (.full_token // ""),
     description: (.desc // ""),
     version: (.version // ""),
     homepage: (.homepage // "")
   })
 ' > "${TMPDIR}/BREW_CASK.json"
 #Copy
 if jq --exit-status . "${TMPDIR}/BREW_CASK.json" >/dev/null 2>&1; then
    echo -e "\n[+] Fetched Casks ==> $(realpath ${TMPDIR}/BREW_CASK.json)\n"
    cp -fv "${TMPDIR}/BREW_CASK.json" "${TMPDIR}/BREW_CASK.json.raw"
   #Generate Ranked
    echo -e "\n[+] Generating Ranked Casks...\n"
    rank_map=$(jq -r 'map({(.pkg): .rank}) | add' "${TMPDIR}/CASK_ANALYTICS.json")
    jq -c '.[]' "${TMPDIR}/BREW_CASK.json.raw" | while read -r formula; do
        pkg_name="$(echo "$formula" | jq -r '.pkg')"
        rank="$(echo "$rank_map" | jq -r --arg pkg "$pkg_name" '.[$pkg]')"
        if [ -n "$rank" ]; then
            formula=$(echo "$formula" | jq --argjson rank "$rank" '. + {rank: ($rank // "")}')
        fi
        echo "$formula" >> "${TMPDIR}/BREW_CASK.json.rank"
    done
    jq -s '.' "${TMPDIR}/BREW_CASK.json.rank" > "${TMPDIR}/BREW_CASK.json.tmp"
   #Copy
   if [[ "$( jq -r '.[] | .pkg' "${TMPDIR}/BREW_CASK.json.tmp" | wc -l)" -gt 7000 ]]; then
      cp -fv "${TMPDIR}/BREW_CASK.json.tmp" "${SYSTMP}/BREW_CASK.json"
   else
     echo -e "\n[-] FATAL: Failed to Generate Ranked Casks\n"   
   fi
 fi
}
export -f func_casks
#-------------------------------------------------------#

#-------------------------------------------------------#
##Run 
func_formula &
func_casks &
wait
echo -e "\n[+] Saved Formula ==> $(realpath ${SYSTMP}/BREW_FORMULA.json)"
echo -e "[+] Saved Casks ==> $(realpath ${SYSTMP}/BREW_CASK.json)\n"
#-------------------------------------------------------#