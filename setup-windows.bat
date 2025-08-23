@echo off
setlocal enabledelayedexpansion

REM Home Assistant Configuration Management - Windows Setup Script
REM This script sets up everything you need to get started

echo Home Assistant Configuration Management - Windows Setup
echo =======================================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    echo.
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)

REM Check Python version
for /f "tokens=2 delims= " %%i in ('python --version 2^>nul') do set PYTHON_VERSION=%%i
if "%PYTHON_VERSION%"=="" (
    set PYTHON_VERSION=Unknown
)
echo [OK] Python %PYTHON_VERSION% found

REM Check if git is available
where git >nul 2>&1
if errorlevel 1 (
    REM Try common Git installation paths
    if exist "C:\Program Files\Git\cmd\git.exe" (
        set PATH=%PATH%;C:\Program Files\Git\cmd
        echo [OK] Git found in C:\Program Files\Git\cmd
    ) else if exist "C:\Program Files (x86)\Git\cmd\git.exe" (
        set PATH=%PATH%;C:\Program Files (x86)\Git\cmd
        echo [OK] Git found in C:\Program Files (x86)\Git\cmd
    ) else (
        echo [ERROR] Git is not installed or not in PATH.
        echo.
        echo Please install Git from https://git-scm.com/download/win
        echo Git Bash includes make command which is needed for this project.
        echo.
        pause
        exit /b 1
    )
) else (
    echo [OK] Git found
)

REM Check if make is available (usually comes with Git Bash)
make --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Make is not available.
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

echo [OK] Make found

echo.
echo Setting up Python environment...

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
echo Checking project setup...

REM Check if Makefile exists
if not exist "Makefile" (
    echo [ERROR] Makefile not found. Are you in the correct directory?
    pause
    exit /b 1
)

echo [OK] Makefile found

REM Check if Claude Code is available
claude --version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Claude Code not found
    echo.
    echo Claude Code is required for this tool to work effectively.
    echo.
    echo To install Claude Code:
    echo 1. Visit: https://claude.ai/
    echo 2. Sign up for Claude Pro if you haven't already
    echo 3. Download the Claude desktop app for Windows
    echo 4. Install the downloaded file (usually named Claude-Setup-x64.exe)
    echo 5. Launch Claude and complete the setup
    echo.
    echo After installation:
    echo - Claude Code CLI should be available in your terminal
    echo - Re-run this script to continue: setup-windows.bat
    echo.
    echo Note: Claude Code provides AI-powered assistance for managing
    echo your Home Assistant configuration files safely and efficiently.
    echo.
    pause
    exit /b 0
) else (
    echo [OK] Claude Code found
)

echo.
echo Home Assistant Configuration
echo ===============================
echo.
echo Let's configure your Home Assistant connection!
echo.

REM Get Home Assistant host
:get_host
set /p HA_HOST="Enter your Home Assistant hostname or IP address (e.g., homeassistant.local or 192.168.1.100): "
if "%HA_HOST%"=="" (
    echo [ERROR] Hostname/IP cannot be empty
    goto get_host
)

echo.
echo Testing connection to %HA_HOST%...
ping -n 1 %HA_HOST% >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Cannot reach %HA_HOST% - please verify the address
    set /p continue_setup="Continue anyway? (y/N): "
    if /i not "!continue_setup!"=="y" (
        echo Setup cancelled. Please check your Home Assistant address and try again.
        pause
        exit /b 1
    )
) else (
    echo [OK] Host %HA_HOST% is reachable
)

echo.
echo SSH Configuration
echo ===================
echo.
echo For secure access, this tool uses SSH keys. Do you have SSH access configured?
echo.
echo Options:
echo 1. I already have SSH key access configured
echo 2. I need help setting up SSH keys
echo 3. Skip SSH setup for now (manual configuration later)
echo.
set /p ssh_option="Choose option (1-3): "

if "%ssh_option%"=="1" (
    echo.
    echo Testing SSH connection to %HA_HOST%...
    REM Test SSH connection (Windows doesn't have a direct equivalent to BatchMode, so we use timeout)
    ssh -o ConnectTimeout=5 %HA_HOST% exit >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] SSH connection failed
        echo Please check your SSH configuration and try again
        echo Common issues:
        echo - SSH keys not added to Home Assistant
        echo - Incorrect hostname/IP
        echo - SSH addon not enabled in Home Assistant
        set SSH_CONFIGURED=false
    ) else (
        echo [OK] SSH connection successful!
        set SSH_CONFIGURED=true
    )
) else if "%ssh_option%"=="2" (
    echo.
    echo SSH Setup Help
    echo =================
    echo.
    echo To set up SSH access to Home Assistant:
    echo.
    echo 1. Install the 'SSH ^& Web Terminal' add-on in Home Assistant
    echo 2. Generate an SSH key pair if you don't have one:
    echo    ssh-keygen -t ed25519 -C "your-email@example.com"
    echo.
    echo 3. Copy your public key to Home Assistant manually:
    echo    - Open your public key file: type %USERPROFILE%\.ssh\id_ed25519.pub
    echo    - Copy the content and add it to HA SSH addon authorized_keys
    echo.
    echo 4. Test the connection:
    echo    ssh root@%HA_HOST%
    echo.
    echo For detailed instructions, visit:
    echo https://github.com/home-assistant/addons/blob/master/ssh/DOCS.md
    echo.
    echo Note: On Windows, consider using Git Bash or WSL for easier SSH management.
    echo.
    set SSH_CONFIGURED=false
) else if "%ssh_option%"=="3" (
    echo.
    echo [INFO] Skipping SSH setup - you can configure this later
    set SSH_CONFIGURED=false
) else (
    echo Invalid option. Skipping SSH setup.
    set SSH_CONFIGURED=false
)

REM Update Makefile with the provided host
echo.
echo Updating Makefile configuration...
if exist "Makefile" (
    REM Create backup
    copy Makefile Makefile.backup >nul

    REM Update HA_HOST in Makefile (Windows batch doesn't have sed, so we use PowerShell)
    powershell -Command "(Get-Content Makefile) -replace '^HA_HOST = .*', 'HA_HOST = %HA_HOST%' | Set-Content Makefile"
    echo [OK] Makefile updated with HA_HOST = %HA_HOST%
) else (
    echo [ERROR] Makefile not found - you may need to configure manually
)

echo.
echo Setup Complete!
echo ==================
echo.
echo Configuration Summary:
echo - Home Assistant Host: %HA_HOST%
if "%SSH_CONFIGURED%"=="true" (
    echo - SSH Access: [OK] Configured and tested
) else (
    echo - SSH Access: [WARNING] Needs configuration
)
echo.
echo Next steps:
if "%SSH_CONFIGURED%"=="true" (
    echo 1. Pull your actual configuration:
    echo    make pull
    echo.
    echo 2. Start creating automations with Claude Code!
) else (
    echo 1. Complete SSH setup ^(see instructions above^)
    echo 2. Pull your actual configuration: make pull
    echo 3. Start creating automations with Claude Code!
)
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
