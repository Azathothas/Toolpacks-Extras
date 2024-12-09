#!/usr/bin/env bash
## <DO NOT RUN STANDALONE, meant for CI Only>
## Meant to Fetch FlatPak data
## Files:
#   "${SYSTMP}/FLATPAK_APPSTREAM.xml"
#   "${SYSTMP}/FLATPAK_APPS_INFO.txt"
#   "${SYSTMP}/FLATPAK_APPS_INFO.json"
#   "${SYSTMP}/FLATPAK_APP_IDS.txt"
#   "${SYSTMP}/FLATPAK_POPULAR.json"
#   "${SYSTMP}/FLATPAK_TRENDING.json"
## Requires: https://github.com/Azathothas/Arsenal/blob/main/misc/Linux/install_dev_tools.sh
# bash <(curl -qfsSL "https://pub.ajam.dev/repos/Azathothas/Arsenal/misc/Linux/install_dev_tools.sh")
## Self: https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_flatpak.sh
# bash <(curl -qfsSL "https://raw.githubusercontent.com/pkgforge/pkgcache/refs/heads/main/scripts/metadata/fetch_flatpak.sh")
#-------------------------------------------------------#


#-------------------------------------------------------#
##ENV
export TZ="UTC"
SYSTMP="$(dirname $(mktemp -u))" && export SYSTMP="${SYSTMP}"
TMPDIR="$(mktemp -d)" && export TMPDIR="${TMPDIR}" ; echo -e "\n[+] Using TEMP: ${TMPDIR}\n"
#Cleanup
rm -rvf "${SYSTMP}/FLATPAK_APPS_INFO.txt" "${SYSTMP}/FLATPAK_APPS_INFO.json" "${SYSTMP}/FLATPAK_APP_IDS.txt" "${SYSTMP}/FLATPAK_POPULAR.json" "${SYSTMP}/FLATPAK_TRENDING.json" 2>/dev/null
#-------------------------------------------------------#


