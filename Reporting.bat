@echo off

REM Zjisti cestu k aktuální složce, kde je umístěn tento .bat soubor
set SCRIPT_DIR=%~dp0

REM Dynamicky nastavíme cestu k Rscript.exe (s uvozovkami pro cesty obsahující mezery)
set "R_PATH=C:\Program Files\R\R-4.4.3\bin\Rscript.exe"

REM Dynamicky nastavíme cestu k uživatelské knihovně R
set "R_LIBS_USER=%USERPROFILE%\AppData\Local\R\win-library\%R_VERSION%"

REM Zobrazíme cesty pro kontrolu
echo Rscript path: %R_PATH%
echo User library path: %R_LIBS_USER%
echo Script path: %SCRIPT_DIR%

REM Zkontrolujeme, zda existuje Rscript.exe
if not exist "%R_PATH%" (
    echo Rscript.exe not found at "%R_PATH%"
    exit /b 1
)

REM Spustíme R skript (R skript je ve stejné složce jako .bat soubor)
"%R_PATH%" "%SCRIPT_DIR%aktualizace_skriptu.R"
"%R_PATH%" "%SCRIPT_DIR%spusteni.R"