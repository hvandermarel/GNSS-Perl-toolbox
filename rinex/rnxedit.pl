#!/usr/bin/perl -w
#
# rnxedit
# -------
# This script edits, filters and converts RINEX observation files.
#
# For help:
#     rnxedit -?
#
# Created:   9 September 2011 by Hans van der Marel
# Modified: 11 February 2012 by Hans van der Marel
#              - Public version for testing
#           23 August 2019 by Hans van der Marel
#              - renamed libraries
#              - new version of librnxio
#              - small code reorganisations
#           26 June 2024 by Hans van der Marel
#              - chomp replaced by regex  =~s /\R\z//; in librnxio
#                to be more resilient to files from other platforms
#           16 June 2025 by Hans van der Marel
#              - renamed script to rnxedit
#              - added functionality to edit the rinex header
#              - changed the default for output rinex version (default
#                for output version is the same input version; by 
#                default no version conversion)
#           20 June 2025 by Hans van der Marel
#              - options for filtering (window, decimation and system)
#              - many major, minor and cosmetic changes
#              - moved some functions to librnxsys.pl
#              - initial release on github as v0.9-alpha
#           22 June 2025 by Hans van der Marel
#              - checked with strict pragma and filled in missing declararions
#              - added editing of receiver type, number and firmware version
#              - added editing of approximate position
#              - added Apache 2.0 license notice
#              - more elaborate check on ouput rinex version
#              - strict is now default, option hidden from users
#              - option -s is now used as shortcut for -satsys
#              - added default record for mandatory SYS / PHASE SHIFT in v3.01-3.05
#              - idem for mandatory GLONASS COD/PHS/BIS in v3.02-3.05
#              - idem for mandatory GLONASS SLOT / FRQ in v3.02 onwards, using 
#                newly added functions in librnxsys.pl with glonass.cfg file
#           25 June 2025 by Hans van der Marel
#              - cfgfile option hidden from user as it is not yet implemented
#              - updated analyze function 
#              - filenames on the command line is now working
#           29 June 2025 by Hans van der Marel
#              - added observation type sorting and removal to filtering
#           30 June 2025 by Hans van der Marel
#              - added sorting on satellite id (using satsys option)
#              - beta0 release on github
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

use vars qw( $VERSION );
use Getopt::Long;
use File::Basename;
use Time::Local;
use lib dirname (__FILE__);

use warnings;
use strict;

require "librnxio.pl";
require "librnxsys.pl";

$VERSION = 20250630;

my $fherr=*STDERR;

# Process the options

Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
my %Config=();
my $Result = GetOptions( \%Config,
                      qw(
                        help|?|h
                        donothing|n
                        verbose|v+
                        version|r=s
                        outputdir|o=s
                        cfgfile|c=s
                        receiverclass|x=s
                        markername|mo=s
                        markernumber|mn=s
                        markertype|mt=s
                        antennatype|at=s
                        antennanumber|an=s
                        antennadelta|ad=s
                        antennaheight|ah=s
                        positionxyz|ap=s
                        receivertype|rt=s
                        receivernumber|rn=s
                        receiverfw|rv=s
                        agency|oa=s
                        operator|op=s
                        runby|or=s
                        begin|b=s
                        end|e=s
                        int|i=s
                        satsys|s=s
                        sort|by=s
                        remove|rm=s
                      ) );
$Config{help} = 1 if ( ! $Result  );

if( $Config{help} )
{
    Syntax();
    exit();
}

my $versoutopt="cc";
if ( exists($Config{version}) ) {
   $versoutopt=$Config{version};
}

my $verbose=0;
if ( exists($Config{verbose}) ) {
   $verbose=$Config{verbose};
} else {
   $Config{verbose}=$verbose;
}

$Config{strict}=1;            # Default is strict (no option)

# Get all the filenames

if ( scalar @ARGV ) {
  # Process the files on the command line
  # The original file is renamed to <file>.orig 
  my @files=();
  foreach my $file ( @ARGV ) {
    # print STDERR "$file\n";
    my @exp=glob($file);
    @exp=sort(@exp);
    push @files,@exp;
  }
  # Parse the rinex file
  foreach my $inputfile ( @files ) {
    if ( exists($Config{donothing}) ) {
       print $fherr "\n\n*** Analyzing $inputfile ***\n\n";
       analyzernx($inputfile,$versoutopt);
    } else {
       # set temporary output filename
       my $outputfile = fileparse($inputfile);
       my $tmpoutputfile = "$outputfile.tmp.$$";
       if ( exists($Config{outputdir}) ) {
          # check if $Config{outputdir} is directory and exists
          if ( -d $Config{outputdir} ) {
             # include $Config{outputdir} in output file name
             $tmpoutputfile = $Config{outputdir}."/".$tmpoutputfile;
             $outputfile = $Config{outputdir}."/".$outputfile;
          } else {
             die "Output directory $Config{outputdir} does not exist, abort...\n";
          }
       }
       print STDOUT "Edit $inputfile -> $outputfile";
       convertrnx($inputfile,$tmpoutputfile,$versoutopt) || warn "Error in convertrnx.";
#      On success, rename output and input file
       if ( -e $outputfile ) {
          print STDOUT ", renamed $outputfile to $outputfile.orig";
          rename($outputfile,$outputfile.".orig");
       }
       rename($tmpoutputfile,$outputfile);
       print STDOUT ", done\n";
    }
  }
} else {
   # Read from standard input and write to standard output
   my $versout=$versoutopt;
   if ( exists($Config{donothing}) ) {
      analyzernx("-",$versoutopt);
   } else {
      convertrnx("-","-",$versoutopt);
   }
}

exit;


