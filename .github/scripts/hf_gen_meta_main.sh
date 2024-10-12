#!/usr/bin/env bash
## <CAN BE RUN STANDALONE>
## <REQUIRES: ${GITHUB_TOKEN} ${HF_TOKEN}>
# source <(curl -qfsSL "https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/main/.github/scripts/hf_gen_meta_main.sh")
# source <(curl -qfsSL "https://l.ajam.dev/hf-gen-meta-main")
##
#-------------------------------------------------------#
##ENV
hf_gen_meta_main()
{
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
if [ -z "${HOST_TRIPLET+x}" ] || [ -z "${HOST_TRIPLET}" ]; then
 HOST_TRIPLET="$(uname -m)-$(uname -s)" && export HOST_TRIPLET="${HOST_TRIPLET}"
fi
BUILDYAML="$(mktemp --tmpdir=${TMPDIR} XXXXX.yaml)" && export BUILDYAML="${BUILDYAML}"
HF_REPO="https://huggingface.co/datasets/Azathothas/Toolpacks-Extras/resolve/main" && export HF_REPO="${HF_REPO}"
HF_REPO_DL="${HF_REPO}/${HOST_TRIPLET}" && export HF_REPO_DL="${HF_REPO_DL}"
#GH_REPO="https://pub.ajam.dev/repos/Azathothas/Toolpacks-Extras" && export GH_REPO="${GH_REPO}"
GH_REPO="https://raw.githubusercontent.com/Azathothas/Toolpacks-Extras/refs/heads/main" && export GH_REPO="${GH_REPO}"
#Get URlS
curl -qfsSL "https://api.github.com/repos/Azathothas/Toolpacks-Extras/contents/.github/scripts/${HOST_TRIPLET}/pkgs" \
-H "Authorization: Bearer ${GITHUB_TOKEN}" | jq -r '.[] | select(.download_url | endswith(".yaml")) | .download_url' |\
grep -i '\.yaml$' | sort -u -o "${TMPDIR}/BUILDURLS"
#Get METADATA.json
curl -qfsSL "${HF_REPO_DL}/METADATA.json.tmp" -o "${TMPDIR}/METADATA.json" || curl -qfsSL "${HF_REPO_DL}/METADATA.json" -o "${TMPDIR}/METADATA.json"
#Get BLAKE3SUM.json
curl -qfsSL "${HF_REPO_DL}/BLAKE3SUM.json" -o "${TMPDIR}/BLAKE3SUM.json"
#Get SHA256SUM.json
curl -qfsSL "${HF_REPO_DL}/SHA256SUM.json" -o "${TMPDIR}/SHA256SUM.json"
##Sanity
if [[ -n "${GITHUB_TOKEN}" ]]; then
   echo -e "\n[+] GITHUB_TOKEN is Exported"
else
   # 60 req/hr
   echo -e "\n[-] GITHUB_TOKEN is NOT Exported"
   echo -e "Export it to avoid ratelimits\n"
   exit 1
fi
if ! command -v git-lfs &> /dev/null; then
   echo -e "\n[-] git-lfs is NOT Installed\n"
   exit 1
fi
if [[ -n "${HF_TOKEN}" ]]; then
   echo -e "\n[+] HF_TOKEN is Exported"
else
   echo -e "\n[-] HF_TOKEN is NOT Exported"
   echo -e "Export it to use huggingface-cli\n"
   exit 1
fi
if ! command -v huggingface-cli &> /dev/null; then
   echo -e "\n[-] huggingface-cli is NOT Installed\n"
   exit 1
fi
if [ ! -s "${TMPDIR}/BUILDURLS" ] || [ ! -s "${TMPDIR}/METADATA.json" ] || [ ! -s "${TMPDIR}/BLAKE3SUM.json" ] || [ ! -s "${TMPDIR}/SHA256SUM.json" ]; then
     echo -e "\n[-] Required Files Aren't Available\n"
   exit 1
fi
##Run
echo -e "\n\n [+] Started Metadata Update at :: $(TZ='UTC' date +'%A, %Y-%m-%d (%I:%M:%S %p)')\n\n"
 for BUILD_URL in $(cat "${TMPDIR}/BUILDURLS" | sed 's/"//g'); do
   echo -e "\n[+] Fetching : ${BUILD_URL}"
    if curl -qfsSL "${BUILD_URL}" -o "${BUILDYAML}" &> /dev/null; then
       dos2unix --quiet "${BUILDYAML}"
      #Sanity Check 
      if [ "$(yq e '.path' "${BUILDYAML}")" = "/" ]; then
         #export Name
          NAME="$(yq -r '.name' ${BUILDYAML})" && export NAME="${NAME}"
         #export Notes (Note)
          NOTE="$(yq -r '.note' ${BUILDYAML})" && export NOTE="$NOTE"
         #export REPO_URL 
          REPO_URL="$(yq -r '.src_url' ${BUILDYAML})" && export REPO_URL="$REPO_URL" 
         #export WEB_URL (WebURL)
          WEB_URL="$(yq -r '.web_url' ${BUILDYAML})" && export WEB_URL="$WEB_URL"
         #export Build Script
          #BUILD_SCRIPT="$(echo "${BUILD_URL}" | sed 's|\.yaml$|.sh|')" && export BUILD_SCRIPT="${BUILD_SCRIPT}"
          BUILD_SCRIPT="https://github.com/Azathothas/Toolpacks-Extras/blob/main/.github/scripts/${HOST_TRIPLET}/pkgs/${NAME}.sh" && export BUILD_SCRIPT="${BUILD_SCRIPT}"
         #export BIN= 
          yq -r '.bins[]' "${BUILDYAML}" | sort -u -o "${TMPDIR}/BINS.txt"
         #Merge with json
          for BIN in $(cat "${TMPDIR}/BINS.txt" | sed 's/"//g'); do
           #Bin Name
             BIN_NAME="$(yq -r '.bin_name' ${BUILDYAML})" && export BIN_NAME="${BIN_NAME}"
             jq --arg BIN "$BIN" --arg BIN_NAME "${BIN_NAME}" '.[] |= if .name == $BIN then . + {bin_name: $BIN_NAME} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
           #BSUM
             B3SUM="$(jq --arg BIN "$BIN" -r '.[] | select(.filename | endswith($BIN)) | .sum' "${TMPDIR}/BLAKE3SUM.json" | tr -d '[:space:]')" && export B3SUM="${B3SUM}"
             jq --arg BIN "$BIN" --arg BSUM "$B3SUM" '.[] |= if .name == $BIN then . + {bsum: $BSUM} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Build_Log 
             BUILD_LOG="${HF_REPO_DL}/${NAME}.log" && export BUILD_LOG="${BUILD_LOG}"
             jq --arg BIN "$BIN" --arg BUILD_LOG "${BUILD_LOG}" '.[] |= if .name == $BIN then . + {build_log: $BUILD_LOG} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Build_Script
             jq --arg BIN "$BIN" --arg BUILD_SCRIPT "${BUILD_SCRIPT}" '.[] |= if .name == $BIN then . + {build_script: $BUILD_SCRIPT} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Category
             CATEGORY="$(yq -r '.category[]' "${BUILDYAML}" | paste -sd ',' - | tr -d '[:space:]')" && export CATEGORY="${CATEGORY}"
             jq --arg BIN "$BIN" --arg CATEGORY "${CATEGORY}" '.[] |= if .name == $BIN then . + {category: $CATEGORY} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"             
            #Description
             DESCRIPTION="$(yq -r '.description' ${BUILDYAML})" && export DESCRIPTION="${DESCRIPTION}"
             jq --arg BIN "$BIN" --arg DESCRIPTION "${DESCRIPTION}" '.[] |= if .name == $BIN then . + {description: $DESCRIPTION} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Extras (All Bins)
             EXTRA_BINS="$(cat ${TMPDIR}/BINS.txt | sed "/^$BIN$/d" | paste -sd ',' -)" && export EXTRA_BINS="${EXTRA_BINS}"  
             jq --arg BIN "$BIN" --arg EXTRA_BINS "$EXTRA_BINS" '.[] |= if .name == $BIN then . + {extra_bins: $EXTRA_BINS} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Note
             jq --arg BIN "$BIN" --arg NOTE "$NOTE" '.[] |= if .name == $BIN then . + {note: $NOTE} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Src URL
             jq --arg BIN "$BIN" --arg REPO_URL "$REPO_URL" '.[] |= if .name == $BIN then . + {src_url: $REPO_URL} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json" 
            #SHASUM
             SHA256="$(jq --arg BIN "$BIN" -r '.[] | select(.filename | endswith($BIN)) | .sum' "${TMPDIR}/SHA256SUM.json" | tr -d '[:space:]')" && export SHA256="${SHA256}"
             jq --arg BIN "$BIN" --arg SHASUM "$SHA256" '.[] |= if .name == $BIN then . + {shasum: $SHASUM} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Version
             VERSION="$(curl -qfsSL "${HF_REPO_DL}/${BIN}.version" | tr -d '[:space:]')" && export VERSION="${VERSION}"
             if [ -z "${VERSION}" ]; then
                export VERSION="latest"
             fi
             jq --arg BIN "$BIN" --arg VERSION "${VERSION}" '.[] |= if .name == $BIN then . + {version: $VERSION} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Web URLs
             jq --arg BIN "$BIN" --arg WEB_URL "$WEB_URL" '.[] |= if .name == $BIN then . + {web_url: $WEB_URL} else . end' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Sort & Map
              jq 'map({
                     name: (.name // "" | if . == null or . == "" then "" else . end),
                     bin_name: (.bin_name // "" | if . == null or . == "" then "" else . end),
                     description: (.description // "" | if . == null or . == "" then "" else . end),
                     note: (.note // "" | if . == null or . == "" then "" else . end),
                     version: (.version // "" | if . == null or . == "" then "" else . end),
                     download_url: (.download_url // "" | if . == null or . == "" then "" else . end),
                     size: (.size // "" | if . == null or . == "" then "" else . end),
                     bsum: (.bsum // "" | if . == null or . == "" then "" else . end),
                     shasum: (.shasum // "" | if . == null or . == "" then "" else . end),
                     build_date: (.build_date // "" | if . == null or . == "" then "" else . end),
                     src_url: (.src_url // "" | if . == null or . == "" then "" else . end),
                     web_url: (.web_url // "" | if . == null or . == "" then "" else . end),
                     build_script: (.build_script // "" | if . == null or . == "" then "" else . end),
                     build_log: (.build_log // "" | if . == null or . == "" then "" else . end),
                     category: (.category // "" | if . == null or . == "" then "" else . end),
                     extra_bins: (.extra_bins // "" | if . == null or . == "" then "" else . end)
                 })' "${TMPDIR}/METADATA.json" > "${TMPDIR}/METADATA.tmp" && mv "${TMPDIR}/METADATA.tmp" "${TMPDIR}/METADATA.json"
            #Print json
            echo -e "\n[+] BIN: $BIN"
            jq --arg BIN "$BIN" '.[] | select(.name == $BIN)' "${TMPDIR}/METADATA.json" 2>/dev/null | tee "${TMPDIR}/METADATA.json.bak.tmp"
            #Append
            if jq --exit-status . "${TMPDIR}/METADATA.json.bak.tmp" >/dev/null 2>&1; then
               cat "${TMPDIR}/METADATA.json.bak.tmp" >> "${TMPDIR}/METADATA.json.bak"
            fi
          done
      fi
    fi
 done
#Configure git
 git config --global "credential.helper" store
 git config --global "user.email" "AjamX101@gmail.com"
 git config --global "user.name" "Azathothas"
#Login
 huggingface-cli login --token "${HF_TOKEN}" --add-to-git-credential
#Clone
 pushd "$(mktemp -d)" >/dev/null 2>&1 && git clone --depth="1" --filter="blob:none" --no-checkout "https://huggingface.co/datasets/Azathothas/Toolpacks-Extras" && cd "./Toolpacks-Extras"
  git sparse-checkout set "." && git checkout
  HF_REPO_LOCAL="$(realpath .)" && export HF_REPO_LOCAL="${HF_REPO_LOCAL}"
  git lfs install
  huggingface-cli lfs-enable-largefiles "."
 popd >/dev/null 2>&1
#Update HF
echo -e "\n[+] Updating Metadata.json ($(realpath ${TMPDIR}/METADATA.json))\n"
if jq --exit-status . "${TMPDIR}/METADATA.json.bak" >/dev/null 2>&1; then
   cat "${TMPDIR}/METADATA.json.bak" | jq -s '.' | jq 'walk(if type == "string" and . == "null" then "" else . end)' > "${TMPDIR}/METADATA.json"
   #Sync
     pushd "${HF_REPO_LOCAL}" >/dev/null 2>&1
       git fetch origin main ; git sparse-checkout add "./${HOST_TRIPLET}"
       find "${HF_REPO_LOCAL}" -type f -size -3c -delete
       rm "./${HOST_TRIPLET}/METADATA.json.tmp"
       cp "${TMPDIR}/METADATA.json" "./${HOST_TRIPLET}/METADATA.json"
       #jq -r tostring "${TMPDIR}/METADATA.json" > "./${HOST_TRIPLET}/METADATA.min.json"
       sed "s|https://huggingface.co/datasets/Azathothas/Toolpacks-Extras/resolve/main/$(uname -m)-$(uname -s)|https://pkg.ajam.dev/$(uname -m)|g" \
       "./${HOST_TRIPLET}/METADATA.json" | jq -r tostring > "./${HOST_TRIPLET}/METADATA.min.json"
      #Commit & Push
       git add --all --verbose && git commit -m "[+] METADATA (${HOST_TRIPLET}) [$(TZ='UTC' date +'%Y_%m_%d')]"
       git branch -a || git show-branch
       git fetch origin main ; git push origin main
     popd >/dev/null 2>&1
else
   echo -e "\n[-] FATAL: ($(realpath ${TMPDIR}/METADATA.json.bak)) is Inavlid\n"
 exit 1
fi
}
export -f hf_gen_meta_main
#-------------------------------------------------------#