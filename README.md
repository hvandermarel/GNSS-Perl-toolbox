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

You can install the full toolbox or select only a few scripts (with required modules) that you are interested in. 

- scripts (with extension `.pl`) can be placed in a directory that is on your seach path (e.g. `~/bin`) or executed from the current working directory
- modules (with extension `.pm`) should be installed in the same directory as your scripts or any other directory that is in the Perl search path (`@INC`) for packages

If you don't like the `.pl` extension in the file name, please feel free to rename the script (removing the `.pl` extension). To use the `.pl` extension on scripts is my
personal preference, but there are many that don't like this or type the `.pl` extension everytime they execute the script. My solution to this "problem" is to use a symbolic 
link without extension. For the modules, never remove the `.pm` extension, Perl relies on this.

### Linux, Mac, other unix

Perl is installed by default on most Linux distributions and Mac. Simply copy the scripts to a folder in your path and they should work. Keep the libraries within the same folder as the scripts.

### Microsoft windows

Perl is not installed by default on Microsoft windows. To use the scripts you have either to install [MSYS2/MinGW64](https://www.msys2.org/) (Minimalist GNU for Windows), [Strawberry Perl](https://strawberryperl.com/) (comes with MSYS2/MinGW64 under the hood), [ActiveState Perl](https://www.activestate.com/platform/supported-languages/perl/), run the scripts from the [Git](https://git-scm.com/downloads) bash shell prompt (which is also MSYS2/MinGW64), or use Linux under Microsoft [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows subsystem for Linux). 

Another option is to use [Matlab](https://www.mathworks.com/products/matlab.html) if you have that already installed. Matlab comes with Perl on-board and you can use Perl from the Matlab command window.

### Perl dependencies

The main Perl dependencies are the modules `Getopt::Long`, `File::Basename` and `Time::Local`. These module are part of core Perl and included by most, if not all, 
Perl distributions.
