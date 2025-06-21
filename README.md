# GNSS-Perl-toolbox
GNSS Perl toolbox with rinex editing and statistics, time conversions, and other utilities.

## Description

### RINEX file editing, filtering and conversion

The subdirectory `rinex` contains Perl scripts for pre-processing RINEX observation files

- **rnxedit**: RINEX observation file editing, filtering and conversion for RINEX version 2, 3 and 4 observation files
- **rnxstats**: RINEX observation statistics with number of epochs, satellites and observations

and Perl libraries **librnxio.pl** with functions for reading and writing RINEX version 2, 3 and 4 observation files (required for `rnxedit` and `rnxstats`)
and **librnxsys.pl** with functions for RINEX observation handling and converting between RINEX version 2 and 3 (required for `rnxedit`).

### GNSS date and time conversion

## Installation

You can install the full toolbox or only selected parts.

### Linux, Mac, other unix

Perl is installed by default on most Linux distributions and Mac. Simply copy the scripts to a folder in your path and they should work. Keep the libraries within the same folder as the scripts.

If you want, you can create a symbolic link (without the `.pl` extension) from folder in your search path to each script.

### Microsoft windows

Perl is not installed by default on Microsoft windows. To use the scripts you have either to install *Strawberry Perl* (comes with MinGW), *ActiveState Perl*, *MingW* (Minimalist GNU for Windows) or use *WSL* (Windows subsystem for Linux).

Another option is to install *Matlab*. *Matlab* comes with Perl on-board and you can use Perl from the Matlab terminal.

