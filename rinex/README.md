# RINEX observation file pre-processing (GNSS-Perl-toolbox)

The subdirectory rinex contains Perl scripts and libraries for pre-processing RINEX observation files.

## RINEX file editing, filtering and conversion - `rnxedit`

RINEX observation file editing, filtering and conversion for RINEX version 2, 3 and 4 observation files.

### Usage instructions

By typing `rnxedit -h` in a terminal (or on some systems `./rnxedit.pl -h`) a brief instruction is provided: 

```
rnxedit                                            (Version: 20250702)
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
    -by sort[[,sort]]  Order for the observation types, with
                         fr[eq]  -  keep .signals (1C, .2W, etc.) together
                         ty[pe]  -  keep types (C, L, S) together
                         se[pt]  -  preferred order for Septentrio receivers
                         as[is]  -  keep as is (no sorting)
    -rm spec[[,spec]]  Remove observation types (spec = [sys:]regex )

Rinex version 2/3+ conversion options:

    -r #[.##]..........RINEX output version, default is to output the same
                       version as the input file
    -x receiverclass...Receiver class (overrides receiver type) for conversion:
                          GPS12    Only include GPS L1 and L2 observations
                          GPS125   Only include GPS L1, L2 and L5 observations
                          GRS12    Only include GPS+GLO L1/L2 and SBAS L1
                          GRS125   Only include GPS L1/L2/L5, GLO L1/L2 and SBAS L1/L5
                          GRES12   Only include GPS+GLO L1/L2, GAL L1/E5b and SBAS L1
                          GRES125  Only include L1/L2/L5/E5b for GPS/GLO/GAL/SBAS
                       The above options are useful for converting from rinex 3 to 2,
                       but are too general for the other direction. For converting from
                       rinex 2 to 3 let the software decide (use the build in templates)
                       or specify explicitly, e.g. "G:1C 2W 2L 5Q,E:1C 5Q".
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

For RINEX version 3 the result of the sort options is

    -by freq|sept  ->  C1C L1C S1C C2W L2W ...             (keep .1C, .2W, etc. together)
    -by type       ->  C1C C1W ... L1C L2W ... S1C S2W ... (keep types together)

For RINEX version 2 the result of the sort options is always the same for the
first five observations "C1 L1 L2 P2 C2", but differs thereafter

    -by freq  ->  C1 L1 L2 P2 C2 S1 S2 C5 L5 S5 C7 L7 S7 ...
    -by type  ->  C1 L1 L2 P2 C2 C5 C7 ... L5 L7 ... S1 S2 S5 S7 ...
    -by sept  ->  C1 L1 L2 P2 C2 C5 L5 C7 L7 ... S1 S2 S5 S7 ...

The option "sept" is a mix of "freq" and "type"; basically it is the same as "freq", but
puts all signal strength types at the end like in "type".

The option "-rm spec[[,spec]]" specifies the observation types to remove. This is
a comma separated list with "spec" a Perl regular expession "regex" operating on all
systems or a key value pair "sys:regex" with a Perl regular expression operating on a
designated system sys (G, R, E, C, S, J, I). For example "G:2L,E:7,D.." removes all
GPS "2L' observations (C2L, L2L, D2L, S2L), all Galileo observations on frequency 7,
and all Doppler observations.

Examples:

    cat MX5C1340.25O | rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 > zand1340.25o

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxedit -mo ZANDMOTOR -mn ZAND
       -ah 1.023 -b 7:30 -e 8:20 -i 30 -s GRE > ZAND00NLD_R_20251340730_50M_30S_MO.rnx

    cat MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxedit -mo ZANDMOTOR -mn ZAND
       -ah 1.023 -r 2 -x GRES125 -s GRS > zand1340.25o

    cat MX5C1340.25O | rnxedit -mo ZANDMOTOR -mn ZAND -ah 1.023 -r 3 -x "G:1C 2W 2L"
        -b 7:30 -e 8:20 > ZAND00NLD_R_20251340730_50M_10S_MO.rnx

    rnxedit -mn NAP30D126 -ah 1.0232 -oa TUD -op Hans zand1340.25o

The first and last example are simple RINEX header edits; in the first example
a new file is created and in the last example the existing file is overwritten
(the original is saved with extension .orig). In the second example a RINEX
version 3 file is edited and filtered. The third and fourth example includes
conversion to RINEX version 2.11 and version 3.00 files respectively, using
different translation profiles.

(c) 2011-2025 by Hans van der Marel, Delft University of Technology.
```

