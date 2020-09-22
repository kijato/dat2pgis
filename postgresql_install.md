**Válasszunk ki egy könyvtárat, ahová a PostgreSQL-t telepíteni szeretnénk:

	cmd.exe
	chcp 1250
	c:
	mkdir c:\PostgreSQL
	cd c:\PostgreSQL

**Download:

	PostgreSQL server ZIP installer from https://www.enterprisedb.com/download-postgresql-binaries
	wget -nH -nd https://get.enterprisedb.com/postgresql/postgresql-12.4-1-windows-x64-binaries.zip
	powershell -command "& { iwr https://get.enterprisedb.com/postgresql/postgresql-12.4-1-windows-x64-binaries.zip -OutFile postgresql-12.4-1-windows-x64-binaries.zip }"

	PostGIS extender from http://download.osgeo.org/postgis/windows/pg12/
	wget -nH -nd http://download.osgeo.org/postgis/windows/pg12/postgis-bundle-pg12-3.0.2x64.zip
	powershell -command "& { iwr http://download.osgeo.org/postgis/windows/pg12/postgis-bundle-pg12-3.0.2x64.zip -OutFile postgis-bundle-pg12-3.0.2x64.zip }"

	PgAdmin III version 1.26b from https://vvs.ru/pg/index-en.html
	wget -nH -nd https://vvs.ru/pg/pgadmin3-1-26.msi
	powershell -command "& { iwr https://vvs.ru/pg/pgadmin3-1-26.msi -OutFile pgadmin3-1-26.msi }"

**unzip postgresql-12.4-1-windows-x64-binaries.zip

Fájlkezelővel másoljuk be/mozgassuk át a postgis-bundle-pg12-3.0.2x64.zip tartalmát *- a makepostgisdb_using_extensions.bat fájl kivételével -* a pgsql könyvtárba. (A már létező fájlokat írjuk felül.)

Nevezzük át a "pgsql" könyvtárat a verziószámnak megfelelő nélvre:

	rename pgsql 12.4-1-x64
	mkdir 12.4

Készítsünk egy batch fájlt, ami a szerver *(, illetve a kliens program)* indítása előtt beállít néhány környezezeti változót annak érdekében, hogy kevesebb paraméter megeadására legyen szükség:

**notepad pg_conf.bat

	set pgdrive=c:

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
	
**call pg_conf.bat

**%pgbin%\pg_ctl.exe init -D %pgdata%

	The files belonging to this database system will be owned by user "%USERNAME%".
	This user must also own the server process.

	The database cluster will be initialized with locale "Hungarian_Hungary.1250".
	The default database encoding has accordingly been set to "WIN1250".
	The default text search configuration will be set to "hungarian".

	Data page checksums are disabled.

	fixing permissions on existing directory c:/PostgreSQL/12.4 ... ok
	creating subdirectories ... ok
	selecting dynamic shared memory implementation ... windows
	selecting default max_connections ... 100
	selecting default shared_buffers ... 128MB
	selecting default time zone ... GMT
	creating configuration files ... ok
	running bootstrap script ... ok
	performing post-bootstrap initialization ... ok
	syncing data to disk ... ok

	initdb: warning: enabling "trust" authentication for local connections
	You can change this by editing pg_hba.conf or using the option -A, or
	--auth-local and --auth-host, the next time you run initdb.

	Success. You can now start the database server using:

	    c:/PostgreSQL/12.4-1-x64/bin/pg_ctl -D c:/PostgreSQL/12.4 -l logfile start

**notepad %pgdata%\postgresql.conf

	listen_addresses = '*'
	password_encryption = md5
	log_timezone = 'Europe/Budapest'
	timezone = 'Europe/Budapest'

**notepad %pgdata%\pg_hba.conf

	host	all	all	<your_ip>/32	md5

rem %pgbin%\pg_ctl.exe start -D %pgdata% -l %pglogfile%

