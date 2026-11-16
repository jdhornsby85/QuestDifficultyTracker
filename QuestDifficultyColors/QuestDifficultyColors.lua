-- Quest Difficulty Colors
-- Tints quest pins on the world map by how hard the quest is for you:
-- grey (trivial) -> green -> yellow -> orange -> red, plus an optional skull on red.

local ADDON = ...
local PREFIX = "|cffff5555QDC|r: "

local defaults = {
    halo = true,   -- colored ring behind the pin
    tintIcon = true, -- tint the icon's glyph ("..." / "?" / "!")
    skull = true,  -- skull badge on the hardest quests
}

-- Difficulty buckets (match Enum.RelativeContentDifficulty: 0..4)
local TRIVIAL, EASY, FAIR, DIFFICULT, IMPOSSIBLE = 0, 1, 2, 3, 4

local COLORS = {
    [TRIVIAL]    = { 0.55, 0.55, 0.55 },
    [EASY]       = { 0.25, 0.80, 0.25 },
    [FAIR]       = { 1.00, 0.85, 0.00 },
    [DIFFICULT]  = { 1.00, 0.50, 0.15 },
    [IMPOSSIBLE] = { 1.00, 0.10, 0.10 },
}

local db
local ticker

---------------------------------------------------------------------------
-- Difficulty lookup
---------------------------------------------------------------------------

local function DifficultyFromLevel(questLevel)
    local diff = questLevel - UnitLevel("player")
    if diff >= 5 then return IMPOSSIBLE end
    if diff >= 3 then return DIFFICULT end
    if diff >= -2 then return FAIR end
    local grey = (UnitQuestTrivialLevelRange and UnitQuestTrivialLevelRange("player")) or 8
    if -diff <= grey then return EASY end
    return TRIVIAL
end

local function GetQuestLevel(questID)
    if not C_QuestLog then return nil end
    -- Same level the quest log shows in brackets, e.g. "[24]".
    if C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetInfo then
        local idx = C_QuestLog.GetLogIndexForQuestID(questID)
        local info = idx and C_QuestLog.GetInfo(idx)
        if info and info.level and info.level > 0 then return info.level end
    end
    if C_QuestLog.GetQuestDifficultyLevel then
        local lvl = C_QuestLog.GetQuestDifficultyLevel(questID)
        if lvl and lvl > 0 then return lvl end
    end
    return nil
end

-- Returns r, g, b, difficultyBucket for a quest, using the same color the
-- quest log uses for its title, so map icons match the log exactly.
local function GetQuestColor(questID)
    if not questID then return nil end
    local level = GetQuestLevel(questID)

    -- 1) Blizzard's quest-log color function (what colors "[24] An Unwelcome Guest" red).
    if level and GetQuestDifficultyColor then
        local ok, c = pcall(GetQuestDifficultyColor, level)
        if ok and type(c) == "table" and c.r then
            return c.r, c.g, c.b, DifficultyFromLevel(level)
        end
    end

    -- 2) Newer client-side difficulty rating + Blizzard's palette for it.
    if C_PlayerInfo and C_PlayerInfo.GetContentDifficultyQuestForPlayer then
        local ok, d = pcall(C_PlayerInfo.GetContentDifficultyQuestForPlayer, questID)
        if ok and type(d) == "number" then
            if GetDifficultyColor then
                local ok2, c = pcall(GetDifficultyColor, d)
                if ok2 and type(c) == "table" and c.r then return c.r, c.g, c.b, d end
            end
            local c = COLORS[d]
            if c then return c[1], c[2], c[3], d end
        end
    end

    -- 3) Our own palette from the level.
    if level then
        local d = DifficultyFromLevel(level)
        local c = COLORS[d]
        return c[1], c[2], c[3], d
    end
    return nil
end

---------------------------------------------------------------------------
-- Pin decoration
---------------------------------------------------------------------------

local function GetDecor(pin)
    local d = pin.__qdc
    if d then return d end
    d = {}

    local halo = pin:CreateTexture(nil, "BACKGROUND", nil, -8)
    halo:SetColorTexture(1, 1, 1, 1)
    halo:SetPoint("TOPLEFT", pin, "TOPLEFT", -5, 5)
    halo:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", 5, -5)
    local mask = pin:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(halo)
    halo:AddMaskTexture(mask)
    d.halo = halo

    local skull = pin:CreateTexture(nil, "OVERLAY", nil, 7)
    skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    skull:SetPoint("CENTER", pin, "TOPRIGHT", -1, -1)
    d.skull = skull

    pin.__qdc = d
    return d
end

local function GetGlyph(pin)
    -- POIButton-style pins keep their glyph in Display.Icon; older ones use .Texture
    return (pin.Display and pin.Display.Icon) or pin.Icon or pin.Texture
end

local function ClearPin(pin)
    local d = pin.__qdc
    if d then
        d.halo:Hide()
        d.skull:Hide()
    end
    if pin.__qdcTinted then
        local g = GetGlyph(pin)
        if g and g.SetVertexColor then g:SetVertexColor(1, 1, 1) end
        pin.__qdcTinted = nil
    end
end