### Dependencies

The `librnxio.pm`, `librnxsys.pm` and `libglonass.pm` Perl modules must be installed in the same directory as `rnxedit.pl`. 
If you don't like to have all these files in your search path, put the files in a separate directory and create a small shell script \ to execute `rnxedit.pl` (symbolic links fail to resolve the modules).

Other dependecies of `rnxedit` are the Perl modules `Getopt::Long`, `File::Basename` and `Time::Local`. These module are very common and included by most Perl distributions.

### Testing and checking of observation type translation, sorting and removal - `rnxobstype` and `rnxobssort`

The Perl scripts `rnxobstype` and `rnxobsort` can be used to test, check and play with the translation,
sorting and removal of RINEX version 2 and 3 observation types. These functions do not change the RINEX files.
They can be used to experiment and play with the various options, and for checking if these give the desired
result. Their functionality is similar to, but more extensive than, the analyze function `rnxedit -n` in `rnxedit`.

For brief instructions on **rnxobstype** type `rnxobstype -h`:  

```
rnxobstype                                            (Version: 20250702)
----------
Translate RINEX version 2 to version 3 observation types and vice versa.
Syntax:

    rnxobstype -?
    rnxobstype [-options] RINEX2_OBSTYPE [[ RINEX2_OBSTYPE ]]
    rnxobstype [-options] < file_with_obstypes
    cat file_with_obstypes | rnxobstype [-options]

If no RINEX version 2 observation types are given on the command line, the script reads
from the standard input and translates any RINEX version 2 or 3 observation TYPES records
it finds. Options are:

    -?|h|help..........This help
    -r #[.##]..........RINEX output version, default is to output the same
                       version as the input file
    -x receiverclass...Receiver class (overrides receiver type) for conversion:
                          GPS12    Only include GPS L1 and L2 observations
                          GPS125   Only include GPS L1, L2 and L5 observations
                          GRS12    Only include GPS+GLO L1/L2 and SBAS L1
                          GRS125   Only include GPS L1/L2/L5, GLO L1/L2 and SBAS L1/L5
                          GRES12   Only include GPS+GLO L1/L2, GAL L1/E5b and SBAS L1
                          GRES125  Only include L1/L2/L5/E5b for GPS/GLO/GAL/SBAS
                       The above options are useful for converting from rinex 3 to 2,
                       but are too general for the other direction. For converting from
                       rinex 2 to 3 let the software decide (use the build in templates)
                       or specify explicitly, e.g. "G:1C 2W 2L 5Q,E:1C 5Q".
    -v                 Verbose (increase verbosity level)

Examples:

    rnxobstype C1 L1 L2 P2 S1 S2
    rnxobstype -v C1 L1 L2 P2 S1 S2
    rnxobstype -x GRES125 C1 L1 L2 P2 S1 S2

    grep TYPES data/MX5C1340.25O | rnxobstype -v -x "G:1C 2W 2L 5Q,E:1C 5Q"

    grep TYPES data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxobstype -x GRES125

(c) 2011-2025 by Hans van der Marel, Delft University of Technology.
```
For brief instructions on **rnxobssort** type `rnxobssort -h`:  

