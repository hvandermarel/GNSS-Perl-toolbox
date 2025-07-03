#!/bin/bash
#
# rnxobstype command
rnxobstype="../rnxobstype.pl -v"
opt3to2="-x GRS12"
opt3to2ext="-x GRS125"

# ======================================================================================================================================================
# Signal type definitions for TRIMBLE NETR9
#
# G: 1C 2W 2X 5X
# R: 1C 1P 2P 2C
# E: 1X 5X 7X 8X
# S: 1C
#
# DLF1
# ----
$rnxobstype $opt3to2  <<EOD
5039K70764          TRIMBLE NETR9       5.45                REC # / TYPE / VERS
C    6 C2I C7I L2I L7I S2I S7I                              SYS / # / OBS TYPES
E   12 C1X C5X C7X C8X L1X L5X L7X L8X S1X S5X S7X S8X      SYS / # / OBS TYPES
G   12 C1C C2W C2X C5X L1C L2W L2X L5X S1C S2W S2X S5X      SYS / # / OBS TYPES
J   18 C1C C1X C1Z C2X C5X C6L L1C L1X L1Z L2X L5X L6L S1C  SYS / # / OBS TYPES
       S1X S1Z S2X S5X S6L                                  SYS / # / OBS TYPES
R   15 C1C C1P C2C C2P C3X L1C L1P L2C L2P L3X S1C S1P S2C  SYS / # / OBS TYPES
       S2P S3X                                              SYS / # / OBS TYPES
S    3 C1C L1C S1C                                          SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
5039K70764          TRIMBLE NETR9       5.45                REC # / TYPE / VERS
     7    L1    L2    C1    P2    P1    S1    S2            # / TYPES OF OBSERV
EOD

#
# WSRA
# ----
$rnxobstype  $opt3to2 <<EOD
5302K41643          TRIMBLE NETR9       5.45                REC # / TYPE / VERS
C    6 C2I L2I S2I C7I L7I S7I                              SYS / # / OBS TYPES
E    9 C1X L1X S1X C7X L7X S7X C8X L8X S8X                  SYS / # / OBS TYPES
G    9 C1C L1C S1C C2W L2W S2W C2X L2X S2X                  SYS / # / OBS TYPES
J   12 C1C L1C S1C C1X L1X S1X C1Z L1Z S1Z C2X L2X S2X      SYS / # / OBS TYPES
R   15 C1C L1C S1C C1P L1P S1P C2C L2C S2C C2P L2P S2P C3X  SYS / # / OBS TYPES
       L3X S3X                                              SYS / # / OBS TYPES
S    3 C1C L1C S1C                                          SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
5302K41643          TRIMBLE NETR9       5.45                REC # / TYPE / VERS
     7    L1    L2    C1    P2    P1    S1    S2            # / TYPES OF OBSERV
EOD
#
# AMEL, IJMU, TXE2
# ----------------
# 5509R50048          TRIMBLE NETR9       5.37                REC # / TYPE / VERS
# 5504R50175          TRIMBLE NETR9       5.37                REC # / TYPE / VERS
# 5429R49164          TRIMBLE NETR9       5.37                REC # / TYPE / VERS
#
$rnxobstype  $opt3to2 <<EOD
5429R49164          TRIMBLE NETR9       5.37                REC # / TYPE / VERS
C    9 C2I C6I C7I L2I L6I L7I S2I S6I S7I                  SYS / # / OBS TYPES
E   12 C1X C5X C7X C8X L1X L5X L7X L8X S1X S5X S7X S8X      SYS / # / OBS TYPES
G   12 C1C C2W C2X C5X L1C L2W L2X L5X S1C S2W S2X S5X      SYS / # / OBS TYPES
J   18 C1C C1X C1Z C2X C5X C6X L1C L1X L1Z L2X L5X L6X S1C  SYS / # / OBS TYPES
       S1X S1Z S2X S5X S6X                                  SYS / # / OBS TYPES
R   15 C1C C1P C2C C2P C3X L1C L1P L2C L2P L3X S1C S1P S2C  SYS / # / OBS TYPES
       S2P S3X                                              SYS / # / OBS TYPES
S    3 C1C L1C S1C                                          SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
5429R49164          TRIMBLE NETR9       5.37                REC # / TYPE / VERS
     9    C1    D1    D2    L1    L2    P1    P2    S1    S2# / TYPES OF OBSERV
EOD
#
# ======================================================================================================================================================
# Signal type definitions for LEICA GR50
#
# G: 1C 2W 2S 5Q
# R: 1C 1P 2P 2C
# E: 1C 5Q 7Q 8Q
# S: 1C
#
#
# APEL, CBW1, VLIE, VLIS
# ----------------------
# 1870104             LEICA GR50          4.31/7.403          REC # / TYPE / VERS
# 1870649             LEICA GR50          4.31/7.403          REC # / TYPE / VERS
# 1870106             LEICA GR50          4.31/7.403          REC # / TYPE / VERS
# 1870107             LEICA GR50          4.31/7.403          REC # / TYPE / VERS

