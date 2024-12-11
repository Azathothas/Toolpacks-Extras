#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch Debian data
## Files:
#   "${SYSTMP}/DEBIAN.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_debian.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_debian.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
apt clean -y -qq
apt update -y -qq
DEBIAN_FRONTEND="noninteractive" apt install coreutils curl findutils grep jq sed util-linux -y -qq 
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/DEBIAN.json" 2>/dev/null
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Data
#Fetch repo
pushd "${TMPDIR}" >/dev/null 2>&1
#Process
process_package() 
{
 #Fetch 
  pkg="$1"
  apt-cache show "$pkg" | awk -v pkg="$pkg" '
   BEGIN {
       version=""; description=""; homepage=""; size=""; shasum=""
   }
   #Trim leading and trailing whitespaces from fields
   {
       for (i=1; i<=NF; i++) gsub(/^ *| *$/, "", $i)
   }
   #Remove unwanted characters from values
   {
       #Remove asterisks, backticks, single and double quotes
       gsub(/\*\*/, "", pkg)
       gsub(/\*\*/, "")
       gsub(/`/, "")
       gsub(/'"'"'/, "")
       gsub(/"/, "")
   }
   /^Version:/ {
       version = substr($0, index($0, $2))
       gsub(/`|'"'"'|"|\*\*/, "", version)
   }
   /^Description:/ {
       description = substr($0, index($0, $2))
       gsub(/`|'"'"'|"|\*\*/, "", description)
   }
   /^Homepage:/ {
       homepage = substr($0, index($0, $2))
       gsub(/`|'"'"'|"|\*\*/, "", homepage)
   }
   /^Size:/ {
       size = $2
   }
   /^SHA256:/ {
       shasum = substr($0, index($0, $2))
       gsub(/`|'"'"'|"|\*\*/, "", shasum)
   }
   /^$/ {
       exit
   }
   END {
       #Human-readable size conversion
       human_size = size
       if (size >= 1073741824) {
           human_size = sprintf("%.2f GB", size / 1073741824)
       } else if (size >= 1048576) {
           human_size = sprintf("%.2f MB", size / 1048576)
       } else if (size >= 1024) {
           human_size = sprintf("%.2f KB", size / 1024)
       } else if (size != "") {
           human_size = sprintf("%d Bytes", size)
       }
       #JSON output with additional cleaning
       gsub(/["\\]/, "", pkg)
       gsub(/["\\]/, "", description)
       gsub(/["\\]/, "", version)
       gsub(/["\\]/, "", shasum)
       gsub(/["\\]/, "", human_size)
       gsub(/["\\]/, "", homepage)
       print "{"
       print "  \"pkg\": \"" pkg "\","
       print "  \"description\": \"" description "\","
       print "  \"version\": \"" version "\","
       print "  \"size\": \"" human_size "\","
       print "  \"shasum\": \"" shasum "\","
       print "  \"homepage\": \"" homepage "\""
       print "}"
   }' 2>/dev/null
}
export -f process_package
#Generate
apt-cache pkgnames | sort -u | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'process_package "$@"' _ "{}" >> "${TMPDIR}/DEBIAN.json.raw"
jq -s '.' "${TMPDIR}/DEBIAN.json.raw" > "${TMPDIR}/DEBIAN.json.tmp"
if jq --exit-status . "${TMPDIR}/DEBIAN.json.tmp" >/dev/null 2>&1; then
 cp -fv "${TMPDIR}/DEBIAN.json.tmp" "${TMPDIR}/DEBIAN.json"
fi
#Copy
if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/DEBIAN.json" | wc -l)" -gt 10000 ]]; then
  cp -fv "${TMPDIR}/DEBIAN.json" "${SYSTMP}/DEBIAN.json"
else
  echo -e "\n[-] FATAL: Failed to Generate Debian Metadata\n"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#