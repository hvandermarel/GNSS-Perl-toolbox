#!/usr/bin/perl -w
#
# gpsdircmp.pl
# ------------
# This script compares two dirctories with gps files and list the files 
# (and auxiliary information) side by side
#
# For help:
#     gpsdircmp -?
#
# Created:   9 September 2006 by Hans van der Marel
# Modified:  5 July 2025 by Hans van der Marel
#              - renamed gpscmp.pl to gpsdircmp.pl
#              - replaced functions by libgpstime.pm
#              - checked with strict pragma
#              - added Apache 2.0 license notice
#
# Copyright 2006-2025 Hans van der Marel, Delft University of Technology.
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
use Time::Local;
use File::Basename;
use lib dirname (__FILE__);

use libgpstime;

use strict;
use warnings;

$VERSION = 20250705;

# Get options

my %Config;

#Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
my $Result = GetOptions( \%Config,
                      qw(
                        source|s=s
                        target|t=s
                        help|?|h
                      ) );
$Config{help} = 1 if( ! $Result || ! scalar @ARGV || scalar @ARGV != 2);

if( $Config{help} )
{
    Syntax();
    exit();
}

# Get inputfiles

my $file1=$ARGV[0];
my $file2=$ARGV[1];

# Process each file

my $avsize1=0;
my $avsize2=0;
my $count1=0;
my $count2=0;
my @sizes1=();
my @sizes2=();
my $sizelimit=100;

my %hash=();

my %hash1=();
if (-e $file1 ) {
  open(FH,"< $file1") or die "can't open $file1";
} else {
  # file doesn't exist, execute find command instead
  open(FH,"find $file1 -printf \"%f %s %h\\\\n\" |") or die "can't create pipe with find $file1";
}
while (<FH>) {
  my @line=split;
  if ( not exists( $Config{source} ) ) {
    # autodetect source template
    $Config{source}=defaulttpl($line[0]) or die "unrecognised filename $line[0], please specify source template explicitly";
    warn "source template is set to $Config{source}\n";
  }
  my %fd=parsetpl($line[0],$Config{source});
  # expand the time information
  my %fdout=gpstime(%fd);
  # make the key
  my $station=$fdout{sta4};
  my $week=$fdout{week};
  my $dow=$fdout{dow};
  my $session=$fdout{sessid};
  my $key=sprintf("%s/%4d/%1d/%1s/%02d",$station,$week,$dow,$session,$fdout{min});
  #my $key=sprintf("%s/%4d/%1d",$station,$week,$dow);
  #my $key=sprintf("%4d/%1d",$week,$dow);
  #print "--> $key $session\n";
  $hash{$key}=+1;
  $hash1{$key}=join(",",@line);
  if ($line[1] > $sizelimit) {
    $avsize1+=$line[1];
    $sizes1[$count1]=$line[1];
    $count1++;
  }
}
close(FH) or die "can't close $file1";

my %hash2=();
if (-e $file2 ) {
  open(FH,"< $file2") or die "can't open $file2";
} else {
  # file doesn't exist, execute find command instead
  open(FH,"find  $file2 -printf \"%f %s %h\\\\n\" |") or die "can't create pipe with find $file2";
}
while (<FH>) {
  my @line=split;
  if ( not exists( $Config{target} ) ) {
    # autodetect target template
    $Config{target}=defaulttpl($line[0]) or die "unrecognised filename $line[0], please specify target template explicitly";
    warn "target template is set to $Config{target}\n";
  }
  my %fd=parsetpl($line[0],$Config{target});
  # expand the time information
  my %fdout=gpstime(%fd);
  # make the key
  my $station=$fdout{sta4};
  my $week=$fdout{week};
  my $dow=$fdout{dow};
  my $session=$fdout{sessid};
  my $key=sprintf("%s/%4d/%1d/%1s/%02d",$station,$week,$dow,$session,$fdout{min});
  #my $key=sprintf("%s/%4d/%1d",$station,$week,$dow);
  #my $key=sprintf("%4d/%1d",$week,$dow);
  #print "--> $key $session\n";
  $hash{$key}=+2;
  $hash2{$key}=join(",",@line);
  if ($line[1] > $sizelimit) {
    $avsize2+=$line[1];
    $sizes2[$count2]=$line[1];
    $count2++;
  }
}
close(FH) or die "can't close $file2";

# determine average filesize

$avsize1=$avsize1/$count1;
$avsize2=$avsize2/$count2;

my $ratio=$avsize2/$avsize1;

