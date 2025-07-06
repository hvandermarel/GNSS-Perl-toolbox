#!/usr/bin/perl
#
# gpsdir.pl
# ---------
# This script generates a generalized directory listing specific for gnss
# related files 
#
# Short syntax
#     gpsdir <files>
#     gpsdir -h
#
# wildcards in the file specification are allowed.
#
# Created:   9 September 2003 by Hans van der Marel
# Modified:  5 July 2025 by Hans van der Marel
#              - replaced functions by libgpstime.pm
#              - checked with strict pragma
#              - added Apache 2.0 license notice
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
                        dir|d=s
                        include|i=s
                        exclude|e=s
                        source|s=s
                        help|?|h
                      ) );
$Config{help} = 1 if( ! $Result || ! scalar @ARGV );

if( $Config{help} )
{
    Syntax();
    exit();
}

# Expand inputfile names

my @files=();
foreach my $file ( @ARGV ) {
  # print "$file\n";
  $file=$Config{dir}.$file if (exists ($Config{dir} ));
  my @exp=glob($file);
  @exp=sort(@exp);
  @exp= grep(/$Config{include}/, @exp) if ($Config{include});
  @exp= grep(!/$Config{exclude}/, @exp) if ($Config{exclude});
  push @files,@exp;
}
#print "@files\n";

# Decide on the source template

if ( not exists( $Config{source} ) ) {
  # Lets try to decide on the source template using the actual data
  # Supported formats:
  #   (week)/(dow)
  #   (year)-(month)-(day)
  #   (doy)-(yr)
  #$Config{source}="(sta4)(week)(dow)000.(ext)";
  #$Config{source}="(sta4)(week)(dow)" if ( $file =~ / \d\d\d\d\/\d /mx );
  #$Config{source}="(doy)-(yr)" if ( $file =~ / \d\d\d\-\d\d /mx ) ;
  #$Config{source}="(year)-(month)-(day)" if ( $file =~ / \d\d\d\d\-\d\d\-\d\d /mx );
  #
  # autodetect source template
  $Config{source}=defaulttpl($files[0]) or die "unrecognised filename $files[0], please specify source template explicitly";
  warn "source template is set to $Config{source}\n";
}
my $tplin=$Config{source};


# Process the selected files

my %daycount=();
my %tmpcount=();

foreach my $file (@files ) {

  next if ( !(-f $file));

  #$filename = basename($file);
  #print "$file  $filename\n";

  # parse the filename

  my %fd=parsetpl($file,$tplin);
  # foreach $key ( keys(%fd) ) {
  #   print "  $key -> $fd{$key} \n";
  # }

  # expand the time information

  my %fdout=gpstime(%fd);

  my $station=$fdout{sta4};
  my $week=$fdout{week};
  my $dow=$fdout{dow};
  my $session=$fdout{sessid};
  my $key=sprintf("%s %4d/%1d",$station,$week,$dow);
  #print "--> $key $session\n";
  my $sessid;
  if ($session =~ /[A-Xa-x]/m) {
    $sessid=ord(lc($session))-ord("a")+1;
    #print "$sessid\n";
    $tmpcount{$key}++;
  } else {
    $sessid=0;
    $tmpcount{$key}=0;
  }
  my $value=$daycount{$key};
  $value="                         " if (!defined($daycount{$key}));
  substr($value,$sessid,1)=$session;

  $daycount{$key}=$value;
}

my $lastday=0;
my $laststation="xxxx";
my $time0 = timegm(0,0,0,6,0,1980);

print "sta4 week/d doy  date              0         1         2\n";
print "---- ------ ---  ---------------  D012345678901234567890123\n";
foreach my $key (sort (keys %daycount )) {
  my ($sta4,$week,$dow) = split(/[\/ ]/,$key);
  my $day=$week*7+$dow;
  my $time=$time0+$day*24*3600;
  my $timestring=gmtime($time);
  $timestring=~ s/00:00:00 //;
  my ($year,$doy) = (gmtime($time))[5,7]; $year+=1900; $doy++;
  my $sdoy=sprintf("%03d",$doy);
  print "\n" if ( ($day > $lastday+1 ) && ( $lastday > 0 ) && ( $sta4 eq $laststation ) ); 
  print "$key $sdoy  $timestring  $daycount{$key}\n";
  $lastday=$day;
  $laststation=$sta4;
}

