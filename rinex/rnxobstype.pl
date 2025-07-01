#!/usr/bin/perl -w
#
# rnxobstype
# ----------
# This script translates rinex version 2 and 3 observations types..
#
# For help:
#     rnxobstype -?
#
# Created:   9 September 2011 by Hans van der Marel
# Modified: 25 June 2025 by Hans van der Marel
#              - observation types from command line and stdin
#              - added help and improved output
#              - added Apache version 2 license
#           29 June 2025 by Hans van der Marel
#               - few minor corrections
#               - released to github
#
# Copyright 2011-2025 Hans van der Marel, Delft University of Technology.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use Getopt::Long;
use File::Basename;
use lib dirname (__FILE__);
use vars qw( $VERSION );

use strict;
use warnings;

require "librnxio.pl";
require "librnxsys.pl";

$VERSION=20250625;

# Input and output file handles

my $fherr = *STDERR;
my $fhin=*STDIN;
binmode($fhin);

# Check options

Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
my %Config=();
my $Result = GetOptions( \%Config,
                      qw(
                        help|?|h
                        cfgfile|c=s
                        receiverclass|x=s
                        versout|r=s
                        verbose|v+
                      ) );
$Config{help} = 1 if ( ! $Result  );

if( $Config{help} )
{
    Syntax();
    exit();
}

 my $receiverclass="DEFAULT";
 if ( exists($Config{receiverclass}) ) {
   $receiverclass=$Config{receiverclass};
}

my $versin=2.11;
my $versout=3.04;
if ( exists($Config{versout}) ) {
  $versout=$Config{versout};
} 

my $verbose=0;
if ( exists($Config{verbose}) ) {
  $verbose=$Config{verbose};
} 

# Get input observation types 

my $mixedfile="M";
my ($receivertype,$obsid3in,$obsid2in);

my $hadobstype2=0;
my $hadobstype3=0;
if ( scalar(@ARGV) > 0 ) {
   # RINEX version 2 observation types can be input from the command line
   $obsid2in = [ @ARGV ];
   $hadobstype2=1;
} else {
   # Read observation types from STDIN (formatted as RINEX OBS TYPES records)
   my @header=();
   while (<$fhin>) {
      s/\R\z//; # chomp();
      push @header,$_;
      last if ( eof($fhin) || uc(substr($_,60)) =~ /^END OF HEADER/ );
   }
   ($receivertype,$obsid3in,$obsid2in) = ScanRnxHdr(\@header);
   if ( scalar(@{$obsid2in}) > 0 ) {
     $hadobstype2=1;
   }
   if ( scalar(keys(%{$obsid3in})) > 0 ) {
     $hadobstype3=1;
   }
   if (defined($receivertype) && $receivertype =~ /^\S+/ && ! exists($Config{receiverclass}) ) {
      $receiverclass = $receivertype;
   }
}

# Allowable signal types for the selected receiver(class)

my ($signaltypes,$selectedrcvrtype)=signaldef($receiverclass);

print $fherr ("\nReceiver type (if available): ", $receivertype, "\n" ); 
print $fherr (  "Receiver class:               ", $receiverclass, "\n" ); 
print $fherr (  "Selected receiver type/class: ", $selectedrcvrtype, "\n\n" ); 
print $fherr (  "Signal type definitions for ", $selectedrcvrtype, "\n\n"); 
prtsignaldef($fherr,$signaltypes);


# Conversion table(s) between RINEX version 2 and 3 observation type for all allowable signals

my ($cnvtable2to3,$cnvtable3to2)=obstypedef($signaltypes);

if ( $verbose > 1 ) {
   print $fherr ("\nConversion table for RINEX version 2 to 3 for all allowable signals\n\n"); 
   prttypedef($fherr,$cnvtable2to3);
   print $fherr ("\nConversion table for RINEX version 3 to 2 for all allowable signals\n\n"); 
   prttypedef($fherr,$cnvtable3to2);
}

# Check that we have observation types as input and determine direction

if ( ! ( $hadobstype2 || $hadobstype3 ) ) {
   print $fherr "\nNo RINEX observation types found on STDIN or in the arguments, done.\n";
   exit;
} elsif ( $hadobstype2 && $hadobstype3 ) {
   print $fherr "\nBoth RINEX version 2 and 3 observation types found, disambiguate before proceeding.\n";
   exit;
}

