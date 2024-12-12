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
curl -qfsSL "https://bin.pkgforge.dev/$(uname -m)/7z" -o "/usr/bin/7z" && chmod +x "/usr/bin/7z"
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/DEBIAN.json" 2>/dev/null
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Data
pushd "${TMPDIR}" >/dev/null 2>&1
#Fetch repo
curl -qfsSL "https://ftp.debian.org/debian/dists/stable/main/binary-amd64/Packages.xz" -o "./packages.xz"
if [[ -s "./packages.xz" ]] && [[ $(stat -c%s "./packages.xz") -gt 1000 ]]; then
 7z e "./packages.xz" -o. -y ; mkdir -pv "./packagedir"
 find "." -type f -iname "*package*" ! -iname "*.xz" -print0 | xargs -0 -I "{}" awk '
   BEGIN {
       pkg = ""
       content = ""
   }
   /^Package:/ {
       if (pkg != "") {
           # Write previous package to file
           print content > "./packagedir/" pkg ".txt"
           content = ""
       }
       pkg = $2
       gsub(/[^a-zA-Z0-9-]/, "", pkg)  # Sanitize filename
   }
   {
       content = content $0 "\n"
   }
   END {
       # Write last package
       if (pkg != "") {
           print content > "./packagedir/" pkg ".txt"
       }
   }
   ' "{}"
fi
if [ ! -d "./packagedir" ] || [ $(du -s "./packagedir" | cut -f1) -le 1000 ]; then
 echo -e "\n[-] FATAL: Broken Packages dir\n"
exit 1
else
 find "./packagedir" -type f -name "*.txt" -print0 | xargs -0 sed -i '/^[[:space:]]*$/d'
 find "./packagedir" -type f -name "*.txt" | wc -l
fi
#Process
process_package()
{
 #Fetch 
  pkg="$1"
  if [[ -s "./packagedir/$pkg.txt" ]] && [[ $(stat -c%s "./packagedir/$pkg.txt") -gt 100 ]]; then
   cat "./packagedir/$pkg.txt" | awk -v pkg="$pkg" '
    BEGIN {
        version=""; description=""; download_url=""; size=""; shasum=""; homepage=""
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
    /^Filename:/ {
        download_url = "https://deb.debian.org/debian/" $2
    }
    /^Size:/ {
        size = $2 + 0
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
        gsub(/["\\]/, "", download_url)
        gsub(/["\\]/, "", shasum)
        gsub(/["\\]/, "", human_size)
        gsub(/["\\]/, "", homepage)
        print "{"
        print "  \"pkg\": \"" pkg "\","
        print "  \"description\": \"" description "\","
        print "  \"version\": \"" version "\","
        print "  \"download_url\": \"" download_url "\","
        print "  \"size\": \"" human_size "\","
        print "  \"shasum\": \"" shasum "\","
        print "  \"homepage\": \"" homepage "\""
        print "}"
    }' 2>/dev/null
  fi
}
export -f process_package
#Generate
apt-cache pkgnames | sort -u | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'process_package "$@" 2>/dev/null' _ "{}" >> "${TMPDIR}/DEBIAN.json.raw"
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