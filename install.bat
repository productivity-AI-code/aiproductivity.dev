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
set "ZIP_URL=https://aiproductivity.dev/dist/MedRecordsAI-DEMO-v2.2.22.zip"
set "ZIP_FILE=%TEMP%\MedRecordsAI-DEMO.zip"

:: ── Step 1: Check / Install Python ─────────────────────────────────
echo  [1/4] Checking for Python...

set "PYTHON_CMD="
python --version >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set "PYTHON_CMD=python"
    goto :python_ready
)
py --version >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set "PYTHON_CMD=py"
    goto :python_ready
)

:: Python not found — offer auto-install
echo.
echo  Python is required but was not found on this system.
echo.
choice /C YN /M "  Install Python automatically"
if !ERRORLEVEL! EQU 2 goto :manual_python

echo.
:: Try winget first
winget --version >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo        Installing Python via winget ^(this may take a few minutes^)...
    winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --scope user
    if !ERRORLEVEL! EQU 0 goto :python_installed
    echo        winget did not succeed, trying direct download...
)

:: Fallback: download from python.org
echo        Downloading Python from python.org...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe' -OutFile '%TEMP%\python-installer.exe'"

if not exist "%TEMP%\python-installer.exe" (
    echo  [ERROR] Download failed.
    goto :manual_python
)

echo        Installing Python ^(this may take a minute^)...
"%TEMP%\python-installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_launcher=1
del /q "%TEMP%\python-installer.exe" 2>nul

:python_installed
:: Refresh PATH from registry
for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "PATH=%%B;!PATH!"
for %%D in ("%LOCALAPPDATA%\Programs\Python\Python312" "%LOCALAPPDATA%\Programs\Python\Python311" "%LOCALAPPDATA%\Programs\Python\Python310") do (
    if exist "%%~D\python.exe" set "PATH=%%~D;%%~D\Scripts;!PATH!"
)

python --version >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set "PYTHON_CMD=python"
    echo        Python installed successfully.
    goto :python_ready
)
py --version >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set "PYTHON_CMD=py"
    echo        Python installed successfully.
    goto :python_ready
)

echo.
echo  [ERROR] Could not verify Python after installation.
echo          Please close this window, then run the installer again.
echo.
pause
exit /b 1

:manual_python
echo.
echo  Please install Python 3.10+ from https://python.org
echo  Make sure "Add Python to PATH" is checked during install.
echo  Then run this installer again.
echo.
pause
exit /b 1

:python_ready
for /f "tokens=2" %%V in ('!PYTHON_CMD! --version 2^>^&1') do set "PY_VER=%%V"
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
    echo        Stopping any running MedRecords AI processes...
    :: Kill Python processes running from the install dir
    powershell -NoProfile -Command "Get-Process python*, py* -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*MedRecordsAI*' -or $_.Path -like '*%INSTALL_DIR:\=\\%*' } | Stop-Process -Force -ErrorAction SilentlyContinue" 2>nul
    :: Also kill any process holding port 8080 or 9876
    for /f "tokens=5" %%P in ('netstat -aon 2^>nul ^| findstr ":8080 :9876" ^| findstr "LISTENING"') do (
        taskkill /PID %%P /F >nul 2>&1
    )
    timeout /t 2 >nul
    echo        Removing previous installation...
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)

:: If directory still exists (locked files), use a fallback location
if exist "%INSTALL_DIR%" (
    echo        Previous installation could not be fully removed.
    echo        Installing to a new folder instead...
    set "INSTALL_DIR=%USERPROFILE%\MedRecordsAI_new"
    if exist "!INSTALL_DIR!" rmdir /s /q "!INSTALL_DIR!" 2>nul
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
