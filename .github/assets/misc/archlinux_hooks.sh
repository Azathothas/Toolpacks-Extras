#!/usr/bin/env bash

## DO NOT RUN DIRECTLY
#ONLY RUN FROM WITHIN CHROOT
#Self


##SystemD Updates
shopt -s nullglob
for i in $(grep -rin -m1 -l "ConditionNeedsUpdate" /usr/lib/systemd/system/); do
  sed -Ei "s/ConditionNeedsUpdate=.*/ConditionNeedsUpdate=/" "$i"
done
grep -rin "ConditionNeedsUpdate" "/usr/lib/systemd/system/"
  
##Pacman Hooks
mkdir -p "/etc/pacman.d/hooks"
#Override Desktop cache
tee "/etc/pacman.d/hooks/update-desktop-database.hook" << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = *

[Action]
Description = Overriding the desktop file MIME type cache...
When = PostTransaction
Exec = /bin/true
EOF
#Override MIME cache
tee "/etc/pacman.d/hooks/30-update-mime-database.hook" << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = *

[Action]
Description = Overriding the desktop file MIME type cache...
When = PostTransaction
Exec = /bin/true
EOF
#Cleanup cache
tee "/etc/pacman.d/hooks/cleanup-pkgs.hook" << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = *

[Action]
Description = Cleaning up downloaded files...
When = PostTransaction
Exec = /bin/sh -c 'rm -rf /var/cache/pacman/pkg/*'
EOF
#Cleanup Locale
tee "/etc/pacman.d/hooks/cleanup-locale.hook" << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = *
  
[Action]
Description = Cleaning up locale files...
When = PostTransaction
Exec = /bin/sh -c 'find /usr/share/locale -mindepth 1 -maxdepth 1 -type d -not -iname "en_us" -exec rm -rf "{}" \;'
EOF
#Cleanup Docs
tee "/etc/pacman.d/hooks/cleanup-doc.hook" << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = *

[Action]
Description = Cleaning up doc...
When = PostTransaction
Exec = /bin/sh -c 'rm -rf /usr/share/doc/*'
EOF
#Cleanup Manpages
tee "/etc/pacman.d/hooks/cleanup-man.hook" << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = *

[Action]
Description = Cleaning up man...
When = PostTransaction
Exec = /bin/sh -c 'rm -rf /usr/share/man/*'
EOF
#Cleanup Fonts
tee "/etc/pacman.d/hooks/cleanup-fonts.hook" << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = *

[Action]
Description = Cleaning up noto fonts...
When = PostTransaction
Exec = /bin/sh -c 'find /usr/share/fonts/noto -mindepth 1 -type f -not -iname "notosans-*" -and -not -iname "notoserif-*" -exec rm "{}" \;'
EOF
##END