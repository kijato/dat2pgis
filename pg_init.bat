 
call pg_conf.bat

rem NET USER %pguser% /DEL
rem NET USER %pguser% * /ADD /ACTIVE:yes /FULLNAME:"PostgreSQL User" /COMMENT:"PostgreSQL Database Administrator"

rem if not defined pgencoding
	%pgbin%\initdb -U %pguser% -D %pgdata%
rem ) else (
rem 	%pgbin%\initdb -E %pgencoding% -U %pguser% -D %pgdata%
rem )

%PERLBIN%\perl -i%EXT% -p -e "s/^#?(checkpoint_segments)\s*=\s*\d+/$1=16/;s/^#?(password_encryption)\s*=\s*\w+/$1=on/" %pgdata%\postgresql.conf
