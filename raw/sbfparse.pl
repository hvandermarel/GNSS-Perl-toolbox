#!/usr/bin/perl
#
# sbfparse.pl
# ----------
#
# SBF (Septentrio Binary File) file parser. Parses SBF binary files and 
# Usage :
#    sbfparse [-c] [-v[level] [-h] [-s] sbffile
#
# - Checks for synchronisation errors and file integrity
# - Count the records and determine start and end epoch
# - Split the file into hourly or daily chunks (N/A)
#
# Created:   9 September 2010 by Hans van der Marel
# Modified:  2 July 2023 by Hans van der Marel
#              - added message description, satids and signals
#              - optional ISMR output
#            6 July 2025 by Hans van der Marel
#              - checked with strict pragma
#              - improved scoping and program flow
#              - added Apache 2.0 license notice
#
# Copyright 2010-2025 Hans van der Marel, Delft University of Technology.
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
use Time::Local;

use strict;
use warnings;

our $VERSION = 20250706;

# Process command line options

our %Config = (
    verbose      =>   0 ,
    quiet        =>   0 ,
    crc          =>   0 ,
    ismr         =>   0 ,
    help         =>   0 ,
);  

my $Result = GetOptions( \%Config,
                      qw(
                        crc|c
                        ismr|s
                        sta4|n=s
                        verbose|v+
                        quiet|q
                        help|?|h
                      ) );

$Config{help} = 1 if( ! $Result || ! scalar @ARGV );
if( $Config{help} )
{
    Syntax();
    exit();
}
if ( $Config{quiet} ) {
   $Config{verbose}=-1;
} else {
   # raise default verbosity level unless ismr output is selected
   $Config{verbose}++ if ( not $Config{ismr} );
}

# get the file names from the command line

my @sbffiles = @ARGV;

# Define sbfmessage types, satids and signal types 

my %sbfmessagetypes=defsbfmessagetypes();
my %sbftimetype=defsbftimetype();
my %sbfsatids=defsatids();
my %sbfsigtypes=defsigtypes();

# setup table for CRC (for fast evaluations -> not working yet)
# our @crc_tabccitt=crc16table() if ( $Config{crc} );

# Process sbf files one by one

