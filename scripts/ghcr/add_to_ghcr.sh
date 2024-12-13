#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Sync All our Prebuilts to ghcr
## The metadata for the pkg to-be-added must already exist in the AIO files
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/ghcr/add_to_ghcr.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/ghcr/add_to_ghcr.sh")
#-------------------------------------------------------#

#-------------------------------------------------------#
##ENV
TZ="UTC"
export ARCH REPO TZ
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#-------------------------------------------------------#

#-------------------------------------------------------#
##Fetch Metadata
pushd "${TMPDIR}" >/dev/null 2>&1
curl -qfsSL "https://bin.pkgforge.dev/aarch64/METADATA.AIO.json" -o "${TMPDIR}/aarch64.json"
curl -qfsSL "https://bin.pkgforge.dev/x86_64/METADATA.AIO.json" -o "${TMPDIR}/x86_64.json"
jq -r '.. | objects | .download_url? // empty' "${TMPDIR}/aarch64.json" > "${TMPDIR}/URLs.txt"
jq -r '.. | objects | .download_url? // empty' "${TMPDIR}/x86_64.json" >> "${TMPDIR}/URLs.txt"
sort -u "${TMPDIR}/URLs.txt" -o "${TMPDIR}/URLs.txt"
readarray -t URLS < "${TMPDIR}/URLs.txt"
##Upload Func
upload_to_ghcr()
{
 local URL="$1"
 #Clear ENV
  unset ARCH BUILD_LOG BUILD_SCRIPT DOWNLOAD_URL GHCR_PKG PKG_FAMILY PKG_NAME PKG_VERSION REPO VERSION TMPJSON
  TMPJSON="$(basename $(mktemp -u)).json"
 #Fetch 
  if echo "${URL}" | grep -q -m 1 'pkgforge.dev/aarch64/'; then
   jq --arg URL "$URL" 'recurse | objects | select(.download_url == $URL)' "${TMPDIR}/aarch64.json" > "${TMPDIR}/${TMPJSON}"
  elif echo "${URL}" | grep -q -m 1 'pkgforge.dev/x86_64/'; then
   jq --arg URL "$URL" 'recurse | objects | select(.download_url == $URL)' "${TMPDIR}/x86_64.json" > "${TMPDIR}/${TMPJSON}"
  fi
 #Parse
  if jq --exit-status . "${TMPDIR}/${TMPJSON}" >/dev/null 2>&1; then
   DOWNLOAD_URL="$(jq -r '.download_url' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
  #Download
   if [[ -n "${DOWNLOAD_URL}" ]]; then
     if echo "${DOWNLOAD_URL}" | grep -q -m 1 'aarch64'; then
       ARCH="aarch64"
     elif echo "${DOWNLOAD_URL}" | grep -q -m 1 'x86_64'; then
       ARCH="x86_64"
     fi
     if echo "${DOWNLOAD_URL}" | grep -q -m 1 'bin.pkgforge.dev'; then
       REPO="bincache"
     elif echo "${DOWNLOAD_URL}" | grep -q -m 1 'pkgcache.pkgforge.dev'; then
       REPO="pkgcache"
     fi
     PKG_DESCRIPTION="$(jq -r '.description' "${TMPDIR}/${TMPJSON}")"
     PKG_FAMILY="$(jq -r '.pkg_family' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_NAME="$(jq -r '.pkg_name' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     PKG_VERSION="$(jq -r '.version' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     BUILD_SCRIPT="$(jq -r '.build_script' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     BUILD_LOG="$(jq -r '.build_log' "${TMPDIR}/${TMPJSON}" | tr -d '[:space:]')"
     GHCR_PKG="$(realpath .)/${PKG_NAME}"
     curl -qfsSL "${DOWNLOAD_URL}" -o "${GHCR_PKG}"
   else
     echo -e "\n[-] No \$DOWNLOAD_URL was parsed"
     return
   fi
  #Upload
   if [[ -s "${GHCR_PKG}" && $(stat -c%s "${GHCR_PKG}") -gt 100 ]]; then
     GHCR_PKGVER="${VERSION:-$(date --utc +"%y%m%dT%H%M%S")}"
     echo -e "\n[+] Parsing/Uploading ${PKG_FAMILY}/${PKG_NAME} --> https://github.com/orgs/pkgforge/packages/container/package/${REPO}%2F${PKG_FAMILY:-PKG_NAME}%2F${PKG_NAME} [${ARCH}]"
     oras push --concurrency "100" --disable-path-validation \
     --config "/dev/null:application/vnd.oci.empty.v1+json" \
     --annotation "org.opencontainers.image.description=${PKG_DESCRIPTION}" \
     --annotation "org.opencontainers.image.documentation=${BUILD_SCRIPT}" \
     --annotation "org.opencontainers.image.licenses=blessing" \
     --annotation "org.opencontainers.image.ref.name=${GHCR_PKGVER}" \
     --annotation "org.opencontainers.image.source=https://github.com/pkgforge/${REPO}" \
     --annotation "org.opencontainers.image.title=${PKG_NAME}" \
     --annotation "org.opencontainers.image.url=${DOWNLOAD_URL}" \
     --annotation "org.opencontainers.image.vendor=pkgforge" \
     --annotation "org.opencontainers.image.version=${GHCR_PKGVER}" \
     "ghcr.io/pkgforge/${REPO}/${PKG_FAMILY:-PKG_NAME}/${PKG_NAME}:${GHCR_PKGVER},${ARCH}" "${GHCR_PKG}"
     rm -rvf "${GHCR_PKG}" "${TMPDIR}/${TMPJSON}" 2>/dev/null
   else
     echo -e "\n[-] FAILED to Download ${PKG_FAMILY}/${PKG_NAME} <-- ${DOWNLOAD_URL} [${ARCH}]\n"
     cat "${TMPDIR}/${TMPJSON}"
     return
   fi
  fi
}
export -f upload_to_ghcr
popd >/dev/null 2>&1
#-------------------------------------------------------#

#-------------------------------------------------------#
##Upload
pushd "${TMPDIR}" >/dev/null 2>&1
if [[ -n "${PARALLEL_LIMIT}" ]]; then
 printf '%s\n' "${URLS[@]}" | xargs -P "${PARALLEL_LIMIT}" -I "{}" bash -c 'upload_to_ghcr "$@" 2>/dev/null' _ "{}"
else 
 printf '%s\n' "${URLS[@]}" | xargs -P "$(($(nproc)+1))" -I "{}" bash -c 'upload_to_ghcr "$@" 2>/dev/null' _ "{}"
fi
popd >/dev/null 2>&1
#-------------------------------------------------------#