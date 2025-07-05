# GNSS file utilities (GNSS-Perl-toolbox)

The subdirectory utils contains Perl scripts that are dessigned to operate
specifically on GNSS files that include year, day of year, week, day of week, month
and/or day of month information:

- `gpstime.pl` GNSS date and time conversion, file templates, and make file creation
- `gpsdircmp.pl` comparison of two directories with GNSS files in different formats
- `ydrange.pl` generate a comma separated list of (files with) year-month-day information

Most of the scripts depend on the `libgpstime.pm` Perl module for processing the file templates and date/time conversion.
The module must be installed in the same directory as the scripts. 

Other dependencies are the Perl modules `Getopt::Long`, `File::Basename` and `Time::Local`. These module are included by most, if not all, 
Perl distributions.


## GNSS date and time conversion, templates and make files - `gpstime`

This script converts GNSS filenames (or other strings) satisfying a source template into new
filenames (or strings) satisfying an output template, while taking care of various date and time 
conversions. 

The filenames (or strings) to convert are provided via the command line and may
or may not use filename globbing (wildcards) provided by the operating system. 
These are translated into new file names with different file, date and time format. 
An example is to translate short RINEX version 2 filename into long RINEX version 3 filenames. 

The output file format is given by a target template with variable names in parenthesis. The 
target template may be a string given on the command line or a text file. 

Three typical use cases are

1. Translation of filenames (e.g. short RINEX-2 filename to long RINEX-3 filenames)
2. Subsitution of variables in a template file
3. Creation of make files (with dependencies and targets) from a template

A key feature is that GPS week, day of week, day of year, year, two-digit year, month and day of month are supported
using only the minimal number of input variables possible. For example, if the input file contains two-digit 
years and day of year (or any other combination sufficient to resolve the date), then all other variables are
computed internally by the script ready to be used in the output template.

By typing `gpstime -h` in a terminal (or on some systems `./gpstime.pl -h`) brief instructions are provided: 

```
gpstime.pl                                            (Version: 20250704)
----------
Convert gps filenames (or other strings) satisfying a source template into new
filenames (or strings) satisfying an output template, while taking care of
various date and time conversions.
Syntax:
    gpstime.pl [-d <Dir>] [-s <Tpl>] [-t <Tpl>]|[-f <File>] [-m] [-l]
                                [-x <var=val>] [-e <Pattern>] File [[Files]]

    -d <Dir>........Specifies the directory where the input files reside.
    -s <Tpl>........Source template for the input files or strings.
                    Defaults: (week)/(dow) | (doy)-(yr) | (year)-(month)-(day) |
                    (year)(month)(day) | (year)(doy).
    -t <Tpl>........Target template for the output files or strings.
                    Defaults to a nice readable format.
    -f <File>.......Path to a file with templates to process (optional).
    -e <pattern>....Pattern to exclude files from processing (optional).
    -m..............Produce a make file from file template.
    -l..............Force (sta4) to lowercase, is default, obsolete option.
    -x <var=value>..Define variable default, can be comma seperated list. The
                    default MRCCC is already set (-x "MRCCC=00NLD").
    -?|h|help.......This help.

  The files on the command line do not have to exist. So this tool can also be
  used to convert arbitrary strings, as in the first two examples. Wildcard
  specifiers are allowed on the command line.

  Examples:
    gpstime.pl 1147/3
    gpstime.pl 2002-03-12
    gpstime.pl 2023177
    gpstime.pl -s (sta4)(week)(dow).tb -t (sta4)(year)0.(yr)d delf11473.tb
    gpstime.pl -s (sta4)(week)(dow).tb -f makefile.prototype delf*.tb

  Supported variables in templates (must be embedded in parenthesis):
    sta4,STA4,Sta4..4 letter station abbreviation (lc, uc, as-is)
    MRCCC.......... 5 letter Rinex-3 monument/receiver/country code
    week,dow........GPS week and day of week
    year,month,day..Date information
    MONTH...........Three-letter abbreviation for month
    yr,doy..........Two digit year and day of year
    sessid,SESSID...Session id [a-x], [A-X] or digit
    hour............Two digit hour
    min.............Two digit minute
    ext.............Extention, file type, etc. (one or more characters)
    wldc............Anything that is not zero or more digits
  Additional variables for output templates (not for source templates):
    iso.............Date and time in ISO format
    dir.............Directory in -d option
    source..........Expanded source file
    target..........Expanded target template (not for target templates)

  Examples of templates:
    (sta4)(week)(dow).tbi
    (year)/(doy)/(sta4)(year)(sessid).(yr)d
    (sta4)(year)(month)(day)(hour).dat
    (year)(doy)

(c) 2002-2025 Hans van der Marel, Delft University of Technology.
```

