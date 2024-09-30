#!/bin/sh

# AM INSTALL SCRIPT VERSION 3.5
set -u
APP="86box"
SRC="https://pkg.ajam.dev/$(uname -m)"
TYPE="AppImage"
SITE="${SRC}/${APP}.${TYPE}"

# CREATE DIRECTORIES AND ADD REMOVER
[ -n "${APP}" ] && mkdir -p "/opt/${APP}" "/opt/${APP}/icons" && cd "/opt/${APP}" || exit 1
printf "#!/bin/sh\nset -e\nrm -f /usr/local/bin/${APP}\nrm -R -f /opt/${APP}" > "./remove"
printf '\n%s' "rm -f /usr/local/share/applications/${APP}-AM.desktop" >> "./remove"
chmod a+x "./remove" || exit 1

# DOWNLOAD AND PREPARE THE APP, $version is also used for updates
VERSION="$(curl -qfsSL "${SITE}.version")"
wget "${SITE}" -O "./${APP}" || exit 1
wget "${SITE}.zsync" 2> /dev/null
echo "${VERSION}" > "./version"
chmod a+x "./${APP}" || exit 1

# LINK TO PATH
ln -s "/opt/${APP}/${APP}" "/usr/local/bin/${APP}"

# SCRIPT TO UPDATE THE PROGRAM
cat >> "./AM-updater" << 'EOF'
#!/bin/sh
set -u
APP=86box
SITE="https://pkg.ajam.dev/$(uname -m)"
VERSION0=$(cat "/opt/${APP}/version")
VERSION="$(curl -qfsSL "${SRC}/${APP}.version")"
[ -n "$VERSION" ] || { echo "Error getting link"; exit 1; }
if [ "$VERSION" != "$VERSION0" ] || [ -e "/opt/${APP}/${APP}.zsync" ]; then
	mkdir "/opt/${APP}/tmp" && cd "/opt/${APP}/tmp" || exit 1
	[ -e "/opt/${APP}/${APP}.zsync" ] || notify-send "A new version of ${APP} is available, please wait"
	[ -e "/opt/${APP}/${APP}.zsync"] && wget "${SRC}/${APP}.${TYPE}.zsync" 2>/dev/null || { wget "${SRC}/${APP}.${TYPE}" || exit 1; }
	cd ..
	mv "/opt/${APP}/${APP}.zsync" "/opt/${APP}/${APP}.zsync" 2>/dev/null || mv --backup=t "./tmp/${APP}.${TYPE}" "./${APP}.${TYPE}"
	[ -e "./${APP}.zsync" ] && { zsync "./${APP}.zsync" || notify-send -u critical "zsync failed to update ${APP}"; }
	chmod a+x "./${APP}" || exit 1
	echo "$VERSION" > "./version"
	rm -R -f ./*zs-old ./*.part ./tmp ./*~
	notify-send "${APP} is updated!"
else
	echo "Update not needed!"
fi
EOF
chmod a+x "./AM-updater" || exit 1

# LAUNCHER & ICON
curl -qfsSL "${SITE}/${APP}.desktop" -o "./${APP}.desktop"
curl -qfsSL "${SITE}/${APP}.DirIcon" -o "./.DirIcon"
sed -i "s#Exec=[^ ]*#Exec=${APP}#g; s#Icon=.*#Icon=/opt/${APP}/icons/${APP}#g" "./${APP}.desktop"
mv "./${APP}.desktop" "/usr/local/share/applications/${APP}-AM.desktop" && mv "./.DirIcon" "./icons/${APP}" 1>/dev/null
