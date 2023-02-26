#!/bin/bash


###############
# Variables
###############
scriptFullPath=$(readlink -f "$0")


###############
# Installation
###############
cronLine="*/5 * * * * $scriptFullPath 1>/dev/null" # Redirect STDOUT to null, so no mail sent when OK

if [ "$1" = "--install" ]; then
	printf "Verify if already installed..."
	
	tmpFile=$(mktemp /tmp/monitor-fans.install.cron.XXXXX)
	crontab -l > "$tmpFile" 2>/dev/null
	hasCronJob=$(cat "$tmpFile" | grep "$0")
	printf "Done\n"
	if [ "$hasCronJob" = "" ]; then
		printf "Installing..."
		echo "$cronLine" >> "$tmpFile"
		crontab "$tmpFile"
		printf "Done\n"
	else
		echo "Already installed. Use --uninstall to uninstall."
	fi

	rm "$tmpFile"

	exit
fi

if [ "$1" = "--uninstall" ]; then
	printf "Verify if installed..."
	tmpFile=$(mktemp /tmp/monitor-fans.install.cron.XXXXX)
	crontab -l > "$tmpFile" 2>/dev/null
	hasCronJob=$(cat "$tmpFile" | grep "$0")
	printf "Done\n"
	if [ "$hasCronJob" = "" ]; then
		echo "Not installed. Use --install to install."
	else
		printf "Uninstalling..."		
		sed -i "\#$scriptFullPath#d" "$tmpFile"
		crontab "$tmpFile"
		printf "Done\n"
	fi

	rm "$tmpFile"
	exit
fi



###############
# Running
###############

## Verify dead share
autoMountedShares=$(grep -F "include = /etc/samba/smb.d/" /etc/samba/smb.conf)
if [ "$autoMountedShares" != "" ]; then
	while IFS='' read -r shareLine || [[ -n "$shareLine" ]]; do
		shareName=$(basename "$shareLine")
		includeLine="include = /etc/samba/smb.d/$shareName"
		shareFolder="/media/$shareName"
		isMounted=$(mount | grep -F "$shareFolder")
		isValid=$(ls -U "$shareFolder" 2>&1 1>/dev/null | head -1)

		#hasToClean=$([[ "$isValid" != "" ]] && [[ "$isMounted" != "" ]]);
		#hasToClean=$([ $hasToclean ] || [ "$isMounted" == "" ]);
		if [ "$isValid" != "" ] || [ "$isMounted" == "" ]; then
			echo "Removing $shareFolder"
			umount "$shareFolder" 2>/dev/null
			sed -iE "\#$includeLine#d" "/etc/samba/smb.conf"
			rm "/etc/samba/smb.d/$shareName" 2>/dev/null
		fi
	done <<< "$autoMountedShares"
fi