foreach my $file (@sbffiles) {

  # set the station name (from file name or commandline option)
  my $station;
  if ( exists($Config{sta4})) {
    $station=$Config{sta4};
  } else {
    $station=substr($file,0,4);
  }

  # optionally decompress the file during read using a pipe with gzip

  my $xfile=$file;
  $xfile="gzip -d -S .zip -c $file |" if ( $file =~ /(\.Z|.gz|.zip)$/i );

  # load complete file into memory

  open(FILE, "$xfile")  or die "can't open $file: $!";
  binmode(FILE);
  undef $/;
  our  $buffer=<FILE>;
  close(FILE)  or die "can't close $file: $!";
  our $buffersize=length($buffer);

  print "SBF file $file ($buffersize bytes):\n\n" if ($Config{verbose} > 1);

  # initialize message counters

  my %seen=();
  my %bytecnt=();
  my %firstencounter=();
  my $recordnum=0;

  # initialize initial week number ($wnc0), start and end second of week
  my $wnc0=0;
  my $starttows=4294967.295; 
  my $endtows=0;
  
  # parse the file in memory
  
  # The ID, length and message contents are returned by NextSBFMessage
  # as variables $id, $idvers, $length, $message, $tow and $wnc.
  # Global variables expected on input are $buffer and $buffersize. 

  my ($id, $idvers, $tow, $wnc, $message, $length);

  #printf ("  ID  v size (__CRC)         TOW  week     start -->      end\n---- -- ---- -------  ----------  ----  --------     --------\n") if ($Config{verbose} > 1);
  printf ("  ID  v size         TOW  week     start -->      end  message type              description\n---- -- ----  ----------  ----  --------     --------  ----------------------    ------------------------------------\n") if ($Config{verbose} > 1);

  my $ptr=0;
  while ( $ptr < $buffersize ) {  
    ($id,$idvers,$message,$length,$tow,$wnc,$ptr)=NextSBFMessage($ptr);
    if (!exists($bytecnt{$id})) {
      $seen{$id}=0;
      $bytecnt{$id}=0;
      $firstencounter{$id}=$recordnum;
    }
    $recordnum++;
    $seen{$id}++;
    $bytecnt{$id}+=$length;
    #printf ("%4d %2d %4d (%5d)  %10.3f  %4d  %8d --> %8d  %s\n", $id, $idvers ,$length ,$crc, $tow/1000, $wnc, $ptr0+1 ,$ptr, $sbfmessagetypes{$id}) if ($Config{verbose} > 1);
    printf ("%4d %2d %4d  %10.3f  %4d  %8d --> %8d  %s\n", $id, $idvers ,$length ,$tow/1000, $wnc, $ptr-$length+1 ,$ptr, $sbfmessagetypes{$id}) if ($Config{verbose} > 1);
    # set start and end time
    if ( exists($sbftimetype{$id}) && $sbftimetype{$id} == 1 ) {
       # set the initial week number
       $wnc0=$wnc if ( ! $wnc0 ); 
       my $tows=($wnc-$wnc0)*604800+$tow/1000;
       $starttows=$tows if ($tows < $starttows );
       $endtows=$tows if ($tows > $endtows );
    }
    # optional ISMR record handling
    if ( $Config{ismr} && $id == 4086 ) {
       my ($tow,$wnc,$numsub,$lensub)=unpack("LSCC",substr($message, 0, 8));
       #printf ("%10.3f  %4d  %4d %4d\n", $tow/1000, $wnc, $numsub ,$lensub);
       my $ptrsub=12;
       for ( my $i=0; $i < $numsub ; $i++ ) {
          my ($rxchan,$sigtype,$svid,$reserved,$s4,$sigmaphi)=unpack("CCCCSS",substr($message, $ptrsub, 8));
          if ( $sigmaphi < 65535 ) {
             $sigmaphi=sprintf("%.6f",$sigmaphi/1000);
          } else {
             $sigmaphi='';
          }
          if ( $s4 < 65535 ) {
             $s4=sprintf("%.6f",$s4/1000);
          } else {
             $s4='';
          }
          if ( $rxchan > 0 && exists $sbfsigtypes{$sigtype} && $svid > 0 && $svid <= 245 ) {
             printf ("%10.3f,%4d,%d,%s,%s,%s,%s\n", $tow/1000,$wnc,$rxchan,$sbfsigtypes{$sigtype},$sbfsatids{$svid},$s4,$sigmaphi);
          } else {
             printf STDERR "Skipped ouput of ISMR record rxchannel %d with invalid signaltype %d for satid %d at %10.3f,%4d\n",$rxchan,$sigtype,$svid,$tow/1000,$wnc;
          }
          $ptrsub=$ptrsub+$lensub;
       }
    }
  }

  # Print statistics for each file

  if ( $Config{verbose} > 0 ) {

     my $time0 = timegm(0,0,0,6,0,1980);      # GPS time starts at Sunday 6th 1980 00:00

     my $totalmessages=0;
     my $totalbytes=0;
     print "\nStatistics for SBF file $file:\n\n";
     printf("Start:  %s\n",scalar(gmtime($time0+$wnc0*604800+$starttows)));
     printf("End:    %s\n\n",scalar(gmtime($time0+$wnc0*604800+$endtows)));
     print "  ID  first  count      bytes    message type              description\n";
     print "----  -----  -----  ---------    ----------------------    ------------------------------------\n";
     # foreach $id ( sort { $a <=> $b } keys %seen ) {
     foreach my $id ( sort { $firstencounter{$a} <=> $firstencounter{$b} } keys %firstencounter ) {
       if (exists($sbfmessagetypes{$id})) {
          printf("%3d %6d%7d %10d    %s\n",$id,$firstencounter{$id},$seen{$id},$bytecnt{$id},$sbfmessagetypes{$id});
       } else {
          printf("%3d %6d%7d %10d\n",$id,$firstencounter{$id},$seen{$id},$bytecnt{$id});
       }
       $totalmessages+=$seen{$id};
       $totalbytes+=$bytecnt{$id};
     }
     print "             -----  ---------\n";
     printf("           %7d %10d   (ignored %d bytes)\n\n",$totalmessages,$totalbytes,$buffersize-$totalbytes);

   }
}
  
exit;

# ---------------------------------------------------------------------------------------------------------------------

# Subroutines

sub Syntax {
  my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
  my $Line = "-" x length( $Script );
  our $VERSION;
  print << "EOT";
$Script                                            (Version: $VERSION)
$Line
Parse SBF (Septentrio Binary Format) file(s), check for synchronisation errors 
and file integrity, count the records, and determine start and end time.
Optionally output ISMR scintillation indices.

Syntax:

    $Script [-c] [-v|-q] [-h|?] [-s] sbffile(s)
        
    -c..............Check the CRC
    -s..............Print ISMR scintillation indices instead of statistics
    -q..............Quiet mode (suppresses all output except ISMR)
    -v..............Verbose mode (list messages or use -v -v for debugging)
    -?|h............This help.
                                            
    sbffile(s)......SBF files (wildcards and compression allowed).
                                                
Examples:

    $Script sept1230.13_
    $Script sept1230.13_.gz
    $Script -v sept1230.13_
                                                    
(c) 2010-2025 Hans van der Marel, Delft University of Technology.
EOT
                                                    
}
                                                    

