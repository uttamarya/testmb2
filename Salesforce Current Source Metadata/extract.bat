@echo off
REM -------------------------------------------------------
REM  Salesforce Metadata Extractor - Windows launcher
REM  Double-click this file or run it from a command prompt.
REM -------------------------------------------------------

cd /d "%~dp0"

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python is not installed or not on PATH.
    echo Install Python from https://www.python.org/downloads/
    pause
    exit /b 1
)

where sf >nul 2>nul
if %errorlevel% neq 0 (
    echo Salesforce CLI (sf) is not installed or not on PATH.
    echo Install it from https://developer.salesforce.com/tools/salesforcecli
    pause
    exit /b 1
)

pip install -r requirements.txt -q 2>nul

python extract_metadata.py
if %errorlevel% neq 0 (
    echo.
    echo Script exited with an error.
)

pause
