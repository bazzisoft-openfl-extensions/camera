@echo off
call lime rebuild . windows -debug %*
call lime rebuild . windows %*
call lime rebuild . android -debug %*
call lime rebuild . android %*
pause