if ( $hadobstype2 ) {

    # RINEX version 3 observation types for the available/selected RINEX 2 observation types 

    my ($obsid3,$colidx)=obstype2to3($mixedfile,$obsid2in,$cnvtable2to3);

    if ( $verbose > 0 ) {
       print $fherr ("\nRINEX version 2 observation types (input)\n"); 
       prtobstype2($fherr,$obsid2in);
       print $fherr ("\nRINEX version 3 observation types (output from obstype2to3)\n"); 
       prtobstype3($fherr,$obsid3);
    }
    if ( $verbose > 1 ) {
       print $fherr ("\nRinex 2->3 column reordering (column number in rinex2)\n\n"); 
       prtobsidx($fherr,$colidx);
    }

    my @cnvtable23=fmtcnvtable($obsid2in,$obsid3,$colidx,$versin,$versout);
    print $fherr "\n";
    for my $line (@cnvtable23) {
        print $fherr $line."\n";
    }


    # Inverse operation on the ouput of the previous step

    my ($obsid2new,$colidx2)=obstype3to2($mixedfile,$obsid3,$cnvtable3to2);

    if ( $verbose > 1 ) {
       print $fherr ("\nRINEX version 3 observation types (from previous step)\n"); 
       prtobstype3($fherr,$obsid3);
       print $fherr ("\nRINEX version 2 observation types (output from obstype3to2)\n"); 
       prtobstype2($fherr,$obsid2new);
       print $fherr ("\nRINEX version 2 observation types (original input)\n"); 
       prtobstype2($fherr,$obsid2in);
       print $fherr ("\nRinex 2->3 column reordering (column number in rinex2)\n\n"); 
       prtobsidx($fherr,$colidx2);
       $colidx=invobsidx($colidx2);
       print $fherr ("\nRinex 3->2 column reordering (column number in rinex3)\n\n"); 
       prtobsidx($fherr,$colidx);
    }

    my @cnvtable32=fmtcnvtable($obsid2new,$obsid3,$colidx2,$versout,$versin);
    print $fherr "\n";
    for my $line (@cnvtable32) {
       print $fherr $line."\n";
    }

}

if ( $hadobstype3 ) {

    # RINEX version 3 observation types for the available/selected RINEX 2 observation types 

    my ($obsid2,$colidx2)=obstype3to2($mixedfile,$obsid3in,$cnvtable3to2);

    if ( $verbose > 0 ) {
       print $fherr ("\nRINEX version 3 observation types (input)\n"); 
       prtobstype3($fherr,$obsid3in);
       print $fherr ("\nRINEX version 2 observation types (output from obstype3to2)\n"); 
       prtobstype2($fherr,$obsid2);
    }
    if ( $verbose > 1 ) {
       print $fherr ("\nRinex 2->3 column reordering (column number in rinex2)\n\n"); 
       prtobsidx($fherr,$colidx2);
       my $colidx=invobsidx($colidx2);
       print $fherr ("\nRinex 3->2 column reordering (column number in rinex3)\n\n"); 
       prtobsidx($fherr,$colidx);
    }

    my @cnvtable32=fmtcnvtable($obsid2,$obsid3in,$colidx2,$versout,$versin);
    print $fherr "\n";
    for my $line (@cnvtable32) {
       print $fherr $line."\n";
    }

    # Inverse operation on the ouput of the previous step

    my ($obsid3new,$colidx)=obstype2to3($mixedfile,$obsid2,$cnvtable2to3);

    if ( $verbose > 1 ) {
       print $fherr ("\nRINEX version 2 observation types (from previous step)\n"); 
       prtobstype2($fherr,$obsid2);
       print $fherr ("\nRINEX version 3 observation types (output from obstype2to3)\n"); 
       prtobstype3($fherr,$obsid3new);
       print $fherr ("\nRINEX version 3 observation types (original input)\n"); 
       prtobstype3($fherr,$obsid3in);
       print $fherr ("\nRinex 2->3 column reordering (column number in rinex2)\n\n"); 
       prtobsidx($fherr,$colidx);
    }

    my @cnvtable23=fmtcnvtable($obsid2,$obsid3new,$colidx,$versin,$versout);
    print $fherr "\n";
    for my $line (@cnvtable23) {
        print $fherr $line."\n";
    }

}

sub Syntax{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# ); $Script =~ s#\.pl$##;
    my $Line = "-" x length( $Script );
    print STDERR << "EOT";
$Script                                            (Version: $VERSION)
$Line
Translate RINEX version 2 to version 3 observation types and vice versa.
Syntax: 

    $Script -? 
    $Script [-options] RINEX2_OBSTYPE [[ RINEX2_OBSTYPE ]] 
    $Script [-options] < file_with_obstypes  
    cat file_with_obstypes | $Script [-options] 
    
If no RINEX version 2 observation types are given on the command line, the script reads 
from the standard input and translates any RINEX version 2 or 3 observation TYPES records
it finds. Options are:

    -?|h|help..........This help
    -r #[.##]..........RINEX output version, default is to output the same 
                       version as the input file
    -x receiverclass...Receiver class (overrides receiver type) for conversion:
                          GPS12    Only include GPS L1 and L2 observations
                          GPS125   Only include GPS L1, L2 and L5 observations
                          GRES125  Only include L1/L2/L5 for GPS/GLO/GAL/SBAS.
    -v                 Verbose (increase verbosity level)

Examples:

    $Script C1 L1 L2 P2 S1 S2
    $Script -v C1 L1 L2 P2 S1 S2
    $Script -x GRES125 C1 L1 L2 P2 S1 S2

    grep TYPES data/MX5C1340.25O | $Script -v -x GRES125

    grep TYPES data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | $Script -x GRES125

(c) 2011-2025 by Hans van der Marel, Delft University of Technology.
EOT

# Unimplemented options (as of yet):
#    -c cfgfile.........Name of optional configuration file, overrides the standard 
#                       rinex 2/3 conversion tables hardwired in the program

}

1;


