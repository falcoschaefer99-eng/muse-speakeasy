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
# MUSE SpeakEasy - Windows Installer
# Installs dependencies and configures Caps Lock voice input.
#
# Usage: Right-click > Run with PowerShell
#   or:  powershell -ExecutionPolicy Bypass -File install-windows.ps1

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  MUSE SpeakEasy - Windows Setup" -ForegroundColor Cyan
Write-Host "  ==============================="
Write-Host ""

# --- Check Python ---
$Python = $null
foreach ($candidate in @("python3", "python", "py")) {
    try {
        $version = & $candidate --version 2>&1
        if ($version -match "Python 3\.(\d+)") {
            $minor = [int]$Matches[1]
            if ($minor -ge 10) {
                $Python = $candidate
                break
            }
        }
    } catch {}
}

if (-not $Python) {
    Write-Host "Python 3.10+ not found." -ForegroundColor Red
    Write-Host "Download from: https://www.python.org/downloads/"
    Write-Host "Make sure to check 'Add Python to PATH' during installation."
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Found Python: $(& $Python --version)" -ForegroundColor Green

# --- Install Python dependencies ---
Write-Host ""
Write-Host "Installing Python dependencies..."
& $Python -m pip install --upgrade pip --quiet 2>$null
& $Python -m pip install numpy sounddevice openai-whisper --quiet
Write-Host "Dependencies installed." -ForegroundColor Green

# --- Check AutoHotkey ---
Write-Host ""
$AhkPath = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe"
$AhkPathAlt = "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey.exe"

if (Test-Path $AhkPath) {
    Write-Host "AutoHotkey v2 found." -ForegroundColor Green
} elseif (Test-Path $AhkPathAlt) {
    $AhkPath = $AhkPathAlt
    Write-Host "AutoHotkey v2 found." -ForegroundColor Green
} else {
    Write-Host "AutoHotkey v2 not found." -ForegroundColor Yellow
    Write-Host "Download from: https://www.autohotkey.com/"
    Write-Host ""
    $install = Read-Host "Open AutoHotkey download page? [y/N]"
    if ($install -eq 'y') {
        Start-Process "https://www.autohotkey.com/"
        Write-Host "Install AutoHotkey v2 and re-run this script." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# --- Install SpeakEasy files ---
Write-Host ""
$InstallDir = "$env:USERPROFILE\.speakeasy"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Copy-Item "$ScriptDir\voice-input.py" "$InstallDir\voice-input.py" -Force
Copy-Item "$ScriptDir\speakeasy-hotkey.ahk" "$InstallDir\speakeasy-hotkey.ahk" -Force

# Update paths in the AHK script
$ahkContent = Get-Content "$InstallDir\speakeasy-hotkey.ahk" -Raw
$PythonFull = (Get-Command $Python).Source
$ahkContent = $ahkContent -replace 'SCRIPT_PATH := EnvGet\("SPEAKEASY_SCRIPT"\) \|\| A_ScriptDir \. "\\voice-input\.py"', "SCRIPT_PATH := EnvGet(""SPEAKEASY_SCRIPT"") || ""$InstallDir\voice-input.py"""
Set-Content "$InstallDir\speakeasy-hotkey.ahk" $ahkContent

Write-Host "Installed to $InstallDir" -ForegroundColor Green

# --- Create startup shortcut ---
Write-Host ""
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = "$startupFolder\SpeakEasy.lnk"

$createShortcut = Read-Host "Start SpeakEasy automatically on login? [Y/n]"
if ($createShortcut -ne 'n') {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $AhkPath
    $Shortcut.Arguments = """$InstallDir\speakeasy-hotkey.ahk"""
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Description = "MUSE SpeakEasy - Voice Input"
    $Shortcut.Save()
    Write-Host "Startup shortcut created." -ForegroundColor Green
}

# --- Pre-download Whisper model ---
Write-Host ""
Write-Host "Pre-downloading Whisper model..."
try {
    & $Python -c "import whisper; whisper.load_model('base')" 2>$null
    Write-Host "Whisper 'base' model ready." -ForegroundColor Green
} catch {
    Write-Host "Model will download on first use." -ForegroundColor Yellow
}

# --- Launch SpeakEasy ---
Write-Host ""
$launch = Read-Host "Launch SpeakEasy now? [Y/n]"
if ($launch -ne 'n') {
    Start-Process $AhkPath -ArgumentList """$InstallDir\speakeasy-hotkey.ahk"""
    Write-Host "SpeakEasy is running!" -ForegroundColor Green
}

# --- Done ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SpeakEasy installed!" -ForegroundColor Green
Write-Host ""
Write-Host "  Press Caps Lock to start recording."
Write-Host "  Press Caps Lock again to stop (or wait for silence)."
Write-Host "  Press Escape to cancel and discard."
Write-Host "  Your words will be typed into the active window."
Write-Host ""
Write-Host "  Config: $InstallDir\voice-input.py"
Write-Host "  Hotkey: $InstallDir\speakeasy-hotkey.ahk"
Write-Host ""
Write-Host "  Environment variables (optional):"
Write-Host "    SPEAKEASY_SILENCE_SECONDS  (default: 8)"
Write-Host "    SPEAKEASY_MAX_SECONDS      (default: 300)"
Write-Host "    SPEAKEASY_WHISPER_MODEL    (default: base)"
Write-Host "    SPEAKEASY_LANGUAGE         (default: en)"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to close"