sub Syntax{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# ); $Script =~ s#\.pl$##;
    my $Line = "-" x length( $Script );
    print STDERR << "EOT";
$Script                                            (Version: $VERSION)
$Line
Edit, filter and convert RINEX observation files.
Syntax: 

    $Script -? 
    $Script [-options] RINEX_observation_file(s) 
    $Script [-options] < inputfile > outputfile  
    cat inputfile | $Script [-options] > outputfile 
    
If no RINEX observation file(s) are given on the command line, the script reads 
from the standard input and writes to standard output. 

Header editing options:

    -mo markername.....String with marker name
    -mn markernumber...String with marker number
    -mt markertype.....String with marker type (only relevant for rinex-3) 
    -at antennatype....String with antenna type and radome
    -an antennanumber..String with antenna number
    -ad antennadelta...Comma separated values for antenna delta U,E,N [m]
    -ah antennaheight..Value for antenna height [m] (eccentricity unchanged)
    -ap positionxyz... Comma separated values for approximate position X,Y,Z [m]
    -rt receivertype...String with receiver type
    -rn receivernumber.String with receiver number
    -rv receiverfw.....String with receiver firmware version
    -oa agency.........String with observer agency
    -op operator.......String with observer name
    -or runby..........String with agency or person running this program

Filtering options:

    -b starttime.......Observation start time [yyyy-mm-dd[ T]]hh:mm[:ss]
    -e endtime.........Observation end time [yyyy-mm-dd[ T]]hh:mm[:ss]
    -i interval........Observation interval [sec] 
    -s satsys..........Satellite systems to include [GRECJS]
    -by sort[[,sort]]  Order for the observation types, with
                         fr[eq]  -  keep .signals (1C, .2W, etc.) together
                         ty[pe]  -  keep types (C, L, S) together
                         se[pt]  -  preferred order for Septentrio receivers
                         as[is]  -  keep as is (no sorting)
    -rm spec[[,spec]]  Remove observation types (spec = [sys:]regex )

Rinex version 2/3+ conversion options:

    -r #[.##]..........RINEX output version, default is to output the same 
                       version as the input file
    -x receiverclass...Receiver class (overrides receiver type) for conversion:
                          GPS12    Only include GPS L1 and L2 observations
                          GPS125   Only include GPS L1, L2 and L5 observations
                          GRES125  Only include L1/L2/L5 for GPS/GLO/GAL/SBAS.
    -n.................Do nothing. Only analyze the headers and give feedback
                       on the translated observation types; useful to check if you 
                       agree with the conversion of observation types before 
                       proceeding with actual conversion!

General options:

    -?|h|help..........This help
    -o outputdir.......Output directory, if not given, any filenames specified
                       on the commandline will be overwritten (the originals
                       will be saved with an extra extention .orig)
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

    cat MX5C1340.25O | $Script -mo ZANDMOTOR -mn ZAND -ah 1.023 > zand1340.25o

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | $Script -mo ZANDMOTOR -mn ZAND \
       -ah 1.023 -b 7:30 -e 8:20 -i 30 -s GRE > ZAND00NLD_R_20251340730_50M_30S_MO.rnx 

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | $Script -mo ZANDMOTOR -mn ZAND \
       -ah 1.023 -r 2 -x GRES125 -s GRS > zand1340.25o

    cat MX5C1340.25O | $Script -mo ZANDMOTOR -mn ZAND -ah 1.023 -r 3 -x GPS12 \
        -b 7:30 -e 8:20 > ZAND00NLD_R_20251340730_50M_10S_MO.rnx

    $Script -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans zand1340.25o

The first and last example are simple RINEX header edits; in the first example
a new file is created and in the last example the existing file is overwritten
(the original is saved with extension .orig). In the second example a RINEX 
version 3 file is edited and filtered. The third and fourth example includes
conversion to RINEX version 2.11 and version 3.00 files respectively, using
different translation profiles (GRES125 and GPS12).

(c) 2011-2025 by Hans van der Marel, Delft University of Technology.
EOT

# Unimplemented options (as of yet):
#    -c cfgfile.........Name of optional configuration file, overrides the standard 
#                       rinex 2/3 conversion tables hardwired in the program

}

sub analyzernx{

  # Analyze RINEX file and the conversion process
  # Usuage
  #
  #   analyzernx($inputfile,$versout);
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($inputfile,$versoutopt)=@_;

  # Open the RINEX observation file 

  my ($fhin);
  if ($inputfile ne "-" ) {
    open($fhin, "< $inputfile") or die "can't open $inputfile: $!";
  } else {
    # read from STDIN 
    $fhin=*STDIN;
  }
  binmode($fhin);

  # Read the RINEX ID line, header and after that close the file

  my ($versin,$mixedfile,$idrec)=ReadRnxId($fhin,"O");
  my $rnxheaderin=ReadRnxHdr($fhin);
  close($fhin) or die "can't close $inputfile: $!";

  # Check/analyze version, set ouput version

  my ($versout,$mainversout,$mainversin) = setversout($versin,$versoutopt);

  # Read and analyze the RINEX header (with temporarily increased verbosity)
  
  $verbose++; 
  my ($receivertype,$obsid3,$obsid2)=ScanRnxHdr($rnxheaderin);
  my $rnxheadertmp=$rnxheaderin;
  my $colidx=[];
  if ( $mainversout ne $mainversin ) {
     ($obsid2,$obsid3,$colidx,$rnxheadertmp)=CnvRnxHdr($versin,$versout,$rnxheaderin,$Config{markertype},$mixedfile);
  } else {
     print $fherr "Main input and output version are the same (mainversion=$mainversout),\n";
     print $fherr "input version $versin, output version $versout, no major conversion needed.\n\n";
  }
  $verbose--; 

  # Set filter options and adjust header accordingly
  my ($windowopt,$rnxheadertmp2)=FilterOptions($rnxheadertmp,\%Config);
  if ( $windowopt->{windowing} || $windowopt->{decimate} ) {
     print $fherr "\n\nFiltering is active:\n";
     print $fherr "Time of first obs: ".gmtime($windowopt->{begin})."\n";
     print $fherr "Time of last obs: ".gmtime($windowopt->{end})."\n";
     print $fherr "Windowing: $windowopt->{windowing} \n";
     print $fherr "Decimate: $windowopt->{decimate}\n";
  }

  # Edit the rinex header
  my $rnxheaderout=EdtRnxHdr($rnxheadertmp2);

  # Print the rinex header

  print $fherr "\n\nModified RINEX header:\n\n";
  WriteRnxId($fherr,$versout,"O",$idrec,$Config{runby});
  WriteRnxHdr($fherr,$rnxheaderout);
  
}

