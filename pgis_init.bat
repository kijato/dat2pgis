
call pg_conf.bat

set pgis=postgis-bundle-pg94x32-2.1.7

if not exist %pghome%\share\extension\postgis.control (
	if exist %pgis%\makepostgisdb_using_extensions.bat (
		cd %pgis%
		notepad makepostgisdb_using_extensions.bat
		call makepostgisdb_using_extensions.bat
		cd ..
	) else (
		goto NINCSPOSTGIS
	)
)

%pgbin%\createdb -h %pghost% -p %pgport% -U %pguser% %pgdb%
rem %pgbin%\createdb -h %pghost% -p %pgport% -U %pguser% -E %pgencoding% %pgdb%

%pgbin%\psql -d %pgdb% -c "CREATE EXTENSION postgis;"
%pgbin%\psql -d %pgdb% -c "CREATE EXTENSION postgis_topology;"
rem %pgbin%\psql -d %pgdb% -c "CREATE EXTENSION fuzzystrmatch;"
rem %pgbin%\psql -d %pgdb% -c "CREATE EXTENSION postgis_tiger_geocoder;"
rem %pgbin%\psql -d %pgdb% -c "CREATE EXTENSION address_standardizer;"
goto KILEPES

:NINCSPOSTGIS
echo ˙
echo Nincs telepítve a PostGIS és nem tudom telepíteni...
echo Ellenőrizd a beállításokat és telepítsd fel/újra!
pause

:KILEPES