$rnxobstype  $opt3to2 <<EOD
1870107             LEICA GR50          4.31/7.403          REC # / TYPE / VERS
C    8 C2I C7I D2I D7I L2I L7I S2I S7I                      SYS / # / OBS TYPES
E   16 C1C C5Q C7Q C8Q D1C D5Q D7Q D8Q L1C L5Q L7Q L8Q S1C  SYS / # / OBS TYPES
       S5Q S7Q S8Q                                          SYS / # / OBS TYPES
G   16 C1C C2S C2W C5Q D1C D2S D2W D5Q L1C L2S L2W L5Q S1C  SYS / # / OBS TYPES
       S2S S2W S5Q                                          SYS / # / OBS TYPES
R   12 C1C C2C C2P D1C D2C D2P L1C L2C L2P S1C S2C S2P      SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
1870107             LEICA GR50          4.31/7.403          REC # / TYPE / VERS
     9    C1    D1    D2    L1    L2    P1    P2    S1    S2# / TYPES OF OBSERV
EOD
#
# SCHIE
# -----
$rnxobstype  $opt3to2 <<EOD
1870111             LEICA GR50          4.35/7.504          REC # / TYPE / VERS
C   12 C2I C6I C7I D2I D6I D7I L2I L6I L7I S2I S6I S7I      SYS / # / OBS TYPES
E   20 C1C C5Q C6C C7Q C8Q D1C D5Q D6C D7Q D8Q L1C L5Q L6C  SYS / # / OBS TYPES
       L7Q L8Q S1C S5Q S6C S7Q S8Q                          SYS / # / OBS TYPES
G   16 C1C C2S C2W C5Q D1C D2S D2W D5Q L1C L2S L2W L5Q S1C  SYS / # / OBS TYPES
       S2S S2W S5Q                                          SYS / # / OBS TYPES
R   12 C1C C2C C2P D1C D2C D2P L1C L2C L2P S1C S2C S2P      SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
1870111             LEICA GR50          4.35/7.504          REC # / TYPE / VERS
     9    C1    D1    D2    L1    L2    P1    P2    S1    S2# / TYPES OF OBSERV
EOD
#
# NTUS
# ----
$rnxobstype  $opt3to2 <<EOD
1832415             LEICA GR50          4.20/7.300          REC # / TYPE / VERS
C    4 C2I C7I L2I L7I                                      SYS / # / OBS TYPES
E    8 C1C C5Q C7Q C8Q L1C L5Q L7Q L8Q                      SYS / # / OBS TYPES
G    8 C1C C2S C2W C5Q L1C L2S L2W L5Q                      SYS / # / OBS TYPES
J    6 C1C C2S C5Q L1C L2S L5Q                              SYS / # / OBS TYPES
R    6 C1C C2C C2P L1C L2C L2P                              SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
1832415             LEICA GR50          4.20/7.300          REC # / TYPE / VERS
RINEX 3 -> 2 TYPE CONVERSION DETAILS:                       COMMENT
     7    C1    C2    C5    L1    L2    L5    P2            # / TYPES OF OBSERV
EOD

#
# ======================================================================================================================================================
# Signal type definitions for SEPT POLARX5 
#
# G: 1C 1W 2W 2L 5Q
# R: 1C 1P 2C 2P
# E: 1C 5Q 7Q 8Q
# S: 1C 5I
#
# EIJS, KOS1, TERS
# ----------------
# 3047859             SEPT POLARX5E       5.4.0               REC # / TYPE / VERS
# 3048419             SEPT POLARX5E       5.3.2               REC # / TYPE / VERS
# 3048026             SEPT POLARX5E       5.3.2               REC # / TYPE / VERS
#
$rnxobstype  $opt3to2ext <<EOD
3048026             SEPT POLARX5E       5.3.2               REC # / TYPE / VERS
C   20 C1P C2I C5P C6I C7I D1P D2I D5P D6I D7I L1P L2I L5P  SYS / # / OBS TYPES
       L6I L7I S1P S2I S5P S6I S7I                          SYS / # / OBS TYPES
E   20 C1C C5Q C6C C7Q C8Q D1C D5Q D6C D7Q D8Q L1C L5Q L6C  SYS / # / OBS TYPES
       L7Q L8Q S1C S5Q S6C S7Q S8Q                          SYS / # / OBS TYPES
G   22 C1C C1L C1W C2L C2W C5Q D1C D1L D2L D2W D5Q L1C L1L  SYS / # / OBS TYPES
       L2L L2W L5Q S1C S1L S1W S2L S2W S5Q                  SYS / # / OBS TYPES
I    4 C5A D5A L5A S5A                                      SYS / # / OBS TYPES
J   20 C1C C1L C1Z C2L C5Q D1C D1L D1Z D2L D5Q L1C L1L L1Z  SYS / # / OBS TYPES
       L2L L5Q S1C S1L S1Z S2L S5Q                          SYS / # / OBS TYPES
