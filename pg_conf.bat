
set pgdrive=c:

set pghome=%pgdrive%\PostgreSQL\postgresql-9.4.8-1
set pgdata=%pgdrive%\PostgreSQL\postgresql-9.4

mkdir %pgdata%

rem set pghome=%pgdrive%\PostgreSQL\postgresql-9.5.3-1\
rem set pgdata=%pgdrive%\PostgreSQL\postgresql-9.5

set pgbin=%pghome%\bin
set pglog=%pgdata%\postgresql.log

set pguser=postgres
set pghost=localhost
set pgport=5432
set pgdb=GIS

rem set pgencoding=UTF8

set PERLBIN=c:\Programs\Perl\perl\bin
set EXT=.orig
