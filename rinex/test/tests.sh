#!/bin/bash
# =============
# rnxedit tests
# =============
#
# Test datasets (SEPT MOSAIC-X5, f/w 4.14.10.1, sn 3685241; TRM57971.00     NONE, 1440921216):
#
#                                              bytes   vers #sat  satsys  
#    MX5C00NLD_R_20251340729_59M_10S_MO.rnx  3151099   3.04   62  CEGRS
#    MX5C1340.25O                            2030316   2.11   44  GRES
#
# both datasets created by sbf2rin-15.6.1
#
#   2025     5    14     7    29   20.0000000     GPS         TIME OF FIRST OBS
#   2025     5    14     8    28   40.0000000     GPS         TIME OF LAST OBS
#     10.000                                                  INTERVAL
#
# G   12 C1C L1C S1C C2W L2W S2W C2L L2L S2L C5Q L5Q S5Q      SYS / # / OBS TYPES
# E   12 C1C L1C S1C C5Q L5Q S5Q C7Q L7Q S7Q C8Q L8Q S8Q      SYS / # / OBS TYPES
# S    6 C1C L1C S1C C5I L5I S5I                              SYS / # / OBS TYPES
# R    9 C1C L1C S1C C2C L2C S2C C3Q L3Q S3Q                  SYS / # / OBS TYPES
# C   15 C1P L1P S1P C5P L5P S5P C2I L2I S2I C7I L7I S7I C6I  SYS / # / OBS TYPES
#        L6I S6I                                              SYS / # / OBS TYPES
#
#     16    C1    L1    L2    P2    C2    C5    L5    C7    L7# / TYPES OF OBSERV
#           C8    L8    S1    S2    S5    S7    S8            # / TYPES OF OBSERV
#
# rinex 3 -> 2 (replication test)
# -------------------------------
#
# Options
#    -s GRES      to sort observation to the same order
#                 as in the rinex 2 original
#    -sort sept   sort observation types typical to Septentrio receivers
#
# Differences in result compared to original rinex 2 file MX5C1340.25O :
#    - extra COMMENTS, no # OF SATELLITES and WAVELENGTH FACT L1/2, in the header
#    - leading zeros in month, day, hour, minute and seconds of epoch time
#
# in earlier version it was necessary to add -rm 3 to remove Glonass L3 and -s GRES to 
# remove BEIDOU, this is now taken care of as result of the GRES125 profile.
# cat data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | ./rnxedit -r 2.11 -x GRES125 -sort sept -rm 3 -s GRES > mx5c1340.25o_replicate
echo "rinex 3 -> 2 (replication test)"
echo "-------------------------------"
echo "$ cat data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | ./rnxedit -r 2.11 -x GRES125 -sort sept -s GRES > mx5c1340.25o_replicate"
cat data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | ./rnxedit -r 2.11 -x GRES125 -sort sept -s GRES > mx5c1340.25o_replicate
diff mx5c1340.25o_replicate expect/mx5c1340.25o_replicate

echo " "
echo "$ diff -w mx5c1340.25o_replicate data/MX5C1340.25O"
diff -w mx5c1340.25o_replicate data/MX5C1340.25O | sed -e "s/^[0-9c0-9].*/============/" > mx5c1340.25o_replicate_diff
diff -w mx5c1340.25o_replicate_diff expect/mx5c1340.25o_replicate_diff

# rinex 2 -> 3 (replication tests)
# --------------------------------
#
# Options
#    -mt GEODETIC provide info for mandatory marker type
#    -rm R:C2P    to remove GLONASS C2P observations (otherwise converted from P2 in rinex 2,
#                 but for GLONASS the P2 is blank). 
#    -s CEGRS     to sort observation to the same order as in the rinex 3 original
#    -sort sept   sort observations type typical to Septentrio receivers
#
# Differences with original rinex 3 file MX5C00NLD_R_20251340729_59M_10S_MO.rnx :
#    - extra COMMENTS, no # OF SATELLITES, in the header
#    - leading zeros in month, day, hour, minute and seconds of epoch time
#    - no L2L and S2L in GPS data (not part of rinex 2, only C2L converted from C2) -
#      only 10 out of 12 types. Could make sense to use -rm R:C2P,G:C2L to remove also
#      this observation type.
#    - no GLONASS 3Q observations (not part of rinex 2) - only 6 out of 9 types
#    - no BEIDOU data (not part of rinex 2)
#    - GALILEO and SBAS data are identical
#
echo " "
echo "rinex 3 -> 2 (replication test)"
echo "-------------------------------"
echo "$ data/MX5C1340.25O | ./rnxedit -mt GEODETIC -r 3.04 -x GRES125 -sort sept -rm R:C2P -s CEGRS > MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate"
cat data/MX5C1340.25O | ./rnxedit -mt GEODETIC -r 3.04 -x GRES125 -sort sept -rm R:C2P -s CEGRS > MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate
diff MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate expect/MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate

