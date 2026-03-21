#!/usr/bin/env python3
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
"""
MUSE SpeakEasy - Push-to-talk voice input for terminal.
Records from mic with silence detection, transcribes locally via Whisper.

Part of the MUSE product line by The Funkatorium.

Usage:
    python3 voice-input.py          # Record until silence, print transcription
    python3 voice-input.py --stop   # Signal a running instance to stop recording
    python3 voice-input.py --abort  # Signal a running instance to abort (discard audio)

Environment variables (all optional):
    SPEAKEASY_SILENCE_SECONDS   Seconds of silence before auto-stop (default: 8)
    SPEAKEASY_MAX_SECONDS       Max recording duration in seconds (default: 300)
    SPEAKEASY_WHISPER_MODEL     Whisper model size: tiny/base/small/medium (default: base)
    SPEAKEASY_LANGUAGE          Transcription language code (default: en)
    SPEAKEASY_SILENCE_THRESHOLD RMS threshold for silence detection (default: 0.015)
"""

__version__ = "1.2.0"
__product__ = "MUSE SpeakEasy"

import sys
import os
import signal
import time

# Check dependencies before importing them
_missing = []
try:
    import numpy as np
except ImportError:
    _missing.append("numpy")
try:
    import sounddevice as sd
except ImportError:
    _missing.append("sounddevice")
try:
    import whisper
except ImportError:
    _missing.append("openai-whisper")

if _missing:
    print(
        f"SpeakEasy: Missing dependencies: {', '.join(_missing)}\n"
        f"Install with: pip install {' '.join(_missing)}",
        file=sys.stderr,
    )
    sys.exit(1)

# --- Config (overridable via env vars) ---
SAMPLE_RATE = 16000
CHANNELS = 1
SILENCE_THRESHOLD = float(os.environ.get("SPEAKEASY_SILENCE_THRESHOLD", "0.015"))
SILENCE_DURATION = float(os.environ.get("SPEAKEASY_SILENCE_SECONDS", "8.0"))
MAX_DURATION = float(os.environ.get("SPEAKEASY_MAX_SECONDS", "300"))
WHISPER_MODEL = os.environ.get("SPEAKEASY_WHISPER_MODEL", "base")
LANGUAGE = os.environ.get("SPEAKEASY_LANGUAGE", "en")
_TMPDIR = os.environ.get("TMPDIR", os.environ.get("TEMP", "/tmp"))
PID_FILE = os.path.join(_TMPDIR, "speakeasy.pid")
STOP_FILE = os.path.join(_TMPDIR, "speakeasy.stop")
ABORT_FILE = os.path.join(_TMPDIR, "speakeasy.abort")

# --- Globals ---
_whisper_model = None
_aborted = False


def get_whisper():
    global _whisper_model
    if _whisper_model is None:
        _whisper_model = whisper.load_model(WHISPER_MODEL)
    return _whisper_model


def record_until_silence():
    """Record audio until silence is detected or max duration reached."""
    global _aborted
    chunks = []
    silence_start = None
    recording = True
    _aborted = False

    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    # Clean up any stale stop/abort files
    for f in (STOP_FILE, ABORT_FILE):
        try:
            os.remove(f)
        except OSError:
            pass

    def handle_stop(signum, frame):
        nonlocal recording
        recording = False

    # SIGUSR1 for Unix, stop file for cross-platform (Windows uses stop file only)
    if hasattr(signal, "SIGUSR1"):
        signal.signal(signal.SIGUSR1, handle_stop)

    print("Recording...", file=sys.stderr, flush=True)

    def callback(indata, frames, time_info, status):
        nonlocal silence_start, recording
        if not recording:
            raise sd.CallbackAbort()

        chunks.append(indata.copy())

        rms = np.sqrt(np.mean(indata ** 2))
        if rms < SILENCE_THRESHOLD:
            if silence_start is None:
                silence_start = time.time()
            elif time.time() - silence_start > SILENCE_DURATION:
                recording = False
                raise sd.CallbackAbort()
        else:
            silence_start = None

    try:
        with sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=CHANNELS,
            dtype="float32",
            blocksize=int(SAMPLE_RATE * 0.1),
            callback=callback,
        ):
            start_time = time.time()
            while recording:
                time.sleep(0.05)
                if time.time() - start_time > MAX_DURATION:
                    break
                # Cross-platform stop: check for stop file
                if os.path.exists(STOP_FILE):
                    try:
                        os.remove(STOP_FILE)
                    except OSError:
                        pass
                    recording = False
                # Cross-platform abort: check for abort file
                if os.path.exists(ABORT_FILE):
                    try:
                        os.remove(ABORT_FILE)
                    except OSError:
                        pass
                    _aborted = True
                    recording = False
    except sd.CallbackAbort:
        pass

    try:
        os.remove(PID_FILE)
    except OSError:
        pass

    if not chunks:
        return None

    return np.concatenate(chunks, axis=0).flatten()


def transcribe(audio):
    """Transcribe audio array using Whisper."""
    model = get_whisper()
    result = model.transcribe(audio, language=LANGUAGE, fp16=False)
    return result["text"].strip()


def stop_recording():
    """Signal a running SpeakEasy instance to stop."""
    # Cross-platform: create stop file (works on all OSes)
    try:
        with open(STOP_FILE, "w") as f:
            f.write("stop")
    except OSError:
        pass

    # Unix: also send SIGUSR1 for immediate response
    if hasattr(signal, "SIGUSR1"):
        try:
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
            os.kill(pid, signal.SIGUSR1)
        except (FileNotFoundError, ProcessLookupError, ValueError):
            pass


def abort_recording():
    """Signal a running SpeakEasy instance to abort (discard audio, no transcription)."""
    # Cross-platform: create abort file
    try:
        with open(ABORT_FILE, "w") as f:
            f.write("abort")
    except OSError:
        pass

    # Unix: also send SIGUSR1 to break out of recording immediately
    if hasattr(signal, "SIGUSR1"):
        try:
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
            os.kill(pid, signal.SIGUSR1)
        except (FileNotFoundError, ProcessLookupError, ValueError):
            pass


def main():
    if "--version" in sys.argv:
        print(f"{__product__} v{__version__}")
        return

    if "--stop" in sys.argv:
        stop_recording()
        return

    if "--abort" in sys.argv:
        abort_recording()
        return

    audio = record_until_silence()

    if _aborted:
        print("", end="")
        return

    if audio is None or len(audio) < SAMPLE_RATE * 0.3:
        print("", end="")
        return

    print("Transcribing...", file=sys.stderr, flush=True)
    text = transcribe(audio)

    if text and text.strip():
        print(text, end="")
    else:
        print("", end="")


if __name__ == "__main__":
    main()
