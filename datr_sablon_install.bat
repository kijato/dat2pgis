
call pg_conf.bat

rem %pgbin%\psql -U %pguser% -h %pghost% -p %pgport% -d %pgdb% -f fmo-datr_sablon.sql
%pgbin%\psql -U %pguser% -h %pghost% -p %pgport% -d %pgdb% -f datr_sablon.sql

rem group:
rem CREATE ROLE dat NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
rem user:
rem CREATE ROLE guest LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
rem GRANT dat TO guest;

rem GIS:
rem GRANT CONNECT, TEMPORARY ON DATABASE "GIS" TO public;
rem GRANT ALL ON DATABASE "GIS" TO postgres;
rem GRANT CONNECT, CREATE ON DATABASE "GIS" TO dat;

rem datr_sablon:
rem ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT SELECT ON TABLES TO dat;
rem ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT USAGE ON SEQUENCES TO dat;
rem ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT EXECUTE ON FUNCTIONS TO dat;
rem ALTER DEFAULT PRIVILEGES IN SCHEMA datr_sablon GRANT USAGE ON TYPES TO dat;
