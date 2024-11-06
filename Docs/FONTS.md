- #### [`Alpine`](https://wiki.alpinelinux.org/wiki/Fonts)
> ```bash
> !#Use doas/sudo wherever applicable
> apk update --no-interactive
> packages="fontconfig font-awesome font-inconsolata font-noto font-terminus font-unifont"
> for pkg in $packages; do apk add "$pkg" --latest --upgrade --no-interactive ; done
> fc-cache --force --verbose || sudo fc-cache --force --verbose
> #Ideally logout/login again or Restart your system
> ```
> 
- #### [`Arch`](https://wiki.archlinux.org/title/Fonts) & [`Derivatives`](https://wiki.archlinux.org/title/Arch-based_distributions)
> ```bash
> !#Use doas/sudo wherever applicable
> pacman -y --sync --refresh --noconfirm
> packages="fontconfig noto-fonts otf-font-awesome terminus-font ttf-dejavu ttf-inconsolata-nerd"
> for pkg in $packages; do pacman -Sy "$pkg" --noconfirm ; done
> fc-cache --force --verbose || sudo fc-cache --force --verbose
> #Ideally logout/login again or Restart your system
> ```
> 
- #### [`Debian`](https://wiki.debian.org/Fonts) & [`Derivatives`](https://en.wikipedia.org/wiki/Category:Debian-based_distributions)
> ```bash
> !#Use doas/sudo wherever applicable
> sudo apt update -y -qq && sudo apt install fontconfig fonts-noto -y
> fc-cache --force --verbose || sudo fc-cache --force --verbose
> #Ideally logout/login again or Restart your system
> ```