** notepad pg_start.bat

	@echo off

	chcp 1250

	if exist pg_conf.bat call pg_conf.bat

	TITLE PostgreSQL indítása [%PGDATADIR%] (%date% %time%)

	rem runas /user:%USERNAME% "%PGDIR%\bin\pg_ctl.exe start -U %USERNAME% -w -D %PGDATADIR% -l %PGLOGFILE%"
	%PGBIN%\pg_ctl.exe start -D %PGDATADIR% -l %PGLOGFILE%

	if not errorlevel 0 pause

	rem EXIT

** notepad pg_stop.bat

	@echo off

	chcp 1250

	if exist pg_conf.bat call.bat pg_conf.bat

	TITLE PostgreSQL leállítása [%PGDATADIR%] (%date% %time%)

	%PGBIN%\pg_ctl.exe stop -D %PGDATADIR%

	if not errorlevel 0 pause

	rem EXIT

**call pg_start.bat

Ha a *postgresql.conf*-ban beállítottuk a *listen_addresses = '*'* paramétert, akkor nem csak a helyi gépről, hanem a helyi hálózaton bármely gépről elérhető a szerver *(a *pg_hba.conf* fájl további beállításaitól függően). Ez esetben a Windows Tűzfal jelezni fogja, hogy új szolgáltatás indul, így az "Elérés engedélyezése (az alapértelmezett hálózatokon)" lehetőséget kell választani.

**%pgbin%\psql -U %username% -d postgres -c "select version()"

				version
	------------------------------------------------------------
	 PostgreSQL 12.4, compiled by Visual C++ build 1914, 64-bit
	(1 row)
Ha értelmezhető a verziószám, akkor elkészült egy csupasz adatbázis klaszter, benne egy alapértelmezett 'postgres' nevű adatbázissal.
Az eljárás szépséghibája, hogy ez az alapértelmezett adatbázis jelenleg az aktuális Windows felhasználó, azaz a %USERNAME% tulajdonában van, miközben számos alapértelmezés a 'postgres' felhasználó meglétére számít, mint adatbázis adminisztrátor. Ezt korrigáljuk is:

**%pgbin%\psql -U %username% -d postgres -c "CREATE ROLE postgres LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION"

**%pgbin%\psql -U %username% -d postgres -c "ALTER DATABASE postgres OWNER TO postgres"

rem PostGIS hozzáadása egy adatbázishoz

Hozzunk létre egy új adatbázist, melyhez hozzáadjuk a PostGIS kiterjesztést is *(Ha nagybetűt szeretnénk használni, akkor a parancssorban a nevet idézőjelbe kell tenni!)*:

**%pgbin%\psql -c "CREATE DATABASE \"%pgdb%\""
**%pgbin%\psql -d "%pgdb%" -c "CREATE EXTENSION postgis"
**%pgbin%\psql -d "%pgdb%" -c "select postgis_full_version()"

											   postgis_full_version
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	 POSTGIS="3.0.2 3.0.2" [EXTENSION] PGSQL="120" GEOS="3.8.1-CAPI-1.13.3" PROJ="Rel. 5.2.0, September 15th, 2018" LIBXML="2.9.9" LIBJSON="0.12" LIBPROTOBUF="1.2.1" WAGYU="0.4.3 (Internal)"
	(1 row)
Ha értelmezhető a verziószám, akkor elkészült a munkára kész adatbázis.


+ Telepítsünk fel egy igen jó segédeszközt: pgadmin3-1-26.msi


+ Ha szolgáltatásként szeretnénk használni az adatbáziskezelőt és nem batch fájlokkal indítani, akkor:

	runas /noprofile /user:Rendszergazda cmd.exe
	call pg_conf.bat 
	d:\PostgreSQL>%pgbin%\pg_ctl.exe register -D %pgdata% -N PostgreSQL
	d:\PostgreSQL>%pgbin%\pg_ctl.exe unregister -D %pgdata% -N PostgreSQL
