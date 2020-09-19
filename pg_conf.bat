@echo off

set pgdrive=c:

set pgdir=PostgreSQL

set pghome=%pgdrive%\%pgdir%\12.4-1-x64

set pgbin=%pghome%\bin

set pgdata=%pgdrive%\%pgdir%\12.4
if not exist %pgdata%\ mkdir %pgdata%

set pglogfile=%pgdata%\postgresql.log

set pguser=postgres
set pghost=localhost
set pgport=5432
set pgdb=GIS
rem set pgencoding=UTF8

set GDAL_DATA=%pghome%\gdal-data

set PERLBIN=%pgdrive%\%pgdir%\strawberry_perl_5.30.2.1-64bit_core 
set EXT=.orig

set path=%pgbin%;%perlbin%;%path%

