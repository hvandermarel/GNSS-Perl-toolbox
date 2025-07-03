# -----------------------------------------------------------------------------
# 
#  Read/Write routines for RINEX 2/3
#
# -----------------------------------------------------------------------------
#
# Perl functions for reading and writing of RINEX 2/3 files.
# Synopsis:
#
#    open($fhin, "< $inputfile") or die "can't open $inputfile: $!"; 
#    binmode($fhin);
#
#    my $reqtype="O";
#    my ($rnxvers,$mixed)=ReadRnxId($fhin,$reqtype);
#    my $rnxheader=ReadRnxHdr($fhin);
#    my ($receivertype,$obsid3,$obsid2)=ScanRnxHdr($rnxheader);
#    while ( ! eof($fhin) ) {
#      my ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped);
#      if ( $rnxvers < 3 ) {
#        ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped,$obsid2upd)=ReadRnx2Data($fhin,$obsid2);
#        In case of rinex-2 we HAVE TO check for changes in observation types, as the read routine depends on it.
#        $obsid2=$obsid2upd if scalar(@$obsid2upd);
#      } else {
#        ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped)=ReadRnx3Data($fhin);
#      }
#    }
#
#    WriteRnxId($fhout,$rnxvers,$type,$idrec);
#    WriteRnxHdr($fhout,$header);
#    while ( something ) {
#      if ( $rnxvers < 3 ) {
#        WriteRnx2Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$obsid2,$data);
#      } else {}
#        WriteRnx3Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$data);
#      }
#    }
#
# Functions:
#
#    my ($rnxvers,$mixed)=ReadRnxId($fhin,$reqtype);
#    my $header=ReadRnxHdr($fhin);
#    my ($receivertype,$obsid3,$obsid2)=ScanRnxHdr($rnxheader);
#    my ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped,$obsid2upd)=ReadRnx2Data($fhin,$obsid2);
#    my ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped)=ReadRnx3Data($fhin);
#
#    WriteRnxId($fhout,$rnxvers,$type,$idrec);
#    WriteRnxHdr($fhout,$header);
#    WriteRnx2Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$obsid2,$data);
#    WriteRnx3Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$data);
#
# Created:   9 September 2011 by Hans van der Marel
# Modified: 11 February 2012 by Hans van der Marel
#              - Public version for testing
#           22 February 2019 by Hans van der Marel
#              - Added ScanRnxHdr function to obtain $obsid2 for rinex-2 reading
#              - renamed variable $nobs to $nobstyp2 for rinex-2 files
#              - included output of observation types in case they have been
#                updated, needed for rinex-2 to accommodate changes in (number of)
#                observation types
#              - renamed package to librnxio.pl (was rnxio.pl)
#           20 June 2025 by Hans van der Marel
#              - minor (cosmetic) updates
#           22 June 2025 by Hans van der Marel
#              - checked with strict pragma
#              - added optional $runby argument to WriteRnxId sub
#              - added Apache 2.0 license notice
#            2 July 2025 by Hans van der Marel
#              - converted to package (with pm extension)
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

package librnxio;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(ReadRnxId WriteRnxId ReadRnxHdr WriteRnxHdr ReadRnx2Data WriteRnx2Data 
          ReadRnx3Data WriteRnx3Data ScanRnxHdr); # symbols to export by default
#our @EXPORT_OK = qw(); # symbols to export on request

