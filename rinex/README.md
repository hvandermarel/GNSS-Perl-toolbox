# RINEX observation file pre-processing (GNSS-Perl-toolbox)

The subdirectory rinex contains Perl scripts and libraries for pre-processing RINEX observation files.

## RINEX file editing, filtering and conversion - `rnxedit`

RINEX observation file editing, filtering and conversion for RINEX version 2, 3 and 4 observation files.

### Usage instructions

By typing `rnxedit -h` in a terminal (or `./rnxedit.pl -h` on some systems) elementary help is provided: 

```
rnxedit                                            (Version: 20250625)
-------
Edit, filter and convert RINEX observation files.
Syntax:

    rnxedit -?
    rnxedit [-options] RINEX_observation_file(s)
    rnxedit [-options] < inputfile > outputfile
    cat inputfile | rnxedit [-options] > outputfile

If no RINEX observation file(s) are given on the command line, the script reads
from the standard input and writes to standard output.

Header editing options:

    -mo markername.....String with marker name
    -mn markernumber...String with marker number
    -mt markertype.....String with marker type (only relevant for rinex-3)
    -at antennatype....String with antenna type and radome
    -an antennanumber..String with antenna number
    -ad antennadelta...Comma separated values for antenna delta U,E,N [m]
    -ah antennaheight..Value for antenna height [m] (eccentricity unchanged)
    -ap positionxyz... Comma separated values for approximate position X,Y,Z [m]
    -rt receivertype...String with receiver type
    -rn receivernumber.String with receiver number
    -rv receiverfw.....String with receiver firmware version
    -oa agency.........String with observer agency
    -op operator.......String with observer name
    -or runby..........String with agency or person running this program

Filtering options:

    -b starttime.......Observation start time [yyyy-mm-dd[ T]]hh:mm[:ss]
    -e endtime.........Observation end time [yyyy-mm-dd[ T]]hh:mm[:ss]
    -i interval........Observation interval [sec]
    -s satsys..........Satellite systems to include [GRECJS]

Rinex version 2/3+ conversion options:

    -r #[.##]..........RINEX output version, default is to output the same
                       version as the input file
    -x receiverclass...Receiver class (overrides receiver type) for conversion:
                          GPS12    Only include GPS L1 and L2 observations
                          GPS125   Only include GPS L1, L2 and L5 observations
                          GRES125  Only include L1/L2/L5 for GPS/GLO/GAL/SBAS.
    -n.................Do nothing. Only analyze the headers and give feedback
                       on the translated observation types; useful to check if you
                       agree with the conversion of observation types before
                       proceeding with actual conversion!

General options:

    -?|h|help..........This help
    -o outputdir.......Output directory, if not given, any filenames specified
                       on the commandline will be overwritten (the originals
                       will be saved with an extra extention .orig)
    -v                 Verbose (increase verbosity level)

Examples:

    cat MX5C1340.25O | rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 > zand1340.25o

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxedit -mo ZANDMOTOR -mn ZAND
       -ah 1.023 -b 7:30 -e 8:20 -i 30 -s GRE > ZAND00NLD_R_20251340730_50M_30S_MO.rnx

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxedit -mo ZANDMOTOR -mn ZAND
       -ah 1.023 -r 2 -x GRES125 -s GRS > zand1340.25o

    cat MX5C1340.25O | rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 -r 3 -x GPS12
        -b 7:30 -e 8:20 > ZAND00NLD_R_20251340730_50M_10S_MO.rnx

    rnxedit -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans zand1340.25o

The first and last example are simple RINEX header edits; in the first example
a new file is created and in the last example the existing file is overwritten
(the original is saved with extension .orig). In the second example a RINEX
version 3 file is edited and filtered. The third and fourth example includes
conversion to RINEX version 2.11 and version 3.00 files respectively, using
different translation profiles (GRES125 and GPS12).

(c) 2011-2025 by Hans van der Marel, Delft University of Technology.
```

### Perl dependencies

The `librnxio.pl` and `librnxsys.pl` Perl libraries must be installed in the same directory as `rnxedit.pl`. 
The file `glonass.cfg` is required for conversion from RINEX version 2.11 to version 3.02 and higher. This file must be present in the same directory as the script. 
If you don't like to have these files in your search path, put the files in their own directory, and create a symbolic link to `rnxedit.pl`.
Other dependecies of `rnxedit` are the Perl modules `Getopt::Long`, `File::Basename` and `Time::Local`. These module are very common and included by most Perl distributions.

