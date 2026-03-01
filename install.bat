@echo off
setlocal EnableDelayedExpansion
title MedRecords AI - Installer
color 0F

echo.
echo  ================================================================
echo    MedRecords AI - One-Click Installer
echo    HIPAA-Compliant Medical Record Summarization
echo  ================================================================
echo.

set "INSTALL_DIR=%USERPROFILE%\MedRecordsAI"
set "ZIP_URL=https://aiproductivity.dev/dist/MedRecordsAI-DEMO-v2.2.0.zip"
set "ZIP_FILE=%TEMP%\MedRecordsAI-DEMO.zip"

:: ── Step 1: Check Python ────────────────────────────────────────────
echo  [1/4] Checking for Python...
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ----------------------------------------------------------------
    echo    Python is required but was not found on this computer.
    echo  ----------------------------------------------------------------
    echo.
    echo  Opening the Python download page now...
    echo.
    echo  IMPORTANT: During Python installation, make sure to check
    echo  the box that says "Add Python to PATH" at the bottom of
    echo  the first screen. Then click "Install Now."
    echo.
    echo  After Python is installed, run this installer again.
    echo.
    start https://www.python.org/downloads/
    pause
    exit /b 1
)
for /f "tokens=2" %%V in ('python --version 2^>^&1') do set "PY_VER=%%V"
echo        Python %PY_VER% found.
echo.

:: ── Step 2: Download ────────────────────────────────────────────────
echo  [2/4] Downloading MedRecords AI...
echo        This may take a minute depending on your connection.
echo.

:: Use PowerShell to download with progress
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ProgressPreference = 'SilentlyContinue'; " ^
  "try { " ^
  "  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
  "  Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing; " ^
  "  Write-Host '        Download complete.' " ^
  "} catch { " ^
  "  Write-Host '  [ERROR] Download failed:' $_.Exception.Message; " ^
  "  exit 1 " ^
  "}" 2>nul

if not exist "%ZIP_FILE%" (
    echo.
    echo  [ERROR] Download failed. Please check your internet connection
    echo  and try again. If the problem persists, download manually from:
    echo  https://aiproductivity.dev
    echo.
    pause
    exit /b 1
)
echo.

:: ── Step 3: Extract ─────────────────────────────────────────────────
echo  [3/4] Installing to %INSTALL_DIR%...

:: Clean previous installation if exists
if exist "%INSTALL_DIR%" (
    echo        Removing previous installation...
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)

:: Extract
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Expand-Archive -LiteralPath '%ZIP_FILE%' -DestinationPath '%INSTALL_DIR%' -Force" 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo  [ERROR] Extraction failed. Please try again or download the
    echo  ZIP manually from https://aiproductivity.dev
    echo.
    pause
    exit /b 1
)

:: Clean up temp ZIP
del "%ZIP_FILE%" 2>nul

echo        Installed successfully.
echo.

:: ── Step 4: Launch ──────────────────────────────────────────────────
echo  [4/4] Launching MedRecords AI setup wizard...
echo.
echo  ================================================================
echo    A browser window will open with the setup wizard.
echo    Follow the steps to complete installation.
echo  ================================================================
echo.

:: Find and launch MedRecordsAI.bat (might be in root or subfolder)
if exist "%INSTALL_DIR%\MedRecordsAI.bat" (
    start "" "%INSTALL_DIR%\MedRecordsAI.bat"
    goto :done
)

:: Check if ZIP had a top-level folder
for /d %%D in ("%INSTALL_DIR%\*") do (
    if exist "%%D\MedRecordsAI.bat" (
        start "" "%%D\MedRecordsAI.bat"
        goto :done
    )
)

echo  [ERROR] Installation files not found. Please try again.
pause
exit /b 1

:done
echo  MedRecords AI is launching in a new window.
echo  You can close this installer window.
echo.
timeout /t 8 >nul