sub NextSBFMessage{

  # Get the next (standard)  message from the SBF file
  # Syntax:
  #          $prt=NextSBFMessage($ptr);
  #
  # The ID, length and message contents are returned in the global variables
  # $id, $idvers, $length, $message, $tow and $wnc.
  #
  # Global variables expected on input are $buffer and $buffersize. 

  my ($ptr) = @_;
  
  our ($buffer,$buffersize);
  our %Config;
  
  my $syncbyte=unpack("S",'$@');

  my ($id, $idvers, $length, $message, $tow, $wnc);

  while ( $ptr <= $buffersize - 1 ) {

    # Check the 8-byte pre-amble of the record
    #
    # Byte   Name       Description            Possible values
    #  0-1   sync       Synchronization bytes  $@
    #  2-3   crc        16 bit CRC
    #  4-5   recid      2-byte block ID (0-12 block number, 13-15 version)
    #  6-7   reclen     Record length (total, must be multiple of 4)       

    # Align with the synchronization bytes ($@)

    if ( $ptr+2 > $buffersize  ) { $ptr=$ptr+2; last}

    my $preamb=unpack("S",substr( $buffer, $ptr , 2));

    print "Preamble (syncbyte) --> $preamb ($syncbyte)\n" if ($Config{verbose} > 2);

    if ($preamb != $syncbyte) {
      #out of sync, re-synchronize
      print STDERR "WARNING: OUT OF SYNC\n";
      my $ptr0=$ptr;
      while ($preamb != $syncbyte ) {
        $ptr++;
        $preamb=unpack("S",substr( $buffer, $ptr , 2));
        print "$preamb " if ($Config{verbose} > 2);
        last if ( $ptr >= $buffersize - 1 );
      }
      print STDERR "Skipped bytes $ptr0 until $ptr\n";
      # print the bad chunk for checking purposes
      my $badstring0=substr( $buffer, $ptr0 - 4 , 4 );
      my $badstring=substr( $buffer, $ptr0 , $ptr-$ptr0 );
      print STDERR "Malformed chunk --> $ptr0...$ptr-1  $badstring0 -> $badstring \n" if ($Config{verbose} > 1);
    }

    if ( $ptr+8 > $buffersize ) { $ptr=$ptr+8; last}

    # Get the remainder of the record pre-amble (CRC, recid, reclen)

    my $tag=substr( $buffer, $ptr+2 , 6);
    my ($crc,$recid,$reclen)=unpack("SSS",$tag);

    print "Preamble (recid, reclen, CRC) --> $recid $reclen $crc\n" if ($Config{verbose} > 2);

    # Check if record length is multiple of 4, if not look for next sync bytes

    if ( $reclen % 4 ) {
      print STDERR "Record length is not multiple of 4-bytes, resynchronize $recid $reclen\n";
      $ptr=$ptr+1;
      next;
    }
  
    # Check the CRC, if CRC does not match look for next sync bytes

    if ( $Config{crc} ) { 
      my $cs=crc16ccitt(substr( $buffer, $ptr+4, $reclen-4) );
      #my $cs=crc16ccitt_fast(substr( $buffer, $ptr+4, $reclen-4) );
      if ( $crc != $cs ) {
        print STDERR "Checksum error (checksum=$crc, computed=$cs), skip\n";
        $ptr=$ptr+$reclen;
        next;
      }
    }
    
    # Ok, done parsing record

    $id=$recid % 8192;
    $idvers=($recid - $id)/8192;
    $length=$reclen;
    $message=substr( $buffer, $ptr+8 , $reclen-8);

    # Time stamp
    #
    # Byte   Name       Description             Do not use values
    #  0-3   TOW        Time-of-week in ms      4294967295 
    #  4-5   WNc        Continuous week number  65535

    ($tow,$wnc)=unpack("LS",substr($message, 0, 6));

    last;

  }
  
  #$ptr0 = $ptr;
  $ptr = $ptr + $length;

  return ($id,$idvers,$message,$length,$tow,$wnc,$ptr);
  #return $ptr;

}


# Subroutine to check CRC (slow version)

sub crc16ccitt { 

  my ($buf)=@_;

  my $cs=0x0000;
  while ( $buf =~ /(.)/gs ) {
    $cs = 0xFFFF & ( ( $cs >> 8) | ( $cs << 8) );
    $cs = $cs ^ ( 0x00FF & ord($1) ) ;
    $cs = 0xFFFF & ( $cs ^ ( ( $cs & 0xFF ) >> 4 ) );
    $cs = 0xFFFF & ($cs ^ ( ( $cs << 8 ) << 4 ) ) ;
    $cs = 0xFFFF & ($cs ^ ( ( ( $cs & 0xFF ) << 4 ) << 1 ) );
  }

  return $cs;
}

# Subroutine to check CRC (fast version with table lookup) <== isn't working yet (DO NOT USE THIS VERSION)

sub crc16ccitt_fast { 

  my ($buf)=@_;
  
  our @crc_tabccitt;

  my $cs=0x0000;
  while ( $buf =~ /(.)/gs ) {
    #print "$cs $1 \n";
    my $c = 0x00FF & ord($1) ;
    my $tmp = ($cs >> 8) ^ $c;
    $cs = ($cs << 8) ^ $crc_tabccitt[ord($tmp)];
    $cs = 0xFFFF & $cs ;
  }

  return $cs;
}


sub crc16table{

  my @crc_tabccitt=();

  for ( my $i=0; $i < 256 ; $i++ ) {
     my $crc = 0x0000;
     my $c   = ( 0x00FF & $i ) << 8;
     $c   = 0xFFFF & $c ;
     for ( my $j=0; $j<8; $j++) {
        if ( ($crc ^ $c) & 0x8000 ) { 
           $crc = ( $crc << 1 ) ^ 0x1021;
        } else {
           $crc =  $crc << 1;
        }
        $crc = 0xFFFF & $crc ;
        $c = $c << 1;
     }
     $crc_tabccitt[$i]=$crc;
  }

  return @crc_tabccitt;
}      