### RINEX compability

One defining characteristic of `rnxedit` and the underlying `librnxio` are that these only manipulate blocks of text. The basic text blocks are

- RINEX header line (80 characters block)
- RINEX observation epoch (25 or 27 character block), epoch flag (1 character) and optional receiver clock offset (15 character block) 
- RINEX PRN number (3 characters block)
- RINEX observation with SSI and LLI indicators (16 character block)

Except for the header lines, all other blocks are only reshuffled in position or deleted, but the content itself is not modified.
The only editing occurs in the headers, for spaces in the PRN number and century in the observation epoch. The observations, SSI and LLI indicators are not edited (though a whole block may be deleted, or spaces inserted).

Marker name, number and type, antenna number, type, delta and height, receiver type, receiver number, receiver version, agency and operator in the RINEX header lines may be edited depending on the input options. Other items in the header, such as time of first and last observation, interval and system records may be changed or deleted depending on the filtering options.
When filtering has been selected, some new comment lines are added to the header detailing the filtering operation.  Unless conversion is selected, not other modification to the header is done.

The most invasive operation is conversion between RINEX version 2 and 3+: observation types are changed and 2-character codes are changed to 3-character codes, or vice versa.  Header record may be added or converted to COMMENTS, and COMMENT lines detailing the operation are added to the end of the header section, including a translation table between the 2- and 3-character codes.

A particular dilemma with upconverting from RINEX version 2 to 3+ is how to provide information missing in version 2 for version 3+. 
Several scenarios for this are hardwired into the code, using receiver classes and more general profiles, which can be selected from the command line. 

Some header records are mandatory, other are optional, and this has changed between versions:

```
                         valid    mandatory   
RINEX VERSION / TYPE      2.10-       2.10-
PGM / RUN BY / DATE       2.10-       2.10-
COMMENT                   2.10-
MARKER NAME               2.10-       2.10-
MARKER NUMBER             2.10-

OBSERVER / AGENCY         2.10-       2.10-
REC # / TYPE / VERS       2.10-       2.10-
ANT # / TYPE              2.10-       2.10-
APPROX POSITION XYZ       2.10-       2.10-
ANTENNA: DELTA H/E/N      2.10-       2.10-

# / TYPES OF OBSERV       2.10-2.11   2.10-2.11
WAVELENGTH FACT L1/2      2.10-2.11   2.10-2.11

MARKER TYPE               3.00-       3.00-
SYS / # / OBS TYPES       3.00-       3.00-
GLONASS SLOT / FRQ        3.01-       3.02-
SYS / PHASE SHIFT         3.01-       3.01-3.05  strongly depricated in version 4
GLONASS COD/PHS/BIS       3.02-       3.02-3.05  strongly depricated in version 4

TIME OF FIRST OBS         2.10-       2.10-
TIME OF LAST OBS          2.10-
INTERVAL                  2.10-

RCV CLOCK OFFS APPL       2.10-
LEAP SECONDS              2.10-
# OF SATELLITES           2.10-
PRN / # OF OBS            2.10-

ANTENNA: DELTA X/Y/Z      3.00-
ANTENNA:PHASECENTER       3.00-
ANTENNA: B.SIGHT XYZ      3.00-
ANTENNA: ZERODIR AZI      3.00-
ANTENNA: ZERODIR XYZ      3.00-
CENTER OF MASS: XYZ       3.00-

SIGNAL STRENGTH UNIT      3.00-
SYS / DCBS APPLIED        3.00-
SYS / PCVS APPLIED        3.00-
SYS / SCALE FACTOR        3.00-

DOI                       4.00-
LICENSE OF USE            4.00-
STATION INFORMATION       4.00-
```

When upconverting from RINEX version 2 to 3+, the default rinex output is version `3.04` for version 3 and version `4.02` 
for version 4. 
From version `3.01` onwards additional information is needed, such as Glonass slot numbers and frequencies, 
phase shifts and Glonass code and phase biases. From RINEX version 4 the latter two records
are depricated, leaving only the Glonass slot numbers as missing information.
For version 3.01(3.02) to 3.05, where the phase shift and Glonass bias records are mandatory, we use blank values 
for the phase shifts and Glonass code and phase biases to indicate that these are unknown, which is in
agreement with the standard). Because of the "strong deprication" of these records in version 4 we consider this 
not as a great miss.