sub convertrnx{

  # Convert and edit a single RINEX file
  # Usuage
  #
  #   convertrnx($inputfile,$outputfile,$versout);
  #
  # (c) Hans van der Marel, Delft University of Technology.


  my ($inputfile,$outputfile,$versoutopt)=@_;

  # Open the RINEX observation files for reading and writing
  # --------------------------------------------------------
  
  my ($fhin,$fhout);

  if ($inputfile ne "-" ) {
    open($fhin, "< $inputfile") or die "can't open $inputfile: $!";
  } else {
    # read from STDIN 
    $fhin=*STDIN;
  }
  if ($outputfile ne "-" ) {
    open($fhout, "> $outputfile") or die "can't open $outputfile: $!";
  } else {
    # write to STOUT
    $fhout=*STDOUT;
  }
  
  binmode($fhin);binmode($fhout);

  # Read the RINEX ID line, check/update rinex  version, and insert PGM / RUN BY header
  # -----------------------------------------------------------------------------------

  my ($versin,$mixedfile,$idrec)=ReadRnxId($fhin,"O");
  my ($versout,$mainversout,$mainversin) = setversout($versin,$versoutopt);

  WriteRnxId($fhout,$versout,"O",$idrec,$Config{runby});
  
  # Read, convert and write the RINEX header
  # ----------------------------------------
  
  # Read the RINEX header
  my $rnxheaderin=ReadRnxHdr($fhin);
  my ($receivertype,$obsid3,$obsid2)=ScanRnxHdr($rnxheaderin);
  # Optionally convert the RINEX header to different format
  my $rnxheadertmp=$rnxheaderin;
  my $colidx={};
  my $reorder=0;
  if ( $mainversout ne $mainversin ) {
     #my ($obsid2,$obsid3,$colidx,$rnxheaderout)=CnvRnxHdr($versin,$versout,$rnxheaderin,$Config{markertype},$mixedfile);
     ($obsid2,$obsid3,$colidx,$rnxheadertmp)=CnvRnxHdr($versin,$versout,$rnxheaderin,$Config{markertype},$mixedfile);
     $reorder=1;
  } else {
     #initialize $colidx in case it will be needed later
     if ( $versout > 2.99 ) {
         $colidx=iniobsidx3($obsid3);
     } else {
         $colidx=iniobsidx2($obsid2,'GRES');
     }
  }
  my $obsid2in=[ @$obsid2 ];
  #my $obsid3in={ %$obsid3 };
  my @newcomments=();
  # Optional sorting of observations types 
  if ( exists($Config{sort}) ) {
     if ( $versout > 2.99 ) {
        ($obsid3,$colidx) = rnxobstype3sort( $obsid3,$colidx , $Config{sort});
        push @newcomments, "RINEX 3 observation types sorted using \"-by $Config{sort}\""; 
        if ( $verbose > 0 ) {
           prtobstype3($fherr,$obsid3);
           prtobsidx($fherr,$colidx);
        }
     } else {
        my $indices=[];
        ($obsid2,$indices) = rnxobstype2sort( $obsid2,$indices , $Config{sort});
        push @newcomments, "RINEX 2 observation types sorted using \"-by $Config{sort}\""; 
        foreach my $sys ( keys %$colidx ) {
            @{$colidx->{$sys}} = @{$colidx->{$sys}}[ @$indices ];
        }
        if ( $verbose > 0 ) {
           prtobstype2($fherr,$obsid2);
           print "[ "; foreach my $tmp ( @$indices) { print $fherr $tmp ." "; }; print "]\n";
           prtobsidx($fherr,$colidx);
        }
     }
     $reorder=1;
  }
  # Optional removal of observations types 
  my $rmtypes={};
  if ( exists($Config{remove}) ) {
     if ( $versout > 2.99 ) {
        ($obsid3, $colidx, $rmtypes) = rnxobstype3rm($obsid3, $colidx, $Config{remove});
        if ( $verbose > 0 ) {
           print $fherr ("\nRINEX 3 observation types after applying -rm $Config{remove}:\n\n"); 
           prtobstype3($fherr,$obsid3);
           prtobsidx($fherr,$colidx);
        }
        push @newcomments, "Removed RINEX 3 observation types using \"-rm $Config{remove}\""; 
        foreach my $sys ( sysids($rmtypes) ) {
           push @newcomments, "   $sys => ".join(' ',@{$rmtypes->{$sys}}); 
        }
     } else {
        ($obsid2, $colidx, $rmtypes) = rnxobstype2rm($obsid2, $colidx, $Config{remove});
        if ( $verbose > 0 ) {
           print $fherr ("\nRINEX 2 observation types after applying -rm $Config{remove}:\n\n"); 
           prtobstype2($fherr,$obsid2);
           prtobsidx($fherr,$colidx);
        }
        push @newcomments, "Removed RINEX 2 observation types using \"-rm $Config{remove}\""; 
        foreach my $sys ( sysids($rmtypes) ) {
        push @newcomments, "   $sys => ".join(' ',@{$rmtypes->{$sys}}); 
        }
     }
     $reorder=1;
  }
  if ( exists($Config{sort}) || exists($Config{remove}) ) {
     my @newobstypes;
     if ( $versout > 2.99 ) {
         @newobstypes=fmtobshead3($obsid3);
     } else {
         @newobstypes=fmtobshead2($obsid2);
     } 
     $rnxheadertmp=rnxheadersplice($rnxheadertmp,\@newobstypes);
     @newcomments = map( sprintf("%-60.60s%-20.20s",$_,"COMMENT"),@newcomments);
     splice( @{$rnxheadertmp}, -1, 0, @newcomments);
  }
  # Set window and decimation filter options and adjust header accordingly
  my ($windowopt,$rnxheadertmp2)=FilterOptions($rnxheadertmp,\%Config);
  if ( $verbose > 0 ) {
     print $fherr "Time of first obs: ".gmtime($windowopt->{begin})."\n";
     print $fherr "Time of last obs: ".gmtime($windowopt->{end})."\n";
     print $fherr "Windowing: $windowopt->{windowing} \n";
     print $fherr "Decimate: $windowopt->{decimate}\n";
  }
  # Edit and write the RINEX header
  my $rnxheaderout=EdtRnxHdr($rnxheadertmp2);
  WriteRnxHdr($fhout,$rnxheaderout);
  
  # # remove trailing -99 (blanks) from $colidx <= cannot be done
  #
  # if ( $reorder ) {
  #    foreach my $sys ( keys %$colidx ) {
  #        print $fherr " $sys ==> ".join(' ',@{$colidx->{$sys}})."\n";
  #        foreach  my $tmp ( reverse @{$colidx->{$sys}} ) { 
  #           last if ($tmp != -99);
  #           pop @{$colidx->{$sys}};
  #        }
  #        print $fherr " $sys ==> ".join(' ',@{$colidx->{$sys}})."\n";
  #     }
  # }
  
  # Parse and convert the observation data 
  # --------------------------------------

  my ($epoch,$epoflag,$clkoffset,$nsat);
  my $data=[];
  my $skipped=[];
  my $obsid2upd=[];

  while ( ! eof($fhin) ) {

    # Read rinex data
    if ( $versin < 3.00 ) {
       ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped,$obsid2upd)=ReadRnx2Data($fhin,$obsid2in);
       $obsid2in=$obsid2upd if ( scalar(@$obsid2upd) > 0);
    } else {
       ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped)=ReadRnx3Data($fhin);
    }
    # Process skipped data (usually RINEX format mistakes)
    if (scalar(@{$skipped}) > 0) {
      # Write rinex data, assume it is header data (needs some checking and processing)
      # Process new header data, can possibly contain observation type info
      if ( $versout < 3.00 ) {
         WriteRnx2Data($fhout,"                           ","4","               ",scalar(@{$skipped}),(),$skipped);
      } else {
         WriteRnx3Data($fhout,"                           ","4","               ",scalar(@{$skipped}),$skipped);
      }
    }
    if ( $epoflag == 4) {
      # Process new header data, can possibly contain observation type info
      #       my ($obsid2upd,$obsid3upd,$colidxupd,$dataupd)=CnvRnxHdr($versin,$versout,$data,$Config{markertype},$mixedfile);
      #       $data=$dataupd;
      #       $nsat=scalar(@{$data});
    }

    # Check if epoch is within window (optional) and decimated (optional) to output interval

    my $keep=1;
    my @values=split(" ",$epoch);
    if ( $windowopt->{windowing} && ($epoflag <= 1) ) {
       my $epochtime = timegm($values[5],$values[4],$values[3],$values[2],$values[1]-1,$values[0]);
       if ( ( $epochtime < $windowopt->{begin}-0.05 ) || ( $epochtime > $windowopt->{end}+0.05 ) ) {
          $keep=0;
       }
    }
    if ( $windowopt->{decimate} && ($epoflag <= 1) && $keep && ( abs( $values[5] - sprintf("%.0f",$values[5]/$windowopt->{decimate})*$windowopt->{decimate} ) > 0.5 ) ) {
        $keep=0;
    }

    # Optionally keep only selected systems and sort on satellite id 

    if ( exists($Config{satsys}) && $keep && ( ($epoflag <= 1) || ($epoflag == 6) ) ) {
       # @{$data} = grep { /^[$Config{satsys}]/} @{$data};
       $data=SortRnxData($data,$Config{satsys});
       $nsat=scalar(@{$data});
    }

    # Reorder the columns (in case of different input and output versions)

    if ( $reorder && $keep && ( ($epoflag <= 1) || ($epoflag == 6) ) ) {
      # Have observation data, re-order the fields in $data
      $data=ReorderRnxData($data,$colidx);
      $nsat=scalar(@{$data});
    }

    # Write rinex data
    if ( $versout < 3.00 ) {
       WriteRnx2Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$obsid2,$data) if ($keep);
    } else {
       WriteRnx3Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$data) if ($keep);
    }
  }

  # Close the RINEX observation files
  # ---------------------------------
  
  close($fhin) or die "can't close $inputfile: $!";
  close($fhout) or die "can't close $outputfile: $!";
  
}

