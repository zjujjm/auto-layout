README File for auto layout toolkit

Author: Junmin Jiang

## Usage

1. First set everything right of config file
2. Set socket port to 8885 in Cadence
2. First time run:
   make init
3. For LVS:
   make lvs-all TOP_MODULE=XX
4. For DRC:
   make drc-all TOP_MODULE=XX
5. For ALL:
   make all TOP_MODULE=XX

## Updates

v2: 30 Apr, 2015

1. runRVE: grep pattern revised to avoid submodules
2. Makefile: action all do not need streamout again
