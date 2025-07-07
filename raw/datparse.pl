#!/usr/bin/perl -w
#
# JPSPARSE 2001 (c) TU Delft, Hans van der Marel
#
# Timble DAT file parser. Parses the DAT binary files and 
# - Checks for synchronisation errors and file integrity
# - Count the records and determine start and end epoch (N/A)
# - Split the file into hourly or daily chunks (N/A)
#
# Usage :  DATPARSE [-c hours] [-d level] [-h] jpsfile

use Getopt::Std;
use Time::Local;

getopts('c:d:n:h:');

$opt_c=0 if (!defined($opt_c));
$opt_d=0 if (!defined($opt_d));

# GPS time starts at Sunday 6th 1980 00:00
$time0 = timegm(0,0,0,6,0,1980);

@datfiles = @ARGV;

foreach $file (@datfiles) {

  if (defined($opt_n)) {
    $station=$opt_n;
  } else {
    $station=substr($file,0,4);
  }
  # load complete file into memory

  $xfile=$file;
  $xfile="gzip -d -S .zip -c $file |" if ( $file =~ /(\.Z|.gz|.zip)$/i );

  open(FILE, "$xfile")  or die "can't open $file: $!";
  binmode(FILE);
  undef $/;
  # until ( eof(FILE) ) {
  #   $buffersize = read (FILE, $buffer, $MAXBUFFER )
  # }
  $buffer=<FILE>;
  close(FILE)  or die "can't close $file: $!";
  $end=length($buffer);

  print "DAT file $file ($end bytes)\n" if ($opt_d > 0);

  # parse the file in memory

  %seen=();
  $epoch=0;
  $havedate=0;
  $chunk0=0;
  $todlast=-999999;
  $daycount=0;

  $ptr=0;
  $ptr=NextDATMessage($ptr);
  while ( $ptr <= $end ) {  
    $seen{$id}++;
    printf ("%3d %4d %2d   %8d --> %8d\n", $id ,$length ,$numrec ,$ptr0 ,$ptr) if ($opt_d > 1);
    SWITCH: {
      if ($id == 17 ) {
        # Receiver time
        ($rcvrtime,$offset,$nsat)=unpack("ddC",$message);
        $rcvrtime=$rcvrtime*.001;
        $offset=$offset;
        $hour=int($rcvrtime/3600); $min=int(($rcvrtime - $hour * 3600)/60); $sec=$rcvrtime - $hour * 3600 - $min * 60;       
        $day=int($hour/24); $hour=$hour-$day*24;
        $time=sprintf("%02d:%02d:%02d",$hour,$min,$sec);
        print "nsat=$nsat time=$rcvrtime ($day $time) offset=$offset msec \n" if ($opt_d > 0);
        last SWITCH;
      }
    }
    $ptr=NextDATMessage($ptr);
  }

  print "\nStatistics for DAT file $file:\n";
  print " ID  count\n";
  foreach $id ( sort { $a <=> $b } keys %seen ) {
    printf("%3d %6d\n",$id,$seen{$id});
  }

}
  
exit;

sub NextDATMessage{

  # Get the next (standard)  message from the Trimble DAT file
  # Syntax:
  #          $prt=NextDATMessage($ptr);
  #
  # The ID, length and message contents are returned in the variables
  # $id, $length and $message.

  my ($ptr) = @_;

  # Check the pre-amble of the record
  #
  # Byte   Name       Description            Possible values
  #  0     preamb     Synchronization byte   must be 74h
  #  1     reclen     Record length        
  #  2     numrec     Number of records
  #  3     rectyp     Record type
  #
  # id     = rectyp 
  # length = reclen if (rectyp > 2 && rectyp != 12 && rectype != 17);
  # length = reclen + 256 * numrec if (rectyp == 12 || rectype == 17 );

  $syncbyte=hex('74');

  if ( $ptr+1 > $end ) { return $ptr+1;}

  $preamb=ord(substr( $buffer, $ptr , 1));

  print "Preamble --> $preamb ($syncbyte)\n" if ($opt_d > 2);

  if ($preamb != $syncbyte) {
    #out of sync, re-synchronize
    print "WARNING: OUT OF SYNC\n";
    $ptr0=$ptr;
    while ($preamb != $syncbyte ) {
      $ptr++;
      $preamb=ord(substr( $buffer, $ptr , 1));
      print "$preamb " if ($opt_d > 2);
      last if ( $ptr >= $end );
    }
    print "Skipped bytes $ptr0 until $prt\n";
    #check if next occurence is a tag as well
    #SOME MORE CODE NEEDED HERE
    # print the bad chunk for checking purposes
#    $badstring0=substr( $buffer, $ptr0 - 4 , 4 );
#    $badstring=substr( $buffer, $ptr0 , $ptr-$ptr0 );
#    print "Malformed chunk $ptr0...$ptr-1  $badstring0 -> $badstring \n";
#    # decode the tag
#    if ($tag =~ /([0-~][0-~])([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])/ ) {
#      $id=$1;
#      $length=hex($2);
#    }
  }

  if ( $ptr+4 > $end ) { return $ptr+4;}

  $tag=substr( $buffer, $ptr+1 , 3);
  ($reclen,$numrec,$rectype)=unpack("CCC",$tag);

  print "$reclen $numrec $rectype\n" if ($opt_d > 2);

  $length=$reclen;
  $length=$reclen + 256*$numrec if ($rectype == 12 || $rectype == 17);
  $id=$rectype;
  $message=substr( $buffer, $ptr+4 , $length);
  $ptr0 = $ptr;
  $ptr = $ptr + $length;

  return $ptr;

}



