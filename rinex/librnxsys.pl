#------------------------------------------------------------------------------
# 
# RINEX2/3 Perl functions
# 
#------------------------------------------------------------------------------
#
#   RINEX observation type printing and formatting functions:
#   ---------------------------------------------------------
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
#   Replace and/or splice records in the rinex header 
#      $header = rnxheadersplice($header,$newrecords);
#
#   RINEX observation type translation functions:
#   ---------------------------------------------
#
#   Translate RINEX observation types into RINEX3 obervation types and vice versa
#      ($obsid3,$obs2idx)=obstype2to3($mixedfile,$obsid2,$cnvtable2to3 );
#      ($obsid2,$obs2idx)=obstype3to2($mixedfile,$obsid3,$cnvtable2to3 );
#
#   Print formatted RINEX2/3 observation type to RINEX3/2 translation table
#      @lines=fmtcnvtable($obsid2,$obsid3,$obs2idx,$versin,$versout);
#
#   Compute the RINEX2 to 3 observation index.
#      ($obs3idx)=invobsidx($obs2idx);
#
#   RINEX Observation type sorting and removal functions:
#   -----------------------------------------------------
#
#   Sort observation types
#      ($obsid3,$obsidx)=rnxobstype3sort($obsid3, $obsidx, $select);
#      ($obsid2,$indices)=rnxobstype2sort($obsid2, $indices, $select);
#
#   Remove observation types
#      ($obsid3,$obsidx)=rnxobstype3rm($obsid3, $obsidx, $rmspec);
#      ($obsid2,$obsidx)=rnxobstype2rm($obsid2, $obsidx, $rmspec);
#
#   Indexing and data reordering functions:
#   ---------------------------------------
#
#   Initialize the observation index.using RINEX2/3 observation types
#      $obsidx = iniobsidx2($obsid2,$satsys);
#      $obsidx = iniobsidx3($obsid3);
#
#   Print the observation index.
#      prtobsidx($fh,$obsidx);
#
#   Reorder observation fields in RINEX data array
#      $data=ReorderRnxData($nsat,$data,$obsidx);
#
#   RINEX observation type definition functions:
#   --------------------------------------------
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
#   Glonass meta data functions:
#   ----------------------------
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
#   %{$obsidx}       - hash with indices to column numbers in the input RINEX data 
#                      file,  
#
#      The position $iold in the original rinex file is given by
#
#         $iold=@{$obsidx->{$sysid}}[$inew]  for $inew=0 .. $#{$obsidx->{$sys}}  
#
#      with $inew the new position in the RINEX file. If $iold equal -99, then
#      the original observation should be removed by inserting blanks.
#
#      Two special cases of $obsidx are either %{$obs2idx} or %{$obs3idx}. 
#
#   %{$colidx}       - Alternative name for $obsidx.
#   @{colidx2}       - Array with indices for @{$obsid2}, same role and function
#                      as %{$colidx}, but specific for rinex 2 observation types
#                      that does not differentiate between systems 
#
#   @{$data}         - Array holding the actual RINEX data for a single epoch
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
#           29 June 2025 by Hans van der Marel
#               - added rnxobstype3sort, rnxobstype2sort, rnxobstype3rm,
#                 rnxobstype2rm, iniobsidx2 and iniobsidx3 functions
#               - added rnxheadersplice function
#               - updated documentation
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


###########################################################################
# RINEX observation type printing and formatting functions
###########################################################################

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