# Subroutines with SBF message definitions

sub defsbfmessagetypes {

  # enumerate sbf message types

  my %sbfmessagetypes = (

  5889 => "MeasEpoch (v1)            Obsolete (PolaRx2)",
  5890 => "ShortMeasEpoch (v1)       Obsolete (PolaRx2)",
  5944 => "GenMeasEpoch (v1)         Measurement set of one epoch (PolaRx2)",
  4027 => "MeasEpoch                 Measurement set of one epoch",
  4000 => "MeasExtra (v1)            Additional info such as observable variance",
  4046 => "IQCorr (v1)               Real and imaginary post-correlation values",
  4086 => "ISMR                      Ionospheric scintillation monitor (ISMR) data",
  4109 => "Meas3Ranges               Code, phase and CN0 measurements",
  4110 => "Meas3CN0HiRes             Extension of Meas3Ranges containing fractional C/N0 values",
  4111 => "Meas3Doppler              Extension of Meas3Ranges containing Doppler values",
  4112 => "Meas3PP                   Extension of Meas3Ranges containing proprietary flags for data post-processing",
  4113 => "Meas3MP                   Extension of Meas3Ranges containing multipath corrections applied by the receiver",
  5922 => "EndOfMeas (v1)            Measurement epoch marker",
                                
  5895 => "GPSRaw (v1)               GPS CA navigation frame (PolaRx2)",
  5947 => "CNAVRaw (v1)              GPS L2C navigation frame (PolaRx2)",
  5898 => "GEORaw (v1)               SBAS L1 navigation frame (PolaRx2)",
  
  4017 => "GPSRawCA (v1)             GPS CA navigation frame",
  4018 => "GPSRawL2C (v1)            GPS L2C navigation frame",
  4019 => "GPSRawL5 (v1)             GPS L5 navigation frame",
  4221 => "GPSRawL1                  GPS L1C navigation frame",
  4026 => "GLORawCA (v1)             GLONASS CA navigation string",
  4022 => "GALRawFNAV (v1)           Galileo F/NAV navigation page",
  4023 => "GALRawINAV (v1)           Galileo I/NAV navigation page",
  4024 => "GALRawCNAV (v1)           Galileo C/NAV navigation page",
  4020 => "GEORawL1 (v1)             SBAS L1 navigation message",
  4021 => "GEORawL5                  SBAS L5 navigation message",
  4047 => "BDSRaw (v1)               Beidou navigation page",
  4218 => "BDSRawB1C                 BeiDou B1C navigation frame",
  4219 => "BDSRawB2a                 BeiDou B2a navigation frame",
  4242 => "BDSRawB2b                 BeiDou B2b navigation frame",
  4066 => "QZSRawL1CA (v1)           QZSS L1 CA navigation frame",
  4067 => "QZSRawL2C (v1 )           QZSS L2C CA navigation frame",
  4068 => "QZSRawL5                  QZSS L5 navigation frame",
  4069 => "QZSRawL6                  QZSS L6 navigation message",
  4227 => "QZSRawL1C                 QZSS L1C navigation frame",
  4228 => "QZSRawL1S                 QZSS L1S navigation message",
  4093 => "NAVICRaw                  NavIC/IRNSS subframe",
                                  
  5891 => "GPSNav (v1)               GPS ephemeris and clock",
  5892 => "GPSAlm (v1)               Almanac data for a GPS satellite",
  5893 => "GPSIon (v1)               Ionosphere data from the GPS subframe 5",
  5894 => "GPSUtc (v1)               GPS-UTC data from GPS subframe 5",
                                
  4004 => "GLONav (v1)               GLONASS ephemeris and clock",
  4005 => "GLOAlm (v1)               Almanac data for a GLONASS satellite",
  4036 => "GLOTime (v1)              GLO-UTC, GLO-GPS and GLO-UT1 data",
                                
  4002 => "GALNav (v1)               Galileo ephemeris, clock, health and BGD",
  4003 => "GALAlm (v1)               Almanac data for a Galileo satellite",
  4030 => "GALIon (v1)               NeQuick Ionosphere model parameters",
  4031 => "GALUtc (v1)               GST-UTC data",
  4032 => "GALGstGps (v1)            GST-GPS data",
  4034 => "GALSARRLM (v1)            Search-and-resque return link message",
                                
  4081 => "BDSNav                    BeiDou ephemeris and clock" ,
  4119 => "BDSAlm                    Almanac data for a BeiDou satellite" ,
  4120 => "BDSIon                    BeiDou Ionospheric delay model parameters" , 
  4121 => "BDSUtc                    BDT-UTC data" , 

  4095 => "QZSNav                    QZSS ephemeris and clock" ,
  4116 => "QZSAlm                    Almanac data for a QZSS satellite" ,

  5925 => "GEOMT00 (v1)              MT00 : SBAS Dont use for safety applications",
  5926 => "GEOPRNMask (v1)           MT01 : PRN Mask assignments",
  5927 => "GEOFastCorr (v1)          MT02-05/24: Fast Corrections",
  5928 => "GEOIntegrity (v1)         MT06 : Integrity information",
  5929 => "GEOFastCorrDegr(v1)       MT07 : Fast correction degradation factors",
  5896 => "GEONav (v1)               MT09 : SBAS navigation message",
  5930 => "GEODegrFactors (v1)       MT10 : Degradation factors",
  5918 => "GEONetworkTime (v1)       MT12 : SBAS Network Time/UTC offset parameters",
  5897 => "GEOAlm (v1)               MT17 : SBAS satellite almanac",
  5931 => "GEOIGPMask (v1)           MT18 : Ionospheric grid point mask",
  5932 => "GEOLongTermCor (v1)       MT24/25 : Long term satellite error corrections",
  5933 => "GEOIonoDelay (v1)         MT26 : Ionospheric delay corrections",
  5917 => "GEOServiceLevel(v1)       MT27 : SBAS Service Message",
  5934 => "GEOClockEphCovMatrix(v1)  MT28 : Clock-Ephemeris Covariance Matrix",
                                
  5903 => "PVTCartesian (v1)         PVT in Cartesian coordinates (PolaRx2)",
  5904 => "PVTGeodetic (v1)          PVT in geodetic coordinates (PolaRx2)",
  5909 => "DOP (v1)                  Dilution of precision (PolaRx2)",
  5910 => "PVTResiduals (v1)         Measurement residuals (PolaRx2)",
  5915 => "RAIMStatistics (v1)       Integrity statistics (PolaRx2)",
  4006 => "PVTCartesian (v2)         Position, velocity, and time in Cartesian coordinates",
  4007 => "PVTGeodetic (v2)          Position, velocity, and time in geodetic coordinates",
  5905 => "PosCovCartesian(v1)       Position covariance matrix (X,Y,Z)",
  5906 => "PosCovGeodetic (v1)       Position covariance matrix (Lat,Lon,Alt)",
  5907 => "VelCovCartesian(v1)       Velocity covariance matrix (X,Y,Z)",
  5908 => "VelCovGeodetic (v1)       Velocity covariance matrix (North,East,Up)",
  4001 => "DOP (v2)                  Dilution of precision",
  4044 => "PosCart (v1)              Position, variance and baseline in Cartesian coordinates",
  4008 => "PVTSatCartesian(v1)       Satellite positions",
  4009 => "PVTResiduals (v2)         Measurement residuals",
  4011 => "RAIMStatistics (v2)       Integrity statistics",
  5935 => "GEOCorrections (v1)       Orbit, Clock and pseudoranges SBAS corrections",
  4043 => "BaseVectorCart (v1)       XYZ relative position and velocity with respect to base(s)",
  4028 => "BaseVectorGeod (v1)       ENU relative position and velocity with respect to base(s)",
  5921 => "EndOfPVT (v1)             PVT epoch marker",
                                
  5914 => "ReceiverTime (v1)         Current receiver and UTC time",
  5911 => "xPPSOffset (v1)           Offset of the xPPS pulse with respect to GNSS time",
                                
  5924 => "ExtEvent (v1)             Time at the instant of an external event",
  4037 => "ExtEventPVTCartesian(v1)  Cartesian position at the instant of an event",
  4038 => "ExtEventPVTGeodetic (v1)  Geodetic position at the instant of an event",
  4217 => "ExtEventBaseVectGeod      ENU relative position with respect to base(s) at the instant of an event",
                                
  5919 => "DiffCorrIn (v1)           Incoming RTCM or CMR message",
  5949 => "BaseStation (v1)          Base station coordinates",
  4049 => "RTCMDatum                 Datum information from the RTK service provider",
                                  
  5913 => "ReceiverStatus (v1)       Overall status information of the receiver (PolaRx2)",
  5912 => "TrackingStatus (v1)       Status of the tracking for all receiver channels (PolaRx2)",
  4013 => "ChannelStatus (v1)        Status of the tracking for all receiver channels",
  4014 => "ReceiverStatus (v2)       Overall status information of the receiver",
  4012 => "SatVisibility (v1)        Azimuth/elevation of visible satellites",
                                
  5902 => "ReceiverSetup (v1)        General information about the receiver set-up",
                                
  4015 => "Commands (v1)             Commands entered by the user",
  5936 => "Comment (v1)              Comment entered by the user",
  4040 => "BBSamples (v1)            Baseband samples"

  );
  
  return %sbfmessagetypes ;
  
}