local function DecoratePin(pin)
    local questID = pin.questID
    if not questID
        or (C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questID)) then
        ClearPin(pin)
        return
    end

    local r, gr, b, diff = GetQuestColor(questID)
    if not r then
        ClearPin(pin)
        return
    end

    local d = GetDecor(pin)

    if db.halo then
        d.halo:SetVertexColor(r, gr, b, 0.95)
        d.halo:Show()
    else
        d.halo:Hide()
    end

    local g = GetGlyph(pin)
    if g and g.SetVertexColor then
        if db.tintIcon then
            g:SetVertexColor(r, gr, b)
            pin.__qdcTinted = true
        elseif pin.__qdcTinted then
            g:SetVertexColor(1, 1, 1)
            pin.__qdcTinted = nil
        end
    end

    if db.skull and diff == IMPOSSIBLE then
        local s = math.max(10, (pin:GetWidth() or 20) * 0.6)
        d.skull:SetSize(s, s)
        d.skull:Show()
    else
        d.skull:Hide()
    end
end

local function ForEachMapPin(fn)
    local map = WorldMapFrame
    if not (map and map.pinPools) then return end
    for template, pool in pairs(map.pinPools) do
        if pool.EnumerateActive then
            for pin in pool:EnumerateActive() do
                fn(pin, template)
            end
        end
    end
end

-- Only the small round quest icons. The map also has full-size layers that carry a
-- questID (e.g. the blue quest-area "blob" overlay); those must never be decorated.
local MAX_ICON_SIZE = 64
local function IsQuestIconPin(pin, template)
    if not pin.questID then return false end
    template = tostring(template or "")
    if template:find("Blob") or template:find("Area") then return false end
    local w, h = pin:GetWidth() or 0, pin:GetHeight() or 0
    if w <= 0 or h <= 0 or w > MAX_ICON_SIZE or h > MAX_ICON_SIZE then return false end
    return true
end

local function Refresh()
    if not (WorldMapFrame and WorldMapFrame:IsShown()) then return end
    ForEachMapPin(function(pin, template)
        if IsQuestIconPin(pin, template) then
            DecoratePin(pin)
        elseif pin.__qdc or pin.__qdcTinted then
            ClearPin(pin)
        end
    end)
end

---------------------------------------------------------------------------
-- Hooking the world map
---------------------------------------------------------------------------

local hooked = false
local function HookWorldMap()
    if hooked or not WorldMapFrame then return end
    hooked = true

    WorldMapFrame:HookScript("OnShow", function()
        Refresh()
        if ticker then ticker:Cancel() end
        -- Pins are created/reused as quests update; a light refresh keeps colors right.
        ticker = C_Timer.NewTicker(0.3, Refresh)
    end)
    WorldMapFrame:HookScript("OnHide", function()
        if ticker then ticker:Cancel(); ticker = nil end
    end)
    if WorldMapFrame.OnMapChanged then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function() C_Timer.After(0, Refresh) end)
    end
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------

local function Toggle(key, label)
    db[key] = not db[key]
    print(PREFIX .. label .. " " .. (db[key] and "|cff55ff55on|r" or "|cffff5555off|r"))
    ForEachMapPin(function(pin) if pin.questID then ClearPin(pin) end end)
    Refresh()
end

SLASH_QUESTDIFFICULTYCOLORS1 = "/qdc"
SLASH_QUESTDIFFICULTYCOLORS2 = "/questdifficulty"
SlashCmdList.QUESTDIFFICULTYCOLORS = function(msg)
    if not db then
        QuestDifficultyColorsDB = QuestDifficultyColorsDB or {}
        db = QuestDifficultyColorsDB
        for k, v in pairs(defaults) do
            if db[k] == nil then db[k] = v end
        end
    end
    msg = (msg or ""):lower():match("^%s*(%S*)")
    if msg == "halo" then
        Toggle("halo", "Colored ring")
    elseif msg == "icon" then
        Toggle("tintIcon", "Icon tint")
    elseif msg == "skull" then
        Toggle("skull", "Skull on hardest quests")
    elseif msg == "pins" then
        -- Debug: list what's on the open map so we can target the right icons.
        if not (WorldMapFrame and WorldMapFrame:IsShown()) then
            print(PREFIX .. "open the world map first.")
            return
        end
        local counts = {}
        ForEachMapPin(function(pin, template)
            local key = template .. (pin.questID and " (has questID)" or "")
            counts[key] = (counts[key] or 0) + 1
        end)
        print(PREFIX .. "pins on this map:")
        for k, n in pairs(counts) do print("  " .. k .. " x" .. n) end
    else
        print(PREFIX .. "commands:")
        print("  /qdc halo  - toggle colored ring (" .. tostring(db.halo) .. ")")
        print("  /qdc icon  - toggle icon tint (" .. tostring(db.tintIcon) .. ")")
        print("  /qdc skull - toggle skull on red quests (" .. tostring(db.skull) .. ")")
        print("  /qdc pins  - debug: list pin types on the open map")
    end
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == ADDON then
        QuestDifficultyColorsDB = QuestDifficultyColorsDB or {}
        db = QuestDifficultyColorsDB
        for k, v in pairs(defaults) do
            if db[k] == nil then db[k] = v end
        end
    elseif event == "ADDON_LOADED" and name == "Blizzard_WorldMap" then
        HookWorldMap()
    elseif event == "PLAYER_LOGIN" then
        HookWorldMap()
        print(PREFIX .. "loaded. Type /qdc for options.")
    end
end)
