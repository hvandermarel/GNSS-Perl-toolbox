#------------------------------------------------------------------------------
# 
# RINEX2/3 Perl functions
# 
#------------------------------------------------------------------------------
#
#   List of functions:
#   ------------------
#
#   Print RINEX2/3 observation types 
#      prtobstype2($fh,$obsid2);
#      prtobstype3($fh,$obsid3);
#
#   Print/format RINEX2/3 observation types as RINEX header
#      prtobshead2($fh,$obsid2);
#      prtobshead3($fh,$obsid3);
#      @header=fmtobshead2($obsid2);
#      @header=fmtobshead3($obsid3);
#
#   Convert RINEX2/3 observation types into a hash with RINEX3/2 obervation types
#      ($obsid3,$obs2idx)=obstype2to3($mixedfile,$obsid2,$cnvtable2to3 );
#      ($obsid2,$obs2idx)=obstype3to2($mixedfile,$obsid3,$cnvtable2to3 );
#
#   Print formatted RINEX2/3 observation type to RINEX3/2 conversion table
#      @lines=fmtcnvtable($obsid2,$obsid3,$obs2idx,$versin,$versout);
#
#   Compute the inverse RINEX2 to 3 observation index.
#      ($obs3idx)=invobsidx($obs2idx);
#
#   Print the observation index.
#      prtobsidx($fh,$obsidx);
#
#   Reorder observation fields in RINEX data array
#      $data=ReorderRnxData($nsat,$data,$obsidx);
#
#   Define all possible RINEX 2 and 3 observations based on a list of available signals
#      ($cnvtable2to3,$cnvtable3to2)=obstypedef($signaltypes);
#
#   Print the hash with observation type definitions and translations
#      prttypedef($fh,$cnvtable2to3);
#      prttypedef($fh,$cnvtable3to2);
#
#   Get signals supported by a particular receiver type.
#      ($signaltypes,$recvtype)=signaldef($receivertype);
#
#   Print the hash with signal type definitions 
#      prtsignaldef($fh,$signaltypes);
#
#   Return an array with logically sorted system ids present in the input hash
#      @sysids=sysids($signaltypes)
#
#   Return GLONASS slot number, SVN and sensor name
#      $glosat = glonassdata($date,$cfgfile);
#      prtglonassdata($glosat);
#      @header = glonassslothdr($glosat);
#
#   Data structures and variables:
#   ------------------------------
#
#   %{$signaltypes}  - hash with 2-char signaltypes (signaldef output)
#                      
#      The hash should be referenced as 
#  
#         $signals=$signaltypes->{$sysid}
#
#      with $sysid the 1-character systemid (G, R, E, C, J, I or S) and
#      $signals a reference to an array with 2-character strings (e.g. 1C,1P,..),
#      i.e. RINEX3 observation types without the leading type identification.
#      The signaltypes are defined in an Windows style ini-files
#      given in the __DATA__ section of this file. 
#
#   %{$cnvtable2to3} - hash with all possible RINEX2 to RINEX3 observation type translations 
#   %{$cnvtable3to2} - hash with all possible RINEX3 to RINEX2 observation type translations
# 
#      The $cnvtable2to3 and $cnvtable3to2 hashes should be referenced as 
#  
#         $id3=$cnvtable2to3->{$sysid}->{$id2}
#         $id2=$cnvtable3to2->{$sysid}->{$id3}
#
#      with $sysid the 1-character systemid (G, R, E, S, I, J, or C) and
#      $id2 and $id3 strings with observation ids. If the return string
#      $id2 or $id3 is blank there is no corresponding observation type. 
#
#   @{$obsid2}       - array with RINEX2 observation ids
#   %{$obsid3}       - hash with arrays of RINEX3 observation types for each system
#   %{$obs2idx}      - hash with indices to RINEX2 observation type matching $obsid3
# 
#      The $obsid2, $obsid3 and $obs2idx array/hashes should be referenced as 
#  
#         @obsid2list=@{$obsid2}
#         @obsid3list=@{$obsid3->{$sysid}}
#         @obsid2idx=@{$obs2idx->{$sysid}}
#
#      with $sysid the 1-character systemid (G, R, E, C, J, I or S), @obsid2list 
#      the array with RINEX2 observation types, @obsid3list the array with RINEX3 
#      observation types and @obs2idx giving the relationship between RINEX3 and
#      RINEX2 observation types, with
#
#         $i2=@{$obs2idx->{$sysid}}[$i3]
#
#      which gives corresponding RINEX 2 column number $i2 for the observation of
#      in RINEX 3 column $i3 for system $sysid (Column count starts with 0). If
#      $i2 is -99 there is not a corresponding RINEX2 observation.
#
#   %{$obs3idx}      - hash with indices to RINEX2 observation type matching $obsid2
#
#      $obs3idx gives the relationship between RINEX3 and RINEX2 observation types, with
#
#         $i3=@{$obs3idx->{$sysid}}[$i2]
#
#      which gives corresponding RINEX 3 column number $i3 for the observation 
#      in RINEX 2 column $i2 for system $sysid (Column count starts with 0). If
#      $i3 is -99 there is not a corresponding RINEX3 observation.
#
#
#   @{$data}         - =ReorderRnxData($nsat,$data,$obsidx);
#   $nsat
#   %{$obsidx}       - either %{$obs2idx} or %{$obs3idx} 
#
#   $mixedfile       - 1-char string with the RINEX filetype ("M" for mixed)
#   $receivertype    - receiver type or class (signaldef input)
#   $rcvrtype        - resolved receiver class (signaldef output)
#   @{$signals}      - array with 2-char signal types for a particular system
#   @sysids          - array with logically sorted system ids (sysids output)
#
#   Examples
#   --------
#
#   Return GLONASS slot number, SVN and sensor name
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
# Created:   9 September 2011 by Hans van der Marel
# Modified: 11 February 2012 by Hans van der Marel
#              - Public version for testing
#           22 February 2019 by Hans van der Marel
#              - major changes and new functions
#              - renamed package to librnxsys.pl (was rnxsub.pl)
#           20 June 2025 by Hans van der Marel
#              - moved functions from rnxedit to this library
#              - refactored and modified several functions
#              - updated the description in the header
#           22 June 2025 by Hans van der Marel
#              - checked with strict pragma and filled in missing declararions
#              - added Apache 2.0 license notice
#              - functions to retrieve GLONASS SVN, slot number and sensor name
#           25 June 2025 by Hans van der Marel
#              - use tell and seek to rewind DATA to original position so that
#                reading this section multiple times work
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

