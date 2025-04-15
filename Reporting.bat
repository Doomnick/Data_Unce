@echo off

REM Zjisti cestu k aktualni slozce, kde je umisten tento .bat soubor
set "SCRIPT_DIR=%~dp0"

REM Nastav cestu k Rscript.exe (s uvozovkami pro pripadne mezery)
set "R_PATH=C:\Program Files\R\R-4.4.3\bin\Rscript.exe"

REM Nastav cestu k uzivatelske knihovne R (pokud by byla potreba)
REM set "R_LIBS_USER=%USERPROFILE%\AppData\Local\R\win-library\%R_VERSION%"

REM Zkontroluj, jestli Rscript.exe existuje
if not exist "%R_PATH%" (
    echo Rscript.exe nebyl nalezen na "%R_PATH%"
    pause
    exit /b 1
)

echo Spoustim aktualizacni skript...
"%R_PATH%" "%SCRIPT_DIR%aktualizace_skriptu.R"
if errorlevel 1 (
    echo Chyba pri spousteni aktualizace skriptu.
    goto end
)

echo Aktualizace dokoncena.

echo Spoustim hlavni skript...
"%R_PATH%" "%SCRIPT_DIR%spusteni.R"
if errorlevel 1 (
    echo Chyba pri spousteni hlavniho skriptu.
    goto end
)

echo Hlavni skript dokonceny.

:end
echo.
echo -------------------------------
echo Hotovo. Zkontroluj vystupy vyse.
echo Stiskni libovolnou klavesu pro ukonceni.
pause >nul