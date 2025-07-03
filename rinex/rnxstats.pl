#!/usr/bin/perl -w
#
#   rnxstats
#   --------
#   This script does stats on RINEX version 2 and 3 files.
#
#   For help:
#       rnxstats -?
#
#   Created:   9 September 2011 by Hans van der Marel
#   Modified: 11 February 2012 by Hans van der Marel
#                - Public version for testing
#             22 August 2019 by Hans van der Marel
#                - Reworked rnx2to3 into rnxstats
#                - Renamed required libraries
#                - Added statistics functionality
#             25 August 2019 by Hans van der Marel
#                - Added database functionality
#                - Added checks on double epochs and time order
#             10 October 2019 by Hans van der Marel
#                - Major overhaul database output, with many new options,
#                  summary, incomplete/missing, file index, ...  
#             14 October 2019 by Hans van der Marel
#                - First release version 
#             16 October 2019 by Hans van der Marel
#                - Added side by side index (eg. 10 and 30 sec), make this
#                  default and have the original index as option
#             22 October 2019 by Hans van der Marel
#                - Get default interval from rinex header
#                - Added warning for out of sync and duplicate epochs to db
#              3 January 2020 by Hans van der Marel
#                - Small improvements to print output
#             19 May 2020 by Hans van der Marel
#                - With -x option, warning field displays a message on number of ingestions
#                - fixed bug on printing negative latency values (fmtLatency)
#             28 May 2020 by Hans van der Marel
#                - Added extra field to database format for latency based on file change date
#             31 Oct 2024 by Hans van der Marel
#                - round epoch to whole second and epochtimes to min-interval
#                - changed min-interval to 0.05 (for u-blox receivers)
#              7 Nov 2024 by Hans van der Marel
#                - use time() in computation of $clatency
#             10 Nov 2024 by Hans van der Marel
#                - print information on data gaps with -p option
#              3 Jul 2025 by Hans van der Marel
#                - use librnxio package instead of require
#                - added use strict and a few missing declarations
#                - added Apache 2.0 license notice
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
use Time::Local ('timegm','timegm_nocheck');
use Fcntl ':flock'; # import LOCK_* constants
use lib dirname (__FILE__);

use librnxio qw( ReadRnxId ReadRnxHdr ScanRnxHdr ReadRnx2Data ReadRnx3Data ); 

use strict;
use warnings;

$VERSION = 20250703;

# Process the options

my %Config = (
     append      =>  0 
); 

#Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
my $Result = GetOptions( \%Config,
                      qw(
                        help|?|h
                        exclude|e=s
                        include|i=s
                        dbfile|b=s
                        append|a
                        list|l:s
                        print|p
                        satid|s
                        verbose|v
                      ) );
$Config{help} = 1 if ( ! $Result || !  ( scalar @ARGV || exists($Config{list}) ) );

if( $Config{help} ) {
    Syntax();
    exit();
}

# Set default for list option (if present)
if ( exists($Config{list})  && ( $Config{list} =~ m/^$/ ) ) {
  $Config{list}='s';
} 


# Get all the filenames

my @files=();
if ( scalar @ARGV ) {
  # Process the files on the command line
  # The original file is renamed to <file>.orig 
  foreach my $file ( @ARGV ) {
    # print STDERR "$file\n";
    my @exp=glob($file);
    @exp=sort(@exp);
    @exp= grep(!/$Config{exclude}/, @exp) if ($Config{exclude});
    @exp= grep(/$Config{include}/, @exp) if ($Config{include});
    push @files,@exp;
  }
} elsif ( !$Config{dbfile} ) {
  # Read from standard input
  push @files,"-";
}

# Process the rinex file(s)

my $numfiles=0;
my %dbnew=();

foreach my $inputfile ( @files ) {
  # parse the rinex files and get summary results
  my $sumline;
  eval {
    $sumline=statrnx($inputfile);
  };
  if ($@) {
    print STDERR "$inputfile throws an exception, continue with next ...\n";
    next;
  }
  #  Make key $filekey 
  my $filekey=basename($inputfile);
  if ( $inputfile =~ /........._._\d\d\d\d\d\d\d\d\d\d\d_\d\d._\d\d._..\.(crx|rnx)(|\.gz)$/ ) {
    # RINEX3 observation file
    my ($sta,$ddccc,$year,$doy,$hour,$min,$period,$int) = ( $inputfile =~ /(....)(.....)_._(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)_(\d\d.)_(\d\d.)_..\.(crx|rnx)(|\.gz)$/ );
    #$filekey =~ s/_MO\.crx\.gz//i  ;    
    #$filekey =~ s/_R_/_/i;
    $filekey=sprintf("%4s%5s_%4d%03d%02d%02d_%3s_%3s",uc($sta),$ddccc,$year,$doy,$hour,$min,$period,$int);
  } elsif ( $inputfile =~ /....\d\d\d.(|\d\d)\.\d\d[doDO](|\.z|\.Z|\.gz)$/ ) {
     # RINEX2 observation file
     my ($sta,$doy,$sessid,$yr) = ( $inputfile =~ /(....)(\d\d\d)(.|.\d\d)\.(\d\d)[doDO](|\.z|\.Z|\.gz)$/ );
     $sta=uc($sta);
     my $ddccc="00XXX";
     my $year=$yr+2000; $year=$yr+1900 if ( $yr > 80);
     my $hour=undef;
     my $min=undef;
     my $period="XXX";
     if ( $sessid =~ /^[a-x]\d\d$/i ) {
        $hour=ord(substr(lc($sessid),0,1))-ord("a");
        $min=substr($sessid,1);
        $period="15M";
     } elsif ( $sessid =~ /^[a-x]$/i ) {
        $hour=ord(lc($sessid))-ord("a");
        $min=0;
        $period="01H";
     } elsif ( $sessid =~ /^0$/ ) {
        $period="01D";
        $hour=0;
        $min=0;
     }
     my @res=split(/,/,$sumline);
     my $int=sprintf("%02dS",$res[3]);
     $filekey=sprintf("%4s%5s_%4d%03d%02d%02d_%3s_%3s",uc($sta),$ddccc,$year,$doy,$hour,$min,$period,$int);
  } else {
    $filekey=basename($inputfile);
  }       
  # Print the summary
  if ($numfiles == 0) {
    #print "$hdrsum\n";
    print "__station,______date,___start,_____end,_intv,_nepo,_avsat,__G__,__R__,__E__,__C__,__J__,__I__,__S__,nsat,_G,_R,_E,_C,_J,_I,_S,filename,latency,ingest,warnings\n";
  }
  print substr($filekey,0,9).",$sumline\n";
  #  Store the summary line in a hash %dbnew
  $dbnew{$filekey}=$sumline;
  $numfiles++;
}


