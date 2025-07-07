# GNSS raw data parsers (GNSS-Perl-toolbox)

This subdirectory contains a couple of Perl scripts to parse and concatenate binary raw
GNSS data files. Some of the files are very old and only provided as-is in case there is still a use for them.
Others, such as `sbfparse.pl`, are more actively supported and used on a daily basis.

## Parse SBF (Septentrio Binary Format) files - `sbfparse`

This script parses SBF (Septentrio Binary Format) file(s). It checks for synchronisation errors
and file integrity, count the records, and determine start and end time, and output this
to the terminal.

Optionally the script can output ISMR scintillation indices as a list of comma separated values.

A brief help is provide with `sbfparse -h`:

```
sbfparse.pl                                            (Version: 20250706)
-----------
Parse SBF (Septentrio Binary Format) file(s), check for synchronisation errors 
and file integrity, count the records, and determine start and end time.
Optionally output ISMR scintillation indices.

Syntax:

    sbfparse.pl [-c] [-v|-q] [-h|?] [-s] sbffile(s)

    -c..............Check the CRC
    -s..............Print ISMR scintillation indices instead of statistics
    -q..............Quiet mode (suppresses all output except ISMR)
    -v..............Verbose mode (list messages or use -v -v for debugging)
    -?|h............This help.

    sbffile(s)......SBF files (wildcards and compression allowed).

Examples:

    sbfparse.pl sept1230.13_
    sbfparse.pl sept1230.13_.gz
    sbfparse.pl -v sept1230.13_

(c) 2010-2025 Hans van der Marel, Delft University of Technology.
```

A typical example with its ouput is

```
$ ./sbfparse.pl DLF2006w30.25_

Statistics for SBF file DLF2006w30.25_:

Start:  Mon Jan  6 22:30:00 2025
End:    Mon Jan  6 22:44:59 2025

  ID  first  count      bytes    message type              description
----  -----  -----  ---------    ----------------------    ------------------------------------
4109      0    900     618336    Meas3Ranges               Code, phase and CN0 measurements
4110      1    900      93524    Meas3CN0HiRes             Extension of Meas3Ranges containing fractional C/N0 values
4111      2    900     201132    Meas3Doppler              Extension of Meas3Ranges containing Doppler values
4086      3     15      18412    ISMR                      Ionospheric scintillation monitor (ISMR) data
4015      4      1       1104    Commands (v1)             Commands entered by the user
5902      5      1        424    ReceiverSetup (v1)        General information about the receiver set-up
5891      6     20       2800    GPSNav (v1)               GPS ephemeris and clock
5893     26      2         96    GPSIon (v1)               Ionosphere data from the GPS subframe 5
4002     27     74      11248    GALNav (v1)               Galileo ephemeris, clock, health and BGD
4030     65      1         32    GALIon (v1)               NeQuick Ionosphere model parameters
4004     66     21       2016    GLONav (v1)               GLONASS ephemeris and clock
4081     77     28       3920    BDSNav                    BeiDou ephemeris and clock
4120    103      1         48    BDSIon                    BeiDou Ionospheric delay model parameters
4031    125     78       3120    GALUtc (v1)               GST-UTC data
5896    159     57       5928    GEONav (v1)               MT09 : SBAS navigation message
4032    239     48       1536    GALGstGps (v1)            GST-GPS data
5894   1363      1         40    GPSUtc (v1)               GPS-UTC data from GPS subframe 5
             -----  ---------
              3048     963716   (ignored 0 bytes)
```
When the `-v` switch is provided a sequential list of messages is also output.

An example of ISMR record output (truncated after the first 18 records) is:
```
 $ ./sbfparse.pl -s DLF2006w30.25_
167400.000,2348,1,GPS_L1CA,G08,0.097000,0.027000
167400.000,2348,1,GPS_L2C,G08,0.069000,0.028000
167400.000,2348,1,GPS_L5,G08,0.029000,0.019000
167400.000,2348,2,GEO_L1,S123,0.066000,0.055000
167400.000,2348,2,GEO_L5,S123,0.112000,
167400.000,2348,3,GEO_L1,S148,0.120000,0.181000
167400.000,2348,4,GEO_L1,S136,0.060000,0.247000
167400.000,2348,4,GEO_L5,S136,0.101000,0.284000
167400.000,2348,5,GEO_L1,S145,0.131000,0.079000
167400.000,2348,6,GAL_L1BC,E27,0.083000,0.030000
167400.000,2348,6,GAL_E5a,E27,0.067000,0.026000
167400.000,2348,6,GAL_E5b,E27,0.066000,0.025000
167400.000,2348,6,GAL_E6BC,E27,0.065000,0.026000
167400.000,2348,7,BDS_B1I,C05,0.102000,0.045000
167400.000,2348,7,BDS_B2I,C05,0.100000,0.040000
167400.000,2348,7,BDS_B3I,C05,0.117000,0.045000
167400.000,2348,8,GPS_L1CA,G03,0.084000,0.034000
167400.000,2348,8,GPS_L2C,G03,0.122000,0.041000
...
```
with for each epoch, satellite and signal a line with, separated by commas, the second in the week (sow), week number (wcn), receiver channel (rxchan), signal type (sigtype), satellite identifier (prn),
amplitude scintillation index (S4) and $\sigma_{\Phi}$ phase scintillation index (sigma-phi).


## Legacy scripts

The following very old scripts are provided as-is without any support

- `datparse.pl` - parse Trimble dat files (last updated 28 Oct 2003)
- `tbparse.pl` - parse AoA and JPL turbo binary files (last updated 7 July 2008)
- `jpsappend.pl` - concatenate Javad and Topcon binary files (last updated 26 Sep 2005)
- `datappend.pl` - concatenate binary files (last updated 25 Sep 2005)

Both concatenation scripts produce a hidden index file `.<outputfile>.idx` with the original file name
and position in the output file (such that with a little effort the operation is invertable). The `jpsappend.pl`
script in addition removes a binary file identifier from the second file onwards.  

These scripts are provided as-is without any recent updates. The Perl code itself is a bit antiquated and has not
been checked using more modern pragma such as `use strict`. Nevertheless, the scripts should still work. 
