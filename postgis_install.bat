
call pg_conf.bat

set PGADMIN="%pghome%\pgAdmin III"
mkdir %pgadmin%
set PGLIB=%pghome%\lib\

xcopy /d bin\*.* "%PGBIN%"
xcopy /d /I /S bin\postgisgui\* "%PGBIN%\postgisgui"
xcopy /d /I plugins.d\* "%PGADMIN%\plugins.d"
xcopy /d lib\*.* "%PGLIB%"
xcopy /d share\extension\*.* "%pghome%\share\extension"
xcopy /d /I /S share\contrib\*.* "%pghome%\share\contrib"
xcopy /d /I gdal-data "%pghome%\gdal-data"

rem pause
