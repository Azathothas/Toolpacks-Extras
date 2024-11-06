- Author: [`@ruanformigoni`](https://github.com/ruanformigoni)
- Project Page: [https://github.com/ruanformigoni/flatimage](https://github.com/ruanformigoni/flatimage)
- Described as `FlatImage, a hybrid of Flatpak sandboxing with AppImage portability`
- Detailed Docs: [https://flatimage.github.io/docs/](https://flatimage.github.io/docs/)
- Naming Schema: `${PKG_NAME}-${BASE_DISTRO_IMAGE}-${ADDITIONAL_MODS}.FlatImage`
> ```bash
> !#Examples
> firefox-alpine.FlatImage --> Created using alpine as base BaseImage/RootFS
> steam-cachyos.FlatImage --> Created using CachyOs as BaseImage/RootFS
> librewolf-alpine-nix.FlatImage --> Created using alpine as BaseImage/RootFS with Nix on top of it
> ```
---


- #### Prerequisites `HOST`
> - [Fuse](https://github.com/pkgforge/pkgcache/blob/main/Docs/FUSE.md) `Required for mounting Filesystems & Images`
> - [Fonts](https://github.com/pkgforge/pkgcache/blob/main/Docs/FONTS.md) `Required to display/render Non-English Chars, Emojis, Symbols etc.`
> - [Kernel User NameSpaces](https://github.com/pkgforge/pkgcache/blob/main/Docs/USER_NAMESPACES.md) `Required for Sandboxing, Security & Performance`
