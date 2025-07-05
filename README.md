# GNSS-Perl-toolbox
GNSS Perl toolbox with rinex editing, filtering, statistics, time and file conversions, and a few other utilities.

## Description

### RINEX file editing, filtering and conversion

The subdirectory `rinex` contains Perl scripts for pre-processing RINEX observation files

- **rnxedit**: RINEX observation file editing, filtering and conversion for RINEX version 2, 3 and 4 observation files
- **rnxstats**: RINEX observation statistics with number of epochs, satellites and observations

and Perl modules **librnxio.pm** with functions for reading and writing RINEX version 2, 3 and 4 observation files (required for `rnxedit` and `rnxstats`),
**librnxsys.pm** with functions for RINEX observation handling and converting between RINEX version 2 and 3 (required for `rnxedit`) and **libglonass.pm** with functions for retrieving historic GLONASS slot numbers.

### GNSS date, time and file management utilities

The subdirectory `utils` contains Perl scripts for GNSS date, time and file management.
The script fall in two groups. 

Scripts that share the more general file template processing:

- `gpstime.pl` GNSS date and time conversion, file templates, and make file creation
- `gpsdir.pl` GNSS directory listing 
- `gpsdircmp.pl` GNSS directory comparison with different file formats
- `gpslatency.pl` GNSS file latency 
- `ydrange.pl` comma separated list of (files with) year-month-day information

These scripts depend on the `libgpstime.pm` Perl module for processing file templates and date/time conversion.
The module must be installed in the same directory as the scripts. 

Script that works with RINEX version 2 short and version 3 long filenames, and support for Hatanaka, unix or gzip
compression

- `scanrnx32.pl` Make IGS style index files and extract meta data from RINEX version 2 and 3 files

Other Perl dependencies are the modules `Getopt::Long`, `File::Basename` and `Time::Local`. These module are included by most, if not all, 
Perl distributions.

## Installation

You can install the full toolbox or only selected parts.

### Linux, Mac, other unix

Perl is installed by default on most Linux distributions and Mac. Simply copy the scripts to a folder in your path and they should work. Keep the libraries within the same folder as the scripts.

### Microsoft windows

Perl is not installed by default on Microsoft windows. To use the scripts you have either to install *Strawberry Perl* (comes with MinGW), *ActiveState Perl*, *MingW* (Minimalist GNU for Windows) or use *WSL* (Windows subsystem for Linux).

Another option is to install *Matlab*. *Matlab* comes with Perl on-board and you can use Perl from the Matlab terminal.

