# DNS-323: How to overcome the software / hardware limitations
Nowdays, the D-Link DNS-323 NAS is not supported anymore and the SMB protocol supports only the version 1. This is how I started the project: trying, at least, to obtain SMBv2.0. The saga is about failure and success: this method that the first part is not enough glorified.

# How to read
The repository is organized with two branches and the latest will be the final and master version. So, if you only want the instructions, just read next, otherwise, navigate through the branches and commmits.

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

- cd /mnt/HD_a2/
- Download all packages listed in "DNS-323/files-needed/fun_plug_0.7/packages/"
- Install them all using `fun-plug -i PACKAGE_FILE_NAME`

> Now fun_plug packages are installed. In fact, I did not installed all of them at once. I figured them out one by one. Hence, some of the errors I depict below go away when they are all installed.

> The only requirement to compile Samba 4.2.0 is Python. So let's compile it.

### Python
- cd /mnt/HD_a2/
- Download https://www.python.org/ftp/python/2.6.9/Python-2.6.9.tgz on Volume_1
- `tar -xvf Python-2.6.9.tgz`
- `cd Python-2.6.9 && ./configure`

> Here, I got errors over errors. Ohhhh! Will I be able to fix all those compilation errors.

I will list all corrections I applied. From my notes, as I did a lot of attempts, it shall be those, but maybe some aren't necessary or not in proper order.

- cd /mnt/HD_a2/
- Download http://uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-armv5l.tar.bz2 to Volume_1
- `tar -xvf cross-compiler-armv5l.tar.bz2`
- `mkdir /ffp/include/linux`
- `cp cross-compiler-armv5l/include/linux/limits.h /ffp/include/linux
- `cd Python-2.6.9 && ./configure`

> Still not :( I will try using a lower version of Python.

- cd /mnt/HD_a2/
- Download http://python.org/ftp/python/2.4.2/Python-2.4.2.tgz 
- `tar -xvf Python-2.4.2.tgz`
- `cd Python-2.4.2 && ./configure`

> Other errors poping up.

- mkdir /ffp/include/asm`
- cd /mnt/HD_a2/
- Download http://uclibc.org/downloads/binaries/0.9.30.1/mini-native-armv5l.tar.bz2 to Volume_1
- `tar -xvf mini-native-armv5l.tar.bz2`
- `cp mini-native-armv5l/usr/include/linux/ /ffp/include/`
- `cp mini-native-armv5l/usr/include/asm/ /ffp/include/`
- `cp mini-native-armv5l/usr/include/asm-generic/ /ffp/include/`
- Disable line 243 of `/ffp/include/unistd.h` to fix double declaration issue
- `cd Python-2.4.2 && ./configure`

> Still no luck! Will I finally compile Python or not?

What if I use `./configure --prefix=/ffp` instead? Let's try with an higher Python version.

- cd /mnt/HD_a2/
- Download http://python.org/ftp/python/2.5.0/Python-2.5.0.tgz on Volume_1
- `tar -xvf Python-2.5.0.tgz`
- `cd Python-2.5.0 && ./configure --prefix=/ffp`

> I, I, I did the first!! Dancing!

- `make`

> Got an error of "not enough space"! GRRRR!

- `mkdir ../tmp.gcc`
- `TMPDIR=/mnt/HD_a2/tmp.gcc/ && make`

> MAN!!! It compiled! Eureka!

- `make install`
- `python`
    - print("Hello my new Python installation")

> More than being compiled, I can execute it and it runs and executes commands.

> Now, the final goal: Samba!

### Samba

- cd /mnt/HD_a2/
- Download https://download.samba.org/pub/samba/stable/samba-4.2.0.tar.gz to Volume_1
- `tar -xvf samba-4.2.0.tar.gz`
- ./configure --prefix=/ffp

> Some failure I was able to link them `./configure` options.

- ./configure --prefix=/ffp --without-ad-dc --without-acl-support --without-ldap --without-ads

> Still... ah another one I will have difficulties compiling!

- cp /ffp/include/et/com_err.h /ffp/include/ ==> Maybe could have been fixed by installing funpkg "e2fsprogs-1.41.14-oarm-3.txz"

> Yeah!! At least, one of three steps done!

- make

> !"/$%?& ! Another compilation missing space! (I don't recall, if it really happened executing `make` or `configure`, but the different technique I used to patch it suggests me that I've done it for `configure`. Remember, it is an instructional story. The end instructions are stone, but the steps to get there are just a little less certain. At that time, I wasn't taking notes to write this.)

- mv /tmp /tmp.old
- mkdir /mnt/HD_a2/tmp.gcc/
- ln -s /mnt/HD_a2/tmp.gcc/ /tmp
- make

> Here, all my attempts were vain! And I tried... so I let the project alone!

> Finally, I thought that with everything I learned from this failure may help me do the right thing in the right order and... that may help. OK! Courage is back! Let's start over!

- Use the reset button on the hardware to erase everything. Reconfigure the RAID-1 if needed and fulfill all the requirements.

> Side note: In fact, the reset button had already been used multiple times. I am telling here that there is highs and lows (success & failure) all long. Each time the peeks (upward and downward) increase.
