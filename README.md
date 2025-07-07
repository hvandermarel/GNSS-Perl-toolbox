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

To use the scripts you do not need to have any Perl knowledge, but you need to have Perl installed on your system. If you have Perl, the scripts will run from the command line like any other Linux, Mac or Windows command line or terminal application.

### Linux, Mac, other unix

Perl is installed by default on most Linux distributions and Mac. Simply copy the scripts to a folder in your path and they should work. Keep the libraries within the same folder as the scripts.

### Microsoft windows

Perl is not installed by default on Microsoft windows. To use the scripts you have either to install [MSYS2/MinGW64](https://www.msys2.org/) (Minimalist GNU for Windows), [Strawberry Perl](https://strawberryperl.com/) (comes with MSYS2/MinGW64 under the hood), [ActiveState Perl](https://www.activestate.com/platform/supported-languages/perl/), run the scripts from the [Git](https://git-scm.com/downloads) bash shell prompt (which is also MSYS2/MinGW64), or use Linux under Microsoft [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows subsystem for Linux). 

Another option is to use [Matlab](https://www.mathworks.com/products/matlab.html) if you have that already installed. Matlab comes with Perl on-board and you can use Perl from the Matlab command window.

If you plan to use the Windows command prompt, please read on. 

In the Windows command prompt (but *not* in a MSYS2/MinGW64 terminal or WSL) you have to run the scripts with a command like `perl script.pl .-options arg`. If you find this 
inconvenient you can create a small (executable) batch file with the same name as the script but extension `.bat`, with the following content
```
@echo off 
rem Wrapper around the rnxedit.pl script for the Windows command line. If perl is not 
rem in your search path replace "perl" the full path to the perl executable. The 
rem Perl script is expected in the same folder as this file, if not use the full 
rem path name to the executable (without "%~dp0")

perl %~dp0rnxedit.pl %*
```
You can then simply execute as `script`.  This is only necessary for the Windows command prompt, not under WSL or from a MSY2/MinGW64 terminal.

### Hints and tips

In order for the operating system to run the scripts it must first find them:

- scripts (with extension `.pl`) should be placed in a directory that is on your seach path (e.g. `~/bin`) or run from the current working directory using the full path,
- modules (with extension `.pm`) should be installed in the same directory as your scripts or any other directory that is in the Perl module search path (`@INC`).

If you don't like to type the `.pl` extension everytime you run the script, please feel free to rename the script (removing the `.pl` extension). Using the `.pl` extension on scripts is my
personal preference, but it is not necessary under Linux and there are many that don't like the use of this extension. My solution to this "problem" is to use a symbolic 
link, without extension, to the actual script file with extension. 

For modules this is completely different, never remove the `.pm` extension, Perl relies on this.


### Perl dependencies

The main Perl dependencies are the modules `Getopt::Long`, `File::Basename` and `Time::Local`. These module are part of core Perl and included by most, if not all, 
Perl distributions.
