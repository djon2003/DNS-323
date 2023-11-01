# DNS-323: How to overcome the software / hardware limitations
Nowdays, the D-Link DNS-323 NAS is not supported anymore and the SMB protocol supports only the version 1. This is how I started the project: trying, at least, to obtain SMBv2.0. The saga is about failure and success: this method that the first part is not enough glorified.

# How to read
The repository is organized with branches and the latest was merged into master. So, if you only want the instructions, just read next, otherwise, navigate through the branches and commits. Have fun!

<a href="https://medium.com/@djon2003/failure-success-principle-dfe3249fcf37">Another point of view of this story: Failure & Success principle</a>

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

---

> __Warning__ Read those notes before going any further

⚠ Make sure to have a backup because this procedure will wipe all your data.\
⚠ If somehow, you are stuck somewhere, you might find a solution, you might get help, BUT always remember that it could be possible you will have to use [the serial method](http://www.cyrius.com/debian/orion/d-link/dns-323/recovery/) to recover to the [original firmware](https://ftp.dlink.ca/ftp/PRODUCTS/DNS-323/DNS-323_FIRMWARE_1.10.ZIP).\
⚠ The D-Link DNS-323 is no longer supported by Debian.

---

## Debian

### Replacing original firmware

- Download https://archive.debian.org/debian/dists/jessie/main/installer-armel/current/images/orion5x/network-console/d-link/dns-323/netboot.img on your computer.
- Use the web interface of your DNS-323, in the firmware update section, and select the previously downloaded file.
- Proceed with "updating" your firmware. ⚠ Don't turn off / reboot your DNS-323 until it ends.
- Reboot the hardware.

### Finding the new IP address and connecting

- Get your computer IP address:
    - Via command line:
        - Open `cmd`.
        - `ipconfig`
        - Look for the network adapter currently in use (the IP address shall start with `192.168.`.
    - Via GUI:
        - Open Windows parameters / control panel.
        - Reach the network settings.
        - View the details of the currently in use adapter.
- Open [NMap](https://nmap.org/) (You can use the software of your choice that would achieve the same goal).
- In target box, you can enter `192.168.1.0/24` (the IP address of your computer except the last number is replaced with 0).
- In command box, add `-p 22` after `nmap`.
- Click on the scan button.

```
Scanning 26 hosts [1 port/host]
Discovered open port 22/tcp on 192.168.1.HIDDEN
Discovered open port 22/tcp on 192.168.1.HIDDEN
Discovered open port 22/tcp on 192.168.1.123
Discovered open port 22/tcp on 192.168.1.HIDDEN
```

All the `HIDDEN` keywords were in fact numbers, but for privacy, I obfuscate them. I left them here so you can see that you could have multiple devices having the port 22 opened. So, from there, you can discard all known IP addresses. If there is more then one left, you can try to connect vis SSH and if it connects, you found it. Here the IP address `192.168.1.123` would be my device (this is not the real one).

- Open [Putty](https://www.putty.org/) or WSL (Windows Subsystem for Linux) that I now prefer over Putty for SSH.
- `ssh installer@192.168.1.123`

```
Username: installer
Password: install
```

### Installing the operating system

- Go to shell directly with this first SSH connection. I will name it SSH-behind-the-scene (shorten SSH-b ![SSH-b][1]).

- `date -s '2020-01-01 11:00:00'`
- `tail -f /var/log/syslog`

- Open another SSH connection. I will name it SSH-installation (shorten SSH-i ![SSH-i][2]).

> OK! Now, to discern in what connection I am doing things, I'll prefix the step with its shortname when I change of context.

- ![SSH-i][2] Choose **Expert mode**.
- In *choosing server* step, select **Enter manually**.
    - Type `archive.debian.org`.
    - Accept default choices.
- In *modules* step, select: `fdisk, lvm-cfg, md+lvm, partman ext3, partman raid`.

- ![SSH-b][1] If it is your first boot, then, using `fdisk`, delete all partitions and ensure GPT on both disks.

- ![SSH-i][2] In *language* step, select your region, BUT do ***NOT*** add keyboard layout/locales.
- Follow steps up to *partionning* and enter it.

- If it is your first boot:

	- Select **Manual**.
	- Follow the **Configure RAID** menu. I recommend using RAID-1 as it is more safe for your data, but you are free, it shouldn't change the following steps.
	- Reboot NAS and start this section over.

- ![SSH-b][1] `cat /proc/mdstat`

If you get:

```
The RAID is currently syncing. (This is a paraphrase)
```

Use `while true; do printf "\033\143"; cat /proc/mdstat; echo "CTRL-C to quit"; sleep 10; done` until you get the result below then reboot.

If you get following result right away, then continue:

```
The RAID is active. (This is a paraphrase)
```

- ![SSH-i][2] In *partionning* step, select **Guided LVM**.
    - Give the names you want.
    - Select both disks.
- Continue up to *install base system*.
    - **STOP** on kernel choice.

- ![SSH-b][1] `nano /target/usr/sbin/mkinitramfs`:
	- Search for `MODULES=most`.
	- Comment all the "case" lines ***except*** `auto_add_modules`.
	
- ![SSH-i][2] In *install base system*.
    - Choose `linux-image-orion5x`.
- Continue up to *Configure package manager*.
	- I chose `No` to first two choices, **security updates** only.
- Continue up to *Make the system bootable* and **WAIT**.

- ![SSH-b][1] `. /lib/chroot-setup.sh`
- Change to `MODULES=loaded` in `/target/etc/initramfs-tools/conf.d/driver-policy` and `/target/etc/initramfs-tools/initramfs.conf`.
- `chroot /target lsmod | cut -f 1 -d\  > /target/etc/initramfs-tools/modules`
- Ensure `/target/etc/initramfs-tools/modules` first line is not "Module", if so delete it.
- `nano /target/usr/sbin/mkinitramfs`:
	- Search for `MODULES=most`.
	- Comment all the "case" lines ***including*** `auto_add_modules`
- `chroot_cleanup`

> I am confident that the above modification could replace previous modification made when it was the *install base system* step. If you want to try/test it.

- ![SSH-i][2] Proceed with the other installation steps.

- ![SSH-b][1] `shutdown -r now`. (If needed)

> After reboot...

- `ssh USERNAME@192.168.1.123`

## Making a complete NAS

> Note: I am not 100% ensure if there is no useless `sudo`.

I decided to create a main folder where all my shares would be and to begin with I have:

- `mkdir -p /share/data`
- `chmod 777 /share/data`
- `mkdir -p /share/scripts`
- `chmod 777 /share/scripts`

> Here I opened file permissions for those to full, but you can lower it or do what ever you want.

### Sudo

- `su`
- `apt install sudo`
- `usermod -aG sudo USERNAME`. Where USERNAME is the username you used during Debian installation section.
- Restart SSH session.

### Postfix

- `sudo apt install postfix`
	- Choose Internet with smarthost.

### Fan

- `sudo apt-get install lm-sensors`
- `sudo sensors-detect`
	- `YES` to all
- `sudo /etc/init.d/kmod start`
- `sudo apt-get install fancontrol`
- `sudo pwmconfig`
- `sudo /etc/init.d/fancontrol start`

> `monitor-fans.sh` execution modes:
> - No param: Tells you if the fan works.
> - `--install`: Install monitoring each 5 minutes.
> - `--uninstall`: Uninstall monitoring.

- `wget -O /share/scripts/monitor-fans.sh https://raw.githubusercontent.com/djon2003/DNS-323/2.3-Add-ons/files/monitor-fans.sh`
- `sudo /share/scripts/monitor-fans.sh --install`

### NTP

- `sudo apt install ntp`

### New locales (for UTF-8)

- `sudo dpkg-reconfigure locales`

### RAID monitoring

- `sudo nano /etc/mdadm/mdadm.conf` :
	- Add `MAILADDR my-email@domain.com`. Where `my-email@domain.com` has to be replaced by your email.
- To test email:
	- Kill any ***mdadm*** process.
	- `sudo mdadm --monitor --scan --test`
- To test failure:
	- Ensure the following command is running or run it: `mdadm --monitor --scan &`.
	- `mdadm --manage --set-faulty /dev/md0 /dev/sdb1`
	- Wait to receive the email.
	- `mdadm /dev/md0 -r /dev/sdb1`
	- `mdadm /dev/md0 -a /dev/sdb1`

### Samba

- `sudo apt-get install samba`
- `sudo bash -c 'echo "include = /etc/samba/smb.share.conf" >> /etc/samba/smb.conf'`
- `sudo wget -O /etc/samba/smb.share.conf https://raw.githubusercontent.com/djon2003/DNS-323/2.3-Add-ons/files/smb.share.conf`
- `sudo systemctl restart smbd`

### USB port

- Install exFAT support: `sudo apt install exfat-fuse exfat-utils`.
- Install NTFS support: `sudo apt install ntfs-3g`.
- Printer: I will let this exercise to the reader. As this one I've been able to do  it, but that's true for my model. Maybe in the future.

### Automount / Autoshare USB disks

#### Compile & Install USBMount

- `sudo apt-get install debhelper build-essential`
- `mkdir /share/temp-install`
- `cd /share/temp-install`
- `wget https://github.com/rbrito/usbmount/archive/refs/heads/master.zip`
- `unzip master.zip`
- `cd usbmount-master`
- `sudo dpkg-buildpackage -us -uc -b`
- `dpkg -i ../usbmount_0.0.24_all.deb`
- `cd /`
- `rm -rf /share/temp-install`

#### Configuration & script to ensure share alive

- `sudo nano /etc/usbmount/usbmount.conf`:
	- Add to **FILESYSTEMS** `exfat ntfs fuseblk ntfs-3g`.
	- Replace **MOUNTOPTIONS** value by `uid=1000,gid=1000,nodev`.
- `sudo wget -O /etc/usbmount/mount.d/01_create_samba_share https://github.com/djon2003/DNS-323/raw/2.3-Add-ons/files/01_create_samba_share`
- `sudo wget -O /etc/usbmount/umount.d/01_remove_samba_share https://github.com/djon2003/DNS-323/raw/2.3-Add-ons/files/01_remove_samba_share`
- `sudo mkdir /etc/samba/smb.d/`
- `wget -O /share/scripts/clear-phantom-shares.sh https://github.com/djon2003/DNS-323/raw/2.3-Add-ons/files/clear-phantom-shares.sh`
- `sudo /share/scripts/clear-phantom-shares.sh --install`

### Interesting packages

- `sudo apt-get install usbutils`: Tools for the USB port.
- `sudo apt install lshw`
	- `lshw -C network` : To show  network adapter.
- `sudo apt-get install eject` 
	- `eject /dev/sdc` : To disconnect/umount USB drive
- `sudo apt-get install udisks2` : Utilitary for USB. i.e. power-off. In my case, using `udisksctl power-off -b /dev/sdc`, made my USB HDD to be completely off. USB reconnection didn't work. I had to unplug the power cable and replug all to have the disk detected again. But, could be useful.

# References

## Debian

- https://md.ekstrandom.net/resources/dns323/
- https://wiki.debian.org/InstallingDebianOn/D-Link/DNS-323
- http://www.cyrius.com/debian/orion/d-link/dns-323/
- http://www.cyrius.com/debian/orion/d-link/dns-323/install/
- https://www.debian.org/releases/jessie/
- https://www.linuxquestions.org/questions/debian-26/how-do-i-create-an-initrd-img-file-597883/

## Recovery

- http://www.cyrius.com/debian/orion/d-link/dns-323/recovery/
- http://dns323.kood.org/hardware%3Aserial
- https://www.ionos.com/help/server-cloud-infrastructure/dedicated-server-for-servers-purchased-before-102818/rescue-and-recovery/software-raid-status-monitoring-linux/

## RAID

- https://tldp.org/HOWTO/Software-RAID-HOWTO-6.html
- https://serverfault.com/questions/495392/remove-faulty-state-in-raid-1

## Samba

- https://tompai.pro/computers/d-link-dns-323-requires-smb1-protocol-cant-connect-from-windows-10/
- https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
- https://www.samba.org/samba/download/
- https://wiki.samba.org/index.php/Build_Samba_from_Source
- https://www.samba.org/samba/history/
- https://wiki.samba.org/index.php?title=Package_Dependencies_Required_to_Build_Samba&oldid=10463#Python
- https://askubuntu.com/questions/917565/checking-smb-version
- https://askubuntu.com/questions/79078/how-to-restart-samba-server
- https://linuxconfig.org/how-to-set-up-a-samba-server-on-debian-10-buster

## Add-ons

- https://www.cyberciti.biz/faq/how-to-find-fan-speed-in-linux-for-cpu-and-gpu/
- https://unix.stackexchange.com/questions/134797/how-to-automatically-mount-an-usb-device-on-plugin-time-on-an-already-running-sy
- https://github.com/rbrito/usbmount

## Others
- https://nas-tweaks.net/371/hdd-installation-of-the-fun_plug-0-7-on-nas-devices/#Steps_for_installing_fun_plug
- http://dns323.kood.org/howto:crosscompile#pre-compiled_binaries
- https://devguide.python.org/getting-started/setup-building/

# Credits

- <a href="https://www.flaticon.com/free-icons/software" title="software icons">Software terminal icons created by Freepik - Flaticon</a>
- People on irc://irc.debian.org/#debian-arm
- People on StackOverFlow or their related sites.

[1]: https://github.com/djon2003/DNS-323/blob/2.4-Finalization/files/SSH-b.png?raw=true
[2]: https://github.com/djon2003/DNS-323/blob/2.4-Finalization/files/SSH-i.png?raw=true
