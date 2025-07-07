# GNSS-Perl-toolbox
GNSS Perl toolbox with rinex editing, filtering, statistics, time and file conversions, and a few other utilities.

## Description

### RINEX file editing, filtering and conversion

The subdirectory [`rinex`](rinex/) contains Perl scripts for pre-processing RINEX observation files

- `rnxedit.pl`: RINEX observation file editing, filtering and conversion for RINEX version 2, 3 and 4 observation files
- `rnxstats.pl`: RINEX observation statistics with number of epochs, satellites and observations

and Perl modules `librnxio.pm` with functions for reading and writing RINEX version 2, 3 and 4 observation files (required for `rnxedit` and `rnxstats`),
`librnxsys.pm` with functions for RINEX observation handling and converting between RINEX version 2 and 3 (required for `rnxedit`) and `libglonass.pm` with functions for retrieving historic GLONASS slot numbers.

### GNSS date, time and file management utilities

The subdirectory [`utils`](utils/) contains Perl scripts for GNSS date, time and file management.
The script fall in two groups. 

Script that works with RINEX version 2 short and version 3 long filenames (including support for Hatanaka, unix or gzip
compression)

- `scanrnx32.pl` Make IGS style index files and extract meta data from RINEX version 2 and 3 files

Scripts that share the more general file template processing (provided by `libgpstime.pm`):

- `gpstime.pl` GNSS date and time conversion, file templates, and make file creation
- `gpsdir.pl` GNSS directory listing 
- `gpsdircmp.pl` GNSS directory comparison with different file formats
- `gpslatency.pl` GNSS file latency 
- `ydrange.pl` comma separated list of (files with) year-month-day information

The second set of scripts depend on the `libgpstime.pm` Perl module for processing file templates and date/time conversion.
The module must be installed in the same directory as the scripts. 

### GNSS raw data parsers

The subdirectory [`raw`](raw/) contains a couple of Perl scripts to parse binary raw GNSS data files. 

- `sbfparse.pl` Parse Septentrio Binary Format files and optionally extract ISMR (scintillation) records

The other scripts, for parsing and concatenating Turbo binary, Trimble dat files or Javad/Topcon raw data files, 
are very old and only provided as-is in case there is still a use for them.


## Installation

You can install the full toolbox or only selected parts.

### Linux, Mac, other unix

Perl is installed by default on most Linux distributions and Mac. Simply copy the scripts to a folder in your path and they should work. Keep the libraries within the same folder as the scripts.

### Microsoft windows

Perl is not installed by default on Microsoft windows. To use the scripts you have either to install *MSYS2/MingW64* (Minimalist GNU for Windows), *Strawberry Perl* (comes with MSYS2/MinGW64), *ActiveState Perl*, , use *WSL* (Windows subsystem for Linux) or run the scripts from the Git bash shell prompt (also MSYS2/MinGW64). 

Another option is to install *Matlab*. *Matlab* comes with Perl on-board and you can use Perl from the Matlab terminal.

## Perl dependencies

The main Perl dependencies are the modules `Getopt::Long`, `File::Basename` and `Time::Local`. These module are part of core Perl and included by most, if not all, 
Perl distributions.
