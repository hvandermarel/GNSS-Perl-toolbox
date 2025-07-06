#!/usr/bin/perl
#
# scanrnx32.pl
# ------------
# This script scans RINEX2/3 files and tabulates meta data.
#
# For help:
#     perl scanrnx32.pl -?
#
# Created   1 August 2000 by Hans van der Marel
# Modified  4 October 2002 by Hans van der Marel    
#          13 January 2008 by Hans van der Marel
#          16 December 2011 by Hans van der Marel
#          25 June 2015 by Hans van der Marel
#           6 January 2018 by Hans van der Marel
#             - support for hourly and high-rate data 
#             - patterns for RINEX3 files
#           5 July 2025 by Hans van der Marel
#            - checked with strict pragma
#            - added Apache 2.0 license notice
#
# Copyright 2003-2025 Hans van der Marel, Delft University of Technology.
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
use File::Basename;
use Time::Local 'timegm_nocheck';
use Getopt::Long;

use strict;
use warnings;

$VERSION = 20250705;

# -------------------------------------------------------------------------------
# Process input arguments and options
# -------------------------------------------------------------------------------

# Get command line arguments

my %Config = (
    verbose      =>  0 ,
    index        =>  1 ,
    csv          =>  0 ,
    quantity     =>  0 ,
    gap          => "b" ,
    meta         =>  0 ,
    sn           =>  0 ,
    crd          =>  0 ,
);  

Getopt::Long::Configure( "prefix_pattern=(-)" );
my $Result = GetOptions( \%Config,
                      qw(
                        index|i!
                        csv|x!
                        quantity|q=f
                        gap|g=s
                        meta|m!
                        sn|s!
                        crd|c!
                        verbose|v
                        help|?|h
                      ) );
$Config{help} = 1 if( ! $Result || ! scalar @ARGV );

if( $Config{help} )
{
    Syntax();
    exit();
}

my $debug=$Config{verbose};
my $idx=$Config{index};
my $csv=$Config{csv};
my $meta=$Config{meta};
my $crd=$Config{crd};
my $sn=$Config{sn};

# Expand the file names (if not done already by the shell)

my @allfiles=();
foreach my $argument (@ARGV) {
  push(@allfiles,glob($argument));
}

# -------------------------------------------------------------------------------
# Build index with filenames...
# -------------------------------------------------------------------------------
#
# Input is @allfiles, the result are the hashes %filename and %fileindex , with
# as key (sta4)(doy)(sessid)[(min)].(yr)

my @filelist;
my %fileindex=();
my %filename=();

# 1. Zipped RINEX2 files

@filelist = grep ( /\d\d\/\d\d\d\/....\d+.*\.zip$/ , grep( !(-d) , @allfiles));
foreach my $file (@filelist) {
  my ($year,$key) = ( $file =~ /(\d\d)\/\d\d\d\/(....\d+.*)\.zip$/ );
  $key=$key.".".$year;
  if ( !exists ($fileindex{$key}) ) {
     $fileindex{$key}=". . . ";
  } 
  $filename{$key}=$file;
}

# 2. RINEX2 naming convention (Observation, Navigation and Meteo files)

@filelist = grep ( /\d+.*\.\d\d[doDO](|\.Z|\.gz)$/ , grep( !(-d) , @allfiles));
foreach my $file (@filelist) {
  my ($key,$ext) = (basename($file) =~ /^(....\d+.*\.\d\d)([doDO])(|\.Z|\.gz)$/);
  $key=uc($key);
  if ( !exists ($fileindex{$key}) ) {
     $fileindex{$key}=". . . ";
  } 
  substr($fileindex{$key},0,1)=$ext;
  $filename{$key}=$file;
}

@filelist = grep ( /\d+.*\.\d\d[mMgG](|\.Z|\.gz)$/ , grep( !(-d) , @allfiles));
foreach my $file (@filelist) {
  my ($key,$ext) = (basename($file) =~ /^(....\d+.*\.\d\d)([mMgG])(|\.Z|\.gz)$/);
  $key=uc($key);
  if ( !exists ($fileindex{$key}) ) {
     $fileindex{$key}=". . . ";
  } 
  substr($fileindex{$key},2,1)=$ext;
}