Basic examples:

```
$ ./gpstime.pl 1147/3
source template is set to (week)/(dow)
Date=2002-01-02 GPSweek/dow=1147/3 doy=002
$ ./gpstime.pl 2023177
source template is set to (year)(doy)
Date=2023-06-26 GPSweek/dow=2268/1 doy=177
$ ./gpstime.pl -s "(sta4)(doy)0.(yr)o"  -t "(STA4)00NLD_R_(year)(doy)0000_01D_30S_MO.rnx"   delf1140.25o
DELF00NLD_R_20251140000_01D_30S_MO.rnx
```

Example working with files:

```
$ ./gpstime.pl -s "(sta4)(doy)(sessid).(yr)(ext).gz" \
         -t "(source) : (year)-(month)-(day)  (doy)  (week)/(dow)" ./2024/02_RINEX/*.gz
./2024/02_RINEX/10081650.24o.gz : 2024-06-13  165  2318/4
./2024/02_RINEX/10081660.24o.gz : 2024-06-14  166  2318/5
./2024/02_RINEX/10081670.24o.gz : 2024-06-15  167  2318/6
./2024/02_RINEX/10081680.24o.gz : 2024-06-16  168  2319/0
./2024/02_RINEX/10081690.24o.gz : 2024-06-17  169  2319/1
./2024/02_RINEX/amtm1690.24o.gz : 2024-06-17  169  2319/1
./2024/02_RINEX/amtm1700.24o.gz : 2024-06-18  170  2319/2
./2024/02_RINEX/amtm1710.24o.gz : 2024-06-19  171  2319/3
./2024/02_RINEX/amtm1720.24o.gz : 2024-06-20  172  2319/4
...
```

Another example working with files, showing how to create a script for moving
files into another folder scructure. Capture the output in a file, and run this
as a script (after checking it does what you want):

```
$ ./gpstime.pl -s "(sta4)(doy)(sessid).(yr)(ext).gz" -t "mv (source) ./(year)/(STA4)/" ./2024/02_RINEX/*.gz
mv ./2024/02_RINEX/10081650.24o.gz ./2024/1008/
mv ./2024/02_RINEX/10081660.24o.gz ./2024/1008/
mv ./2024/02_RINEX/10081670.24o.gz ./2024/1008/
mv ./2024/02_RINEX/10081680.24o.gz ./2024/1008/
mv ./2024/02_RINEX/10081690.24o.gz ./2024/1008/
mv ./2024/02_RINEX/amtm1690.24o.gz ./2024/AMTM/
mv ./2024/02_RINEX/amtm1700.24o.gz ./2024/AMTM/
...
```

More complex examples for creating make files:

```
$ cat > tmp.mrl <<EOD
(target): (source)
    sbf2rin -R3 -i 30 -f (source) -o (target)
EOD
$ ./gpstime.pl -s "(sta4)(doy)(sessid).(yr)_" -t "(STA4)00NLD_R_(year)(doy)(hour)(min)_01H_30S_MO.rnx" \
      -f tmp.mrl -m  delf134b.25_ delf134c.25_ delf134x.25_
ALL : DELF00NLD_R_20251340100_01H_30S_MO.rnx DELF00NLD_R_20251340200_01H_30S_MO.rnx DELF00NLD_R_20251342300_01H_30S_MO.rnx

DELF00NLD_R_20251340100_01H_30S_MO.rnx: delf134b.25_
    sbf2rin -R3 -i 30 -f delf134b.25_ -o DELF00NLD_R_20251340100_01H_30S_MO.rnx
DELF00NLD_R_20251340200_01H_30S_MO.rnx: delf134c.25_
    sbf2rin -R3 -i 30 -f delf134c.25_ -o DELF00NLD_R_20251340200_01H_30S_MO.rnx
DELF00NLD_R_20251342300_01H_30S_MO.rnx: delf134x.25_
    sbf2rin -R3 -i 30 -f delf134x.25_ -o DELF00NLD_R_20251342300_01H_30S_MO.rnx

```