#print "$avsize1, $avsize2, $ratio, $count1, $count2\n";

# determine median of filesize

my $i1=int(0.50*$count1);
my $i2=int(0.50*$count2);
my $msize1=( sort {$a <=> $b} @sizes1 )[$i1];
my $msize2=( sort {$a <=> $b} @sizes2 )[$i2];

$ratio=$msize2/$msize1;

#print "$msize1, $msize2, $ratio, $count1, $count2, $i1, $i2\n";

# try another method to determine the compression ratio

my $count=0;
my @ratios=();
foreach my $key (sort (keys %hash )) {
  if ( (exists $hash1{$key} ) && (exists $hash2{$key} ) ) {
    my $size1=(split(",",$hash1{$key}))[1];
    my $size2=(split(",",$hash2{$key}))[1];    
    if ( ($size1 > $sizelimit ) && ($size2 > $sizelimit) ) {
       $ratios[$count]=$size2/$size1;
       $count++;
    }
  }
}
my $i=int(0.50*$count);
$ratio=( sort {$a <=> $b} @ratios )[$i];

#print "$ratio $count $i\n";

printf("\n     %40.40s   %-40.40s   ratio\n\n",$file1,$file2);
printf("Number of files           %12d               %12d                          %5.2f\n", $count1,$count2,$count2/$count1);
printf("Average filesize          %12.0f               %12.0f                          %5.2f\n", $avsize1,$avsize2,$avsize2/$avsize1);
printf("Median filesize           %12.0f               %12.0f                          %5.2f\n", $msize1,$msize2,$msize2/$msize1);
printf("Median of ratios                                                                           %5.2f\n\n", $ratio);

# compare and print the differences

my $day;
my $lastday=0;
my $laststation="xxxx";
my $action=" ";
my @missing=();

printf("%-61s   %s\n",$file1,$file2);
print("filename____________ ____size path___________________________   filename_______ ____size path__________________________\n\n");
foreach my $key (sort (keys %hash )) {
  my $line1=" , , ";
  my $line2=" , , ";
  if ( (exists $hash1{$key} ) && (exists $hash2{$key} ) ) {
    $action=" ";
    $line1=$hash1{$key}; 
    $line2=$hash2{$key};
    # compare file sizes
    my $size1=(split(",",$line1))[1];
    my $size2=(split(",",$line2))[1];    
    if ( ($size1 < $sizelimit ) && ($size2 < $sizelimit) ) {
       $action="-";
    } elsif ($size1 < $sizelimit ) {
       $action="<";
    } elsif ($size2 < $sizelimit ) {
       $action=">"
    } elsif ($size1 == $size2 ) {
       $action="="
    } else {
       my $dsize=2*($size1*$ratio-$size2)/($size1*$ratio+$size2);
       $action=")" if ($dsize > 0.2);
       $action="]" if ($dsize > 0.5);
       $action="(" if ($dsize < -0.2);
       $action="[" if ($dsize < -0.5);
    }        
  } elsif (exists $hash1{$key} ) {
    $action=">";
    $line1=$hash1{$key}; 
    $line2=" , , ";
  } elsif (exists $hash2{$key} ) {
    $action="<";
    $line1=" , , "; 
    $line2=$hash2{$key};
  } else {
    warn "this cannot be";
  }
  # check for missing days
  my @tmp=split("/",$key);
  $day=$tmp[1]*7+$tmp[2];
  if ( ( ($day-$lastday) > 1 ) && ($lastday > 0 ) && ($tmp[0] eq $laststation) ) {
    #printf("\n");
    print("                                                              ?\n");
    for ( my $i=$lastday+1;$i < $day;$i++) {
      push(@missing,$tmp[0]."/".$i );
    } 
  }
  $lastday=$day;  
  $laststation=$tmp[0];  

  printf("%-20s %8s %-31s %-1s %-15s %8s %-30s\n", split(",",$line1) , $action,  split(",",$line2));

  $hash{$key}=$action;
}

printf("\nCopy left to right candidates (due to missing files on the right)\n\n");
foreach my $key (sort (keys %hash )) {
  if ($hash{$key} eq ">") {
     printf("%s/%s\n", (split(",",$hash1{$key}))[2,0]);  
  }
}
printf("\nCopy left to right candidates (due to size differences of 50%% or more)\n\n");
foreach my $key (sort (keys %hash )) {
  if ($hash{$key} eq "]") {
     printf("%s/%s\n", (split(",",$hash1{$key}))[2,0]);  
  }
}
printf("\nCopy left to right candidates (due to size differences of 20%%-50%%)\n\n");
foreach my $key (sort (keys %hash )) {
  if ($hash{$key} eq ")") {
     printf("%s/%s\n", (split(",",$hash1{$key}))[2,0]);  
  }
}


