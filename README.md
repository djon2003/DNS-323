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

Across all my searches to find answers during my previous *phase*, that I'm calling "the compilation try", I saw another option that could be explored, but more risky. Hence, the first phase which had been a dead end. I could flash totally the hardware by another OS. When you are trying to accomplish something that you don't have experience in or you think it can be risky: ensure a fallback solution. 

In te first step, I simply had to use the reset button et voilà! Now if a catastrophic result happens (no access to the device), I would have to open the device, plug a wire and use serial commands to upload the original firmware. More complex, risky and it has a cost.

OK! After looking at what I found, I choose Debian because I have someone that already did it. And he raised no issue. It should easy. No?

> At that moment, even if the task was labeled easy, my confidence was not that high due to the failure of the previous phase.

---

> __Warning__ Read those notes before going any further

⚠ Make sure to have a backup because this procedure will wipe all your data.\
⚠ If somehow, you are stuck somewhere, you might find a solution, you might get help, BUT always remember that it could be possible you will have to use [the serial method](http://www.cyrius.com/debian/orion/d-link/dns-323/recovery/) to recover to the [original firmware](https://ftp.dlink.ca/ftp/PRODUCTS/DNS-323/DNS-323_FIRMWARE_1.10.ZIP).\
⚠ The D-Link DNS-323 is no longer supported by Debian.

---

## Debian

> Let's put aside all my doubts and start this new phase.

> The two following subsections are inspired by http://www.cyrius.com/debian/orion/d-link/dns-323/install/.

### Replacing original firmware

- Download https://ftp.nl.debian.org/debian/dists/jessie/main/installer-armel/current/images/orion5x/network-console/d-link/dns-323/netboot.img on your computer.
- Use the web interface of your DNS-323, in the firmware update section, and select the previously downloaded file.
- Proceed with "updating" your firmware. ⚠ Don't turn off / reboot your DNS-323 until it ends.
- Reboot the hardware.

### Finding the new IP address and connecting

- I firstly thought to ping my device in a loop using the previously assigned IP address

- I secondly tried to verify my router DHCP table to retrieve the new address.

> No luck. What I've done. My hardware is no more accessible and my only way to connect back to it would be the [the serial method](http://www.cyrius.com/debian/orion/d-link/dns-323/recovery/). Wait! I know! Based on the instructions, I have to connect via SSH. So, I could search the IP with a software that looks for opened ports in my local network.

- Get your computer IP address:
    - Via command line:
        - Open `cmd`.
        - `ipconfig`.
        - Look for the network adapter currently in use (the IP address shall start with `192.168.`.
    - Via GUI:
        - Open Windows parameters / control panel.
        - Reach the network settings.
        - View the details of the currently in use adapter.
- Open [NMap](https://nmap.org/) (You can use the software of your choice that would achieve the same goal).
- In target box, you can enter `192.168.1.0/24` (the IP address of your computer except the last number is replaced with 0).
- In command box, add `-p 22` after `nmap`
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
- `ssh installer@192.168.1.123`.

```
Username: installer
Password: install
```

> Bingo! At least I can still access my device. I am safe.

### Installing the operating system

> This time, I'll prepare myself like a pro.

- Go to shell directly with this first SSH connection. I will name it SSH-behind-the-scene (shorten SSH-b).

- `date -s '2020-01-01 11:00:00'`
- `tail -f /var/log/syslog`.

- Open another SSH connection. I will name it SSH-installation (shorten SSH-i).

> OK! Now, to discern in what connection I am doing things, I'll prefix the step with its shortname when I change of context.

- SSH-i: Choose **Expert mode**.
- Select **Enter manually**.
    - Type `archive.debian.org`.
    - Accept default choices.
- In modules step, select: `fdisk, lvm-cfg, md+lvm, partman ext3, partman raid`.
- In language step, select your region, BUT do NOT add keyboard layout/locales.
- Follow steps up to partionning and enter it.
- SSH-b: `cat /proc/mdstat`.
```
The RAID is active. (This is a paraphrase)
```
- SSH-i: In partionning step, select **Guided LVM**.
    - Give the names you want.
    - Select both disks.

> At that point, I knew I had to choose a kernel. So, I tried to dig into how to apply the fix suggestion in the error of `mkinitramfs`.

- Continue up to *install base system*.
    - **STOP** on kernel choice.

- SSH-b: `nano /target/usr/sbin/mkinitramfs`.
	- Search for `MODULES=most`.
	- Comment all the "case" lines ***except*** `auto_add_modules`.
	
- In *install base system*.
    - Choose `linux-image-orion5x`
    
> OHHHHHHHHHHH!! Wow! I went through this step without error.

- Continue up to *Configure package manager*.
	- I chose `No` to first two choices, **security updates** only.

- Continue up to *Make the system bootable*.

> It fails now because the `initrd` file is too big for the hardware. I will reproduce the issue myself.

- SSH-b: `. /lib/chroot-setup.sh`.
- `chroot_setup`.
- `chroot /target/ update-initramfs -u -k 3.16.0-6-orion5x`.

```
update-initramfs: Generating /boot/initrd.img-3.16.0-6-orion5x
flash-kernel: installing version 3.16.0-6-orion5x

The initial ramdisk is too large. This is often due to the unnecessary inclusion
of all kernel modules in the image. To fix this set MODULES=dep in one or both
/etc/initramfs-tools/conf.d/driver-policy (if it exists) and
/etc/initramfs-tools/initramfs.conf and then run 'update-initramfs -u -k 3.16.0-6-orion5x'

Not enough space for initrd in MTD 'File System' (need 10528885 but is actually 6488064).
run-parts: /etc/initramfs/post-update.d//flash-kernel exited with return code 1
```

> I tried to set `set MODULES=dep`, but I got the same error.

- Change to `MODULES=loaded` in `/target/etc/initramfs-tools/conf.d/driver-policy` and `/target/etc/initramfs-tools/initramfs.conf`.
- `chroot /target lsmod | cut -f 1 -d\  > /target/etc/initramfs-tools/modules`.
- Ensure /target/etc/initramfs-tools/modules first line is not "Module", if so delete it.
- `nano /target/usr/sbin/mkinitramfs`.
	- Search for `MODULES=most`.
	- Comment all the "case" lines ***including*** "auto_add_modules".
- `chroot /target/ update-initramfs -u -k 3.16.0-6-orion5x`.

> BANG!! The flash has been updated. Another irreversible step. Crossing fingers!

> I am confident that the above modification could replace previous modification made when it was the *install base system* step. If you want to try/test it.

- SSH-i: Continue with *Make the system bootable*.

> OHH NO!! It fails because it says something (I don't remember what) is already currently running.

- SSH-b: `chroot_cleanup`.

- SSH-i: Continue with *Make the system bootable*.

> Waiting... waiting... waiting...! The step ended. No error! Yahoo!! Final step.

- Proceed with the final installation steps.

- `shutdown -r now`.

> After reboot...

- `ssh USERNAME@192.168.1.123`.

> Boom! I am connected on the newly installed system! Already gained more physical space! Let's relax a bit and will finish with "add-ons".