```
rnxobssort                                            (Version: 20250627)
----------
Sort RINEX version 2 to version 3 observation types.
Syntax:

    rnxobssort -?
    rnxobssort [-options] RINEX2_OBSTYPE [[ RINEX2_OBSTYPE ]]
    rnxobssort [-options] < file_with_obstypes
    cat file_with_obstypes | rnxobssort [-options]

If no RINEX version 2 observation types are given on the command line, the script reads
from the standard input and translates any RINEX version 2 or 3 observation TYPES records
it finds. Options are:

    -?|h|help..........This help
    -by sort[[,sort]]  Order for the observation types, with
                         fr[eq]  -  keep .signals (1C, .2W, etc.) together
                         ty[pe]  -  keep types (C, L, S) together
                         se[pt]  -  preferred order for Septentrio receivers
                         as[is]  -  keep as is (no sorting)
    -rm spec[[,spec]]  Remove observation types (spec = [sys:]regex )
    -v                 Verbose (increase verbosity level)

For RINEX version 3 the result of the sort options is

    -by freq|sept  ->  C1C L1C S1C C2W L2W ...             (keep .1C, .2W, etc. together)
    -by type       ->  C1C C1W ... L1C L2W ... S1C S2W ... (keep types together)

For RINEX version 2 the result of the sort options is always the same for the
first five observations "C1 L1 L2 P2 C2", but differs thereafter

    -by freq  ->  C1 L1 L2 P2 C2 S1 S2 C5 L5 S5 C7 L7 S7 ...
    -by type  ->  C1 L1 L2 P2 C2 C5 C7 ... L5 L7 ... S1 S2 S5 S7 ...
    -by sept  ->  C1 L1 L2 P2 C2 C5 L5 C7 L7 ... S1 S2 S5 S7 ...

The option "sept" is a mix of "freq" and "type"; basically it is the same as "freq", but
puts all signal strength types at the end like in "type".

The option "-rm spec[[,spec]]" specifies the observation types to remove. This is
a comma separated list with "spec" a Perl regular expession "regex" operating on all
systems or a key value pair "sys:regex" with a Perl regular expression operating on a
designated system sys (G, R, E, C, S, J, I). For example "G:2L,E:7,D.." removes all
GPS "2L' observations (C2L, L2L, D2L, S2L), all Galileo observations on frequency 7,
and all Doppler observations.

Examples:

    rnxobssort -by freq C1 C2 L1 L2 P2 S1 S2
    rnxobssort -by sept C1 P2 C2 C5 C7 L1 L2 L5 L7 S1 S2 S5 S7
    rnxobssort -by sept,freq,type C1 P2 C2 C5 C7 L1 L2 L5 L7 S1 S2 S5 S7

    grep TYPES data/MX5C1340.25O | rnxobssort -by type

    grep TYPES data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxobssort -by freq
    grep TYPES data/MX5C00NLD_R_20251340729_59M_10S_MO.rnx | rnxobssort -by freq,type,sept

(c) 2025 by Hans van der Marel, Delft University of Technology.
```
### Examples

Examples and test cases are provided in the folder `./test`. 

### RINEX compatibility

One defining characteristic of `rnxedit` and the underlying `librnxio` is that only blocks of text are manipulated. The basic text blocks are

- RINEX header line (80 characters)
- RINEX observation epoch (25 or 27 characters), epoch flag (1 character) and optional receiver clock offset (15 characters) 
- RINEX PRN number (3 characters)
- RINEX observation with SSI and LLI indicators (16 characters)

These text blocks are only reshuffled to different positions in the file or removed, the content itself - except for of header lines - is not modified.
The only editing occurs in the headers. The observations, SSI and LLI indicators are not edited (though a whole block may be removed or replaced by blanks). 
The only exception is that spaces are filled in the PRN number and century information may be provide in dates when required by the rinex standard.

Marker name, number and type, antenna number, type, delta and height, receiver type, receiver number, receiver version, agency and operator in the RINEX header lines may be edited depending on the input options. Other items in the header, such as time of first and last observation, interval and system records may be changed or removed depending on the filtering options.
When filtering is selected, a few new comment lines are added to the header detailing the filtering operation.  

The most invasive operation is conversion between RINEX version 2 and 3+. Observation types are changed and 2-character codes are changed to 3-character codes, or vice versa.  Header record may be added or converted to COMMENTS, and COMMENT lines detailing the operation are added to the header section, including a translation table between the 2- and 3-character codes.

A dilemma with upconverting from RINEX version 2 to 3+ is not all information required for three character observation codes is available from version 2. For the reverse operation, it may not be clear which observations type to select.  
Several scenarios for this are hardwired into the code, using receiver classes and more general profiles, which can be selected from the command line. 

Another dilemma with upconverting from RINEX version 2 to 3+ is how to provide mandatory header information for version 3+ that might be missing in version 2.
In RINEX observation files some header records are mandatory, others are optional, and records valid in one version may be invalid in another version, depending on the version used.

