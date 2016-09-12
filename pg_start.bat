
call pg_conf.bat

%pgbin%\pg_ctl.exe start -D %pgdata% -l %pglog%
