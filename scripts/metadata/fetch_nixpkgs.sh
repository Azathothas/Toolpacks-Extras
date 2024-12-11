#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch NixOs data
## Files:
#   "${SYSTMP}/NIXPKGS.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_nixpkgs.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_nixpkgs.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/NIXPKGS.json" 2>/dev/null
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Data
#Fetch repo
pushd "${TMPDIR}" >/dev/null 2>&1
curl -qfsSL "https://raw.githubusercontent.com/Azathothas/NixOS-Packages/refs/heads/main/nixpkgs.json" | jq 'to_entries | map({pkg: .value.pname, description: .value.description, version: .value.version}) | sort_by(.pkg) | .' > "${TMPDIR}/NIXPKGS.json.tmp"
if jq --exit-status . "${TMPDIR}/NIXPKGS.json.tmp" >/dev/null 2>&1; then
 cp -fv "${TMPDIR}/NIXPKGS.json.tmp" "${TMPDIR}/NIXPKGS.json"
fi
#Copy
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/NIXPKGS.json" | wc -l)" -gt 10000 ]]; then
  cp -fv "${TMPDIR}/NIXPKGS.json" "${SYSTMP}/NIXPKGS.json"
else
  echo -e "\n[-] FATAL: Failed to Generate NixOs Metadata\n"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#