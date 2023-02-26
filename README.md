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

- `tail -f /var/log/syslog`.
- `cat /proc/mdstat`.

```
No such file
```

> Oh! So, I have to continue the installation before having access to that.

- Open another SSH connection. I will name it SSH-installation (shorten SSH-i).

> OK! Now, to discern in what connection I am doing things, I'll prefix the step with its shortname when I change of context.

- SSH-i: Choose `Expert mode`.
- Select `Enter manually`.
    - Type `archive.debian.org`.
    - Accept default choices.
- In modules step, select: `fdisk, lvm-cfg, md+lvm, partman ext3, partman raid`.
- In language step, select your region and add the desired keyboard layouts.
- Follow steps up to partionning and enter it.
- SSH-b: `cat /proc/mdstat`.
```
The RAID is active. (This is a paraphrase)
```
- SSH-i: In partionning step, select `Guided LVM`.
    - Give the names you want.
    - Select both disks.

- Continue up to `install base system`.
    - Choose `linux-image-orion5x`

At ~78%:\
```
Failed installing busybox : "There are problems and -y was used without --force-yes"
```

> What the heck!? After some investigation, I found a line I could add the missing option. Really! Shoudn't it be going through without the modification I will apply!? This step won't be an exception: hard work!

- SSH-b: `nano /bin/apt-install`:
    - Replace `apt_opts="-q -y"` by `apt_opts="-q -y --force-yes"`.

- SSH-i: Enter `install base system`.

> Worst! Iiiii. It failed before choosing the Linux headers. I will try to apply the modification just before headers choice.

- SSH-b: Revert the modification of `/bin/apt-install`

- SSH-i: Enter `install base system`.
    - Stop on headers choice.

- SSH-b: `nano /bin/apt-install`:
    - Replace `apt_opts="-q -y"` by `apt_opts="-q -y --force-yes"`.

- SSH-i: In `install base system`:
    - Choose `linux-image-orion5x`
    
At ~83%:
```
Jan 24 19:17:47 in-target: /etc/kernel/postinst.d/initramfs-tools:
Jan 24 19:17:47 in-target: update-initramfs: Generating /boot/initrd.img-3.16.0-6-orion5x
Jan 24 19:17:48 in-target: mkinitramfs: for device /dev/mapper/VOLUME_GROUPE_NAME--vg-root missing  /sys/block/ entry
Jan 24 19:17:48 in-target: mkinitramfs: workaround is MODULES=most
Jan 24 19:17:48 in-target: mkinitramfs: Error please report the bug
Jan 24 19:17:48 in-target: update-initramfs: failed for /boot/initrd.img-3.16.0-6-orion5x with 1.
Jan 24 19:17:48 in-target: run-parts: /etc/kernel/postinst.d/initramfs-tools exited with return code 1
Jan 24 19:17:48 in-target: Failed to process /etc/kernel/postinst.d at /var/lib/dpkg/info/linux-image-3.16.0-6-orion5x.postinst line 634
```
- SSH-i: For `install base system`, I tried:
    - Different combinations on when to apply my modification.
    - Launching the installer with `MODULES=most && debian-installer`.
    - Not adding keyboard layout: this one fixed some "minor" errors.

> The horizon depicts an enormous cyclone. Well, I learned not to add keyboard layouts. Even though choosing a kernel is mandatory to make the boot, I told myself I could test "none" and try to install it later on.

- SSH-b: Ensure to have the modification of `/bin/apt-install`

- SSH-i: In `install base system`:
    - Choose `none` on the kernel question.
    
- Continue up to "Configure package manager"
	- I chose `No` to first two choices, **security updates** only.

- Continue with *Select and install software*

> From there, it has been a tough row to hoe.

Among my infinite attempts, I found this error:
```
GPG error: http://archive.debian.org jessie Release: The following signatures were invalid: KEYEXPIRED 1587841717" (GMT: Saturday 25 April 2020 19:08:37) when "chroot /target /usr/bin/apt-get update
```

> I realized something big here! I was about sure the issue with the obligation to use `--force-yes` was linked to a certificate issue, but I didn't see, at first, it was linked to an expired one. So...

- SSH-b: `date -s '2020-01-01 11:00:00'`

> The date was chosen to be lower than the Linux time 1587841717. My hacks trying to inject `--force-yes` shall now be useless. Cool!

>  I will start back.

- `shutdown -r now`