sub EdtRnxHdr{

  # Edit the RINEX header 
  # Usuage
  #  
  #    my $rnxheaderout=EdtRnxHd($rnxheaderin);
  #
  # with @rnxheaderin a pointer to an array with RINEX header lines. The
  # configuration information is taken from the global $Config hash with keys
  #
  #   markername|mo=s
  #   markernumber|mn=s
  #   markertype|mt=s
  #   antennatype|at=s
  #   antennanumber|an=s
  #   antennadelta|ad=s
  #   antennaheigt|ah=s
  #   positionxyz|ap=s
  #   receivertype|rt=s
  #   receivernumber|rn=s
  #   receiverfw|rv=s
  #   agency|oa=s
  #   operator|op=s
  #
  # It returns the array with edited RINEX headers as reference.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($rnxheaderin)=@_;
  
  my @rnxheaderout=();

  foreach my $line (@{$rnxheaderin}) {

    my $headid=uc(substr($line,60));

    if ( $headid =~ /^MARKER NAME/ && exists($Config{markername}) ) {
       push @rnxheaderout,sprintf("%-60.60s%-20.20s",$Config{markername},$headid);
    } elsif ( $headid =~ /^MARKER NUMBER/ && exists($Config{markernumber}) ) {
       push @rnxheaderout,sprintf("%-20.20s%-40.40s%-20.20s",$Config{markernumber},substr($line,20,40),$headid);
    } elsif ( $headid =~ /^MARKER TYPE/ && exists($Config{markertype}) ) {
       push @rnxheaderout,sprintf("%-20.20s%-40.40s%-20.20s",$Config{markertype},substr($line,20,40),$headid);
    } elsif ( $headid =~ /^ANT # \/ TYP/ ) { 
       if ( exists($Config{antennanumber}) ) {
            substr($line,0,20)=sprintf("%-20.20s",$Config{antennanumber});
       }
       if ( exists($Config{antennatype}) ) {
            substr($line,20,20)=sprintf("%-20.20s",$Config{antennatype});
       }
       push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),$headid);
    } elsif ( $headid =~ /^ANTENNA: DELTA H\/E\/N/ ) {
       if ( exists($Config{antennadelta}) ) {
            substr($line,0,42)=sprintf("%14.4f%14.4f%14.4f",split(/,/,$Config{antennadelta}));
       }
       if ( exists($Config{antennaheight}) ) {
            substr($line,0,14)=sprintf("%14.4f",$Config{antennaheight});
       }
       push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),$headid);
    } elsif ( $headid =~ /^REC # \/ TYPE \/ VERS/ ) { 
       if ( exists($Config{receivernumber}) ) {
            substr($line,0,20)=sprintf("%-20.20s",$Config{receivernumber});
       }
       if ( exists($Config{receivertype}) ) {
            substr($line,20,20)=sprintf("%-20.20s",$Config{receivertype});
       }
       if ( exists($Config{receiverfw}) ) {
            substr($line,40,20)=sprintf("%-20.20s",$Config{receiverfw});
       }
       push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),$headid);
    } elsif ( $headid =~ /^APPROX POSITION XYZ/ && exists($Config{positionxyz}) ) {
       substr($line,0,42)=sprintf("%14.4f%14.4f%14.4f",split(/,/,$Config{positionxyz}));
       push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),$headid);
    } elsif ( $headid =~ /^OBSERVER \/ AGENCY/ ) {
       if ( exists($Config{operator}) ) {
            substr($line,0,20)=sprintf("%-20.20s",$Config{operator});
       }
       if ( exists($Config{agency}) ) {
            substr($line,20,40)=sprintf("%-40.40s",$Config{agency});
       }
       push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),$headid);
    } else {
       push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),$headid);
    }
  }

  return \@rnxheaderout;
  
}

