authsight
=========

Snap a webcam picture when someone tries to log into your computer with a wrong password. A remake of the Authsight project by Jonathan Zdziarski.

Uses imagesnap from http://iharder.sourceforge.net/current/macosx/imagesnap/ to capture images. 

Installation
============

1. Download ImageSnap from http://prdownloads.sourceforge.net/iharder/ImageSnap-v0.2.5.tgz
2. Copy imagesnap to /usr/local/bin and make executable.
3. Copy the authsightd.pl to /usr/local/bin and make executable.
4. Copy the authsightd.plist to /Library/LaunchDaemon
5. Run `sudo chown root:wheel /Library/LaunchDaemons/org.nogas.authsightd.plist`
6. Run `sudo chmod 644 /Library/LaunchDaemons/org.nogas.authsightd.plist`
7. Run `sudo launchctl load -w /Library/LaunchDaemons/org.nogas.authsightd.plist`