use strict;
use warnings;

sub prtobstype2{

  # Print RINEX2 observation types 
  # Usuage
  #
  #   prtobstype2($fh,$obsid2);
  #
  # with $fd the filehandle and $obsid2 the pointer to the array with RINEX2 
  # observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.


  my ($fh,$obsid2) = @_;

  print $fh ("\nRINEX 2 observation types (input):\n\n"); 

  my $nobs2=scalar(@{$obsid2});

  my $i1=0;
  my $i2= $nobs2 >= $i1+9 ? $i1+9 : $nobs2;
  my $obsid2str="    ".join("    ",@{$obsid2}[$i1...$i2-1]);
  printf $fh ("%6d%-54.54s\n",$nobs2,$obsid2str)  or die "can't write to RINEX2 observation types: $!";      
  for (my $i=0; $i < int(($nobs2-1)/9); $i++) {
    $i1=$i1+9;
    $i2= $nobs2 >= $i1+9 ? $i1+9 : $nobs2;
    $obsid2str="    ".join("    ",@{$obsid2}[$i1...$i2-1]);
    printf $fh ("      %-54.54s\n",$obsid2str)  or die "can't write RINEX2 observation types: $!";      
  }
  print $fh ("\n\n");

  return;
}

sub prtobstype3{

  # Print RINEX3 observation types 
  # Usuage
  #
  #   prtobstype3($fh,$obsid3);
  #
  # with $fd the filehandle and $obsid3 the reference to the hash with RINEX3
  # observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($fh,$obsid3)=@_;

  print $fh ("\nRINEX 3 observation types (output):\n\n"); 

  #foreach my $sysid (keys(%{$obsid3})) {
  foreach my $sysid (sysids($obsid3)) {
    my @obsid3list=@{$obsid3->{$sysid}};
    my $nobs3=scalar(@obsid3list);
    my $i1=0;
    my $i2= $nobs3 >= $i1+13 ? $i1+13 : $nobs3;
    my $obsid3str=join(" ",@obsid3list[$i1...$i2-1]);
    printf $fh ("%1s  %3d %-52.52s\n",$sysid,$nobs3,$obsid3str)  or die "can't write RINEX3 observation types: $!";      
    for (my $i=0; $i < int(($nobs3-1)/13); $i++) {
      $i1=$i1+13;
      $i2= $nobs3 >= $i1+13 ? $i1+13 : $nobs3;
      $obsid3str=join(" ",@obsid3list[$i1...$i2-1]);
      printf $fh ("       %-52.52s\n",$obsid3str)  or die "can't write RINEX3 observation types: $!";      
    }
  }
  print $fh ("\n\n");

  return;

}

