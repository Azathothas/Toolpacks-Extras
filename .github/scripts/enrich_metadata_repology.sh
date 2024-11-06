#!/usr/bin/env bash
#
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_metadata_repology.sh")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${REPOLOGY_PKG}" ] || \
   [ -z "${BINDIR}" ] || \
   [ -z "${BIN}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ] || \
   [ -z "${USER_AGENT}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
fi
#Size
BINDIR_SIZE="$(du -sh "${BINDIR}" 2>/dev/null | awk '{print $1}' 2>/dev/null)" && export "BINDIR_SIZE=${BINDIR_SIZE}"
if [ ! -d "${BINDIR}" ] || [ -z "$(ls -A "${BINDIR}")" ] || [ -z "${BINDIR_SIZE}" ] || [[ "${BINDIR_SIZE}" == *K* ]]; then
     echo -e "\n[+] Broken/Empty Built "${BINDIR}" Found\n"
     exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Main
 #Fetch
   pushd "$($TMPDIRS)" >/dev/null 2>&1 ; set +x
   for i in {1..3}; do
     RESP=$(curl -A "${USER_AGENT}" -w "\n%{http_code}" -qfsSL "https://repology.org/api/v1/project/${REPOLOGY_PKG}")
     CODE=$(tail -n1 <<< "$RESP")
     [ "${CODE}" = "404" ] && exit 1
     JSON=$(head -n -1 <<< "$RESP")
     [ "${JSON}" = "[]" ] && exit 1
     [ ${#JSON} -lt 1024 ] && exit 1
     echo "${JSON}" | jq . > "./repology.json"
     [[ -f "./repology.json" ]] && [[ $(stat -c%s "./repology.json") -gt 1024 ]] && break
     [[ $i -lt 3 ]] && sleep 2
   done ; set -x
   if [[ -f "./repology.json" ]] && [[ $(stat -c%s "./repology.json") -gt 1024 ]]; then
    #Copy
     rsync -achLv "./repology.json" "${BINDIR}/${APP}.repology.json" 2>/dev/null
     rsync -achLv "./repology.json" "${BINDIR}/${BIN}.repology.json" 2>/dev/null
     rsync -achLv "./repology.json" "${BINDIR}/${PKG_NAME}.repology.json" 2>/dev/null
    #Cleanup
     unset CODE JSON RESP REPOLOGY_PKG
   fi
   rm -rf "$(realpath .)" && popd >/dev/null 2>&1 ; set +x
#-------------------------------------------------------#