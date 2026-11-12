@echo off
setlocal
cd /d "%~dp0"

set "MANIFEST_FX=extension\lua\joypad-assist\gamepad_tweaks\manifest.ini"
set "MANIFEST_UI=apps\lua\gamepad_tweaks\manifest.ini"

if not exist "%MANIFEST_FX%" (
    echo ERROR: script manifest not found: %MANIFEST_FX%
    exit /b 1
)
if not exist "%MANIFEST_UI%" (
    echo ERROR: app manifest not found: %MANIFEST_UI%
    exit /b 1
)

for /f "tokens=1,* delims==" %%A in ('findstr /b /c:"VERSION" "%MANIFEST_FX%"') do set "VER_FX=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr /b /c:"VERSION" "%MANIFEST_UI%"') do set "VER_UI=%%B"
set "VER_FX=%VER_FX: =%"
set "VER_UI=%VER_UI: =%"

if "%VER_FX%"=="" (
    echo ERROR: VERSION not found in %MANIFEST_FX%
    exit /b 1
)
if "%VER_UI%"=="" (
    echo ERROR: VERSION not found in %MANIFEST_UI%
    exit /b 1
)
if not "%VER_FX%"=="%VER_UI%" (
    echo ERROR: version mismatch - script %VER_FX% vs app %VER_UI%
    exit /b 1
)

if not exist "dist" mkdir "dist"
set "ZIP_PATH=dist\gamepad-tweaks-v%VER_FX%.zip"
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%"

echo Creating %ZIP_PATH%...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$paths = @('README.md', 'assets', 'apps', 'extension');" ^
    "Compress-Archive -Path $paths -DestinationPath '%ZIP_PATH%' -CompressionLevel Optimal"
if errorlevel 1 (
    echo ERROR: failed to create package.
    exit /b 1
)

echo.
echo Package created successfully:
echo %CD%\%ZIP_PATH%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName System.IO.Compression.FileSystem;" ^
    "$archive = [System.IO.Compression.ZipFile]::OpenRead('%ZIP_PATH%');" ^
    "$archive.Entries | ForEach-Object { $_.FullName };" ^
    "$archive.Dispose()"

endlocal