@filelist = grep ( /\d+.*\.\d\d[nN](|\.Z|\.gz)$/ , grep( !(-d) , @allfiles));
foreach my $file (@filelist) {
  my ($key,$ext) = (basename($file) =~ /^(....\d+.*\.\d\d)([nN])(|\.Z|\.gz)$/);
  $key=uc($key);
  if ( !exists ($fileindex{$key}) ) {
     $fileindex{$key}=". . . ";
  } 
  substr($fileindex{$key},4,1)=$ext;
}

# 3. RINEX3 naming convention (Observation files only)

@filelist = grep ( /.*_._\d\d\d\d\d\d\d\d\d\d\d_\d\d._\d\d._..\.(crx|rnx)(|\.gz)$/ , grep( !(-d) , @allfiles));
foreach my $file (@filelist) {
  #print "$file\n";
  my ($sta,$yr,$doy,$hour,$min,$tp) = (basename($file) =~ /^(....)\d\d..._._\d\d(\d\d)(\d\d\d)(\d\d)(\d\d)_\d\d(.)_\d\d._..\.(crx|rnx)(|\.gz)$/);
  my $ext="3";
  my $sessid;
  if ( $tp =~ /D/i ) {
    $sessid=0;
  } elsif ( $tp =~ /H/i ) {
    $sessid=chr(ord("a")+$hour);
  } else { 
    $sessid=chr(ord("a")+$hour) . $min;
  }
  my $key=$sta . $doy . $sessid . "." . $yr;
  $key=uc($key);
  if ( !exists ($fileindex{$key}) ) {
     $fileindex{$key}=". . . ";
  } 
  substr($fileindex{$key},0,1)=$ext;
  $filename{$key}=$file;
}


# -------------------------------------------------------------------------------
# Build index with file latency and/or file size
# -------------------------------------------------------------------------------


# Move code from the two blocks below and create a hashtable with the data,
# that can later be printed in different format (seperating functionality from
# lay-out).


# -------------------------------------------------------------------------------
# Print file index (IGS style)
# -------------------------------------------------------------------------------

# Order is reverted, make this an option

$idx=0 if ($csv);

# Optionally print index table 

