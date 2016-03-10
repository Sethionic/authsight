authsight
=========

Snap a webcam picture when someone tries to log into your computer with a wrong password. A remake of the Authsight project by Jonathan Zdziarski.

Uses imagesnap from http://iharder.sourceforge.net/current/macosx/imagesnap/ to capture images. 

Installation
============

**With prepackaged installer**

1. Download AuthSight.pkg from this repo and run it. 

OR

**Do it yourself**

1. Download imagesnap from http://prdownloads.sourceforge.net/iharder/ImageSnap-v0.2.5.tgz
2. Copy imagesnap to /usr/local/bin and make executable.
3. Download org.nogas.authsightd.plist and authsightd.pl from this repo
4. Copy the authsightd.pl to /usr/local/bin and make executable.
5. Run `sudo cp org.nogas.authsightd.plist /Library/LaunchDaemon/org.nogas.authsightd.plist`
6. Run `sudo chown root:wheel /Library/LaunchDaemons/org.nogas.authsightd.plist`
7. Run `sudo chmod 644 /Library/LaunchDaemons/org.nogas.authsightd.plist`
8. Run `sudo launchctl load -w /Library/LaunchDaemons/org.nogas.authsightd.plist`