my %weekcount=();
foreach my $key (sort (keys %tmpcount )) {
  my ($sta4,$week,$dow) = split(/[\/ ]/,$key);
  my $key2=$sta4." ".$week;
  #print "--> $key2 $dow\n";
  my $value=$weekcount{$key2};
  $value="       " if (!defined($weekcount{$key2}));
  my $sessid=0;
  if ($tmpcount{$key} != 0 ) {
    $sessid=chr(ord("a")+$tmpcount{$key}-1);
  }
  substr($value,$dow,1)=$sessid;
  $weekcount{$key2}=$value;
}

my $lastweek=0;
$laststation="xxxx";
print "\n";
print "sta4 week  0123456\n";
print "---- ----  -------\n";
foreach my $key2 (sort (keys %weekcount )) {
  my ($sta4,$week) = split(/ /,$key2);
  print "\n" if ( ($week > $lastweek+1 ) && ( $lastweek > 0 ) && ( $sta4 eq $laststation ) ); 
  print "$key2  $weekcount{$key2}\n";
  $lastweek=$week;
  $laststation=$sta4;
}

$lastday=0;
print "\n\nMissing days:\n\n";
print "sta4  date             week/d doy \n";
print "----  ---------------  ------ --- \n";
foreach my $key (sort (keys %daycount )) {
  my ($sta4,$week,$dow) = split(/[\/ ]/,$key);
  my $day=$week*7+$dow;
  my $time=$time0+$day*24*3600;
  my $timestring=gmtime($time);
  $timestring=~ s/00:00:00 //;
  my ($year,$doy) = (gmtime($time))[5,7]; $year+=1900; $doy++;
  my $sdoy=sprintf("%03d",$doy);
  if ( ($day > $lastday+1 ) && ( $lastday > 0 ) && ( $sta4 eq $laststation ) ) {
     for (my $i=$lastday+1; $i < $day; $i++) {
        my $time=$time0+$i*24*3600;
        my $week=int(($time-$time0)/(7*24*3600));
        my $dow=int(($time-$time0)/(24*3600) % 7);
        my $timestring=gmtime($time);
        $timestring=~ s/00:00:00 //;
        my ($year,$doy) = (gmtime($time))[5,7]; $year+=1900; $doy++;
        my $sdoy=sprintf("%03d",$doy);
        print "$sta4  $timestring  $week/$dow $sdoy \n";
     }
  }
  $lastday=$day;
  $laststation=$sta4;
}

exit;


sub Syntax
{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print << "EOT";
$Script                                            (Version: $VERSION)
$Line
Make a generalized "directory listing" for GNSS specific files
which use either "week/dow", "doy" or "year, month, day" formats.
Syntax: 
  $Script [-d <Dir>] [-s <Tpl>] [-[e|i] <Pattern>] File [[Files]]

  -d <Dir>........Specifies the directory where the input files reside.
  -s <Tpl>........Source template for the input files or strings.
  -i <pattern>....Pattern to include files from processing (optional).
  -e <pattern>....Pattern to exclude files from processing (optional).
  -?|h|help.......This help.

wildcards in the file specification are allowed. The source template is
determined automatically from the filenames.

Examples:
  $Script -s (sta)/(week)(dow)000.cbi -d refsta delf/*.cbi
  $Script -s (year)/(doy)/(sta4)(doy)(sessid).(yr)d  
                                       rinex/2002/???/delf*.02d.Z
   
Supported variables in templates (must be embedded in parenthesis):
  sta4,STA4,Sta4..4 letter station abbreviation
  MRCCC.......... 5 letter Rinex-3 monument/receiver/country code
  week,dow........GPS week and day of week
  year,month,day..Date information
  MONTH...........Three-letter abbreviation for month
  yr,doy..........Two digit year and day of year
  sessid,SESSID...Session id [a-x], [A-X] or digit 
  hour............Two digit hour 
  min.............Two digit minute
  ext.............Extention, file type, etc. (one or more characters)
  wldc............Anything that is not zero or more digits

(c) 2003-2025 Hans van der Marel, Delft University of Technology.
EOT

}

1;