@echo off
REM Batch file wrapper for Extract-FileVersionsFromGit.ps1
REM This allows users to run the PowerShell script easily without worrying about execution policies

setlocal

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell script exists
if not exist "%SCRIPT_DIR%Extract-FileVersionsFromGit.ps1" (
    echo Error: Extract-FileVersionsFromGit.ps1 not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

REM Run the PowerShell script with execution policy bypass
echo Running Git File Version Extractor...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Extract-FileVersionsFromGit.ps1" %*

REM Pause so user can see results
echo.
echo Press any key to continue...
pause >nul