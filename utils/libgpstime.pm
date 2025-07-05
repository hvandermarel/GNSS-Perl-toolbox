# -----------------------------------------------------------------------------
# 
# Perl package for managing GNSS file templates
#
# -----------------------------------------------------------------------------
#
# Perl functions to parse GNSS file names using a file template. 
#
# Functions:
#
#    Parse GNSS file name using a file templates
#
#        %fd = parsetpl($path,$template);
#
#     with as input $path a path with filename and $template the template to use 
#     for parsing the path. The outcome is a hash %fd with the variables recovered
#     from the input $path.
#
#    Expand GNSS file template  
#
#        $path = expandtpl($template,%fd);
#
#    with $template the template and %fd a hash with the variables to expand.
#  
#    Complete gps timing information in input hash as much as possible
#
#        %fdout = gpstime ( %fdin );
#
#    with  
#                                                       Required Input
#        $fd->{week}     GPS week number (4 digits)     1
#        $fd->{dow}      day of week (1 digit)          1
#        $fd->{year}     year (4 digits)                   2     4
#        $fd->{yr}       year (2 digits)                      3     5
#        $fd->{doy}      day of year                       2  3
#        $fd->{month}    month of year (2 digits)                4  5
#        $fd->{day}      day of week (2 digits)                  4  5
#
#    on output all combinations are returned plus the original contents of %fdin.
#
#    Get default file name template from an example file
#
#        $template = defaulttpl($filename);
#
#    with $template the resulting template best fitting the filename in $filename 
#
# data structures:
#
#    $template
#        GNSS file templates, string, with variable between parenthesis.
#
#        Variables for source and output templates:
#            sta4,STA4,Sta4..4 letter station abbreviation (lc, uc, as-is) *)
#            MRCCC.......... 5 letter Rinex-3 monument/receiver/country code
#            week,dow........GPS week and day of week
#            year,month,day..Date information 
#            MONTH...........Three-letter abbreviation for month
#            yr,doy..........Two digit year and day of year
#            sessid,SESSID...Session id [a-x], [A-X] or digit 
#            hour............Two digit hour 
#            min             Two digit minute
#            ext.............Extention, file type, etc. (one or more characters)
#            wldc            Anything that is not zero or more digits
#
#         *) sta4,STA4 and Sta4 are case insensitive in source templates and
#            can be used interchangeably (even holding different values), button
#            on output the case is converted to resp. lower case, uppercase or 
#            kept as is.
#
#        Additional variables for output templates (not for source templates):
#            iso.............Date and time in ISO format  
#            dir.............Directory in -d option  
#            source..........Expanded source file 
#            target..........Expanded target template (not for target templates)
#
#        Examples
#
#            rawdata/(yr)-(month)/(sta4)(week)(dow).cbi
#            rinex/(year)/(sta4)(doy)0.(yr)d.Z
#
#    %fd
#        hash holding variables from the parsed file data as key value pairs.
#
#    $path
#        string with the a file path (optional folders and filename)
#
# Created:   9 September 2002 by Hans van der Marel
# Modified: 11 March 2006 by Hans van der Marel
#              - Added defaulttpl function
#            4 July 2025 by Hans van der Marel
#              - removed all four initial functions from gpstime.pl,
#                gpscmp.pl, gpsdir.pl and gpslatency.pl, and converted
#                into a Perl package
#              - included some more documentation
#              - checked with strict pragma
#              - new Sta4 variable (leave case as-is)
#              - added a few more default templates to defaulttpl 
#              - added Apache 2.0 license notice
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

package libgpstime;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(parsetpl expandtpl gpstime defaulttpl); # symbols to export by default
#our @EXPORT_OK = qw(); # symbols to export on request


