#!/usr/bin/perl
#
# ydrange.pl
# ----------
# This script generates a comma separated year-day list.
#
# For help:
#     perl ydrange.pl -?
#
# Created:   9 September 2002 by Hans van der Marel
# Modified:  4 July 2025 by Hans van der Marel
#              - checked with strict pragma
#              - added Apache 2.0 license notice
#
# Copyright 2002-2025 Hans van der Marel, Delft University of Technology.
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

use strict;
use warnings;

$VERSION = 20250704;

my %Config = (
    delay   =>  0 ,
    range   =>  1
);  

Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
my $Result = GetOptions( \%Config,
                      qw(
                        delay|d=s
                        range|r=s
                        gps|g
                        doy|y
                        rnx|x
                        rx2|2
                        rx3|3
                        help|?|h
                      ) );
$Config{help} = 1 if ( ! $Result );

if( $Config{help} )
{
    Syntax();
    exit();
}


my $time0 = 3657;            # Day number for 6-Jan-1980, 522 week and 3 days since 1-1-1970
my $now=int(time()/86400);   # Current day number

my $list;

for ( my $i=$now-$Config{delay}-$Config{range}+1; $i <= $now-$Config{delay}; $i++ ) {
   my ($day,$week,$dow);
   if ($Config{gps}) {
     $week=int(($i-$time0)/7);
     $dow=int(($i-$time0) % 7);
     $day=sprintf("%04.4d%1d",$week,$dow);
   } else {
     my @day=gmtime($i*86400);
     if ($Config{doy}) {
       $day=sprintf("%02.2d%03.3d",$day[5] % 100,$day[7]+1);
     } elsif ($Config{rnx}) {
       $day=sprintf("%03.3d.\\.%02.2d",$day[7]+1,$day[5] % 100);
     } elsif ($Config{rx2}) {
       $day=sprintf("%03.3d...\\.%02.2d",$day[7]+1,$day[5] % 100);
     } elsif ($Config{rx3}) {
       $day=sprintf("%04.4d%03.3d",$day[5]+1900,$day[7]+1);
     } else {
       $day=sprintf("%04.4d%02.2d%02.2d",$day[5]+1900,$day[4]+1,$day[3]);
     }
   }
   if ( $list ) {
     if ( $Config{rnx} || $Config{rx3} )  {
       $list=join("|",$list,$day);
     } else {
       $list=join(",",$list,$day);
     }
   } else {
     $list=$day;
   }
}

print "$list";

exit;


sub Syntax
{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print << "EOT";
$Script                                            (Version: $VERSION)
$Line
Generate a comma separated list of year-month-day information.
Syntax: 
    $Script [-[hgyx23]] [-d[delay] <numdays] [-r[ange] <numdays>] 

    -d[elay] ## ....Generate is for ## days in the past (default 0).
    -r[ange] ## ....Number of days in the list (default 1).
    -?|h|help.......This help.
    
Default is to create a comma separated list with yyyymmdd values, unless
one of the following mutually exclusive options is used

    -g[ps]..........Csv list GPS week and day of week.
    -[do]y..........Csv list witg 2 digit year and day of year.
    -[rn]x..........Regex with rinex 2 file pattern
    -[rx]2..........Csv list with rinex 2 highrate file pattern
    -[rx]3..........Regex with rinex-3 yyyydoy values

(c) 2002-2025 Hans van der Marel, Delft University of Technology.
EOT

}

1;

