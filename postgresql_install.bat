
cmd.exe

chcp 1250

d:

mkdir d:\PostgreSQL
cd d:\PostgreSQL

	Download:

	PostgreSQL server ZIP installer from https://www.enterprisedb.com/download-postgresql-binaries
	wget -nH -nd https://get.enterprisedb.com/postgresql/postgresql-12.4-1-windows-x64-binaries.zip
	powershell -command "& { iwr https://get.enterprisedb.com/postgresql/postgresql-12.4-1-windows-x64-binaries.zip -OutFile postgresql-12.4-1-windows-x64-binaries.zip }"

	PostGIS extender from http://download.osgeo.org/postgis/windows/pg12/
	wget -nH -nd http://download.osgeo.org/postgis/windows/pg12/postgis-bundle-pg12-3.0.2x64.zip
	powershell -command "& { iwr http://download.osgeo.org/postgis/windows/pg12/postgis-bundle-pg12-3.0.2x64.zip -OutFile postgis-bundle-pg12-3.0.2x64.zip }"

	PgAdmin III version 1.26b from https://vvs.ru/pg/index-en.html
	wget -nH -nd https://vvs.ru/pg/pgadmin3-1-26.msi
	powershell -command "& { iwr https://vvs.ru/pg/pgadmin3-1-26.msi -OutFile pgadmin3-1-26.msi }"

unzip postgresql-12.4-1-windows-x64-binaries.zip
rename pgsql 12.4-1-x64

mkdir 12.4

notepad pg_conf.bat
 
call pg_conf.bat

%pgbin%\pg_ctl.exe init -D %pgdata%
The files belonging to this database system will be owned by user "%USERNAME%".
This user must also own the server process.

The database cluster will be initialized with locale "Hungarian_Hungary.1250".
The default database encoding has accordingly been set to "WIN1250".
The default text search configuration will be set to "hungarian".

Data page checksums are disabled.

fixing permissions on existing directory d:/PostgreSQL/12.4 ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... windows
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Europe/Belgrade
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    d:/PostgreSQL/12.4-1-x64/bin/pg_ctl -D d:/PostgreSQL/12.4 -l logfile start


notepad %pgdata%\postgresql.conf
	listen_addresses = '*'
	password_encryption = md5
	log_timezone = 'Europe/Budapest'
	timezone = 'Europe/Budapest'

notepad %pgdata%\ph_hba.conf
	host	all	all	<your_ip>/32	md5

%pgbin%\pg_ctl.exe start -D %pgdata% -l %pglogfile%

if not localhost: Windows Firewall -> Elérés engedélyezése

%pgbin%\psql -U %username% -d postgres -c "select version()"
                          version
------------------------------------------------------------
 PostgreSQL 12.4, compiled by Visual C++ build 1914, 64-bit
(1 row)

%pgbin%\psql -U %username% -d postgres -c "CREATE ROLE postgres LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION"
CREATE ROLE

%pgbin%\psql -U %username% -d postgres -c "ALTER DATABASE postgres OWNER TO postgres"
ALTER DATABASE

rem PostGIS

%pgbin%\pg_ctl.exe stop -D %pgdata%

unzip postgis-bundle-pg12-3.0.2x64.zip

cd postgis-bundle-pg12-3.0.2x64

call ..\postgis_install.bat

%pgbin%\pg_ctl.exe start -D %pgdata% -l %pglogfile%

%pgbin%\psql -c "CREATE DATABASE %pgdb%"
%pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION postgis;"
rem %pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION postgis_sfcgal;"
rem %pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION postgis_topology;"
rem %pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION address_standardizer;"
rem %pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION address_standardizer_data_us;"
rem %pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION fuzzystrmatch;"
rem %pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION postgis_tiger_geocoder;"

REM Uncomment the below line if this is a template database
REM "%PGBIN%\psql" -d "%pgdb%" -c "UPDATE pg_database SET datistemplate = true WHERE datname = '%pgdb%';GRANT ALL ON geometry_columns TO PUBLIC; GRANT ALL ON spatial_ref_sys TO PUBLIC"

%pgbin%\pg_ctl.exe restart -D %pgdata%

rem %pgbin%\pg_ctl.exe stop -D %pgdata%

pgadmin3-1-26.msi

exit /b

del postgresql-12.4-1-windows-x64-binaries.zip
del postgis-bundle-pg12-3.0.2x64.zip
del pgadmin3-1-26.msi

+

runas /noprofile /user:Rendszergazda cmd.exe

call pg_conf.bat 

d:\PostgreSQL>%pgbin%\pg_ctl.exe register -D %pgdata% -N PostgreSQL

d:\PostgreSQL>%pgbin%\pg_ctl.exe unregister -D %pgdata% -N PostgreSQL



rem NET USER %pguser% /DEL
rem NET USER %pguser% * /ADD /ACTIVE:yes /FULLNAME:"PostgreSQL User" /COMMENT:"PostgreSQL Database Administrator"

rem if not defined pgencoding
rem 	%pgbin%\initdb -U %pguser% -D %pgdata%
rem ) else (
rem 	%pgbin%\initdb -E %pgencoding% -U %pguser% -D %pgdata%
rem )

rem %PERLBIN%\perl -i%EXT% -p -e "s/^#?(checkpoint_segments)\s*=\s*\d+/$1=16/;s/^#?(password_encryption)\s*=\s*\w+/$1=on/" %pgdata%\postgresql.conf