```
                          valid       mandatory   
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
WAVELENGTH FACT L1/2      2.10-2.11  

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

From version `3.01` onwards additional header information is needed, such as Glonass slot numbers, 
phase shift and Glonass bias records. From RINEX version 4 phase shift and Glonass bias records
are depricated, leaving only the Glonass slot numbers as missing information in a conversion from rinex version 2.
For version 3.01(3.02) to 3.05, the only versions where phase shift and Glonass bias records are mandatory, we use blank values 
for the phase shifts and Glonass biases to indicate that these are unknown (in agreement with the standard). 
Because of the "strong deprication" of these records in version 4 we consider this not as a great miss.

The only problem is when the Glonass slot numbers are missing, which may happen in input versions below 3.02. To cover
this situation all Glonass slot numbers that have been used in the past are provided by the Perl module `libglonass.pm`, 
which is used by the software to insert the Glonass slot numbers at the date of observation into the rinex header. This is a 
solution that works well with older rinex version 2 files, but beware, when converting contemporary rinex
version 2 files make sure the `libglonass.pm` module is up to date.

### Comparison with other tools (`teqc`, `gfzrnx`)

The `rnxedit` tool was inspired by Unavco's `teqc` and GFZ's `gfzrnx`, but doesn't share any of the code. For a comparison of the three tools:

- `teqc` only operates on RINEX version 2 files, can create RINEX version 2 from raw data files, but does quality control that none of the other two tools can do
- `rnxedit` and `teqc` can edit RINEX header data using command line options (`gfzrnx` uses crux files)
- all three tools can do filtering
- `gfzrnx` and `rnxedit` can convert between RINEX versions, `teqc` cannot
- `rnxedit` and `teqc` are single pass and can be used in pipes, `gfzrnx` reads all data in memory first and tends to be more heavy on resources than the two other tools
- `teqc` and `gfzrnx` are more capable in their own domain and have more options than `rnxedit`
- `teqc` is no anymore supported
- the free version of `gfzrnx` cannot be used for production work
- `rnxedit` source code is available (Perl) and runs on many systems, while `teqc` and `gfzrnx` are distributed as binaries for specific systems
  
In short, `rnxedit` can be used only for relatively simple and common tasks, but combines the "best" from `teqc` and `gfzrnx`.

### Motivation and development history

When in 2011 the first RINEX version 3 files came around not that many tools existed to handle the new format or conversion to the - at that time - much better supported version .
At the same time it was clear that Unavco's `teqc` would never support RINEX version 3.
This motivated me in 2011 to write a set of Perl scripts and functions for reading, writing and converting RINEX files. This became the initial version of `rnxedit`, then known as `rnx2to3.pl` (despite the name a two way convertor), and precursor libraries for `librnxio.pl` (called `rnxio.pl`) and `librnxsys.pl` (called `rnxsub.pl`). 
Soon after `gfzrnx` came around i started to use `gfzrnx` for production work. The `rnx2to3.pl` was only used for some special projects, but the underlying code was used as the basis for a new tool (called `rnxstats`) to produce observation counts and statistics.

For the editing and checking of meta data in RINEX observations files another Perl script was developed using header templates generated from a station meta-data XML database. This worked very well in a production environment, but for editing a few files from the command line it was not as convenient as the good old `teqc`.
So in 2025, i decided to add editing and filtering capabilities to `rnx2to3.pl`, rename it to `rnxedit` and release it as open source under a Apache 2 licence on github. 

Another main motivation to develop `rnxedit` is that `teqc` is not anymore supported, while `gfzrnx` is now licensed under a more restrictive license not allowing production work with the free version and tends to be rather heavy on system resources (compared to `teqc` and `rnxedit`). Also, no source code is available for `gfzrnx` and `teqc`, which i find another drawback.

To me, `rnxedit` is not intended as a full replacement for `teqc` or `gfzrnx`, it only excels at the most common operations (95% of the work). All three software tools have their own specific use cases. 

## RINEX observation statistics - `rnxstats`

RINEX observation statistics with number of epochs, satellites and observations. 
Brief instructions are provided by `rnxstats -h`

```
rnxstats                                            (Version: 20250703)
--------
Statistics for RINEX version 2 and version 3 observation files. The syntax
for simple scanning of files is

    rnxstats [-p] [-s] [-v] [-e <Pattern>] [-i <Pattern>] RINEX_observation_file(s)

    rnxstats [-p] [-s] [-v] < inputfile
    cat inputfile | rnxstats [-p] [-s] [-v][-options]
    zcat inputfile | crx2rnx | rnxstats [-p] [-s] [-v]

