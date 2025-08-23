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
echo ⚙️  Home Assistant Configuration
echo ===============================
echo.
echo Let's configure your Home Assistant connection!
echo.

REM Get Home Assistant host
:get_host
set /p HA_HOST="Enter your Home Assistant hostname or IP address (e.g., homeassistant.local or 192.168.1.100): "
if "%HA_HOST%"=="" (
    echo ❌ Hostname/IP cannot be empty
    goto get_host
)

echo.
echo Testing connection to %HA_HOST%...
ping -n 1 %HA_HOST% >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Warning: Cannot reach %HA_HOST% - please verify the address
    set /p continue_setup="Continue anyway? (y/N): "
    if /i not "!continue_setup!"=="y" (
        echo Setup cancelled. Please check your Home Assistant address and try again.
        pause
        exit /b 1
    )
) else (
    echo ✅ Host %HA_HOST% is reachable
)

echo.
echo 🔑 SSH Configuration
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
        echo ❌ SSH connection failed
        echo Please check your SSH configuration and try again
        echo Common issues:
        echo - SSH keys not added to Home Assistant
        echo - Incorrect hostname/IP
        echo - SSH addon not enabled in Home Assistant
        set SSH_CONFIGURED=false
    ) else (
        echo ✅ SSH connection successful!
        set SSH_CONFIGURED=true
    )
) else if "%ssh_option%"=="2" (
    echo.
    echo 📚 SSH Setup Help
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
    echo ⏭️  Skipping SSH setup - you can configure this later
    set SSH_CONFIGURED=false
) else (
    echo Invalid option. Skipping SSH setup.
    set SSH_CONFIGURED=false
)

REM Update Makefile with the provided host
echo.
echo 📝 Updating Makefile configuration...
if exist "Makefile" (
    REM Create backup
    copy Makefile Makefile.backup >nul

    REM Update HA_HOST in Makefile (Windows batch doesn't have sed, so we use PowerShell)
    powershell -Command "(Get-Content Makefile) -replace '^HA_HOST = .*', 'HA_HOST = %HA_HOST%' | Set-Content Makefile"
    echo ✅ Makefile updated with HA_HOST = %HA_HOST%
) else (
    echo ❌ Makefile not found - you may need to configure manually
)

echo.
echo 🎉 Setup Complete!
echo ==================
echo.
echo Configuration Summary:
echo - Home Assistant Host: %HA_HOST%
if "%SSH_CONFIGURED%"=="true" (
    echo - SSH Access: ✅ Configured and tested
) else (
    echo - SSH Access: ⚠️  Needs configuration
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