# To assist in the comparison the above test is repeated with (-rm R:C2P,G:C2L) and compared to
# a filtered outcome on the rinex 3 without BEIDOU, GLONASS 3Q, and GPS 2L. This reduces the differences
# to only the first two points of the previous test
#
echo " "
echo "$ cat data/MX5C1340.25O | ./rnxedit -mt GEODETIC -r 3.04 -x GRES125 -sort sept -rm R:C2P,G:2L -s CEGRS > MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_2"
cat data/MX5C1340.25O | ./rnxedit -mt GEODETIC -r 3.04 -x GRES125 -sort sept -rm R:C2P,G:2L -s CEGRS > MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_2
diff MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_2 expect/MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_2
echo " "
echo "$ cat data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | ./rnxedit -rm G:2L,R:3 -s EGRS > MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_3"
cat data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | ./rnxedit -rm G:2L,R:3 -s EGRS > MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_3
diff MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_3 expect/MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_3

echo " "
echo "$ diff -w MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_2 MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_3"
diff -w MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_2 MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_3 | sed -e "s/^[0-9c0-9].*/============/" > MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_diff
diff -w MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_diff expect/MX5C00NLD_R_20251340729_59M_10S_MO.rnx_replicate_diff

# rinex editing and filtering
# ---------------------------
#
# Fairly complex example, setting the marker name, number and antenna height, decimating to 30 sec, selecting begin
# and end times, and selecting only GPS L1 and legacy L2 signals.
#  
echo " "
echo "rinex editing and filtering"
echo "---------------------------"
echo "$ cat data/MX5C1340.25O | ./rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 -b 7:30 -e 8:20 -i 30 -s G -rm ([578]|C2) > zand1340.25o"
cat data/MX5C1340.25O | ./rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 -b 7:30 -e 8:20 -i 30 -s G -rm "([578]|C2)" > zand1340.25o
diff zand1340.25o expect/zand1340.25o

echo " "
echo "$ cat data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | ./rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 -b 7:30 -e 8:20 -i 30 -s G -rm ([3578]|2L) > ZAND00NLD_R_20251340730_50M_30S_GO.rnx"
cat data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | ./rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 -b 7:30 -e 8:20 -i 30 -s G -rm "([3578]|2L)" > ZAND00NLD_R_20251340730_50M_30S_GO.rnx
diff ZAND00NLD_R_20251340730_50M_30S_GO.rnx expect/ZAND00NLD_R_20251340730_50M_30S_GO.rnx

echo " "
echo "$ cat data/MX5C1340.25O | ./rnxedit -mt GEODETIC -mo ZANDMOTOR -mn ZAND -ah 1.023 -b 7:30 -e 8:20 -i 30 -r 3.04 -s G -rm ([3578]|2L) -sort sept > ZAND00NLD_R_20251340730_50M_30S_GO.rnx_from2"
cat data/MX5C1340.25O | ./rnxedit -mt GEODETIC -mo ZANDMOTOR -mn ZAND -ah 1.023 -b 7:30 -e 8:20 -i 30 -r 3.04 -s G -rm "([3578]|2L)" -sort sept > ZAND00NLD_R_20251340730_50M_30S_GO.rnx_from2
diff -w ZAND00NLD_R_20251340730_50M_30S_GO.rnx_from2 ZAND00NLD_R_20251340730_50M_30S_GO.rnx | sed -e "s/^[0-9c0-9].*/============/" > ZAND00NLD_R_20251340730_50M_30S_GO.rnx_from2_diff
diff -w ZAND00NLD_R_20251340730_50M_30S_GO.rnx_from2_diff expect/ZAND00NLD_R_20251340730_50M_30S_GO.rnx_from2_diff

# rinex editing and filtering (one or more files)
# -----------------------------------------------
#
# Wildcards are permitted to edit a batch of files 

echo " "
echo "rinex editing and filtering (one or more files)"
echo "-----------------------------------------------"
echo "$ ./rnxedit -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans zand1340.25o"
./rnxedit -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans zand1340.25o
diff zand1340.25o zand1340.25o.orig

echo " "
echo "$ ./rnxedit -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans -o ./tmp *.{25o,25o_replicate}"
mkdir -p ./tmp
./rnxedit -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans -o ./tmp *.{25o,25o_replicate}

