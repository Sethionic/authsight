#!/usr/bin/perl
#The orignal perl script behind authsight

use strict;
use IO::Handle;
use MIME::Base64;
use File::stat;
use vars qw { $ISIGHTCAPTURE $LOGDIR $LOGFILE $LAST $EMAIL $AIRPORT $IFCONFIG };
require "ctime.pl";

$| = 1;

$ISIGHTCAPTURE = "/opt/local/bin/isightcapture";
$LOGDIR        = "/var/log/AuthSight";
$LOGFILE       = "/var/log/secure.log";
$EMAIL         = "";
$IFCONFIG      = "/sbin/ifconfig";
$AIRPORT       = "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport";

mkdir($LOGDIR) if (! -d $LOGDIR);
&log("startup");
&log("reading configuration");
&getconfig();
if ($EMAIL eq "") {
    &log("logging only - no email address specified");
} else { 
    &log("logging and reporting to $EMAIL");
}
open(TAIL, "$LOGFILE");
while(<TAIL>) { }
for (;;) {

    while(<TAIL>) {
        chomp;
        if (/failed to authenticate user ([A-Z]*)/i) { ###For 10.6, use /var/log/secure.log
            my($user) = $1;
            if ($LAST eq $_) {
                $LAST = $_;
                &log("strange dupe error. ignoring: $_");
            }
            $LAST = $_;
            my($sec, $min, $hour, $day, $mon, $year) = (localtime(time));
            $year += 1900;
            $mon  ++;
            my($date) = sprintf("%02d-%02d-%04d_%02d.%02d.%02d", $mon, $day, $year, $hour, $min, $sec);
            my($file) = "$LOGDIR/$user\_$date.jpg";
            my($result) = `osascript -e 'do shell script "$ISIGHTCAPTURE $file"'`;
            chomp($result);
            &log("CAPTURE ON $_");
            &log("$file $result");

            if ($EMAIL ne "") {
                my($data);
                my($stat) = stat($file);
                my($size) = $stat->size();
                &log("emailing photo to $EMAIL size=" . $size);
                open(FILE, "<$file");
                binmode(FILE);
                read(FILE, $data, $size, 0);
                close(FILE);
                &email($data);
            }
        }
    }

    select(undef, undef, undef, .20);

    if (stat(*TAIL)->nlink == 0) {
        &log("re-opening $LOGFILE on new filehandle");
        close(TAIL);
        open(TAIL, $LOGFILE) || &log("failed to re-open file: $!");
        while(<TAIL>) { }
        &log("file re-oened");
    }
    seek(TAIL, 0, 1);
}

sub log {
  my($msg) = @_;
  my($time) = ctime(time);
  my(@proc) = split(/\//, $0);
  my($procname) = $proc[$#proc];
  chomp $msg;
  chomp($time);
  open(FILE, ">>/var/log/authsight.log");
  print FILE "$time $procname\[$$] $msg\n";
  close(FILE);
}

sub email {
    my($data) = @_;
    my($encoded) = encode_base64($data);
    my $ifconfig = `$IFCONFIG -a`;
    my $airport  = `$AIRPORT -I`;

    open(MAIL, "|/usr/sbin/sendmail -t");
    print MAIL <<_END;
To: $EMAIL
From: AuthSight <authsightd\@localhost.localdomain>
Subject: Authentication Failure
Content-Type: multipart/mixed; BOUNDARY="00BOUND"

--00BOUND
Content-Type: text/plain
Content-Transfer-Encoding: 8bit

$ifconfig

$airport

--00BOUND
Content-Type: image/jpeg
Content-Transfer-Encoding: base64

$encoded
--00BOUND--

_END
    close(MAIL);
    system("/usr/sbin/sendmail -q");
}

sub getconfig() {
    open(FILE, "</etc/authsight.cfg") || return -1;
    $EMAIL = <FILE>;
    close(FILE);
    $EMAIL =~ tr/[a-z0-9\@\.\_]//cd;
    return 0;
}