redirecting the output of `./gpstime.pl` to a make file (`tmp.mak`) allows execution of the 
commands using `make -f tmp.mak`.

Another example to show how the script can be used to create daily from hourly files:

```
$ cat > tmp.mrl <<EOD
(target): (source)
    cat $< > tmp.sbf
    sbf2rin -R3 -i 30 -f tmp.sbf -o (target)
    rm -f tmp.sbf
EOD
$ ./gpstime.pl -s "(sta4)(doy)(sessid).(yr)_" -t "(STA4)00NLD_R_(year)(doy)0000_01D_30S_MO.rnx" \
      -f tmp.mrl -m  delf134b.25_ delf134c.25_ delf134x.25_
ALL : DELF00NLD_R_20251340000_01D_30S_MO.rnx

DELF00NLD_R_20251340000_01D_30S_MO.rnx: delf134b.25_ delf134c.25_ delf134x.25_
    cat $< > tmp.sbf
    sbf2rin -R3 -i 30 -f tmp.sbf -o DELF00NLD_R_20251340000_01D_30S_MO.rnx
    rm -f tmp.sbf
```

The make file templates are the actual recipees. They can become as complex
as needed and are usually stored as file with `mrl` extension in a safe place for 
further reuse.


## GNSS directory listing - `gpsdir`

This Perl script makes a generalized directory listing for GNSS files
using the date and time information in the filenames.

By typing `gpsdir -h` in a terminal (or on some systems `./gpsdir.pl -h`) a short help is provided

```
gpsdir.pl                                            (Version: 20250705)
---------
Make a generalized "directory listing" for GNSS specific files
which use either "week/dow", "doy" or "year, month, day" formats.
Syntax:
  gpsdir.pl [-d <Dir>] [-s <Tpl>] [-[e|i] <Pattern>] File [[Files]]

  -d <Dir>........Specifies the directory where the input files reside.
  -s <Tpl>........Source template for the input files or strings.
  -i <pattern>....Pattern to include files from processing (optional).
  -e <pattern>....Pattern to exclude files from processing (optional).
  -?|h|help.......This help.

wildcards in the file specification are allowed. The source template is
determined automatically from the filenames.

Examples:
  gpsdir.pl -s (sta)/(week)(dow)000.cbi -d refsta delf/*.cbi
  gpsdir.pl -s (year)/(doy)/(sta4)(doy)(sessid).(yr)d
                                       rinex/2002/???/delf*.02d.Z

Supported variables in templates (must be embedded in parenthesis):
  sta4,STA4,Sta4..4 letter station abbreviation
  MRCCC.......... 5 letter Rinex-3 monument/receiver/country code
  week,dow........GPS week and day of week
  year,month,day..Date information
  MONTH...........Three-letter abbreviation for month
  yr,doy..........Two digit year and day of year
  sessid,SESSID...Session id [a-x], [A-X] or digit
  hour............Two digit hour
  min.............Two digit minute
  ext.............Extention, file type, etc. (one or more characters)
  wldc............Anything that is not zero or more digits

(c) 2003-2025 Hans van der Marel, Delft University of Technology.
```

An example is shown below (with reduced output):

```
$ ./gpsdir.pl -d ./2024/02_RINEX/ -s "(sta4)(doy)0.(yr)(ext)" *.24o.gz
sta4 week/d doy  date              0         1         2
---- ------ ---  ---------------  D012345678901234567890123
1008 2318/4 165  Thu Jun 13 2024  0
1008 2318/5 166  Fri Jun 14 2024  0
1008 2318/6 167  Sat Jun 15 2024  0
1008 2319/0 168  Sun Jun 16 2024  0
1008 2319/1 169  Mon Jun 17 2024  0
amtm 2319/1 169  Mon Jun 17 2024  0
amtm 2319/2 170  Tue Jun 18 2024  0
amtm 2319/3 171  Wed Jun 19 2024  0
...
vr71 2319/5 173  Fri Jun 21 2024  0
vr71 2319/6 174  Sat Jun 22 2024  0

sta4 week  0123456
---- ----  -------
1008 2318      000
1008 2319  00
amtm 2319   0000
ausb 2319   0000
...
viti 2319   0    0
viti 2320  000
vr71 2319     0000

Missing days:

sta4  date             week/d doy
----  ---------------  ------ ---
bf09  Fri Jun 21 2024  2319/5 173
bf09  Sat Jun 22 2024  2319/6 174
...
viti  Fri Jun 21 2024  2319/5 173
```