R   20 C1C C1P C2C C2P C3Q D1C D1P D2C D2P D3Q L1C L1P L2C  SYS / # / OBS TYPES
       L2P L3Q S1C S1P S2C S2P S3Q                          SYS / # / OBS TYPES
S    8 C1C C5I D1C D5I L1C L5I S1C S5I                      SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
3048026             SEPT POLARX5E       5.3.2               REC # / TYPE / VERS
     9    C1    D1    D2    L1    L2    P1    P2    S1    S2# / TYPES OF OBSERV
EOD
#
$rnxobstype <<EOD
3048026             SEPT POLARX5E       5.3.2               REC # / TYPE / VERS
RINEX 3 -> 2 TYPE CONVERSION DETAILS:                       COMMENT
    11    C1    C2    C5    L1    L2    L5    P1    P2    S1# / TYPES OF OBSERV
          S2    S5                                          # / TYPES OF OBSERV
EOD

# ROVN, ZEGV
# ----------
# 3057780             SEPT POLARX5        5.3.2               REC # / TYPE / VERS
# 3046503             SEPT POLARX5        5.3.2               REC # / TYPE / VERS

$rnxobstype $opt3to2ext <<EOD
3046503             SEPT POLARX5        5.3.2               REC # / TYPE / VERS
C   15 C1P C2I C5P C6I C7I L1P L2I L5P L6I L7I S1P S2I S5P  SYS / # / OBS TYPES
       S6I S7I                                              SYS / # / OBS TYPES
E   15 C1C C5Q C6C C7Q C8Q L1C L5Q L6C L7Q L8Q S1C S5Q S6C  SYS / # / OBS TYPES
       S7Q S8Q                                              SYS / # / OBS TYPES
G   17 C1C C1L C1W C2L C2W C5Q L1C L1L L2L L2W L5Q S1C S1L  SYS / # / OBS TYPES
       S1W S2L S2W S5Q                                      SYS / # / OBS TYPES
J   15 C1C C1L C1Z C2L C5Q L1C L1L L1Z L2L L5Q S1C S1L S1Z  SYS / # / OBS TYPES
       S2L S5Q                                              SYS / # / OBS TYPES
R    9 C1C C2C C3Q L1C L2C L3Q S1C S2C S3Q                  SYS / # / OBS TYPES
S    6 C1C C5I L1C L5I S1C S5I                              SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
3046503             SEPT POLARX5        5.3.2               REC # / TYPE / VERS
RINEX 3 -> 2 TYPE CONVERSION DETAILS:                       COMMENT
    11    C1    C2    C5    L1    L2    L5    P1    P2    S1# / TYPES OF OBSERV
          S2    S5                                          # / TYPES OF OBSERV
EOD
#
# VSLF
# ----

$rnxobstype  $opt3to2ext <<EOD
3001395             SEPT POLARX4TR      2.3.3               REC # / TYPE / VERS
G    9 C1C L1C C1W C2W L2W C2L L2L C5Q L5Q                  SYS / # / OBS TYPES
E    8 C1C L1C C5Q L5Q C7Q L7Q C8Q L8Q                      SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
3001395             SEPT POLARX4TR      2.3.3               REC # / TYPE / VERS
RINEX 3 -> 2 TYPE CONVERSION DETAILS:                       COMMENT
     8    C1    C2    C5    L1    L2    L5    P1    P2      # / TYPES OF OBSERV
EOD

# WSRT
# ----

$rnxobstype  $opt3to2 <<EOD
3024778             SEPT POLARX5        5.3.2               REC # / TYPE / VERS
C   12 C2I C6I C7I D2I D6I D7I L2I L6I L7I S2I S6I S7I      SYS / # / OBS TYPES
E   20 C1C C5Q C6C C7Q C8Q D1C D5Q D6C D7Q D8Q L1C L5Q L6C  SYS / # / OBS TYPES
       L7Q L8Q S1C S5Q S6C S7Q S8Q                          SYS / # / OBS TYPES
G   18 C1C C1W C2L C2W C5Q D1C D2L D2W D5Q L1C L2L L2W L5Q  SYS / # / OBS TYPES
       S1C S1W S2L S2W S5Q                                  SYS / # / OBS TYPES
J    8 C1C C2L D1C D2L L1C L2L S1C S2L                      SYS / # / OBS TYPES
R   20 C1C C1P C2C C2P C3Q D1C D1P D2C D2P D3Q L1C L1P L2C  SYS / # / OBS TYPES
       L2P L3Q S1C S1P S2C S2P S3Q                          SYS / # / OBS TYPES
S    4 C1C D1C L1C S1C                                      SYS / # / OBS TYPES
EOD

$rnxobstype <<EOD
3024778             SEPT POLARX5        5.3.2               REC # / TYPE / VERS
RINEX 3 -> 2 TYPE CONVERSION DETAILS:                       COMMENT
    11    C1    C2    C5    L1    L2    L5    P1    P2    S1# / TYPES OF OBSERV
          S2    S5                                          # / TYPES OF OBSERV
EOD

