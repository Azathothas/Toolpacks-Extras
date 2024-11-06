#!/usr/bin/env bash
#
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/util_fetch_repology_meta.sh")
# source <(curl -qfsSL "https://l.ajam.dev/util-fetch-repology-meta")
#set -x
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
util_fetch_repology_meta()
{
  #ENV  
   local INPUT="${1:-$(cat)}"
   local REPOLOGY_PKG="$(echo "${INPUT}" | tr -cd '[:alnum:]_-')"
   SYSTMP="$(dirname $(mktemp -u))"
   TMP_JSON="${SYSTMP}/repology.tmp.json"
   if [[ -z "${USER_AGENT}" ]]; then
     USER_AGENT="$(curl -qfsSL 'https://pub.ajam.dev/repos/Azathothas/Wordlists/Misc/User-Agents/ua_chrome_macos_latest.txt')"
   fi
  #Fetch
   rm -rf "${TMP_JSON}" 2>/dev/null
   echo -e "\n[+] Package: ${REPOLOGY_PKG} (${TMP_JSON})"
   curl -A "${USER_AGENT}" -qfsSL "https://repology.org/api/v1/project/${REPOLOGY_PKG}" -o "${TMP_JSON}"
   if [[ -f "${TMP_JSON}" ]] && [[ $(stat -c%s "${TMP_JSON}") -gt 1024 ]]; then
    echo -e "\n[+] https://repology.org/project/${REPOLOGY_PKG}/information\n"
     #Description
      jq -r '.[] | select(.summary != null and .summary != "") | .summary' "${TMP_JSON}" | sed -e 's/["'\''`|]//g' -e 's/^[ \t]*//;s/[ \t]*$//' | sort -u | grep -viE 'l10n|ICU data|language pack' | awk '{print "description: \"" $0 "\""}' ; echo
     #distro_pkg
      jq -r '.[] | "[\(.repo)/\(.subrepo // "")] --> \(.srcname)"' "${TMP_JSON}" | sed -e 's/["'\''`|]//g' -e 's/^[ \t]*//;s/[ \t]*$//' | sort -u | grep -iE 'alpine_edge|arch|aur|debian_12|debian_13|debian_unstable|nix_unstable' ; echo
     #license
      jq -r '.[] | select(.licenses != null and .licenses != "") | .licenses[]' "${TMP_JSON}" | sed -e 's/["'\''`|]//g' -e 's/^[ \t]*//;s/[ \t]*$//' -e 's/(.*)//g' | sort -u | awk '{print "  - \"" $0 "\""}' | awk 'BEGIN {print "license:"} {print}' ; echo
     #tag
      jq -r '.[] | select(.categories != null) | .categories[]' "${TMP_JSON}" | sed -e 's/["'\''`|]//g' -e 's/^[ \t]*//;s/[ \t]*$//' | sort -u | grep -viE 'app:gui|misc|unspecified' | awk 'BEGIN {print "tag:"} {print "  - \"" $1 "\""}' ; echo
   fi
  }
export -f util_fetch_repology_meta
#-------------------------------------------------------#