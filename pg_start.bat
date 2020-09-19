@echo off

chcp 1250

if exist pg_conf.bat call pg_conf.bat

TITLE PostgreSQL indítása [%PGDATADIR%] (%date% %time%)

rem runas /user:%USERNAME% "%PGDIR%\bin\pg_ctl.exe start -U %USERNAME% -w -D %PGDATADIR% -l %PGLOGFILE%"
%PGBIN%\pg_ctl.exe start -D %PGDATADIR% -l %PGLOGFILE%

if not errorlevel 0 pause

rem EXIT