if ( $idx ) {

  my %names=();
  my %days=();
  my %sessids=();
  foreach my $key ( sort (keys(%fileindex))) {
    if ( exists($filename{$key}) ){
      my ($name,$doy,$sessid,$yr)= ($key =~ /^(....)(\d\d\d)(.*)\.(\d\d)$/);
      $name=uc($name);
      print "$name,$doy,$sessid,$yr\n" if ($debug);
      my $day=$yr."-".$doy."-".$sessid;
      push(@{ $names{$name} }, $day);
      push(@{ $days{$day} }, $name);
      $sessids{$sessid}=1;
    }
  }
  my $style="daily";
  foreach my $sessid (keys(%sessids)) {
     $style="hourly" if $sessid =~ /^[a-x]$/i;
     $style="hr" if $sessid =~ /^[a-x]\d\d$/i;
  }

  my @head=();
  my $fileinterval;
  my $prtinterval;
  if ( $style =~ /daily/i ) { 
     $head[0]="***** ";
     $head[1]=" DUT  ";
     $head[2]="***** ";
     $head[3]="      ";
     $head[4]="******";
     $fileinterval=24*3600;
     $prtinterval=24*3600;
  } elsif ( $style =~ /hourly/i ) {
     $head[0]="******  ";
     $head[1]=" DUT    ";
     $head[2]="******  ";
     $head[3]=" 1=03M  ";
     $head[4]="********";
     $fileinterval=3600;
     $prtinterval=180;
  } else {
     $head[0]="*******   ";
     $head[1]=" DUT      ";
     $head[2]="*******   ";
     $head[3]=" 1=01M    ";
     $head[4]="**********";
     $fileinterval=900;
     $prtinterval=60;
  }
  
  my $index="";
  my $count=0;
  foreach my $name (sort {uc($a) cmp uc($b)} (keys(%names)) ) {
    $head[0]=$head[0] . " " . uc(substr($name,0,1)) ;
    $head[1]=$head[1] . " " . uc(substr($name,1,1)) ;
    $head[2]=$head[2] . " " . uc(substr($name,2,1)) ;
    $head[3]=$head[3] . " " . uc(substr($name,3,1)) ;
    $head[4]=$head[4] . "**";
    $index=$index . ". ";
    $names{$name}=$count;
    $count++;
  }
  my $date=gmtime();
  $head[4]=$head[4] . " Last update: " . $date; 

  my ($minute,$hour,$year,$doy)=(gmtime())[1,2,5,7];
  if ( $style =~ /daily/i ) { 
     $head[4]=$head[4] . "   (" . sprintf("%02d-%03d",$year % 100,$doy+1) . ")";
  } elsif ( $style =~ /hourly/i ) {
     $head[4]=$head[4] . "   (" . sprintf("%02d-%03d-%s",$year % 100,$doy+1,chr($hour+ord("A"))) . ")";
  } else { 
     $head[4]=$head[4] . "   (" . sprintf("%02d-%03d-%s%02d",$year % 100,$doy+1,chr($hour+ord("A")),int($minute/15)*15) . ")";
  }
  
  print "$head[0]\n$head[1]\n$head[2]\n$head[3]\n$head[4]\n";

  #my $lastdoy=366;
  my $lastdoy=0;
  foreach my $day (sort { $b cmp $a }(keys(%days)) ) {
    my ($yr,$doy,$sessid)=split("-",$day);
    my ($hour, $minute, $daystr);
    my $tmp=$index;
    if ( $style =~ /hr/i ) {
      ($hour,$minute) = ( $sessid =~ /^(.)(\d\d)$/ );
      $hour=ord(lc($hour))-ord("a");
      $daystr=$day;
    } elsif ( $style =~ /hourly/i ) {
      $hour=ord(lc($sessid))-ord("a");
      $minute=0;
      $daystr=$day;
    } else {
      $daystr=substr($day,0,-2);
      $hour=0;
      $minute=0;
    }
    if ( $Config{gap} =~ /^f/i ) {
       #for ( my $i = $lastdoy+1; $i < $doy; $i++) {
       for ( my $i = $lastdoy-1; $i > $doy; $i--) {
          printf("%s-%03d %s\n",$yr,$i,$tmp);
       }
     } elsif ( $Config{gap} =~ /^b/i ) {
       #printf("\n") if ( $lastdoy+1 < $doy );
       printf("\n") if ( $lastdoy-1 > $doy );
    }
    $lastdoy=$doy;
    foreach my $name (@{ $days{$day} }  ) {
       my $key=$name.$doy.$sessid.".".$yr;
       my $count=$names{$name}*2;
       my $tfil = timegm_nocheck(0,$minute,$hour,$doy,0,$yr);
       my $age;
       my $size;
       if ( exists($filename{$key}) ){
          my $mfil;
          ($size,$mfil) = (stat($filename{$key}))[7,9];
          my $agesec=$mfil-$tfil-$fileinterval;
          $age=int(($mfil-$tfil-$fileinterval)/$prtinterval)+1;
          $age=0 if ($age < 0 );
          $age="*" if ($age > 9 );
          print "$tfil $mfil   $agesec  $age\n" if ($debug);
       } else {
          $age="?";
          $size=0;
       }
       if ( $Config{quantity} > 0 ) {
         my $size=int($size/($Config{quantity}*1024*1024));
         $size="*" if ($size > 9);
         substr($tmp,$count,1)=$size;
       } else {
         substr($tmp,$count,1)=$age;
       }
    }
    print "$daystr $tmp\n";
  }
  
}