#-------------------------------------------------------#
##Generate Data
#Add Repos
sudo flatpak remote-add --if-not-exists flathub "https://dl.flathub.org/repo/flathub.flatpakrepo"
flatpak --user remote-add --if-not-exists flathub "https://dl.flathub.org/repo/flathub.flatpakrepo" 2>/dev/null
#Install a dummy to populate db
sudo flatpak search "cpu-x"
sudo flatpak install --noninteractive --or-update --assumeyes flathub "io.github.thetumultuousunicornofdarkness.cpu-x"
ls "/var/lib/flatpak/appstream/flathub/x86_64/active/" -lah
if command -v flatpak &> /dev/null; then
   FLATPAK_APPSTREAM="$(sudo find "/var/lib/flatpak" -type f -name "appstream.xml" -print 2>/dev/null | xargs realpath | head -n 1)" && export FLATPAK_APPSTREAM="${FLATPAK_APPSTREAM}"
   if [[ -f "${FLATPAK_APPSTREAM}" ]] && [[ $(stat -c%s "${FLATPAK_APPSTREAM}") -gt 10000 ]]; then
     cp -fv "${FLATPAK_APPSTREAM}" "${SYSTMP}/FLATPAK_APPSTREAM.xml"
     rm -rvf "${TMPDIR}/FLATPAK_APPS.tmp.txt" 2>/dev/null
     clean_xml() {
         local LINE="$1"
         local TAG="$2"
         echo "${LINE}" | sed -n "s|.*<${TAG}>\(.*\)</${TAG}>.*|\1|p"
     }
     declare -A STORED_ID
     readarray -t XML_LINES < "${FLATPAK_APPSTREAM}"
     TOTAL_LINES=${#XML_LINES[@]}
     for ((i = 0; i < TOTAL_LINES; i++)); do
         LINE="${XML_LINES[i]}"
         if [[ $LINE =~ \<id\> ]]; then
             APP_ID=$(clean_xml "${LINE}" "id")
             [[ -n "${STORED_ID[${APP_ID}]}" ]] && continue
             NAME=""
             SUMMARY=""
             for ((j = i + 1; j < i + 10 && j < TOTAL_LINES; j++)); do
                 NEXT_LINE="${XML_LINES[j]}"
                 if [[ -z "${NAME}" && ${NEXT_LINE} =~ \<name\> ]]; then
                     NAME=$(clean_xml "${NEXT_LINE}" "name")
                 elif [[ -z "${SUMMARY}" && ${NEXT_LINE} =~ \<summary\> ]]; then
                     SUMMARY=$(clean_xml "${NEXT_LINE}" "summary")
                 fi
                 [[ -n "${NAME}" && -n "${SUMMARY}" ]] && break
             done
             if [[ -n "${APP_ID}" && -n "${NAME}" && -n "${SUMMARY}" ]]; then
                 STORED_ID["${APP_ID}"]=1
                 printf "NAME: %s\nAPP_ID: %s\nDescr: %s\n-----------------------------\n" \
                     "${NAME}" "${APP_ID}" "${SUMMARY}"
             fi
         fi
     done >> "${TMPDIR}/FLATPAK_APPS.tmp.txt"
   fi
fi
#Sanity Check & Append
if [[ -f "${TMPDIR}/FLATPAK_APPS.tmp.txt" ]] && [[ $(stat -c%s "${TMPDIR}/FLATPAK_APPS.tmp.txt") -gt 1000 ]]; then
   N_NAME="$(grep -o "NAME" "${TMPDIR}/FLATPAK_APPS.tmp.txt" | wc -l)"
   N_APPID="$(grep -o "APP_ID" "${TMPDIR}/FLATPAK_APPS.tmp.txt" | wc -l)"
   N_DESCR="$(grep -o "Descr" "${TMPDIR}/FLATPAK_APPS.tmp.txt" | wc -l)"
   if [ "${N_NAME}" -ge 100 ] && [ "${N_APPID}" -ge 100 ] && [ "${N_DESCR}" -ge 100 ]; then
     cp -fv "${TMPDIR}/FLATPAK_APPS.tmp.txt" "${SYSTMP}/FLATPAK_APPS_INFO.txt"
     #Convert to Json
      awk 'BEGIN {RS="-----------------------------"} NF' "${SYSTMP}/FLATPAK_APPS_INFO.txt" | jq -R -s '
        split("\n\n") | map(
          split("\n") | map(select(. != "")) | 
          reduce .[] as $line (
            {};
            . + (
              if $line | startswith("NAME:") then {"pkg": ($line | split(": ")[1] | ltrimstr(" ") | rtrimstr(" "))}
              elif $line | startswith("APP_ID:") then {"app_id": ($line | split(": ")[1] | ltrimstr(" ") | rtrimstr(" "))}
              elif $line | startswith("Descr:") then {"description": ($line | split(": ")[1] | ltrimstr(" ") | rtrimstr(" "))}
              else .
              end
            )
          )
        ) | map(select(.pkg != null and .app_id != null and .description != null)) | sort_by(.pkg)
      ' | jq . > "${TMPDIR}/FLATPAK_APPS_INFO.json.tmp"
      if jq --exit-status . "${TMPDIR}/FLATPAK_APPS_INFO.json.tmp" >/dev/null 2>&1; then
       cp -fv "${TMPDIR}/FLATPAK_APPS_INFO.json.tmp" "${SYSTMP}/FLATPAK_APPS_INFO.json"
      fi
   fi
fi
#Fetch AppStream IDs
curl -A "${USER_AGENT}" -qfsSL "https://flathub.org/api/v2/appstream" | jq -r '.[]' > "${SYSTMP}/FLATPAK_APP_IDS.txt"
#Fetch Popular Apps
curl -A "${USER_AGENT}" -qfsSL "https://flathub.org/api/v2/popular/last-month?locale=en" | jq '
[.hits[] | {
  pkg: (.name // ""),
  app_id: (.app_id // ""),
  description: (.summary // ""),
  description_long: (
    .description // "" 
    | gsub("\\n[ \t]+"; "<br>")
    | gsub("<br>$"; "")
    | gsub("<br>\\s*<br>"; "<br>")
    | gsub("<br>\\s*<br>+"; "<br>")
    | gsub("\".*?\""; "")
    | gsub("\\s{2,}"; " ")
    | select(
        (. | test("flatpak|flathub|flatseal"; "i")) | not
      )
  ),
  build_date: (.updated_at | if . then (todateiso8601 | sub("Z$"; "")) else "" end),
  category: (.categories // []),
  icon: (.icon // ""),
  license: (.project_license // ""),
  tag: (.keywords // []),
  rank: (.installs_last_month // "")
}] | sort_by(-.rank) | [range(length) as $i | .[$i] | .rank = ($i + 1)]' | jq . > "${TMPDIR}/FLATPAK_POPULAR.json"
if jq --exit-status . "${TMPDIR}/FLATPAK_POPULAR.json" >/dev/null 2>&1; then
 cp -fv "${TMPDIR}/FLATPAK_POPULAR.json" "${SYSTMP}/FLATPAK_POPULAR.json"
fi
#Fetch Trending Apps
curl -A "${USER_AGENT}" -qfsSL "https://flathub.org/api/v2/trending/last-two-weeks?locale=en" | jq '
[.hits[] | {
  pkg: (.name // ""),
  app_id: (.app_id // ""),
  description: (.summary // ""),
  description_long: (
    .description // "" 
    | gsub("\\n[ \t]+"; "<br>")
    | gsub("<br>$"; "")
    | gsub("<br>\\s*<br>"; "<br>")
    | gsub("<br>\\s*<br>+"; "<br>")
    | gsub("\".*?\""; "")
    | gsub("\\s{2,}"; " ")
    | select(
        (. | test("flatpak|flathub|flatseal"; "i")) | not
      )
  ),
  build_date: (.updated_at | if . then (todateiso8601 | sub("Z$"; "")) else "" end),
  category: (.categories // []),
  icon: (.icon // ""),
  license: (.project_license // ""),
  tag: (.keywords // []),
  rank: (.installs_last_month // "")
}] | sort_by(-.rank) | [range(length) as $i | .[$i] | .rank = ($i + 1)]' | jq . > "${TMPDIR}/FLATPAK_TRENDING.json"
if jq --exit-status . "${TMPDIR}/FLATPAK_TRENDING.json" >/dev/null 2>&1; then
 cp -fv "${TMPDIR}/FLATPAK_TRENDING.json" "${SYSTMP}/FLATPAK_TRENDING.json"
fi
#-------------------------------------------------------#