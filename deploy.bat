@echo off
setlocal

set "REPO=D:\code\HallConfig-gamepadfx"
set "AC=D:\SteamLibrary\steamapps\common\assettocorsa"

set "SRC_SCRIPT=%REPO%\extension\lua\joypad-assist\hall_config"
set "DST_SCRIPT=%AC%\extension\lua\joypad-assist\hall_config"

set "SRC_UI=%REPO%\apps\lua\hall_config_ui"
set "DST_UI=%AC%\apps\lua\hall_config_ui"

echo ===============================================
echo   hall_config - Deploy to Assetto Corsa
echo ===============================================
echo Repo:   %REPO%
echo Target: %AC%
echo.

REM --- Gamepad FX script (Fase 0-2) ---
if exist "%DST_SCRIPT%" (
    echo [1/2] Removing old deployed script...
    rmdir /s /q "%DST_SCRIPT%"
) else (
    echo [1/2] No previous deployed script found, skip removal.
)

if exist "%SRC_SCRIPT%" (
    echo       Deploying script -^> %DST_SCRIPT%
    xcopy "%SRC_SCRIPT%" "%DST_SCRIPT%\" /E /I /Y >nul
    echo       Done.
) else (
    echo       SKIP: source not found at %SRC_SCRIPT%
)

echo.

REM --- In-game UI app (Fase 3, mungkin belum ada) ---
if exist "%DST_UI%" (
    echo [2/2] Removing old deployed UI app...
    rmdir /s /q "%DST_UI%"
) else (
    echo [2/2] No previous deployed UI app found, skip removal.
)

if exist "%SRC_UI%" (
    echo       Deploying UI app -^> %DST_UI%
    xcopy "%SRC_UI%" "%DST_UI%\" /E /I /Y >nul
    echo       Done.
) else (
    echo       SKIP: source not found yet at %SRC_UI% ^(normal sebelum Fase 3^)
)

echo.
echo ===============================================
echo   Deploy selesai.
echo ===============================================
pause