@echo off
setlocal enabledelayedexpansion

REM Home Assistant Configuration Management - Windows Setup Script
REM This script sets up everything you need to get started

echo 🏠 Home Assistant Configuration Management - Windows Setup
echo ====================================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH.
    echo.
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)

REM Check Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python %PYTHON_VERSION% found

REM Check if git is available
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git is not installed or not in PATH.
    echo.
    echo Please install Git from https://git-scm.com/download/win
    echo Git Bash includes make command which is needed for this project.
    echo.
    pause
    exit /b 1
)

echo ✅ Git found

REM Check if make is available (usually comes with Git Bash)
make --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Make is not available.
    echo.
    echo Recommended solutions:
    echo 1. Use Git Bash (comes with Git for Windows) - RECOMMENDED
    echo 2. Install WSL (Windows Subsystem for Linux)
    echo 3. Install make via Chocolatey: choco install make
    echo 4. Install MinGW-w64
    echo.
    echo For the easiest experience, please use Git Bash to run commands.
    echo.
    pause
    exit /b 1
)

echo ✅ Make found

echo.
echo 🐍 Setting up Python environment...

REM Create virtual environment
if not exist "venv" (
    echo Creating Python virtual environment...
    python -m venv venv
) else (
    echo Virtual environment already exists
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo Installing Python dependencies...
pip install homeassistant voluptuous pyyaml jsonschema requests

echo.
echo 🔧 Checking project setup...

REM Check if Makefile exists
if not exist "Makefile" (
    echo ❌ Makefile not found. Are you in the correct directory?
    pause
    exit /b 1
)

echo ✅ Makefile found

REM Check if Claude Code is available
claude --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Claude Code not found - installing...
    echo Downloading Claude Code installer...
    
    REM Download Claude Code for Windows
    powershell -Command "Invoke-WebRequest -Uri 'https://claude.ai/download/windows' -OutFile '%TEMP%\claude-code-setup.exe'"
    
    if exist "%TEMP%\claude-code-setup.exe" (
        echo Opening Claude Code installer...
        start "%TEMP%\claude-code-setup.exe"
        echo.
        echo 📱 Please complete the Claude Code installation:
        echo 1. Follow the installation wizard
        echo 2. Complete the setup process
        echo 3. Re-run this script after installation: setup-windows.bat
        echo.
        echo Claude Code will help you manage your Home Assistant configuration easily!
        pause
        exit /b 0
    ) else (
        echo ❌ Failed to download Claude Code installer
        echo Please download manually from: https://claude.ai/download
        echo Then re-run this script
        pause
        exit /b 1
    )
) else (
    echo ✅ Claude Code found
)

echo.
echo 🎉 Setup Complete!
echo ==================
echo.
echo Next steps:
echo 1. Configure your Home Assistant connection in the Makefile:
echo    - Edit the HA_HOST variable with your Home Assistant hostname/IP
echo    - Set up SSH key authentication to your HA instance
echo.
echo 2. Pull your actual configuration:
echo    make pull
echo.
echo 3. Start creating automations with Claude Code!
echo.
echo IMPORTANT: Use Git Bash or WSL to run make commands if you encounter issues
echo with the regular Windows Command Prompt.
echo.
echo For detailed instructions, see the README.md file.
echo.
echo Need help? Check the troubleshooting section in README.md
echo or create an issue at: https://github.com/philippb/claude-homeassistant/issues
echo.
pause