# Database operations

my %db=();
my %dbcount=();

if ( $Config{dbfile} && $numfiles > 0 ) {

  # Update the database file with the new results
  # Two modes:
  # - update the database
  # - append mode

  my $dbfile=$Config{dbfile};  
  my $dbread=0;
  if ( $Config{append} ) {
    # open for appending only
    open(DB, ">>$dbfile")  or die "can't open $dbfile for appending: $!";
  } else {
    if (-e $dbfile ) {
      # file exists, open for read-write (and later read, rewind, and write updates)
      open(DB, "+<$dbfile")  or die "can't open $dbfile for read/writing: $!";
      $dbread=1;
    } else {
      # file does not yet exist, open write only
      open(DB, ">$dbfile")  or die "can't open $dbfile for writing: $!";
    }
  }
  # lock file 
  unless (flock(DB,LOCK_EX|LOCK_NB)) {
    warn "can't immediately write-lock the file ($!), blocking ...";
    unless (flock(DB,LOCK_EX)) {
      die "can't get write-lock on file: $!";
    }
  }
  if ( $dbread ) {
    # read older contents of database and update
    while (<DB>) {
      chomp;
      my ($key,$values)=split("=>");
      $db{$key}=$values;      
    }
    for my $key (keys(%dbnew)) {
      $db{$key}=$dbnew{$key};
    }
    seek(DB,0,0) or die "can't rewind $dbfile: $!";  
    for my $bfile (sort(keys(%db))) {
      print DB "$bfile=>$db{$bfile}\n";
    }
    truncate(DB,tell(DB)) or die "can't truncate $dbfile: $!";
  } else {
    # append results to existing database (or create initial database)
    for my $bfile (sort(keys(%dbnew))) {
      print DB "$bfile=>$dbnew{$bfile}\n";
    }   
    %db=%dbnew;   # for later listing...
  }
  # unlock and close
  flock(DB,LOCK_UN);
  close(DB);
} 

if ( $Config{dbfile} && exists($Config{list}) ) {

  # List database contents

  if ( $numfiles == 0 ) {

    # Read database file (if the database has been update/appended, we already have the information)

    my $dbfile=$Config{dbfile};  
    if ( -e $dbfile ) {
      open(DB, "$dbfile")  or die "can't open $dbfile for reading: $!";
      # lock file 
      unless (flock(DB,LOCK_SH|LOCK_NB)) {
        warn "can't immediately read-lock the file ($!), blocking ...";
        unless (flock(DB,LOCK_SH)) {
          die "can't get read-lock on file: $!";
        }
      }
      while (<DB>) {
        chomp;
        my ($key,$values)=split("=>");
        $db{$key}=$values;      
        # count the number of entries (new)
        if ( !exists($dbcount{$key}) ) {
           $dbcount{$key}=0;
        }
        $dbcount{$key}++;
      }
      flock(DB,LOCK_UN);
      close(DB);
    }
  }

  # Print the database contents

  if ( $Config{list} =~ m/[xse]/i ) {  
    printdb(%db);
  }
  if ( $Config{list} =~ m/[iq]/i ) {  
    if ( $Config{list} =~ m/1/i ) {  
      printindex(%db);
    } else {
      printindex2(%db);
    }
  }
  
}

exit;


sub Syntax{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# ); $Script =~ s#\.pl$##;
    my $Line = "-" x length( $Script );
    print STDERR << "EOT";
$Script                                            (Version: $VERSION)
$Line
Statistics for RINEX version 2 and version 3 observation files. The syntax
for simple scanning of files is

    $Script [-p] [-s] [-v] [-e <Pattern>] [-i <Pattern>] RINEX_observation_file(s) 
    
    $Script [-p] [-s] [-v] < inputfile   
    cat inputfile | $Script [-p] [-s] [-v][-options] 
    zcat inputfile | crx2rnx | $Script [-p] [-s] [-v] 

Rinex observation files may be (Hatanaka) compressed. If no RINEX observation 
file(s) are given on the command line, and no database operations are planned,
the script reads from the standard input.
The extended syntax for data base operations is

    $Script -b <dbfile> [-a] [-l] [-v] [-e <Pattern>] [-i <Pattern>] 
                                                      RINEX_observation_file(s)
    $Script -b <dbfile> -l [sxe] [-e <Pattern>] [-i <Pattern>] [-v]
    $Script -b <dbfile> -l [iqr1] [-e <Pattern>] [-i <Pattern>] [-v]

The first syntac is used to update the database, the second to list the content 
of the database, and third to produce an index listing.
Available options are  

    -b <dbfile>.....Database file to update/read
    -a .............Append to database file (the full db is not read)
    -l [sxeiqr1]....List database contents (option can be combined) 
        -l s          Only summary table (default for -l)
        -l x          Include output per file
        -l e          Include overview of missing and incomplete files
        -l i          Index with file latency
        -l q          Index with percentage of data (overrides i)
        -l r          Print index in reverse order (needs i or q)   
        -l 1          Print index in one column mode (needs i or q)    
    -e <pattern>....Pattern to exclude rinex input files/db-entries (optional).
    -i <pattern>....Pattern to include rinex input files/db-entries (optional).
    -p .............Print extended information for each rinex input file
    -s .............Print a list of satellites for each rinex input file
    -v .............Verbose output
    -?|h|help.......This help.

Wildcard specifiers are allowed on the command line for the rinex files.
 
(c) 2011-2025 by Hans van der Marel, Delft University of Technology.
EOT

}

