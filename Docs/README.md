- #### What? & Why?
<!-- This is not True (Yet) -->
<!-- > - This, at the time of writing is, the **[largest collection](https://github.com/pkgforge/pkgcache#-status-)** of [*`downloadable`* (without requiring compilation)](https://huggingface.co/datasets/pkgforge/pkgcache/tree/main) & [*`up-to-date`*](https://github.com/pkgforge/pkgcache/commits/main/) 📦📀 Portable Packages available on the public web.
> > **`More >`** than all of these *COMBINED*: [ivan-hc/AM](https://github.com/ivan-hc/AM), [AppImageHub](https://www.appimagehub.com/)
<!-- Will Show when we actually have more pkgs -->
> - I created [Toolpacks](https://github.com/Azathothas/Toolpacks), the [largest collection](https://github.com/Azathothas/Toolpacks/blob/main/Docs/README.md#what--why) of Static Binaries on the web.
> - Life was fun & everything was okay until: https://github.com/Azathothas/Toolpacks/issues/28, this made me go down a rabbit hole where I discovered formats like: [AppBundles](https://github.com/xplshn/pelf/) `|` [AppImages](https://github.com/ivan-hc/AM) `|` [FlatImages](https://github.com/ruanformigoni/flatimage) `|` [RunImages](https://github.com/VHSgunzo)
> - Those didn't really fit the theme of [Toolpacks](https://github.com/Azathothas/Toolpacks), and thus this repo came into Existence.
> - The aim is to have [a centralized repo](https://huggingface.co/datasets/pkgforge/pkgcache/tree/main) & [scripts](https://github.com/pkgforge/pkgcache/tree/main/.github/scripts) to [build, compile & bundle](https://github.com/pkgforge/pkgcache/actions) as <ins>many PKGs</ins> as possible and in as <ins>many format</ins> as Possible.
---
- #### How does It All Work?
> - It's all same as [ToolPacks](https://github.com/Azathothas/Toolpacks/blob/main/Docs/README.md#how-does-it-all-work), with some changes such as this repo uses [Hugging Face](https://huggingface.co/datasets/pkgforge/pkgcache/tree/main) instead of an [R2 Bucket.](https://bin.pkgforge.dev)

---
- #### How to add (request) a new a PKG/Tool?
> 1. First & Foremost, make sure to check that it's **not already available**.
> 2. After you are really sure that it's not available, [create a new issue](https://github.com/pkgforge/pkgcache/issues/new)
> ```YAML
> Title: [+] PKG Request ${YOUR_PKG_TITLE}
> Body: Provide a `Description`, `Category`, `web_url`, `src_url` of the PKG
> #web_url is just the homepage/project page , #src_url is Git or Source Code url
> Also: Include if someone already builds an AppImage (or another Portable Format), so we can just simply fetch from there.
> ```
---

- #### `Broken | NOT Portable` Packages
> - If you find a `$PKG` that doesn't work (`segfaults/crashes`) or some other erros, it will be treated as a bug.
> - First, try to diagnose, and see if it only affects you.
> - Also search online and [in the Issues Page](https://github.com/pkgforge/pkgcache/issues), if there's entries about your Issue.
> - Also, read the relevant entry of your format to see if it's an Edge Case:
> > - [`$PKG.AppBundle`](https://github.com/pkgforge/pkgcache/blob/main/Docs/APPBUNDLES.md)
> > - [`$PKG.AppImage`](https://github.com/pkgforge/pkgcache/blob/main/Docs/APPIMAGES.md)
> > - [`$PKG.Archives`](https://github.com/pkgforge/pkgcache/blob/main/Docs/ARCHIVES.md)
> > - [`$PKG.FlatImage`](https://github.com/pkgforge/pkgcache/blob/main/Docs/FLATIMAGES.md)
> > - [`$PKG.GameImage`](https://github.com/pkgforge/pkgcache/blob/main/Docs/GAMEIMAGES.md)
> > - [`$PKG.NixAppImage`](https://github.com/pkgforge/pkgcache/blob/main/Docs/NIXAPPIMAGES.md)
> > - [`$PKG.RunImage`](https://github.com/pkgforge/pkgcache/blob/main/Docs/RUNIMAGES.md)
> - Finally, [create an Issue](https://github.com/pkgforge/pkgcache/issues/new) (Include as much info as possible, including your [`Distro`](https://distrowatch.com/), [`Desktop Environments`](https://en.wikipedia.org/w/index.php?title=Desktop_environment#Gallery), [`Window Managers`](https://wiki.archlinux.org/title/Window_manager), [`XDG_ENV`](https://wiki.archlinux.org/title/XDG_Base_Directory), [`ENV_VARS (env)`]
---

- #### Why not host on GitHub?
> - Because GitHub has very conservative limits: https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github
> - [Hugging Face](https://huggingface.co/datasets/pkgforge/pkgcache/tree/main) has [generous limits](https://huggingface.co/docs/hub/en/repositories-recommendations) & [inbuilt support for LFS](https://huggingface.co/docs/hub/en/repositories-getting-started)
> - Last but not least, to avoid https://github.com/pkgforge/pkgcache/edit/main/Docs/README.md#dmca-copyright--cease--desist
---

- #### How to verify checksums?
> - [**SHA256SUM**](https://linux.die.net/man/1/sha256sum)
> ```bash
> ❯ Linux (curl + jq + sha256sum)
> !#path= should be exact location to $PKG, so if it's in cwd, path="./$PKG" [REPLACE $PKG with literal Value)
> echo "$(curl -qfsSL "https://pkgcache.pkgforge.dev/$(uname -m)/METADATA.json" | jq -r '.[] | select(.name == "$PKG") | .shasum')  $PKG" | sha256sum -c -
>  
> ```
> - Or You can do it manually, the checksums are at:
> > - [`BLAKE3SUM aarch64-Linux`](https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux/BLAKE3SUM.json): https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux/BLAKE3SUM.json
> > - [`BLAKE3SUM x86_64-Linux`](https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux/BLAKE3SUM.json): https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux/BLAKE3SUM.json
> > - [`SHA256SUM aarch64-Linux`](https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux/SHA256SUM.json): https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux/SHA256SUM.json
> > - [`SHA256SUM x86_64-Linux`](https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux/SHA256SUM.json): https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux/SHA256SUM.json
---

- #### Supporting More [`Architectures`](https://wiki.debian.org/SupportedArchitectures) & [`OS`](https://en.wikipedia.org/wiki/List_of_operating_systems)
> - I would like to build `PKGS` for other architectures like [`riscv64`](https://en.wikipedia.org/wiki/RISC-V), and the [BSD Family of OSes](https://en.wikipedia.org/wiki/Comparison_of_BSD_operating_systems), however my time & especially **`RESOURCES`** are limited.
> - If you would like to see additional build targets prioritized, donating a [Dedicated Build Server](https://github.com/pkgforge/pkgcache/tree/main/Docs#how-to-contribute) would be the optimal encouragement.
> - Note: `32-Bit` `PKGS` will likely never be Supported/Added since that's now ancient and even embedded devices now ship with `64-Bit` **ARCH**
---

- #### [Cache & Rebuild](https://github.com/marketplace/actions/cache)
> - It's often been suggested to use a [caching system](https://github.com/cachix/cachix) to <ins>Decrease Build Time</ins> & <ins>Avoid Rebuilding OutDated Repos</ins>
> - While this suggestion is sound and seems like a no-brainer to implement, potential pain-points:
> > - This would involve rewriting all of the [build recipes (`~ >5000`)](https://github.com/pkgforge/pkgcache/tree/main/.github/scripts) or at the very least adding some new logic to the process.
> > - This would also require [New infra & Servers](https://github.com/pkgforge/pkgcache/tree/main/Docs#how-to-contribute) which will <ins>increase Cost & Maintenance.</ins>
> > - Using [Cached Artefacts](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/caching-dependencies-to-speed-up-workflows) & [Non-Ephemeral Containers](https://github.com/ephemeralenvironments/ephemeralenvironments) will mean an increase in [Attack Vectors via Supply Chain](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions).
> > - Thus, this is quite impractical and is unlikely to ever be implemented.
---

- #### **`📦 Frontend Package Managers 📦`**
> - Here are some fantastic package managers 📦 [developed](https://antonz.org/writing-package-manager/) by talented individuals that [utilize this project](https://github.com/pkgforge/pkgcache/blob/main/Docs/METADATA.md):
> > - [`@xplshn/dbin`](https://github.com/xplshn/dbin) is the current de-facto, recommended one you should use, but it's more of cli-manager.
> > - [`@ivan-hc/AM`](https://github.com/ivan-hc/AM) can also be used, if they use `$PKGS` from here.
---

- #### [`DMCA`](https://opensource.guide/legal/), [`Copyright`](https://opensource.guide/legal/) & [`Cease & Desist`](https://opensource.guide/legal/)
> - If you/your project/software uses a license which forbids binary distribution, and you would like to take down the binary:
> > - First, having such clause and disallowing people to distribute binaries, will harm only your own popularity/ potential user increment
> > - Second, this repo is intentionally licensed as [`unlicense`](https://unlicense.org/) which is essentially Public Domain/Do whatever you want.
> > - Third, if you have no problems with any major package managers like [brew](https://brew.sh/), [NixPKGs](https://search.nixos.org/packages), [pkgsrc](https://pkgsrc.org/) etc, you shouldn't have an Issue with this repo.
> > - In summary, all `DMCA | CopyRight` **Notices will be Ignored & Not Complied With.**
> > > All PKGs are hosted on HuggingFace, and NOT GitHub. GitHub only contains scripts & source code.
---

- #### How to Setup & Configure Local Build Environment
> - This uses the same Runners & Build Environment as [Toolpacks](https://github.com/Azathothas/Toolpacks/blob/main/Docs/README.md#how-to-setup--configure-local-build-environment)
> - Initial steps are same, but you will also have to have a [Hugging Face Token](https://huggingface.co/docs/hub/en/security-tokens), check [setup_env.sh](https://github.com/pkgforge/pkgcache/blob/main/.github/scripts/x86_64-Linux/env.sh) for details
---

- #### How to contribute?
> To contribute, you **first must read & understand this entire repo**. After that, follow similar code/script style to make changes & then create a pull request.
> 
> This means, if your changes/pull request is not compatible with how I would do it, it will probably involve a lot of back & forth (Merge/Squashing)
> 
> Hence, if all you want to do is request for some packages/tools to be added, you are better off creating an Issue instead. Read: https://github.com/pkgforge/pkgcache/tree/main/Docs#how-to-add-request-a-new-a-pkgtool
>
> - However, if it's not related to `code | asking for more packages` to be included, you can **contribute/help me by donating a build server**. Either `arm (Preferred)` or `amd x86_64`.
> - Servers & Storage cost money, right now I pay for [Self Hosted Github Runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners) & R2 Bucket (`70-100$/Month`).
> > | Builder | Specs| Host | Dedicated ? | Build Time | Cost |
> > | ------- | ---- | ---- | --------- | ---------- | ---- |
> > | [`x86_64` `Linux`](https://github.com/pkgforge/pkgcache/actions/workflows/build_x86_64-Linux.yaml) | `8 vCPU (AMD EPYC™ 9634)` `+` `16 GB RAM (DDR5 ECC)` `+` `512 GB SSD` `+` `Unmetered Bandwidth` | [`Netcup`](https://www.netcup.eu/bestellen/produkt.php?produkt=3694) | [`Semi-Dedicated`](https://www.netcup.eu/vserver/vergleich-root-server-vps.php) | `20-25` `Hrs` | `$18.50/Mo` |
> > | [`aarch64` `Linux`](https://github.com/pkgforge/pkgcache/actions/workflows/build_aarch64_Linux.yaml) | `12 vCPU (Ampere Altra)` `+` `24 GB RAM (??)` `+` `768 GB SSD` `+` `Unmetered Bandwidth` | [`Netcup`](https://www.netcup.eu/bestellen/produkt.php?produkt=3991) | `NO` | `35-40` `Hrs` | `$16.70/Mo` | 
---

- #### [WebUI (pkgcache.pkgforge.dev)](https://pkgcache.pkgforge.dev/)
> - At some point, it would be nice to have a web interface like https://portable-linux-apps.github.io/, but for now, It's not planned.
---

- #### Typos, Grammatical Errors & Bad Documentation
> - Unfortunately, English is NOT my Native Tongue & neither do I have the patience or time to extensibly review & double check what I write!
> - As a result, there's higher than usual frequency of typos & grammatical errors. And the Documentation is rather obscure and not well written.
> - That's why, I welcome any and all efforts to correct me. Please [submit PRs](https://github.com/pkgforge/pkgcache/pulls) and I will merge them.
---

- #### Public Code Search
> - [GitHub Search](https://github.com/search?q=NOT+user%3AAzathothas+NOT+user%3Axplshn+NOT+user%3Ametis-os+NOT+user%3Ahackerschoice+NOT+is%3Afork+pkgcache.pkgforge.dev&type=code&s=updated&o=desc): `NOT user:Azathothas NOT user:xplshn NOT user:metis-os NOT user:hackerschoice NOT is:fork pkgcache.pkgforge.dev`
> - [Google](https://www.google.com)|[Bing](https://www.bing.com/)|[Baidu](https://www.baidu.com): `"*.pkgcache.pkgforge.dev" -site:ajam.dev`
---

- #### [Contact](https://ajam.dev/contact)
> - If you find your question hasn't been answered here OR you would like to seek clarification OR just say Hi : https://ajam.dev/contact
