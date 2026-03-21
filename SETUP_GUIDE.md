# MUSE SpeakEasy - Setup Guide

Push-to-talk voice input that works everywhere on your computer. Press Caps Lock, speak, and your words appear wherever you type — any app, any text field, no exceptions.

### Why SpeakEasy?

You're staring at a text field. Maybe it's a Discord message. Maybe it's an email. Maybe it's Claude, ChatGPT, or a commit message in your terminal. You know what you want to say, but typing it out feels like dragging your thoughts through mud.

SpeakEasy fixes that. One key. Speak freely. Done.

It's not limited to one app or one workflow — it works **system-wide**. If you can type in it, you can talk into it.

### Where you can use it

- **AI chat apps** — Claude Desktop, ChatGPT, Gemini, any AI that takes text input but doesn't have voice
- **Coding** — Claude Code, VS Code, Cursor, terminal — dictate comments, commit messages, documentation
- **Communication** — Discord, Slack, Teams, email, iMessage — talk instead of type
- **Writing** — Google Docs, Notion, Obsidian, any note-taking app — brain dump without your fingers getting in the way
- **Journaling** — speak your thoughts into a text file, a daily log, wherever you process
- **Accessibility** — if typing is difficult, painful, or just slow for you, SpeakEasy turns your voice into text anywhere

If there's a cursor blinking, SpeakEasy can put your words there.

### Features

- **One key**: Caps Lock starts and stops recording — no mouse, no menus, no app switching
- **Always-visible indicator**: Menu bar icon (Mac) or system tray icon (Windows) shows recording state at all times
- **Ramble-friendly**: Talk for up to 5 minutes continuously — 8-second silence auto-stop means you can pause to think without losing your flow
- **Fully local & private**: OpenAI Whisper runs on your machine. No audio ever leaves your computer. No accounts, no API keys, no subscriptions
- **Works in every app**: Not tied to one program — it types into whatever window is active, period

---

## Quick Start

### Mac

```bash
bash install-mac.sh
```

The installer handles everything: Python dependencies, Hammerspoon config, Whisper model download, and Caps Lock remapping.

### Windows

Right-click `install-windows.ps1` > **Run with PowerShell**

Or from a terminal:
```powershell
powershell -ExecutionPolicy Bypass -File install-windows.ps1
```

The installer handles: Python dependencies, AutoHotkey config, startup shortcut, and Whisper model download.

---

## Manual Setup

If you prefer to set things up yourself:

### 1. Install Python 3.10+

