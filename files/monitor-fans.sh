#!/bin/sh


###############
# Variables
###############
scriptFullPath=$(readlink -f "$0")
scriptDir=$(dirname "$scriptFullPath")
confFile="$scriptFullPath.conf"


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
	if [ "$hasCronJob" = "" ] || [ ! -f "$confFile" ]; then
		if [ ! -f "$confFile" ]; then
			read -p "Mail 'To' address:" mailTo
			read -p "Mail 'From' address:" mailFrom
		fi

		printf "Installing..."
		if [ ! -f "$confFile" ]; then
			echo "MAIL_TO=\"$mailTo\"" > "$confFile"
			echo "MAIL_FROM=\"$mailFrom\"" >> "$confFile"
			echo "MAIL_FROM_NAME=\"\$(hostname)\"" >> "$confFile"
		fi
		if [ "$hasCronJob" = "" ]; then
			echo "$cronLine" >> "$tmpFile"
			crontab "$tmpFile"
		fi
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

if [ ! -f "$confFile" ]; then
	echo "Missing configuration file. Please run with --install."
	exit
fi

## Include configuration file
. "$confFile"

## Verify fan speed
inErrorFile="$scriptFullPath.err"
fanSpeed=$(sensors | grep -e "^fan" | sed -E "s/fan[0-9][^0-9]+([0-9]+)[^0-9]*/\1/")
if [ $fanSpeed -lt 1 ]; then
	errTooYoung=$(find "$inErrorFile" -mtime -1 -print 2>/dev/null)
	if [ -f "$inErrorFile" ] && [ "$errTooYoung" != "" ]; then
		echo "Fan broken! Email already sent"
	else
		if [ -f "$inErrorFile" ] && [ "$errTooYoung" = "" ]; then
			logger "error: $0 sent back email of broken fan at `date`"
			echo "Sent back email of broken fan"
		else
			logger "error: $0 sent email of broken fan at `date`"
			echo "Sent email of broken fan"
		fi

		subject="Fan is broken"
		body="Verify the fan as the monitoring reads fan speed at zero"

		echo "$body" | mail -s "$subject" -a "From: $MAIL_FROM_NAME <$MAIL_FROM>" "$MAIL_TO"
		touch "$inErrorFile"
	fi
else
	rm "$inErrorFile" 2>/dev/null
	echo "Fan works!"
fi