## GNSS directory comparison - `gpsdircmp`

This Perl script compares two directories (or directory listing) with GNSS filenames and
list them side-by-side.GNSS filenames can be in several different formats
for each side of the comparison.

By typing `gpsdircmp -h` in a terminal (or on some systems `./gpsdircmp.pl -h`) a short help is provided

```
gpsdircmp.pl                                            (Version: 20250705)
------------
Compare two directories (or directory listing) with GNSS filenames and
list them side-by-side.GNSS filenames can be in several different formats
for each side of the comparison.
Syntax:
  gpsdircmp.pl [-s <Tpl>] [-t <Tpl>]  "path1" "path2"
  gpsdircmp.pl [-s <Tpl>] [-t <Tpl>]  dirList1 dirList2

    -s <Tpl>........Source template for the first file/directory
    -t <Tpl>........Target template for the second file/directory
    -?|h|help.......This help.

the template specifiers are optional, and have only to be specified
if the software fails to autodetect the filename format.

The directory specifications path1 and path2 must be enclosed in "" to
prevent shell-globbing), dirList1 and dirList2 are files with filenames, filesize
and path created using the find command, e.g.

  find ~/rawdata/2006/kosg/* -printf "%f %s %h\n" >> file.1

Examples:
  gpsdircmp.pl "./*.cmp" "~/rawdata/200{5,6}/kosg/*"

  find ~/rawdata/2006/kosg/* -printf "%f %s %h\n" > file.1
  find ~/rinex/2006/???/kosg*.??d.Z -printf "%f %s %h\n" > file.2
  gpsdircmp.pl file.1 file.2

  gpsdircmp.pl -s "(sta4)(week)(dow).tb" -t "(sta4)(year)0.(yr)d" file.1 file.2

Supported variables in templates (must be embedded in parenthesis):
  sta4,STA4,Sta4..4 letter station abbreviation (lc, uc, as-is)
  MRCCC.......... 5 letter Rinex-3 monument/receiver/country code
  week,dow........GPS week and day of week
  year,month,day..Date information
  MONTH...........Three-letter abbreviation for month
  yr,doy..........Two digit year and day of year
  sessid,SESSID...Session id [a-x], [A-X] or digit
  hour............Two digit hour
  min.............Two digit minute
  ext.............Extention, file type, etc. (one or more characters)
  wldc............Anything that is not zero or more digits

Examples of templates:
  (sta4)(week)(dow).tbi
  (year)/(doy)/(sta4)(year)(sessid).(yr)d
  (sta4)(year)(month)(day)(hour).dat

(c) 2006-2025 Hans van der Marel, Delft University of Technology.
```

An example, comparing two folders with rinex data created by different persons using the same
raw input data, is given below. 

