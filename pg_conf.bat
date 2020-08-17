
set pgdrive=d:

set pghome=%pgdrive%\PostgreSQL\12.4-1-x64
set pgdata=%pgdrive%\PostgreSQL\12.4

set pgbin=%pghome%\bin
set pglogfile=%pgdata%\postgresql.log

set pguser=postgres
set pghost=localhost
set pgport=5432
set pgdb=GIS

rem set pgencoding=UTF8

set PERLBIN=%pgdrive%\PostgreSQL\strawberry_perl_5.30.2.1-64bit_core 
set EXT=.orig

set path=%pgbin%;%perlbin%;%path%