Rinex observation files may be (Hatanaka) compressed. If no RINEX observation
file(s) are given on the command line, and no database operations are planned,
the script reads from the standard input.
The extended syntax for data base operations is

    rnxstats -b <dbfile> [-a] [-l] [-v] [-e <Pattern>] [-i <Pattern>]
                                                      RINEX_observation_file(s)
    rnxstats -b <dbfile> -l [sxe] [-e <Pattern>] [-i <Pattern>] [-v]
    rnxstats -b <dbfile> -l [iqr1] [-e <Pattern>] [-i <Pattern>] [-v]

The first syntac is used to update the database, the second to list the content
of the database, and third to produce an index listing.
Available options are

    -b <dbfile>.....Database file to update/read
    -a .............Append to database file (the full db is not read)
    -l [sxeiqr1]....List database contents (option can be combined)
        -l s          Only summary table (default for -l)
        -l x          Include output per file
        -l e          Include overview of missing and incomplete files
        -l i          Index with file latency
        -l q          Index with percentage of data (overrides i)
        -l r          Print index in reverse order (needs i or q)
        -l 1          Print index in one column mode (needs i or q)
    -e <pattern>....Pattern to exclude rinex input files/db-entries (optional).
    -i <pattern>....Pattern to include rinex input files/db-entries (optional).
    -p .............Print extended information for each rinex input file
    -s .............Print a list of satellites for each rinex input file
    -v .............Verbose output
    -?|h|help.......This help.

Wildcard specifiers are allowed on the command line for the rinex files.

(c) 2011-2025 by Hans van der Marel, Delft University of Technology.
```
This utility processes multiple RINEX observation files and provides statistics on the number of epochs, number of satellites, etc.
An example output, taken from the [TU Delft GNSS data center](https://gnss1.tudelft.nl/dpga/scripts/prtstats.php?list=s) is
```
  station     #files  #incmpl #missing  intv  nepo avsat   G    R    E    C    J    I    S  nsat  G  R  E  C  J  I  S latency  ingest