sub ReadRnxId{

  # Read the RINEX ID line, check type, and return rinex  version.
  # Usuage
  #  
  #    my ($rnxvers,$mixed,$idrec)=ReadRnxId($fhin,$reqtype);
  #
  # with $fhin the file handle, $reqtype the required type (e.g. "O"), $rnxvers the
  # version string, $mixed a 1-char flag indication mixed observation files,
  # and $idrec the RINEX header record.
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($fhin,$reqtype)=@_;
  
  my ($rnxvers,$mixed,$idrec);

  my  $headid;
  my $skipped=0;
  
  while (<$fhin>) {

    s/\R\z//; # chomp();
    
    $headid=uc(substr($_,60));

    if ( $headid =~ /^RINEX VERSION \/ TYPE/) {
       $rnxvers=substr($_, 0,9);
       $rnxvers=~ s/^\s+//;
       $reqtype=uc(substr($reqtype,0,1));
       if ( substr($_,20,1) !~ /^$reqtype/i ) {
         die "RINEX file is not the right file type ($reqtype), quiting...";
       }
       $mixed=substr($_, 40,1);
       $idrec=$_;
       last;
    } elsif ( eof($fhin) || ( $headid =~ /^END OF HEADER/) ) {
       die "RINEX file (?) has no or invalid RINEX VERSION / TYPE record, quiting...";
    } else {
      $skipped++;
    } 
  }
  if ( $skipped > 0 ) {
     warn "Skipped $skipped records before the RINEX VERSION / TYPE record, continuing...";
  }

  return ($rnxvers,$mixed,$idrec);
  
}

