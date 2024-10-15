- #### [What?](https://man7.org/linux/man-pages/man7/user_namespaces.7.html)
> - This is only relevant for packages from `.pkg`
> - The TLDR is that it's a way to isolate user and group IDs between processes, like creating a "mini operating system" inside the real operating system.
> - In a user namespace, a process can think it's running as the root user (with all the usual admin powers), but in reality, it's still a regular user outside of that namespace. 
> - This allows AppImages (& Variants) think they have full control, but in fact, they are limited to what the outer system allows.
> - Some distros like [Ubuntu](https://ubuntu.com/blog/ubuntu-23-10-restricted-unprivileged-user-namespaces) disable it using AppArmor for security: https://ubuntu.com/blog/ubuntu-23-10-restricted-unprivileged-user-namespaces
> - But you can disable that, and just use modern Sandboxing Tools like [BubbleWrap](https://github.com/containers/bubblewrap) & [firejail](https://github.com/netblue30/firejail). Or Wrappers like [AISAP]( https://github.com/mgord9518/aisap) & 

---
- #### [Check]()
```bash
!#Check if it's enabled at Kernel Level
sysctl -n user.max_user_namespaces
#This will print a number
#if it doesn't or it's user.max_user_namespaces = 0, then it's disabled

!#Check if it's enabled/restricted Using unshare : https://man7.org/linux/man-pages/man1/unshare.1.html
unshare --user echo "Username namespaces supported"
#If Suporrted: Username namespaces supported
#If Not: unshare: unshare(0x10000000): Operation not permitted

!#Check if AppArmor|SeLinux is stopping us 
sudo dmesg | grep -E '(selinux|apparmor|security)'
#Look for lines containing words like denied, disallowing etc
```

---
- #### Errors & Solutions
> > - `READ`: https://www.baeldung.com/linux/kernel-enable-user-namespaces
> > - `READ`: https://man7.org/linux/man-pages/man7/namespaces.7.html
> > - `READ`: https://man7.org/linux/man-pages/man7/user_namespaces.7.html
> > - You will also need to install [`uidmap`](https://command-not-found.com/newuidmap)
> > - For [Ubuntu (AppArmor)](https://askubuntu.com/questions/1511854/how-to-permanently-disable-ubuntus-new-apparmor-user-namespace-creation-restric): https://askubuntu.com/questions/1511854/how-to-permanently-disable-ubuntus-new-apparmor-user-namespace-creation-restric
> 
> - **`[WARN] Your kernel does not support user namespaces`**
> > ```bash
> > !#Because /proc/self/ns/user on your System, doesn't exist
> > 1. You need to install SUID Bubblewrap into the system
> > #For RunImage, this solution will work, but for others, refer to others.
> > # wget "https://bin.ajam.dev/$(uname -m)/bwrap" -O "/tmp/bwrap"
> > # sudo cp -f "/tmp/bwrap" "/usr/bin/bwrap" && sudo chmod u+s "/usr/bin/bwrap"
> >
> > 2. You need to run some Packages (that require usernamespace) as ROOT [NOT RECOMMENDED & DANGEROUS]
> >
> > 3. Install a Kernel with user namespaces support like XanMod kernel -> https://xanmod.org
> >
> > ```
> > 
> - **`[WARN] You must Enable unprivileged_userns_clone`**
> > ```bash
> > !#Because /proc/sys/kernel/unprivileged_userns_clone == 0
> > ❯ Enable unprivileged_userns_clone
> > echo "kernel.unprivileged_userns_clone=1" | sudo tee "/etc/sysctl.d/98-unprivileged-userns-clone.conf"
> > echo "1" | sudo tee "/proc/sys/kernel/unprivileged_userns_clone"
> > sudo service procps restart
> > sudo sysctl -p "/etc/sysctl.conf"
> > #Reboot
> > ```
> > 
> - **`[WARN] You must Enable max_user_namespaces`**
> > ```bash
> > !#Because /proc/sys/user/max_user_namespaces == 0
> > ❯ Enable max_user_namespaces
> > echo "user.max_user_namespaces=10000" | sudo tee "/etc/sysctl.d/98-max-user-namespaces.conf"
> > echo "100000" | sudo tee "/proc/sys/user/max_user_namespaces"
> > sudo service procps restart
> > sudo sysctl -p "/etc/sysctl.conf"
> > #Reboot
> > ```
> >
> - **`[WARN] You must Disable userns_restrict`**
> > ```bash
> > !#Because /proc/sys/kernel/userns_restrict == 1
> > ❯ Disable userns_restrict
> > echo "kernel.userns_restrict=0" | sudo tee "/etc/sysctl.d/98-userns.conf"
> > echo "0" | sudo tee "/proc/sys/kernel/userns_restrict"
> > sudo service procps restart
> > sudo sysctl -p "/etc/sysctl.conf"
> > #Reboot
> > ```
> >
> - **`[WARN] You must disable apparmor_restrict_unprivileged_userns`**
> > ```bash
> > !#Because /proc/sys/kernel/apparmor_restrict_unprivileged_userns == 1
> > ❯ Disable apparmor_restrict_unprivileged_userns
> > echo "kernel.apparmor_restrict_unprivileged_userns=0" | sudo tee "/etc/sysctl.d/98-apparmor-unuserns.conf"
> > echo "0" | sudo tee "/proc/sys/kernel/apparmor_restrict_unprivileged_userns"
> > sudo service procps restart
> > sudo sysctl -p "/etc/sysctl.conf"
> > #Reboot
> > ```
>
