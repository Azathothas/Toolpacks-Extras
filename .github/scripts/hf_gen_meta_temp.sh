#!/usr/bin/env bash
## DO NOT RUN STANDALONE (DIRECTLY)
## <RUN AFTER: hf_gen_meta_src>
## <RUN BEFORE: hf_gen_meta_main>
#
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_gen_meta_temp.sh")
# source <(curl -qfsSL "https://l.ajam.dev/hf-gen-meta-temp")
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
  echo -e "\n[+]Require ENV:VARS are NOT Set...\n"
  exit 1
fi
#-------------------------------------------------------#

#-------------------------------------------------------#
##Generate Metadata (TEMP)
hf_gen_meta_temp()
{
pushd "${HF_REPO_PKGDIR}" >/dev/null && curl -qfsSL "https://pub.ajam.dev/utils/devscripts/jq/to_human_bytes.jq" -o "./sizer.jq"
#Generate Template
 rclone lsjson --fast-list "." | jq -r \
   --arg HOST_TRIPLET "${HOST_TRIPLET}" \
   'include "./sizer"; 
    .[] | select(.Size != 0 and .Size != -1 and (.Name | test("\\.(jq|json|md|tmp|txt)$") | not)) | 
    {
      name: (.Name),
      bin_name,
      description,
      note,
      version,
      download_url: "https://huggingface.co/datasets/Azathothas/Toolpacks-Extras/resolve/main/\($HOST_TRIPLET)/\(.Path)", 
      size: (.Size | tonumber | bytes), 
      bsum,
      shasum, 
      build_date: (.ModTime | split(".")[0]),
      src_url, 
      web_url,
      build_script,
      build_log,
      category,
      extra_bins
    }' | jq -s 'sort_by(.name)' | jq '.[]' > "${SYSTMP}/${HOST_TRIPLET}-metadata.json.tmp"
 echo "[" $(cat "${SYSTMP}/${HOST_TRIPLET}-metadata.json.tmp" | tr '\n' ' ' | sed 's/}/},/g' | sed '$ s/,$//') "]" | sed '$s/,[[:space:]]*\]/\]/' | jq . | tee "${HF_REPO_PKGDIR}/METADATA.json.tmp"
 rm "./sizer.jq"
popd >/dev/null 2>&1
}
export -f hf_gen_meta_temp
#-------------------------------------------------------#