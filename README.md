# DNS-323: How to overcome the software / hardware limitations
Nowdays, the D-Link DNS-323 NAS is not supported anymore and the SMB protocol supports only the version 1. This is how I started the project: trying, at least, to obtain SMBv2.0. The saga is about failure and success: this method that the first part is not enough glorified.

# How to read
The repository is organized with branches and the latest will be merged into master version. So, if you only want the instructions, just read next, otherwise, navigate through the branches and commmits.

# What you will obtain
- Debian Jessie as operating system
- SMBv3
- SSH connection to the hardware
- Overcome the 2TB limitation
- Possibility to add a USB 2.0 hub
- Automount / sharing of disk devices connected
- RAID-1 with failure detection that will warn you via email
- Fan control with failure detection that will warn you via email
- Printing server

# What you will lose
- The web interface to manage the hardware, but one could install something but may have to build it by him/herself.

# Let's start!

OK! What will I do. First of all, for the project to be feasible, I have to be able to somewhat give instructions to the OS. Looking through Internet, I found fun_plug. I would be able to connect through Telnet to execute commands. So here, my goal that I set is to be able to compile a newer version of Samba on the NAS, but not too much so it could be easier to integrate with less collateral changes to apply.

Good! My project is defined, my goal is written down and measurable. Let's rock!

> Now I was really confident I could do it and I would do it! Only success is on the path!

## Requirements
- Activate SMBv1.0 on Windows to be able to access a share volume. Turn on SMB1.0: https://tompai.pro/computers/d-link-dns-323-requires-smb1-protocol-cant-connect-from-windows-10/
- Find the device IP: You can use NMap to do so.
- Ensure access to the share volume

> Don't despair big boy! This trial will be the one!

## Steps
### Fun_plug / Telnet
- Follow the instructions on https://nas-tweaks.net/371/hdd-installation-of-the-fun_plug-0-7-on-nas-devices/#Steps_for_installing_fun_plug to install fun_plug.
    - Download http://inreto.de/dns323/fun-plug/0.7/oabi/fun_plug.tgz
    - Download https://inreto.de/dns323/fun-plug/0.7/oabi/fun_plug
    - Move them on the root directory of the share volume named Volume_1
    - Reboot the NAS
    - **There now should be a folder ffp, if not, reboot again**
- Connect using Telnet

> Oh yes! Success! I am now in a Linux environment. I can do anything!

- `cd /mnt/HD_a2/`
- Download all packages listed in "DNS-323/files-needed/fun_plug_0.7/packages/"
- Install them all using `fun-plug -i PACKAGE_FILE_NAME`

> Now fun_plug packages are installed. In fact, I did not installed all of them at once. I figured them out one by one. Hence, some of the errors I depict below go away when they are all installed.

> The only requirement to compile Samba 4.2.0 is Python. So let's compile it.

> OK! This time, I'll try again with Python 2.6, but with all funpkg I needed all along in previous attempt.

### Python

- `cd /mnt/HD_a2/`
- Download https://www.python.org/ftp/python/2.6.9/Python-2.6.9.tgz on Volume_1
- `tar -xvf Python-2.6.9.tgz`
- Download https://github.com/djon2003/DNS-323/blob/aebffb4d5951558f4ac0b8af336812918b40c1bd/files-needed/misc/sysv.S on Volume_1
- cp /mnt/HD_a2/sysV.S /mnt/HD_a2/Python-2.6.9/Modules/_ctypes/libffi/src/arm/
- `cd Python-2.6.9 && ./configure --prefix=/ffp`
- `make`

> Now the `_ctypes` module didn't fail, but it did not fix the Samba current error. OH!! What can I do? I don't have other ideas.

> Again, a little break is salvation. After looking in the Samba folder, I found `install_with_python.sh` where I discovered `configure` options that I may use.

- `./configure --prefix=/ffp --enable-shared --disable-ipv6`
- `make`

> OK! For now I don't see any improvement. Let's continue with Samba. Who knows!

### Samba

- `cd /mnt/HD_a2/`
- Download https://download.samba.org/pub/samba/stable/samba-4.2.0.tar.gz on Volume_1
- `tar -xvf samba-4.2.0.tar.gz`
- `./configure --prefix=/ffp --without-ad-dc --without-acl-support --without-ldap --without-ads`
- `make`

> One bug further! It went through the problematic step. Bingo!

