#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch Alpine data
## Files:
#   "${SYSTMP}/ALPINE_PKG.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_alpine_pkg.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_alpine_pkg.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/ALPINE_PKG.json" 2>/dev/null
#-------------------------------------------------------#


#-------------------------------------------------------#
##Func
#Split Packages
split_apkindex()
{
 find "." -type f -iname "APKINDEX" ! -iname "*.tar*" -print0 | xargs -0 -I "{}" awk '
   BEGIN {
       pkg = ""
       content = ""
   }
   /^P:/ {
       if (pkg != "") {
           # Write previous package to file
           print content > "./packagedir/" pkg ".txt"
           content = ""
       }
       pkg = substr($0, 3)
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
 if [ ! -d "./packagedir" ] || [ $(du -s "./packagedir" | cut -f1) -le 1000 ]; then
  echo -e "\n[-] FATAL: Broken Packages dir\n"
 exit 1
 else
  find "./packagedir" -type f -name "*.txt" -print0 | xargs -0 sed -i '/^[[:space:]]*$/d'
  find "./packagedir" -type f -name "*.txt" | wc -l
 fi   
} 
export -f split_apkindex
#Process Packages (Main)
process_package_main()
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
    /^V:/ {
        version = substr($0, index($0, $1))
        gsub(/^V:/, "", version)
        gsub(/`|'"'"'|"|\*\*/, "", version)
    }
    /^T:/ {
        description = substr($0, index($0, $1))
        gsub(/^T:/, "", description)
        gsub(/`|'"'"'|"|\*\*/, "", description)
    }
    /^U:/ {
        homepage = substr($0, index($0, $1))
        gsub(/^U:/, "", homepage)
        gsub(/`|'"'"'|"|\*\*/, "", homepage)
    }
    /^S:/ {
        size = substr($0, 3) + 0
        gsub(/^S:/, "", size)
        gsub(/`|'"'"'|"|\*\*/, "", size)
    }
    /^c:/ {
        shasum = substr($0, index($0, $1))
        gsub(/^c:/, "", shasum)
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
        print "  \"homepage\": \"" homepage "\","
        print "  \"version\": \"" version "\","
        print "  \"download_url\": \"https://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64/" pkg "-" version ".apk\","
        print "  \"size\": \"" human_size "\","
        #print "  \"shasum\": \"" shasum "\"," #is inaccurate
        print "  \"build_script\": \"https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/main/" pkg "/APKBUILD\""
        print "}"
    }' 2>/dev/null
  fi
}
export -f process_package_main
#Process Packages (community)
process_package_community()
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
    /^V:/ {
        version = substr($0, index($0, $1))
        gsub(/^V:/, "", version)
        gsub(/`|'"'"'|"|\*\*/, "", version)
    }
    /^T:/ {
        description = substr($0, index($0, $1))
        gsub(/^T:/, "", description)
        gsub(/`|'"'"'|"|\*\*/, "", description)
    }
    /^U:/ {
        homepage = substr($0, index($0, $1))
        gsub(/^U:/, "", homepage)
        gsub(/`|'"'"'|"|\*\*/, "", homepage)
    }
    /^S:/ {
        size = substr($0, 3) + 0
        gsub(/^S:/, "", size)
        gsub(/`|'"'"'|"|\*\*/, "", size)
    }
    /^c:/ {
        shasum = substr($0, index($0, $1))
        gsub(/^c:/, "", shasum)
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
        print "  \"homepage\": \"" homepage "\","
        print "  \"version\": \"" version "\","
        print "  \"download_url\": \"https://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/" pkg "-" version ".apk\","
        print "  \"size\": \"" human_size "\","
        #print "  \"shasum\": \"" shasum "\"," #is inaccurate
        print "  \"build_script\": \"https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/community/" pkg "/APKBUILD\""
        print "}"
    }' 2>/dev/null
  fi
}
export -f process_package_community
#-------------------------------------------------------#


#-------------------------------------------------------#
##Generate Data
pushd "${TMPDIR}" >/dev/null 2>&1
#Fetch repo (Main)
curl -qfsSL "https://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64/APKINDEX.tar.gz" -o "./APKINDEX.tar.gz"
if [[ -s "./APKINDEX.tar.gz" ]] && [[ $(stat -c%s "./APKINDEX.tar.gz") -gt 1000 ]]; then
 tar -xzvf "./APKINDEX.tar.gz" ; rm -rf "./packagedir" 2>/dev/null ; mkdir -pv "./packagedir"
 split_apkindex
 find "./packagedir" -type f -iname "*.txt" | sed -E 's|.*/||; s|\.txt$||' | sort -u | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'process_package_main "$@" 2>/dev/null' _ "{}" >> "${TMPDIR}/ALPINE.json.main.tmp"
  if jq --exit-status . "${TMPDIR}/ALPINE.json.main.tmp" >/dev/null 2>&1; then
   cp -fv "${TMPDIR}/ALPINE.json.main.tmp" "${TMPDIR}/ALPINE.json.main"
  fi
fi
#Fetch repo (Community)
curl -qfsSL "https://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz" -o "./APKINDEX.tar.gz"
if [[ -s "./APKINDEX.tar.gz" ]] && [[ $(stat -c%s "./APKINDEX.tar.gz") -gt 1000 ]]; then
 tar -xzvf "./APKINDEX.tar.gz" ; rm -rf "./packagedir" 2>/dev/null ; mkdir -pv "./packagedir"
 split_apkindex
 find "./packagedir" -type f -iname "*.txt" | sed -E 's|.*/||; s|\.txt$||' | sort -u | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'process_package_community "$@" 2>/dev/null' _ "{}" >> "${TMPDIR}/ALPINE.json.community.tmp"
  if jq --exit-status . "${TMPDIR}/ALPINE.json.community.tmp" >/dev/null 2>&1; then
   cp -fv "${TMPDIR}/ALPINE.json.community.tmp" "${TMPDIR}/ALPINE.json.community"
  fi
fi
##Merge
if [[ -s "${TMPDIR}/ALPINE.json.main" ]] && [[ -s "${TMPDIR}/ALPINE.json.community" ]]; then
 cat "${TMPDIR}/ALPINE.json.main" "${TMPDIR}/ALPINE.json.community" | jq -s '. | sort_by(.pkg)' > "${TMPDIR}/ALPINE_PKG.json.tmp"
 if jq --exit-status . "${TMPDIR}/ALPINE_PKG.json.tmp" >/dev/null 2>&1; then
  cp -fv "${TMPDIR}/ALPINE_PKG.json.tmp" "${TMPDIR}/ALPINE_PKG.json"
  if [[ "$(jq -r '.[] | .pkg' "${TMPDIR}/ALPINE_PKG.json" | wc -l)" -gt 10000 ]]; then
   cp -fv "${TMPDIR}/ALPINE_PKG.json" "${SYSTMP}/ALPINE_PKG.json"
  else
   echo -e "\n[-] FATAL: Failed to Generate Alpine Metadata\n"
  fi
 fi
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#