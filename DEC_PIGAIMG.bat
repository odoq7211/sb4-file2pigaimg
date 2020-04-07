@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
set pigaimg_path=%~1
php DEC_PIGAIMG.php
echo;
pause
endlocal
