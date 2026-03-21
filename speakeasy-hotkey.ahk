; Copyright 2026 The Funkatorium (Falco & Rook Schäfer)
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

; MUSE SpeakEasy - Push-to-talk voice input for Windows
; Remaps Caps Lock to toggle voice recording + transcription.
; Tray icon changes state: green (ready), red (recording), blue (transcribing)
;
; Requires: AutoHotkey v2, Python 3.10+, voice-input.py with dependencies
;
; Part of the MUSE product line by The Funkatorium.

#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Config ---
; Path to Python executable (update to match your install)
PYTHON_PATH := EnvGet("SPEAKEASY_PYTHON") || "python"
; Path to voice-input.py
SCRIPT_PATH := EnvGet("SPEAKEASY_SCRIPT") || A_ScriptDir . "\voice-input.py"

isRecording := false
recordingPID := 0

; --- Tray state indicator ---
UpdateTray(state) {
    if state = "recording" {
        A_IconTip := "SpeakEasy: Recording..."
        TraySetIcon("Shell32.dll", 170)  ; Red circle
    } else if state = "transcribing" {
        A_IconTip := "SpeakEasy: Transcribing..."
        TraySetIcon("Shell32.dll", 145)  ; Gear/processing
    } else {
        A_IconTip := "SpeakEasy: Ready — Caps Lock to talk"
        TraySetIcon("Shell32.dll", 177)  ; Green checkmark
    }
}

; Tooltip helper
ShowStatus(msg, duration := 2000) {
    ToolTip(msg)
    if duration > 0
        SetTimer(() => ToolTip(), -duration)
}

; Start recording
StartRecording() {
    global isRecording, recordingPID

    if isRecording {
        StopRecording()
        return
    }

    isRecording := true
    UpdateTray("recording")
    ShowStatus("🎤 Recording... (Esc to cancel)", 0)  ; Persistent until stopped

    ; Enable Escape hotkey during recording
    Hotkey("Escape", AbortRecording, "On")

    ; Run voice-input.py, capture stdout to temp file
    outputFile := EnvGet("TEMP") . "\speakeasy-output.txt"
    try FileDelete(outputFile)

    ; Launch Python script
    cmd := '"' . PYTHON_PATH . '" "' . SCRIPT_PATH . '" > "' . outputFile . '" 2>NUL'
    Run(A_ComSpec . ' /c ' . cmd,, "Hide", &pid)
    recordingPID := pid

    ; Watch for process completion
    SetTimer(CheckRecordingDone.Bind(outputFile), 200)
}

; Stop recording via stop file
StopRecording() {
    global isRecording, recordingPID

    if !isRecording
        return

    ; Disable Escape hotkey
    Hotkey("Escape", AbortRecording, "Off")

    UpdateTray("transcribing")
    ShowStatus("🧠 Transcribing...")

    ; Create stop file (cross-platform mechanism)
    stopFile := EnvGet("TEMP") . "\speakeasy.stop"
    try FileAppend("stop", stopFile)

    ; Also try --stop for signal-based stop
    cmd := '"' . PYTHON_PATH . '" "' . SCRIPT_PATH . '" --stop'
    Run(A_ComSpec . ' /c ' . cmd,, "Hide")
}

; Abort recording — discard audio, no transcription
AbortRecording(*) {
    global isRecording, recordingPID

    if !isRecording
        return

    ; Disable Escape hotkey
    Hotkey("Escape", AbortRecording, "Off")

    isRecording := false
    UpdateTray("idle")
    ShowStatus("❌ Cancelled", 1500)

    ; Create abort file
    abortFile := EnvGet("TEMP") . "\speakeasy.abort"
    try FileAppend("abort", abortFile)

    ; Also signal via --abort
    cmd := '"' . PYTHON_PATH . '" "' . SCRIPT_PATH . '" --abort'
    Run(A_ComSpec . ' /c ' . cmd,, "Hide")

    ; Kill the recording process
    if recordingPID {
        try ProcessClose(recordingPID)
        recordingPID := 0
    }
}

; Check if recording process finished
CheckRecordingDone(outputFile) {
    global isRecording, recordingPID

    if !isRecording {
        SetTimer(, 0)  ; Stop checking
        return
    }

    ; Check if process is still running
    try {
        if ProcessExist(recordingPID)
            return  ; Still running, check again later
    }

    ; Process done
    SetTimer(, 0)  ; Stop checking
    isRecording := false
    try Hotkey("Escape", AbortRecording, "Off")
    UpdateTray("idle")

    ; Read transcription output
    text := ""
    try {
        if FileExist(outputFile)
            text := Trim(FileRead(outputFile))
        FileDelete(outputFile)
    }

    if text = "" {
        ShowStatus("🔇 No speech detected", 1500)
        return
    }

    ; Show preview
    preview := SubStr(text, 1, 50)
    if StrLen(text) > 50
        preview .= "..."
    ShowStatus("✅ " . preview, 2000)

    ; Type the transcribed text into active window
    ; Small delay to ensure tooltip doesn't interfere
    Sleep(100)
    SendInput(text)
}

; --- Hotkey: Caps Lock toggles recording ---
CapsLock::StartRecording()

; Disable Caps Lock toggle behavior
*CapsLock Up::return

; Tray menu
A_TrayMenu.Delete()
A_TrayMenu.Add("MUSE SpeakEasy v1.2.0", (*) => 0)
A_TrayMenu.Disable("MUSE SpeakEasy v1.2.0")
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())

; Initialize
Hotkey("Escape", AbortRecording, "Off")  ; Register but keep disabled
UpdateTray("idle")
ShowStatus("🎤 SpeakEasy ready — Caps Lock to talk, Esc to cancel", 3000)
