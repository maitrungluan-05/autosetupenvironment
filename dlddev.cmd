@echo off
setlocal
powershell.exe -NoProfile -File "%~dp0devsetup.ps1" %*
exit /b %ERRORLEVEL%