printf("\nCopy right to left candidates (due to missing files on the left)\n\n");
foreach my $key (sort (keys %hash )) {
  if ($hash{$key} eq "<") {
     printf("%s/%s\n", (split(",",$hash2{$key}))[2,0]);  
  }
}
printf("\nCopy right to left candidates (due to size differences of 50%% or more)\n\n");
foreach my $key (sort (keys %hash )) {
  if ($hash{$key} eq "[") {
     printf("%s/%s\n", (split(",",$hash2{$key}))[2,0]);  
  }
}
printf("\nCopy right to left candidates (due to size differences of 20%%-50%%)\n\n");
foreach my $key (sort (keys %hash )) {
  if ($hash{$key} eq "(") {
     printf("%s/%s\n", (split(",",$hash2{$key}))[2,0]);  
  }
}

my $time0 = timegm(0,0,0,6,0,1980);

if ( scalar(@missing) ) {
  printf("\nStations with perhaps missing days on both sides (?)\n\n");
  printf("sta4  wwww/d  doy  date___________\n");
  foreach my $item (@missing) {
    my ($station,$i)=split(/\//,$item);
    my $time=$time0+$i*24*3600;
    my $timestring=gmtime($time);
    $timestring=~ s/00:00:00 //;
    my ($year,$doy) = (gmtime($time))[5,7]; $year+=1900; $doy++;
    my $sdoy=sprintf("%03d",$doy);
    my $week=int(($time-$time0)/(7*24*3600));
    my $dow=int(($time-$time0)/(24*3600) % 7);
    $timestring=gmtime($time);
    $timestring=~ s/00:00:00 //;
    ($year,$doy) = (gmtime($time))[5,7]; $year+=1900; $doy++;
    $sdoy=sprintf("%03d",$doy);
    print "$station  $week/$dow  $sdoy  $timestring\n";
  }
}

exit;


sub Syntax
{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print << "EOT";
$Script                                            (Version: $VERSION)
$Line
Compare two directories (or directory listing) with GNSS filenames and 
list them side-by-side.GNSS filenames can be in several different formats
for each side of the comparison.
Syntax: 
  $Script [-s <Tpl>] [-t <Tpl>]  "path1" "path2"
  $Script [-s <Tpl>] [-t <Tpl>]  dirList1 dirList2

    -s <Tpl>........Source template for the first file/directory
    -t <Tpl>........Target template for the second file/directory
    -?|h|help.......This help.

the template specifiers are optional, and have only to be specified
if the software fails to autodetect the filename format.

The directory specifications path1 and path2 must be enclosed in "" to 
prevent shell-globbing), dirList1 and dirList2 are files with filenames, filesize
and path created using the find command, e.g. 

  find ~/rawdata/2006/kosg/* -printf "%f %s %h\\n" >> file.1

Examples:
  $Script "./*.cmp" "~/rawdata/200{5,6}/kosg/*"

  find ~/rawdata/2006/kosg/* -printf "%f %s %h\\n" > file.1
  find ~/rinex/2006/???/kosg*.??d.Z -printf "%f %s %h\\n" > file.2
  $Script file.1 file.2

  $Script -s "(sta4)(week)(dow).tb" -t "(sta4)(year)0.(yr)d" file.1 file.2

Supported variables in templates (must be embedded in parenthesis):
  sta4,STA4,Sta4..4 letter station abbreviation (lc, uc, as-is)
  MRCCC.......... 5 letter Rinex-3 monument/receiver/country code
  week,dow........GPS week and day of week
  year,month,day..Date information 
  MONTH...........Three-letter abbreviation for month
  yr,doy..........Two digit year and day of year
  sessid,SESSID...Session id [a-x], [A-X] or digit 
  hour............Two digit hour 
  min             Two digit minute
  ext.............Extention, file type, etc. (one or more characters)
  wldc            Anything that is not zero or more digits
 
Examples of templates:
  (sta4)(week)(dow).tbi
  (year)/(doy)/(sta4)(year)(sessid).(yr)d
  (sta4)(year)(month)(day)(hour).dat

(c) 2006-2025 Hans van der Marel, Delft University of Technology.
EOT

}

1;