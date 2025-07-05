#!/usr/bin/perl
#
# gpslatency.pl
# -------------
# This script generates a directory listing with latency information
#
# Short syntax:
#     gpsdir <files>
#     gpslatency -h
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
                        length|l=s
                        crit|c=s
                        help|?|h
                      ) );
$Config{help} = 1 if( ! $Result || ! scalar @ARGV );

if( $Config{help} )
{
    Syntax();
    exit();
}

my $expdelay=60*60;
if ( exists ($Config{length}) ) {
  $expdelay=$Config{length}*60; 
}

my $latelimit=-9999;
if ( exists ($Config{crit}) ) {
  $latelimit=$Config{crit}*60; 
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

my %latencystat=();

print "Filename                                  First Epoch                 Received                       Latency  Delay(sec)    Dirname\n";
print "----------------------------------------  --------------------------  --------------------------  ----------  ----------    -------------\n";
foreach my $file (@files ) {

  next if ( !(-f $file));

  # parse the filename

  my %fd=parsetpl($file,$tplin);
  # foreach $key ( keys(%fd) ) {
  #   print "  $key -> $fd{$key} \n";
  # }

  # expand the time information 

  my %fdout=gpstime(%fd);
  
  my $gpstime = timegm( 0, $fdout{min}, $fdout{hour}, $fdout{day}, $fdout{month} - 1, $fdout{year} );
  my $gpstimestamp    = gmtime($gpstime);

  if ( ! exists ($Config{length}) ) {
    if ( $fdout{sessid} =~ /0/ ) {
      $expdelay = 1440*60;
    } elsif ( $fdout{min} !~ /-0/ ) {
      $expdelay = 15*60;
    } 
  }
  
  # get the file modification time
  
  my $last_mod_time = (stat ($file))[9];
  my $timestamp       = gmtime($last_mod_time);

  # compute file latency (in seconds) wrt to start epoch
  
  my $latency=$last_mod_time - $gpstime;
  
  my $latency_minutes = int( $latency / 60 );
  my $latency_hours = int( $latency / 3600 );
  my $latency_min = sprintf('%02d',$latency_minutes);
  my $latency_sec = sprintf('%02d',$latency - $latency_minutes * 60);
  my $latency_string=""; 
  if ( $latency < 86400 ) {
     $latency_string = sprintf('%02d:%02d:%02d',$latency_hours,$latency_minutes - $latency_hours*60 ,$latency - $latency_minutes*60);
  } elsif ( $latency < 864000 ) {
     $latency_string = sprintf('%.1f day',$latency/86400);
  } else {
     $latency_string = sprintf('%.0f days',$latency/86400);
  } 
  my $late= $latency - $expdelay;

  if (!defined($latencystat{$latency_string})) {
    $latencystat{$latency_string}=1;
  } else {
    $latencystat{$latency_string}=$latencystat{$latency_string}+1;
  }

  # print

  if ( $late > $latelimit ) {
    my $filename = basename($file);
    my $dirname = dirname($file);
    #print "$file  $timestamp  $gpstimestamp  $fdout{year}-$fdout{month}-$fdout{day} $fdout{hour}:$fdout{min}  $latency_minutes:$latency_sec   $late\n";
    printf("%-41.41s %-26.26s  %-26.26s%12s%12s    %s\n",$filename,$gpstimestamp,$timestamp,$latency_string,$late,$dirname);
  }

}

print "\n\n   Latency   Count\n";
print "----------   -----\n";
foreach my $key (sort(keys(%latencystat))) {
  printf("%10s  %6s\n",$key,$latencystat{$key});  
}

exit;


sub Syntax
{
    my( $Script ) = ( $0 =~ m#([^\\/]+)$# );
    my $Line = "-" x length( $Script );
    print << "EOT";
$Script                                            (Version: $VERSION)
$Line
Make a directory listing of GNSS specific files which use either 
"week/dow", "doy" or "year, month, day" formats with file latency
data.
Syntax: 
  $Script [-d <Dir>] [-s <Tpl>] [-[e|i] <Pattern>] File [[Files]]

  -d <Dir>........Specifies the directory where the input files reside.
  -s <Tpl>........Source template for the input files or strings.
  -i <pattern>....Pattern to include files from processing (optional).
  -e <pattern>....Pattern to exclude files from processing (optional).
  -l <minutes>....File interval in minutes (default is 60 minutes).
  -c <minutes>....Only print files that are later than this limit.
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