
set pgdrive=c:

set pghome=%pgdrive%\PostgreSQL\12.3-2-x64
set pgdata=%pgdrive%\PostgreSQL\12.3

mkdir %pgdata%

set pgbin=%pghome%\bin
set pglog=%pgdata%\postgresql.log

set pguser=postgres
set pghost=localhost
set pgport=5432
set pgdb=GIS

rem set pgencoding=UTF8

set PERLBIN=c:\Programs\Perl\perl\bin
set EXT=.orig
