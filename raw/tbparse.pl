#!/usr/bin/perl -w
#
# TBPARSE 2008 (c) TU Delft, Hans van der Marel
#
# Turbo binary file parser. Parses the TB binary files and 
# - Checks for synchronisation errors and file integrity
# - Count the records and determine start and end epoch
# - Remove duplicate data records
#
# Usage :  TBPARSE [-d level][-o tbout] [-e tbbad] tbfile

use Getopt::Std;
use Time::Local;

getopts('d:o:e:');

$opt_d=0 if (!defined($opt_d));


@datfiles = @ARGV;

foreach $file (@datfiles) {

  # load complete file into memory

  $xfile=$file;
  $xfile="gzip -d -S .zip -c $file |" if ( $file =~ /(\.Z|.gz|.zip)$/i );

  open(FILE, "$xfile")  or die "can't open $file: $!";
  binmode(FILE);
  undef $/;
  $buffer=<FILE>;
  close(FILE)  or die "can't close $file: $!";
  $end=length($buffer);


  if (defined($opt_o)) {
    open(OUTFILE, ">$opt_o")  or die "can't open tb output file $opt_o: $!";
    binmode(OUTFILE);
  }
  if (defined($opt_e)) {
    open(DUPFILE, ">$opt_e")  or die "can't open tb error file $opt_e: $!";
    binmode(DUPFILE);
  }


  print "Turbo binary file $file ($end bytes)\n" if ($opt_d > 0);

  # parse the file in memory

  %seen=();

  $ptr=0;
  $ptr=NextTBMessage($ptr);
  $lasttimetag=-999;
  $lastchannel=0;
  $intv=3600;
  @svns=();
  @channels=();


  $sof=0;
  
  while ( $ptr <= $end ) {  
    $seen{$id}++;
    printf ("%3d %4d   %8d --> %8d\n", $id ,$length ,$ptr0 ,$ptr) if ($opt_d > 2);
    last if ($length == 0);
    if ( $id == 104 ) {
       ($svn,$channel,$timetag)=unpack("CCN",substr($message,0,6));
       if ( ( $timetag != $lasttimetag ) && ( $lasttimetag != -999) ) {
	  $intv=$timetag-$lasttimetag if ( ($timetag-$lasttimetag) < $intv );
          if ($opt_d > 0) {
             printf("==> %12d  %3d  channels: ",$lasttimetag,$count);
   	     for (@channels) { printf(" %3d",$_) };
	     printf("\n");
	  }
	  if ( ($timetag-$lasttimetag) > $intv ) {
             printf("!!! DATAGAP of %d sec. at %d!!!\n",$timetag-$lasttimetag,$timetag);
	  } 
	  $count=0;
          @svns=();
          @channels=();

          syswrite(OUTFILE,substr($buffer,$sof,$ptr0-$sof)) if (defined($opt_o));
	  $sof=$ptr0;
       }
       if ( ( $timetag == $lasttimetag ) && ( $channel <= $lastchannel) ) {
          printf("==> %12d  %3d  channels: ",$timetag,$count);
	  for (@channels) { printf(" %3d",$_) };
	  printf("   !!! DUPLICATE RECORDS !!!\n");
	  $count=0;
          @svns=();
          @channels=();

          syswrite(DUPFILE,substr($buffer,$sof,$ptr0-$sof)) if (defined($opt_e));
	  $sof=$ptr0;
       }
       $count++;
       push(@svns,$svn); 
       push(@channels,$channel); 
       # printf("==> %3d %3d %12d\n",$svn,$channel,$timetag);
       $lasttimetag=$timetag;       
       $lastchannel=$channel;
    }

    $ptr=NextTBMessage($ptr);
  }

  print "\nStatistics for TB file $file:\n";
  print " ID  count\n";
  foreach $id ( sort { $a <=> $b } keys %seen ) {
    printf("%3d %6d\n",$id,$seen{$id});
  }

  syswrite(OUTFILE,substr($buffer,$sof,$end-$sof)) if (defined($opt_o));


}

  close(OUTFILE) if (defined($opt_o));
  close(DUPFILE) if (defined($opt_e));


exit;

sub NextTBMessage{

  # Get the next (standard)  message from the Turbo Binary file
  # Syntax:
  #          $prt=NextTBMessage($ptr);
  #
  # The ID, length and message contents are returned in the variables
  # $id, $length and $message.

  my ($ptr) = @_;

  # Check the pre-amble of the record
  #
  # Byte   Name       Description            Possible values
  #  0     rectyp     Record type
  #  1     reclen     Record length        
  #
  # id     = rectyp 

  if ( $ptr+1 > $end ) { return $ptr+1;}

  $tag=substr( $buffer, $ptr, 2);
  ($rectype,$reclen)=unpack("CC",$tag);

  print "$reclen $rectype\n" if ($opt_d > 2);

  $length=$reclen;
  $id=$rectype;
  $message=substr( $buffer, $ptr+2 , $length-2);
  $ptr0 = $ptr;
  $ptr = $ptr + $length;

  return $ptr;

}