# -------------------------------------------------------------------------------
# Print file index (transposed style)
# -------------------------------------------------------------------------------

# Optionally print CSV style of table (transpose of index table)

if ( $csv ) {

  my %names=();
  my %days=();
  my %yrs=();   
  foreach my $key ( sort (keys(%fileindex))) {
    if ( exists($filename{$key}) ){
      my ($name,$doy,$sessid,$yr)= ($key =~ /^(....)(\d\d\d)(.*)\.(\d\d)$/);
      $name=uc($name);
      print "$name,$doy,$sessid,$yr\n" if ($debug);
      my $day=$yr."-".$doy."-".$sessid;
      push(@{ $names{$name} }, $day);
      push(@{ $days{$day} }, $name);
      push(@{ $yrs{$yr} }, $name);
    }
  }

  my @head=();
  $head[0]="***** ";
  $head[1]=" DUT  ";
  $head[2]="***** ";
  $head[3]="      ";
  $head[4]="      ";
  $head[5]="      ";
  $head[6]="******";
  my $index="";

  my $count=0;
  my %daycount=();
  my $lastdoy=366;
  my $lastyr=99;
  foreach my $day (sort (keys(%days)) ) {
    my ($yr,$doy,$sessid)=split("-",$day);
    if ( $lastdoy+1 < $doy  || $lastyr < $yr ) {
      $head[0]=$head[0] . "  ";
      $head[1]=$head[1] . "  ";
      $head[2]=$head[2] . "  ";
      $head[3]=$head[3] . "  ";
      $head[4]=$head[4] . "  ";
      $head[5]=$head[5] . "  ";
      $head[6]=$head[6] . "**";
      $index=$index . "  ";
      $count++;
    }
    $lastdoy=$doy;
    $lastyr=$yr;
    $head[0]=$head[0] . " " . substr($yr,0,1) ;
    $head[1]=$head[1] . " " . substr($yr,1,1) ;
    $head[2]=$head[2] . " " . "-" ;
    $head[3]=$head[3] . " " . substr($doy,0,1) ;
    $head[4]=$head[4] . " " . substr($doy,1,1) ;
    $head[5]=$head[5] . " " . substr($doy,2,1) ;
    $head[6]=$head[6] . "**";
    $daycount{$day}=$count;
    $index=$index . ". ";
    $count++;
  }
  my $date=gmtime();
  $head[6]=$head[6] . " Last update: " . $date; 

  print "$head[0]\n$head[1]\n$head[2]\n$head[3]\n$head[4]\n$head[5]\n$head[6]\n";

  foreach my $name (sort {uc($a) cmp uc($b)} (keys(%names)) ) {
    my $tmp=$index;    
    foreach my $day (@{ $names{$name} }  ) {
       my ($yr,$doy,$sessid)=split("-",$day);
       my $key=$name.$doy.$sessid.".".$yr;
       my $count=$daycount{$day}*2;
       my $tfil = timegm_nocheck(0,0,0,$doy,0,$yr);
       my $age;
       my $size;
       if ( exists($filename{$key}) ){
          my $mfil;
          ($size,$mfil) = (stat($filename{$key}))[7,9];
          $age=$mfil-$tfil-24*3600;
          print "$tfil $mfil   $age\n" if ($debug);
          $age=int(($mfil-$tfil)/(24*3600));
          $age=1 if ($age < 1 );
          $age="*" if ($age > 9 );
       } else {
          $age="?";
          $size=0;
       }
       if ( $Config{quantity} > 0 ) {
         $size=int($size/($Config{quantity}*1024*1024));
         $size="*" if ($size > 9);
         substr($tmp,$count,1)=$size;
       } else {
         substr($tmp,$count,1)=$age;
       }
    }
    print "$name   $tmp\n";
  }

  @head=();
  $head[0]="      ";
  $head[1]="      ";
  $head[2]="******";
  $index="";

  $count=0;
  my %yrcount=();
  foreach my $yr (sort (keys(%yrs)) ) {
    $head[0]=$head[0] . " " . substr($yr,0,1) ;
    $head[1]=$head[1] . " " . substr($yr,1,1) ;
    $head[2]=$head[2] . "**";
    $yrcount{$yr}=$count;
    $index=$index . ". ";
    $count++;
  }

  print "\n\n$head[0]\n$head[1]\n$head[2]\n";

  foreach my $name (sort {uc($a) cmp uc($b)} (keys(%names)) ) {
    my $tmp=$index;    
    foreach my $day (@{ $names{$name} }  ) {
       my ($yr,$doy,$sessid)=split("-",$day);
       my $count=$yrcount{$yr}*2;
       my $ndays=substr($tmp,$count,1);
       if ( $ndays =~ m/\./ ) {
          $ndays=1;
       } elsif ( $ndays =~ m/[9*]/ ) {
          $ndays="*";
       } else {
          $ndays++;
       }
       substr($tmp,$count,1)=$ndays;
    }
    print "$name   $tmp\n";
  }
  
}