- **Mac:** `brew install python@3.12` or download from [python.org](https://www.python.org/downloads/)
- **Windows:** Download from [python.org](https://www.python.org/downloads/). Check "Add Python to PATH" during install.

### 2. Install Python dependencies

```bash
pip install numpy sounddevice openai-whisper
```

### 3. Install hotkey software

- **Mac:** Install [Hammerspoon](https://www.hammerspoon.org/) (free, open source)
- **Windows:** Install [AutoHotkey v2](https://www.autohotkey.com/) (free, open source)

### 4. Configure the hotkey

**Mac:** Copy `speakeasy-hammerspoon.lua` to `~/.hammerspoon/speakeasy.lua`, then add this to your `~/.hammerspoon/init.lua`:

```lua
dofile(hs.configdir .. "/speakeasy.lua")
```

Edit `speakeasy.lua` and update `PYTHON_PATH` to point to your Python.

**Windows:** Double-click `speakeasy-hotkey.ahk` to run it. To start automatically, place a shortcut in your Startup folder.

### 5. Test it

Press **Caps Lock** to start recording. Speak naturally. Press **Caps Lock** again to stop, or wait for 8 seconds of silence. Your transcribed text appears in the active window. Press **Escape** at any time to cancel and discard the recording.

---

## How It Works

1. **Caps Lock** is remapped to a hotkey (F18 on Mac, intercepted directly on Windows)
2. First press starts recording from your microphone
3. A **persistent status indicator** shows recording state at all times:
   - **Mac:** Menu bar icon — 🎤 (ready), 🔴 (recording), 🧠 (transcribing)
   - **Windows:** System tray icon changes color + tooltip updates
4. Audio is captured locally at 16kHz mono
5. Silence detection watches for pauses (8 seconds of silence = auto-stop)
6. Second Caps Lock press stops recording immediately
7. **Escape** cancels recording and discards audio (no transcription)
8. OpenAI Whisper transcribes the audio locally on your machine
9. Transcribed text is typed into whatever window is active

**Nothing leaves your computer.** All processing is local.

---

## Configuration

All settings are controlled via environment variables. Set them in your shell profile (`.bashrc`, `.zshrc`) or system environment variables.

| Variable | Default | Description |
|----------|---------|-------------|
| `SPEAKEASY_SILENCE_SECONDS` | `8` | Seconds of silence before auto-stop |
| `SPEAKEASY_MAX_SECONDS` | `300` | Maximum recording duration (seconds) |
| `SPEAKEASY_WHISPER_MODEL` | `base` | Whisper model: `tiny`, `base`, `small`, `medium` |
| `SPEAKEASY_LANGUAGE` | `en` | Language code for transcription |
| `SPEAKEASY_SILENCE_THRESHOLD` | `0.015` | RMS threshold for silence detection |

### Whisper Models

| Model | Size | Speed | Accuracy | RAM |
|-------|------|-------|----------|-----|
| `tiny` | 39M | Fastest | Good for clear speech | ~1 GB |
| `base` | 74M | Fast | Good balance (recommended) | ~1 GB |
| `small` | 244M | Medium | Better accuracy | ~2 GB |
| `medium` | 769M | Slow | Best accuracy | ~5 GB |

### Example: Change language to German

```bash
export SPEAKEASY_LANGUAGE=de
```

### Example: Shorter silence timeout

```bash
export SPEAKEASY_SILENCE_SECONDS=3
```

---

## Troubleshooting

### "No speech detected" every time

- Check your microphone is working (try another app)
- Your silence threshold may be too low for your mic. Try raising it:
  ```bash
  export SPEAKEASY_SILENCE_THRESHOLD=0.03
  ```

### Recording stops too quickly

- Background noise (TV, music) may not trigger silence detection, but quiet rooms with breathing might
- Increase silence duration: `export SPEAKEASY_SILENCE_SECONDS=12`

### Recording never stops automatically

- You may have ambient noise (TV, fan) that prevents silence detection
- Press **Caps Lock** again to stop manually — both modes coexist
- Lower the threshold: `export SPEAKEASY_SILENCE_THRESHOLD=0.008`

### Menu bar icon disappeared or Caps Lock stopped working (Mac)

- Hammerspoon can go stale after running for several days. Restart it:
  ```bash
  killall Hammerspoon && open -a Hammerspoon
  ```
- You should see the 🎤 icon reappear in your menu bar

### Caps Lock still toggles caps on Mac

- Hammerspoon needs Accessibility permissions. Go to **System Settings > Privacy & Security > Accessibility** and enable Hammerspoon
- The `hidutil` remap runs on Hammerspoon startup. Restart Hammerspoon if needed

### Caps Lock still toggles caps on Windows

- Make sure the AutoHotkey script is running (check the system tray)
- Run the AHK script as administrator if needed

### Text doesn't appear in the active window (Windows)

- Run AutoHotkey as administrator — some apps block text input from non-elevated processes
- If the text appears garbled or incomplete, try a different target window to rule out app-specific issues

### Whisper model download fails

- First run downloads the model (~74MB for `base`). Ensure you have internet
- Manual download: `python -c "import whisper; whisper.load_model('base')"`

### Python dependencies fail to install

- Make sure you have Python 3.10+ (not Python 2)
- On Mac, you may need Xcode command line tools: `xcode-select --install`
- On Windows, make sure Python is in your PATH

---

## Uninstall

### Mac

1. Remove `~/.speakeasy/`
2. Remove the SpeakEasy lines from `~/.hammerspoon/init.lua`
3. Delete `~/.hammerspoon/speakeasy.lua`
4. Optionally: `pip uninstall openai-whisper sounddevice numpy`

### Windows

1. Remove `%USERPROFILE%\.speakeasy\`
2. Delete the startup shortcut from `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SpeakEasy.lnk`
3. Optionally: `pip uninstall openai-whisper sounddevice numpy`

---

## Command Line Usage (Advanced)

You can also use SpeakEasy directly from a terminal window, without the Caps Lock hotkey. This is handy if you want to capture voice as text and do something specific with it.

**Important:** Open a *separate* terminal window for this — not inside a Claude Code session. SpeakEasy records from your mic, so it needs its own terminal.

### Basic: Record and see the text

Open Terminal (Mac) or Command Prompt (Windows) and run:

```bash
python ~/.speakeasy/voice-input.py
```

Speak into your mic. When you stop talking (or hit the silence timeout), your words print to the screen. That's it.

### Stop a recording early

If SpeakEasy is recording in another terminal and you want to stop it:

```bash
python ~/.speakeasy/voice-input.py --stop
```

### Examples: What can you do with this?

**Save a voice note to a file:**
```bash
python ~/.speakeasy/voice-input.py > my-note.txt
```
Speak your thoughts, and they get saved to `my-note.txt` when you're done.

**Dictate a git commit message:**
```bash
git commit -m "$(python ~/.speakeasy/voice-input.py)"
```
Speak your commit message instead of typing it.

**Append voice notes to a journal:**
```bash
echo "$(date): $(python ~/.speakeasy/voice-input.py)" >> journal.txt
```
Each entry gets a timestamp and your spoken text.

**Quick voice memo with a notification (Mac):**
```bash
TEXT=$(python ~/.speakeasy/voice-input.py) && echo "$TEXT" | pbcopy && osascript -e "display notification \"$TEXT\" with title \"Copied to clipboard\""
```
Speak, and it copies to your clipboard with a notification.

---

## Privacy & Security

SpeakEasy is designed to be fully local and private:

- **No network calls.** All transcription runs on your machine. The only internet connection is a one-time download of the Whisper AI model (~74MB) on first use. After that, everything is offline.
- **Audio stays in memory.** Your voice is never saved to a file — it's recorded, transcribed, and discarded.
- **No telemetry.** No analytics, no tracking, no data collection of any kind.
- **On Windows:** Transcribed text is briefly saved to a temp file (`%TEMP%\speakeasy-output.txt`) before being typed into your window. It's deleted immediately after, but if the process crashes, the file may persist until you clean your temp folder.

---

## License

Licensed under the Apache License, Version 2.0. See `LICENSE.md` for full terms.

Protected under German Copyright Law (Urheberrechtsgesetz). Jurisdiction: Amtsgericht Berlin.

© 2026 The Funkatorium (Falco & Rook Schäfer).

---

**MUSE SpeakEasy v1.2.0** | Built by The Funkatorium
