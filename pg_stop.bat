@echo off

chcp 1250

if exist pg_conf.bat call pg_conf.bat

TITLE PostgreSQL leállítása [%PGDATADIR%] (%date% %time%)

%PGBIN%\pg_ctl.exe stop -D %PGDATADIR%

if not errorlevel 0 pause

rem EXIT
