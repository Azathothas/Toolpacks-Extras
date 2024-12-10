#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch FlatPak data
## Files:
#   "${SYSTMP}/PKGSRC.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_pkgsrc.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_pkgsrc.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/PKGSRC.json" 2>/dev/null
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Data
#Fetch repo
pushd "${TMPDIR}" >/dev/null 2>&1
git clone --filter="blob:none" --depth="1" "https://github.com/NetBSD/pkgsrc"
git clone --filter="blob:none" --depth="1" "git://wip.pkgsrc.org/pkgsrc-wip.git" "./pkgsrc/wip-repo"
find "./pkgsrc" -type f -name "DESCR" | xargs -P "$(($(nproc)+1))" -I {} sh -c '
    PKG=$(basename "$(dirname "{}")");
    DESCR=$(jq -aRs '"'"'gsub("\n";"<br>")'"'"' "{}");
    printf '"'"'{"pkg":"%s","description":%s}\n'"'"' "$PKG" "$DESCR"
' | jq -s '.' > "${TMPDIR}/PKGSRC.json.tmp"
if jq --exit-status . "${TMPDIR}/PKGSRC.json.tmp" >/dev/null 2>&1; then
 cat "${TMPDIR}/PKGSRC.json.tmp" | jq '
 [.[] | {
   pkg: (.pkg // ""),
   description: (
     .description // "" 
     | gsub("\\n[ \t]+"; "<br>")
     | gsub("<br>$"; "")
     | gsub("<br>\\s*<br>"; "<br>")
     | gsub("<br>\\s*<br>+"; "<br>")
     | gsub("\".*?\""; "")
     | gsub("\\s{2,}"; " ")
     | gsub("//"; "")
     | gsub("\\t"; " ")
   ),
 }] | sort_by(.pkg)' | jq . > "${TMPDIR}/PKGSRC.json"
fi
#Copy
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/PKGSRC.json" | wc -l)" -gt 10000 ]]; then
  cp -fv "${TMPDIR}/PKGSRC.json" "${SYSTMP}/PKGSRC.json"
else
  echo -e "\n[-] FATAL: Failed to Generate Pkgsrc Metadata\n"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#