#!/usr/bin/env bash
## DO NOT RUN STANDALONE (DIRECTLY)
## <RUN AFTER: Building something>
## <RUN BEFORE: hf_gen_meta_temp>
#
# source <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/main/.github/scripts/hf_gen_meta_src.sh")
# source <(curl -qfsSL "https://l.ajam.dev/hf-gen-meta-src")
##
#set -x
#-------------------------------------------------------#
##Sanity Checks
#ENV:VARS
if [ -z "${HF_REPO_PKGDIR}" ] || \
   [ -z "${HOST_TRIPLET}" ] || \
   [ -z "${SYSTMP}" ] || \
   [ -z "${TMPDIRS}" ]; then
 #exit
  echo -e "\n[+]Required ENV:VARS are NOT Set...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
hf_gen_meta_src()
{
##Generate Metadata
#Chmod +xwr
 find "${HF_REPO_PKGDIR}" -maxdepth 1 -type f -exec chmod +xwr {} \; 2>/dev/null
 #File 
 cd "${HF_REPO_PKGDIR}" && find "./" -maxdepth 1 -type f |\
    grep -v -E '\.desktop$|\.DirIcon$|\.jq$|\.json$|\.jpeg$|\.jpg$|\.png$|\.svg$|\.txt$|\.upx$|\.version$|\.webp$|\.xml$|\.zsync$' |\
    sort | xargs file | jc --monochrome --pretty --file | jq . > "${SYSTMP}/${HOST_TRIPLET}_FILE"
    if [[ -f "${HF_REPO_PKGDIR}/FILE.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/FILE.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.type=$a_dict[.filename].type else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_FILE" "${HF_REPO_PKGDIR}/FILE.json" | jq . > "${SYSTMP}/${HOST_TRIPLET}_FILE.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_FILE.json" | jq . > "${HF_REPO_PKGDIR}/FILE.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_FILE" | jq . > "${HF_REPO_PKGDIR}/FILE.json"
    fi
#Size (stat)
 cd "${HF_REPO_PKGDIR}" && curl -qfsSL "https://pub.ajam.dev/utils/devscripts/jq/to_human_bytes.jq" -o "./sizer.jq"
    find "." -maxdepth 1 -exec stat {} \; | jc --monochrome --pretty --stat | jq \
    'include "./sizer"; .[] | select(.size != 0 and .size != -1 and (.file | test("\\.(jq|json|md|tmp|txt)$") | not))
    | {filename: (.file), size: (.size | tonumber | bytes)}' | jq -s 'sort_by(.filename)' | jq . > "${SYSTMP}/${HOST_TRIPLET}_SIZE"
    if [[ -f "${HF_REPO_PKGDIR}/SIZE.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/SIZE.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.size=$a_dict[.filename].size else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_SIZE" "${HF_REPO_PKGDIR}/SIZE.json" | jq . > "${SYSTMP}/${HOST_TRIPLET}_SIZE.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_SIZE.json" | jq . > "${HF_REPO_PKGDIR}/SIZE.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_SIZE" | jq . > "${HF_REPO_PKGDIR}/SIZE.json"
    fi
    rm "./sizer.jq"
#BLAKE3SUM
 cd "${HF_REPO_PKGDIR}" && find "./" -maxdepth 1 -type f |\
    grep -v -E '\.desktop$|\.DirIcon$|\.jq$|\.json$|\.jpeg$|\.jpg$|\.png$|\.svg$|\.txt$|\.upx$|\.version$|\.webp$|\.xml$|\.zsync$' | sort | xargs b3sum |\
    jq -R -s 'split("\n") | map(select(length > 0) | split(" +"; "g") | {filename: .[1], sum: .[0]}) | sort_by(.filename)' |\
    jq . > "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM"
    if [[ -f "${HF_REPO_PKGDIR}/BLAKE3SUM.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/BLAKE3SUM.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.sum=$a_dict[.filename].sum else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM" "${HF_REPO_PKGDIR}/BLAKE3SUM.json" | jq . > "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM.json" | jq . > "${HF_REPO_PKGDIR}/BLAKE3SUM.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_BLAKE3SUM" | jq . > "${HF_REPO_PKGDIR}/BLAKE3SUM.json"
    fi
#SHA256SUM
 cd "${HF_REPO_PKGDIR}" && find "./" -maxdepth 1 -type f |\
    grep -v -E '\.desktop$|\.DirIcon$|\.jq$|\.json$|\.jpeg$|\.jpg$|\.png$|\.svg$|\.txt$|\.upx$|\.version$|\.webp$|\.xml$|\.zsync$' | sort | xargs sha256sum |\
    jq -R -s 'split("\n") | map(select(length > 0) | split(" +"; "g") |{filename: .[1],sum: .[0]}) | sort_by(.filename)' |\
    jq . > "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM"
    if [[ -f "${HF_REPO_PKGDIR}/SHA256SUM.json" ]] && [[ $(stat -c%s "${HF_REPO_PKGDIR}/SHA256SUM.json") -gt 100 ]]; then
       jq -s '.[0]as$a|.[1]|($a|map({key:.filename,value:.})|
              from_entries)as$a_dict|(map(.filename)|sort)as$b_filenames|
              map(if$a_dict[.filename]then.sum=$a_dict[.filename].sum else. end)+($a|
              map(select(.filename as$f|$b_filenames|index($f)|not)))' \
           "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM" "${HF_REPO_PKGDIR}/SHA256SUM.json" > "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM.json"
       cat "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM.json" | jq . > "${HF_REPO_PKGDIR}/SHA256SUM.json"
    else
       cat "${SYSTMP}/${HOST_TRIPLET}_SHA256SUM" | jq . > "${HF_REPO_PKGDIR}/SHA256SUM.json"
    fi
#Logs
pushd "$(mktemp -d)" >/dev/null
 find "${HF_REPO_PKGDIR}" -type f -regex ".*\.log$" -exec sh -c 'echo -e "\n\n" >> merged_logs.log && cat "$1" >> merged_logs.log' sh {} \;
 if command -v trufflehog &> /dev/null; then
   trufflehog filesystem "./merged_logs.log" --no-fail --no-verification --no-update --json 2>/dev/null | jq -r '.Raw' | sed '/{/d' | xargs -I "{}" sh -c 'echo "{}" | tr -d " \t\r\f\v"' | xargs -I "{}" sed "s/{}/ /g" -i "./merged_logs.log"
 fi
 sed -e '/.*github_pat.*/Id' -e '/.*glpat.*/Id' -e '/.*ghp_.*/Id' -e '/.*hf_.*/Id' -e '/.*token.*/Id' -e '/.*access_key_id.*/Id' -e '/.*secret_access_key.*/Id' -e '/.*cloudflarestorage.*/Id' -i "./merged_logs.log"
 grep -viE 'github_pat|ghp_|glpat|hf_|token|access_key_id|secret_access_key|cloudflarestorage' "./merged_logs.log" > "./merged_logs.log.txt"
 rsync -av --checksum --copy-links --human-readable --remove-source-files --exclude="*/" "./merged_logs.log.txt" "${HF_REPO_PKGDIR}/BUILD.log.txt"
popd >/dev/null 2>&1
}
export -f hf_gen_meta_src
#-------------------------------------------------------#