```
[3193/3539] Linking default/lib/uid_wrapper/libuid-wrapper.so
default/lib/uid_wrapper/uid_wrapper_1.o: In function `uwrap_new_id':
uid_wrapper.c:(.text+0xb30): undefined reference to `__tls_get_addr'
uid_wrapper.c:(.text+0xc6c): undefined reference to `__tls_get_addr'
default/lib/uid_wrapper/uid_wrapper_1.o: In function `uwrap_init':
uid_wrapper.c:(.text+0xe50): undefined reference to `__tls_get_addr'
uid_wrapper.c:(.text+0xec4): undefined reference to `__tls_get_addr'
default/lib/uid_wrapper/uid_wrapper_1.o: In function `uwrap_setresuid_thread':
uid_wrapper.c:(.text+0x10cc): undefined reference to `__tls_get_addr'
default/lib/uid_wrapper/uid_wrapper_1.o:uid_wrapper.c:(.text+0x14ac): more undefined references to `__tls_get_addr' follow
```

> Oh my, oh my, oh my! Will I get over all those errors. Impossible!

- `./configure --prefix=/ffp --without-ad-dc --without-acl-support --without-ldap --without-ads --disable-gnutls`
- `make`

> Still no luck! Moreover, I discovered `gnustls` was disabled by default. So... was useless. Also, I learned that, here, the acronym TLS is not for Transport Layer Security, but Thread Local Storage. At least, it explains why this module was not part of the cause.

- `make V=1`

```
[3193/3539] Linking default/lib/uid_wrapper/libuid-wrapper.so
14:02:07 runner /ffp/bin/gcc default/lib/uid_wrapper/uid_wrapper_1.o -o /mnt/HD_a2/samba-4.2.0/bin/default/lib/uid_wrapper/libuid-wrapper.so -lpthread -Wl,-no-undefined -Wl,--export-dynamic -Wl,--as-needed -fstack-protector -shared -Wl,-rpath,/mnt/HD_a2/samba-4.2.0/bin/shared -Wl,-rpath,/mnt/HD_a2/samba-4.2.0/bin/shared/private -L/usr/local/lib -Wl,-Bdynamic -ldl
default/lib/uid_wrapper/uid_wrapper_1.o: In function `uwrap_new_id':
uid_wrapper.c:(.text+0xb30): undefined reference to `__tls_get_addr'
uid_wrapper.c:(.text+0xc6c): undefined reference to `__tls_get_addr'
default/lib/uid_wrapper/uid_wrapper_1.o: In function `uwrap_init':
uid_wrapper.c:(.text+0xe50): undefined reference to `__tls_get_addr'
uid_wrapper.c:(.text+0xec4): undefined reference to `__tls_get_addr'
default/lib/uid_wrapper/uid_wrapper_1.o: In function `uwrap_setresuid_thread':
uid_wrapper.c:(.text+0x10cc): undefined reference to `__tls_get_addr'
default/lib/uid_wrapper/uid_wrapper_1.o:uid_wrapper.c:(.text+0x14ac): more undefined references to `__tls_get_addr' follow
```

> Ehm, ehm! Here, even if it seems to be same output, if you look carefully, you'll see one extra line. An important one!

- Extract `ld-2.32.so` from http://ftp.us.debian.org/debian/pool/main/g/glibc/libc6_2.31-13+deb11u5_armel.deb on Volume_1
- `/ffp/bin/gcc /mnt/HD_a2/samba-4.2.0/bin/default/lib/uid_wrapper/uid_wrapper_1.o -o /mnt/HD_a2/samba-4.2.0/bin/default/lib/uid_wrapper/libuid-wrapper.so -lpthread -Wl,-no-undefined -Wl,--export-dynamic -Wl,--as-needed -fstack-protector -shared -Wl,-rpath,/mnt/HD_a2/samba-4.2.0/bin/shared -Wl,-rpath,/mnt/HD_a2/samba-4.2.0/bin/shared/private -L/usr/local/lib -Wl,-Bdynamic -ldl /mnt/HD_a2/ld-2.31.so`

> Oh yes! This fix shall work because... it compiled!

- `make`

> Patate! (French word that means failure in this context)

- `cp /mnt/HD_a2/ld-2.31.so /ffp/lib/ld-2.31.so`
- `ln -s /ffp/lib/ld-2.31.so /ffp/lib/ld-linux.so.3`
- `make`

> Name another vegetable that would mark failure... again! No high expectations, I'll just clean and retry.

- Try clean + config + make

> As expected, no change. Let's go drastically. When something goes wrong, you don't control a process and all other pathways had been explored, is there a way to circumvent the bug by intercepting something you know is called. Oh, giving my an idea!

- Create a script `/mnt/HD_a2/gcc.sh` with the following content:
```
#!/bin/sh

inputToTest1="default/lib/uid_wrapper/uid_wrapper_1.o -o /mnt/HD_a2/samba-4.2.0/bin/default/lib/uid_wrapper/libuid-wrapper.so -lpthread -Wl,-no-undefined -Wl,--export-dynamic -Wl,--as-needed -fstack-protector -shared -Wl,-rpath,/mnt/HD_a2/samba-4.2.0/bin/shared -Wl,-rpath,/mnt/HD_a2/samba-4.2.0/bin/shared/private -L/usr/local/lib -Wl,-Bdynamic -ldl"
inputToAdd1="/mnt/HD_a2/ld-2.31.so"
input="$@"

(
	cd /mnt/HD_a2/samba-4.2.0/bin

	if [ "$input" = "$inputToTest1" ]; then
		gcc0 $@ $inputToAdd1
	else
		gcc0 $@
	fi
)
```

- `mv /ffp/bin/gcc /ffp/bin/gcc0`
- `ln -s /mnt/HD_a2/gcc.sh /ffp/bin/gcc`
- `make`

> Oh my GOD!! It passed through the erronous compiling step! Waiting...

```
default/source3/smbd/notify_inotify_75.o: In function `inotify_setup':
notify_inotify.c:(.text+0x984): undefined reference to `inotify_init'
default/source3/smbd/notify_inotify_75.o: In function `watch_destructor':
notify_inotify.c:(.text+0xe34): undefined reference to `inotify_rm_watch'
default/source3/smbd/notify_inotify_75.o: In function `inotify_watch':
notify_inotify.c:(.text+0xfd4): undefined reference to `inotify_add_watch'
notify_inotify.c:(.text+0x1150): undefined reference to `inotify_rm_watch'
notify_inotify.c:(.text+0x11ec): undefined reference to `inotify_rm_watch'
```

> Ahhhh, failed, again! And if I recall correctly, it was a step around 3400 on 3539. Man, I was about to it.

> More investigation on this issue didn't help me to overcome this problem. I opened [a question on StackOverFlow](https://stackoverflow.com/questions/75179314/is-inotify-init-contained-in-linux-kernel), but I couldn't continue with the suggestions. When I received those, I was already trying to install Debian and I couldn't go back (well, not easily).

> My confidence to end my small project was now at its lowest (before Debian installation attempt).
