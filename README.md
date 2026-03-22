<p align="center">
  <img src="./banner.png" alt="MUSE SpeakEasy" width="600" />
</p>

<p align="center">
  <em>Press one key. Speak. Your words appear wherever you type.</em>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-D4AF37?style=flat" alt="License: Apache 2.0" /></a>
  <img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=flat&logo=python&logoColor=white" alt="Python 3.10+" />
  <img src="https://img.shields.io/badge/macOS-Hammerspoon-000000?style=flat&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/Windows-AutoHotkey%20v2-0078D4?style=flat&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/Privacy-100%25%20Local-brightgreen?style=flat" alt="100% Local" />
</p>

---

## What Is This?

SpeakEasy turns any text field on your computer into a microphone. Press one key, speak naturally, and your words appear — terminal, editor, browser, chat, anywhere. Everything runs locally on your machine. Nothing ever leaves it.

## Features

- **One-key voice input** — press to start, press again to stop. Escape to cancel
- **Ramble-friendly** — talk for up to 5 minutes with smart silence detection
- **99 languages** — English, German, Spanish, Japanese, and 95+ more
- **Mac + Windows** — full support for both platforms with one-click installers
- **Zero background footprint** — does nothing until you press the key
- **Configurable** — adjust sensitivity, recording duration, transcription quality, and language

## Quick Start

### macOS

```bash
bash install-mac.sh
```

The installer sets up everything: Python dependencies, Hammerspoon configuration, and Caps Lock remapping. Reboot once after install.

### Windows

```powershell
# Right-click > Run with PowerShell
.\install-windows.ps1
```

Installs dependencies, configures AutoHotkey v2, and sets up the Caps Lock hotkey.

### Manual Setup

See the full [Setup Guide](SETUP_GUIDE.md) for manual installation, troubleshooting, and configuration options.

## How It Works

1. **Press Caps Lock** — starts recording from your microphone
2. **Speak naturally** — smart silence detection knows when you're thinking vs. when you're done
3. **Press Caps Lock again** (or wait for silence) — transcription happens locally via Whisper
4. **Text appears** wherever your cursor is — terminal, editor, browser, chat, anywhere

Press **Escape** at any time to cancel without transcribing.

## Configuration

Set these environment variables to customize behavior:

| Variable | Default | Description |
|----------|---------|-------------|
| `SPEAKEASY_SILENCE_SECONDS` | `2.0` | Seconds of silence before auto-stop |
| `SPEAKEASY_SILENCE_THRESHOLD` | `0.01` | Volume threshold for silence detection |
| `SPEAKEASY_MAX_DURATION` | `300` | Maximum recording duration (seconds) |
| `WHISPER_MODEL` | `base` | Whisper model size (`tiny`, `base`, `small`, `medium`, `large`) |
| `WHISPER_LANGUAGE` | (auto) | Force a specific language (e.g., `en`, `de`, `ja`) |

## Privacy

100% local and private. All transcription happens on your machine using OpenAI's Whisper model — no cloud, no subscription, no account. The only network call is a one-time model download (~74MB) on first use.

## Requirements

- Python 3.10+
- A microphone
- macOS: [Hammerspoon](https://www.hammerspoon.org/) (installed automatically)
- Windows: [AutoHotkey v2](https://www.autohotkey.com/) (installed automatically)

## License

Licensed under the [Apache License, Version 2.0](LICENSE.md).

Copyright 2026 The Funkatorium (Falco & Rook Schäfer). Protected under German Copyright Law (Urheberrechtsgesetz). Jurisdiction: Amtsgericht Berlin.

---

<p align="center">
  <a href="https://linktr.ee/musestudio95">
    <img src="https://img.shields.io/badge/Built%20by-The%20Funkatorium-D4AF37?style=flat" alt="Built by The Funkatorium" />
  </a>
</p>
