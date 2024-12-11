#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch Alpine data
## Files:
#   "${SYSTMP}/ALPINE.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_alpine.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_alpine.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/ALPINE.json" 2>/dev/null
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Data
#Fetch repo
pushd "${TMPDIR}" >/dev/null 2>&1
git clone --filter="blob:none" --depth="1" "https://gitlab.alpinelinux.org/alpine/aports.git"
find "./aports" -type f -name "APKBUILD" | xargs -P "$(($(nproc)+1))" -I {} sh -c '
    PKG=$(basename "$(dirname "{}")");
    DESCR=$(sed -n '"'"'s/^pkgdesc="\(.*\)"/\1/p'"'"' "{}" | jq -aRs '"'"'gsub("\n";"<br>")'"'"');
    VERSION=$(sed -n '"'"'s/^pkgver=\(.*\)/\1/p'"'"' "{}" | jq -aRs '"'"'gsub("\n";"")'"'"');
    HOMEPAGE=$(sed -n '"'"'s/^url="\(.*\)"/\1/p'"'"' "{}" | jq -aRs '"'"'gsub("\n";"<br>")'"'"');
    LICENSE=$(sed -n '"'"'s/^license="\(.*\)"/\1/p'"'"' "{}" | jq -aRs '"'"'gsub("\n";"<br>")'"'"');
    BUILD_SCRIPT=$(echo "{}" | sed "s|^./aports/\([^/]*\)/|https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/\1/|")
    printf '"'"'{"pkg":"%s","description":%s,"version":%s,"homepage":%s,"license":%s,"build_script":"%s"}\n'"'"' "$PKG" "$DESCR" "$VERSION" "$HOMEPAGE" "$LICENSE" "$BUILD_SCRIPT"
' | jq -s '.' > "${TMPDIR}/ALPINE.json.tmp"
if jq --exit-status . "${TMPDIR}/ALPINE.json.tmp" >/dev/null 2>&1; then
 cat "${TMPDIR}/ALPINE.json.tmp" | jq '
 def clean_text:
   gsub("\\n[ \t]+"; "<br>")
   | gsub("<br>$"; "")
   | gsub("<br>\\s*<br>"; "<br>")
   | gsub("<br>\\s*<br>+"; "<br>")
   | gsub("\".*?\""; "")
   | gsub("\\s{2,}"; " ")
   | gsub("//"; "")
   | gsub("\\t"; " ");
 [.[] | {
    pkg: (.pkg // "") | clean_text,
    description: (.description // "") | clean_text,
    version: (.version // "") | clean_text,
    homepage: (.homepage // "") | clean_text,
    license: (.license // "") | clean_text,
    build_script: (.build_script // "") | clean_text
 }] | sort_by(.pkg)' | jq . > "${TMPDIR}/ALPINE.json"
fi
#Copy
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/ALPINE.json" | wc -l)" -gt 10000 ]]; then
  cp -fv "${TMPDIR}/ALPINE.json" "${SYSTMP}/ALPINE.json"
else
  echo -e "\n[-] FATAL: Failed to Generate Alpine Metadata\n"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#