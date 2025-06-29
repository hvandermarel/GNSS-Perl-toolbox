@echo off 
rem Edit, filter and convert RINEX observation files.
rem For instructions:
rem
rem    rnxedit -h
rem
rem This is just a wrapper around the rnxedit.pl script for the Windows 
rem command line. If perl is not in your search path replace "perl" 
rem the full path to the perl executable.

perl %~dp0rnxedit.pl %*
