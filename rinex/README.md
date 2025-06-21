# RINEX observation file pre-processing (GNSS-Perl-toolbox)

The subdirectory rinex contains Perl scripts and libraries for pre-processing RINEX observation files.

## RINEX file editing, filtering and conversion - `rnxedit`

RINEX observation file editing, filtering and conversion for RINEX version 2, 3 and 4 observation files.

By typing  

> rnxedit -h

in a terminal (`./rnxedit.pl -h` on some systems) elementary help is provided: 

```
rnxedit                                            (Version: 20250616)
-------
Edit, filter and convert RINEX observation files.
Syntax: 

    rnxedit [-options] RINEX_observation_file(s) 
    rnxedit [-options] < inputfile > outputfile  
    cat inputfile | rnxedit [-options] > outputfile 
    
If no RINEX observation file(s) are given on the command line, the script reads 
from the standard input and writes to standard output. 

General options:

    -?|h|help..........This help
    -o outputdir.......Output directory, if not given, any filenames specified
                       on the commandline will be overwritten (the originals
                       will be saved with an extra extention .orig)
    -r #[.##]..........RINEX output version, default is to output the same 
                       version as the input file

Header editing options:

    -mo markername.....String with marker name
    -mn markernumber...String with marker number
    -mt markertype.....String with marker type (only relevant for rinex-3) 
    -at antennatype....String with antenna type and radome
    -an antennanumber..String with antenna number
    -ad antennadelta...Comma separated values for antenna delta U/E/N [m]
    -ah antennaheight..Value for antenna height [m] (eccentricity unchanged)
    -oa agency.........String with observer agency
    -op operator.......String with observer name
    -or runby..........String with agency or person running this program

Filtering options:

    -b starttime.......Observation start time [yyyy-mm-dd[ T]]hh:mm[:ss]
    -e endtime.........Observation end time [yyyy-mm-dd[ T]]hh:mm[:ss]
    -i interval........Observation interval [sec] 
    -sys satsys........Satellite systems to include [GRECJS]

Rinex version 2/3 conversion options:

    -c cfgfile.........Name of optional configuration file, overrides the standard 
                       rinex 2/3 conversion tables hardwired in the program
    -n.................Do nothing. Only analyze the headers and give feedback
                       on the translated observation types; VERY USEFUL option
                       to check if you agree with the conversion of observation
                       types before proceeding with actual conversion!
    -s.................Enforce strict format rules (without this option the 
                       old version observation type records are kept)
    -x receiverclass...Receiver class (overrides receiver type) for conversion:
                          GPS12    Only include GPS L1 and L2 observations
                          GPS125   Only include GPS L1, L2 and L5 observations
                          GRES125  Only include L1/L2/L5 for GPS/GLO/GAL/SBAS.

Examples:

    cat MX5C1340.25O | rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 > zand1340.25o

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxedit -mo ZANDMOTOR -mn ZAND 
       -ah 1.023 -b 7:30 -e 8:20 -i 30 -sys GRE > ZAND00NLD_R_20251340730_50M_30S_MO.rnx 

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxedit -mo ZANDMOTOR -mn ZAND 
       -ah 1.023 -r 2 -x GRES125 -sys GRS > zand1340.25o

    cat MX5C1340.25O | rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 -r 3 -x GPS12 
        -b 7:30 -e 8:20 > ZAND00NLD_R_20251340730_50M_10S_MO.rnx

    rnxedit -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans zand1340.25o

The first and last example are simple RINEX header edits; in the first example
a new file is created and in the last example the existing file is overwritten
(the original is saved with extension .orig). In the second example a RINEX 
version 3 file is edited and filtered. The third and fourth example includes
conversion to RINEX version 2.11 and version 3.00 files respectively, using
different translation profiles (GRES125 and GPS12).

(c) 2011-2025 by Hans van der Marel (H.vanderMarel@tudelft.nl)
Delft University of Technology.
```


## RINEX observation statistics - `rnxstats`

RINEX observation statistics with number of epochs, satellites and observations.

## Perl function libraries

The scripts require one or more of the following Perl function libraries:

- **librnxio.pl** with functions for reading and writing RINEX version 2, 3 and 4 observation files (required for `rnxedit` and `rnxstats`)
- **librnxsys.pl** with functions for RINEX observation handling and converting between RINEX version 2 and 3 (required for `rnxedit`).

These libraries can also be useful in the own right. Documentation on the functions and the data structures that are used is given in the header section of the libraries. 