sub WriteRnxId{

  # Write the RINEX ID line and and insert PGM / RUN BY header 
  # Usuage
  #  
  #    WriteRnxId($fhout,$rnxvers,$type,$idrec);
  #    WriteRnxId($fhout,$rnxvers,$type,$idrec,$runby,$pgm);
  #
  # with $fhout the file handle, $type the file type (e.g. "O"), $rnxvers the
  # version string, $mixed a 1-char flag indication mixed observation files,
  # and $idrec the RINEX header record. The optional argument $runby is the
  # person or agency doing the conversion, otherwise the default is to use
  # the 'USERNAME' or 'USER' environment variable. 
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($fhout,$rnxvers,$type,$idrec,$runby,$pgm)=@_;

  my $DATE=sprintf("%04d%02d%02d %02d%02d%02d UTC",(gmtime)[5]+1900,(gmtime)[4]+1,(gmtime)[3,2,1,0]);
  my $USER=$ENV{'USER'};
  $USER=$ENV{'USERNAME'} if (exists($ENV{'USERNAME'}) ) ;
  $USER=$runby if ( defined($runby) ) ;
  my ( $SCRIPT ) = ( $0 =~ m#([^\\/]+)$# ); $SCRIPT =~ s#\.pl$##;
  $SCRIPT=$SCRIPT."-v".$main::VERSION if ( defined($main::VERSION) );
  $SCRIPT=$pgm if ( defined($pgm) );

  substr($idrec,0,9)=sprintf("%9.2f",$rnxvers);
  print $fhout ($idrec,"\n")          or die "can't write RINEX ID record: $!";
  #printf $fhout ("%-20.20s%-20.20s%-20.20sPGM / RUN BY / DATE \n",$SCRIPT."-v".$VERSION,$USER,$DATE)  or die "can't write RINEX PRM / RUN BY record: $!";      
  printf $fhout ("%-20.20s%-20.20s%-20.20sPGM / RUN BY / DATE \n",$SCRIPT,$USER,$DATE)  or die "can't write RINEX PRM / RUN BY record: $!";      

  return;
  
}

sub ReadRnxHdr{

  # Read the RINEX header and return the header lines
  # Usuage
  #  
  #    my $header=ReadRnxHdr($fhin);
  #
  # with $fhin the file handle and $header a pointer to the array with header lines
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($fhin)=@_;
  
  my @header=();
  while (<$fhin>) {
    s/\R\z//; # chomp();
    if ( eof($fhin) ) {
       die "No END OF HEADER record found in RINEX header, quiting...";
    }
    push @header,$_;
    last if ( uc(substr($_,60)) =~ /^END OF HEADER/);
  }
  return \@header;
  
}

sub WriteRnxHdr{

  # Write a RINEX header block. 
  # Usuage
  #  
  #    WriteRnxHdr($fhout,$header);
  #
  # with $fhout the file handle and $header a pointer to the array with header lines.
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($fhout,$header)=@_;;
  
  foreach (@{$header}) {
     print $fhout ($_,"\n") or die "can't write RINEX header: $!";
  }

  return;
  
}

sub ReadRnx2Data{

  # Read the RINEX 2 data and return the epoch, flag, sat.ids and data
  # Usuage
  #  
  #    my ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped)=ReadRnx2Data($fhin,$nobstyp2);
  #
  # with $fhin the file handle and $nobstyp2 the number of observation types
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($fhin,$obsid2)=@_;
  
  my ($epoch,$epoflag,$nsat,$clkoffset);
  my @data=();
  my @skipped=();
  
  my $nobstyp2 = scalar(@$obsid2);
  my $obsid2upd=[];

  # try to read the epoch header

  my $line;
  while (<$fhin>) {
    s/\R\z//; # chomp;
    if ( eof($fhin) ) {
      die "Premature EOF for RINEX file, quiting...";
    }
    $line=$_;
    # implement some checking here...., there can be spurious lines
    my $isepochheader=1;
    if ( substr($line,28,1) !~ /[0123456]/ ||  ( length($line) > 68 && substr($line,68) =~ /[A-Za-z_#\/]/ ) ) { 
      $isepochheader=0;
    }
    last if ($isepochheader == 1);
    # hey..., no epoch header; we have unexpected lines, put these into @skipped
    push @skipped,$line;
    # if RINEX 2 observation type record, update $obsid2 (may have changed) - this is non standard rinex-2
    if ( length($line) > 60 && substr($line,60)=~ /^# \/ TYPES OF OBSERV/ ) {
       $nobstyp2=substr($line, 0,6);
       for (my $i=0; $i < int(($nobstyp2-1)/9); $i++) {
          $line=<$fhin>;
          $line =~ s/\R\z//; # chomp($line);
          push @skipped,$line;
       }
       my ($receiver, $obsid3, $obsid2)=ScanRnxHdr(\@skipped);
       $obsid2upd=$obsid2;
    }
  }

  # process the epoch header

  $epoch=substr($line, 1,25);
  $epoflag= substr($line,28,1);
  $nsat=substr($line,29,3);

  if ( $epoch =~ /\d+/ ) {
    my $year=substr($epoch,0,2);
    if ($year > 80) {
      $year=$year+1900;
    } else {
      $year=$year+2000;
    }
    $epoch=sprintf("%04d %22s",$year,substr($epoch,3)); 
  } else {
    $epoch="  ".$epoch;
  }
  
  $clkoffset="               ";
  if ( $epoflag =~ /^[01]/ ) {
     if ( length($line) > 68 ) {
        $clkoffset=substr($line,68,12);
     }
     if ( $clkoffset =~ /\d/ ) {
        $clkoffset =~ s/\s+$//;   
        $clkoffset=pack("A15",$clkoffset."000");
     }
  }

  my $satids="";
  if ( $epoflag =~ /^[016]/ ) {
     my $tmp=$line;
     for (my $i=0; $i < int(($nsat-1)/12); $i++) {
        $satids.=substr($tmp,32,36);
        $tmp=<$fhin>;
        $tmp =~ s/\R\z//; # chomp($tmp);
     }
     $satids.=substr($tmp,32,(($nsat-1)%12+1)*3);
  }
    
  # Read data records

  my $ll=int(($nobstyp2-1)/5)+1;

  if ( $epoflag =~ /^[016]/ ) {
    # read observation records
    for (my $i=0; $i < $nsat;$i++) {
      my $sysid=substr($satids,$i*3,1);
      my $satnum=substr($satids,$i*3+1,2);
      my $obsrec=substr($satids,$i*3,3);
      for (my $l=0; $l < $ll;$l++) {
        my $tmp=<$fhin>;
        $tmp =~ s/\R\z//; # chomp($tmp);
        $tmp=pack("A80",$tmp);
        my $nobsi=$nobstyp2-$l*5;
        $nobsi=5 if ($nobsi > 5);
        $obsrec.=substr($tmp,0,$nobsi*16);
      }
      push @data,$obsrec;
    }
  } else {
    # read all other epoch data (comments etc)
    for (my $i=0; $i < $nsat;$i++) {
      my $tmp=<$fhin>;
      $tmp =~ s/\R\z//; # chomp($tmp);
      push @data,$tmp;
    }
  }
  if ( $epoflag =~ /4/ ) {
     my ($receiver, $obsid3, $obsid2)=ScanRnxHdr(\@skipped);
     $obsid2upd=$obsid2 if ( scalar(@$obsid2) > 0 );
  }
  
  return ($epoch,$epoflag,$clkoffset,$nsat,\@data,\@skipped,$obsid2upd);
  
}

sub WriteRnx2Data{

  # Write the RINEX 2 data to file
  # Usuage
  #  
  #    WriteRnx2Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$nobstyp2,$data);
  #
  # with $fhout the file handle.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($fhout,$epoch,$epoflag,$clkoffset,$nsat,$obsid2,$data)=@_;

  my $nobstyp2 = scalar(@$obsid2);

  # Write the epoch header

  my $line;
  if ( $clkoffset =~ /\d/ ) {
    $line=sprintf(" %-25.25s  %1d%3d%36s%-12.12s",substr($epoch,2),$epoflag,$nsat," ",substr($clkoffset,0,12));
  } else {
    $line=sprintf(" %-25.25s  %1d%3d%36s",substr($epoch,2),$epoflag,$nsat," ");
  }

  if ( $epoflag =~ /^[016]/ ) {
     my $j1=0;
     my $j2=0;
     for (my $i=0; $i < int(($nsat-1)/12)+1; $i++) {
        $j1=$j2;
        $j2=$j2+12;
        $j2=$nsat if ($j2 > $nsat);
        my $k=0;
        for (my $j=$j1; $j < $j2; $j++) {
           substr($line,32+$k*3,3)=substr($data->[$j],0,3);
           $k++;
        }
        print $fhout  ($line,"\n")  or die "can't write to RINEX 2 file";
        $line=sprintf("%68s"," ");
     }
  } else {
     print $fhout  ($line,"\n")  or die "can't write to RINEX 2 file";
  }
    
  # Write data records

  my $ll=int(($nobstyp2-1)/5)+1;

  if ( $epoflag =~ /^[016]/ ) {
     # Write observation records
     for (my $i=0; $i < $nsat;$i++) {
        my $j1=0;
        my $j2=0;
        my $tmp=$data->[$i];
        for (my $l=0; $l < $ll;$l++) {
          $j1=$j2;
          $j2=$j2+5;
          $j2=$nobstyp2 if ($j2 > $nobstyp2);
          print $fhout  (substr($tmp,3+$j1*16,($j2-$j1)*16),"\n")  or die "can't write to RINEX 2 file";
        }
     }
  } else {
     # Write all other epoch data (comments etc)
     for (my $i=0; $i < $nsat;$i++) {
        print $fhout  ($data->[$i],"\n")  or die "can't write to RINEX 2 file";
     }
  }

  return;
    
}

sub ReadRnx3Data{

  # Read the RINEX 3 data and return the epoch, flag, sat.ids and data
  # Usuage
  #  
  #    my ($epoch,$epoflag,$clkoffset,$nsat,$data,$skipped)=ReadRnx3Data($fhin);
  #
  # with $fhin the file handle
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($fhin)=@_;
  
  my ($epoch,$epoflag,$nsat,$clkoffset);
  my @data=();
  my @skipped=();

  # try to read the epoch header

  my $line;
  while (<$fhin>) {
    s/\R\z//; # chomp;
     if ( eof($fhin) ) {
      die "Premature EOF for RINEX file, quiting...";
    }
    # do some checking here...., there can be spurious lines
    $line=$_;
    last if ( /^\>\s/);
    # hey..., no epoch header; we have unexpected lines, put these into @skipped
    push @skipped,$line;
  }

  # process the epoch header

  $epoch=substr($line, 2,27);
  $epoflag=substr($line,31,1);
  $nsat=substr($line,32,3);
  $clkoffset="               ";
  if ( $epoflag =~ /[01]/ ) {
    if ( length($line) > 42 ) {
      $clkoffset=substr($line,42,15);
    }
  }

  # Read data records

  for (my $i=0; $i < $nsat;$i++) {
    $line=<$fhin>;
    $line =~ s/\R\z//; # chomp($line);
    push @data,$line;
  }

  return ($epoch,$epoflag,$clkoffset,$nsat,\@data,\@skipped);
  
}

sub WriteRnx3Data{

  # Write the RINEX 3 data to file
  # Usuage
  #  
  #    WriteRnx3Data($fhout,$epoch,$epoflag,$clkoffset,$nsat,$data);
  #
  # with $fhout the file handle.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($fhout,$epoch,$epoflag,$clkoffset,$nsat,$data)=@_;

  # Write the epoch header

  if ( $clkoffset =~ /\d/ ) {
    printf($fhout "> %27s  %1d%3d      %15s\n",$epoch,$epoflag,$nsat,$clkoffset)          or die "can't write to RINEX 3 file"; 
  } else {
    printf($fhout "> %27s  %1d%3d\n",$epoch,$epoflag,$nsat )  or die "can't write to RINEX 3 file"; 
  }

  # Write data records

  for (my $i=0; $i < $nsat;$i++) {
     print $fhout  ($data->[$i],"\n")  or die "can't write to RINEX 3 file";
  }

  return;
  
}

sub ScanRnxHdr{

  # Scan the RINEX header for receiver and observation type information
  # Usuage
  #  
  #    my ($receivertype,$obsid3,$obsid2)=ScanRnxHdr($rnxheader);
  #
  # with @{$rnxheader} an array with the header lines. The function return
  # the receiver type $receivertype, and if rinex-3 the rinex-3 observation 
  # types in the hash $obsid3, or else, the rinex-2 legacy observation types
  # in the array $obsid2. Note that $obsid2 is something (or actually its 
  # length) that is required for reading the remainder of the rinex-2 files!
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($rnxheader)=@_;

  my $receivertype="UNKNOWN";
  my $obsid3={};
  my $obsid2=[];
  
  my @wavelengthfact=();

  # Scan the RINEX header lines to get receiver and observation type info

  my $j=0;
  while ( $j < scalar(@$rnxheader) ) {

    my $line=$rnxheader->[$j]; 
    my $headid=uc(substr($line,60));
    $j++;
            
    
    if ( $headid =~ /^REC # \/ TYPE \/ VERS/ ) {
      # get receiver type
       $receivertype=substr($line,20,20);
    } elsif ( $headid =~ /^WAVELENGTH FACT L1\/2/) {
       # get WAVELENGTH FACT is only used by RINEX version 2
       push @wavelengthfact,$line;
    } elsif ( $headid =~ /^# \/ TYPES OF OBSERV/) {
       # Get RINEX 2 observation types record
       my $nobstyp2=substr($line, 0,6);
       my $obsid2str=substr(uc($line),6,54);
       for (my $i=0; $i < int(($nobstyp2-1)/9); $i++) {
         $line=$rnxheader->[$j];
         $j++;
         $obsid2str.=substr(uc($line),6,54);
       }
       @{$obsid2}=split(" ",$obsid2str);       
    } elsif ( $headid =~ /^SYS \/ # \/ OBS TYPES/) {
       # Get RINEX 3 observation types record
       my $sysid=substr($line,0,1);
       my $nobstyp3=substr($line, 3,3);
       my $obsid3str=substr(uc($line),6,54);
       for (my $i=0; $i < int(($nobstyp3-1)/13); $i++) {
         $line=$rnxheader->[$j];
         $j++;
         $obsid3str.=substr(uc($line),6,54);
      }
      @{$obsid3->{$sysid}}=split(" ",$obsid3str);
    }
  }

  return ($receivertype,$obsid3,$obsid2);
  
}

1;