```
$ ./gpsdircmp.pl "./2024/02_RINEX/*.gz" "./2024_STUDENTS/02_RINEX/????/*{o,o.gz}"
source template is set to (sta4)(doy)(sessid).(yr)(ext).gz
target template is set to (sta4)(doy)(sessid).(yr)(ext)

                         ./2024/02_RINEX/*.gz   ./2024_STUDENTS/02_RINEX/????/*{o,o.gz}    ratio

Number of files                    365                        109                           0.30
Average filesize               2724502                    6641870                           2.44
Median filesize                1988589                    5927201                           2.98
Median of ratios                                                                            2.51

./2024/02_RINEX/*.gz                                            ./2024_STUDENTS/02_RINEX/????/*{o,o.gz}
filename____________ ____size path___________________________   filename_______ ____size path__________________________

10081650.24o.gz       1309093 ./2024/02_RINEX                 ) 10081650.24o     2346984 ./2024_STUDENTS/02_RINEX/1008 
10081660.24o.gz       5129342 ./2024/02_RINEX                 ) 10081660.24o     9146614 ./2024_STUDENTS/02_RINEX/1008 
10081670.24o.gz       5106449 ./2024/02_RINEX                 ) 10081670.24o     9146813 ./2024_STUDENTS/02_RINEX/1008 
10081680.24o.gz       5095091 ./2024/02_RINEX                 ) 10081680.24o     9159597 ./2024_STUDENTS/02_RINEX/1008 
10081690.24o.gz       1965229 ./2024/02_RINEX                 ) 10081690.24o     3395516 ./2024_STUDENTS/02_RINEX/1008 
amtm1690.24o.gz        595863 ./2024/02_RINEX                 >                                                        
...
bf011750.24o.gz        770084 ./2024/02_RINEX                 >                                                        
bf091720.24o.gz        711247 ./2024/02_RINEX                   BF091720.24o.gz  1652506 ./2024_STUDENTS/02_RINEX/BF09 
                                                              < BF091730.24o.gz    32602 ./2024_STUDENTS/02_RINEX/BF09 
                                                              ?
bf091760.24o.gz       4689613 ./2024/02_RINEX                 >                                                        
bf091770.24o.gz       8982320 ./2024/02_RINEX                 >                                                        
...
vr711730.24o.gz       1581271 ./2024/02_RINEX                 >                                                        
vr711740.24o.gz        626925 ./2024/02_RINEX                 >                                                        

Copy left to right candidates (due to missing files on the right)

./2024/02_RINEX/amtm1690.24o.gz
./2024/02_RINEX/amtm1700.24o.gz
...
./2024/02_RINEX/vr711740.24o.gz

Copy left to right candidates (due to size differences of 50% or more)
...
Copy left to right candidates (due to size differences of 20%-50%)
...
Copy right to left candidates (due to missing files on the left)
...
Copy right to left candidates (due to size differences of 50% or more)
...
Copy right to left candidates (due to size differences of 20%-50%)
...
Stations with perhaps missing days on both sides (?)

sta4  wwww/d  doy  date___________
bf09  2319/6  174  Sat Jun 22 2024
bf09  2320/0  175  Sun Jun 23 2024
...
viti  2319/5  173  Fri Jun 21 2024
```

Most of the output been suppressed (...) to save space.

## GNSS file latency - `gpslatency`

This script makes a listing of GNSS files with their latency. The
latency is computed by comparing the date and time information from the 
filenames to the os timestamp of the file. 

By typing `gpslatency -h` in a terminal (or on some systems `./gpslatency.pl -h`) a short help is provided

```
gpslatency.pl                                            (Version: 20250705)
-------------
Make a directory listing of GNSS specific files which use either
"week/dow", "doy" or "year, month, day" formats with file latency
data.
Syntax:
  gpslatency.pl [-d <Dir>] [-s <Tpl>] [-[e|i] <Pattern>] File [[Files]]

  -d <Dir>........Specifies the directory where the input files reside.
  -s <Tpl>........Source template for the input files or strings.
  -i <pattern>....Pattern to include files from processing (optional).
  -e <pattern>....Pattern to exclude files from processing (optional).
  -l <minutes>....File interval in minutes (default is 60 minutes).
  -c <minutes>....Only print files that are later than this limit.
  -?|h|help.......This help.

wildcards in the file specification are allowed. The source template is
determined automatically from the filenames.

Examples:
  gpslatency.pl -s (sta)/(week)(dow)000.cbi -d refsta delf/*.cbi
  gpslatency.pl -s (year)/(doy)/(sta4)(doy)(sessid).(yr)d
                                       rinex/2002/???/delf*.02d.Z

Supported variables in templates (must be embedded in parenthesis):
  sta4,STA4,Sta4..4 letter station abbreviation
  MRCCC.......... 5 letter Rinex-3 monument/receiver/country code
  week,dow........GPS week and day of week
  year,month,day..Date information
  MONTH...........Three-letter abbreviation for month
  yr,doy..........Two digit year and day of year
  sessid,SESSID...Session id [a-x], [A-X] or digit
  hour............Two digit hour
  min.............Two digit minute
  ext.............Extention, file type, etc. (one or more characters)
  wldc............Anything that is not zero or more digits

(c) 2003-2025 Hans van der Marel, Delft University of Technology.
```

