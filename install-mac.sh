#!/bin/bash
# Copyright 2026 The Funkatorium (Falco & Rook Schäfer)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# MUSE SpeakEasy - Mac Installer
# Installs dependencies and configures Caps Lock voice input.
#
# Usage: bash install-mac.sh

set -e

SPEAKEASY_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "  MUSE SpeakEasy - Mac Setup"
echo "  =========================="
echo ""

# --- Check Python ---
PYTHON=""
for candidate in python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" &>/dev/null; then
        version=$("$candidate" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
        major=$(echo "$version" | cut -d. -f1)
        minor=$(echo "$version" | cut -d. -f2)
        if [ "$major" -ge 3 ] && [ "$minor" -ge 10 ]; then
            PYTHON="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    echo -e "${RED}Python 3.10+ not found.${NC}"
    echo "Install with: brew install python@3.12"
    echo "Or download from: https://www.python.org/downloads/"
    exit 1
fi
echo -e "${GREEN}Found Python:${NC} $($PYTHON --version)"

# --- Install Python dependencies ---
echo ""
echo "Installing Python dependencies..."
$PYTHON -m pip install --upgrade pip --quiet
$PYTHON -m pip install \
    -r "$SPEAKEASY_DIR/requirements.txt" \
    --require-hashes \
    --quiet
echo -e "${GREEN}Dependencies installed.${NC}"

# --- Check Hammerspoon ---
echo ""
if [ -d "/Applications/Hammerspoon.app" ] || [ -d "$HOME/Applications/Hammerspoon.app" ]; then
    echo -e "${GREEN}Hammerspoon found.${NC}"
else
    echo -e "${YELLOW}Hammerspoon not found.${NC}"
    echo "Install from: https://www.hammerspoon.org/"
    echo "Or: brew install --cask hammerspoon"
    echo ""
    read -p "Install Hammerspoon via Homebrew now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v brew &>/dev/null; then
            brew install --cask hammerspoon
            echo -e "${GREEN}Hammerspoon installed.${NC}"
        else
            echo -e "${RED}Homebrew not found. Install Hammerspoon manually.${NC}"
            exit 1
        fi
    fi
fi

# --- Copy voice-input.py ---
echo ""
INSTALL_DIR="$HOME/.speakeasy"
mkdir -p "$INSTALL_DIR"
cp "$SPEAKEASY_DIR/voice-input.py" "$INSTALL_DIR/voice-input.py"
chmod +x "$INSTALL_DIR/voice-input.py"
echo -e "${GREEN}Installed voice-input.py to $INSTALL_DIR${NC}"

# --- Configure Hammerspoon ---
echo ""
HS_DIR="$HOME/.hammerspoon"
HS_INIT="$HS_DIR/init.lua"
SPEAKEASY_LUA="$HS_DIR/speakeasy.lua"

mkdir -p "$HS_DIR"

# Copy the Hammerspoon config
cp "$SPEAKEASY_DIR/speakeasy-hammerspoon.lua" "$SPEAKEASY_LUA"

# Update paths in the lua config
PYTHON_FULL=$(command -v "$PYTHON")
sed -i '' "s|/usr/local/bin/python3|$PYTHON_FULL|g" "$SPEAKEASY_LUA"
if ! grep -q "$PYTHON_FULL" "$SPEAKEASY_LUA"; then
    echo -e "${RED}Error: Python path substitution failed in $SPEAKEASY_LUA${NC}"
    echo "Expected to find: $PYTHON_FULL"
    exit 1
fi
# Add require to init.lua if not already present
if [ -f "$HS_INIT" ]; then
    if ! grep -q "speakeasy" "$HS_INIT"; then
        echo "" >> "$HS_INIT"
        echo '-- MUSE SpeakEasy voice input' >> "$HS_INIT"
        echo 'dofile(hs.configdir .. "/speakeasy.lua")' >> "$HS_INIT"
        echo -e "${GREEN}Added SpeakEasy to existing Hammerspoon config.${NC}"
    else
        echo -e "${YELLOW}SpeakEasy already in Hammerspoon config — skipped.${NC}"
    fi
else
    echo '-- MUSE SpeakEasy voice input' > "$HS_INIT"
    echo 'dofile(hs.configdir .. "/speakeasy.lua")' >> "$HS_INIT"
    echo -e "${GREEN}Created Hammerspoon config with SpeakEasy.${NC}"
fi

# --- Reload Hammerspoon ---
if pgrep -q Hammerspoon; then
    echo ""
    echo "Reloading Hammerspoon..."
    open -g "hammerspoon://reload"
    echo -e "${GREEN}Hammerspoon reloaded.${NC}"
fi

# --- Pre-download Whisper model ---
echo ""
echo "Pre-downloading Whisper model (this may take a moment on first run)..."
$PYTHON -c "import whisper; whisper.load_model('base')" 2>/dev/null && \
    echo -e "${GREEN}Whisper 'base' model ready.${NC}" || \
    echo -e "${YELLOW}Model will download on first use.${NC}"

# --- Done ---
echo ""
echo "========================================"
echo -e "${GREEN}  SpeakEasy installed!${NC}"
echo ""
echo "  Press Caps Lock to start recording."
echo "  Press Caps Lock again to stop (or wait for silence)."
echo "  Press Escape to cancel and discard."
echo "  Your words will be typed into the active window."
echo ""
echo "  Config: $INSTALL_DIR/voice-input.py"
echo "  Hotkey: $SPEAKEASY_LUA"
echo ""
echo "  Environment variables (optional):"
echo "    SPEAKEASY_SILENCE_SECONDS  (default: 8)"
echo "    SPEAKEASY_MAX_SECONDS      (default: 300)"
echo "    SPEAKEASY_WHISPER_MODEL    (default: base)"
echo "    SPEAKEASY_LANGUAGE         (default: en)"
echo "========================================"
echo ""