sub parsetpl{

  # Parse gps file name using a GPS file templates
  # Usuage:
  #           %fd = parsetpl($path,$template);
  # 
  # with $path the gps filepath to parse, $template the template used to
  # parse the filepath, and %fd a hash with the expanded variables.
  #
  # Examples of templates:
  #
  #      rawdata/(yr)-(month)/(sta4)(week)(dow).cbi
  #      rinex/(year)/(sta4)(doy)0.(yr)d.Z
  #
  # (c) Hans van der Marel, Delft University of Technology

  my ($path,$template) = @_;
  my %fd = ();

  my %ptpl = (
    sta4  =>  '....' ,
    STA4  =>  '....' ,
    Sta4  =>  '....' ,
    MRCCC =>  '\d\d...' ,
    ext   =>  '.+' ,
    week  =>  '\d\d\d\d',
    www   =>  '\d\d\d',
    dow   =>  '\d',
    year  =>  '\d\d\d\d' ,
    yr    =>  '\d\d',
    doy   =>  '\d\d\d',
    month =>  '\d\d',
    MONTH =>  'JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC',
    day   =>  '\d\d',
    sessid => '[A-Xa-x\d]' ,
    SESSID => '[A-Xa-x\d]' ,
    hour =>   '\d\d',
    min  =>   '\d\d',
    iso  =>   '\d\d\d\d-\d\d-\d\dT\d\d:\d\dZ',
    wldc   =>   '\D*'
  );  

  my ($i,$key,$pattern,@keys,@values);

  # get the keys (variable names) from the template

  @keys = ( $template =~ / \( ( .*? ) \) /gx );
  foreach $key (@keys) {
    warn "Warning: unknown key $key in template $template\n" if ( not exists $ptpl{$key} );
  }

  # build a pattern to parse the file path

  ($pattern = $template ) =~ s/\./\\\./g;
  $pattern =~ s/ \( ( .*? ) \) / exists( $ptpl{$1} ) ? "($ptpl{$1})" : "(.+)" /giex ;

  # Parse the file path using the previously generated pattern

  @values = ( $path =~ / $pattern /gix );

  $i=0;
  foreach $key (@keys) {
    if ( exists( $fd{$key} ) ) {
      die "Error $key $fd{$key} != $values[$i]\n" if ( ( $fd{$key} ne $values[$i] ) && ( $key ne "wldc" ) ); 
    } elsif ( exists( $values[$i] ) ) {
      $fd{$key}=$values[$i] ;
    } else {
      die "Error reading $key from $path using $template\n"; 
    }
    $i++;
  }
  
  # add source file to the %fd hash
  $fd{source}=$path ;

  # make station abbreviation lowercase (new code inserted below)
  #    $fd{sta4}=lc($fd{STA4}) if ($fd{STA4} && ! $fd{sta4}); 
  #    $fd{STA4}=uc($fd{sta4}) if ($fd{sta4} && ! $fd{STA4}); 
  #    if ($Config{lowercase}) { 
  #      $fd{sta4}=lc($fd{sta4});
  #    }
  # make station abbreviation lowercase, uppercase and as-is (changed July 2025)
  $fd{Sta4}=$fd{sta4} if ($fd{sta4} && ! $fd{Sta4}); 
  $fd{Sta4}=$fd{STA4} if ($fd{STA4} && ! $fd{Sta4}); 
  $fd{sta4}=$fd{Sta4} if ($fd{Sta4} && ! $fd{sta4} );
  $fd{STA4}=$fd{Sta4} if ($fd{Sta4} && ! $fd{STA4} );
  $fd{sta4}=lc($fd{sta4}) if ( $fd{sta4} );
  $fd{STA4}=uc($fd{STA4}) if ( $fd{STA4} );
  # make sessid abbreviation lowercase
  $fd{sessid}=lc($fd{SESSID}) if ($fd{SESSID} && ! $fd{sessid}); 
  $fd{SESSID}=uc($fd{sessid}) if ($fd{sessid} && ! $fd{SESSID}); 
  #foreach $key ( keys(%fd) ) {
  #  print "  $key -> $fd{$key} \n";
  #}

  return %fd;

}

sub expandtpl{

  # Expand gps file name template
  # Usuage:
  #           $path = expandtpl($template,%fd);
  #
  # with $template the template and %fd a hash with the variables to expand
  #
  # Examples of templates:
  #
  #      rawdata/(yr)-(month)/(sta4)(week)(dow).cbi
  #      rinex/(year)/(sta4)(doy)0.(yr)d.Z
  #
  # (c) Hans van der Marel, Delft University of Technology

  my ($template,%fd) = @_;
  my $path;

  my $key;

  foreach $key ( $template =~ / \( ( .*? ) \) /gx ) {
    warn "Warning: unknown key $key in template $template\n" if ( not exists $fd{$key} );
  }
  ($path = $template ) =~ s/ \( ( .*? ) \) / exists( $fd{$1} ) ? $fd{$1} : "*" /gex ;

  return $path;

}