sub prtobshead2{

  # Print RINEX2 observation types as RINEX2 header
  # Usuage
  #
  #   prtobshead2($fh,$obsid2);
  #
  # with $fd the filehandle and $obsid2 the pointer to the array with RINEX2 
  # observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.

   my ($fh,$obsid2)=@_;

   my $nobs=scalar(@{$obsid2});

   my $i1=0;
   my $i2= $nobs >= $i1+9 ? $i1+9 : $nobs;
   my $obsid2str="    ".join("    ",@{$obsid2}[$i1...$i2-1]);
   printf $fh ("%6d%-54.54s# / TYPES OF OBSERV \n",$nobs,$obsid2str)  or die "can't write to RINEX2 observation types: $!";      
   for (my $i=0; $i < int(($nobs-1)/9); $i++) {
        $i1=$i1+9;
        $i2= $nobs >= $i1+9 ? $i1+9 : $nobs;
        $obsid2str="    ".join("    ",@{$obsid2}[$i1...$i2-1]);
        printf $fh ("      %-54.54s# / TYPES OF OBSERV \n",$obsid2str)  or die "can't write RINEX2 observation types: $!";      
   }

}

sub prtobshead3{

  # Print RINEX3 observation types as RINEX3 header
  # Usuage
  #
  #   prtobshead3($fh,$obsid3);
  #
  # with $fd the filehandle and $obsid3 the reference to the hash with RINEX3
  # observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.

   my ($fh,$obsid3)=@_;

   #foreach my $sysid (keys(%{$obsid3})) {
   foreach my $sysid (sysids($obsid3)) {
      my @obsid3list=@{$obsid3->{$sysid}};
      my $nobs3=scalar(@obsid3list);
      my $i1=0;
      my $i2= $nobs3 >= $i1+13 ? $i1+13 : $nobs3;
      my $obsid3str=join(" ",@obsid3list[$i1...$i2-1]);
      printf $fh ("%1s  %3d %-52.52s SYS / # / OBS TYPES \n",$sysid,$nobs3,$obsid3str)  or die "can't write to output file: $!";      
      for (my $i=0; $i < int(($nobs3-1)/13); $i++) {
         $i1=$i1+13;
         $i2= $nobs3 >= $i1+13 ? $i1+13 : $nobs3;
         $obsid3str=join(" ",@obsid3list[$i1...$i2-1]);
         printf $fh ("       %-52.52s SYS / # / OBS TYPES \n",$obsid3str)  or die "can't write to output file: $!";      
      }
   }

}

sub fmtobshead2{

  # Format RINEX2 observation types as RINEX2 header
  # Usuage
  #
  #   @header=fmtobshead2($obsid2);
  #
  # with $obsid2 the pointer to the array with RINEX2 observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.

   my ($obsid2)=@_;

   my @header=();
   
   my $nobs=scalar(@{$obsid2});

   my $i1=0;
   my $i2= $nobs >= $i1+9 ? $i1+9 : $nobs;
   my $obsid2str="    ".join("    ",@{$obsid2}[$i1...$i2-1]);
   push @header,sprintf("%6d%-54.54s# / TYPES OF OBSERV ",$nobs,$obsid2str);      
   for (my $i=0; $i < int(($nobs-1)/9); $i++) {
        $i1=$i1+9;
        $i2= $nobs >= $i1+9 ? $i1+9 : $nobs;
        $obsid2str="    ".join("    ",@{$obsid2}[$i1...$i2-1]);
        push @header,sprintf("      %-54.54s# / TYPES OF OBSERV ",$obsid2str);  
   }

   return @header;

}

sub fmtobshead3{

  # Format RINEX3 observation types as RINEX3 header
  # Usuage
  #
  #   my @header=fmtobshead3($obsid3);
  #
  # with $obsid3 the reference to the hash with RINEX3 observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.

   my ($obsid3)=@_;

   my @header=();
   
   #foreach my $sysid (keys(%{$obsid3})) {
   foreach my $sysid (sysids($obsid3)) {
      my @obsid3list=@{$obsid3->{$sysid}};
      my $nobs3=scalar(@obsid3list);
      my $i1=0;
      my $i2= $nobs3 >= $i1+13 ? $i1+13 : $nobs3;
      my $obsid3str=join(" ",@obsid3list[$i1...$i2-1]);
      push @header,sprintf("%1s  %3d %-52.52s SYS / # / OBS TYPES ",$sysid,$nobs3,$obsid3str);      
      for (my $i=0; $i < int(($nobs3-1)/13); $i++) {
         $i1=$i1+13;
         $i2= $nobs3 >= $i1+13 ? $i1+13 : $nobs3;
         $obsid3str=join(" ",@obsid3list[$i1...$i2-1]);
         push @header,sprintf("       %-52.52s SYS / # / OBS TYPES ",$obsid3str);      
      }
   }

   return @header;
}

