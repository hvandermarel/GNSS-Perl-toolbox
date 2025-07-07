#!/usr/bin/perl -w
#
# JPSAPPEND 2001 (c) TU Delft, Hans van der Marel
#
# Append JPS files 
#
# Usage :  JPSAPPEND [-c] [-d #] [-a] [-f] -o outputfile inputfiles
#
# Options: -c             skip each second JPS file preamble in the 
#                         copy/append operation
#          -d #           debugging level
#          -o outputfile  output file name
#          -a             append input files to "outputfile" 
#          -f             force overwrite if "outputfile" already
#                         exists, or force file creation in case
#                         of append mode if "outputfile" does not exist
#
# "outputfile".idx will be created/updated to hold information
# to undo the copy/append operation later.

use Getopt::Std;
use Time::Local;
use File::Basename;

# GPS time starts at Sunday 6th 1980 00:00

# $time0 = timegm(0,0,0,6,0,1980);

# Get command line options

getopts('o:d:caf');

$opt_d=0 if (!defined($opt_d));
$opt_c=0 if (!defined($opt_c));
$opt_a=0 if (!defined($opt_a));
$opt_f=0 if (!defined($opt_f));

die "Output file missing: JPSAPPEND [-c] [-d #] [-a] -o outputfile inputfile(s)" if (!defined($opt_o));

$outputfile=$opt_o;
($indexname,$path,$suffix)=fileparse($opt_o);
$indexfile= $path . "." . $indexname . $suffix . ".idx";

# Open output file

if ($opt_a == 0) {
  # open file for writing, checking for overwriting first
  if ( ( -e $outputfile ) &&  ( $opt_f == 0 ) ) {
    die "Error: $opt_o already exists, use -f to force overwrite\n";
  }
  # Open for writing only
  open(OUTFILE, "> $outputfile")  or die "can't open outputfile $outputfile: $!";
  binmode(OUTFILE);
  undef $/;
  # open index file
  open(IDXFILE, "> $indexfile")  or die "can't open indexfile $indexfile: $!";
  $endbyte=0;
  # set $numheader to 0 to copy the header of the first file 
  $numheader=0;
} else {
  # open file for appending, checking first if it exists
  if ( !( -e $outputfile ) ) {
    if ( $opt_f == 0 )  {
       die "Error: $outputfile does not exist, use -f to force file creation\n";
    } else {
      # set $numheader to 0 to copy the header of the first file 
      $numheader=0;
      $endbyte=0;
    }
  } else {
    # set $numheader to 1 to skip copying the header  
    $numheader=1;
    $endbyte=(-s $outputfile);
  }
  # Open for appending (create if neccessary)
  open(OUTFILE, ">> $outputfile")  or die "can't open outputfile $outputfile: $!";
  binmode(OUTFILE);
  undef $/;
  # open index file
  open(IDXFILE, ">> $indexfile")  or die "can't open indexfile $indexfile: $!";
}

# Expand file names

@jpsfiles=();
foreach $file ( @ARGV ) {
  # print "$file\n";
  @exp=glob($file);
  @exp=sort(@exp);
  push @jpsfiles,@exp;
}


$totalbytes=0;
$numfiles=0;
$motime=0;

foreach $file (@jpsfiles)  {

  open(FILE, "< $file")  or die "can't open $file: $!";
  binmode(FILE);
  undef $/;
  $buffer=<FILE>;
  close(FILE)  or die "can't close $file: $!";
  $size=length($buffer);
  $start=0;
  $end=$size;

  if ( $opt_c > 0 ) {

    # parse the first lines of the file to determine the boundary
    # of the header (if $opt_c)

    $ptr=0;
    $ptr=NextJPSMessage($ptr);
    LOOP: while ( $ptr < $end ) {  
      print "$id $length    $ptr0 --> $ptr \n" if ($opt_d > 2);
      SWITCH: {
        if ($id =~ /RD/ ) {
          last SWITCH;
        }
        if ($id =~ /~~/ ) {
          last LOOP;
          last SWITCH;
        }
        if ($id =~ /JP/ ) {
          # File identifier
          last SWITCH;
        }
      }
      $ptr=NextJPSMessage($ptr);
    }

    # skip the header, except for the first file

    if ( $numheader == 0 ) {
      $numheader++;  
    } else {    
      $start=$ptr0;
      $size=$end-$ptr0;
    }
  }

  $totalbytes=$totalbytes+$size;
  $skipped=$end-$size;
  $numfiles++;

  print "JPS file $file ($end bytes) --> copied $size bytes, skipped $skipped \n" if ($opt_d > 0);

  $startbyte=$endbyte+1;
  $endbyte=$endbyte+$size;
  $mtime = (stat($file))[9];
  $motime=$mtime if ($mtime > $motime);
  $filename = basename($file, "" );

  print IDXFILE "$filename $startbyte $endbyte $size $end $mtime\n";

  print OUTFILE substr($buffer,$start,$size);

}

