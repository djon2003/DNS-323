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
- `cd Python-2.6.9 && ./configure --prefix=/ffp`
- `make`

```
Failed to find the necessary bits to build these modules:
_bsddb             _tkinter           bsddb185
dbm                gdbm               nis
sunaudiodev
To find the necessary bits, look in setup.py in detect_modules() for the module's name.


Failed to build these modules:
_ctypes            _curses_panel
```

> Even with those fails, `python` can be executed

> One timer!

