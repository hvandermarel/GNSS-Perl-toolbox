#!/usr/bin/perl -w
#
# rnxobssort
# ----------
# This script sorts and/or removes rinex version 2 and 3 observations types..
#
# For help:
#     rnxobssort -?
#
# Created:  27 June 2025 by Hans van der Marel
# Modified: 29 June 2025 by Hans van der Marel
#              - added remove functionality
#              - released to github
#
# Copyright 2025 Hans van der Marel, Delft University of Technology.
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

use librnxio qw( ScanRnxHdr );
use librnxsys;

use strict;
use warnings;

$VERSION=20250602;

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
                        sort|by=s
                        remove|rm=s
                        verbose|v
                      ) );
$Config{help} = 1 if ( ! $Result  );

if( $Config{help} )
{
    Syntax();
    exit();
}

my $verbose=0;
if ( exists($Config{verbose}) ) {
  $verbose=1;
} 
if ( ! exists($Config{sort}) ) {
  $Config{sort}="asis";
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
   $receivertype="";
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
}


if ( $hadobstype3 ) {

   print $fherr ("\nInput RINEX 3 observation types:\n\n"); 
   prtobstype3($fherr,$obsid3in);

   my $obsid3=$obsid3in;
   my $colidx={};
   foreach my $by ( split(/,/,$Config{sort}) ) {
      ($obsid3,$colidx) = rnxobstype3sort( $obsid3,$colidx , $by);
      print $fherr ("\nRINEX 3 observation types sorted using ** -by $by **:\n\n"); 
      prtobstype3($fherr,$obsid3);
      prtobsidx($fherr,$colidx);
   }
   
   #my $colidx = iniobsidx3($obsid3);
   #prtobsidx($fherr,$colidx);

   if ( exists($Config{remove}) ) {
 
      my $rmtypes={};
      ($obsid3, $colidx, $rmtypes) = rnxobstype3rm($obsid3, $colidx, $Config{remove});

      print $fherr ("\nRINEX 3 observation types after applying -rm $Config{remove}:\n\n"); 
      prtobstype3($fherr,$obsid3);
      prtobsidx($fherr,$colidx);

      print $fherr ("\nRemoved RINEX 3 using -rm $Config{remove}:\n\n"); 
      prtobstype3($fherr,$rmtypes);
   }
   
}