sub defsbftimetype {

  # enumerate sbf messages type which contain receiver time stamps
  #
  #  1 : receiver time stamp
  #  2 : SIS time stamp
  #  3 : external event
  #  0 : other

  my %sbftimetype = (

  5889 => 1 ,   # "MeasEpoch (v1)            obsolete (PolaRx2)",
  5890 => 1 ,   # "ShortMeasEpoch (v1)       obsolete (PolaRx2)",
  5944 => 1 ,   # "GenMeasEpoch (v1)         measurement set of one epoch (PolaRx2)",

  4027 => 1 ,   # "MeasEpoch (v2)            measurement set of one epoch",
  4000 => 1 ,   # "MeasExtra (v1)            additional info such as observable variance",
  5922 => 1 ,   # "EndOfMeas (v1)            measurement epoch marker",
  
  4046 => 1 ,   # "IQCorr (v1)               Real and imaginary post-correlation values",
  4086 => 1 ,   # "ISMR                      Ionospheric scintillation monitor (ISMR) data",

  4109 => 1 ,   # "Meas3Ranges               Code, phase and CN0 measurements",
  4110 => 1 ,   # "Meas3CN0HiRes             Extension of Meas3Ranges containing fractional C/N0 values",
  4111 => 1 ,   # "Meas3Doppler              Extension of Meas3Ranges containing Doppler values",
  4112 => 1 ,   # "Meas3PP                   Extension of Meas3Ranges containing proprietary flags for data post-processing",
  4113 => 1 ,   # "Meas3MP                   Extension of Meas3Ranges containing multipath corrections applied by the receiver",
                                
  5895 => 2 ,   # "GPSRaw (v1)               GPS CA navigation frame (PolaRx2)",
  5947 => 2 ,   # "CNAVRaw (v1)              GPS L2C navigation frame (PolaRx2)",
  5898 => 2 ,   # "GEORaw (v1)               SBAS L1 navigation frame (PolaRx2)",

  4017 => 2 ,   # "GPSRawCA (v1)             GPS CA navigation frame",
  4018 => 2 ,   # "GPSRawL2C (v1)            GPS L2C navigation frame",
  4019 => 2 ,   # "GPSRawL5 (v1)             GPS L5 navigation frame",
  4221 => 2 ,   # "GPSRawL1                  GPS L1C navigation frame",
  4026 => 2 ,   # "GLORawCA (v1)             GLONASS CA navigation string",
  4022 => 2 ,   # "GALRawFNAV (v1)           Galileo F/NAV navigation page",
  4023 => 2 ,   # "GALRawINAV (v1)           Galileo I/NAV navigation page",
  4024 => 2 ,   # "GALRawCNAV (v1)           Galileo C/NAV navigation page",
  4020 => 2 ,   # "GEORawL1 (v1)             SBAS L1 navigation message",
  4021 => 2 ,   # "GEORawL5                  SBAS L5 navigation message",
  4047 => 2 ,   # "BDSRaw                    Beidou navigation page",
  4218 => 2 ,   # "BDSRawB1C                 BeiDou B1C navigation frame",
  4219 => 2 ,   # "BDSRawB2a                 BeiDou B2a navigation frame",
  4242 => 2 ,   # "BDSRawB2b                 BeiDou B2b navigation frame",
  4068 => 2,    # "QZSRawL5                  QZSS L5 navigation frame",
  4069 => 2 ,   # "QZSRawL6                  QZSS L6 navigation message",
  4227 => 2 ,   # "QZSRawL1C                 QZSS L1C navigation frame",
  4228 => 2 ,   # "QZSRawL1S                 QZSS L1S navigation message",
  4093 => 2 ,   # "NAVICRaw                  NavIC/IRNSS subframe",
                                
  5891 => 2 ,   # "GPSNav (v1)               GPS ephemeris and clock",
  5892 => 2 ,   # "GPSAlm (v1)               Almanac data for a GPS satellite",
  5893 => 2 ,   # "GPSIon (v1)               Ionosphere data from the GPS subframe 5",
  5894 => 2 ,   # "GPSUtc (v1)               GPS-UTC data from GPS subframe 5",
                                
  4004 => 2 ,   # "GLONav (v1)               GLONASS ephemeris and clock",
  4005 => 2 ,   # "GLOAlm (v1)               Almanac data for a GLONASS satellite",
  4036 => 2 ,   # "GLOTime (v1)              GLO-UTC, GLO-GPS and GLO-UT1 data",
                                
  4002 => 2 ,   # "GALNav (v1)               Galileo ephemeris, clock, health and BGD",
  4003 => 2 ,   # "GALAlm (v1)               Almanac data for a Galileo satellite",
  4030 => 2 ,   # "GALIon (v1)               NeQuick Ionosphere model parameters",
  4031 => 2 ,   # "GALUtc (v1)               GST-UTC data",
  4032 => 2 ,   # "GALGstGps (v1)            GST-GPS data",

  4081 => 2 ,   # "BDSNav                    BeiDou ephemeris and clock" ,
  4119 => 2 ,   # "BDSAlm                    Almanac data for a BeiDou satellite" ,
  4120 => 2 ,   # "BDSIon                    BeiDou Ionospheric delay model parameters" , 
  4121 => 2 ,   # "BDSUtc                    BDT-UTC data" , 

  4095 => 2 ,   # "QZSNav                    QZSS ephemeris and clock" ,
  4116 => 2 ,   # "QZSAlm                    Almanac data for a QZSS satellite" ,
                                
  5925 => 2 ,   # "GEOMT00 (v1)              MT00 : SBAS Dont use for safety applications",
  5926 => 2 ,   # "GEOPRNMask (v1)           MT01 : PRN Mask assignments",
  5927 => 2 ,   # "GEOFastCorr (v1)          MT02-05/24: Fast Corrections",
  5928 => 2 ,   # "GEOIntegrity (v1)         MT06 : Integrity information",
  5929 => 2 ,   # "GEOFastCorrDegr(v1)       MT07 : Fast correction degradation factors",
  5896 => 2 ,   # "GEONav (v1)               MT09 : SBAS navigation message",
  5930 => 2 ,   # "GEODegrFactors (v1)       MT10 : Degradation factors",
  5918 => 2 ,   # "GEONetworkTime (v1)       MT12 : SBAS Network Time/UTC offset parameters",
  5897 => 2 ,   # "GEOAlm (v1)               MT17 : SBAS satellite almanac",
  5931 => 2 ,   # "GEOIGPMask (v1)           MT18 : Ionospheric grid point mask",
  5932 => 2 ,   # "GEOLongTermCor (v1)       MT24/25 : Long term satellite error corrections",
  5933 => 2 ,   # "GEOIonoDelay (v1)         MT26 : Ionospheric delay corrections",
  5917 => 2 ,   # "GEOServiceLevel(v1)       MT27 : SBAS Service Message",
  5934 => 2 ,   # "GEOClockEphCovMatrix(v1)  MT28 : Clock-Ephemeris Covariance Matrix",
                                
  5903 => 1 ,   # "PVTCartesian (v1)         PVT in Cartesian coordinates (PolaRx2)",
  5904 => 1 ,   # "PVTGeodetic (v1)          PVT in geodetic coordinates (PolaRx2)",
  5909 => 1 ,   # "DOP (v1)                  Dilution of precision (PolaRx2)",
  5910 => 1 ,   # "PVTResiduals (v1)         Measurement residuals (PolaRx2)",
  5915 => 1 ,   # "RAIMStatistics (v1)       Integrity statistics (PolaRx2)",
  4006 => 1 ,   # "PVTCartesian (v2)         Position, velocity, and time in Cartesian coordinates",
  4007 => 1 ,   # "PVTGeodetic (v2)          Position, velocity, and time in geodetic coordinates",
  5905 => 1 ,   # "PosCovCartesian(v1)       Position covariance matrix (X,Y,Z)",
  5906 => 1 ,   # "PosCovGeodetic (v1)       Position covariance matrix (Lat,Lon,Alt)",
  5907 => 1 ,   # "VelCovCartesian(v1)       Velocity covariance matrix (X,Y,Z)",
  5908 => 1 ,   # "VelCovGeodetic (v1)       Velocity covariance matrix (North,East,Up)",
  4001 => 1 ,   # "DOP (v2)                  Dilution of precision",
  4044 => 1 ,   # "PosCart (v1)              Position, variance and baseline in Cartesian coordinates",
  4008 => 1 ,   # "PVTSatCartesian(v1)       Satellite positions",
  4009 => 1 ,   # "PVTResiduals (v2)         Measurement residuals",
  4011 => 1 ,   # "RAIMStatistics (v2)       Integrity statistics",
  5935 => 1 ,   # "GEOCorrections (v1)       Orbit, Clock and pseudoranges SBAS corrections",
  4043 => 1 ,   # "BaseVectorCart (v1)       XYZ relative position and velocity with respect to base(s)",
  4028 => 1 ,   # "BaseVectorGeod (v1)       ENU relative position and velocity with respect to base(s)",
  5921 => 1 ,   # "EndOfPVT (v1)             PVT epoch marker",
                                
  5914 => 1 ,   # "ReceiverTime (v1)         Current receiver and UTC time",
  5911 => 0 ,   # "xPPSOffset (v1)           Offset of the xPPS pulse with respect to GNSS time",
                                
  5924 => 3 ,   # "ExtEvent (v1)             Time at the instant of an external event",
  4037 => 3 ,   # "ExtEventPVTCartesian(v1)  Cartesian position at the instant of an event",
  4038 => 3 ,   # "ExtEventPVTGeodetic (v1)  Geodetic position at the instant of an event",
  4217 => 3 ,   # "ExtEventBaseVectGeod      ENU relative position with respect to base(s) at the instant of an event",
                                
  5919 => 1 ,   # "DiffCorrIn (v1)           Incoming RTCM or CMR message",
  5949 => 1 ,   # "BaseStation (v1)          Base station coordinates",
  4049 => 1 ,   # "RTCMDatum                 Datum information from the RTK service provider",
                                
  5913 => 0 ,   # "ReceiverStatus (v1)       Overall status information of the receiver (PolaRx2)",
  5912 => 0 ,   # "TrackingStatus (v1)       Status of the tracking for all receiver channels (PolaRx2)",
  4013 => 0 ,   # "ChannelStatus (v1)        Status of the tracking for all receiver channels",
  4014 => 0 ,   # "ReceiverStatus (v2)       Overall status information of the receiver",
  4012 => 0 ,   # "SatVisibility (v1)        Azimuth/elevation of visible satellites",
                                
  5902 => 0 ,   # "ReceiverSetup (v1)        General information about the receiver set-up",
                                
  4015 => 0 ,   # "Commands (v1)             Commands entered by the user",
  5936 => 0 ,   # "Comment (v1)              Comment entered by the user",
  4040 => 1 ,   # "BBSamples (v1)            Baseband samples"

  );
  
  return %sbftimetype ;
  
}