The only problem is when the Glonass slot numbers are missing (in input versions below 3.02). To cover
this situation this software reads the file `glonass.cfg`, which contains a full history of slot numbers, 
to obtain the slot number at the date of observation and insert these into the rinex header. This is a 
solution that works well with older rinex version 2 files, but beware, when converting contemporary rinex
version 2 files make sure to update the `glonass.cfg` file.

### Comparison with other tools (`teqc`, `gfzrnx`)

The `rnxedit` tool was inspired by Unavco's `teqc` and GFZ's `gfzrnx`, but doesn't share any of the code. For a comparison of the three tools:

- `teqc` only operates on RINEX version 2 files, can create RINEX version 2 from raw data files, and do quality control
- `rnxedit` and `teqc` can edit RINEX header data using command line options (`gfzrnx` uses crux files for this)
- all three tools can do filtering
- `gfzrnx` and `rnxedit` can convert between RINEX versions, `teqc` cannot
- `rnxedit` and `teqc` are single pass and can be used in pipes, `gfzrnx` reads all data in memory first and tends to be more heavy on resources than the two other tools
- `teqc` and `gfzrnx` are more capable in their own domain and have more options than `rnxedit`
- `teqc` is no anymore supported
- the free version of `gfzrnx` cannot be used for production work
- `rnxedit` source code is available (Perl) and runs on many systems, while `teqc` and `gfzrnx` are distributed as binaries for specific systems
  
In short, `rnxedit` can be used only for relatively simple and common tasks, but combines the "best" from `teqc` and `gfzrnx`.

### Motivation and development history

When in 2011 the first RINEX version 3 files came around tools did not initially exist to convert the - at that time badly supported - RINEX version 3 files to version 2. 
At the same time it was clear that Unavco's `teqc` would never support RINEX version 3.
This motivated me in 2011 to write a set of Perl scripts and functions for reading, writing and converting RINEX files. This became the initial version of `rnxedit`, then known as `rnx2to3.pl` (which could also do the conversion in the other direction), and precursor libraries for `librnxio.pl` (called `rnxio.pl`) and `librnxsys.pl` (called `rnxsub.pl`). 
Soon after `gfzrnx` came around and we started to use `gfzrnx` for production work. The `rnx2to3.pl` was only used for some special projects and as the basis for a tool (`rnxstats`) to produce observation counts and statistics.

For the editing and checking of meta data in the RINEX observations files another Perl script was developed using header templates generated from a station meta-data XML database. This worked very well in a production environment, but for editing a single file it was not as convenient as the good old `teqc` for RINEX version 2, although still easier than using `gfzrnx` (for RINEX version 3).

So in 2025, i decided to add editing and filtering capabilities to `rnx2to3.pl`, rename it to `rnxedit`, and release it as open source under a Apache 2 licence on github. 

Another main motivation to develop `rnxedit` is that `teqc` is not anymore supported, and that `gfzrnx` is now licensed under a more restrictive license not allowing production work with the free version, that `gfzrnx` tends to be rather heavy on system resources (compared to `teqc` and `rnxedit`), and there is no source code available for `gfzrnx` and `teqc`. 

To me, `rnxedit` is intended as replacement for `teqc` and `gfzrnx`, not for everything, but only the most common operations (98% of the work). For all three tools, `teqc`, `gfzrnx` and `rnxedit`, there are jobs for which it is the "right" tool. 

## RINEX observation statistics - `rnxstats`

RINEX observation statistics with number of epochs, satellites and observations.

## Perl function libraries

The scripts require one or more of the following Perl function libraries:

- **librnxio.pl** with functions for reading and writing RINEX version 2, 3 and 4 observation files (required for `rnxedit` and `rnxstats`)
- **librnxsys.pl** with functions for RINEX observation handling and converting between RINEX version 2 and 3 (required for `rnxedit`).

These libraries can also be useful in the own right. Documentation on the functions and the data structures that are used is given in the header section of the libraries. 
