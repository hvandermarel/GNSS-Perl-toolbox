# -----------------------------------------------------------------------------
# 
# Perl functions for retrieving GLONASS slot number, SVN and sensor name
#
# -----------------------------------------------------------------------------
#
# Return GLONASS slot number, SVN and sensor name
#
# Functions:
#
#      $glosat = glonassdata($date,$cfgfile);
#      prtglonassdata($glosat);
#      @header = glonassslothdr($glosat);
#
# Example:
#
#    #!/bin/perl
#
#    use File::Basename;
#    use lib dirname (__FILE__);
#    require "libglonass.pl";
#
#    my $glosat = glonassdata($ARGV[0],"glonass.cfg");
# 
#    prtglonassdata($glosat);
#
#    my @header = glonassslothdr($glosat);
#    foreach my $line (@header) {
#       print $line."\n";
#    }
#
# Created:  23 June 2025 by Hans van der Marel
# Modified: 24 June 2025 by Hans van der Marel
#              - refactored into function library
#              - Apache 2.0 license notice
# Modified:  2 July 2025 by Hans van der Marel
#              - converted to package(with .pm extension)
#
# Copyright 2025 Hans van der Marel, Delft University of Technology.
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

package libglonass;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(glonassdata prtglonassdata glonassslothdr); # symbols to export by default
#our @EXPORT_OK = qw(); # symbols to export on request


###########################################################################
# Glonass meta data functions
###########################################################################

sub prtglonassdata{

  # Print GLONASS prn, svn, sensor name and slot number. 
  # Usuage
  #  
  #    my $glosat = glonassdata($date);
  #    prtglonassdata($glosat);
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($glosat) = @_;
  
  printf("prn   svn   sensor        ifrq\n---   ---   -----------   ----\n");
  foreach my $prn ( sort keys %$glosat ) {
    printf("%3s   %3s   %-12.12s   %3s\n",$prn,$glosat->{$prn}[0],$glosat->{$prn}[1],, $glosat->{$prn}[2]);
  }
  printf("\n");
 
  return;
}

sub glonassslothdr{

  # Return an array with RINEX header lines with "GLONASS SLOT / FRQ" records.
  # Usuage
  #  
  #    my $glosat = glonassdata($date);
  #    my @header = glonassslothdr($glosat);
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($glosat) = @_;

  # 11 R04  6 R05  1 R06 -4 R11  0 R12 -1 R13 -2 R14 -7 R21  4 GLONASS SLOT / FRQ #
  #    R22 -3 R23  3 R24  2                                    GLONASS SLOT / FRQ #

  my @header=();
  my $count=0;
  my $line=sprintf("%3.0f ", scalar(%$glosat) );
  foreach my $prn ( sort keys %$glosat ) {
    if ( $count >= 8 ) {
       push @header, sprintf("%-60.60s%-20.20s",$line,"GLONASS SLOT / FRQ #");
       $line="    ";
       $count=0;
    }
    $line .= sprintf("%-3.3s%3.0f ",$prn,$glosat->{$prn}[2]);
    $count++;
  }
  push @header, sprintf("%-60.60s%-20.20s",$line,"GLONASS SLOT / FRQ #");

  return @header;
  
}

