@echo off
setlocal
echo [DEPRECATED] "devsetup" has been renamed to "dlddev". Please use "dlddev" in new scripts. 1>&2
call "%~dp0dlddev.cmd" %*
exit /b %ERRORLEVEL%