An example is shown below (with reduced output):

```
$ ./gpslatency.pl -d ./2024/02_RINEX/ -s "(sta4)(doy)0.(yr)(ext)" *.24o.gz
Filename                                  First Epoch                 Received                       Latency  Delay(sec)    Dirname
----------------------------------------  --------------------------  --------------------------  ----------  ----------    -------------
10081650.24o.gz                           Thu Jun 13 00:00:00 2024    Wed Jul 10 11:32:00 2024       27 days     2287920    ./2024/02_RINEX
10081660.24o.gz                           Fri Jun 14 00:00:00 2024    Wed Jul 10 11:32:00 2024       26 days     2201520    ./2024/02_RINEX
10081670.24o.gz                           Sat Jun 15 00:00:00 2024    Wed Jul 10 11:32:00 2024       25 days     2115120    ./2024/02_RINEX
10081680.24o.gz                           Sun Jun 16 00:00:00 2024    Wed Jul 10 11:32:00 2024       24 days     2028720    ./2024/02_RINEX
10081690.24o.gz                           Mon Jun 17 00:00:00 2024    Wed Jul 10 11:32:00 2024       23 days     1942320    ./2024/02_RINEX
amtm1690.24o.gz                           Mon Jun 17 00:00:00 2024    Wed Jul 10 11:32:00 2024       23 days     1942320    ./2024/02_RINEX
amtm1700.24o.gz                           Tue Jun 18 00:00:00 2024    Wed Jul 10 11:32:00 2024       22 days     1855920    ./2024/02_RINEX
amtm1710.24o.gz                           Wed Jun 19 00:00:00 2024    Wed Jul 10 11:32:00 2024       21 days     1769520    ./2024/02_RINEX
...
vr711730.24o.gz                           Fri Jun 21 00:00:00 2024    Wed Jul 10 11:36:00 2024       19 days     1596960    ./2024/02_RINEX
vr711740.24o.gz                           Sat Jun 22 00:00:00 2024    Wed Jul 10 11:36:00 2024       18 days     1510560    ./2024/02_RINEX

   Latency   Count
----------   -----
   13 days       4
   14 days      12
   15 days      16
...
  367 days       5
  368 days       1
```



## Bulding blocks for GNSS file name globbing - `ydrange`

The script `ydrange.pl` is a minimalistic Perl script to create comma separated
lists or building blocks for file name globbing in shell scripts. It is often
used in a shell script, in conjunction with `gpstime.pl`, to generate a file path
for a processing job.

By typing `ydrange -h` in a terminal (or on some systems `./ydrange.pl -h`) a short help is provided

```
ydrange.pl                                            (Version: 20250704)
----------
Generate a comma separated list of year-month-day information.
Syntax:
    ydrange.pl [-[hgyx23]] [-d[delay] <numdays] [-r[ange] <numdays>]

    -d[elay] ## ....Generate is for ## days in the past (default 0).
    -r[ange] ## ....Number of days in the list (default 1).
    -?|h|help.......This help.

Default is to create a comma separated list with yyyymmdd values, unless
one of the following mutually exclusive options is used

    -g[ps]..........Csv list GPS week and day of week.
    -[do]y..........Csv list witg 2 digit year and day of year.
    -[rn]x..........Regex with rinex 2 file pattern
    -[rx]2..........Csv list with rinex 2 highrate file pattern
    -[rx]3..........Regex with rinex-3 yyyydoy values

(c) 2002-2025 Hans van der Marel, Delft University of Technology.
```

Examples:

```
$ ./ydrange.pl
20250705
$ ./ydrange.pl -d 1 -r 5
20250630,20250701,20250702,20250703,20250704
$ ./ydrange.pl -d 1 -r 5 -3
2025181|2025182|2025183|2025184|2025185
$ ./ydrange.pl -d 1 -r 5 -2
181...\.25,182...\.25,183...\.25,184...\.25,185...\.25
```

## Perl module `libgpstime.pm`

This module provides the function for the template processing used by `gpstime.pl`, `gpsdircmp.pl`, `gpsdir.pl` and `gpslatency.pl`. 
The module must be installed in the same folder as the scripts.