sub statrnx{

  # Analyze RINEX file and compute statistics
  # Usuage
  #
  #   statrnx($inputfile);
  #
  
  #  This function returns a summary line with CSV values:
  #       0   4-letter abbreviation
  #    1..3   date, start and stop time
  #       4   measurement interval and duration
  #    5..7   number of epochs, missing epochs at start/end and in-between, percentage of epochs
  #   8..11   number of satellites, total, and per system
  #  12..15   average number of satellites per epoch, total, and per system
  #  20..22   filename,filesize and modification time of the file
  

  my ($inputfile)=@_;

  # Open the RINEX observation files for reading and writing

  my ($fhin);

  if ($inputfile ne "-" ) {
  
    my $xfile=$inputfile;
    # print "$inputfile\n";
    if ( $inputfile =~ /(\.crx\.gz|\.\d\dd\.Z)$/i ) {
       $xfile="gzip -d -c $inputfile | crx2rnx - |";
    } elsif ( $inputfile =~ /(\.Z|\.gz)$/i ) {
       $xfile="gzip -d -c $inputfile |";
    } elsif ( $inputfile =~ /(\.crx|\.\d\dd)$/i ) {
       $xfile="crx2rnx - $inputfile |";
    }

    # print "$xfile\n";
  
    open($fhin, "$xfile") or die "can't open $inputfile: $!";

  } else {
    # read from STDIN 
    $fhin=*STDIN;
  }
  
  binmode($fhin);

  # Read the RINEX ID line 

  my ($versin,$mixedfile,$idrec)=ReadRnxId($fhin,"O");
     
  # Read RINEX header

  my $rnxheaderin=ReadRnxHdr($fhin);

  # Scan the RINEX header lines to get receiver and observation type info

  my ($receivertype,$obsid3,$obsid2)=ScanRnxHdr($rnxheaderin);

  # Get epcoh interval from the header

  my $epochinterval=9999999999;
  foreach my $line ( @$rnxheaderin)  {
     my $headid=uc(substr($line,60));
     if ( $headid =~ /^INTERVAL/ ) {
       # get data interval
       ( $epochinterval ) = ( $line =~ /^\s*(\d+)/ );
     }
  }

  # Print (optionally)

  if ( $Config{print} ) {
    print "Rinex file name: $inputfile\n";
    print "Receiver type:  $receivertype\n";
    print "Rinex version:  $versin\n";
    print "Rinex-3 observation types:  \n";
    foreach my $sysid (keys(%{$obsid3})) {
       my @obsid3list=@{$obsid3->{$sysid}};
       my $nobstyp3=scalar(@obsid3list);
       printf("   %1s  %3d  %s \n",$sysid,$nobstyp3,join(" ",@obsid3list));      
    }
    my $nobstyp2=scalar(@$obsid2);
    print "Rinex-2 observation types:  $nobstyp2  -> ".join("   ",@{$obsid2})."\n" if ( $nobstyp2 > 0);
  }
  # Initialize the sums and statistics
  
  my $numepochs=0;
  my $numobs=0;
  my $numskipped=0;
  my $firstepoch=undef;
  my $lastepoch=undef;
  my $previousepochtime=undef;
  my $mininterval=0.050;

  my %satcountbysys;
  foreach my $sysid (split(//,"GRECJIS")) {
     $satcountbysys{$sysid}=0;
  }
  my %obscountbysat;

  # Parse and convert the observation data 
 
  my ($epoch,$epoflag,$clkoffset,$nsat);
  my $data=[];
  my $skipped=[];
  my $outofsync=0;
  my $obsid2upd=[];
  
  while ( ! eof($fhin) ) {
    # Read rinex data
    if ( $versin < 3.00 ) {
       ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped,$obsid2upd)=ReadRnx2Data($fhin,$obsid2);
       # In case of rinex-2 we HAVE TO check for changes in observation types, as the read routine depends on it.
       $obsid2=$obsid2upd if scalar(@$obsid2upd);
    } else {
       ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped)=ReadRnx3Data($fhin);
    }
    # Process skipped data (usually RINEX format mistakes)
    if (scalar(@{$skipped}) > 0) {
       my $numskip=scalar(@{$skipped});
       $numskipped+=$numskip;
       if ( $Config{verbose} ) {
          print "Skipped $numskip lines at epoch $epoch\n";
          for (my $i=0; $i < $numskip; $i++) {
             print "$skipped->[$i]\n";
          }
       }
    }
    # Process observations
    if ($epoflag <= 1) {
      # We have observation data  
      print "$epoch  $nsat\n" if $Config{verbose};
      # Check epoch values
      my @values=split(" ",$epoch);
      my $epochtime = timegm_nocheck($values[5],$values[4],$values[3],$values[2],$values[1]-1,$values[0]);
      # reformat epochtime(round to multiple of mininterval) and epoch (to nearest second)
      $epochtime = sprintf("%.0f",$epochtime/$mininterval)*$mininterval;
      my @values2 = gmtime($epochtime);
      $epoch=sprintf('%04d-%02d-%02d %02d:%02d:%02d',$values2[5]+1900,$values2[4]+1,$values2[3],$values2[2],$values2[1],$values2[0]);  # reformat epoch
      if ( defined($previousepochtime) ) {
         my $interval=$epochtime-$previousepochtime;
         if ( $interval < $mininterval ) {
            # duplicate epochs, or epochs are decreasing, ...
            print STDERR "Epoch time is decreasing or duplicate epochs, current ".gmtime($epochtime)." le last ".gmtime($previousepochtime)."\n";
            $outofsync++;
         } elsif ( $interval < $epochinterval) {
            $epochinterval=$interval;
         } elsif ( $interval > $epochinterval && $Config{print} ) {
            print STDERR "Data gap of ".sprintf("%d",$interval)." sec between ".$lastepoch." and ".$epoch.".\n";
         }
      }
      $previousepochtime=$epochtime;
      # Update global statistics
      $numepochs+=1;
      $numobs+=$nsat;
      $firstepoch=$epoch if ( !defined($firstepoch) );
      $lastepoch=$epoch;
      # Count the number of satellites per system and observations per satellite
      for (my $i=0; $i < $nsat;$i++) {
         my $orgrec=$data->[$i];
         my $sysid=uc(substr($orgrec,0,1));
         my $satid=uc(substr($orgrec,0,3));
         $satcountbysys{$sysid}+=1;
         $obscountbysat{$satid}=0 if ( !exists($obscountbysat{$satid}) );
         $obscountbysat{$satid}+=1;
         #my $lastobs=int((length($orgrec)-4)/16)+1;
         #print $fherr "$orgrec\n";
         #print $fherr "$lastobs\n";
         #$orgrec.="  ";
         # foreach my $iold (@{$obsidx->{$sysid}}) {
         #   #print $fherr "--> $i $inew  $iold \n";
         #   if ( ( $iold != $nan ) && ( $iold <= $lastobs ) ) {
         #   }
         # }                                                                                            
      }                                                                                
      #$data=ReorderRnxData($nsat,$data,$colidx);
    } elsif ( $epoflag == 4) {
      # Process new header data, can possibly contain observation type info
    }
  }

  # Close the RINEX observation files

  close($fhin) or die "can't close $inputfile: $!";

  # Postprocess start, stop time and interval
  
  my $yyyymmdd=substr($firstepoch,0,10); $yyyymmdd =~ s/ /-/g;
  $firstepoch=substr($firstepoch,11,8); $firstepoch =~ s/ /:/g;
  $lastepoch=substr($lastepoch,11,8); $lastepoch =~ s/ /:/g;
  $epochinterval=int($epochinterval/$mininterval)*$mininterval;

