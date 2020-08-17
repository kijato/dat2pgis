
call pg_conf.bat

%pgbin%\psql -d %pgdb% -f datr_sablon.sql

%pgbin%\psql -d "%pgdb%" -c "GRANT CONNECT ON DATABASE \"%pgdb%\" TO public"

%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT SELECT ON TABLES TO public"
%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT USAGE ON SEQUENCES TO public"
%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT EXECUTE ON FUNCTIONS TO public"
%pgbin%\psql -d "%pgdb%" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT USAGE ON TYPES TO public"
 
 
 Probléma: tables declared WITH OIDS are not supported
 