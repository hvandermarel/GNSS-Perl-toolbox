#!/usr/bin/perl -w 
#
# DATAPPEND 2002 (c) TU Delft, Hans van der Marel
#
# Append Trimble DAT files 
#
# Usage :  DATAPPEND [-d #] [-a] [-f] [-z] -o outputfile inputfiles
#
# Options: -d #           debugging level
#          -o outputfile  output file name
#          -z             optionally decompress files before merging
#          -a             append input files to "outputfile" 
#          -f             force overwrite if "outputfile" already
#                         exists, or force file creation in case
#                         of append mode if "outputfile" does not exist
#
# .<outputfile>.idx will be created/updated to hold information
# to undo the copy/append operation later.

use Getopt::Std;
use File::Basename;

# Get command line options

getopts('o:d:afz');

$opt_d=0 if (!defined($opt_d));
$opt_a=0 if (!defined($opt_a));
$opt_f=0 if (!defined($opt_f));
$opt_z=0 if (!defined($opt_z));

die "Output file missing: DATAPPEND [-d #] [-a] [-z] -o outputfile inputfile(s)" if (!defined($opt_o));

$outputfile=$opt_o;
($indexname,$path,$suffix)=fileparse($opt_o,"(\.Z|\.gz)");
if ($suffix =~ /(\.Z|\.gz)$/i) {
  $suffix = ".idx" ;
} else {
  $suffix = $suffix . ".idx" ;
}
$indexfile= $path . "." . $indexname . $suffix;
print "$indexfile\n" if ( $opt_d);

# Expand input file names

@datfiles=();
foreach $file ( @ARGV ) {
  # print "$file\n";
  @exp=glob($file);
  @exp=sort(@exp);
  @exp= grep(!/$outputfile/, @exp);
  push @datfiles,@exp;
}

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

# Concatenate the input files 

$totalbytes=0;
$numfiles=0;
$motime=0;

foreach $file (@datfiles)  {

  $xfile=$file;
  $xfile="gzip -d -S .zip -c $file |" if ( $opt_z && $file =~ /(\.Z|.gz|.zip)$/i );
  print "$xfile\n" if ($opt_d > 1);

  open(FILE, "$xfile")  || die "can't open $file: $!";
  binmode(FILE);
  undef $/;
  $buffer=<FILE>;
  close(FILE)  or die "can't close $file: $!";
  $size=length($buffer);

  $totalbytes=$totalbytes+$size;
  $numfiles++;

  print "DAT file $file ($size bytes)\n" if ($opt_d > 0);

  $startbyte=$endbyte+1;
  $endbyte=$endbyte+$size;
  $mtime = (stat($file))[9];
  $motime=$mtime if ($mtime > $motime);
  $filename = basename($file, "" );
  $filename = basename($filename, "/\.Z|\.gz/i" ) if ($opt_z);
  print IDXFILE "$filename $startbyte $endbyte $size $mtime\n";

  print OUTFILE $buffer;

}

print "DAT output file $outputfile ($totalbytes bytes), created from $numfiles files\n" if ($opt_d > 0);

close(OUTFILE)  or die "can't close $outputfile: $!";
close(IDXFILE)  or die "can't close $indexfile: $!";

# Set the modification time to the latest of the input files (add a one second increment to be safe)

$now=time;
$motime++;
utime($now,$motime,$outputfile,$indexfile) || die "Can't set the modification time on $outputfile";

exit;