# -------------------------------------------------------------------------------
# Print table with meta data
# -------------------------------------------------------------------------------

# Optionally print meta data

if ( $meta ) {

  if ( $sn ) {

    #print "filename    types  markername          number    receiver type       s/n       version             antenna type         s/n         height\n";
    #print "----------- -----  ------------------- --------- ------------------- --------- ------------------- -------------------- --------- --------\n";
    print "filename    types  markername           markernumber         receiver type        s/n                  version              antenna type         s/n                   height\n";
    print "----------- -----  -------------------- -------------------- -------------------- -------------------- -------------------- -------------------- -------------------- -------\n";
    
  } else {
  
    print "filename    types  markername          number    receiver type       antenna type           height\n";
    print "----------- -----  ------------------- --------- ------------------- -------------------- --------\n";

  }
  
  foreach my $key ( sort (keys(%fileindex))) {

    my %rnxdata=();
    my $rnxsum=" ";
    if ( exists($filename{$key}) ){
      my $rnxfile=$filename{$key};
      if (-r $rnxfile ) {
        # $rnxfile="gzip -d -c $rnxfile |" if ( $rnxfile =~ /\.Z$/i );  
        if ( $rnxfile =~ /(\.Z|.\.gz)/i ) {
           #$rnxfile="gzip -d -c $rnxfile |";  
           $rnxfile="gzip -q -d -c  $rnxfile |";  
        } elsif ( $rnxfile =~ /\.zip$/i ) {
           my $zipfilelist=`unzip -qq -l $rnxfile | awk '{ print \$4}'`;
           my $k=0;
           my $rnxfileo="";
           foreach my $file (split(/\n/,$zipfilelist)) {
              #print "$file\n";
              if ( basename($file) =~ /^....\d+.*\.\d\d.$/ ) {              
                my ($key2,$ext) = (basename($file) =~ /^(....\d+.*\.\d\d)(.)$/);
                $rnxfileo = $file if ( $ext =~ /[dDoO]/ );
                if ( $key ne $key2 ) {
                  print STDERR "One files inside $rnxfile has a name $key2 different from key $key\n";
                }
                substr($fileindex{$key},$k,1)=$ext;
                $k++;
              }
           }
           if ( $k > 0 && $rnxfileo ne "" ) { 
           # my $rnxfileo=`unzip -qq -l $rnxfile | awk '{ print \$4}' | awk /\...[oO]/ `;
           $rnxfile="unzip -p $rnxfile $rnxfileo |";  
           }
        }
        ($rnxsum,%rnxdata) = &ReadRnx($rnxfile);
      }
    }

    print "$key $fileindex{$key} $rnxsum\n";
    if ($debug) {
      foreach my $rnxkey (keys(%rnxdata)) {
        print "  $rnxkey --> $rnxdata{$rnxkey}\n";
      }
    }
  }
}


exit;


# ----------------------------------------------------------------------------
# Subroutines

