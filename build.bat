@echo off
rem call lime rebuild . windows -debug
rem call lime rebuild . windows -clean

call lime rebuild . flash -clean
call lime rebuild . windows -clean
call lime rebuild . android -clean

pause