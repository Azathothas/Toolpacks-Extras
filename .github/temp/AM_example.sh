#!/bin/sh
set -u
##This is an example/template on how AM can use Toolpacks-Extras's METADATA (https://pkg.ajam.dev/x86_64/METADATA.min.json)
#Fields Available:
#name: "#Contains the Name of the $PKG itself, this is NOT what it will/should be Installed as"
#bin_name: "#Contains the real name, the $PKG will be installed as"
#description: "#Contains the Description of the $PKG/$PKG_FAMILY [Otherwise EMPTY]"
#category: "#Contains the $PKG/$PKG_FAMILY's Category"
#note: "#Contains Additional Notes,Refs,Info the user need to be aware of, of the $PKG/$PKG_FAMILY [Otherwise EMPTY]"
#version: "#Contains the version of the $PKG"
#src_url: "#Contains the Git/Source URL of the $PKG/$PKG_FAMILY [Otherwise EMPTY]"
#web_url: "#Contains the Website/Project Page URL of the $PKG/$PKG_FAMILY [Otherwise EMPTY]"
#download_url: "#Contains the Raw Direct Download URL of the $PKG"
#size: "#Contains the Total Size of the $PKG"
#bsum: "#Contains the Exact Blake3sum of the $PKG"
#shasum: "#Contains the Exact Sha256sum of the $PKG"
#build_date: "#Contains the Exact Date the $PKG was Built(Fetched) & Uploaded"
#build_script: "#Contains the Actual Script the $PKG was Built(Fetched) With"
#build_log: "#Contains the link to view the Actual CI BUILD LOG of the $PKG"
#extra_bins: "#Contains names of related pkgs (Only if they belong to same $PKG_FAMILY) of the $PKG/$PKG_FAMILY [Otherwise EMPTY]
##But only some are used as AM doesn't support ALL
#The value of APP, is same as .bin_name from METADATA
APP="puddletag"
#The src is just the root url, the original is: https://huggingface.co/datasets/Azathothas/Toolpacks-Extras/resolve/main/x86_64-Linux
SRC="https://pkg.ajam.dev/$(uname -m)"
#The type tells us what kind of package it is, Details: https://github.com/Azathothas/Toolpacks-Extras/tree/main/Docs
TYPE="NixAppImage"
#This is to construct the .download_url from METADATA
SITE="${SRC}/${APP}.${TYPE}"

#COPIED VERBATIM from AM
[ -n "${APP}" ] && mkdir -p "/opt/${APP}" "/opt/${APP}/icons" && cd "/opt/${APP}" || exit 1
printf "#!/bin/sh\nset -e\nrm -f /usr/local/bin/${APP}\nrm -R -f /opt/${APP}" > "./remove"
printf '\n%s' "rm -f /usr/local/share/applications/${APP}-AM.desktop" >> "./remove"
chmod a+x "./remove" || exit 1

#Version can be fetched easily by appending .version at the end of .download_url from METADATA
VERSION="$(curl -qfsSL "${SITE}.version")"
wget "${SITE}" -O "./${APP}" || exit 1
echo "${VERSION}" > "./version"
chmod a+x "./${APP}" || exit 1

#COPIED VERBATIM from AM
ln -s "/opt/${APP}/${APP}" "/usr/local/bin/${APP}"

#Updater, containing the same changes as described above
cat >> "./AM-updater" << 'EOF'
#!/bin/sh
set -u
APP="puddletag"
SRC="https://pkg.ajam.dev/$(uname -m)"
TYPE="NixAppImage"
SITE="${SRC}/${APP}.${TYPE}"
VERSION0=$(cat "/opt/${APP}/version")
VERSION="$(curl -qfsSL "${SITE}.version")"
[ -n "$VERSION" ] || { echo "Error getting link"; exit 1; }
if command -v appimageupdatetool >/dev/null 2>&1; then
	cd "/opt/${APP}" || exit 1
	appimageupdatetool -Or ./"${APP}" && chmod a+x ./"${APP}" && echo "${VERSION}" > ./version && exit 0
fi
if [ "$VERSION" != "$VERSION0" ]; then
	mkdir "/opt/${APP}/tmp" && cd "/opt/${APP}/tmp" || exit 1
	notify-send "A new version of ${APP} is available, please wait"
	wget "${SITE}" || exit 1
	cd ..
	mv --backup=t "./tmp/${APP}.${TYPE}" "./${APP}"
	chmod a+x "./${APP}" || exit 1
	echo "$VERSION" > "./version"
	rm -R -f ./*zs-old ./*.part ./tmp ./*~
	notify-send "${APP} is updated!"
else
	echo "Update not needed!"
fi
EOF
chmod a+x "./AM-updater" || exit 1

##To fetch the Icon & Desktop file, there's two options
#The usual way
./"${APP}" --appimage-extract *.desktop 1>/dev/null && mv ./squashfs-root/*.desktop ./"${APP}".desktop
./"${APP}" --appimage-extract .DirIcon 1>/dev/null && mv ./squashfs-root/.DirIcon ./DirIcon
#Or this way:
curl -qfsSL "${SITE}.desktop" -o "./${APP}.desktop"
curl -qfsSL "${SITE}.DirIcon" -o "./.DirIcon"
##The LAUNCHER & ICON, block has now no need to check symlinks
##COPIED VERBATIM from AM
sed -i "s#Exec=[^ ]*#Exec=${APP}#g; s#Icon=.*#Icon=/opt/${APP}/icons/${APP}#g" "./${APP}.desktop"
mv "./${APP}.desktop" "/usr/local/share/applications/${APP}-AM.desktop" && mv ./DirIcon "./icons/${APP}"
rm -R -f ./squashfs-root