#  my $mtime=(stat($inputfile))[9];
  my ($mtime,$ctime)=(stat($inputfile))[9,10];
  $ctime=time();
  my $latency=$mtime-$previousepochtime; 
  my $clatency=$ctime-$previousepochtime;

  # Print stats
  
  my $avsats=$numobs/$numepochs;
  my $numsats=keys(%obscountbysat);
  my %numsatbysys;
  foreach my $sysid (split(//,"GRECJIS")) {
     $numsatbysys{$sysid}=0;      
  }
  foreach my $satid (sort(keys(%obscountbysat))) {
     my $sysid=substr($satid,0,1);
     $numsatbysys{$sysid}+=1;
  }
    
  if ( $Config{print} ) {
    print "Number of epochs: $numepochs\n";
    print "Number of satellites: $numsats\n";
    print "Average number of satellites per epoch:  $avsats\n";
    print "Number of satellites and average per epoch for each system:\n";

    foreach my $sysid (split(//,"GRECJIS")) {
       printf("   %1s  %3d  %6.3f \n",$sysid,$numsatbysys{$sysid},$satcountbysys{$sysid}/$numepochs) if ($numsatbysys{$sysid} > 0);      
    }
    
    print "Date: $yyyymmdd\n";
    print "First epoch: $firstepoch\n";
    print "Last epoch: $lastepoch\n";
    print "Measurement interval: $epochinterval [s]\n" ;

    print "Filename: $inputfile\n" ;
    print "File latency: $latency ($clatency) [s]\n";
  }
  
  if ( $Config{satid} ) {
    print "Number of observation epochs for each satellite:\n";
    foreach my $satid (sort(keys(%obscountbysat))) {
      printf("   %3s  %5d  \n",$satid,$obscountbysat{$satid});      
    }
  }

  my $warn="";
  if ( $numskipped > 0 ) {
     $warn.=sprintf("  ** skipped %d lines **",$numskipped); 
  }
  if ( $outofsync > 0 ) {
     $warn.=sprintf("  ** %d duplicate epoch(s) or out of sync **",$outofsync); 
  }
  my $sum="";
  { 
    no warnings 'uninitialized'; 
    $sum=sprintf("%s,%s,%s,%5.1f,%5d,%6.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%4d,%2d,%2d,%2d,%2d,%2d,%2d,%2d,%s,%.1f,%.1f,%s",
      $yyyymmdd,$firstepoch,$lastepoch,$epochinterval,
      $numepochs,
      $avsats,
      $satcountbysys{G}/$numepochs,$satcountbysys{R}/$numepochs,$satcountbysys{E}/$numepochs,$satcountbysys{C}/$numepochs,$satcountbysys{J}/$numepochs,$satcountbysys{I}/$numepochs,$satcountbysys{S}/$numepochs,
      $numsats,
      $numsatbysys{G},$numsatbysys{R},$numsatbysys{E},$numsatbysys{C},$numsatbysys{J},$numsatbysys{I},$numsatbysys{S},
      basename($inputfile,""),$latency,$clatency,$warn);
  }

  return $sum;  #\%numsatbysys,\%satcountbysys);
    
}

sub printdb{

  my (%db)=@_;

  # sort and select database contents 

  my @exp=sort { $db{$a} cmp $db{$b} } keys %db;
  @exp= grep(!/$Config{exclude}/, @exp) if ($Config{exclude});
  @exp= grep(/$Config{include}/, @exp) if ($Config{include});

  if ( scalar(@exp) < 1 ) {
     print "No database entries found, maybe too restrictive include and/or exclude regex expressions...?\n";
     return; 
  }

  # make arrays with station name, filestart and file intervals

  my %stations=();
  my %filestarts=();
  my %fileintervals=();
  for my $key (@exp) {
    my ($station,$filestart,$fileinterval)=split(/_/,$key,3);
    $stations{$station}++;
    $filestarts{$filestart}++;
    $fileintervals{$fileinterval}++;
  }

  # get the first and last entry, convert this to minutes, and set conversion strings %trintv 

  my $first=(split(/_/,$exp[0]))[1];
  my $last=(split(/_/,$exp[$#exp]))[1];

  my @values=( $first =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
  my $firstmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;
  @values=( $last =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
  my $lastmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;

  print "$first $last \n" if $Config{verbose};

  my %trintv; 
  $trintv{'D'}=24*60; 
  $trintv{'H'}=60; 
  $trintv{'M'}=1;
  $trintv{'S'}=1/60;
  
  # print the database contents, count incomplete and missing files
  
  #    for each interval {
  #       print title
  #       for each station {
  #          print table with summary line
  #       }
  #       print table of stations with summary lines
  #       print list of incomplete files
  #       print list of missing files
  #    }
 
  
  my $header="\n  station       date    first     last  intv  nepo avsat   G    R    E    C    J    I    S  nsat  G  R  E  C  J  I  S latency  ingest warnings\n";
  my $sepline= "_________ __________ ________ ________ _____ _____ _____ ____ ____ ____ ____ ____ ____ ____ ____ __ __ __ __ __ __ __ _______ _______\n";
  my $trailer= "                                       _____ _____ _____ ____ ____ ____ ____ ____ ____ ____ ____ __ __ __ __ __ __ __ _______ _______\n";
  
  for my $fileinterval (sort(keys(%fileintervals))) {
    
    # process file interval
    
    # printf("\n%s:\n\n",$fileinterval)  if ( $Config{list} =~ m/x/i );

    my ($duration,$interval)=split(/_/,$fileinterval);
    print "$duration $interval \n" if $Config{verbose};
    my @tmp=( $duration =~  m/(\d\d)(.)/ );
    my $fileintmin=$tmp[0]*$trintv{$tmp[1]};
    @tmp=( $interval =~  m/(\d\d)(.)/ );
    my $dataintsec=60*$tmp[0]*$trintv{$tmp[1]};
    my $expectedepochs=60*$fileintmin/$dataintsec;
    my $expectedfiles=scalar(keys(%filestarts));

    printf("\n\nRinex statistics, %s, %s - %s (%d files expected, with %d epochs per file):\n\n",$fileinterval,$first,$last,$expectedfiles,$expectedepochs) if ( $Config{list} =~ m/x/i );

    my @dbmissing=();
    my %dbincomplete=();
    my %dbstation=();
    
    for my $station (sort(keys(%stations))) {

      # process station 

      my $prevfilestartmin=$firstmin-$fileintmin;
      my $numfiles=0;
      my $missingfiles=0;
      my $incompletefiles=0;
      my $avnepo=0;
      my $avlatency=0;
      my $avclatency=0;
      my @avsats=(0,0,0,0,0,0,0,0);
      my @maxsats=(0,0,0,0,0,0,0,0);

      for my $filestart (sort(keys(%filestarts))) {
         # make file key and start date of the file in minutes
         my $key=join("_",$station,$filestart,$fileinterval);
         my @values=( $filestart =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
         my $filestartmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;
         # process file if in database         
         if ( exists($db{$key}) ) {
            # print header lines (only once per station)
            if ( ( $numfiles == 0) &&  ( $Config{list} =~ m/x/i ) ) {
              print $header;
              print $sepline;
            }      
            # check if files are missing, count the number of missing files, print dots, and add missing files to the list @dbmissing
            my $missing=sprintf("%.0f",($filestartmin-$prevfilestartmin-$fileintmin)/$fileintmin);
            if (  $missing > 0 ) {
               $missingfiles+=$missing;
               print ".........\n"  if ( $Config{list} =~ m/x/i );
               my ($sec,$min,$hour,$mday,$mon,$year,$wday,$doy) = gmtime(($prevfilestartmin+$fileintmin)*60);
               my $strmissing=sprintf("%9s_%4d%03d%02d%02d_%s",$station,$year+1900,$doy+1,$hour,$min,$fileinterval); 
               $strmissing .= sprintf("  (%04d-%02d-%02d %02d:%02d:%02d)",$year+1900,$mon+1,$mday,$hour,$min,$sec);
               if ( $missing > 1 ) {
                  ($sec,$min,$hour,$mday,$mon,$year,$wday,$doy) = gmtime(($filestartmin-$fileintmin)*60);
                  $strmissing .= sprintf(" ...  %9s_%4d%03d%02d%02d_%s",$station,$year+1900,$doy+1,$hour,$min,$fileinterval); 
                  ($sec,$min,$hour,$mday,$mon,$year,$wday,$doy) = gmtime($filestartmin*60-$dataintsec);
                  $strmissing .= sprintf("  (%04d-%02d-%02d %02d:%02d:%02d)",$year+1900,$mon+1,$mday,$hour,$min,$sec);
                  $strmissing .= sprintf("  -> %d files",$missing);
               }
               push @dbmissing, $strmissing
            }
            $prevfilestartmin=$filestartmin;
            # Increase file counter, update station summary statistics, and check for incomplete files
            $numfiles++;
            my @res=split(",",$db{$key},-1);
            if ( scalar(@res) == 24 ) {
               push @res,$res[23];
               $res[23]=$res[22];
            }
            $avnepo+=$res[4];            
            if ( $res[4] < $expectedepochs ) {
              $incompletefiles++;
              $dbincomplete{$key}=$db{$key};
            }
            $avlatency+=$res[22];            
            $avclatency+=$res[23];            
            for ( my $k=0;$k < 8;$k++) {
               $avsats[$k]+=$res[$k+5];
               $maxsats[$k]=$res[$k+13] if ($res[$k+13] > $maxsats[$k]); 
            }          
            my $latency=fmtLatency($res[22]);
            my $clatency=fmtLatency($res[23]);
            # print the file data
            #print "$station,$db{$key}\n";
            # print warning on ingests
            if ( exists($dbcount{$key}) && $dbcount{$key} > 1 ) {
              #$res[24]=$res[24]. "(" . $dbcount{$key} . " ingestions) ";
              $res[24]=$res[24]. "(" . $dbcount{$key} . "nd ingest) " if $dbcount{$key} == 2;
              $res[24]=$res[24]. "(" . $dbcount{$key} . "rd ingest) " if $dbcount{$key} == 3;
              $res[24]=$res[24]. "(" . $dbcount{$key} . "th ingest) " if $dbcount{$key} > 3;
            }
            printf("%9s %10s %8s %8s %5.1f %5d %5.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4d %2d %2d %2d %2d %2d %2d %2d %7s %7s %s\n",$station,@res[0..20],$latency,$clatency,$res[24]) if ( $Config{list} =~ m/x/i )
         }
      }
      if ( $numfiles > 0 ) {
        # check if files are missing, count the number of missing files, print dots, and add missing files to the list @dbmissing  
        my $filestartmin=$lastmin+$fileintmin;  
        my $missing=sprintf("%.0f",($filestartmin-$prevfilestartmin-$fileintmin)/$fileintmin);
        if (  $missing > 0 ) {
          $missingfiles+=$missing;
          print ".........\n" if ( $Config{list} =~ m/x/i );
               my ($sec,$min,$hour,$mday,$mon,$year,$wday,$doy) = gmtime(($prevfilestartmin+$fileintmin)*60);
               my $strmissing=sprintf("%9s_%4d%03d%02d%02d_%s",$station,$year+1900,$doy+1,$hour,$min,$fileinterval); 
               $strmissing .= sprintf("  (%04d-%02d-%02d %02d:%02d:%02d)",$year+1900,$mon+1,$mday,$hour,$min,$sec);
               if ( $missing > 1 ) {
                  ($sec,$min,$hour,$mday,$mon,$year,$wday,$doy) = gmtime(($filestartmin-$fileintmin)*60);
                  $strmissing .= sprintf(" ...  %9s_%4d%03d%02d%02d_%s",$station,$year+1900,$doy+1,$hour,$min,$fileinterval); 
                  ($sec,$min,$hour,$mday,$mon,$year,$wday,$doy) = gmtime($filestartmin*60-$dataintsec);
                  $strmissing .= sprintf("  (%04d-%02d-%02d %02d:%02d:%02d)",$year+1900,$mon+1,$mday,$hour,$min,$sec);
                  $strmissing .= sprintf("  -> %d files",$missing);
               }
               push @dbmissing, $strmissing
        }
        # print summary line
        print $trailer if ( $Config{list} =~ m/x/i );
        $avnepo=$avnepo/$numfiles;
        $avlatency=$avlatency/$numfiles;
        $avclatency=$avclatency/$numfiles;
        $avlatency=fmtLatency($avlatency);
        $avclatency=fmtLatency($avclatency);
        for ( my $k=0;$k < 8;$k++) {
          $avsats[$k]=$avsats[$k]/$numfiles;
        }          
        if ( $Config{list} =~ m/x/i ) {
          #printf("Files       %5d                      %5.1f %5.0f %5.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4d %2d %2d %2d %2d %2d %2d %2d %7s\n",$numfiles,$dataintsec,$avnepo,@avsats,@maxsats,$avlatency);
          printf("Files   %5d  (%5d incomplete)      %5.1f %5.0f %5.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4d %2d %2d %2d %2d %2d %2d %2d %7s %7s\n",$numfiles,$incompletefiles,$dataintsec,$avnepo,@avsats,@maxsats,$avlatency,$avclatency);
          printf("Missing %5d\n\n",$missingfiles);
        }
        # add summary line to %dbstation
        $dbstation{$station}=join(",",$numfiles,$incompletefiles,$missingfiles,$dataintsec,$avnepo,@avsats,@maxsats,$avlatency,$avclatency);
      }
    }

    # print station summary

    if ( $Config{list} =~ m/s/i ) {

      printf("\n\nStation summary, %s, %s - %s (%d files expected, with %d epochs per file):\n\n",$fileinterval,$first,$last,$expectedfiles,$expectedepochs);

      print "\n  station     #files  #incmpl #missing  intv  nepo avsat   G    R    E    C    J    I    S  nsat  G  R  E  C  J  I  S latency  ingest\n";
      print   "_________ __________ ________ ________ _____ _____ _____ ____ ____ ____ ____ ____ ____ ____ ____ __ __ __ __ __ __ __ _______ _______\n";
      for my $station (sort(keys(%dbstation))) {
        my @res=split(",",$dbstation{$station});
        printf("%9s %10d %8d %8d %5.1f %5d %5.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4d %2d %2d %2d %2d %2d %2d %2d %7s %7s\n",$station,@res[0..22]);
      }
    }


    # print overview of missing files

    printf("\n\nIncomplete and missing files, %s, %s - %s (%d files expected, with %d epochs per file):\n",$fileinterval,$first,$last,$expectedfiles,$expectedepochs) if ( $Config{list} =~ m/e/i );    

    if ( $Config{list} =~ m/e/i ) {
      if ( scalar(@dbmissing) > 0 ) {    
        # print missing files
        printf("\nMissing files:\n\n");
        foreach my $strmissing (@dbmissing) {
          printf("%s\n",$strmissing);
        } 
        printf("\n");
      } else {
        printf("\nNo missing files, hooray!\n");
      }    
    }


    # print overview of incomplete files

    if ( $Config{list} =~ m/e/i ) {

      if ( scalar(keys(%dbincomplete)) > 0 ) {    
        # print incomplete files
        printf("\nIncomplete files:\n\n");
        print $header;
        print $sepline;
        for my $key (sort(keys(%dbincomplete))) {
          my ($station)=split(/_/,$key);
          my @res=split(",",$dbincomplete{$key},-1);
          if ( scalar(@res) == 24 ) {
             push @res,$res[23];
             $res[23]=$res[22];
          }
          my $latency=fmtLatency($res[22]);
          my $clatency=fmtLatency($res[23]);
          #print "$station,$dbincomplete{$key}\n";          #print "$station,$dbincomplete{$key}\n";
          # print warning on ingests
          if ( exists($dbcount{$key}) && $dbcount{$key} > 1 ) {
            $res[24]=$res[24]. "(" . $dbcount{$key} . "nd ingest) " if $dbcount{$key} == 2;
            $res[24]=$res[24]. "(" . $dbcount{$key} . "rd ingest) " if $dbcount{$key} == 3;
            $res[24]=$res[24]. "(" . $dbcount{$key} . "th ingest) " if $dbcount{$key} > 3;
          }
          printf("%9s %10s %8s %8s %5.1f %5d %5.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4d %2d %2d %2d %2d %2d %2d %2d %7s %7s %s\n",$station,@res[0..20],$latency,$clatency,$res[24]);
        }
      } else {
        printf("All files are complete, hooray!\n");
      }
    }
    

  }
}


sub printindex{

  my (%db)=@_;

  # sort and select database contents 

  my @exp=sort { $db{$a} cmp $db{$b} } keys %db;
  @exp= grep(!/$Config{exclude}/, @exp) if ($Config{exclude});
  @exp= grep(/$Config{include}/, @exp) if ($Config{include});

  if ( scalar(@exp) < 1 ) {
     print "No database entries found, maybe too restrictive include and/or exclude regex expressions...?\n";
     return; 
  }

  # make arrays with station name, filestart and file intervals

  my %stations=();
  my %filestarts=();
  my %fileintervals=();
  for my $key (@exp) {
    my ($station,$filestart,$fileinterval)=split(/_/,$key,3);
    $stations{$station}++;
    $filestarts{$filestart}++;
    $fileintervals{$fileinterval}{$station}++;
  }

  # get the first and last entry, convert this to minutes, and set conversion strings %trintv 

  my $first=(split(/_/,$exp[0]))[1];
  my $last=(split(/_/,$exp[$#exp]))[1];

  my @values=( $first =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
  my $firstmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;
  @values=( $last =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
  my $lastmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;

  print "$first $last \n" if $Config{verbose};

  my %trintv; 
  $trintv{'D'}=24*60; 
  $trintv{'H'}=60; 
  $trintv{'M'}=1;
  $trintv{'S'}=1/60;
  
  # print the index 
  
  #    for each interval {
  #       print header
  #       for each filestart {
  #          print line with status (one line for all stations)
  #       }
  #    }
 
  
  for my $fileinterval (sort(keys(%fileintervals))) {
    
    # process file interval
    
    printf("\n%s:\n\n",$fileinterval)  if ( $Config{verbose} );

    my ($duration,$interval)=split(/_/,$fileinterval);
    print "$duration $interval \n" if $Config{verbose};
    my @tmp=( $duration =~  m/(\d\d)(.)/ );
    my $fileintmin=$tmp[0]*$trintv{$tmp[1]};
    @tmp=( $interval =~  m/(\d\d)(.)/ );
    my $dataintsec=60*$tmp[0]*$trintv{$tmp[1]};
    my $expectedepochs=60*$fileintmin/$dataintsec;

    my $prtinterval=60;
    if ( $duration =~ m/01D/ ) {
      $prtinterval=6*60;
    } elsif ( $duration =~ m/01H/ ) {
      $prtinterval=3*60;
    } else {
      $prtinterval=int(60*$fileintmin/15);
    }
    my $strinterval=sprintf(" 1=%02dM     ",int($prtinterval/60));
    if ( $Config{list} =~ m/q/i ) {
      $strinterval=" 1=10%     ";
    }
    
    #my @stationlist=sort(keys(%stations)); #sort(keys(%fileintervals{$fileinterval}));
    my @stationlist=sort(keys(%{$fileintervals{$fileinterval}}));

    # make header and initialize index line

    my @head=();
    my $index="";
    my $count=0;
    my %names=();

    $head[0]="********** ";
    $head[1]=sprintf(" %7s   ",$fileinterval);
    $head[2]="********** ";
    $head[3]=$strinterval;
    $head[4]="***********";

    for my $station (@stationlist) {
      for ( my $k=0; $k<4; $k++ ) {
        $head[$k]=$head[$k] . " " . uc(substr($station,$k,1)) ;
      }
      $head[4]=$head[4] . "**";
      $index=$index . ". ";
      $names{$station}=$count;
      $count++;
    }

    my $lastupdate=time();
    if ( $Config{dbfile} ) {
       $lastupdate=(stat($Config{dbfile}))[9];
    }

    my $date=gmtime($lastupdate);
    $head[4]=$head[4] . "  Last update: " . $date; 
    
    my ($minute,$hour,$year,$doy)=(gmtime($lastupdate))[1,2,5,7];
    $minute = $hour*60 + $minute;
    $minute = int($minute/$fileintmin)*$fileintmin;
    $hour = int($minute/60);
    $minute = $minute - $hour*60;
    $head[4]=$head[4] . "  (" . sprintf("%04d%03d%02d%02d",$year + 1900,$doy+1,$hour,$minute) . ")";
    #if ( $style =~ /daily/i ) { 
    #   $head[4]=$head[4] . "   (" . sprintf("%02d-%03d",$year % 100,$doy+1) . ")";
    #} elsif ( $style =~ /hourly/i ) {
    #   $head[4]=$head[4] . "   (" . sprintf("%02d-%03d-%s",$year % 100,$doy+1,chr($hour+ord("A"))) . ")";
    #} else { 
    #   $head[4]=$head[4] . "   (" . sprintf("%02d-%03d-%s%02d",$year % 100,$doy+1,chr($hour+ord("A")),int($minute/15)*15) . ")";
    #}
  
    print "\n\n$head[0]\n$head[1]\n$head[2]\n$head[3]\n$head[4]\n";
    
    # Print the index    

    my @sortedfilestarts;
    my $prevfilestartmin;
    if ( $Config{list} =~ m/r/i ) {
      # Order is reverted
      $prevfilestartmin=$lastmin+$fileintmin;
      @sortedfilestarts=sort( { $b cmp $a } keys(%filestarts));
    } else {
      $prevfilestartmin=$firstmin-$fileintmin;
      @sortedfilestarts=sort(keys(%filestarts));
    }
    for my $filestart (@sortedfilestarts) {

      # check if files are missing, count the number of missing files, print dots, and add missing files to the list @dbmissing
      my @values=( $filestart =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
      my $filestartmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;
      my $missing;
      if ( $Config{list} =~ m/r/i ) {
        $missing=sprintf("%.0f",($prevfilestartmin-$filestartmin-$fileintmin)/$fileintmin);      
      } else {
        $missing=sprintf("%.0f",($filestartmin-$prevfilestartmin-$fileintmin)/$fileintmin);
      }
      print ".........\n"  if ( $missing > 0 );
      $prevfilestartmin=$filestartmin;
      
      my $tmp=$index;
      foreach my $station (sort(keys(%names))) {
        # make file key and start date of the file in minutes
        my $key=join("_",$station,$filestart,$fileinterval);
        # process file if in database         
        if ( exists($db{$key}) ) {
           my @res=split(",",$db{$key},-1);
            if ( scalar(@res) == 24 ) {
               push @res,$res[23];
               $res[23]=$res[22];
            }
           # number of epochs and file latency
           my $nepo=$res[4];            
           my $latency=$res[23];
           my $size= int(10*$nepo/$expectedepochs);
           $size="x" if ($size > 9);
           my $age=int($latency/$prtinterval)+1;
           $age=0 if ($age < 0 );
           $age="*" if ($age > 9 );
           $count=$names{$station}*2;
           if ( $Config{list} =~ m/q/i ) {
             substr($tmp,$count,1)=$size;
           } else {
             substr($tmp,$count,1)=$age;
           }
        }
      }  
      print "$filestart $tmp\n";
    }
    print "\n";
  }

}

sub printindex2{

  # print index side by side

  my (%db)=@_;

  # sort and select database contents 

  my @exp=sort { $db{$a} cmp $db{$b} } keys %db;
  @exp= grep(!/$Config{exclude}/, @exp) if ($Config{exclude});
  @exp= grep(/$Config{include}/, @exp) if ($Config{include});

  if ( scalar(@exp) < 1 ) {
     print "No database entries found, maybe too restrictive include and/or exclude regex expressions...?\n";
     return; 
  }

  # make arrays with station name, filestart and file intervals

  my %stations=();
  my %filestarts=();
  my %fileintervals=();
  for my $key (@exp) {
    my ($station,$filestart,$fileinterval)=split(/_/,$key,3);
    $stations{$station}++;
    $filestarts{$filestart}++;
    $fileintervals{$fileinterval}{$station}++;
  }

  # get the first and last entry, convert this to minutes, and set conversion strings %trintv 

  my $first=(split(/_/,$exp[0]))[1];
  my $last=(split(/_/,$exp[$#exp]))[1];

  my @values=( $first =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
  my $firstmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;
  @values=( $last =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
  my $lastmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;

  print "$first $last \n" if $Config{verbose};

  my %trintv; 
  $trintv{'D'}=24*60; 
  $trintv{'H'}=60; 
  $trintv{'M'}=1;
  $trintv{'S'}=1/60;
  
  # initialize the header, default index line and file interval data
 
  my @head=();
  for ( my $k=0; $k<5; $k++ ) {
    $head[$k]="";
  }
  my %index=();

  my $fileintmin;
  my %expectedepochs=();
  my %prtinterval=();
  my %names=();

  # fill the header, default index line and file interval data
 
  for my $fileinterval (sort(keys(%fileintervals))) {
    
    # process file interval
    
    printf("\n%s:\n\n",$fileinterval)  if ( $Config{verbose} );

    my ($duration,$interval)=split(/_/,$fileinterval);
    print "$duration $interval \n" if $Config{verbose};
    my @tmp=( $duration =~  m/(\d\d)(.)/ );
    $fileintmin=$tmp[0]*$trintv{$tmp[1]};
    @tmp=( $interval =~  m/(\d\d)(.)/ );
    my $dataintsec=60*$tmp[0]*$trintv{$tmp[1]};
    $expectedepochs{$fileinterval}=60*$fileintmin/$dataintsec;

    $prtinterval{$fileinterval}=60;
    my $strinterval;
    if ( $duration =~ m/01D/ ) {
      $prtinterval{$fileinterval}=12*60*60;  # 12 hours
      $strinterval=sprintf(" 1=%02dH     ",int($prtinterval{$fileinterval}/(60*60)));
    } elsif ( $duration =~ m/01H/ ) {
      $prtinterval{$fileinterval}=3*60;      # 3 minutes
      $strinterval=sprintf(" 1=%02dM     ",int($prtinterval{$fileinterval}/60));
    } else {
      $prtinterval{$fileinterval}=int(60*$fileintmin/15);
      $strinterval=sprintf(" 1=%02dM     ",int($prtinterval{$fileinterval}/60));
    }
    if ( $Config{list} =~ m/q/i ) {
      $strinterval=" 1=10%     ";
    }
    
    #my @stationlist=sort(keys(%stations)); #sort(keys(%fileintervals{$fileinterval}));
    my @stationlist=sort(keys(%{$fileintervals{$fileinterval}}));

    # make header and initialize index line

    $head[0].="********** ";
    $head[1].=sprintf(" %7s   ",$fileinterval);
    $head[2].="********** ";
    $head[3].=$strinterval;
    $head[4].="***********";

    $index{$fileinterval}="";
    my $count=0;
    for my $station (@stationlist) {
      for ( my $k=0; $k<4; $k++ ) {
        $head[$k]=$head[$k] . " " . uc(substr($station,$k,1)) ;
      }
      $head[4]=$head[4] . "**";
      $index{$fileinterval}.=". ";
      $names{$fileinterval}{$station}=$count;
      $count++;
    }

    for ( my $k=0; $k<5; $k++ ) {
       $head[$k].="  " ;
    }

  }

  # Complete the header line with time stamp
  
  my $lastupdate=time();
  if ( $Config{dbfile} ) {
       $lastupdate=(stat($Config{dbfile}))[9];
  }

  my $date=gmtime($lastupdate);
  $head[4]=$head[4] . "Last update: " . $date; 
    
  my ($minute,$hour,$year,$doy)=(gmtime($lastupdate))[1,2,5,7];
  $minute = $hour*60 + $minute;
  $minute = int($minute/$fileintmin)*$fileintmin;
  $hour = int($minute/60);
  $minute = $minute - $hour*60;
  $head[4]=$head[4] . "  (" . sprintf("%04d%03d%02d%02d",$year + 1900,$doy+1,$hour,$minute) . ")";

  # print the index 
  
  #   print header
  #   for each filestart {
  #     print line with status (one line for stations for all possible data intervals)
  #   }

  my $expectedfiles=scalar(keys(%filestarts));

  printf("\nFile index %s - %s (%d files expected):\n",$first,$last,$expectedfiles);

  
  print "\n\n$head[0]\n$head[1]\n$head[2]\n$head[3]\n$head[4]\n";
    
  my @sortedfilestarts;
  my $prevfilestartmin;
  if ( $Config{list} =~ m/r/i ) {
    # Order is reverted
    $prevfilestartmin=$lastmin+$fileintmin;
    @sortedfilestarts=sort( { $b cmp $a } keys(%filestarts));
  } else {
    $prevfilestartmin=$firstmin-$fileintmin;
    @sortedfilestarts=sort(keys(%filestarts));
  }
  for my $filestart (@sortedfilestarts) {

    # check if files are missing, count the number of missing files, print dots, and add missing files to the list @dbmissing
    my @values=( $filestart =~ m/(\d\d\d\d)(\d\d\d)(\d\d)(\d\d)/ );
    my $filestartmin = timegm_nocheck(0,$values[3],$values[2],$values[1],0,$values[0])/60;
    my $missing;
    if ( $Config{list} =~ m/r/i ) {
      $missing=sprintf("%.0f",($prevfilestartmin-$filestartmin-$fileintmin)/$fileintmin);      
    } else {
      $missing=sprintf("%.0f",($filestartmin-$prevfilestartmin-$fileintmin)/$fileintmin);
    }
    $prevfilestartmin=$filestartmin;
    print ".........\n"  if ( $missing > 0 );

    my $line="";
    for my $fileinterval (sort(keys(%fileintervals))) {
      my $tmp=$index{$fileinterval};
      foreach my $station (sort(keys(%{$names{$fileinterval}}))) {
        # make file key and start date of the file in minutes
        my $key=join("_",$station,$filestart,$fileinterval);
        # process file if in database         
        if ( exists($db{$key}) ) {
           my @res=split(",",$db{$key},-1);
            if ( scalar(@res) == 24 ) {
               push @res,$res[23];
               $res[23]=$res[22];
            }
           # number of epochs and file latency
           my $nepo=$res[4];            
           my $latency=$res[23];
           my $size= int(10*$nepo/$expectedepochs{$fileinterval});
           $size="x" if ($size > 9);
           my $age=int($latency/$prtinterval{$fileinterval})+1;
           $age=0 if ($age < 0 );
           $age="*" if ($age > 9 );
           my $count=$names{$fileinterval}{$station}*2;
           if ( $Config{list} =~ m/q/i ) {
             substr($tmp,$count,1)=$size;
           } else {
             substr($tmp,$count,1)=$age;
           }
        }
      }
      $line.="$filestart $tmp ";
    }
    print "$line\n";
  }
  print "\n";

  for my $fileinterval (sort(keys(%fileintervals))) {
    if ( !( $fileinterval =~ m/(^\d\d)D/ ) ) {
      for ( my $k=0; $k<24; $k++ ) {
         printf("%s=%02d ",chr(ord("a")+$k),$k) ;
         print "\n" if ( $k==11 || $k==23 );
      }
      print "\n";
      last;
    }
  }


}

sub fmtLatency{
  my ($latency)=@_;
  
  my $latencymin=int(abs($latency)/60);
  my $latencysec=abs($latency) - $latencymin*60;
  my $latencysign="";
  $latencysign="-" if ( $latency < 0 );
  my $latencystr=sprintf("%s%.0f:%02.0f",$latencysign,$latencymin,$latencysec);
            
  return $latencystr;
}
              
# End of file is here 