sub obstype2to3{

  # Convert RINEX2 observation types into a hash with RINEX3 obervation types
  # Usuage
  #
  #   my ($obsid3,$obs2idx)=obstype2to3($mixedfile,$obsid2,$cnvtable2to3 );
  #
  # with $mixedfile a 1-char string with the RINEX filetype ("M" for mixed),
  # $obsid2 (\@obsid2) reference to the array with RINEX2 observation ids,
  # and $cnvtable2to3 a hash reference for the conversion table for RINEX2 to
  # RINEX3 observation types. 
  # 
  # The function returns pointers to two hashstructures with respectively
  # the RINEX3 observation types and a index to the corresponding RINEX2
  # observation type in $obsid2. 
  # The output hashes should be referenced as 
  #  
  #    @obsid3list=@{$obsid3->{$sysid}}
  #    @obsid2idx=@{$obs2idx->{$sysid}}
  #
  # with $sysid the 1-character systemid (G, R, E, S, or C) and
  # @obsid3list the array with RINEX3 observation types and
  # @obsids2idx the correcponding observation in the RINEX2 obervation
  # list, i.e.
  #
  #    $i2=@{$obs2idx->{$sysid}}[$i3]
  #
  # which gives corresponding RINEX 2 column number $i2 for the observation of
  # in RINEX 3 column $i3 for system $sysid (Column count starts with 0). If
  # it $i2 is -99 there is not a corresponding RINEX2 observation (which
  # should not happen in this case, because when we go from RINEX2 to RINEX3
  # we should always have a matching observation). 
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($mixedfile,$obsid2,$cnvtable2to3) = @_;

  my $obsid3={};
  my $obs2idx={};

  my @sysids=();
  if ( $mixedfile =~ /M/i ) {
    # must come from definitions file
    @sysids=keys(%{$cnvtable2to3});
  } else {
    @sysids=split(//,uc($mixedfile));
  }
  
  foreach my $sysid (@sysids) {
    $obsid3->{$sysid}=();
    $obs2idx->{$sysid}=();
    my $j=0;
    foreach my $obstype2 (@$obsid2) {
      if ( exists($cnvtable2to3->{$sysid}->{$obstype2}) ) {
        my $obstype3=$cnvtable2to3->{$sysid}->{$obstype2};
        push @{$obsid3->{$sysid}} , $obstype3;
        push @{$obs2idx->{$sysid}} , $j;
      }
      $j++;
    }
  }

  return ($obsid3,$obs2idx);

} 

sub obstype3to2{

  # Convert hash with RINEX3 observation types into RINEX2 obervation types
  # Usuage
  #
  #   my ($obsid2,$obs2idx)=obstype3to2($mixedfile,$obsid3,$cnvtable2to3 );
  #
  # with $mixedfile a 1-char string with the RINEX filetype ("M" for mixed),
  # $obsid3 (\%obsid3) reference to the hash with RINEX3 observation ids,
  # and $cnvtable3to2 a hash reference for the conversion table for RINEX3 to
  # RINEX2 observation types. 
  # 
  # The function returns two pointers respectively to a array with 
  # the RINEX2 observation types and a hash with the index to the corresponding 
  # RINEX3 observation type in $obsid3. 
  # The output should be referenced as 
  #  
  #    @obsid2list=@{$obsid2}
  #    @obsid2idx=@{$obs2idx->{$sysid}}
  #
  # with $sysid the 1-character systemid (G, R, E, S, or C) and
  # @obsid2list the array with RINEX2 observation types and
  # @obsids2idx the correcponding observation in the RINEX2 obervation
  # list, i.e.
  #
  #    $i2=@{$obs2idx->{$sysid}}[$i3]
  #
  # which gives corresponding RINEX 2 column number $i2 for the observation of
  # in RINEX 3 column $i3 for system $sysid (Column count starts with 0). If
  # it $i2 is -99 there is not a corresponding RINEX2 observation (which
  # should not happen in this case, because when we go from RINEX2 to RINEX3
  # we should always have a matching observation). 
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($mixedfile,$obsid3,$cnvtable3to2) = @_;

  my $obsid2=();
  my $obs2idx={};

  my @sysids=();
  if ( $mixedfile =~ /M/i ) {
    # must come from definitions file
    @sysids=sysids($obsid3);
  } else {
    @sysids=split(//,uc($mixedfile));
  }

  # make array with of RINEX2 observation types
  
  my $tmpid2={};
  my $k=0;
  foreach my $sysid (@sysids) {
    $obs2idx->{$sysid}=();
    foreach my $obstype3 (@{$obsid3->{$sysid}}) {
      if ( exists($cnvtable3to2->{$sysid}->{$obstype3}) && $cnvtable3to2->{$sysid}->{$obstype3} !~ m/^\s*$/ ) {
        my $obstype2=$cnvtable3to2->{$sysid}->{$obstype3};
        if ( ! exists($tmpid2->{$obstype2}) ) {
           $tmpid2->{$obstype2}=$k;
           $k++;
           push @{$obsid2} , $obstype2;
        }
      }
    }
  }

  # make the index to entries in the RINEX3 observations

  my $nan=-99;
  foreach my $sysid (@sysids) {
    $obs2idx->{$sysid}=();
    my $j=0;
    foreach my $obstype3 (@{$obsid3->{$sysid}}) {
      if ( exists($cnvtable3to2->{$sysid}->{$obstype3}) && $cnvtable3to2->{$sysid}->{$obstype3} !~ m/^\s*$/ ) {
        my $obstype2=$cnvtable3to2->{$sysid}->{$obstype3};
        push @{$obs2idx->{$sysid}} , $tmpid2->{$obstype2};
      } else {
        push @{$obs2idx->{$sysid}} , $nan;     
      }
      $j++;
    }
  }

  return ($obsid2,$obs2idx);

} 

sub fmtcnvtable{

  # Print formatted RINEX3 to RINEX2 observation type conversion table.
  # Usuage
  #
  #   @lines=fmtcnvtable($obsid2,$obsid3,$obs2idx,$versin,$versout);
  #
  # with $obsid2 (\@obsid2) reference to the array with RINEX2 observation ids,
  # and  $obsid3 and $obs2idx a reference to a hashstructures with respectively
  # the RINEX3 observation types and a index to the corresponding RINEX2
  # observation type in $obsid2. 
  # The input hashes should be referenced as 
  #  
  #    @obsid3list=@{$obsid3->{$sysid}}
  #    @obsid3idx=@{$obs2idx->{$sysid}}
  #
  # with $sysid the 1-character systemid (G, R, E, S, J, I or C) and
  # @obsid3list the array with RINEX3 observation types and
  # @obsid3idx the corresponding observation in the RINEX2 obervation
  # list.
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($obsid2,$obsid3,$obs2idx,$versin,$versout) = @_;
  my @lines=();
  my $headerline="";
  
  my $nan=-99;
  
  my $nobs2=scalar(@{$obsid2});
  
  my $upconvert;
  if ($versin < 3.00 && $versout > 2.99 ) {
     $upconvert=1;
  } elsif ($versin > 2.99 && $versout < 3.00 ) {
     $upconvert=0;
  } else {
    return @lines;
  }  

  my $obs3idx=invobsidx($obs2idx);
  
  push @lines, "RINEX OBSERVATION TRANSLATION: ".sprintf("%.2f",$versin)." -> ".sprintf("%.2f",$versout);

  if ( $upconvert ) {

    # UPCONVERT:  RINEX2 -> RINEX3

    $headerline="           ";
    foreach my $sysid (sysids($obsid3)) {
      $headerline .= sprintf("%-8.8s",$sysid);
    }
    push @lines, $headerline;

    for (my $i=0; $i < $nobs2; $i++) {
      my $line=sprintf("%-2.2s(%2.0f) -> ",@{$obsid2}[$i],$i+1);
      foreach my $sysid (sysids($obsid3)) {
        my $j=$nan;
        $j=@{$obs3idx->{$sysid}}[$i] if ($i < scalar(@{$obs3idx->{$sysid}}));
        if ( $j != $nan ) {
          $line .= sprintf("%-3.3s(%2.0f) ",@{$obsid3->{$sysid}}[$j],$j+1);
        } else {
          $line .= "        ";
        }
      }
      push @lines, $line;
    }
 
  } else {

    # DOWNCONVERT:  RINEX3 -> RINEX 2

    $headerline=" ";
    foreach my $sysid (sysids($obsid3)) {
      $headerline .= sprintf("%-8.8s",$sysid);
    }
    push @lines, $headerline;

    for (my $i=0; $i < $nobs2; $i++) {
      my $line="";
      foreach my $sysid (sysids($obsid3)) {
        my $j=@{$obs3idx->{$sysid}}[$i];
        if ( $j != $nan ) {
          $line .= sprintf("%-3.3s(%2.0f) ",@{$obsid3->{$sysid}}[$j],$j+1);
        } else {
          $line .= "        ";
        }
      }
      $line .= sprintf("-> %-2.2s(%2.0f)",@{$obsid2}[$i],$i+1);
      push @lines, $line;
    }

    push @lines, "RINEX OBSERVATION TRANSLATION: UNUSED RINEX3 TYPES";
    
    my $missing={};
    my $kk=0;
    foreach my $sysid (sysids($obs2idx)) {
      @{$missing->{$sysid}}=();
      my $j=0;
      my $k=0;
      foreach my $i (@{$obs2idx->{$sysid}}) {
        if ( $i == $nan ) {
          push @{$missing->{$sysid}},$j;
          $k++;
        }
        $j++;
      }
      $kk=$k if $k > $kk; 
    }  

    push @lines, $headerline;
    for (my $i=0; $i < $kk; $i++) {
      my $line="";
      foreach my $sysid (sysids($missing)) {
        if ( $i < scalar(@{$missing->{$sysid}}) ) {
          my $j=@{$missing->{$sysid}}[$i];
          $line=$line.sprintf("%-3.3s(%2.0f) ",@{$obsid3->{$sysid}}[$j],$j+1);
        } else {
          $line=$line."        ";
        }
      }
      push @lines, $line;
    }

  }

  return @lines;
}

sub invobsidx{

  # Compute the inverse RINEX2 to 3 observation index.
  # Usuage
  #
  #    my ($obs3idx)=invobsidx($obs2idx);
  #
  # with $obs2idx and $obs3idx references to hash arrays with the indexes.
  # The hashes are defined as follows
  #
  #    $i2=@{$obs2idx->{$sysid}}[$i3]
  #    $i3=@{$obs3idx->{$sysid}}[$i2]
  #
  # where $i2 is the RINEX 2 column number and $i3 the RINEX3 column number 
  # The column count starts with 0!. If -99 is returned there is not a 
  # corresponding observation (which should only happen when going from
  # RINEX 3 to 2).
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($obs2idx)=@_;

  my $obs3idx={};
  my $nan=-99;
  
  my $nobs2=0;
  foreach my $sysid (sysids($obs2idx)) {
    foreach my $i (@{$obs2idx->{$sysid}}) {
       $nobs2=$i+1 if ($i+1 > $nobs2);
    }
  }
  my @tmp3idx=();
  for ( my $i=0; $i<$nobs2; $i++ ) {
     push @tmp3idx, $nan;
  }
  foreach my $sysid (sysids($obs2idx)) {
    @{$obs3idx->{$sysid}}=@tmp3idx;
    my $j=0;
    foreach my $i (@{$obs2idx->{$sysid}}) {
       if ( $i != $nan ) {
        @{$obs3idx->{$sysid}}[$i]=$j;
      }
      $j++;
    }
  }

  return ($obs3idx);

}

sub prtobsidx{

  # Print the observation index.
  # Usuage
  #
  #    prtobsidx($fh,$colidx);
  #
  # with $colidx being either $obs2idx or $obs3idx references to hash arrays 
  # with the indexes. The hashes are defined as follows
  #
  #    $i2=@{$obs2idx->{$sysid}}[$i3]
  #    $i3=@{$obs3idx->{$sysid}}[$i2]
  #
  # which $i2 the RINEX 2 column number and $i3 the RINEX3 column number 
  # The column count starts with 0!. If -99 is returned there is not a 
  # corresponding observation (which should only happen when going from
  # RINEX 3 to 2).
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($fh,$colidx)=@_;
  
  for my $sysid ( keys(%{$colidx}) ) {
     print $fh ($sysid, ": ");
     for my $id (@{$colidx->{$sysid}})  {
        print $fh (" ".$id);
     }
     print $fh ("\n");
  }
  
}

sub ReorderRnxData{

  # Reorder observation fields in RINEX data array
  # Usuage
  #  
  #    $data=ReorderRnxData($data,$obsidx);
  #
  # with $data a reference to an array of RINEX observation records and $obsidx 
  # a refererence to the hash with reordering information.
  # 
  # Each observations record consists of a satellite id in the first 3 
  # characters, folowed by blocks of 16 characters with the observation data. 
  #
  # $obsidx is a references to hash which is defined as follows
  #
  #    $iold=@{$obsidx->{$sysid}}[$inew]
  #
  # which $inew the new RINEX column number for the output and $iold the 
  # corresponding RINEX column number in the original data record.
  # The column count starts with 0!. If -99 is returned there is not a 
  # corresponding observation, in which case blanks are inserted.
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($data,$obsidx)=@_;
  
  my $nan=-99;
  my $empty="                ";
  my $dataout=[];

  # Reorder the observation records
  for my $orgrec (@{$data}) {
    my $sysid=substr($orgrec,0,1);
    my $newrec=substr($orgrec,0,3);
    my $inew=0;
    my $lastobs=int((length($orgrec)-4)/16)+1;
    #print STDERR "$orgrec\n";
    #print STDERR "$lastobs\n";
    $orgrec.="  ";
    foreach my $iold (@{$obsidx->{$sysid}}) {
      #print STDERR "--> $i $inew  $iold \n";
      if ( ( $iold != $nan ) && ( $iold <= $lastobs ) ) {
        $newrec.=substr($orgrec,$iold*16+3,16);
      } else {
        $newrec.=$empty;
      }
      $inew++;
    }
    if ( $inew > 0 ) {
      push @{$dataout}, $newrec;
    }
  }

  return $dataout;
  
}

sub obstypedef{

  # Define all possible RINEX 2 and 3 observation based on a list of 
  # available signals
  # Usuage
  #
  #    my ($cnvtable2to3,$cnvtable3to2)=obstypedef($signaltypes);
  #
  # with $signaltypes a hash reference with available signals for a 
  # particular receiver. The output consists of hash references 
  # $cnvtable2to3 and $cnvtable3to2 that lists all possible relations
  # between RINEX2 and RINEX3 observation types and vice versa.  
  # The output hashes should be referenced as 
  #  
  #    $id3=$cnvtable2to3->{$sysid}->{$id2}
  #    $id2=$cnvtable3to2->{$sysid}->{$id3}
  #
  # with $sysid the 1-character systemid (G, R, E, S, I, J, or C) and
  # $id2 and $id3 strings with observation ids. If the return
  # string $id2 or $id3 is blank there is no corresponding 
  # observation type. 
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($signaltypes)=@_;

  my $cnvtable2to3={};
  my $cnvtable3to2={};
  
  for my $sysid ( keys(%{$signaltypes}) ) {
     # print "$sysid = ", $signaltypes->{$sysid}, "\n";
     $cnvtable2to3->{$sysid}={};
     $cnvtable3to2->{$sysid}={};
     for my $na ( split(" ",$signaltypes->{$sysid}) ) {
        for my $t ( split(//,"CLDS") ) {
           my $id3=$t.$na;
           my $id2;
           if ( ( $t =~ /C/ ) && ( $na =~ /^\d[PWDYM]$/ ) ) {
             $id2="P".substr($na,0,1);
           } else {
             $id2=$t.substr($na,0,1);
           }
           if ( ! exists($cnvtable2to3->{$sysid}->{$id2} ) ) {
              $cnvtable2to3->{$sysid}->{$id2}=$id3;
              $cnvtable3to2->{$sysid}->{$id3}=$id2;
           } else {
              $cnvtable3to2->{$sysid}->{$id3}="  ";
           }
        }
     }
  }

  return ($cnvtable2to3,$cnvtable3to2);

}

sub prttypedef{

  # Print the hash with observation type definitions and translations
  # Usuage
  #
  #   prttypedef($fh,$cnvtable2to3);
  #   prttypedef($fh,$cnvtable3to2);
  #
  # with $fd the filehandle and the second argument the reference to the hash 
  # observation type definitions.
  #
  # (c) Hans van der Marel, Delft University of Technology.

   my ($fh,$typedef)=@_;

   for my $sysid ( keys(%{$typedef}) ) {
      print $fh ($sysid, ": ");
      for my $id ( keys(%{$typedef->{$sysid}}) ) {
        print $fh ("$id->", $typedef->{$sysid}->{$id}, "; ");
      }
      print $fh ("\n");
   }

}


sub signaldef{

  # Get signals supported by a particular receiver type.
  # Usuage
  #
  #    my ($signaltypes,$recvtype)=signaldef($receivertype);
  #
  # with $ receivertype a string with the receiver name and
  # $signaltypes a hash reference with signals supported by this
  # receiver and the selected receivertype. The hash should be referenced as 
  #  
  #    $signals=$signaltypes->{$sysid}
  #
  # with $sysid the 1-character systemid (G, R, E, S, or C) and
  # $signals a string with supported signals for each system.
  # The signals are 2-character strings (e.g. 1C,1P,..), i.e.
  # RINEX3 observation types without the leading type identification.
  #
  # The signaltypes are defined in an Windows style ini-files
  # given in the __DATA__ section of this file. 
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($rcvrtype)=@_;
  
  my $ini = {};
  my $header;
     
  my $data_start = tell DATA; # save the position
  while (<DATA>) {
    chomp;
    # ignore blank lines
    next if /^\s*$/;
    # ignore commented lines
    next if /^\s*\;|#/;
    # check for section header
    if ( /^\s*\[([^\]]+)\]/ ) {
      $header = $1;
      # remove leading and trailing white spaces
      $header =~ s/^\s*|\s*$//g;
      $ini->{$header} = {};
    }
    # check for section data
    if (/(\S+)\s*[=:]\s*(.*?)\s*$/) {
      $ini->{$header}->{$1} = $2;
    }
  }
  seek DATA, $data_start, 0;  # reposition the filehandle right past __DATA__

  # the data could be printed as $ini->{SECTION_HEADER}->{key}
  #for my $sysid ( keys(%{$ini->{$rcvrtype}}) ) {
  #   print "$sysid: ", $ini->{$rcvrtype}->{$sysid}, "\n";
  #}

  # remove leading and trailing white spaces from receiver type
  $rcvrtype =~ s/^\s*|\s*$//g;
  $rcvrtype=uc($rcvrtype);
  if ( ! exists($ini->{$rcvrtype}) ) {
     print STDERR ("\n+------------------------------------------------------+\n");
     print STDERR   ("| WARNING: RECEIVER TYPE NOT FOUND, SELECTED DEFAULT!! |\n");
     print STDERR   ("|           -- USE AT YOUR OWN RISK --                 |\n");
     print STDERR   ("+------------------------------------------------------+\n");
     $rcvrtype="DEFAULT";
  }

  return ($ini->{$rcvrtype},$rcvrtype);

}

sub prtsignaldef{

  # Print the hash with signal type definitions 
  # Usuage
  #
  #   prtsignaldef($fh,$signaltypes);
  #
  # with $fd the filehandle and the second argument the reference to the hash 
  # with signal type definitions.
  #
  # the data could be printed as $ini->{SECTION_HEADER}->{key}
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($fh,$signaltypes)=@_;
    
  for my $sysid ( keys(%{$signaltypes}) ) {
     print $fh "$sysid: ", $signaltypes->{$sysid}, "\n";
  }

}

sub sysids{

  # Return an array with sorted system ids present in the input hash
  # Usage:
  #
  #     @sysids=sysids($signaltypes)
  #
  # The output is a logically sorted list of system ids (with GPS first).
  # Input is a hash reference.
  # This function is intended to replace the statement keys(%{$signaltypes}))
  # by  sysids($signaltypes)  to get a logically sorted list of system ids.
  #
  # (c) Hans van der Marel, Delft University of Technology.

  my ($signaltypes)=@_;
  
  my $sysidin=join("",keys(%{$signaltypes}));
  my $sysidall="GRECJIS";
  $sysidall   =~ s/[^$sysidin]//g ;
  
  my @sysids=split(//,$sysidall);
  
  return @sysids;

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
  
  open(GLONASS, $glofile) or die("Could not open file $glofile.");
  while (my $line = <GLONASS>) { 
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
  close GLONASS;
  
  return \%glosat;
}

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

1;
__DATA__
# Definition of signal types (RINEX 3 style) for various GNSS receivers.
# The order is important in case of multiple signals per frequency:
# for conversion to RINEX version 2 the first signal of a particular
# frequency will be used for the pseudo-range, carrier-phase, doppler 
# and snr, of the second signal (of that frequency) only the pseudo-range
# is used.
# 
# Compiled by Hans van der Marel, last update 18-Sep-2011, 19-Jun-2025

[Aliases]
TRIMBLE NETR9: NETR9, NETR5
SEPT MOSAIC-X5: SEPT POLARX5
DEFAULT: TOPCON
                                                                                                               
[TRIMBLE NETR9]
G: 1C 2W 2X 5X
R: 1C 1P 2P 2C 
E: 1X 5X 7X 8X 
S: 1C  

[SEPT MOSAIC-X5]
G: 1C 1W 2W 2L 5Q
R: 1C 1P 2C 2P
E: 1C 5Q 7Q 8Q
S: 1C 5I

[SEPT POLARX5]
G: 1C 1W 2W 2L 5Q
R: 1C 1P 2C 2P 3Q
E: 1C 5Q 7Q 8Q
C: 1P 5P 2I 7I 6I 
S: 1C 5I

[GPS12]
G: 1C 1W 2W 2L 2X

[GPS125]
G: 1C 1W 2W 2L 2X 5Q

[GRS12]
G: 1C 1W 2W 2L 2X
R: 1C 1P 2C 2P
S: 1C

[GRES12]
G: 1C 1W 2W 2L 2X
R: 1C 1P 2C 2P
E: 1C 7Q
S: 1C

[GRES125]
G: 1C 1W 2W 2L 2X 5Q
R: 1C 1P 2C 2P 3Q
E: 1C 5Q 7Q 8Q
S: 1C 5I

[DEFAULT]
G: 1C 1W 2W 2X 
R: 1C 1P 2P 2C
S: 1C 