sub defsigtypes {

  # enumerate sbf signal types

  my %sbfsigtypes = (
        0 => 'GPS_L1CA' ,
        1 => 'GPS_L1P' ,
        2 => 'GPS_L2P' ,
        3 => 'GPS_L2C' ,
        4 => 'GPS_L5' ,
        5 => 'GPS_L1C' ,
        6 => 'QZS_L1CA' ,
        7 => 'QZS_L2C' , 
        8 => 'GLO_L1CA' ,
        9 => 'GLO_L1P' ,
       10 => 'GLO_L2P' ,
       11 => 'GLO_L2CA' , 
       12 => 'GLO_L3' ,
       13 => 'BDS_B1C' ,
       14 => 'BDS_B2a' ,
       15 => 'IRN_L5' ,
       16 => 'Reserved' ,
       17 => 'GAL_L1BC' ,
       18 => 'Reserved' ,
       19 => 'GAL_E6BC' ,
       20 => 'GAL_E5a' ,
       21 => 'GAL_E5b' ,
       22 => 'GAL_E5' ,
       23 => 'MSS_LBand' ,
       24 => 'GEO_L1' ,
       25 => 'GEO_L5' ,
       26 => 'QZS_L5' ,
       27 => 'QZS_L6' ,
       28 => 'BDS_B1I' ,
       29 => 'BDS_B2I' ,
       30 => 'BDS_B3I' ,
       31 => 'Reserved' ,
       32 => 'QZS_L1C' , 
       33 => 'QZS_L1S' , 
       34 => 'BDS_B2b' ,
       35 => 'Reserved' 
  );

  return %sbfsigtypes ;
}