print "JPS output file $outputfile ($totalbytes bytes), created from $numfiles files\n" if ($opt_d > 0);

close(OUTFILE)  or die "can't close $outputfile: $!";
close(IDXFILE)  or die "can't close $indexfile: $!";

# Set the modification time to the latest of the input files (add one second to be safe)

$now=time;
$motime++;
utime($now,$motime,$outputfile,$indexfile) || die "Can't set the modification time on $outputfile";

exit;

sub NextJPSMessage{

  # Get the next (standard) JPS message from the JPS file
  # Syntax:
  #          $prt=NextJpsMessage($ptr);
  #
  # The ID, length and message contents are returned in the variables
  # $id, $length and $message.

  my ($ptr) = @_;

  # Skip delimiters and non-standard messages

  $ptr=SkipDelimiters($ptr);

  if ( $ptr+5 > $end ) { return $ptr+5;}

  $tag=substr( $buffer, $ptr , 5);
  if ($tag =~ /([0-~][0-~])([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])/ ) {
    $id=$1;
    $length=hex($2);
  } else {
    #out of sync, re-synchronize
    print "WARNING: OUT OF SYNC\n";
    $ptr0=$ptr;
    while ($tag !~ /([0-~][0-~])([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])/ ) {
      $ptr++;
      $tag=substr( $buffer, $ptr , 5);
      last if ( $ptr >= $end );
    }
    #check if next occurence is a tag as well
    #SOME MORE CODE NEEDED HERE
    # print the bad chunk for checking purposes
    $badstring0=substr( $buffer, $ptr0 - 4 , 4 );
    $badstring=substr( $buffer, $ptr0 , $ptr-$ptr0 );
    print "Malformed chunk $ptr0...$ptr-1  $badstring0 -> $badstring \n";
    # decode the tag
    if ($tag =~ /([0-~][0-~])([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])/ ) {
      $id=$1;
      $length=hex($2);
    }
  }
  # $message=substr( $buffer, $ptr+5 , $length);
  $ptr0 = $ptr;
  $ptr = $ptr + $length + 5;

  return $ptr;

}

sub SkipDelimiters{

  # Skip delimiters and non-standard messages
  # Syntax:
  #          $prt=SkipDelimeters($ptr);
  #

  my ($ptr) = @_;

  while ( $ptr < $end && substr($buffer, $ptr , 1) =~ /[\r\n]/ ) {
    # Skip <CR> and <LF>
    while ( $ptr < $end && substr($buffer, $ptr , 1) =~ /[\r\n]/ ) {
      $ptr++;
    }
    # Skip non-standard messages (Starting with ! thru /)
    if ( $ptr < $end && substr($buffer, $ptr , 1) =~ /[!-\/]/ ) {
      # $prt0=$ptr;
      while ( $ptr < $end && substr($buffer, $ptr , 1) !~ /[\r\n]/ ) {
        $ptr++;
      }
      print "Skip non-standard message from $ptr0 - $ptr\n";
    }
  }

  return $ptr;

}

sub checksum{

  my ($buf)=@_;
  my $cs="\0";

  print "$buf\n";
  $cs2=chop($buf);
  while ( $buf =~ /(.)/gs ) {
    #print "$cs $1 \n";
    $cs = (( "$cs" << 2) | ( "$cs" >> 6));
    $cs = "$cs" ^ "$1" ;
  }
  $cs = (( "$cs" << 2) | ( "$cs" >> 6));
  print "error checksum $cs <=> $cs2 \n" if ("$cs" != "$cs2");

  return;
}

sub sec2hms{

  my ($sec)=@_;

  $sec=$sec % 86400;  
  my $hour=int($sec/3600);
  my $min=int($sec/60)-$hour*60;
  $sec=$sec-$hour*3600-$min*60;

  my $string=sprintf("%2d:%02d:%02d",$hour,$min,$sec);

  return $string;

}