if ( $hadobstype2 ) {

   print $fherr ("\nInput RINEX 2 observation types:\n\n"); 
   prtobstype2($fherr,$obsid2in);

   # my $colidx2 = [];
   # @$colidx2 = 0 .. $#{$obsid2in};
   # print "[ "; foreach my $tmp ( @$colidx2) { print $tmp ." "; }; print "]\n";
   # if ( $Config{remove} ) {
     # my @obsid2in2 = grep {!/$Config{remove}/} @$obsid2in;  
     # prtobstype2($fherr,\@obsid2in2);
     # my @indices = grep { $obsid2in->[$_] !~ /$Config{remove}/ } 0..$#{$obsid2in}; 
     # print "[ "; foreach my $tmp ( @indices) { print $tmp ." "; }; print "]\n";
     # my @obsid2in3 = @$obsid2in[ @indices ]; 
     # my @colidx3 = @$colidx2[ @indices ]; 
     # prtobstype2($fherr,\@obsid2in3);
     # print "[ "; foreach my $tmp ( @colidx3) { print $tmp ." "; }; print "]\n";
   # }

   my $obsid2=$obsid2in;
   my $colidx2=[];

   foreach my $by ( split(/,/,$Config{sort}) ) {
      ($obsid2,$colidx2) = rnxobstype2sort( $obsid2,$colidx2 , $by);
      print $fherr ("\nRINEX 2 observation types sorted using ** -by $by **:\n\n"); 
      prtobstype2($fherr,$obsid2);
      print "[ "; foreach my $tmp ( @$colidx2) { print $tmp ." "; }; print "]\n";
   }
   
   print $fherr ("\nObservation index hash constructed from RINEX 2 permutation array:\n\n"); 
   #my $colidx = iniobsidx2(obsid2in,[ 'G', 'R', 'E', 'S']);
   #foreach my $sys ( keys %$colidx ) {
   my $colidx={};
   foreach my $sys ( split(//,'GRES') ) {
       @{$colidx->{$sys}} = @$colidx2 ;
   }
   prtobsidx($fherr,$colidx);

   if ( exists($Config{remove}) ) {

      my $rmtypes={};
      ($obsid2, $colidx, $rmtypes) = rnxobstype2rm($obsid2, $colidx, $Config{remove});

      print $fherr ("\nRINEX 2 observation types after applying -rm $Config{remove}:\n\n"); 
      prtobstype2($fherr,$obsid2);
      prtobsidx($fherr,$colidx);

      print $fherr ("\nRemoved RINEX 2 using -rm $Config{remove}:\n\n"); 
      prtobstype3($fherr,$rmtypes);
   }

}

sub Syntax{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# ); $Script =~ s#\.pl$##;
    my $Line = "-" x length( $Script );
    print STDERR << "EOT";
$Script                                            (Version: $VERSION)
$Line
Sort RINEX version 2 to version 3 observation types.
Syntax: 

    $Script -? 
    $Script [-options] RINEX2_OBSTYPE [[ RINEX2_OBSTYPE ]] 
    $Script [-options] < file_with_obstypes  
    cat file_with_obstypes | $Script [-options] 
    
If no RINEX version 2 observation types are given on the command line, the script reads 
from the standard input and translates any RINEX version 2 or 3 observation TYPES records
it finds. Options are:

    -?|h|help..........This help
    -by sort[[,sort]]  Order for the observation types, with
                         fr[eq]  -  keep .signals (1C, .2W, etc.) together
                         ty[pe]  -  keep types (C, L, S) together
                         se[pt]  -  preferred order for Septentrio receivers
                         as[is]  -  keep as is (no sorting)
    -rm spec[[,spec]]  Remove observation types (spec = [sys:]regex )
    -v                 Verbose (increase verbosity level)

For RINEX version 3 the result of the sort options is 

    -by freq|sept  ->  C1C L1C S1C C2W L2W ...             (keep .1C, .2W, etc. together)
    -by type       ->  C1C C1W ... L1C L2W ... S1C S2W ... (keep types together)

For RINEX version 2 the result of the sort options is always the same for the
first five observations "C1 L1 L2 P2 C2", but differs thereafter

    -by freq  ->  C1 L1 L2 P2 C2 S1 S2 C5 L5 S5 C7 L7 S7 ...
    -by type  ->  C1 L1 L2 P2 C2 C5 C7 ... L5 L7 ... S1 S2 S5 S7 ...
    -by sept  ->  C1 L1 L2 P2 C2 C5 L5 C7 L7 ... S1 S2 S5 S7 ...

The option "sept" is a mix of "freq" and "type"; basically it is the same as "freq", but 
puts all signal strength types at the end like in "type".

The option "-rm spec[[,spec]]" specifies the observation types to remove. This is
a comma separated list with "spec" a Perl regular expession "regex" operating on all
systems or a key value pair "sys:regex" with a Perl regular expression operating on a
designated system sys (G, R, E, C, S, J, I). For example "G:2L,E:7,D.." removes all 
GPS "2L' observations (C2L, L2L, D2L, S2L), all Galileo observations on frequency 7, 
and all Doppler observations. 

Examples:

    $Script -by freq C1 C2 L1 L2 P2 S1 S2
    $Script -by sept C1 P2 C2 C5 C7 L1 L2 L5 L7 S1 S2 S5 S7
    $Script -by sept,freq,type C1 P2 C2 C5 C7 L1 L2 L5 L7 S1 S2 S5 S7

    grep TYPES data/MX5C1340.25O | $Script -by type

    grep TYPES data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | $Script -by freq
    grep TYPES data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | $Script -by freq,type,sept

(c) 2025 by Hans van der Marel, Delft University of Technology.
EOT

}