sub defsatids {

  # enumerate sbf satellite ids

  my %sbfsatids=();
  
  for ( my $i=0; $i < 256; $i++) {

    my $sid='   ';
    my $svid=$i;
    if ( $svid <= 0 ) { 
       $sid='XXX';
    } elsif ( $svid <= 37 ) {
       # 1-37: PRN number of a GPS satellite Gnn (nn = SVID)
       $sid=sprintf("G%02d",$svid);
    } elsif ( $svid <= 61 ) {
       # 38-61: Slot number of a GLONASS satellite with an offset of 37 (R01 to R24) Rnn (nn = SVID-37)
       $sid=sprintf("R%02d",$svid-37);
    } elsif ( $svid <= 62 ) {  
       # 62: GLONASS satellite of which the slot number is not known NA
       $sid='RNA';
    } elsif ( $svid <= 68 ) {
       # 63-68: Slot number of a GLONASS satellite with an offset of 38 (R25 to R30) Rnn (nn = SVID-38)
    } elsif ( $svid <= 70 ) {
       $sid='???';
    } elsif ( $svid <= 106 ) {
       # 71-106: PRN number of a GALILEO satellite with an offset of 70 Enn (nn = SVID-70)
       $sid=sprintf("E%02d",$svid-70);
    } elsif ( $svid <= 119 ) {
       # 107-119: L-Band (MSS) satellite. Corresponding satellite name can be found in the LBandBeams block. 
       $sid=sprintf("M%02d",$svid-107);
    } elsif ( $svid <= 140 ) {
       # 120-140: PRN number of an SBAS satellite (S120 to S140) Snn (nn = SVID-100)
       $sid=sprintf("S%02d",$svid);
    } elsif ( $svid <= 180 ) {
       # 141-180: PRN number of a BeiDou satellite with an offset of 140 Cnn (nn = SVID-140)
       $sid=sprintf("C%02d",$svid-140);
    } elsif ( $svid <= 187 ) {
       # 181-187: PRN number of a QZSS satellite with an offset of 180 Jnn (nn = SVID-180)
       $sid=sprintf("J%02d",$svid-180);
    } elsif ( $svid <= 197) {
       # 191-197: PRN number of a NavIC/IRNSS satellite with an offset of 190 (I01 to I07) Inn (nn = SVID-190)
       $sid=sprintf("I%02d",$svid-190);
    } elsif ( $svid <= 215 ) {
       # 198-215: PRN number of an SBAS satellite with an offset of 57 (S141 to S158) Snn (nn = SVID-157)
       $sid=sprintf("S%02d",$svid-57);
    } elsif ( $svid <= 222 ) {
       # 216-222: PRN number of a NavIC/IRNSS satellite with an offset of 208 (I08 to I14) Inn (nn = SVID-208)
       $sid=sprintf("I%02d",$svid-208);
    } elsif ( $svid <= 245 ) {
       # 223-245: PRN number of a BeiDou satellite with an offset of 182 (C41 to C63)
       $sid=sprintf("C%02d",$svid-182);
    }
    $sbfsatids{$svid}=$sid; 
  }

  return %sbfsatids;
}