-- Copyright 2026 The Funkatorium (Falco & Rook Schäfer)
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- MUSE SpeakEasy - Push-to-talk voice input for macOS
-- Drop this into your ~/.hammerspoon/init.lua (or require it)
--
-- Remaps Caps Lock → F18, binds F18 to toggle voice recording.
-- Transcribed text is typed into the active window.
-- Menu bar icon shows recording state at all times.
--
-- Part of the MUSE product line by The Funkatorium.

-- === Config ===
-- Update PYTHON_PATH to your Python with numpy, sounddevice, openai-whisper installed
local PYTHON_PATH = os.getenv("SPEAKEASY_PYTHON") or "/usr/local/bin/python3"
local SCRIPT_PATH = os.getenv("SPEAKEASY_SCRIPT") or os.getenv("HOME") .. "/.speakeasy/voice-input.py"

-- === State ===
local isRecording = false
local wasAborted = false
local voiceTask = nil

-- === Alert style ===
hs.alert.defaultStyle.textSize = 16
hs.alert.defaultStyle.radius = 8
hs.alert.defaultStyle.atScreenEdge = 2  -- top of screen (near menu bar)

-- === Menu Bar Indicator ===
local menuIcon = hs.menubar.new()

local function updateMenuIcon(state)
    if not menuIcon then return end
    if state == "recording" then
        menuIcon:setTitle("🔴")
        menuIcon:setTooltip("SpeakEasy: Recording...")
    elseif state == "transcribing" then
        menuIcon:setTitle("🧠")
        menuIcon:setTooltip("SpeakEasy: Transcribing...")
    else
        menuIcon:setTitle("🎤")
        menuIcon:setTooltip("SpeakEasy: Ready — Caps Lock to talk")
    end
end

updateMenuIcon("idle")

-- === Caps Lock → F18 remap ===
local function remapCapsLock()
    local cmd = [[hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}']]
    hs.execute(cmd)
    print("SpeakEasy: Caps Lock remapped to F18")
end
remapCapsLock()

-- === Escape to cancel (modal — only active during recording) ===
local escapeModal = hs.hotkey.modal.new()
escapeModal:bind({}, "escape", function()
    isRecording = false
    wasAborted = true
    escapeModal:exit()
    updateMenuIcon("idle")
    hs.alert.show("❌ Cancelled", 1)
    -- Signal abort via --abort
    hs.task.new(PYTHON_PATH, function() end, {SCRIPT_PATH, "--abort"}):start()
    -- Terminate the recording task if still running
    if voiceTask and voiceTask:isRunning() then
        voiceTask:terminate()
    end
    voiceTask = nil
end)

-- === Voice input toggle ===
local function startVoiceInput()
    if isRecording then
        -- Second press: stop recording
        isRecording = false
        escapeModal:exit()
        updateMenuIcon("transcribing")
        hs.alert.show("🧠 Transcribing...", 1)
        -- Signal via --stop
        hs.task.new(PYTHON_PATH, function() end, {SCRIPT_PATH, "--stop"}):start()
        return
    end

    -- First press: start recording
    isRecording = true
    wasAborted = false
    updateMenuIcon("recording")
    hs.alert.show("🎤 Listening... (Esc to cancel)", 1)
    escapeModal:enter()

    voiceTask = hs.task.new(PYTHON_PATH, function(exitCode, stdOut, stdErr)
        isRecording = false
        escapeModal:exit()
        updateMenuIcon("idle")
        -- If abort was triggered, ignore all output
        if wasAborted then return end
        if stdOut and stdOut ~= "" then
            local text = stdOut:match("^%s*(.-)%s*$")  -- trim
            if text and text ~= "" then
                local preview = text:sub(1, 50)
                if #text > 50 then preview = preview .. "..." end
                hs.alert.show("✅ " .. preview, 2)
                -- Small delay to ensure alert is shown
                hs.timer.doAfter(0.1, function()
                    hs.eventtap.keyStrokes(text)
                end)
            else
                hs.alert.show("🔇 No speech detected", 1)
            end
        else
            hs.alert.show("🔇 No speech detected", 1)
        end
    end, {SCRIPT_PATH})
    voiceTask:start()
end

-- === Bind F18 (remapped Caps Lock) ===
hs.hotkey.bind({}, "f18", startVoiceInput)

hs.alert.show("🎤 SpeakEasy ready — Caps Lock to talk, Esc to cancel", 2)
