@echo off
echo ===============================================
echo   Gamepad Tweaks - Uninstaller
echo ===============================================
echo.

set "AC_DIR=%~dp0"

if not exist "%AC_DIR%AssettoCorsa.exe" (
    echo ERROR: Please place this uninstall.bat file inside your main Assetto Corsa folder
    echo ^(where AssettoCorsa.exe is located^) and run it again.
    echo.
    pause
    exit /b
)

echo Found Assetto Corsa directory: %AC_DIR%
echo.
set /p "CONFIRM=Are you sure you want to completely remove Gamepad Tweaks? (Y/N): "
if /I "%CONFIRM%" neq "Y" (
    echo Uninstall cancelled.
    pause
    exit /b
)

echo.
set "SCRIPT_DIR=%AC_DIR%extension\lua\joypad-assist\gamepad_tweaks"
set "UI_DIR=%AC_DIR%apps\lua\gamepad_tweaks"

if exist "%SCRIPT_DIR%" (
    echo [-] Removing extension\lua\joypad-assist\gamepad_tweaks...
    rmdir /s /q "%SCRIPT_DIR%"
) else (
    echo [ ] Script folder already removed or missing.
)

if exist "%UI_DIR%" (
    echo [-] Removing apps\lua\gamepad_tweaks...
    rmdir /s /q "%UI_DIR%"
) else (
    echo [ ] UI folder already removed or missing.
)

echo.
echo Gamepad Tweaks has been successfully uninstalled.
pause
