#!/usr/bin/perl
#
# gpstime.pl
# ----------
# This script converts gps file specifications using source and target 
# templates, taking care of the various time formats.
#
# For help:
#     perl gpstime.pl -?
#
# Created:   9 September 2002 by Hans van der Marel
# Modified:  6 March 2023 by Hans van der Marel
#              - Last production version with all functions included 
#            4 July 2025 by Hans van der Marel
#              - moved functions that are also used by other scripts
#                to libgpstime.pm 
#              - included some more documentation
#              - checked with strict pragma
#              - changed name from gpstime.pl to gpsdate.pl
#              - new Sta4 variable (leave case as is)
#              - sta4 variable is always lowercase: former -l option is now 
#                default. Removed this option from help but left as undocumented 
#                non functional option to maintain backward syntax compability
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
use File::Basename;
use lib dirname (__FILE__);

use libgpstime;

use strict;
use warnings;

$VERSION = 20250704;

#my %Config = (
#    target      =>  'Date=(year)-(month)-(day) GPSweek/dow=(week)/(dow) doy=(doy)' ,
#);  

my %Config;

# Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
my $Result = GetOptions( \%Config,
                      qw(
                        dir|d=s
                        source|s=s
                        target|t=s
                        file|f=s
                        make|m
                        lowercase|l
                        exclude|e=s
                        var|x=s
                        help|?|h
                      ) );
$Config{help} = 1 if( ! $Result || ! scalar @ARGV );

if( $Config{help} )
{
    Syntax();
    exit();
}
#if( $Config{target} && $Config{file} ) {
#   die "Options -t[arget] and -f[ile] are mutually exclusive.\n";
#}

my $file=$ARGV[0];
if ( not exists( $Config{source} ) ) {
  # autodetect source template
  $Config{source}=defaulttpl($file) or die "unrecognised filename $file, please specify source template explicitly";
  warn "source template is set to $Config{source}\n";
}
my $tplin=$Config{source};
my @tplfile=();
if ($Config{file}) {
  $file=$Config{file};
  #print "$file\n";
  open (FILE,"< $file");
  @tplfile=<FILE>;
  close(FILE);
  #print "@tplfile";
} elsif ($Config{target}) { 
  @tplfile=( $Config{target} );
} else {
  @tplfile=("Date=(year)-(month)-(day) GPSweek/dow=(week)/(dow) doy=(doy)" );
}

# Expand inputfile names

my @files=();
foreach my $file ( @ARGV ) {
  # print "$file\n";
  $file=$Config{dir}.$file if (exists ($Config{dir} ));
  my @exp=glob($file);
  @exp=sort(@exp);
  @exp= grep(!/$Config{exclude}/i, @exp) if ($Config{exclude});
  push @files,@exp;
}
#print "@files\n";

# convert each file

#@targets=();
my %targets=();
foreach my $file ( @files ) {

  # print "$file $tplin\n";
  my %fd=parsetpl($file,$tplin);
  # foreach $key ( keys(%fd) ) {
  #   print "  $key -> $fd{$key} \n";
  # }
  my %fdout=gpstime(%fd);

  # optionally add directory, Rinex-3 MRCCC information and extra variables to the hash
  $fdout{dir}=$Config{dir} if (exists ($Config{dir} ));
  if ( exists($Config{var}) ) {
     my @xvalues = split(/,/, $Config{var});
     foreach my $xpair (@xvalues) {
        #print "$xpair\n";
        my ($xkey, $xval) = split(/=/, $xpair);
        $fdout{$xkey}=$xval;
     }
  }
  $fdout{MRCCC}="00NLD" if (!exists ($fdout{MRCCC} ));

  #foreach $key ( keys(%fdout) ) {
  #     print "  $key -> $fdout{$key} \n";
  #}

  # optionally add target information to the hash (only if -t[arget] defined on input)
  if ( $Config{target} ) {
    my $tplout=$Config{target};
    $fdout{target} = expandtpl($tplout,%fdout);
#    push @targets,$fdout{target};
    my $target=$fdout{target};
    if ( exists ($targets{$target} ) ) {
       my $tmp=$targets{$target}->{source};
#       print "$tmp\n";
       $fdout{source}=join(" ",$tmp,$fdout{source});
    }
    foreach my $key ( keys(%fdout) ) {
      $targets{$target}->{$key}=$fdout{$key};
    }
  }

  # expand the output template
  if ( !( $Config{make} && $Config{file}) ) {
    foreach my $tplout (@tplfile) {
      chomp $tplout;
      my $new = expandtpl($tplout,%fdout);
      print "$new\n";
    } 
  }

}

if ( $Config{make} && $Config{file}) {
    my $targetlist=join(" ",sort(keys(%targets)));
    print "ALL : $targetlist\n\n";
    foreach my $target ( sort(keys(%targets)) ) {
      my %fdout=%{$targets{$target}};
      foreach my $tplout (@tplfile) {
        chomp $tplout;
        my $new = expandtpl($tplout,%fdout);
        print "$new\n";
      } 
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
Convert gps filenames (or other strings) satisfying a source template into new
filenames (or strings) satisfying an output template, while taking care of 
various date and time conversions.
Syntax: 
    $Script [-d <Dir>] [-s <Tpl>] [-t <Tpl>]|[-f <File>] [-m] [-l] 
                                [-x <var=val>] [-e <Pattern>] File [[Files]]

    -d <Dir>........Specifies the directory where the input files reside.
    -s <Tpl>........Source template for the input files or strings.
                    Defaults: (week)/(dow) | (doy)-(yr) | (year)-(month)-(day) | 
                    (year)(month)(day) | (year)(doy).
    -t <Tpl>........Target template for the output files or strings. 
                    Defaults to a nice readable format.
    -f <File>.......Path to a file with templates to process (optional). 
    -e <pattern>....Pattern to exclude files from processing (optional).
    -m..............Produce a make file from file template.
    -l..............Force (sta4) to lowercase, is default, obsolete option.
    -x <var=value>..Define variable default, can be comma seperated list. The 
                    default MRCCC is already set (-x "MRCCC=00NLD"). 
    -?|h|help.......This help.

  The files on the command line do not have to exist. So this tool can also be
  used to convert arbitrary strings, as in the first two examples. Wildcard
  specifiers are allowed on the command line.

  Examples:
    $Script 1147/3
    $Script 2002-03-12
    $Script 2023177
    $Script -s (sta4)(week)(dow).tb -t (sta4)(year)0.(yr)d delf11473.tb
    $Script -s (sta4)(week)(dow).tb -f makefile.prototype delf*.tb

  Supported variables in templates (must be embedded in parenthesis):
    sta4,STA4,Sta4..4 letter station abbreviation (lc, uc, as-is)
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
  Additional variables for output templates (not for source templates):
    iso.............Date and time in ISO format  
    dir.............Directory in -d option  
    source..........Expanded source file 
    target..........Expanded target template (not for target templates)
 
  Examples of templates:
    (sta4)(week)(dow).tbi
    (year)/(doy)/(sta4)(year)(sessid).(yr)d
    (sta4)(year)(month)(day)(hour).dat
    (year)(doy)

(c) 2002-2025 Hans van der Marel, Delft University of Technology.
EOT

}

1;