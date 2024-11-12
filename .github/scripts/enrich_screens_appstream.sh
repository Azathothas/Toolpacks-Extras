#!/usr/bin/env bash
#
# DO NOT RUN DIRECTLY
#
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/enrich_screens_appstream.sh")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${BINDIR}" ] || \
   [ -z "${BIN}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
fi
#CMD
if ! command -v xq &> /dev/null; then
    echo -e "\n[-] xq is NOT Installed"
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
 enrich_screens_appstream()
 {
 local STDIN_INPUT
 local N=1
 STDIN_INPUT="$(cat)"
 echo "${STDIN_INPUT}" | grep -o 'https://[^"]*\.\(jpeg\|jpg\|png\|svg\|webp\)' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | while read -r URL; do
   FORMAT="${URL##*.}"
   curl -A "${USER_AGENT}" -qfsSL "${URL}" -o "${BIN}.screen_${N}.${FORMAT}"
   ((N++))
   done
   if find "." -maxdepth 1 -type f -name '*screen*' -size +1k | grep -q .; then
     TMP_DIR="$(mktemp -d)"
     find "." -maxdepth 1 -name '*screen_*' -exec du -b "{}" + | \
         sort -nr | \
         awk -v TMP_DIR="${TMP_DIR}" '{
             split($2, a, "screen_");
             if (match($2, /\.([^.]+)$/)) {
                 ext = substr($2, RSTART + 1, RLENGTH - 1);
                 new_name = sprintf("%s/screen_%d.%s", TMP_DIR, NR, ext);
             } else {
                 new_name = sprintf("%s/screen_%d", TMP_DIR, NR);
             }
             system(sprintf("cp \"%s\" \"%s\"", $2, new_name));
         }' 2>/dev/null
     find "${TMP_DIR}" -type f | \
         while read -r TMP_FILE; do
             FILENAME="$(basename "${TMP_FILE}")"
             TARGET_DIR="."
             BASE_NAME="$(find "." -maxdepth 1 -name '*screen_*' -print -quit | sed 's/screen_[0-9]*\..*//')"
             if [ -n "${BASE_NAME}" ]; then
                 TARGET_DIR=$(dirname "${BASE_NAME}")
                 PREFIX=$(basename "${BASE_NAME}")
                 mv -f "${TMP_FILE}" "${TARGET_DIR}/${PREFIX}${FILENAME}"
             fi
         done
     rm -rf "${TMP_DIR}" ; unset BASE_NAME FILENAME N PREFIX STDIN_INPUT TARGET_DIR TMP_DIR TMP_FILE
   fi
   if find "." -maxdepth 1 -type f -name '*screen*' -size +1k | grep -q .; then
     find "." -maxdepth 1 -type f -name '*screen_*' -exec rsync -achLv "{}" "${BINDIR}" \; 2>/dev/null
     if [[ -f "${BINDIR}/${BIN}.scr.png" ]] && [[ $(stat -c%s "${BINDIR}/${BIN}.scr.png") -gt 1024 ]]; then
       echo "https://pkgcache.pkgforge.dev/$(uname -m)/${BIN}.scr.png" | tee "${BINDIR}/${BIN}.screens.txt"
     fi
     find "." -maxdepth 1 -type f -name '*screen_*' -printf '%f\n' | sort -t'_' -k2,2n | sed "s|^|https://pkgcache.pkgforge.dev/$(uname -m)/|" | tee -a "${BINDIR}/${BIN}.screens.txt"
     sed '1s/^[ \t]*//; $s/[ \t]*$//; s/^[ \t]*//; s/[ \t]*$//' -i "${BINDIR}/${BIN}.screens.txt"
     if [[ ! -f "${BINDIR}/${APP}.screens.txt" || $(stat -c%s "${BINDIR}/${APP}.screens.txt") -le 3 ]]; then
       rsync -achLv  "${BINDIR}/${BIN}.screens.txt" "${BINDIR}/${APP}.screens.txt"
     fi
   fi
 }
export -f enrich_screens_appstream
#-------------------------------------------------------#