sub FilterOptions{

  # Get/set filtering options for the RINEX data
  # Usuage
  #  
  #    my ($windowopt,$rnxheaderout)=FilterOptions($rnxheaderin,\%Config);
  #
  # with @rnxheaderin a pointer to an array with RINEX header lines and $config
  # pointer to $Config. It returns a hash with filter options and array with 
  # updated RINEX header.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($rnxheaderin,$config)=@_;
  
  my %windowopt=();
  my @rnxheaderout=();
  my @comments=();

  # Get time of first observation and interval from RINEX header

  my $timeoffirstobs=undef;
  my $interval=undef;
  if (my ($matched) = grep substr($_,60) =~ /^INTERVAL/ , @{$rnxheaderin} ) {
    $interval = substr($matched,0,10); $interval =~ s/\s//g;
  }
  if (my ($matched) = grep substr($_,60) =~ /^TIME OF FIRST OBS/ , @{$rnxheaderin} ) {
    $timeoffirstobs = join(" ",split(" ",substr($matched,0,43)));
  }
  #  if (my @matched = grep substr($_,60) =~ /^SYS \/ PHASE SHIFT/ , @{$rnxheaderin} ) {
  #    print STDERR "found it: ".join("\n",@matched)."\n";
  #  }

  # Check begin and end options, and set filtering parameters and optional check output interval

  my $windowing=0;
  my @values=split(" ",$timeoffirstobs);
  my $begin=timegm(0, 0, 0, 6, 0, 1980);
  if ( exists($Config{begin}) ) {
     if ( $Config{begin} =~ /(\d+)-(\d+)-(\d+)[\s|T](\d+)\:(\d+)\:(\d+)/ ) {
        $begin=timegm($6,$5,$4,$3,$2-1,$1);
     } elsif ( $Config{begin} =~ /(\d+)-(\d+)-(\d+)[\s|T](\d+)\:(\d+)/ ) {
        $begin=timegm(0.0,$5,$4,$3,$2-1,$1);
     } elsif ( $Config{begin} =~ /(\d+)\:(\d+)\:(\d+)/ ) {
        $begin=timegm($3,$2,$1,$values[2],$values[1]-1,$values[0]);
     } elsif ( $Config{begin} =~ /(\d+)\:(\d+)/ ) {
        $begin=timegm(0.0,$2,$1,$values[2],$values[1]-1,$values[0]);
     } else {
        print $fherr "Invalid time format with option -b, ignore and continue.";
     }
     $windowing=1;
  }
  my $end=timegm(59.9, 59, 23, 31, 11, 2099);
  if ( exists($Config{end}) ) {
     if ( $Config{end} =~ /(\d+)-(\d+)-(\d+)[\s|T](\d+)\:(\d+)\:(\d+)/ ) {
        $end=timegm($6,$5,$4,$3,$2-1,$1);
     } elsif ( $Config{end} =~ /(\d+)-(\d+)-(\d+)[\s|T](\d+)\:(\d+)/ ) {
        $end=timegm(59.9,$5,$4,$3,$2-1,$1);
     } elsif ( $Config{end} =~ /(\d+)\:(\d+)\:(\d+)/ ) {
       $end=timegm($3,$2,$1,$values[2],$values[1]-1,$values[0]);
     } elsif ( $Config{end} =~ /(\d+)\:(\d+)/ ) {
        $end=timegm(59.9,$2,$1,$values[2],$values[1]-1,$values[0]);
     } else {
        print $fherr "Invalid time format with option -e, ignore and continue.";
     }
     $windowing=1;
  }
  my $decimate=0;
  if ( exists($Config{int}) ) {
     $decimate = 60 / sprintf("%.0f", 60.0 / $Config{int} ); 
     if ( $decimate == $interval ) {
         $decimate=0;
     }
  }
  $windowopt{windowing}=$windowing;
  $windowopt{begin}=$begin;
  $windowopt{end}=$end;
  $windowopt{decimate}=$decimate;

  if ( $verbose > 0 ) {
     print $fherr "Time of first obs: $timeoffirstobs\nInterval: $interval\n";
     print $fherr "Time of first obs: ".gmtime($begin)."\n";
     print $fherr "Time of last obs: ".gmtime($end)."\n";
     print $fherr "Windowing: $windowing \n";
     print $fherr "Decimate: $decimate \n";
  }

  if ( $windowing || $decimate || exists($Config{satsys}) ) {
    push @comments,sprintf("%-60.60s%-20.20s","RNXEDIT OBSERVATION FILE FILTERING:","COMMENT");
    push @comments,sprintf("%-60.60s%-20.20s","Filter parameters (from command line):","COMMENT");
    push @comments,sprintf("%-60.60s%-20.20s","- first:    ".scalar(gmtime($begin)),"COMMENT");
    push @comments,sprintf("%-60.60s%-20.20s","- last:     ".scalar(gmtime($end)),"COMMENT");
    push @comments,sprintf("%-60.60s%-20.20s","- interval: $decimate","COMMENT") if ( $decimate);
    push @comments,sprintf("%-60.60s%-20.20s","- systems:  $Config{satsys}","COMMENT") if ( exists($Config{satsys}) );
  }

  # adjust interval, time of first and last observation in RINEX header, remove observation
  # counts if something has changed
  
  my $cntchanged=0;
  my $removed=0;
  my $removedsys=0;
  $cntchanged=1 if ( exists($Config{satsys}) ); 
  foreach my $line (@{$rnxheaderin}) {
    my $headid=uc(substr($line,60));
    if ( $headid =~ /^INTERVAL/ && $decimate) {
       # modify interval
       push @rnxheaderout,sprintf("%10.3f",$decimate).substr($line,10,60);
       push @comments,sprintf("%-60.60s%-20.20s","Interval changed to $decimate (was $interval)","COMMENT");
       $cntchanged=1;
    } elsif ( $headid =~ /^TIME OF FIRST OBS/ && $windowing ) {
       my @values=split(" ",substr($line,0,43));
       my $timeoffirstobs = timegm($values[5],$values[4],$values[3],$values[2],$values[1]-1,$values[0]);
       if ( $begin > $timeoffirstobs ) {
          @values=gmtime($begin);
          substr($line,0,43)=sprintf("%6d%6d%6d%6d%6d%13.7f",$values[5]+1900,$values[4]+1,$values[3],$values[2],$values[1],$values[0]);
          push @comments,sprintf("%-60.60s%-20.20s","Time of first observation changed:","COMMENT");
          push @comments,sprintf("%-60.60s%-20.20s","   ".scalar(gmtime($begin))." (was ".scalar(gmtime($timeoffirstobs)).")","COMMENT");
          $cntchanged=1;
       }
       push @rnxheaderout,$line;
    } elsif ( $headid =~ /^TIME OF LAST OBS/ && $windowing) {
       my @values=split(" ",substr($line,0,43));
       my $timeoflastobs = timegm($values[5],$values[4],$values[3],$values[2],$values[1]-1,$values[0]);
       if ( $end < $timeoflastobs ) {
          @values=gmtime($end);
          substr($line,0,43)=sprintf("%6d%6d%6d%6d%6d%13.7f",$values[5]+1900,$values[4]+1,$values[3],$values[2],$values[1],$values[0]);
          push @comments,sprintf("%-60.60s%-20.20s","Time of last observation changed:","COMMENT");
          push @comments,sprintf("%-60.60s%-20.20s","   ".scalar(gmtime($end))." (was ".scalar(gmtime($timeoflastobs)).")","COMMENT");
          $cntchanged=1;
       }
       push @rnxheaderout,$line;
    } elsif ( exists($Config{satsys}) && ( $headid =~ /^SYS \/ # \/ OBS TYPES/  || $headid =~ /^SYS \/ PHASE SHIFT/ || $headid =~ /^SYS \/ DCBS APPLIED/  || $headid =~ /^SYS \/ PCVS APPLIED/  || $headid =~ /^SYS \/ SCALE FACTOR/ ) ) {
       if ( substr($line,0,1) =~ /[$Config{satsys}]/ ) {
          push @rnxheaderout,$line;
       } else {
          push @comments,sprintf("%-60.60s%-20.20s","SYS / # / OBSTYPES records have been adjusted","COMMENT") if ($removedsys == 0);
          $removedsys++;
       }
    } elsif ( $headid =~ /^END OF HEADER/  ) {
       push @rnxheaderout,@comments;
       push @rnxheaderout,$line;
    } elsif ( $headid =~ /^# OF SATELLITES/  && $cntchanged  ) {
       push @comments,sprintf("%-60.60s%-20.20s","Satellite count removed from RINEX header","COMMENT");
    } elsif ( $headid =~ /^PRN \/ # OF OBS/  && $cntchanged  ) {
       push @comments,sprintf("%-60.60s%-20.20s","Observation counts removed from RINEX header","COMMENT") if ($removed == 0);
       $removed++;
    } else {
       push @rnxheaderout,$line;
    }
  }

  if ( $verbose > 0 ) {
     print $fherr "Time of first obs: $timeoffirstobs\nInterval: $interval\n";
     print $fherr "Time of first obs: ".gmtime($begin)."\n";
     print $fherr "Time of last obs: ".gmtime($end)."\n";
     print $fherr "Windowing: $windowing \n";
     print $fherr "Decimate: $decimate \n";
  }

  return \%windowopt, \@rnxheaderout;
    
}

sub CnvRnxHdr{

  # Convert the RINEX header from version 2 into version 3+ or vice versa
  # Usuage
  #  
  #    my ($obsid2,$obsid3,$colidx,$rnxheaderout)=CnvRnxHdr($versin,$versout,$rnxheaderin,$markertype,$mixedfile);
  #
  # with @rnxheader an array with header lines.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($versin,$versout,$rnxheaderin,$markertype,$mixedfile)=@_;

  # Scan the RINEX header lines to get receiver and observation type info

  my ($receivertype,$obsid3,$obsid2)=ScanRnxHdr($rnxheaderin);
 
  # prepare the RINEX 2 and RINEX3+ observation type information

  my $receiverclass=$receivertype;
  if ( exists($Config{receiverclass}) ) {
      $receiverclass=$Config{receiverclass};
  }
  my ($signaltypes,$selectedrcvrtype)=signaldef($receiverclass);
  my ($cnvtable2to3,$cnvtable3to2)=obstypedef($signaltypes);
  if ( $verbose > 0 ) {
    print $fherr ("\nReceiver type (RINEX file): ", $receivertype, "\n" ); 
    print $fherr (  "Selected receiver type:     ", $selectedrcvrtype, "\n\n" ); 
    print $fherr ("Signal type definitions for ", $selectedrcvrtype, "\n\n"); 
    prtsignaldef($fherr,$signaltypes);
    print $fherr ("\nConversion table for RINEX version 2 to 3\n\n"); 
    prttypedef($fherr,$cnvtable2to3);
    print $fherr ("\nConversion table for RINEX version 3 to 2\n\n"); 
    prttypedef($fherr,$cnvtable3to2);
  }

  # Observation type translation

  my $colidx={};

  my $hadobstype2=0;
  my $hadobstype3=0;
  if ( scalar(@{$obsid2}) > 0 ) {
    $hadobstype2=1;
  }
  if ( scalar(keys(%{$obsid3})) > 0 ) {
    $hadobstype3=1;
  }

  my @cnvtable=();
  if ($versin < 3.00 && $versout > 2.99 ) {
     if ( $hadobstype2 == 0 ) {
        die "RINEX 2 file has no type 2 observation type record";
     } 
     if ( $hadobstype3 == 0 ) {
       # convert RINEX2 observation type into RINEX3 types
       ($obsid3,$colidx)=obstype2to3($mixedfile,$obsid2,$cnvtable2to3);
     } else {
       # have a type 3 record, use this instead <-- not yet implemented
       # need to set $colidx
       ($obsid3,$colidx)=obstype2to3($mixedfile,$obsid2,$cnvtable2to3);
     }  
     @cnvtable=fmtcnvtable($obsid2,$obsid3,$colidx,$versin,$versout);
     if ( $verbose > 0 ) {
       print $fherr ("\nConversion from RINEX version 2 ($versin) to 3 ($versout)\n"); 
       print $fherr ("\nRINEX 2 observation types:\n\n"); 
       prtobstype2($fherr,$obsid2);
       print $fherr ("\nRINEX 3 observation types:\n\n"); 
       prtobstype3($fherr,$obsid3);
       for my $line (@cnvtable) {
         print $fherr $line."\n";
       }
       print $fherr ("\nRinex output column order (2->3)\n\n"); 
       prtobsidx($fherr,$colidx);
     }
  } elsif ( $versin > 2.99 && $versout < 3.00 ) {
     if ( $hadobstype3 == 0 ) {
        die "RINEX 3 file has no type 3 observation type record";
     } 
     my $colidx2=[];
     if ( $hadobstype2 == 0 ) {
       # convert RINEX3 observation type into RINEX2 types
       my $obsid2p;
       ($obsid2p,$colidx2)=obstype3to2($mixedfile,$obsid3,$cnvtable3to2);
       @{$obsid2}=@{$obsid2p};
     } else {
       # have a type 2 record, use this instead <-- not yet implemented
       # need to set $colidx
       my $obsid2p;
       ($obsid2p,$colidx2)=obstype3to2($mixedfile,$obsid3,$cnvtable3to2);
       @{$obsid2}=@{$obsid2p};
     }  
     @cnvtable=fmtcnvtable($obsid2,$obsid3,$colidx2,$versin,$versout);
     if ( $verbose > 0 ) {
       print $fherr ("\nConversion from RINEX version 3 ($versin) to 2 ($versout)\n"); 
       print $fherr ("\nRINEX 2 observation types:\n\n"); 
       prtobstype2($fherr,$obsid2);
       print $fherr ("\nRINEX 3 observation types:\n\n"); 
       prtobstype3($fherr,$obsid3);
       for my $line (@cnvtable) {
         print $fherr $line."\n";
       }
       print $fherr ("\nInverse Rinex column order (2->3)\n\n"); 
       prtobsidx($fherr,$colidx2);
     }
     $colidx=invobsidx($colidx2);
     if ( $verbose > 0 ) {
       print $fherr ("\nRinex output column order (3->2)\n\n"); 
       prtobsidx($fherr,$colidx);
     }
#  } else {
#    $colidx=XXXXXXX
  }

  # Modify and copy the header lines

  my $rnxheaderout=();
  if ( $versin < 3.00 && $versout > 2.99 ) {
     # Version 2 -> 3
     $rnxheaderout=CnvRnxHdr2to3($rnxheaderin,$obsid3,\%Config,$versout,\@cnvtable);
     #splice @{$rnxheaderout},-1,0,@comments;
  } elsif ( $versin > 2.99 && $versout < 3.00 ) {
     # Version 3 -> 2
     $rnxheaderout=CnvRnxHdr3to2($rnxheaderin,$obsid2,\%Config,$versout,\@cnvtable);
     #splice @{$rnxheaderout},-1,0,@comments;
  } else {
     # Verbatim (same major version)
     @{$rnxheaderout}=@{$rnxheaderin};
     # need to make minor adjustments between versions 3 and 4
   }
   
  return ($obsid2,$obsid3,$colidx,$rnxheaderout);
  
}

sub CnvRnxHdr2to3{

  # Convert the RINEX header from version 2 into version 3 
  # Usuage
  #  
  #    my $rnxheaderout=CnvRnxHdr2to3($rnxheaderin,$obsid3,$config,$versout,$cnvtable);
  #
  # with @rnxheaderin a pointer to an array with RINEX2 header lines,
  # $obsid3 the pointer to the hash structure with RINEX3 observation types,
  # and $config the rerefence to the hash structure with additional configuration
  # information, such as the markertype. It returns the array with RINEX3 
  # headers as reference.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($rnxheaderin,$obsid3,$config,$versout,$cnvtable)=@_;
  
  my @rnxheaderout=();
   
  my $hadmarkerrecord=0;
  my $hadmarkertype=0;
  my $haveinsertedrnx3types=0;
  my $haveremovedrnx2types=0;

  foreach my $line (@{$rnxheaderin}) {

    my $headid=uc(substr($line,60));

    # insert mandatory "MARKER TYPE" header for RINEX 3 (after all other MARKER records)
    if ( $headid =~ /^MARKER TYPE/) {
      $hadmarkertype=1;
    }
    if ( $headid =~ /^MARKER/) {
      $hadmarkerrecord=1;
    }
    if ( ( $hadmarkertype == 0 ) && ( $hadmarkerrecord == 1 ) && ( $headid !~ /^MARKER/ ) ) {
      push @rnxheaderout,sprintf("%-20.20s%-40.40s%-20.20s","UNKNOWN","","MARKER TYPE");
      $hadmarkertype=1;
    }  

    # Insert RINEX 3 observation types just before the type 2 observation types
    if ( $headid =~ /^# \/ TYPES OF OBSERV/ && $haveinsertedrnx3types == 0) {
      for my $line (@$cnvtable) {
        push @rnxheaderout, sprintf("%-60.60s%-20.20s",$line,"COMMENT");
      }
      push @rnxheaderout,fmtobshead3($obsid3);
      if ( $config->{strict} && $versout >= 3.01 && $versout <= 3.05 ) {
          # Insert default SYS / PHASE SHIFT records for compability, mandatory with 
          # version 3.01-3.05, introduced with 3.01, but strongly depricated with version 4
          for my $sysid ( sysids($obsid3) ) {
             push @rnxheaderout,sprintf("%-60.60s%-20.20s",$sysid,"SYS / PHASE SHIFT");
          } 
      } 
      $haveinsertedrnx3types=1;
    }
  
    # Copy existing records, while changing obsolete records to comments
    if  (   $config->{strict} && 
          ( $headid =~ /^WAVELENGTH FACT L1\/2/  || 
            $headid =~ /^# \/ TYPES OF OBSERV/    )  ) {
      if ( $headid =~ /^WAVELENGTH FACT L1\/2/  || ( $headid =~ /^# \/ TYPES OF OBSERV/ && $haveremovedrnx2types == 0 ) ) {
         push @rnxheaderout,sprintf("%-60.60s%-20.20s","OBSOLETE RINEX-V2 ".$headid." :","COMMENT");
         $haveremovedrnx2types=1 if ( $headid =~ /^# \/ TYPES OF OBSERV/ );
      }
      push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),"COMMENT");
    } else {
      push @rnxheaderout,$line;
    }
  }

  if ( $config->{strict} && $versout >= 3.02 && $versout <= 3.05 ) {
     # Insert default GLONASS COD/PHS/BIS record for compability, mandatory with 
     # version 3.02-3.05, introduced with 3.02, but strongly depricated with version 4
     splice @rnxheaderout,-1,0,sprintf("%-60.60s%-20.20s","","GLONASS COD/PHS/BIS");
  } 
  my $glonasscfg = dirname(__FILE__) . "/glonass.cfg";
  if ( $config->{strict} && $versout >= 3.02 && -e $glonasscfg ) {
     # Insert GLONASS SLOT / FRQ records, mandatory since version 3.02, requires
     # libglonass.pl Perl module
     my $dateoffirstobs;
     foreach my $line (@{$rnxheaderin}) {
         if ( uc(substr($line,60)) =~ /^TIME OF FIRST OBS/ ) {
            $dateoffirstobs = sprintf("%04d-%02d-%02d",split(" ",substr($line,0,18)));
            #print STDERR "$dateoffirstobs\n";
            last;
         }
     }
     my $glosat = glonassdata($dateoffirstobs,$glonasscfg);
     if ( $config->{verbose} > 1 ) {
        prtglonassdata($glosat);
     }
     splice @rnxheaderout,-1,0,glonassslothdr($glosat);
  } 

  return \@rnxheaderout;
    
}

sub CnvRnxHdr3to2{

  # Convert the RINEX header from version 3 into version 2 
  # Usuage
  #  
  #    my $rnxheaderout=CnvRnxHdr3to2($rnxheaderin,$obsid2,$config,$versout,$cnvtable);
  #
  # with @rnxheaderin a pointer to an array with RINEX3 header lines,
  # $obsid2 the pointer to the array structure with RINEX2 observation types,
  # and $config a reference to a hash with additional configuration information. 
  # It returns the array with RINEX2 headers as reference.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($rnxheaderin,$obsid2,$config,$versout,$cnvtable)=@_;
  
  my @rnxheaderout=();
   
  my $hasinsertedtype2=0;
  my %haveremovedrnx3types=();
  
  foreach my $line (@{$rnxheaderin}) {

    my $headid=uc(substr($line,60));

    # Insert RINEX 2 observation types just before the type 3 observation types
    if ( ($hasinsertedtype2 == 0) && ( $headid =~ /^SYS \/ # \/ OBS TYPES/) ) {
      for my $line (@$cnvtable) {
        push @rnxheaderout, sprintf("%-60.60s%-20.20s",$line,"COMMENT");
      }
      push @rnxheaderout,fmtobshead2($obsid2);
      $hasinsertedtype2=1;
    }

    # Copy existing records, while changing future version records to comments
    if  (   $config->{strict} && 
          ( $headid =~ /^MARKER TYPE/              || 
            $headid =~ /^SYS \/ # \/ OBS TYPES/    ||
            $headid =~ /^SYS \/ PHASE SHIFT/       ||
            $headid =~ /^GLONASS SLOT \/ FRQ/      ||
            $headid =~ /^GLONASS COD\/PHS\/BIS/    ||
            $headid =~ /^ANTENNA\: DELTA X\/Y\/Z/  || 
            $headid =~ /^ANTENNA\:PHASECENTER/     ||
            $headid =~ /^ANTENNA\: B.SIGHT XYZ/    ||
            $headid =~ /^ANTENNA\: ZERODIR AZI/    ||
            $headid =~ /^ANTENNA\: ZERODIR XYZ/    ||
            $headid =~ /^CENTER OF MASS\: XYZ/     ||
            $headid =~ /^SIGNAL STRENGTH UNIT/     ||
            $headid =~ /^SYS \/ DCBS APPLIED/      ||
            $headid =~ /^SYS \/ PCVS APPLIED/      ||
            $headid =~ /^SYS \/ SCALE FACTOR/      ||
            $headid =~ /^DOI/                      ||
            $headid =~ /^LICENSE OF USE/           ||
            $headid =~ /^STATION INFORMATION/   )   ) {
      if ( ! exists($haveremovedrnx3types{$headid}) ) {
         push @rnxheaderout,sprintf("%-60.60s%-20.20s","COMMENTED OUT RINEX-V3 ".$headid." :","COMMENT");
         $haveremovedrnx3types{$headid}=1;
      }
      push @rnxheaderout,sprintf("%-60.60s%-20.20s",substr($line,0,60),"COMMENT");
    } else {
      push @rnxheaderout,$line;
    }
  }

  return \@rnxheaderout;
  
}

sub setversout{
   
   my ($versin,$versoutopt) =@_;
   
   my $mainversin = $versin < 2.99 ? 2 : 3;  # $mainversin is 2 or 3 (even for version 4)
   my $mainversout;  
   my $versout;
   if ( $versoutopt =~ /^cc$/ ) {
      # output version is the same as the input version
      $mainversout=$mainversin;
      $versout=$versin;
   } elsif ( $versoutopt =~ /^\s*$/ ) {
     # main output version is the opposite of the main input version
     $mainversout = $mainversin == 2 ? 3 : 2;  
     $versout = checkrnxversion($mainversout);    # use default version 2 or 3
  } elsif ( $versoutopt =~ /^[234]$/ ) {
     if ( $versin =~ /^$versoutopt/ ) {
        # output version is the same as input version if main version matches
        $mainversout=$mainversin;
        $versout=$versin;
     } else {
        # main version different from input, version is set to the default for the main output version
        $mainversout = $versout == 2 ? 2 : 3;  
        $versout = checkrnxversion($versoutopt);
     } 
  } else {
     $mainversout = $versoutopt < 2.99 ? 2 : 3; # $mainversout is 2 or 3 (even for version 4)
     $versout = checkrnxversion($versoutopt);
  } 
  
  return $versout, $mainversout, $mainversin;

}

sub checkrnxversion{

   my ($version)=@_;

   $version="2.11" if ( $version =~/^2$/ );
   $version="3.00" if ( $version =~/^3$/ );
   $version="4.02" if ( $version =~/^4$/ );

   my $ok=0; $ok=1 if ( $version =~ /^(2.11|3\.0[0-5]|4\.0[0-3])$/ );
   if ( ! $ok ) {
      my $versold=$version;
      $version="2.11" if ( $version =~/^2.*$/ );
      $version="3.04" if ( $version =~/^3.*$/ );
      $version="4.02" if ( $version =~/^4.*$/ );
      my $ok=0; $ok=1 if ( $version =~ /^(2.11|3\.0[0-5]|4\.0[0-2])$/ );
      if ( $ok ) {
         print STDERR "Warning: Unknown rinex version $versold, will use $version instead.\n";
      } else {
         print STDERR "Error: Unsupported rinex version $versold, aborting.\n";
         die;
      }
   }
   
   return $version;
}




