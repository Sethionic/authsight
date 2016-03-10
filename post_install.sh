#!/bin/bash
cp authsightd.plist /Library/LaunchDaemon/org.nogas.authsightd.plist
sudo chown root:wheel /Library/LaunchDaemons/org.nogas.authsightd.plist
chmod 644 /Library/LaunchDaemons/org.nogas.authsightd.plist
launchctl load -w /Library/LaunchDaemons/org.nogas.authsightd.plist

