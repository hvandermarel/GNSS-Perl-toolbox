# RINEX observation file pre-processing examples

The subdirectory contains examples to test the editing, filtering and translation of RINEX files.

Two test scripts, each with several examples, are provided

- `tests.sh` bash shell script with examples for editing, filtering and translation of RINEX data with `rnxedit`
- `test_rnxobstype.sh` bash shell script with examples for converting RINEX observation types from version 2 to 3 and vice versa

together with plain ascii files with their expected output.

The input and expected output RINEX data files are provided as a separate download `rnxedit_v0-9_test_datasets.zip` as an extra assest with the latest release. Unpack this zip file in the `test` folder, this will create a folder `./data` with input RINEX observation files
and  `./expected` with the output of `rnxedit`. The test script `tests.sh`  compares its outcomes with the files in `./expected`. 
