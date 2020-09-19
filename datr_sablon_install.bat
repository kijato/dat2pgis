
call pg_conf.bat

%pgbin%\psql -d %pgdb% -c "DROP SCHEMA datr_sablon CASCADE"

%pgbin%\psql -d %pgdb% -f datr_sablon_mini.sql

%pgbin%\psql -d "%pgdb%" -c "GRANT CONNECT ON DATABASE \"%pgdb%\" TO public"

%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT SELECT ON TABLES TO public"
%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT USAGE ON SEQUENCES TO public"
%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT EXECUTE ON FUNCTIONS TO public"
%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT USAGE ON TYPES TO public"
 

echo  Probléma: tables declared WITH OIDS are not supported

echo You can print the errors and standard output to a single file by using the "&1" command to redirect the output for STDERR to STDOUT and then sending the output from STDOUT to a file:
rem echo dir file.xxx 1> output.msg 2>&1
echo ˙
echo c:\PostgreSQL>datr_sablon_install.bat 1> datr_sablon_install.log 2>&1