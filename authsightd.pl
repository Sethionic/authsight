#!/usr/bin/env perl

use strict;
use Fcntl;
use File::stat;
use IO::File;
use IO::Handle;
use IO::Select;
use MIME::Base64;
use POSIX qw(:errno_h);
use vars qw { $IMAGESNAP $LOGDIR $LOGFILE $LAST $EMAIL $AIRPORT $IFCONFIG };

$| = 1;

$IMAGESNAP     = "/usr/local/bin/imagesnap";
$LOGDIR        = "/var/log/AuthSight";
$LOGFILE       = "/dev/auditpipe";
$EMAIL         = "";
$IFCONFIG      = "/sbin/ifconfig";
$AIRPORT       = "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport";
my $HEADER_SIZE = 18;
use constant READ_SIZE => 16*1024;

#Start of code
mkdir($LOGDIR) if (! -d $LOGDIR);
&log("startup");
&log("reading configuration");
&getconfig();
if ($EMAIL eq "") {
    &log("logging only - no email address specified");
} else { 
    &log("logging and reporting to $EMAIL");
}

# Open the auditpipe, this should never close.
sysopen(my ($fh), $LOGFILE, O_RDONLY|O_NONBLOCK) || &log("Couldn't open $LOGFILE for reading: $!\n");

binmode($fh) || &log("can't binmode $LOGFILE") ;

my $sel = new IO::Select ($fh); 

for (;;) { # Loop indefinitely, incase auditpipe is closed 
   my $buf = '';
   my $remaining_bytes;
   while ($sel->can_read()) {
      my $rv = sysread($fh, $buf, READ_SIZE, length($buf)); &log("Failed to fill buffer $!\n") if !defined($rv); last if !$rv;
      while ($buf) {
         my $msg = substr($buf,0,$HEADER_SIZE, "");
         my($user) = "";
         my ($header_token_ID, $header_byte_count, $header_version, $header_event_type, $header_event_modifier, $header_epoch_seconds, $header_milliseconds ) = unpack 'H2 H8 H2 H4 H4 H8 H8', $msg;
         $remaining_bytes = hex($header_byte_count) - $HEADER_SIZE ;
         if (length($buf) < $remaining_bytes) { my $rv = sysread($fh, $buf, READ_SIZE, length($buf)); &log("Failed to fill buffer $!\n") if !defined($rv); last if !$rv; }
         my ($remainder_of_record)= substr ($buf,0,$remaining_bytes, "");
         if (hex($header_event_type) eq "45023") {
            if ( ($remainder_of_record =~ /.*Authentication for user <([A-Za-z0-9]*)\x0\x27[^\x0]>/i) or 
                 ($remainder_of_record =~ /.*Verify password for record type Users '([A-Za-z0-9]*)'.*\x0\x27[^\x0]/i) or
                 ($remainder_of_record =~ /.*user <([A-Za-z0-9]*)>\x0\x27[^\x0]/i) or
                 ($remainder_of_record =~ /.*Error opening DS node for user <([A-Za-z0-9]*)>\x0\x27[^\x0]/i)
            ) {
               if (defined($1)) {
                  $user = $1;
                  if ($LAST eq $_) {
                      $LAST = $_;
                      &log("strange dupe error. ignoring: $_");
                  }
                  $LAST = $_;
	       } else {
                  $user="unknown";
               }
               my($sec, $min, $hour, $day, $mon, $year) = (localtime(time));
               $year += 1900;
               $mon  ++;
               my($date) = sprintf("%02d-%02d-%04d_%02d.%02d.%02d", $mon, $day, $year, $hour, $min, $sec);
               my($file) = "$LOGDIR/$user\_$date.jpg";
               my($result) = `osascript -e 'do shell script "$IMAGESNAP $file"' >> /var/log/authsight.log`;
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
         if (length($buf) < $HEADER_SIZE) { my $rv = sysread($fh, $buf, READ_SIZE, length($buf)); &log("Failed to fill buffer $!\n") if !defined($rv); last if !$rv; }
      }
   }
    if (stat($fh)->nlink == 0) {
       &log("re-opening $LOGFILE on new filehandle");
       close($fh);
       sysopen(my ($fh), $LOGFILE, O_RDONLY|O_NONBLOCK) || &log("Couldn't open $LOGFILE for reading: $!\n");
       binmode($fh) || &log("can't binmode $LOGFILE");
        &log("file re-oened");
   }
}

sub log {
  my($msg) = @_;
  my($time) = time;
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
