#!/bin/bash

# Home Assistant Configuration Management - Mac Setup Script
# This script sets up everything you need to get started

set -e  # Exit on any error

echo "🏠 Home Assistant Configuration Management - Mac Setup"
echo "=================================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is for macOS only. Please use setup-windows.bat for Windows."
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "🔍 Checking prerequisites..."

# Check if Python 3.8+ is available
if ! command_exists python3; then
    echo "❌ Python 3 is not installed."
    echo "Please install Python from https://www.python.org/downloads/"
    echo "Or use Homebrew: brew install python3"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.8"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
    echo "❌ Python $PYTHON_VERSION found, but Python 3.8+ is required."
    echo "Please upgrade Python from https://www.python.org/downloads/"
    exit 1
fi

echo "✅ Python $PYTHON_VERSION found"

# Check if git is available
if ! command_exists git; then
    echo "❌ Git is not installed."
    echo "Installing Command Line Tools (includes git)..."
    xcode-select --install
    echo "Please run this script again after installation completes."
    exit 1
fi

echo "✅ Git found"

# Check if make is available
if ! command_exists make; then
    echo "❌ Make is not installed."
    echo "Installing Command Line Tools (includes make)..."
    xcode-select --install
    echo "Please run this script again after installation completes."
    exit 1
fi

echo "✅ Make found"

# Check if ssh is available
if ! command_exists ssh; then
    echo "❌ SSH is not available. This is unusual for macOS."
    exit 1
fi

echo "✅ SSH found"

echo ""
echo "🐍 Setting up Python environment..."

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
else
    echo "Virtual environment already exists"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing Python dependencies..."
pip install homeassistant voluptuous pyyaml jsonschema requests

echo ""
echo "🔧 Checking project setup..."

# Check if Makefile exists
if [ ! -f "Makefile" ]; then
    echo "❌ Makefile not found. Are you in the correct directory?"
    exit 1
fi

echo "✅ Makefile found"

# Check if Claude Code is available
if command_exists claude; then
    echo "✅ Claude Code found"
else
    echo "⚠️  Claude Code not found - installing..."
    echo "Downloading Claude Code installer..."
    
    # Download Claude Code for Mac
    curl -L -o /tmp/claude-code.dmg "https://claude.ai/download/macos"
    
    if [ $? -eq 0 ]; then
        echo "Opening Claude Code installer..."
        open /tmp/claude-code.dmg
        echo ""
        echo "📱 Please complete the Claude Code installation:"
        echo "1. Install Claude Code from the opened disk image"
        echo "2. Follow the setup wizard"
        echo "3. Re-run this script after installation: ./setup-mac.sh"
        echo ""
        echo "Claude Code will help you manage your Home Assistant configuration easily!"
        exit 0
    else
        echo "❌ Failed to download Claude Code installer"
        echo "Please download manually from: https://claude.ai/download"
        echo "Then re-run this script"
        exit 1
    fi
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Configure your Home Assistant connection in the Makefile:"
echo "   - Edit the HA_HOST variable with your Home Assistant hostname/IP"
echo "   - Set up SSH key authentication to your HA instance"
echo ""
echo "2. Pull your actual configuration:"
echo "   make pull"
echo ""
echo "3. Start creating automations with Claude Code!"
echo ""
echo "For detailed instructions, see the README.md file."
echo ""
echo "Need help? Check the troubleshooting section in README.md"
echo "or create an issue at: https://github.com/philippb/claude-homeassistant/issues"