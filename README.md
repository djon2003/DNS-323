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