_________ __________ ________ ________ _____ _____ _____ ____ ____ ____ ____ ____ ____ ____ ____ __ __ __ __ __ __ __ _______ _______
AMEL00NLD         31        0        0  30.0  2880  51.3 12.2  9.5 10.7 15.5  0.4  0.0  3.0  128 32 24 27 39  3  0  3    1:33    1:38
APEL00NLD         31        0        0  30.0  2880  50.2 12.1  9.4 10.6 15.6  0.4  0.0  2.1  135 32 24 29 44  3  0  3    1:27    1:33
CBW100NLD         31        0        0  30.0  2880  47.9 11.7  9.0 10.0 15.0  0.1  0.0  2.1  132 32 24 29 43  2  0  3    2:26    2:29
DELF00NLD         31        0        0  30.0  2880  57.3 11.9 10.2 11.2 16.7  0.3  2.6  4.4  149 32 26 29 45  3  7  7    1:21    1:25
DELZ00NLD         30        0        1  30.0  2880  47.3 11.6  8.9 10.0 14.5  0.0  0.0  2.2  127 32 24 27 41  0  0  3    3:42    3:45
DHEL00NLD         31        0        0  30.0  2880  41.9 10.0  8.3  9.0 12.8  0.0  0.0  1.6  130 32 24 29 42  0  0  3    4:09    4:14
DLF100NLD         31        0        0  30.0  2880  51.0 12.1  9.4 10.8 15.3  0.3  0.0  3.0  132 32 24 29 42  3  0  3    1:12    1:17
EIJS00NLD         31        0        0  30.0  2880  59.7 11.7 10.0 11.1 17.1  0.2  3.0  6.5  149 32 26 29 45  3  7  7    3:29    3:34
ENSC00NLD         31        0        0  30.0  2880  47.5  9.9  9.0  9.6 14.1  0.0  0.0  5.0  137 32 26 29 44  0  0  6   15:25   15:28
EPEN00NLD         31        2        0  30.0  2878  45.2  9.3  8.7  9.2 13.2  0.0  0.0  4.7  135 32 26 29 43  0  0  5    0:52    0:57
HARL00NLD         31        0        0  30.0  2880  47.8 11.6  9.1 10.0 14.7  0.3  0.0  2.1  135 32 24 29 43  3  0  4  138:15  138:18
HHO200NLD         31        0        0  30.0  2880  47.5 11.5  9.0 10.0 14.8  0.1  0.0  2.1  132 32 24 29 43  1  0  4    4:26    4:30
IJMU00NLD         31        0        0  30.0  2880  52.3 12.1  9.4 10.6 16.9  0.3  0.0  3.0  134 32 24 27 45  3  0  3   19:57   20:00
KOS100NLD         31        0        0  30.0  2880  60.8 12.0 10.2 11.3 17.2  0.3  3.1  6.5  149 32 26 29 45  3  7  7    1:22    1:26
MASL00NLD         31        0        0  30.0  2880  51.3 11.3  9.9 10.7 15.7  0.2  0.0  3.5  139 32 26 29 44  2  0  6    1:03    1:08
NTUS00SGP         31        0        0  30.0  2880  44.8  9.7  6.5  8.7 16.0  3.9  0.0  0.0  134 32 24 27 47  4  0  0   70:33   70:36
PBCM00BEL         31        0        0  30.0  2880  39.1  9.9  8.0  8.3 13.0  0.0  0.0  0.0  125 32 24 27 42  0  0  0    8:09   12:33
PBLB00BEL         29        2        3  30.0  2741  38.8  9.7  7.9  8.1 13.0  0.0  0.0  0.0  126 32 24 27 43  0  0  0    6:60   48:44
ROVN00NLD         31        3        0  30.0  2878  55.0 11.7 10.0 11.1 17.1  0.2  0.0  4.9  141 32 26 29 45  3  0  7    0:51    0:58
SCHI00NLD         31        0        0  30.0  2880  43.8 10.5  8.6  9.2 13.4  0.1  0.0  2.1  132 32 24 29 43  1  0  3    4:04    4:09
STWK00NLD         31        0        0  30.0  2880  54.5 11.5  9.9 10.9 16.7  0.3  0.0  5.1  141 32 26 29 44  3  0  7   15:31   15:33
TERS00NLD         31        0        0  30.0  2880  61.0 12.1 10.2 11.3 17.4  0.4  3.0  6.5  149 32 26 29 45  3  7  8    3:56    3:60
TXE200NLD         31        0        0  30.0  2880  48.2 11.8  9.2 10.1 14.3  0.0  0.0  2.8  124 32 24 27 38  0  0  3   30:05   30:11
VBZH00NLD         17        1       14  30.0  2821  53.4 11.7  9.5 10.6 15.4  0.0  0.0  6.3  130 32 24 27 40  0  0  7   15:28   15:32
VLIE00NLD         31        0        0  30.0  2880  47.3 11.7  9.1 10.1 14.2  0.1  0.0  2.1  132 32 24 29 42  2  0  3    2:20    2:23
VLIS00NLD         31        0        0  30.0  2880  49.6 11.9  9.4 10.5 15.5  0.1  0.0  2.1  134 32 24 29 43  3  0  3    4:21    4:24
VSLF00NLD         26        0        5  30.0  2880  17.6  9.7  0.0  7.8  0.0  0.0  0.0  0.0   56 31  0 25  0  0  0  0  250:54  250:55
WSRA00NLD         31        1        0  30.0  2879  50.8 12.0  9.3 10.4 15.6  0.4  0.0  2.9  130 32 24 27 41  3  0  3   16:41   16:44
WSRT00NLD         31        0        0  30.0  2880  57.4 11.6  9.4 10.5 15.9  0.4  2.8  6.6  141 32 24 27 40  3  7  8    1:12    1:17
ZEGV00NLD         31        0        0  30.0  2880  55.4 11.9 10.1 11.2 16.9  0.3  0.0  4.9  142 32 26 29 45  3  0  7    0:60    1:06
```
with for each station a count of the number of files (#files), incomplete (#incmpl) and missing files (#missing) over the last month, the data interval (intv), average number of epochs (nepo), satellites (avsat) in total and by system, and number of different satellites (nsat) observed over the period of one day in total and by system, and two measures for the average latency (latency and ingest) of the files.

## Perl function libraries

The scripts require one or more of the following Perl modules:

- **librnxio** with functions for reading and writing RINEX version 2, 3 and 4 observation files (required for `rnxedit` and `rnxstats`)
- **librnxsys** with functions for RINEX observation handling and converting between RINEX version 2 and 3 (required for `rnxedit`).
- **libglonass** with functions and historic slot allocations for GLONASS (required for `rnxedit`)

These modules can also be useful in the own right. Documentation on the functions and the data structures that are used is given in the header section of the modules. 