sub gpstime{

  # Complete gps timing information in input hash as much as possible
  # Usuage:
  #           %fdout = gpstime ( %fdin );
  #
  # with  
  #                                                 Required Input
  #  $fd->{week}     GPS week number (4 digits)     1
  #  $fd->{dow}      day of week (1 digit)          1
  #  $fd->{year}     year (4 digits)                   2     4
  #  $fd->{yr}       year (2 digits)                      3     5
  #  $fd->{doy}      day of year                       2  3
  #  $fd->{month}    month of year (2 digits)                4  5
  #  $fd->{day}      day of week (2 digits)                  4  5
  #
  # on output all combinations are returned plus the original contents of %fdin
  #
  # (c) Hans van der Marel, Delft University of Technology

  use Time::Local ('timegm','timegm_nocheck');

  my ( %fin ) = @_;

  my ($time,$sec,$min,$hour,$day,$month,$year,$wday,$doy,$week,$dow,$sessid);
  my %fd=%fin;

  my %monthcnv=( 'JAN' => 0 , 'FEB' => 1 , 'MAR' => 2 , 'APR' => 3 , 'MAY' => 4 ,
                 'JUN' => 5 , 'JUL' => 6 , 'AUG' => 7 , 'SEP' => 8 , 'OCT' => 9 ,
                 'NOV' => 10 , 'DEC' => 11 );
  my @monthnames=('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

  # make full year info
  if ( exists( $fd{yr} ) && not exists( $fd{year}) ) {
    if ( $fd{yr} < 80 ) { 
      $fd{year} = 2000 + $fd{yr}; 
    } else { 
      $fd{year} = 1900 + $fd{yr}; 
    }
  } 

  # complete year information if only doy is given
  if ( exists( $fd{doy} )  && not exists( $fd{year} ) ) {
     # missing year information, take current year
     ($year,$doy) = (gmtime())[5,7]; $year+=1900;
     if ( ($fd{doy} > 300) && ($doy < 100)) {
       $year=$year-1;
     }
     $fd{year}=$year;
  }

  # make full week info (undocumented option for last 3 digits of week)
  if ( exists( $fd{www} ) && not exists( $fd{week}) ) {
    if ( $fd{www} < 600 ) { 
      $fd{week} = 1000 + $fd{www}; 
    } else { 
      $fd{week} = sprintf("%04d",$fd{www}) ;
    }
  } 

  # get month number if only monthname is given
  if ( exists( $fd{MONTH} ) && not exists( $fd{month}) ) {
    # Conversion from year, month and day of month
    $fd{month}=$monthcnv{uc($fd{MONTH})}+1;
  }

  # complete year information if only month and day are given
  if ( exists( $fd{month} ) && exists( $fd{day} ) && not exists( $fd{year} ) ) {
     # missing year information, take current year
     ($year,$doy) = (gmtime())[5,7]; $year+=1900;
     if ( ($fd{month} > 9) && ($doy < 100)) {
       $year=$year-1;
     }
     $fd{year}=$year;
  }

  # complete all the date information
  my $time0 = timegm(0,0,0,6,0,1980);
  if ( exists( $fd{week} ) && exists( $fd{dow} ) ) {
    # Conversion from GPS week and dow
    $week=$fd{week};
    $dow=$fd{dow};
    $time=$time0+($week*7+$dow)*24*3600;
    ($sec,$min,$hour,$day,$month,$year,$dow,$doy) = gmtime($time); $month++; $doy++; $year+=1900;
    die "Error dow $fd{dow} != $dow from gmtime\n" if $fd{dow} != $dow ;
  } elsif ( exists( $fd{year} )  && exists( $fd{doy} ) ) {
    # Conversion from year and doy 
    $year=$fd{year};
    $doy=$fd{doy};
    $time = timegm_nocheck(0,0,0,$doy,0,$year);
    $week=int(($time-$time0)/(7*24*3600));
    $dow=int(($time-$time0)/(24*3600) % 7);
    ($sec,$min,$hour,$day,$month,$year,$wday,$doy) = gmtime($time); $month++; $doy++; $year+=1900;
    die "Error year $fd{year} != $year from gmtime\n" if $fd{year} != $year ;
    die "Error doy $fd{doy} != $doy from gmtime\n" if $fd{doy} != $doy ;
    die "Error dow $dow != $wday from gmtime\n" if $dow != $wday ;
  } elsif ( exists( $fd{year} )  && exists( $fd{month} ) && exists( $fd{day} ) ) {
    # Conversion from year, month and day of month
    $year=$fd{year};
    $month=$fd{month};
    $day=$fd{day};
    $time = timegm(0,0,0,$day,$month-1,$year);
    $week=int(($time-$time0)/(7*24*3600));
    $dow=int(($time-$time0)/(24*3600) % 7);
    ($sec,$min,$hour,$day,$month,$year,$wday,$doy) = gmtime($time); $month++; $doy++; $year+=1900;
    die "Error year $fd{year} != $year from gmtime\n" if $fd{year} != $year ;
    die "Error month $fd{month} != $month from gmtime\n" if $fd{month} != $month ;
    die "Error day $fd{day} != $day from gmtime\n" if $fd{day} != $day ;
    die "Error dow $dow != $wday from gmtime\n" if $dow != $wday ;
  } else {
    die "Error: not enough information for gpstime\n";
  }

  # print "$sec,$min,$hour,$day,$month,$year,$wday,$doy,$week,$dow \n";

  $fd{week} = sprintf("%04d",$week) ;
  $fd{dow}  = sprintf("%01d",$dow) ;
  $fd{year} = sprintf("%04d",$year) ;
  $fd{month} = sprintf("%02d",$month) ;
  $fd{day}  = sprintf("%02d",$day) ;
  $fd{doy}  = sprintf("%03d",$doy) ;
  $fd{yr} = sprintf("%02d",$fd{year} % 100) ; 

  $fd{MONTH} = $monthnames[$fd{month}-1];

  # Make 3letter week (undocumented option)
  $fd{www} = sprintf("%03d",$week % 1000 ) ;

  # complete the session information (hourly files) (optional)
  if ( exists( $fd{hour} ) && not exists( $fd{sessid} ) ) {
    $hour=$fd{hour};
    if ( $hour >=0 && $hour < 24 ) { 
      $sessid=chr(ord("a")+$hour);
    } else {
      $sessid=0;
    }
    $fd{sessid}=$sessid;
    $fd{SESSID}=uc($sessid); 
  } elsif ( ( not exists( $fd{hour} )) && exists( $fd{sessid} ) ) {
    $sessid=$fd{sessid};
    if ( $sessid =~ /^[A-Xa-x]$/m ) {
      $hour=ord(lc($sessid))-ord("a");
      $fd{hour}=sprintf("%02d",$hour) ;
    } else {
      $fd{hour}=24 ;
      $hour=0;
    }
  } else {
    $sessid="0";
    $hour=0;
    $fd{sessid}=$sessid;
    $fd{SESSID}=uc($sessid); 
    $fd{hour}=sprintf("%02d",$hour) ;
  }

  # complete the session information (minutes part) (optional)
  if ( not exists( $fd{min} ) ) {
     $min=0;
     $fd{min}  = sprintf("%02d",$min) ;
  }

  # make date/time string in ISO format
  $fd{iso} = sprintf("%4d-%02d-%02dT%02d:%02dZ",$year,$month,$day,$hour,$min);

  return %fd;

}

sub defaulttpl{

  # Get default file name template from an example file
  # Usuage:
  #           $template = defaulttpl($filename);
  #
  # with $t the template and $filename an example filename
  #
  # (c) Hans van der Marel, Delft University of Technology

  my ($filename) = @_;
  my $template;

  # autodetect source template
  if      ( $filename =~ / ....\d\d\d\d\d\d\d\d\d\d\./mx ) {
     $template="(sta4)(year)(month)(day)(hour)(wldc).(ext)";
  } elsif ( $filename =~ / ....\d\d\d.\d\d\.\d\d. /mx ) {
     $template="(sta4)(doy)(sessid)(min).(yr)(ext)";
  } elsif ( $filename =~ / ....\d\d\d.\.\d\d.\.Z/mx ) {
     $template="(sta4)(doy)(sessid).(yr)(ext).Z";
  } elsif ( $filename =~ / ....\d\d\d.\.\d\d.\.gz/mx ) {
     $template="(sta4)(doy)(sessid).(yr)(ext).gz";
  } elsif ( $filename =~ / ....\d\d\d.\.\d\d. /mx ) {
     $template="(sta4)(doy)(sessid).(yr)(ext)";
  } elsif ( $filename =~ / ....\d\d..._\D_\d\d\d\d\d\d\d\d\d\d\d_ /mx ) {
     $template="(STA4)(MRCCC)_(wldc)_(year)(doy)(hour)(min)_";
  } elsif ( $filename =~ / _\d\d\d\d\d\d\d\d\d\d\d_ /mx ) {
     $template="_(year)(doy)(hour)(min)_";
  } elsif ( $filename =~ / \d\d\d\d\/\d /mx ) {
     $template="(week)/(dow)";
  } elsif ( $filename =~ / \d\d\d\d\-\d\d\-\d\d /mx ) {
     $template="(year)-(month)-(day)";
  } elsif ( $filename =~ / \d\d\d-\d\d /mx ) {
     $template="(doy)-(yr)";
  } elsif ( $filename =~ / \d\d\d\d\d\d\d\d /mx ) {
     $template="(year)(month)(day)";
  } elsif ( $filename =~ / \d\d\d\d\d\d\d /mx ) {
     $template="(year)(doy)";
  } else {
     warn "defaulttpl: cannot get template from file example $filename\n";
     return;
  }
 
  return $template;

}

1;
