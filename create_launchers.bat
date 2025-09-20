@echo off
setlocal enabledelayedexpansion

REM Base directories
set "BASE_DIR=%~dp0"
set "PROGRAMS_DIR=%BASE_DIR%Programs"
set "GLOBAL_CONFIG=..\Configuration\dosbox.conf"
set "DOSBOX_CMD=..\Configuration\DosBox\dosbox.exe"

echo === DOSBox Launcher Generator ===
echo Base directory: %BASE_DIR%
echo Programs directory: %PROGRAMS_DIR%
echo Using DOSBox: %DOSBOX_CMD%
echo.

REM Iterate program folders
for /D %%F in ("%PROGRAMS_DIR%\*") do (
    set "PROG=%%~nxF"
    echo Processing program folder: !PROG!

    REM Find the first EXE (or largest if you prefer)
    set "EXE="
    for /F "delims=" %%E in ('dir /B /O-S "%%F\*.exe" 2^>nul') do (
        set "EXE=%%E"
        goto FoundEXE
    )
    echo   No .EXE found in !PROG!, skipping.
    echo.
    goto ContinueLoop

:FoundEXE
    echo   Detected main EXE: !EXE!

    REM Use local dosbox.conf if exists
    if exist "%%F\dosbox.conf" (
        set "CONFIG=dosbox.conf"
        echo   Using local config: !CONFIG!
    ) else (
        set "CONFIG=%GLOBAL_CONFIG%"
        echo   Using global config: !CONFIG!
    )

    REM Create launcher .bat
    set "LAUNCHER=%BASE_DIR%start_!PROG!.bat"
    (
        echo @echo off
        echo cd /d "%%~dp0Programs\!PROG!"
        echo "!DOSBOX_CMD!" "!EXE!" -conf "!CONFIG!" -fullscreen -exit
    ) > "!LAUNCHER!"
    echo   Created launcher: !LAUNCHER!
    echo.

:ContinueLoop
)

echo === Launcher generation complete ===
endlocal