sub glonassdata{

  # Return hash of array reference with all active GLONASS satellites at 
  # a specific data, with slot number (ifrq), SVN and sensor name.
  # Usuage
  #  
  #    my $glosat = glonassdata($date);
  #
  # with $date a string with YYYY-MM-DD or YYYYMMDD format. Output is
  # a refererence to a hash of arrays, which is accessed as
  #
  #     ( $svn, $sensor, $ifrq ) = $glosat->{$prn}
  #
  #  with $prn the GLONASS PRN number "R##".
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($date,$glofile) = @_;
  $date =~ s/-//g;
  
  my %glosat=();
  
  #open(GLONASS, $glofile) or die("Could not open file $glofile.");
  #while (my $line = <GLONASS>) { 
  my $data_start = tell DATA; # save the position
  while (my $line = <DATA>) { 
     # print $line; 
     chomp $line;
     next if ( $line =~ /^#/ || $line =~ /^\s*$/ ); 
     my ($prn,$svn,$number,$start,$end,$sensor,$ifrq) = split(" ",$line);
     $start =~ s/-//g;
     $end =~ s/-//g;
     $end =~ s/current/99999999/;
     if ( $date > $start && $date < $end ) {
        $glosat{$prn} = [ $svn, $sensor, $ifrq ];
     }
  }
  #close GLONASS;
  seek DATA, $data_start, 0;  # reposition the filehandle right past __DATA__
  
  return \%glosat;
}

1;
__DATA__
#DATASOURCE: SATELLIT_I20.SAT, University of Bern.
#DOWNLOADED AND MODIFIED: 2025-06-23 BY HM
#VALID UNTIL: 2025-06-23
#
#PRN   SVN  NUMBER  START       END             SENSOR       IFRQ
#---   ---  ------  ----------  ----------      ----------   ----
R01    771       1  1996-01-01  1996-12-22      GLONASS        23
R01    779       1  1998-12-30  2004-12-26      GLONASS         2
R01    796       1  2004-12-26  2006-03-21      GLONASS         2
R01    796       2  2006-03-21  2009-12-14      GLONASS         7
R01    730       1  2009-12-14  2010-09-07      GLONASS-M       1
R01    730       2  2010-09-07  2012-07-14      GLONASS-M       1
R01    730       3  2012-07-14  2018-03-18      GLONASS-M       1
R01    730       4  2018-03-18  current         GLONASS-M       1
R02    757       1  1996-01-01  1997-08-24      GLONASS         5
R02    794       1  2003-12-10  2005-02-17      GLONASS         4
R02    794       2  2005-02-17  2008-12-25      GLONASS         1
R02    728       1  2008-12-25  2009-09-14      GLONASS-M       1
R02    728       2  2009-09-14  2013-07-01      GLONASS-M      -4
R02    747       1  2013-07-01  current         GLONASS-M      -4
R03    763       1  1994-11-20  2001-12-01      GLONASS        21
R03    789       1  2001-12-01  2008-12-25      GLONASS        12
R03    727       1  2008-12-25  2010-10-01      GLONASS-M       5
R03    722       2  2010-10-01  2010-12-16      GLONASS-M      -5
R03    727       3  2010-12-16  2011-03-11      GLONASS-M       5
R03    715       3  2011-03-11  2011-10-13      GLONASS-M      -6
R03    801       2  2011-10-13  2011-12-01      GLONASS-K1     -5
R03    744       1  2011-12-01  current         GLONASS-M       5
R04    762       1  1994-11-20  1999-11-20      GLONASS        12
R04    795       1  2003-12-10  2009-12-14      GLONASS         6
R04    733       1  2009-12-14  2010-10-01      GLONASS-M       6
R04    727       2  2010-10-01  2010-12-16      GLONASS-M       6
R04    801       1  2011-02-26  2011-10-11      GLONASS-K1     -5
R04    742       1  2011-10-13  2019-08-26      GLONASS-M       6
R04    859       1  2019-12-27  current         GLONASS-M       6
R05    711       1  2001-12-01  2006-03-21      GLONASS         2
R05    711       2  2006-03-21  2009-12-14      GLONASS         7
R05    734       1  2009-12-14  2015-01-31      GLONASS-M       1
R05    734       2  2015-02-01  2018-08-12      GLONASS-M       1
R05    856       1  2018-08-22  current         GLONASS-M       1
R06    764       1  1994-11-20  2001-12-01      GLONASS        13
R06    790       1  2001-12-01  2003-12-10      GLONASS         9
R06    701       1  2003-12-10  2008-04-27      GLONASS-M       1
R06    701       2  2008-04-27  2009-09-14      GLONASS-M       1
R06    701       3  2009-09-14  2010-04-28      GLONASS-M      -4
R06    714       2  2010-04-28  2010-10-01      GLONASS-M      -6
R06    733       2  2010-10-01  current         GLONASS-M      -4
R07    759       1  1996-01-01  1997-08-05      GLONASS        21
R07    786       1  1998-12-30  2004-12-26      GLONASS         7
R07    712       1  2004-12-26  2007-02-07      GLONASS-M       4
R07    712       2  2007-02-07  2011-12-15      GLONASS-M       5
R07    745       1  2011-12-15  current         GLONASS-M       5
R08    769       1  1996-01-01  1997-06-26      GLONASS         2
R08    784       1  1998-12-30  2004-12-26      GLONASS         8
R08    797       1  2004-12-26  2008-12-25      GLONASS         6
R08    729       1  2008-12-25  2012-09-13      GLONASS-M       6
R08    743       1  2012-09-17  2012-10-18      GLONASS-M      -6
R08    712       3  2012-10-18  2012-12-22      GLONASS-M       6
R08    743       2  2012-12-22  2013-01-06      GLONASS-M      -6
R08    801       4  2013-01-06  2013-02-23      GLONASS-K1     -5
R08    743       3  2013-02-23  current         GLONASS-M       6
R09    776       1  1995-12-14  2007-12-25      GLONASS         6
R09    722       1  2007-12-25  2010-10-01      GLONASS-M      -2
R09    736       2  2010-10-01  2013-12-08      GLONASS-M      -2
R09    736       4  2013-12-08  2015-03-08      GLONASS-M      -2
R09    736       5  2015-03-08  2016-02-16      GLONASS-M      -2
R09    802       3  2016-02-16  2016-11-18      GLONASS-K1     -6
R09    802       4  2016-11-18  current         GLONASS-K1     -2
R10    781       1  1995-07-24  2006-12-25      GLONASS         9
R10    717       1  2006-12-25  2009-03-12      GLONASS-M       4
R10    717       2  2009-03-12  2019-08-02      GLONASS-M      -7
R10    723       4  2019-09-30  current         GLONASS-M       0
R11    785       1  1995-07-24  2007-12-25      GLONASS         4
R11    723       1  2007-12-25  2010-07-18      GLONASS-M       0
R11    723       3  2010-07-18  2016-06-24      GLONASS-M       0
R11    853       1  2016-06-24  2020-11-20      GLONASS-M       0
R11    805       2  2020-12-01  2020-12-23      GLONASS-K1     -5
R11    805       3  2020-12-23  current         GLONASS-K1      0
R12    767       1  1994-08-11  2010-09-02      GLONASS        22
R12    737       1  2010-09-02  2013-12-07      GLONASS-M      -1
R12    737       2  2013-12-08  2015-12-26      GLONASS-M      -1
R12    737       3  2015-12-27  2016-11-22      GLONASS-M      -1
R12    723       2  2016-12-15  2019-06-19      GLONASS-M      -1
R12    858       1  2019-06-19  current         GLONASS-M      -1
R13    782       1  1995-12-14  2007-12-25      GLONASS         6
R13    721       1  2007-12-25  current         GLONASS-M      -2
R14    770       1  1994-08-11  2006-12-25      GLONASS         9
R14    715       1  2006-12-25  2009-03-12      GLONASS-M       4
R14    715       2  2009-03-12  2010-12-16      GLONASS-M      -7
R14    722       3  2010-12-16  2011-10-13      GLONASS-M      -7
R14    715       4  2011-10-13  2017-07-09      GLONASS-M      -7
R14    801       6  2017-09-21  2017-10-06      GLONASS-K1     -5
R14    852       1  2017-10-10  current         GLONASS-M      -7
R15    780       1  1995-07-24  1999-04-07      GLONASS         4
R15    778       1  1999-04-07  2006-12-25      GLONASS        11
R15    716       1  2006-12-25  2018-11-24      GLONASS-M       0
R15    857       1  2018-11-24  current         GLONASS-M       0
R16    775       1  1994-08-11  2010-09-02      GLONASS        22
R16    736       1  2010-09-02  2010-10-01      GLONASS-M      -6
R16    738       1  2010-10-01  2016-02-15      GLONASS-M      -1
R16    736       3  2016-03-09  2021-12-18      GLONASS-M      -1
R16    861       1  2022-11-28  current         GLONASS-M      -1
R17    760       1  1994-04-11  2000-10-13      GLONASS        24
R17    787       1  2000-10-13  2007-10-26      GLONASS         5
R17    718       1  2007-10-26  2009-03-12      GLONASS-M      -1
R17    718       2  2009-03-12  2010-12-16      GLONASS-M       4
R17    714       3  2010-12-16  2011-01-17      GLONASS-M      -5
R17    714       4  2011-01-17  2011-12-20      GLONASS-M       4
R17    746       1  2011-12-20  2015-04-13      GLONASS-M       4
R17    714       6  2015-04-13  2016-01-27      GLONASS-M      -6
R17    802       2  2016-01-27  2016-02-16      GLONASS-K1     -6
R17    714       7  2016-02-16  2016-02-24      GLONASS-M       4
R17    851       1  2016-02-24  current         GLONASS-M       4
R18    758       1  1994-04-11  2000-10-13      GLONASS        10
R18    783       1  2000-10-13  2008-09-25      GLONASS        10
R18    724       1  2008-09-25  2014-02-12      GLONASS-M      -3
R18    714       5  2014-02-18  2014-04-11      GLONASS-M      -6
R18    854       1  2014-04-11  current         GLONASS-M      -3
R19    777       1  1995-03-07  2005-12-25      GLONASS         3
R19    798       1  2005-12-25  2007-10-26      GLONASS         3
R19    720       1  2007-10-26  2025-05-17      GLONASS-M       3
R19    807       3  2025-05-17  current         GLONASS-K1      3
R20    765       1  1995-03-07  2006-02-28      GLONASS         1
R20    793       2  2006-02-28  2007-10-26      GLONASS        11
R20    719       1  2007-10-26  current         GLONASS-M       2
R21    756       1  1996-01-01  2002-12-25      GLONASS        24
R21    792       1  2002-12-25  2007-02-06      GLONASS         5
R21    792       2  2007-02-06  2008-09-25      GLONASS         8
R21    725       1  2008-09-25  2009-03-11      GLONASS-M      -1
R21    725       2  2009-03-11  2011-11-05      GLONASS-M       4
R21    725       3  2011-11-06  2014-08-02      GLONASS-M       4
R21    855       1  2014-08-02  current         GLONASS-M       4
R22    766       1  1995-03-07  2002-12-25      GLONASS        10
R22    791       1  2002-12-25  2007-10-26      GLONASS        10
R22    798       2  2007-10-26  2008-09-25      GLONASS         3
R22    726       1  2008-09-25  2010-03-01      GLONASS-M      -3
R22    731       1  2010-03-01  2020-06-25      GLONASS-M      -3
R22    735       2  2020-08-13  2022-06-05      GLONASS-M      -3
R22    806       1  2022-07-07  current         GLONASS-K1     -3
R23    761       1  1994-04-11  2002-12-25      GLONASS         3
R23    793       1  2002-12-25  2006-02-28      GLONASS        11
R23    714       1  2006-02-28  2010-03-19      GLONASS-M       3
R23    732       1  2010-03-19  current         GLONASS-M       3
R24    774       1  1996-01-01  1996-08-27      GLONASS         1
R24    788       1  2000-10-13  2005-12-25      GLONASS         3
R24    713       1  2005-12-25  2010-03-01      GLONASS-M       2
R24    735       1  2010-03-01  2020-04-10      GLONASS-M       2
R24    860       1  2020-04-10  current         GLONASS-M       2
R25    805       1  2020-11-12  2020-12-01      GLONASS-K1     -5
R25    807       1  2022-10-10  2025-05-11      GLONASS-K1     -5
R25    807       2  2025-05-11  2025-05-17      GLONASS-K1      7
R25    720       2  2025-05-17  current         GLONASS-M       7
R26    801       3  2012-03-15  2013-01-06      GLONASS-K1     -5
R26    801       5  2013-02-23  2017-09-21      GLONASS-K1     -5
R26    801       7  2017-10-06  2019-08-06      GLONASS-K1     -5
R26    801       8  2019-08-06  2020-10-27      GLONASS-K1     -6
R26    803       1  2023-09-08  current         GLONASS-K2     -6
R27    802       1  2014-11-30  2016-01-27      GLONASS-K1      7
R27    716       2  2019-08-03  2020-01-01      GLONASS-M      -4
R27    804       1  2025-03-02  2025-04-02      GLONASS-K2      7
R27    804       2  2025-04-02  current         GLONASS-K2     -5
