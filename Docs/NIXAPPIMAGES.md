- Author: [`@ralismark`](https://github.com/ralismark) `+` [`@Azathothas`](https://github.com/Azathothas) `+` [`Others`](https://github.com/NixOS/bundlers)
- Project Page: [https://github.com/pkgforge/nix-appimage](https://github.com/pkgforge/nix-appimage)
- Described as An AppImage created using a [Nix-Bundler](https://github.com/NixOS/bundlers) like [pkgforge/nix-appimage](https://github.com/pkgforge/nix-appimage) & [DavHau/nix-portable](https://github.com/DavHau/nix-portable)
- Naming Schema: `${PKG_NAME}.NixAppImage`
> ```bash
> !#Examples
> firefox.NixAppImage --> FireFox from #NixPkgs : -p firefox
> ungoogled-chromium.NixAppImage --> Ungoogled Chromium from #NixPkgs : -p ungoogled-chromium
> ```
---

- Caveats & Known Issues
> - [libGL](https://github.com/NixOS/nixpkgs/issues/9415)
> - ~~[User Namespaces & Sandboxing](https://github.com/ralismark/nix-appimage/issues/10)~~ `Fixed` by [`@pkgforge/nix-appimage`](https://github.com/pkgforge/nix-appimage)
> - **Large Image Size**: About `2-5x` larger than other formats, but <ins>guarantee absolute portability.</ins>
---

- #### Prerequisites `HOST`
> - [Fuse](https://github.com/pkgforge/pkgcache/blob/main/Docs/FUSE.md) `Required for mounting Filesystems & Images`
> - [Fonts](https://github.com/pkgforge/pkgcache/blob/main/Docs/FONTS.md) `Required to display/render Non-English Chars, Emojis, Symbols etc.`
> - [Kernel User NameSpaces](https://github.com/pkgforge/pkgcache/blob/main/Docs/USER_NAMESPACES.md) `Required for Sandboxing, Security & Performance`
