-- Loudmouth CopyChat
-- Standalone (no BugGrabber/BugSack dependency). Captures:
--   * Lua errors      -- via our own error handler, plus LUA_WARNING /
--                        ADDON_ACTION_BLOCKED / ADDON_ACTION_FORBIDDEN events
--                        (same approach BugGrabber uses).
--   * Chat text       -- everything printed to any chat frame (includes some
--                        errors addons print to chat).
-- Open with /ce or /copyerrors to get one selectable window: all errors first,
-- then chat text -- select-all is automatic, so just Ctrl+C.

Loudmouth = Loudmouth or {}
Loudmouth.CopyChat = Loudmouth.CopyChat or {}

local CopyChat = Loudmouth.CopyChat
CopyChat.chat = CopyChat.chat or {}         -- chat lines
CopyChat.errors = CopyChat.errors or {}     -- captured Lua errors
CopyChat.maxLines = CopyChat.maxLines or 500
CopyChat.maxErrors = CopyChat.maxErrors or 200

-- Strip color / hyperlink / texture escape codes so the text pastes clean.
local function CleanText(text)
    text = tostring(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")   -- color start
    text = text:gsub("|r", "")                    -- color end
    text = text:gsub("|H.-|h(.-)|h", "%1")        -- hyperlinks -> visible label
    text = text:gsub("|T.-|t", "")                -- inline textures
    return text
end

--------------------------------------------------------------------------------
-- Chat capture
--------------------------------------------------------------------------------

local function StoreLine(_, text)
    if type(text) == "string" and text ~= "" then
        local chat = CopyChat.chat
        chat[#chat + 1] = CleanText(text)
        if #chat > CopyChat.maxLines then
            table.remove(chat, 1)
        end
    end
end

local function HookChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and not cf.LoudmouthCopyHooked then
            hooksecurefunc(cf, "AddMessage", StoreLine)
            cf.LoudmouthCopyHooked = true
        end
    end
end

--------------------------------------------------------------------------------
-- Lua error capture (standalone -- emulates BugGrabber's technique)
--------------------------------------------------------------------------------

-- Best-effort stack retrieval, adapted from Blizzard's/BugGrabber's handler.
local function GetErrorStack()
    local getHeight = GetCallstackHeight
    local getErrHeight = GetErrorCallstackHeight
    if getHeight and getErrHeight then
        local errHeight = getErrHeight()
        if errHeight then
            local level = getHeight() - (errHeight - 1)
            local stack = debugstack(level)
            if stack then return stack end
        end
    end
    return debugstack(3) or ""
end

-- Store a formatted error entry (skips exact consecutive duplicates).
local function StoreError(message, stack)
    message = CleanText(message)
    stack = stack and CleanText(stack) or ""

    local entry = date("[%H:%M:%S] ") .. message
    if stack ~= "" then
        entry = entry .. "\n" .. stack
    end

    local errors = CopyChat.errors
    if errors[#errors] == entry then
        return -- de-dup identical back-to-back errors
    end
    errors[#errors + 1] = entry
    if #errors > CopyChat.maxErrors then
        table.remove(errors, 1)
    end
end

-- Our error handler. Wrapped in pcall so a failure here never loops.
local function OnError(msg)
    local stack = GetErrorStack()
    pcall(StoreError, msg, stack)
    if CopyChat.previousHandler then
        return CopyChat.previousHandler(msg)
    end
end

local function HookErrors()
    if CopyChat.errorHandlerHooked then return end

    -- Chain the current handler so anything else still works.
    CopyChat.previousHandler = geterrorhandler()
    seterrorhandler(OnError)
    CopyChat.errorHandlerHooked = true

    -- Catch taint warnings and blocked/forbidden calls, like BugGrabber does.
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("LUA_WARNING")
    frame:RegisterEvent("ADDON_ACTION_BLOCKED")
    frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    frame:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "LUA_WARNING" then
            pcall(StoreError, "LUA_WARNING: " .. tostring(arg1 or ""), nil)
        else
            pcall(StoreError, string.format("%s: AddOn '%s' tried to call '%s'.",
                event, tostring(arg1 or "?"), tostring(arg2 or "?")), nil)
        end
    end)
    CopyChat.eventFrame = frame
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------

local function BuildText()
    local out = {}

    out[#out + 1] = string.format("===== LUA ERRORS (%d) =====", #CopyChat.errors)
    if #CopyChat.errors == 0 then
        out[#out + 1] = "(none captured this session -- /reload, then reproduce the bug)"
    else
        out[#out + 1] = table.concat(CopyChat.errors, "\n\n")
    end

    out[#out + 1] = ""
    out[#out + 1] = string.format("===== CHAT (%d lines) =====", #CopyChat.chat)
    if #CopyChat.chat == 0 then
        out[#out + 1] = "(no chat captured yet)"
    else
        out[#out + 1] = table.concat(CopyChat.chat, "\n")
    end

    return table.concat(out, "\n")
end

local function Populate()
    local frame = CopyChat.Frame
    if not frame then return end
    frame.editBox:SetText(BuildText())
    frame.editBox:HighlightText()
end

local function BuildFrame()
    if CopyChat.Frame then return CopyChat.Frame end

    local frame = CreateFrame("Frame", "LoudmouthCopyChatFrame", UIParent, "BackdropTemplate")
    frame:SetSize(640, 460)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        centerSized = true,
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()

    local title = frame:CreateFontString()
    title:SetFontObject("GameFontNormal")
    title:SetPoint("TOP", 0, -14)
    title:SetText("Loudmouth Copy  (Ctrl+C to copy, Esc to close)")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    -- Refresh button (re-pull latest, useful if you left the window open)
    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(90, 20)
    refreshButton:SetPoint("TOPLEFT", 16, -38)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function() Populate() end)

    -- Clear button (wipe captured buffers)
    local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearButton:SetSize(90, 20)
    clearButton:SetPoint("LEFT", refreshButton, "RIGHT", 8, 0)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        wipe(CopyChat.errors)
        wipe(CopyChat.chat)
        Populate()
    end)

    local scroll = CreateFrame("ScrollFrame", "LoudmouthCopyChatScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -66)
    scroll:SetPoint("BOTTOMRIGHT", -34, 16)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(580)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    scroll:SetScrollChild(edit)

    frame.editBox = edit
    CopyChat.Frame = frame
    return frame
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function CopyChat.Show()
    BuildFrame()
    Populate()
    CopyChat.Frame:Show()
    CopyChat.Frame.editBox:SetFocus()
end

function CopyChat.Toggle()
    BuildFrame()
    if CopyChat.Frame:IsShown() then
        CopyChat.Frame:Hide()
    else
        CopyChat.Show()
    end
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------

local ok, err = pcall(function()
    HookChatFrames()
    HookErrors()
end)
if not ok then
    print("|cFFFF0000Loudmouth CopyChat Error:|r " .. tostring(err))
end

-- Slash commands: /ce and /copyerrors
SLASH_LOUDMOUTHCOPYERRORS1 = "/ce"
SLASH_LOUDMOUTHCOPYERRORS2 = "/copyerrors"
SlashCmdList["LOUDMOUTHCOPYERRORS"] = function()
    CopyChat.Toggle()
end
