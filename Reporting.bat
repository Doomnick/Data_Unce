@echo off
REM Set the path to Rscript.exe
set R_PATH="C:\Program Files\R\R-4.3.2\bin\Rscript.exe"

REM Set the path to the user library
set R_LIBS_USER=C:\Users\DKolinger\AppData\Local\R\win-library\4.3

REM Run the update script
echo Starting update...
%R_PATH% aktualizace_skriptu.R

REM Run the main script
echo Starting main script...
%R_PATH% spusteni.R

pause