sub Syntax
{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print << "EOT";
$Script                                            (Version: $VERSION)
$Line
Extract meta data from one or more RINEX files .
Syntax: 
    $Script [-i] [-m] [-v] [-h|?] file-patterns

    -i[ndex]........IGS stye index (default yes), use -noi[ndex] to disable.
    -q[uantity] <m> Give the filesize in index in bins of <m> Mb instead of latency.  
    -x              CSV style of index.
    -m[eta].........Print meta data (default no). 
    -s[n]...........Print also serial and version numbers (default no).
    -c[rd]..........Print also a-priori coordinates (default no). 
    -v[erbose]......Verbose mode (extra debugging output). 
    -?|h|help.......This help.

    file-patterns...Input files (wildcards and csh style globbing allowed).

Examples:
  $Script 2002/???/*.*
  $Script -noi -m 2002/???/{delf,eijs}*.*

(c) 2000-2025 Hans van der Marel, Delft University of Technology.
EOT

}


sub ReadRnx{

  # Read RINEX observation file 

  my($rnxfile) = @_;
  my($rnxsum);
  my(%rnxdata);

  my(@fields);


  open(RNXFILE,"$rnxfile") ||  die ("Error opening $rnxfile\n");
  # $count=1; 
  my $markername=   "---                 ";
  my $markernumber= "---       ";
  my $antheight=    "-99.9999";
  my $recnum=       "---                 ";
  my $firmware=     "---                 ";
  my $rectype=      "---                 ";
  my $antnum=       "---                 ";
  my $anttype=      "---                 ";    
  my $aprpos=       " ";

  while (<RNXFILE>) {
    chop($_);
    last if ( /END OF HEADER/ );
    @fields=unpack("a60 a20",$_);
    $rnxdata{$fields[1]}="$fields[0]";
    if ($fields[1] =~ /MARKER NAME/ ) {
       $markername=$fields[0];
    } elsif ($fields[1] =~ /MARKER NUMBER/ ) {
       $markernumber=unpack("a20",$fields[0]); 
       $markernumber =~ s/\s+$//;
    } elsif ($fields[1] =~ /ANTENNA: DELTA H\/E\/N/ ) {
       $antheight=unpack("a14",$fields[0]); 
    } elsif ($fields[1] =~ /REC # \/ TYPE \/ VERS/ ) {
       ($recnum,$rectype,$firmware)=unpack("a20 a20 a20",$fields[0]); 
       $recnum =~ s/\s+$//;
    } elsif ($fields[1] =~ /ANT # \/ TYPE/ ) {
       ($antnum,$anttype)=unpack("a20 a20",$fields[0]); 
       $antnum =~ s/\s+$//;
    } elsif ($fields[1] =~ /APPROX POSITION XYZ/ ) { 
       $aprpos=unpack("a42",$fields[0]);                  
    }

    if ( $sn ) {
       #$rnxsum=sprintf("%-20.20s%-9s %-20.20s%-9s %-20.20s%-20.20s %-10s%8.4f",$markername,$markernumber,$rectype,$recnum,$firmware,$anttype,$antnum,$antheight);        
       $rnxsum=sprintf("%-20.20s %-20.20s %-20.20s %-20.20s %-20.20s %-20.20s %-20.20s%8.4f",$markername,$markernumber,$rectype,$recnum,$firmware,$anttype,$antnum,$antheight);        
    } else {
       #$rnxsum=pack("a20 a10 a20 a20 a-9",$markername,$markernumber,$rectype,$anttype,$antheight);
       $rnxsum=sprintf("%-20.20s%-10.10s%-20.20s%-20.20s%9.4f",$markername,$markernumber,$rectype,$anttype,$antheight);    
    }

    if ($crd) {
       #$rnxsum=pack("a20 a10 a20 a20 a14 a42",$markername,$markernumber,$rectype,$anttype,$antheight,$aprpos);
       $rnxsum=$rnxsum . $aprpos;
    }

  } # End of While
  close(RNXFILE);   #  if !( $rnxfile =~ /gzip/ );


  return $rnxsum,%rnxdata;

}

# End of file is here 