sub rnxheadersplice{

   # Replace and/or splice records in the rinex header 
   # Usuage:
   #
   #   $header = rnxheadersplice($header,$newrecords);
   #
   # with @{$header} the header records and @{$newrecords} the 
   # new records to replace the ones in or insert at the end of
   # @{$header}. 
   #
   # (c) Hans van der Marel, Delft University of Technology.

   my ($header,$newrecords)=@_;
   
   my %modify=();
   foreach my $line (@$newrecords) {
       my $recid=substr($line,60);$recid =~ s/\s*$//;
       $modify{$recid}++;
   }

   foreach my $recid ( keys %modify ) {
       my $index  = [ grep { substr($header->[$_],60) =~ /$recid/ } 0..$#{$header} ] ;
       my $new  = [ grep { substr($_,60) =~ /$recid/ } @$newrecords ];
       my $length = scalar(@$index);
       if ( $length == 0 ) {
          splice @{$header},-1,0,@$new;
          #print $fherr "Inserted $modify{$recid} \"$recid\" record(s) at the end of the rinex header\n";
       } elsif ( ( $index->[$length-1] - $index->[0] +1 ) == $length ) {
          splice @{$header},$index->[0],$length,@$new;
          #print $fherr "Replaced $length \"$recid\" record(s) by $modify{$recid} updated records\n";
       } else {
          die "Header records to replace must be continuous";
       }
   }
   
   return $header;
   
}

###########################################################################
# RINEX observation type translation functions 
###########################################################################

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

    if ( $kk > 0 ) {
      push @lines, "RINEX OBSERVATION TRANSLATION: UNUSED RINEX3 TYPES";
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

###########################################################################
# RINEX observation type sorting and removal functions
###########################################################################

sub rnxobstype3sort{

  # Sort RINEX3 obervation types and return hash with indices
  # Usuage
  #
  #   my ($obsid3,$colidx)=rnxobstype3sort($obsid3, {}, $select);
  #   my ($obsid3,$colidx)=rnxobstype3sort($obsid3, $colidx, $select);
  #
  # with $obsid3 (\%obsid3) the hash reference with RINEX3 observation ids
  # and $colidx the reference to a hash with corresponding column indices.
  # The sort order is specified by $select, possible values are
  #
  #    fr[eq]  -  C1C L1C S1C C2W L2W ...             (keep .1C, .2W, etc. together)
  #    ty[pe]  -  C1C C1W ... L1C L2W ... S1C S2W ... (keep types together)
  #    se[pt]  -  preferred order for septentrio receivers, same as "freq", except
  #               for Beidou which uses a different frequency order (15276)
  #    as[is]  -  keep as is (no sorting)
  #
  # Two letters are enough (the other characters are ignored).
  #
  # The observation type order is 'CLDSX', the frequency order is ascending,
  # and attribute order is such that the more important or used observations
  # come first.
  #
  # When $colidx is an empty hash reference {} on input the observation
  # types are assumed to be still in their original order (i.e. alligned
  # with the data in the file). The indices in $colidx are always pointing
  # to the column in the rinex file that holds the data.
  # 
  # The output and input  hashes should be referenced as 
  #  
  #    @obsid3list=@{$obsid3->{$sysid}}
  #    @obsid3idx=@{$colidx->{$sysid}}
  #
  # with $sysid the 1-character systemid and @obsid3list the array with 
  # RINEX3 observation types for that system and @obsids3idx an array with
  # the position in the RINEX observation file, i.e.
  #
  #    $tfa=@{$obsid3->{$sysid}}[$inew]
  #    $iold=@{$colidx->{$sysid}}[$inew]
  #
  # which gives RINEX 3 column number $iold and observation type $tfa at position $inew
  # for the sorted observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
  my ($obsid3,$colidx,$select)=@_;
  
  # define prefered order 

  my $freqs='123456789';
  my $types='CLDSX';
  my $attrs='PWCXLSZQIBADEYMRN';
  
  # create an array with the predefined sort order for a superset of all possible observation types 

  my @order = ();
  if ( $select =~ /^(fr|se).*/ ) {
     foreach my $freq ( split(//,$freqs) ) {
        foreach my $attr ( split(//,$attrs) ) {
           foreach my $type ( split(//,$types) ) {
              push @order, "$type$freq$attr";
           }
        }
     }
  } elsif ( $select =~ /^ty.*/ ) {
     foreach my $type ( split(//,$types) ) {
        foreach my $freq ( split(//,$freqs) ) {
           foreach my $attr ( split(//,$attrs) ) {
              push @order, "$type$freq$attr";
           }
        }
     }
  } elsif ( $select =~ /^as.*/ ) {
     my %colidxout=();
     foreach my $sysid (keys(%{$obsid3})) {
        if ( exists( $colidx->{$sysid} ) ) {
           $colidxout{$sysid} = $colidx->{$sysid};
        } else {
           my @tmp=@{$obsid3->{$sysid}};
           $colidxout{$sysid} = [ 0 .. $#tmp ] ;
        }
     }
     return $obsid3,\%colidxout;
  } else {
     die "Error rnxobstype3sort: unknown sort option $select\n";
  }

  my %order_beidou;
  if ( $select =~ /^(se).*/ ) {
     my $freqs_beidou='152763489';
     my @order = ();
     foreach my $freq_beidou ( split(//,$freqs_beidou) ) {
        foreach my $attr ( split(//,$attrs) ) {
           foreach my $type ( split(//,$types) ) {
              push @order, "$type$freq_beidou$attr";
           }
        }
     }
     %order_beidou = map { $order[$_] => $_ } 0..$#order;
  }

  # convert the array with predefined sort order into a hash with as key the 
  # observation type and as value the position in the predefined sort order, 
  # the hash will be used to sort the actual observation types
  
  my %order = map { $order[$_] => $_ } 0..$#order;

  # sort rinex 3 observation types for each system
  
  my %obsid3out=();
  my %colidxout=();
  foreach my $sysid (keys(%{$obsid3})) {
     my @obsid3list=@{$obsid3->{$sysid}};
     #my @sorted = sort { $order{$a} <=> $order{$b} } @obsid3list;
     my @indices = sort { $order{$obsid3list[$a]} <=> $order{$obsid3list[$b]} } 0 .. $#obsid3list;
     if ( $sysid =~ /^C$/ && $select =~ /^(se).*/ ) {
        @indices = sort { $order_beidou{$obsid3list[$a]} <=> $order_beidou{$obsid3list[$b]} } 0 .. $#obsid3list;
     }
     my @sorted = @obsid3list[@indices]; 
     $obsid3out{$sysid} = [ @sorted ] ;
     if ( exists( $colidx->{$sysid} ) ) {
        $colidxout{$sysid} = [ @{$colidx->{$sysid}}[ @indices ] ];
     } else {
        $colidxout{$sysid} = [ @indices ] ;
     }
  }

  return \%obsid3out,\%colidxout;

}

sub rnxobstype2sort{

  # Sort RINEX2 obervation types and return array with indices
  # Usuage
  #
  #   my ($obsid2,$indices)=rnxobstype2sort($obsid2, [], $select);
  #   my ($obsid2,$indices)=rnxobstype2sort($obsid2, $indices, $select);
  #
  # with $obsid2 (\@obsid2) an array reference with RINEX2 observation ids
  # and $indices an array reference with corresponding column indices.
  # The sort order is specified by $select, possible values are
  #
  #    fr[eq] -  C1 L1 L2 P2 C2 S1 S2 C5 L5 S5 C7 L7 S7 ...
  #    ty[pe] -  C1 L1 L2 P2 C2 C5 C7 ... L5 L7 ... S1 S2 S5 S7 ...
  #    se[pt] -  C1 L1 L2 P2 C2 C5 L5 C7 L7 ... S1 S2 S5 S7 ...
  #    as[is] -  keep as is (no sorting)
  #
  # Two letters are enough (the other characters are ignored).
  #
  # All sorting options are the same for the first five observation types
  # "C1 L1 L2 P2 C2", which is a sort of convention for RINEX2 because
  # of the particularities involved with the P codes. Otherwise, the 
  # observation type order is 'PCLDS'.  The option "se[pt]" is a mix of
  # "freq" and "type"; basically it is the same as "freq", but puts all 
  # signal strength types at the end like in "type".
  #
  # When $indices is an empty array reference [] on input the observation
  # types are assumed to be still in their original order (i.e. alligned
  # with the data in the file). The indices in $indices are always pointing
  # to the column in the rinex file that holds the data.
  # 
  # The output and input arrays should be referenced as 
  #  
  #    $tf=@{$obsid2}[$inew]
  #    $iold=@{$indices}}[$inew]
  #
  # which gives RINEX data column number $iold and observation type $tf at position $inew
  # for the sorted observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.


  my ($obsid2,$colidx,$select)=@_;
  
  # define prefered order 

  my $freqs='123456789';
  my $types='PCLDS';
  
  # create an array with the predefined sort order for a superset of all possible observation types 

  my @order = ( 'C1', 'L1', 'L2', 'P2', 'C2' );
  if ( $select =~ /^fr.*/ ) {
     foreach my $freq ( split(//,$freqs) ) {
        foreach my $type ( split(//,$types) ) {
           push @order, "$type$freq" if ( "$type$freq "!~ /[CLP][12]/ );
        }
     }
  } elsif ( $select =~ /^ty.*/ ) {
     foreach my $type ( split(//,$types) ) {
        foreach my $freq ( split(//,$freqs) ) {
           push @order, "$type$freq" if ( "$type$freq" !~ /[CLP][12]/ );
        }
     }
  } elsif ( $select =~ /^se.*/ ) {
     foreach my $freq ( split(//,$freqs) ) {
        foreach my $type ( split(//,'CLD') ) {
           push @order, "$type$freq" if ( "$type$freq "!~ /[CLP][12]/ );
        }
     }
     foreach my $freq ( split(//,$freqs) ) {
        push @order, "S$freq";
     }
  } elsif ( $select =~ /^as.*/ ) {
     my @colidxout=();
     if ( scalar(@$colidx) == scalar(@$obsid2) ) { 
        @colidxout = @$colidx;
     } else {
        my @tmp = @$obsid2;
        @colidxout = 0 .. $#tmp  ;
     }
     return $obsid2,\@colidxout;
  } else {
     $select=undef;
     die "unknown option\n";
  }

  # convert the array with predefined sort order into a hash with as key the 
  # observation type and as value the position in the predefined sort order, 
  # the hash will be used to sort the actual observation types
  
  my %order = map { $order[$_] => $_ } 0..$#order;

  # sort rinex 2 observation types
  
  #my @sorted = sort { $order{$a} <=> $order{$b} } @$obsid2;
  my @obsid2list = @$obsid2;
  my @indices = sort { $order{$obsid2list[$a]} <=> $order{$obsid2list[$b]} } 0 .. $#obsid2list;
  my @obsid2out = @obsid2list[@indices]; 
  my @colidxout=();
  if ( scalar(@$colidx) == scalar(@$obsid2) ) { 
     @colidxout = @$colidx[ @indices ];
  } else {
     @colidxout = @indices ; ;
  }

  return \@obsid2out,\@colidxout;

}

sub rnxobstype3rm{

  # Remove RINEX3 obervation types
  # Usuage
  #
  #   my ($obsid3,$colidx)=rnxobstype3rm($obsid3, $colidx, $rmspec);
  #
  # with $obsid3 (\%obsid3) the hash reference with RINEX3 observation ids
  # and $colidx the reference to a hash with corresponding column indices.
  # 
  # The string $rmspec specifies the observation types to remove. This is
  # a comma separated list with a regular expession or key value pair 
  # separated by a colon with as key the system and an regex as value:
  #
  #    regex
  #    sys:regex
  #    sys:regex,regex,...
  #    sys:regex,sys:regex,...
  #
  # without system identifier sys: (G:, R:, E:, S:, C:, J: or I:) the regex
  # is applied to all systems (giving no sys: is equivalent to X:). For example
  #
  #     "G:2L,E:7,D.."
  #
  # removes all GPS "2L' observations (C2L, L2L, D2L, S2L), all Galileo
  # obsevations on frequency 7, and all Doppler observations.
  #  
  # The output and input  hashes should be referenced as 
  #  
  #    @obsid3list=@{$obsid3->{$sysid}}
  #    @obsid3idx=@{$colidx->{$sysid}}
  #
  # with $sysid the 1-character systemid and @obsid3list the array with 
  # RINEX3 observation types for that system and @obsids3idx an array with
  # the position in the RINEX observation file, i.e.
  #
  #    $tfa=@{$obsid3->{$sysid}}[$inew]
  #    $iold=@{$colidx->{$sysid}}[$inew]
  #
  # which gives RINEX 3 column number $iold and observation type $tfa at position $inew
  # for the sorted observation types.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
   my ($obsid3, $colidx, $rmspec) = @_;

   my $obsid3out = { %$obsid3 };
   my $colidx3out = { %$colidx };
   my $rmtypes = {};

   # parse the remove specification string
   
   my %removes;
   foreach my $tmp ( split(/,/, $rmspec) ) {
      if ( $tmp =~ /[:]/ ) {
        my ($key,$value) = split(/[,:]/, $tmp);
        $removes{$key} = $value;
      } else {
        $removes{X} = $tmp;
      }
   }
   
   # remove the selected observation types
   
   foreach my $sys ( keys %$obsid3 ) {
      if ( exists($removes{$sys}) ) {
           #print "Removing observation types: $sys => "; foreach my $tmp ( grep {/$removes{$sys}/} @{$obsid3->{$sys}} ) { print $tmp ." "; }; print "\n";
           $rmtypes->{$sys} = [ grep {/$removes{$sys}/} @{$obsid3->{$sys}} ];
           my @indices = grep { $obsid3->{$sys}->[$_] !~ /$removes{$sys}/ } 0..$#{$obsid3->{$sys}}; 
           $obsid3out->{$sys} = [ @{$obsid3->{$sys}}[ @indices ] ]; 
           $colidx3out->{$sys} = [ @{$colidx->{$sys}}[ @indices ] ]; 
      }
      if ( exists($removes{'X'}) ) {
           #print "Removing observation types: X => "; foreach my $tmp ( grep {/$removes{'X'}/} @{$obsid3out->{$sys}} ) { print $tmp ." "; }; print "\n";
           push @{$rmtypes->{$sys}} , grep {/$removes{'X'}/} @{$obsid3out->{$sys}};
           my @indices = grep { $obsid3out->{$sys}->[$_] !~ /$removes{'X'}/ } 0..$#{$obsid3out->{$sys}}; 
           $obsid3out->{$sys} = [ @{$obsid3out->{$sys}}[ @indices ] ]; 
           $colidx3out->{$sys} = [ @{$colidx3out->{$sys}}[ @indices ] ]; 
      }
   }

   return $obsid3out, $colidx3out, $rmtypes;
}

sub rnxobstype2rm{

  # Remove RINEX2 obervation types
  # Usuage
  #
  #   my ($obsid2,$colidx)=rnxobstype2rm($obsid2, $colidx, $rmspec);
  #
  # with $obsid2 (\@obsid2) the array reference with RINEX2 observation ids
  # and $colidx the reference to a hash with corresponding column indices.
  # for each system.
  # 
  # The string $rmspec specifies the observation types to remove. This is
  # a comma separated list with a regular expession or key value pair 
  # separated by a colon with as key the system and an regex as value:
  #
  #    regex
  #    sys:regex
  #    sys:regex,regex,...
  #    sys:regex,sys:regex,...
  #
  # without system identifier sys: (G:, R:, E:, S:, C:, J: or I:) the regex
  # is applied to all systems (giving no sys: is equivalent to X:). For example
  #
  #     "G:2L,E:7,D.."
  #
  # removes all GPS "2L' observations (C2L, L2L, D2L, S2L), all Galileo
  # obsevations on frequency 7, and all Doppler observations.
  #  
  # The output and input colidx hashes should be referenced as 
  #  
  #    @obsid2idx=@{$colidx->{$sysid}}
  #
  # with $sysid the 1-character systemid and @obsids2idx an array with the position in the 
  # RINEX observation file or -99 to indicate a missing observation (blank) in
  # each system.
  #
  # (c) Hans van der Marel, Delft University of Technology.
  
   my ($obsid2, $colidx, $rmspec) = @_;

   my $obsid2out = [ @$obsid2 ];
   my $colidx2out = { %$colidx };
   my $rmtypes = {};

   # parse the remove specification string
   
   my %removes;
   foreach my $tmp ( split(/,/, $rmspec) ) {
      if ( $tmp =~ /[:]/ ) {
        my ($key,$value) = split(/[,:]/, $tmp);
        $removes{$key} = $value;
      } else {
        $removes{X} = $tmp;
      }
   }

   # remove the selected rinex 2 observation types by setting the pointer to -99
   
   foreach my $sys ( keys %$colidx) {
      if ( exists($removes{$sys}) ) {
           #print "Removing observation types: $sys => "; foreach my $tmp ( grep {/$removes{$sys}/} @$obsid2 ) { print $tmp ." "; }; print "\n";
           $rmtypes->{$sys} = [ grep {/$removes{$sys}/} @$obsid2 ];
           my @indices = grep { $obsid2->[$_] =~ /$removes{$sys}/ } 0..$#{$obsid2}; 
           foreach my $i ( @indices ) { $colidx2out->{$sys}[$i] = -99}; 
      }
   }

   # remove the selected rinex 2 observation types whole (all systems)

   if ( exists($removes{'X'}) ) {

     #print "\n\nRemoving observation types: "; foreach my $tmp ( grep {/$removes{'X'}/} @$obsid2 ) { print $tmp ." "; }; print "\n\n";
     my @indices = grep { $obsid2->[$_] !~ /$removes{'X'}/ } 0..$#{$obsid2}; 
     #print "[ "; foreach my $tmp ( @indices) { print $tmp ." "; }; print "]\n";
     $obsid2out = [ @$obsid2[ @indices ] ]; 
     foreach my $sys ( keys %$colidx2out) {
        push @{$rmtypes->{$sys}} , grep {/$removes{'X'}/} @{$obsid2};
        $colidx2out->{$sys} = [ @{$colidx2out->{$sys}}[ @indices ] ]; 
     }     
   }

   return $obsid2out, $colidx2out, $rmtypes;
}

###########################################################################
# Indexing and data reordering functions
###########################################################################

sub iniobsidx2 {

  # Initialize the observation index.using RINEX2 observation types
  # Usuage
  #
  #    $colidx = iniobsidx2($obsid2,$satsys);
  #
  # returns the reference to a hash of arrays $colidx with as key the
  # satellite system and as value an array with the column numbers 
  # corresponding to the observation type in the array $obsid2.
  #
  # (c) Hans van der Marel, Delft University of Technology.

   my ($obsid2,$satsys) = @_;
  
   my $colidx={};
   foreach my $sys ( split(//,$satsys) ) {
      $colidx->{$sys} = [ 0 .. $#{$obsid2} ];
      #print "$sys => [ "; foreach my $tmp ( @{$colidx->{$sys}} ) { print $tmp ." "; }; print "]\n";
   }

   return $colidx;
}

sub iniobsidx3 {

  # Initialize the observation index.using RINEX3 observation types
  # Usuage
  #
  #    $colidx = iniobsidx3($obsid3);
  #
  # returns the reference to a hash of arrays $colidx with the column numbers 
  # in the RINEX dataset for the corresponding observation type in $obsid3.
  #
  # (c) Hans van der Marel, Delft University of Technology.

   my ($obsid3) = @_;
  
   my $colidx={};
   foreach my $sys ( keys %$obsid3 ) {
      $colidx->{$sys} = [ 0 .. $#{$obsid3->{$sys}} ];
      #print "$sys => [ "; foreach my $tmp ( @{$colidx->{$sys}} ) { print $tmp ." "; }; print "]\n";
   }

   return $colidx;
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
  #for my $sysid ( keys(%{$colidx}) ) {
  for my $sysid ( sysids($colidx) ) {
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

###########################################################################
# RINEX observation type definition functions
###########################################################################

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

   #for my $sysid ( keys(%{$typedef}) ) {
   for my $sysid ( sysids($typedef) ) {
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
    
  #for my $sysid ( keys(%{$signaltypes}) ) {
  for my $sysid ( sysids($signaltypes) ) {
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

###########################################################################
# Glonass meta data functions
###########################################################################

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
