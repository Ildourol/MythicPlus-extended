local activeAffixes = {}
local AIO = AIO or require("AIO")
local L = {
    Text = function(self, category, key, localeIndex)
        if not self[category] or not self[category][key] then
            return key
        end
        
        if not self[category][key][localeIndex] then
            return self[category][key][0]
        end
        
        return self[category][key][localeIndex]
    end,
    Items = {},
    Dungeons = {},
    UI = {}
}
if AIO.AddAddon() then
    return
end

MythicPlusCharRunState = {
    active = false,
    mapId = nil,
    tier = nil,
    duration = nil,
    elapsed = nil,
    bossNames = {},
    killedBosses = {},
    potentialGain = 0,
    penalty = 0,
    bonus = 0,
    deaths = 0,
    maxDeaths = 0,
    enemyForces = {
        current = 0,
        required = 0,
        percentage = 0,
        completed = false
    },
    saveTime = nil
}

AIO.AddSavedVarChar("MythicPlusCharRunState")

local MythicHandlers = AIO.AddHandlers("AIO_Mythic", {})
local lastKeystoneLink = nil
local lastMapName = nil
local lastTierLevel = nil
local fmt, floor = string.format, math.floor
local localeDataReceived = false

function MythicHandlers.ReceiveLocaleData(_, category, entries)
    if type(entries) == "table" then
        L[category] = entries
        if L.Items and L.Dungeons and L.UI then
            localeDataReceived = true
            if MythicPlusFrame then
                UpdateLocalizedElements()
            end
        end
    end
end

function MythicGetText(category, key)
    local localeIndex = GetLocale() and MythicGetLocaleIndex() or 0
    return L:Text(category, key, localeIndex)
end

function MythicGetLocaleIndex()
    local locale = GetLocale()
    local localeMap = {
        ["enUS"] = 0, ["enGB"] = 0,
        ["koKR"] = 1,
        ["frFR"] = 2,
        ["deDE"] = 3,
        ["zhCN"] = 4,
        ["zhTW"] = 5,
        ["esES"] = 6,
        ["esMX"] = 7,
        ["ruRU"] = 8
    }
    return localeMap[locale] or 0
end

local UpdateScoreList, UpdateLeaderboardList, UpdateScoreFilters, UpdateLeaderboardFilters

function UpdateLocalizedElements()
    if DUNGEONS then
        for mapId, dungeonData in pairs(DUNGEONS) do
            dungeonData.name = MythicGetText("Dungeons", dungeonData.originalName)
        end
    end
    
    if MythicPlusFrame then
        if tabs then
            for i, tab in ipairs(tabs) do
                if i == 1 then
                    tab:SetText(MythicGetText("UI", "Overview"))
                elseif i == 2 then
                    tab:SetText(MythicGetText("UI", "Score"))
                elseif i == 3 then
                    tab:SetText(MythicGetText("UI", "Settings") or "Settings")
                elseif i == 4 then
                    tab:SetText(MythicGetText("UI", "Leaderboard"))
                end
            end
        end
        
        if MythicPlusFrame.overviewTitle then
            MythicPlusFrame.overviewTitle:SetText(MythicGetText("UI", "Overview"))
        end
        if MythicPlusFrame.scoreTitle then
            MythicPlusFrame.scoreTitle:SetText(MythicGetText("UI", "Score"))
        end
        if MythicPlusFrame.settingsTitle then
            MythicPlusFrame.settingsTitle:SetText(MythicGetText("UI", "Settings") or "Settings")
        end
        if MythicPlusFrame.leaderboardTitle then
            MythicPlusFrame.leaderboardTitle:SetText(MythicGetText("UI", "Leaderboard"))
        end
    
        if frame and frame.affixButtons then
            for _, button in ipairs(frame.affixButtons) do
                if button.affixName then
                    local isActive = frame.currentAffixes and 
                        (button.affixName == frame.currentAffixes[1] or 
                         button.affixName == frame.currentAffixes[2] or 
                         button.affixName == frame.currentAffixes[3])
                    
                    button.label:SetText((isActive and "|cff00ff00" or "") .. MythicGetText("UI", button.affixName))
                    button:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        local color = AFFIXES[button.affixName].color or "|cffffffff"
                        GameTooltip:SetText(color .. MythicGetText("UI", button.affixName) .. "|r")
                        GameTooltip:AddLine(AFFIXES[button.affixName].description or "", 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                end
            end
        end
        if UpdateScoreList then
            UpdateScoreList()
        end
        if UpdateLeaderboardList then
            UpdateLeaderboardList()
        end
        if UpdateScoreFilters then
            UpdateScoreFilters()
        end
        if UpdateLeaderboardFilters then
            UpdateLeaderboardFilters()
        end
        if MythicPlusFrame:IsVisible() and MythicPlusFrame.currentTab then
            SetActiveTab(MythicPlusFrame.currentTab)
        end
    end
end

local DUNGEONS = {
    -- Wrath of the Lich King
    [574] = { originalName = "Utgarde Keep", name = "Utgarde Keep", icon = "Interface\\Icons\\achievement_boss_svalasorrowgrave", expansion = "WotLK", mode = "Normal & Heroic" },
    [575] = { originalName = "Utgarde Pinnacle", name = "Utgarde Pinnacle", icon = "Interface\\Icons\\achievement_boss_kingymiron", expansion = "WotLK", mode = "Normal & Heroic" },
    [576] = { originalName = "The Nexus", name = "The Nexus", icon = "Interface\\Icons\\spell_frost_frozencore", expansion = "WotLK", mode = "Normal & Heroic" },
    [578] = { originalName = "The Oculus", name = "The Oculus", icon = "Interface\\Icons\\achievement_boss_eregos", expansion = "WotLK", mode = "Normal & Heroic" },
    [595] = { originalName = "The Culling of Stratholme", name = "The Culling of Stratholme", icon = "Interface\\Icons\\achievement_dungeon_cotstratholme_normal", expansion = "WotLK", mode = "Normal & Heroic" },
    [599] = { originalName = "Halls of Stone", name = "Halls of Stone", icon = "Interface\\Icons\\achievement_boss_sjonnir", expansion = "WotLK", mode = "Normal & Heroic" },
    [600] = { originalName = "Drak'Tharon Keep", name = "Drak'Tharon Keep", icon = "Interface\\Icons\\inv_bone_skull_04", expansion = "WotLK", mode = "Normal & Heroic" },
    [601] = { originalName = "Azjol-Nerub", name = "Azjol-Nerub", icon = "Interface\\Icons\\inv_misc_head_nerubian_01", expansion = "WotLK", mode = "Normal & Heroic" },
    [602] = { originalName = "Halls of Lightning", name = "Halls of Lightning", icon = "Interface\\Icons\\achievement_boss_archaedas", expansion = "WotLK", mode = "Normal & Heroic" },
    [604] = { originalName = "Gundrak", name = "Gundrak", icon = "Interface\\Icons\\achievement_boss_galdarah", expansion = "WotLK", mode = "Normal & Heroic" },
    [608] = { originalName = "The Violet Hold", name = "The Violet Hold", icon = "Interface\\Icons\\achievement_reputation_kirintor", expansion = "WotLK", mode = "Normal & Heroic" },
    [619] = { originalName = "Ahn'kahet: The Old Kingdom", name = "Ahn'kahet: The Old Kingdom", icon = "Interface\\Icons\\achievement_boss_yoggsaron_01", expansion = "WotLK", mode = "Normal & Heroic" },
    [632] = { originalName = "The Forge of Souls", name = "The Forge of Souls", icon = "Interface\\Icons\\achievement_boss_devourerofsouls", expansion = "WotLK", mode = "Normal & Heroic" },
    [650] = { originalName = "Trial of the Champion", name = "Trial of the Champion", icon = "Interface\\Icons\\achievement_reputation_argentcrusader", expansion = "WotLK", mode = "Normal & Heroic" },
    [658] = { originalName = "Pit of Saron", name = "Pit of Saron", icon = "Interface\\Icons\\achievement_boss_scourgelordtyrannus", expansion = "WotLK", mode = "Normal & Heroic" },
    [668] = { originalName = "Halls of Reflection", name = "Halls of Reflection", icon = "Interface\\Icons\\achievement_dungeon_icecrown_frostmourne", expansion = "WotLK", mode = "Normal & Heroic" },

    -- Vanilla Dungeons
    [389] = { originalName = "Ragefire Chasm", name = "Ragefire Chasm", icon = "Interface\\Icons\\spell_fire_fire", expansion = "Vanilla", mode = "Normal" },
    [36]  = { originalName = "Deadmines", name = "Deadmines", icon = "Interface\\Icons\\inv_misc_gear_01", expansion = "Vanilla", mode = "Normal" },
    [43]  = { originalName = "Wailing Caverns", name = "Wailing Caverns", icon = "Interface\\Icons\\spell_nature_healingtouch", expansion = "Vanilla", mode = "Normal" },
    [33]  = { originalName = "Shadowfang Keep", name = "Shadowfang Keep", icon = "Interface\\Icons\\spell_shadow_haunting", expansion = "Vanilla", mode = "Normal" },
    [48]  = { originalName = "Blackfathom Deeps", name = "Blackfathom Deeps", icon = "Interface\\Icons\\spell_frost_frostbolt02", expansion = "Vanilla", mode = "Normal" },
    [34]  = { originalName = "The Stockade", name = "The Stockade", icon = "Interface\\Icons\\inv_misc_key_03", expansion = "Vanilla", mode = "Normal" },
    [90]  = { originalName = "Gnomeregan", name = "Gnomeregan", icon = "Interface\\Icons\\inv_misc_gear_08", expansion = "Vanilla", mode = "Normal" },
    [47]  = { originalName = "Razorfen Kraul", name = "Razorfen Kraul", icon = "Interface\\Icons\\inv_weapon_shortblade_08", expansion = "Vanilla", mode = "Normal" },
    [129] = { originalName = "Razorfen Downs", name = "Razorfen Downs", icon = "Interface\\Icons\\inv_misc_bone_01", expansion = "Vanilla", mode = "Normal" },
    [189] = { originalName = "Scarlet Monastery", name = "Scarlet Monastery", icon = "Interface\\Icons\\spell_holy_sealofwrath", expansion = "Vanilla", mode = "Normal" },
    [70]  = { originalName = "Uldaman", name = "Uldaman", icon = "Interface\\Icons\\spell_nature_strength", expansion = "Vanilla", mode = "Normal" },
    [209] = { originalName = "Zul'Farrak", name = "Zul'Farrak", icon = "Interface\\Icons\\inv_misc_stonetablet_02", expansion = "Vanilla", mode = "Normal" },
    [349] = { originalName = "Maraudon", name = "Maraudon", icon = "Interface\\Icons\\spell_nature_elementalshields", expansion = "Vanilla", mode = "Normal" },
    [109] = { originalName = "Temple of Atal'Hakkar", name = "Temple of Atal'Hakkar", icon = "Interface\\Icons\\inv_misc_head_dragon_green", expansion = "Vanilla", mode = "Normal" },
    [230] = { originalName = "Blackrock Depths", name = "Blackrock Depths", icon = "Interface\\Icons\\inv_pick_02", expansion = "Vanilla", mode = "Normal" },
    [229] = { originalName = "Blackrock Spire", name = "Blackrock Spire", icon = "Interface\\Icons\\inv_misc_head_dragon_black", expansion = "Vanilla", mode = "Normal" },
    [429] = { originalName = "Dire Maul", name = "Dire Maul", icon = "Interface\\Icons\\inv_misc_book_09", expansion = "Vanilla", mode = "Normal" },
    [289] = { originalName = "Scholomance", name = "Scholomance", icon = "Interface\\Icons\\spell_shadow_antimagicshell", expansion = "Vanilla", mode = "Normal" },
    [329] = { originalName = "Stratholme", name = "Stratholme", icon = "Interface\\Icons\\spell_shadow_deathanddecay", expansion = "Vanilla", mode = "Normal" },

    -- The Burning Crusade
    [543] = { originalName = "Hellfire Ramparts", name = "Hellfire Ramparts", icon = "Interface\\Icons\\spell_fire_incinerate", expansion = "TBC", mode = "Normal & Heroic" },
    [542] = { originalName = "The Blood Furnace", name = "The Blood Furnace", icon = "Interface\\Icons\\spell_shadow_bloodboil", expansion = "TBC", mode = "Normal & Heroic" },
    [540] = { originalName = "The Shattered Halls", name = "The Shattered Halls", icon = "Interface\\Icons\\inv_weapon_shortblade_27", expansion = "TBC", mode = "Normal & Heroic" },
    [547] = { originalName = "The Slave Pens", name = "The Slave Pens", icon = "Interface\\Icons\\spell_nature_healingtouch", expansion = "TBC", mode = "Normal & Heroic" },
    [546] = { originalName = "The Underbog", name = "The Underbog", icon = "Interface\\Icons\\spell_nature_stranglevines", expansion = "TBC", mode = "Normal & Heroic" },
    [545] = { originalName = "The Steamvault", name = "The Steamvault", icon = "Interface\\Icons\\spell_frost_summonwaterelemental", expansion = "TBC", mode = "Normal & Heroic" },
    [557] = { originalName = "Mana-Tombs", name = "Mana-Tombs", icon = "Interface\\Icons\\spell_arcane_manafeeder", expansion = "TBC", mode = "Normal & Heroic" },
    [558] = { originalName = "Auchenai Crypts", name = "Auchenai Crypts", icon = "Interface\\Icons\\spell_shadow_curseoftounges", expansion = "TBC", mode = "Normal & Heroic" },
    [556] = { originalName = "Sethekk Halls", name = "Sethekk Halls", icon = "Interface\\Icons\\ability_hunter_beastcall", expansion = "TBC", mode = "Normal & Heroic" },
    [555] = { originalName = "Shadow Labyrinth", name = "Shadow Labyrinth", icon = "Interface\\Icons\\spell_shadow_mindflay", expansion = "TBC", mode = "Normal & Heroic" },
    [560] = { originalName = "Old Hillsbrad Foothills", name = "Old Hillsbrad Foothills", icon = "Interface\\Icons\\inv_misc_head_human_01", expansion = "TBC", mode = "Normal & Heroic" },
    [269] = { originalName = "The Black Morass", name = "The Black Morass", icon = "Interface\\Icons\\spell_nature_timestop", expansion = "TBC", mode = "Normal & Heroic" },
    [553] = { originalName = "The Botanica", name = "The Botanica", icon = "Interface\\Icons\\ability_druid_treeoflife", expansion = "TBC", mode = "Normal & Heroic" },
    [552] = { originalName = "The Arcatraz", name = "The Arcatraz", icon = "Interface\\Icons\\spell_shadow_shadowward", expansion = "TBC", mode = "Normal & Heroic" },
    [554] = { originalName = "The Mechanar", name = "The Mechanar", icon = "Interface\\Icons\\inv_gizmo_02", expansion = "TBC", mode = "Normal & Heroic" },
    [585] = { originalName = "Magisters' Terrace", name = "Magisters' Terrace", icon = "Interface\\Icons\\inv_misc_gem_bloodstone_02", expansion = "TBC", mode = "Normal & Heroic" },
}

AIO.Handle("AIO_Mythic", "RequestLocaleData", "Items")
AIO.Handle("AIO_Mythic", "RequestLocaleData", "Dungeons")
AIO.Handle("AIO_Mythic", "RequestLocaleData", "UI")
AIO.Handle("AIO_Mythic", "RequestRunState")

local DUNGEON_ORDER = {
    -- WotLK
    574, 575, 576, 578,
    595, 599, 600, 601,
    602, 604, 608, 619,
    632, 650, 658, 668,
    -- Vanilla
    389, 36, 43, 33, 48,
    34, 90, 47, 129, 189,
    70, 209, 349, 109, 230,
    229, 429, 289, 329,
    -- TBC
    543, 542, 540, 547,
    546, 545, 557, 558,
    556, 555, 560, 269,
    553, 552, 554, 585
}

local AFFIXES = {
    ["Enrage"] = { icon = "Interface\\Icons\\spell_nature_shamanrage", color = "|cffff0000", description = function() return MythicGetText("UI", "Enrage Description") end },
    ["Rejuvenating"] = { icon = "Interface\\Icons\\ability_druid_empoweredrejuvination", color = "|cff00ff00", description = function() return MythicGetText("UI", "Rejuvenating Description") end },
    ["Turtling"] = { icon = "Interface\\Icons\\ability_warrior_shieldmastery", color = "|cffffff00", description = function() return MythicGetText("UI", "Turtling Description") end },
    ["Shamanism"] = { icon = "Interface\\Icons\\spell_fire_totemofwrath", color = "|cffa335ee", description = function() return MythicGetText("UI", "Shamanism Description") end },
    ["Magus"] = { icon = "Interface\\Icons\\ability_mage_hotstreak", color = "|cff3399ff", description = function() return MythicGetText("UI", "Magus Description") end },
    ["Priest Empowered"] = { icon = "Interface\\Icons\\spell_holy_searinglightpriest", color = "|cffcccccc", description = function() return MythicGetText("UI", "Priest Empowered Description") end },
    ["Demonism"] = { icon = "Interface\\Icons\\ability_warlock_demonicpower", color = "|cff8b0000", description = function() return MythicGetText("UI", "Demonism Description") end },
    ["Falling Stars"] = { icon = "Interface\\Icons\\ability_druid_starfall", color = "|cff66ccff", description = function() return MythicGetText("UI", "Falling Stars Description") end },
}

function MythicHandlers.ReceiveMapNameAndTier(_, mapName, tier)
    local originalMapName = mapName
    for id, dungeon in pairs(DUNGEONS) do
        if dungeon.originalName == mapName then
            mapName = MythicGetText("Dungeons", dungeon.originalName)
            break
        end
    end
    
    lastMapName = mapName
    lastTierLevel = tier

    if GameTooltip:IsShown() then
        local name, link = GameTooltip:GetItem()
        if link and name and (string.find(name, "Mythic Keystone") or string.find(name, MythicGetText("Items", "Mythic Keystone"))) then
            GameTooltip:Hide()
            GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
        end
    end
end

local lineAdded = false
function OnTooltipSetItem(tooltip)
    local name, link = tooltip:GetItem()
    local englishName = "Mythic Keystone"
    local localizedName = MythicGetText("Items", "Mythic Keystone")
    
    if not name or (not string.find(name, englishName) and not string.find(name, localizedName)) then 
        return 
    end
    
    if link ~= lastKeystoneLink then
        lastKeystoneLink = link
        lastMapName = "Loading..."
        lastTierLevel = "Loading..."
        AIO.Handle("AIO_Mythic", "RequestMapNameAndTier")
    end
    local line = _G[tooltip:GetName() .. "TextLeft2"]
    if line then
        local tierText = lastTierLevel and lastTierLevel ~= "Loading..." and ("+" .. lastTierLevel) or ""
        line:SetText("|cffa335ee" .. MythicGetText("UI", "Mythic") .. tierText .. " |r" .. (lastMapName or "Loading..."))
        line:Show()
        tooltip:Show()
    end
end

local function OnTooltipCleared(tooltip)
    lineAdded = false
end

GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)

local mythicMiniButton = CreateFrame("Button", "MythicPlusMiniButton", Minimap)
mythicMiniButton:SetSize(24, 24)
mythicMiniButton:SetFrameStrata("MEDIUM")
mythicMiniButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

mythicMiniButton:SetNormalTexture("Interface\\AddOns\\Blizzard_AchievementUI\\UI-Achievement-MinimapButton")
mythicMiniButton:SetPushedTexture("Interface\\AddOns\\Blizzard_AchievementUI\\UI-Achievement-MinimapButton-Down")

local icon = mythicMiniButton:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\Icons\\achievement_bg_wineos_underxminutes")
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
icon:SetAllPoints(mythicMiniButton)

local border = mythicMiniButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(64, 64)
border:SetPoint("CENTER", mythicMiniButton, "CENTER", 12, -12)

mythicMiniButton:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", -20, 70)

mythicMiniButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(MythicGetText("UI", "Mythic+"))
    if self.hasVaultLoot then
        GameTooltip:AddLine(MythicGetText("UI", "There is loot in your Vault in Dalaran City"), 1, 1, 0)
    end
    GameTooltip:Show()
end)
mythicMiniButton:SetScript("OnLeave", GameTooltip_Hide)

mythicMiniButton:SetScript("OnClick", function()
    if MythicPlusFrame:IsShown() then
        PlaySound("igCharacterInfoClose")
        MythicPlusFrame:Hide()
    else
        PlaySound("igCharacterInfoOpen")
        MythicPlusFrame:Show()
    end
end)

function MythicHandlers.ReceiveWeeklyAffixes(_, affix1, affix2, affix3)
    local function colorize(name)
        return (AFFIXES[name].color or "|cffffffff") .. MythicGetText("UI", name) .. "|r"
    end

    local text = MythicGetText("UI", "This week's affixes:") .. " " ..
        colorize(affix1) .. ", " ..
        colorize(affix2) .. ", " ..
        colorize(affix3)

    MythicPlusFrame.affixText:SetText(text)
    
    MythicPlusFrame.currentAffixes = {affix1, affix2, affix3}

    for _, button in ipairs(MythicPlusFrame.affixButtons) do
        local name = button.affixName
        local label = button.label
        local isActive = name == affix1 or name == affix2 or name == affix3
        label:SetText((isActive and "|cff00ff00" or "") .. MythicGetText("UI", name))
    end
end

MythicPlusFrame = CreateFrame("Frame", "MythicPlusFrame", UIParent)
local frame = MythicPlusFrame

if localeDataReceived then
    UpdateLocalizedElements()
end

frame:SetSize(720, 480)
frame:SetScale(1.25)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetToplevel(true)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnHide", function(self)PlaySound("igCharacterInfoClose") self:StopMovingOrSizing() end)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

for _, region in ipairs({frame:GetRegions()}) do
    if region:GetObjectType() == "Texture" then
        region:Hide()
    end
end

local darkBG = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
darkBG:SetAllPoints(frame)
darkBG:SetTexture(0.04, 0.04, 0.06, 0.78)

local paperBG = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
paperBG:SetTexture("Interface\\MythicPlus\\textures\\Paper")
paperBG:SetAllPoints(frame)
paperBG:SetTexCoord(0, 1, 75/1024, (1024-75)/1024)
paperBG:SetAlpha(0.35)

local borderSize = 167
local borderCornerTexCoordW = 167/256
local borderCornerTexCoordH = 168/256
local borderExpansion = math.floor(borderSize * 0.1)

local topLeftCorner = frame:CreateTexture(nil, "ARTWORK")
topLeftCorner:SetTexture("Interface\\MythicPlus\\textures\\Border")
topLeftCorner:SetSize(borderSize, borderSize)
topLeftCorner:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderExpansion, borderExpansion)
topLeftCorner:SetTexCoord(0, borderCornerTexCoordW, 0, borderCornerTexCoordH)

local topRightCorner = frame:CreateTexture(nil, "ARTWORK")
topRightCorner:SetTexture("Interface\\MythicPlus\\textures\\Border")
topRightCorner:SetSize(borderSize, borderSize)
topRightCorner:SetPoint("TOPRIGHT", frame, "TOPRIGHT", borderExpansion, borderExpansion)
topRightCorner:SetTexCoord(borderCornerTexCoordW, 0, 0, borderCornerTexCoordH)

local bottomLeftCorner = frame:CreateTexture(nil, "ARTWORK")
bottomLeftCorner:SetTexture("Interface\\MythicPlus\\textures\\Border")
bottomLeftCorner:SetSize(borderSize, borderSize)
bottomLeftCorner:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -borderExpansion, -borderExpansion)
bottomLeftCorner:SetTexCoord(0, borderCornerTexCoordW, borderCornerTexCoordH, 0)

local bottomRightCorner = frame:CreateTexture(nil, "ARTWORK")
bottomRightCorner:SetTexture("Interface\\MythicPlus\\textures\\Border")
bottomRightCorner:SetSize(borderSize, borderSize)
bottomRightCorner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderExpansion, -borderExpansion)
bottomRightCorner:SetTexCoord(borderCornerTexCoordW, 0, borderCornerTexCoordH, 0)

local topBorder = frame:CreateTexture(nil, "ARTWORK")
topBorder:SetTexture("Interface\\MythicPlus\\textures\\Border_Top")
topBorder:SetHeight(32)
topBorder:SetPoint("TOPLEFT", topLeftCorner, "TOPRIGHT", 0, 0)
topBorder:SetPoint("TOPRIGHT", topRightCorner, "TOPLEFT", 0, 0)
local topBorderWidth = 720 + (borderExpansion * 2) - (borderSize * 2)
local topTexCoordRight = math.min(1.0, topBorderWidth / 1024)
topBorder:SetTexCoord(0, topTexCoordRight, 0, 1)

local bottomBorder = frame:CreateTexture(nil, "ARTWORK")
bottomBorder:SetTexture("Interface\\MythicPlus\\textures\\Border_Bottom")
bottomBorder:SetHeight(32)
bottomBorder:SetPoint("BOTTOMLEFT", bottomLeftCorner, "BOTTOMRIGHT", 0, 0)
bottomBorder:SetPoint("BOTTOMRIGHT", bottomRightCorner, "BOTTOMLEFT", 0, 0)
local bottomTexCoordRight = math.min(1.0, topBorderWidth / 1024)
bottomBorder:SetTexCoord(0, bottomTexCoordRight, 0, 1)

local leftBorder = frame:CreateTexture(nil, "ARTWORK")
leftBorder:SetTexture("Interface\\MythicPlus\\textures\\Border_Left")
leftBorder:SetWidth(32)
leftBorder:SetPoint("TOPLEFT", topLeftCorner, "BOTTOMLEFT", -1, 0)
leftBorder:SetPoint("BOTTOMLEFT", bottomLeftCorner, "TOPLEFT", -1, 0)
local leftBorderHeight = 480 + (borderExpansion * 2) - (borderSize * 2)
local leftTexCoordBottom = math.min(1.0, leftBorderHeight / 1024)
leftBorder:SetTexCoord(0, 1, 0, leftTexCoordBottom)

local rightBorder = frame:CreateTexture(nil, "ARTWORK")
rightBorder:SetTexture("Interface\\MythicPlus\\textures\\Border_Right")
rightBorder:SetWidth(32)
rightBorder:SetPoint("TOPRIGHT", topRightCorner, "BOTTOMRIGHT", 1, 0)
rightBorder:SetPoint("BOTTOMRIGHT", bottomRightCorner, "TOPRIGHT", 1, 0)
local rightTexCoordBottom = math.min(1.0, leftBorderHeight / 1024)
rightBorder:SetTexCoord(0, 1, 0, rightTexCoordBottom)

table.insert(UISpecialFrames, "MythicPlusFrame")
frame:Hide()

local tabBackground = CreateFrame("Frame", nil, frame)
tabBackground:SetSize(120, 400)
tabBackground:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -20)

local function CreateStyledTabButton(parent, text, index, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(100, 32)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -20 - ((index - 1) * 35))
    button:SetText(text)
    button:SetNormalFontObject("GameFontNormal")
    button:GetNormalTexture():SetVertexColor(0.8, 0.2, 0.2, 1)
    button:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3, 1)
    button:GetPushedTexture():SetVertexColor(0.6, 0.1, 0.1, 1)
    button.isSelected = false
    button:SetScript("OnClick", function()
        onClick(index)
    end)

    return button
end

local function CreateBannerTitle(parent, text, anchorPoint)
    local banner = parent:CreateTexture(nil, "OVERLAY")
    banner:SetTexture("Interface\\MythicPlus\\textures\\Banner")
    banner:SetSize(256, 64)
    banner:SetPoint("TOP", parent, "TOP", 0, anchorPoint or 0)
    
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("CENTER", banner, "CENTER", 0, 0)
    title:SetText(text)
    title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    title:SetTextColor(1, 1, 1)
    
    return banner, title
end

--------------------------------------------------------------------------------
-- TAB 1: OVERVIEW CONTAINER
--------------------------------------------------------------------------------
local overviewContainer = CreateFrame("Frame", nil, frame)
overviewContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, -15)
overviewContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
frame.overviewContainer = overviewContainer

local overviewBanner, overviewTitle = CreateBannerTitle(overviewContainer, MythicGetText("UI", "Overview"), -5)
frame.overviewTitle = overviewTitle
frame.overviewBanner = overviewBanner

local affixText = overviewContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
affixText:SetPoint("TOP", overviewBanner, "BOTTOM", 0, -10)
affixText:SetJustifyH("CENTER")
affixText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
affixText:SetText(MythicGetText("UI", "This week's affixes:") .. " Loading...")
frame.affixText = affixText

local affixNames = {
    "Enrage", "Rejuvenating", "Turtling", "Shamanism",
    "Magus", "Priest Empowered", "Demonism", "Falling Stars"
}

frame.affixButtons = {}
local buttonSize = 80
local buttonSpacing = 30
local columns = 4
local totalWidth = columns * buttonSize + (columns - 1) * buttonSpacing
local startX = -(totalWidth / 2) + 40

for i, name in ipairs(affixNames) do
    local button = CreateFrame("Button", nil, overviewContainer)
    button:SetSize(buttonSize, buttonSize)

    local row = math.floor((i - 1) / columns)
    local col = (i - 1) % columns
    button:SetPoint(
        "TOP",
        affixText,
        "BOTTOM",
        startX + col * (buttonSize + buttonSpacing),
        -40 - row * (buttonSize + buttonSpacing)
    )

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexture(AFFIXES[name].icon or "Interface\\Icons\\spell_nature_polymorph")

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", button, "BOTTOM", 0, -2)
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    label:SetText(name)

    button.affixName = name
    button.label = label

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local color = AFFIXES[name].color or "|cffffffff"
        GameTooltip:SetText(color .. MythicGetText("UI", name) .. "|r")
        local description = AFFIXES[name].description
        if type(description) == "function" then
            description = description()
        end
        GameTooltip:AddLine(description or "", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.affixButtons[i] = button
end

frame.scoreButtons = {}
frame.leaderboardButtons = {}

local currentDungeonScores = {}
local currentTotalPoints = 0
local currentTopThree = {}
local currentDungeonTop = {}

local function GetFilteredDungeons(filterKey)
    local list = {}
    for _, mapId in ipairs(DUNGEON_ORDER) do
        local data = DUNGEONS[mapId]
        if data then
            if filterKey == "ALL" or data.expansion == filterKey then
                table.insert(list, mapId)
            end
        end
    end
    return list
end

local function GetExpansionColor(exp)
    if exp == "Vanilla" then
        return "|cffff9900"
    elseif exp == "TBC" then
        return "|cff33ff33"
    elseif exp == "WotLK" then
        return "|cff00ccff"
    end
    return "|cffffffff"
end

local function GetModeColoredText(mode)
    if mode == "Normal & Heroic" then
        return "|cffffd100" .. MythicGetText("UI", "Normal & Heroic") .. "|r"
    else
        return "|cffaaaaaa" .. MythicGetText("UI", "Normal") .. "|r"
    end
end

local function UpdateFilterButtonStyles(buttons, activeKey)
    for key, btn in pairs(buttons) do
        local norm = btn:GetNormalTexture()
        local high = btn:GetHighlightTexture()
        if key == activeKey then
            if norm then norm:SetVertexColor(1, 0.4, 0.4, 1) end
            if high then high:SetVertexColor(1, 0.6, 0.6, 1) end
        else
            if norm then norm:SetVertexColor(0.5, 0.15, 0.15, 1) end
            if high then high:SetVertexColor(0.8, 0.3, 0.3, 1) end
        end
    end
end

local filterDefs = {
    { key = "ALL", text = "All (51)", loc = "All" },
    { key = "WotLK", text = "WotLK (16)", loc = "Wrath of the Lich King" },
    { key = "TBC", text = "TBC (16)", loc = "The Burning Crusade" },
    { key = "Vanilla", text = "Vanilla (19)", loc = "Vanilla" },
}

--------------------------------------------------------------------------------
-- TAB 2: SCORE CONTAINER (Dropdown Filter + Native Scrolling Window)
--------------------------------------------------------------------------------
local scoreContainer = CreateFrame("Frame", nil, frame)
scoreContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, -15)
scoreContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
scoreContainer:Hide()
frame.scoreContainer = scoreContainer

local scoreBanner, scoreTitle = CreateBannerTitle(scoreContainer, MythicGetText("UI", "Score"), -5)
frame.scoreTitle = scoreTitle
frame.scoreBanner = scoreBanner

local scoreText = scoreContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
scoreText:SetPoint("TOP", scoreBanner, "BOTTOM", 0, -2)
scoreText:SetText(MythicGetText("UI", "Score:") .. " Loading...")
frame.scoreText = scoreText

local currentScoreFilter = "ALL"
local scoreScrollOffset = 0
local SCORE_VISIBLE_ROWS = 12

-- Dropdown Menu for Expansion Filtering
local scoreFilterDropDown = CreateFrame("Frame", "MythicScoreFilterDropDown", scoreContainer, "UIDropDownMenuTemplate")
scoreFilterDropDown:SetPoint("TOPLEFT", scoreContainer, "TOPLEFT", 0, -64)
UIDropDownMenu_SetWidth(scoreFilterDropDown, 130)
UIDropDownMenu_SetText(scoreFilterDropDown, MythicGetText("UI", "All") .. " (51)")

local function UpdateScoreFilterText()
    local name = "All (51)"
    for _, def in ipairs(filterDefs) do
        if def.key == currentScoreFilter then
            name = def.text
            break
        end
    end
    UIDropDownMenu_SetText(scoreFilterDropDown, name)
end

local function ScoreDropDown_OnClick(self)
    UIDropDownMenu_SetSelectedID(scoreFilterDropDown, self:GetID())
    currentScoreFilter = self.value
    scoreScrollOffset = 0
    UpdateScoreFilterText()
    if UpdateScoreList then UpdateScoreList() end
end

UIDropDownMenu_Initialize(scoreFilterDropDown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for _, def in ipairs(filterDefs) do
        info.text = def.text
        info.value = def.key
        info.func = ScoreDropDown_OnClick
        info.checked = (def.key == currentScoreFilter)
        UIDropDownMenu_AddButton(info, level)
    end
end)

-- Score Table Header
local scoreHeader = CreateFrame("Frame", nil, scoreContainer)
scoreHeader:SetSize(520, 20)
scoreHeader:SetPoint("TOPLEFT", scoreContainer, "TOPLEFT", 10, -96)

local scoreHeaderBg = scoreHeader:CreateTexture(nil, "BACKGROUND")
scoreHeaderBg:SetAllPoints()
scoreHeaderBg:SetTexture(0, 0, 0, 0.5)

local scoreHName = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scoreHName:SetPoint("LEFT", scoreHeader, "LEFT", 12, 0)
scoreHName:SetText(MythicGetText("UI", "Dungeon") or "Dungeon")

local scoreHExp = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scoreHExp:SetPoint("CENTER", scoreHeader, "LEFT", 235, 0)
scoreHExp:SetText(MythicGetText("UI", "Expansion") or "Expansion")

local scoreHMode = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scoreHMode:SetPoint("CENTER", scoreHeader, "LEFT", 325, 0)
scoreHMode:SetText(MythicGetText("UI", "Difficulty") or "Difficulty")

local scoreHScore = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scoreHScore:SetPoint("RIGHT", scoreHeader, "RIGHT", -76, 0)
scoreHScore:SetText(MythicGetText("UI", "Rating") or "Rating")

local scoreHTp = scoreHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scoreHTp:SetPoint("RIGHT", scoreHeader, "RIGHT", -14, 0)
scoreHTp:SetText(MythicGetText("UI", "Portal") or "Portal")

-- Score ScrollBar (Native Blizzard UIPanelScrollBarTemplate)
local scoreSlider = CreateFrame("Slider", "MythicScoreScrollBar", scoreContainer, "UIPanelScrollBarTemplate")
scoreSlider:SetSize(16, (SCORE_VISIBLE_ROWS * 24) - 32)
scoreSlider:SetPoint("TOPLEFT", scoreContainer, "TOPLEFT", 535, -120 - 16)
scoreSlider:SetMinMaxValues(0, 0)
scoreSlider:SetValueStep(1)
scoreSlider:SetValue(0)

local scoreUpBtn = _G["MythicScoreScrollBarScrollUpButton"]
if scoreUpBtn then
    scoreUpBtn:SetScript("OnClick", function()
        scoreSlider:SetValue(scoreSlider:GetValue() - 1)
        PlaySound("UChatScrollButton")
    end)
end

local scoreDownBtn = _G["MythicScoreScrollBarScrollDownButton"]
if scoreDownBtn then
    scoreDownBtn:SetScript("OnClick", function()
        scoreSlider:SetValue(scoreSlider:GetValue() + 1)
        PlaySound("UChatScrollButton")
    end)
end

local function ScrollScore(delta)
    local minV, maxV = scoreSlider:GetMinMaxValues()
    local cur = scoreSlider:GetValue()
    local nxt = math.min(maxV, math.max(minV, cur - delta))
    if nxt ~= cur then
        scoreSlider:SetValue(nxt)
    end
end

-- Score Rows
local scoreRows = {}
for i = 1, SCORE_VISIBLE_ROWS do
    local row = CreateFrame("Button", nil, scoreContainer)
    row:SetSize(520, 23)
    row:SetPoint("TOPLEFT", scoreContainer, "TOPLEFT", 10, -120 - ((i - 1) * 24))

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, (i % 2 == 0) and 0.25 or 0.12)
    row.bg = bg

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetBlendMode("ADD")

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetPoint("LEFT", row, "LEFT", 12, 0)
    nameText:SetWidth(190)
    nameText:SetJustifyH("LEFT")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    row.nameText = nameText

    local expText = row:CreateFontString(nil, "OVERLAY")
    expText:SetPoint("CENTER", row, "LEFT", 235, 0)
    expText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    row.expText = expText

    local modeText = row:CreateFontString(nil, "OVERLAY")
    modeText:SetPoint("CENTER", row, "LEFT", 325, 0)
    modeText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    row.modeText = modeText

    local scoreVal = row:CreateFontString(nil, "OVERLAY")
    scoreVal:SetPoint("RIGHT", row, "RIGHT", -76, 0)
    scoreVal:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    row.scoreVal = scoreVal

    local tpBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    tpBtn:SetSize(58, 18)
    tpBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    tpBtn:SetFrameLevel(row:GetFrameLevel() + 5)
    tpBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    tpBtn:EnableMouse(true)
    tpBtn:SetText(MythicGetText("UI", "Teleport") or "Teleport")
    local tpBtnText = tpBtn:GetFontString()
    if tpBtnText then
        tpBtnText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    end
    tpBtn:SetScript("OnClick", function(self)
        local mapId = self.mapId or (self:GetParent() and self:GetParent().mapId)
        if mapId then
            PlaySound("igMainMenuOption")
            AIO.Handle("AIO_Mythic", "TeleportToDungeon", mapId)
        end
    end)
    tpBtn:SetScript("OnEnter", function(self)
        local mapId = self.mapId or (self:GetParent() and self:GetParent().mapId)
        if not mapId then return end
        local data = DUNGEONS[mapId]
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local dName = data and MythicGetText("Dungeons", data.originalName) or "Dungeon"
        GameTooltip:SetText(MythicGetText("UI", "Teleport to") or "Teleport to", 1, 1, 1)
        GameTooltip:AddLine(dName, 1, 0.82, 0)
        GameTooltip:Show()
    end)
    tpBtn:SetScript("OnLeave", GameTooltip_Hide)
    row.tpBtn = tpBtn

    row:RegisterForClicks()
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta) ScrollScore(delta) end)

    row:SetScript("OnEnter", function(self)
        if not self.mapId then return end
        local data = DUNGEONS[self.mapId]
        if not data then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(MythicGetText("Dungeons", data.originalName), 1, 1, 1)
        local expLoc = data.expansion == "WotLK" and MythicGetText("UI", "Wrath of the Lich King") 
                       or data.expansion == "TBC" and MythicGetText("UI", "The Burning Crusade") 
                       or MythicGetText("UI", "Vanilla")
        GameTooltip:AddLine(MythicGetText("UI", "Expansion:") .. " " .. expLoc, 0.8, 0.8, 0.8)
        GameTooltip:AddLine(MythicGetText("UI", "Supported Modes:") .. " " .. MythicGetText("UI", data.mode), 0.8, 0.8, 0.8)
        local s = currentDungeonScores[tostring(self.mapId)] or 0
        GameTooltip:AddLine(MythicGetText("UI", "Personal Score:") .. " " .. string.format("%.2f", s), 1, 0.82, 0)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    scoreRows[i] = row
end
frame.scoreButtons = scoreRows

scoreContainer:EnableMouseWheel(true)
scoreContainer:SetScript("OnMouseWheel", function(_, delta) ScrollScore(delta) end)
scoreSlider:EnableMouseWheel(true)
scoreSlider:SetScript("OnMouseWheel", function(_, delta) ScrollScore(delta) end)

UpdateScoreList = function(fromSlider)
    local filtered = GetFilteredDungeons(currentScoreFilter)
    local maxOffset = math.max(0, #filtered - SCORE_VISIBLE_ROWS)
    scoreSlider:SetMinMaxValues(0, maxOffset)
    if scoreScrollOffset > maxOffset then
        scoreScrollOffset = maxOffset
    end
    if not fromSlider then
        scoreSlider:SetValue(scoreScrollOffset)
    end

    if maxOffset > 0 then
        scoreSlider:Show()
    else
        scoreSlider:Hide()
    end

    if scoreUpBtn then
        if scoreScrollOffset <= 0 then scoreUpBtn:Disable() else scoreUpBtn:Enable() end
    end
    if scoreDownBtn then
        if scoreScrollOffset >= maxOffset then scoreDownBtn:Disable() else scoreDownBtn:Enable() end
    end

    for i = 1, SCORE_VISIBLE_ROWS do
        local dataIndex = scoreScrollOffset + i
        local mapId = filtered[dataIndex]
        local row = scoreRows[i]
        if mapId and DUNGEONS[mapId] then
            local data = DUNGEONS[mapId]
            row.mapId = mapId
            if row.tpBtn then
                row.tpBtn.mapId = mapId
                row.tpBtn:Show()
            end
            row.nameText:SetText(MythicGetText("Dungeons", data.originalName))
            row.expText:SetText(GetExpansionColor(data.expansion) .. data.expansion .. "|r")
            row.modeText:SetText(GetModeColoredText(data.mode))

            local s = currentDungeonScores[tostring(mapId)] or 0
            if s > 0 then
                row.scoreVal:SetText(string.format("%.2f", s))
                row.scoreVal:SetTextColor(1, 1, 1)
            else
                row.scoreVal:SetText("0")
                row.scoreVal:SetTextColor(0.5, 0.5, 0.5)
            end
            row:Show()
        else
            row.mapId = nil
            if row.tpBtn then
                row.tpBtn.mapId = nil
                row.tpBtn:Hide()
            end
            row:Hide()
        end
    end
end

scoreSlider:SetScript("OnValueChanged", function(_, value)
    local intVal = math.floor(value + 0.5)
    if scoreScrollOffset ~= intVal then
        scoreScrollOffset = intVal
        UpdateScoreList(true)
    end
end)

UpdateScoreFilters = function()
    UpdateScoreFilterText()
    if scoreHName then
        scoreHName:SetText(MythicGetText("UI", "Dungeon") or "Dungeon")
        scoreHExp:SetText(MythicGetText("UI", "Expansion") or "Expansion")
        scoreHMode:SetText(MythicGetText("UI", "Difficulty") or "Difficulty")
        scoreHScore:SetText(MythicGetText("UI", "Rating") or "Rating")
        if scoreHTp then
            scoreHTp:SetText(MythicGetText("UI", "Portal") or "Portal")
        end
    end
    for _, r in ipairs(scoreRows) do
        if r.tpBtn then
            r.tpBtn:SetText(MythicGetText("UI", "Teleport") or "Teleport")
        end
    end
end

--------------------------------------------------------------------------------
-- TAB 3: LEADERBOARD CONTAINER (Podiums + List View)
--------------------------------------------------------------------------------
local leaderboardContainer = CreateFrame("Frame", nil, frame)
leaderboardContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, -15)
leaderboardContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
leaderboardContainer:Hide()
frame.leaderboardContainer = leaderboardContainer

local leaderboardBanner, leaderboardTitle = CreateBannerTitle(leaderboardContainer, MythicGetText("UI", "Leaderboard"), -5)
frame.leaderboardTitle = leaderboardTitle
frame.leaderboardBanner = leaderboardBanner

frame.podiums = {}
local podiumSpecs = {
    { height = 20, width = 64, color = {0.8, 0.8, 0.8}, x = -75, rankText = "|cffc0c0c0#2|r" },
    { height = 28, width = 74, color = {0.95, 0.84, 0.0}, x = 0, rankText = "|cffffd700#1|r" },
    { height = 15, width = 64, color = {0.72, 0.45, 0.2}, x = 75, rankText = "|cffcd7f32#3|r" },
}

for i, spec in ipairs(podiumSpecs) do
    local podium = CreateFrame("Frame", nil, leaderboardContainer)
    podium:SetSize(spec.width, spec.height)
    podium:SetPoint("BOTTOM", leaderboardBanner, "TOP", spec.x, -118)

    local bg = podium:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(spec.color[1], spec.color[2], spec.color[3], 0.9)

    local rankLabel = podium:CreateFontString(nil, "OVERLAY")
    rankLabel:SetPoint("BOTTOM", podium, "TOP", 0, 13)
    rankLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE, THICK")
    rankLabel:SetText(spec.rankText)
    podium.rankLabel = rankLabel

    local name = podium:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("BOTTOM", podium, "TOP", 0, 1)
    name:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    name:SetText("—")
    podium.name = name

    local score = podium:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    score:SetPoint("CENTER", podium, "CENTER")
    score:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    score:SetText("0")
    podium.score = score

    frame.podiums[i] = podium
end

local function UpdatePodiums()
    local visualToRank = {2, 1, 3}
    for i = 1, 3 do
        local rank = visualToRank[i]
        local entry = currentTopThree[rank]
        local podium = frame.podiums[i]
        if podium then
            if entry then
                podium.name:SetText(entry.name)
                podium.score:SetText(string.format("%.2f", entry.points or 0))
            else
                podium.name:SetText("—")
                podium.score:SetText("0")
            end
        end
    end
end

local currentLbFilter = "ALL"
local lbScrollOffset = 0
local LB_VISIBLE_ROWS = 8
local lbFilterButtons = {}

-- Leaderboard ScrollBar (Native Blizzard UIPanelScrollBarTemplate)
local lbSlider = CreateFrame("Slider", "MythicLeaderboardScrollBar", leaderboardContainer, "UIPanelScrollBarTemplate")
lbSlider:SetSize(16, (LB_VISIBLE_ROWS * 24) - 32)
lbSlider:SetPoint("TOPLEFT", leaderboardContainer, "TOPLEFT", 535, -204 - 16)
lbSlider:SetMinMaxValues(0, 0)
lbSlider:SetValueStep(1)
lbSlider:SetValue(0)

local lbUpBtn = _G["MythicLeaderboardScrollBarScrollUpButton"]
if lbUpBtn then
    lbUpBtn:SetScript("OnClick", function()
        lbSlider:SetValue(lbSlider:GetValue() - 1)
        PlaySound("UChatScrollButton")
    end)
end

local lbDownBtn = _G["MythicLeaderboardScrollBarScrollDownButton"]
if lbDownBtn then
    lbDownBtn:SetScript("OnClick", function()
        lbSlider:SetValue(lbSlider:GetValue() + 1)
        PlaySound("UChatScrollButton")
    end)
end

local function ScrollLeaderboard(delta)
    if not lbSlider then return end
    local minV, maxV = lbSlider:GetMinMaxValues()
    local cur = lbSlider:GetValue()
    local nxt = math.min(maxV, math.max(minV, cur - delta))
    if nxt ~= cur then
        lbSlider:SetValue(nxt)
    end
end

local function CreateLbFilterBar(parent, yOffset, onSelect)
    local buttons = {}
    local totalW = 4 * 85 + 3 * 8
    local startX = (520 - totalW) / 2
    
    for i, def in ipairs(filterDefs) do
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(85, 22)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", startX + (i - 1) * 93, yOffset)
        btn:SetText(def.text)
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn.filterKey = def.key
        btn.filterDef = def

        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            onSelect(def.key)
        end)
        buttons[def.key] = btn
    end
    return buttons
end

lbFilterButtons = CreateLbFilterBar(leaderboardContainer, -156, function(key)
    currentLbFilter = key
    lbScrollOffset = 0
    if lbSlider then lbSlider:SetValue(0) end
    UpdateFilterButtonStyles(lbFilterButtons, currentLbFilter)
    if UpdateLeaderboardList then UpdateLeaderboardList() end
end)
UpdateFilterButtonStyles(lbFilterButtons, currentLbFilter)

-- Leaderboard Table Header
local lbHeader = CreateFrame("Frame", nil, leaderboardContainer)
lbHeader:SetSize(520, 20)
lbHeader:SetPoint("TOPLEFT", leaderboardContainer, "TOPLEFT", 10, -182)

local lbHeaderBg = lbHeader:CreateTexture(nil, "BACKGROUND")
lbHeaderBg:SetAllPoints()
lbHeaderBg:SetTexture(0, 0, 0, 0.5)

local lbHName = lbHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lbHName:SetPoint("LEFT", lbHeader, "LEFT", 12, 0)
lbHName:SetText(MythicGetText("UI", "Dungeon") or "Dungeon")

local lbHExp = lbHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lbHExp:SetPoint("CENTER", lbHeader, "LEFT", 255, 0)
lbHExp:SetText(MythicGetText("UI", "Expansion") or "Expansion")

local lbHTop = lbHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lbHTop:SetPoint("CENTER", lbHeader, "LEFT", 365, 0)
lbHTop:SetText(MythicGetText("UI", "Highest Score:") or "Best Record")

local lbHKey = lbHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
lbHKey:SetPoint("RIGHT", lbHeader, "RIGHT", -25, 0)
lbHKey:SetText("Best Key")

-- Leaderboard Rows
local lbRows = {}
for i = 1, LB_VISIBLE_ROWS do
    local row = CreateFrame("Button", nil, leaderboardContainer)
    row:SetSize(520, 23)
    row:SetPoint("TOPLEFT", leaderboardContainer, "TOPLEFT", 10, -204 - ((i - 1) * 24))

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, (i % 2 == 0) and 0.25 or 0.12)
    row.bg = bg

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetBlendMode("ADD")

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetPoint("LEFT", row, "LEFT", 12, 0)
    nameText:SetWidth(230)
    nameText:SetJustifyH("LEFT")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    row.nameText = nameText

    local expModeText = row:CreateFontString(nil, "OVERLAY")
    expModeText:SetPoint("CENTER", row, "LEFT", 255, 0)
    expModeText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    row.expModeText = expModeText

    local topText = row:CreateFontString(nil, "OVERLAY")
    topText:SetPoint("CENTER", row, "LEFT", 365, 0)
    topText:SetWidth(150)
    topText:SetJustifyH("CENTER")
    topText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    row.topText = topText

    local keyText = row:CreateFontString(nil, "OVERLAY")
    keyText:SetPoint("RIGHT", row, "RIGHT", -25, 0)
    keyText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    row.keyText = keyText

    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta) ScrollLeaderboard(delta) end)

    row:SetScript("OnEnter", function(self)
        if not self.mapId then return end
        local data = DUNGEONS[self.mapId]
        if not data then return end
        local top = currentDungeonTop[tostring(self.mapId)]
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(MythicGetText("Dungeons", data.originalName), 1, 1, 1)
        if top and top.score and top.score > 0 then
            GameTooltip:AddLine(MythicGetText("UI", "Highest Score:"), 1, 1, 0)
            GameTooltip:AddLine("  " .. (top.name or "Unknown") .. ": " .. top.score, 1, 1, 1)
            if top.highestKey and top.highestKey > 0 then
                local highestKeyText = MythicGetText("UI", "Highest Key +%d by:"):format(top.highestKey)
                GameTooltip:AddLine(highestKeyText, 1, 1, 0)
                if top.keyHolderNames and #top.keyHolderNames > 0 then
                    for _, memberName in ipairs(top.keyHolderNames) do
                        GameTooltip:AddLine("  " .. memberName, 0.8, 1, 0.8)
                    end
                else
                    GameTooltip:AddLine("  " .. MythicGetText("UI", "Unknown"), 0.8, 1, 0.8)
                end
            else
                GameTooltip:AddLine(MythicGetText("UI", "Highest Key: None completed in time"), 0.7, 0.7, 0.7)
            end
        else
            GameTooltip:AddLine(MythicGetText("UI", "No records available"), 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    lbRows[i] = row
end
frame.leaderboardButtons = lbRows

leaderboardContainer:EnableMouseWheel(true)
leaderboardContainer:SetScript("OnMouseWheel", function(_, delta) ScrollLeaderboard(delta) end)
lbSlider:EnableMouseWheel(true)
lbSlider:SetScript("OnMouseWheel", function(_, delta) ScrollLeaderboard(delta) end)

UpdateLeaderboardList = function(fromSlider)
    local filtered = GetFilteredDungeons(currentLbFilter)
    local maxOffset = math.max(0, #filtered - LB_VISIBLE_ROWS)
    lbSlider:SetMinMaxValues(0, maxOffset)
    if lbScrollOffset > maxOffset then
        lbScrollOffset = maxOffset
    end
    if not fromSlider then
        lbSlider:SetValue(lbScrollOffset)
    end

    if maxOffset > 0 then
        lbSlider:Show()
    else
        lbSlider:Hide()
    end

    if lbUpBtn then
        if lbScrollOffset <= 0 then lbUpBtn:Disable() else lbUpBtn:Enable() end
    end
    if lbDownBtn then
        if lbScrollOffset >= maxOffset then lbDownBtn:Disable() else lbDownBtn:Enable() end
    end

    for i = 1, LB_VISIBLE_ROWS do
        local dataIndex = lbScrollOffset + i
        local mapId = filtered[dataIndex]
        local row = lbRows[i]
        if mapId and DUNGEONS[mapId] then
            local data = DUNGEONS[mapId]
            row.mapId = mapId
            row.nameText:SetText(MythicGetText("Dungeons", data.originalName))
            local modeBadge = (data.mode == "Normal & Heroic") and "|cffffd100N/H|r" or "|cffaaaaaaN|r"
            row.expModeText:SetText(GetExpansionColor(data.expansion) .. data.expansion .. "|r " .. modeBadge)

            local top = currentDungeonTop[tostring(mapId)]
            if top and top.score and top.score > 0 then
                local pName = top.name or "Unknown"
                if #pName > 12 then pName = pName:sub(1, 10) .. ".." end
                row.topText:SetText(string.format("%s (%.1f)", pName, top.score))
                row.topText:SetTextColor(1, 0.82, 0)
                if top.highestKey and top.highestKey > 0 then
                    row.keyText:SetText("+" .. top.highestKey)
                    row.keyText:SetTextColor(0, 1, 0)
                else
                    row.keyText:SetText("—")
                    row.keyText:SetTextColor(0.5, 0.5, 0.5)
                end
            else
                row.topText:SetText("—")
                row.topText:SetTextColor(0.5, 0.5, 0.5)
                row.keyText:SetText("—")
                row.keyText:SetTextColor(0.5, 0.5, 0.5)
            end
            row:Show()
        else
            row.mapId = nil
            row:Hide()
        end
    end
end

lbSlider:SetScript("OnValueChanged", function(_, value)
    local intVal = math.floor(value + 0.5)
    if lbScrollOffset ~= intVal then
        lbScrollOffset = intVal
        UpdateLeaderboardList(true)
    end
end)

UpdateLeaderboardFilters = function()
    if lbFilterButtons["ALL"] then
        lbFilterButtons["ALL"]:SetText(MythicGetText("UI", "All") .. " (51)")
        lbFilterButtons["WotLK"]:SetText("WotLK (16)")
        lbFilterButtons["TBC"]:SetText("TBC (16)")
        lbFilterButtons["Vanilla"]:SetText(MythicGetText("UI", "Vanilla") .. " (19)")
    end
    if lbHName then
        lbHName:SetText(MythicGetText("UI", "Dungeon") or "Dungeon")
        lbHExp:SetText(MythicGetText("UI", "Expansion") or "Expansion")
        lbHTop:SetText(MythicGetText("UI", "Highest Score:") or "Best Record")
    end
end

--------------------------------------------------------------------------------
-- TAB 3: SETTINGS CONTAINER (Options & Configuration)
--------------------------------------------------------------------------------
local settingsContainer = CreateFrame("Frame", nil, frame)
settingsContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, -15)
settingsContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
settingsContainer:Hide()
frame.settingsContainer = settingsContainer

local settingsBanner, settingsTitle = CreateBannerTitle(settingsContainer, MythicGetText("UI", "Settings") or "Settings", -4)
frame.settingsTitle = settingsTitle
frame.settingsBanner = settingsBanner

-- Helper to create styled card panels
local function CreateSettingCard(parent, titleText, yOffset, height)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(520, height)
    card:SetPoint("TOP", parent, "TOP", 0, yOffset)
    card:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0.04, 0.04, 0.06, 0.55)
    card:SetBackdropBorderColor(0.55, 0.45, 0.25, 0.75)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -10)
    title:SetText(titleText)

    return card
end

-- CARD 1: Keystone & Progression Rules
local card1 = CreateSettingCard(settingsContainer, "|cffffd100[ Keystone & Progression Rules ]|r", -72, 116)

-- Option 1: Cheat Mode Checkbox
local optNoKey = CreateFrame("CheckButton", "MythicPlusSetting_NoKey", card1, "UICheckButtonTemplate")
optNoKey:SetPoint("TOPLEFT", card1, "TOPLEFT", 18, -32)
optNoKey:SetSize(24, 24)

local optNoKeyLabel = card1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
optNoKeyLabel:SetPoint("LEFT", optNoKey, "RIGHT", 6, 0)
optNoKeyLabel:SetText("No Keystone Required (Cheat Mode)")

local optNoKeyDesc = card1:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
optNoKeyDesc:SetPoint("TOPLEFT", optNoKey, "BOTTOMLEFT", 28, -1)
optNoKeyDesc:SetText("Allows opening Font of Power and selecting any tier (1-100) without a keystone.")

-- Option 2: Cross-Dungeon Reattunement Checkbox
local optReattune = CreateFrame("CheckButton", "MythicPlusSetting_Reattune", card1, "UICheckButtonTemplate")
optReattune:SetPoint("TOPLEFT", card1, "TOPLEFT", 18, -72)
optReattune:SetSize(24, 24)

local optReattuneLabel = card1:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
optReattuneLabel:SetPoint("LEFT", optReattune, "RIGHT", 6, 0)
optReattuneLabel:SetText("Allow Cross-Dungeon Key Reattunement")

local optReattuneDesc = card1:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
optReattuneDesc:SetPoint("TOPLEFT", optReattune, "BOTTOMLEFT", 28, -1)
optReattuneDesc:SetText("Allows players to re-attune their keystone to the current dungeon at the fountain.")

-- CARD 2: Heroic Difficulty Reward Multipliers
local card2 = CreateSettingCard(settingsContainer, "|cffffd100[ Heroic Difficulty Reward Multipliers ]|r", -198, 150)

local function CreateSettingRow(parent, name, labelText, defaultVal, yOffset, tipText)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, yOffset)
    label:SetText(labelText)

    local box = CreateFrame("EditBox", name, parent)
    box:SetSize(65, 22)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", 195, yOffset + 2)
    box:SetAutoFocus(false)
    box:SetText(defaultVal)
    box:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    box:SetTextColor(1, 1, 1, 1)
    box:SetJustifyH("CENTER")
    box:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    box:SetBackdropColor(0.02, 0.02, 0.04, 0.85)
    box:SetBackdropBorderColor(0.6, 0.5, 0.3, 0.8)

    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(1, 0.85, 0.2, 1)
    end)
    box:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.6, 0.5, 0.3, 0.8)
    end)

    if tipText then
        local tip = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        tip:SetPoint("LEFT", box, "RIGHT", 12, 0)
        tip:SetText(tipText)
    end

    return box
end

local boxBonusChance = CreateSettingRow(card2, "MythicSetting_BonusChanceBox", "Loot Bonus Multiplier:", "1.25", -34, "|cff888888(e.g. 1.25 = +25% drop chance)|r")
local boxExtraEmblem = CreateSettingRow(card2, "MythicSetting_ExtraEmblemBox", "Extra Emblem Reward:", "1", -62, "|cff888888(Extra Emblems of Frost awarded)|r")
local boxGoldMult    = CreateSettingRow(card2, "MythicSetting_GoldMultBox",    "Gold Reward Multiplier:", "1.50", -90, "|cff888888(e.g. 1.50 = +50% bonus gold)|r")
local boxRatingMult  = CreateSettingRow(card2, "MythicSetting_RatingMultBox",  "Rating Score Multiplier:", "1.10", -118, "|cff888888(e.g. 1.10 = +10% rating score)|r")

-- Status Message (Centered at bottom)
local statusMsg = settingsContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statusMsg:SetPoint("BOTTOM", settingsContainer, "BOTTOM", 0, 20)
statusMsg:SetJustifyH("CENTER")
statusMsg:SetText("")

-- Action Buttons (Centered side by side)
local saveBtn = CreateFrame("Button", "MythicSetting_SaveBtn", settingsContainer, "UIPanelButtonTemplate")
saveBtn:SetSize(130, 28)
saveBtn:SetPoint("BOTTOM", settingsContainer, "BOTTOM", -75, 46)
saveBtn:SetText("Save Settings")

local resetBtn = CreateFrame("Button", "MythicSetting_ResetBtn", settingsContainer, "UIPanelButtonTemplate")
resetBtn:SetSize(130, 28)
resetBtn:SetPoint("BOTTOM", settingsContainer, "BOTTOM", 75, 46)
resetBtn:SetText("Reset Defaults")

saveBtn:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    local newCfg = {
        NoKeystoneRequired = optNoKey:GetChecked() and 1 or 0,
        AllowKeyReattunement = optReattune:GetChecked() and 1 or 0,
        HeroicBonusChance = tonumber(boxBonusChance:GetText()) or 1.25,
        HeroicExtraEmblem = math.floor(tonumber(boxExtraEmblem:GetText()) or 1),
        HeroicGoldMultiplier = tonumber(boxGoldMult:GetText()) or 1.5,
        HeroicRatingMultiplier = tonumber(boxRatingMult:GetText()) or 1.1,
    }
    statusMsg:SetText("|cff00ff00Saving settings...|r")
    AIO.Handle("AIO_Mythic", "SaveConfig", newCfg)
end)

resetBtn:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    optNoKey:SetChecked(false)
    optReattune:SetChecked(false)
    boxBonusChance:SetText("1.25")
    boxExtraEmblem:SetText("1")
    boxGoldMult:SetText("1.50")
    boxRatingMult:SetText("1.10")
    statusMsg:SetText("|cffffff00Defaults restored in form. Click 'Save Settings' to apply.|r")
end)

function MythicHandlers.ReceiveConfig(_, cfg)
    if not cfg or type(cfg) ~= "table" then return end
    optNoKey:SetChecked(cfg.NoKeystoneRequired == 1)
    optReattune:SetChecked(cfg.AllowKeyReattunement == 1)
    boxBonusChance:SetText(string.format("%.2f", cfg.HeroicBonusChance or 1.25))
    boxExtraEmblem:SetText(tostring(cfg.HeroicExtraEmblem or 1))
    boxGoldMult:SetText(string.format("%.2f", cfg.HeroicGoldMultiplier or 1.5))
    boxRatingMult:SetText(string.format("%.2f", cfg.HeroicRatingMultiplier or 1.1))
    statusMsg:SetText("|cff00ff00Settings up to date.|r")
end

--------------------------------------------------------------------------------
-- MAIN TABS & ACTIVATION
--------------------------------------------------------------------------------
local tabs = {}
local function SetActiveTab(index)
    PlaySound("igMainMenuOptionCheckBoxOn")
    frame.currentTab = index
    
    for i, tab in ipairs(tabs) do
        if i == index then
            tab.isSelected = true
            tab:GetNormalTexture():SetVertexColor(1, 0.4, 0.4, 1)
            tab:GetHighlightTexture():SetVertexColor(1, 0.5, 0.5, 1)
        else
            tab.isSelected = false
            tab:GetNormalTexture():SetVertexColor(0.8, 0.2, 0.2, 1)
            tab:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3, 1)
        end
    end

    if index == 1 then
        overviewContainer:Show()
        AIO.Handle("AIO_Mythic", "RequestWeeklyAffixes")
    else
        overviewContainer:Hide()
    end

    if index == 2 then
        scoreContainer:Show()
        UpdateScoreList()
        AIO.Handle("AIO_Mythic", "RequestTotalPoints")
    else
        scoreContainer:Hide()
    end

    if index == 3 then
        settingsContainer:Show()
        AIO.Handle("AIO_Mythic", "RequestConfig")
    else
        settingsContainer:Hide()
    end

    if index == 4 then
        leaderboardContainer:Show()
        UpdatePodiums()
        UpdateLeaderboardList()
        AIO.Handle("AIO_Mythic", "RequestLeaderboard")
    else
        leaderboardContainer:Hide()
    end
end

tabs[1] = CreateStyledTabButton(tabBackground, MythicGetText("UI", "Overview"), 1, SetActiveTab)
tabs[2] = CreateStyledTabButton(tabBackground, MythicGetText("UI", "Score"), 2, SetActiveTab)
tabs[3] = CreateStyledTabButton(tabBackground, MythicGetText("UI", "Settings") or "Settings", 3, SetActiveTab)
tabs[4] = CreateStyledTabButton(tabBackground, MythicGetText("UI", "Leaderboard"), 4, SetActiveTab)

frame:SetScript("OnShow", function(self)
    if self.currentTab then
        SetActiveTab(self.currentTab)
    else
        SetActiveTab(1)
    end
end)

SetActiveTab(1)

function MythicHandlers.ReceiveLeaderboard(_, topThree, dungeonTop)
    currentTopThree = topThree or {}
    currentDungeonTop = dungeonTop or {}
    UpdatePodiums()
    UpdateLeaderboardList()
end

function MythicHandlers.StartMythicTimerGUI(_, mapId, tier, duration, bossNames, potentialGain, enemiesRequired)
    potentialGain = tonumber(potentialGain) or 0
    enemiesRequired = tonumber(enemiesRequired) or 50
    if type(bossNames) ~= "table" then bossNames = {} end
    local maxDeaths = (tier == 1) and 6 or 4
    WatchFrame:Hide(); WATCHFRAME_COLLAPSED = true

    local baseHeight = 140 + #bossNames * 18
    local frameHeight = (enemiesRequired > 0) and (baseHeight + 28) or baseHeight

    local timerFrame = CreateFrame("Frame", nil, UIParent)
    timerFrame:SetSize(320, frameHeight)
    timerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -120)
    timerFrame:SetMovable(true)
    timerFrame:EnableMouse(true)
    timerFrame:RegisterForDrag("LeftButton")
    timerFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    timerFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local progressBar = timerFrame:CreateTexture(nil, "BACKGROUND")
    progressBar:SetTexture("Interface\\MythicPlus\\textures\\MythicBar.blp")
    progressBar:SetSize(0, 128)
    progressBar:SetPoint("LEFT", timerFrame, "LEFT", 0, -10)
    progressBar:SetTexCoord(0, 0, 0, 1)
    progressBar:Hide()

    local function updateProgress(killedBosses, totalBosses)
        if totalBosses == 0 then return end
        local progress = math.min(killedBosses / totalBosses, 1.0)
        local maxWidth = 256
        local currentWidth = maxWidth * progress
        if progress > 0 then
            progressBar:Show()
            progressBar:SetWidth(currentWidth)
            progressBar:SetTexCoord(0, progress, 0, 1)
        else
            progressBar:Hide()
        end
    end

    local goldenFrame = timerFrame:CreateTexture(nil, "ARTWORK")
    goldenFrame:SetTexture("Interface\\MythicPlus\\textures\\MythicFrame.blp")
    goldenFrame:SetSize(256, 128)
    goldenFrame:SetPoint("LEFT", timerFrame, "LEFT", 0, -10)
    goldenFrame:SetTexCoord(0, 1, 0, 1)

    local dungeonText = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dungeonText:SetPoint("TOP", goldenFrame, "TOP", 0, -12)
    local dungeonName = (DUNGEONS[mapId] and DUNGEONS[mapId].name) or ("Map "..mapId)
    dungeonText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    dungeonText:SetText(fmt("|cffFFD700%s|r", dungeonName))

    local tierText = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tierText:SetPoint("TOP", goldenFrame, "LEFT", 50, 26)
    tierText:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    tierText:SetText(fmt("|cffFFD700Level %d|r", tier))

    local timerText = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timerText:SetPoint("CENTER", goldenFrame, "LEFT", 48, -6)
    timerText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    timerText:SetText(fmt("%02d:%02d", floor(duration/60), duration%60))

    local deaths, penalty, bonus = 0, 0, 0
    local scoreLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scoreLabel:SetPoint("BOTTOM", goldenFrame, "BOTTOM", 60, 50)
    
    local gold, red, green, reset = "|cffFFD700", "|cffff0000", "|cff33ff33", "|r"
    local scoreStr = gold..potentialGain..reset.." "..gold.."("..reset..red.."-"..penalty..reset..gold.."/"..reset..green.."+"..bonus..reset..gold..")"..reset.." "..gold..deaths.."/"..maxDeaths..reset
    scoreLabel:SetText(scoreStr)

    local affixContainer = CreateFrame("Frame", nil, timerFrame)
    affixContainer:SetSize(200, 30)
    affixContainer:SetPoint("BOTTOM", scoreLabel, "TOP", 40, 11)

    local affixIcons = {}
    local currentAffixes = {}

    if MythicPlusFrame and MythicPlusFrame.currentAffixes then
        currentAffixes = MythicPlusFrame.currentAffixes
    end

    local numAffixes = math.min(tier, 4)
    local iconSize = 20
    local iconSpacing = 4
    local totalWidth = (numAffixes * iconSize) + ((numAffixes - 1) * iconSpacing)
    local startX = -totalWidth / 2

    for i = 1, numAffixes do
        local affixName = currentAffixes[i]
        if affixName and AFFIXES[affixName] then
            local icon = CreateFrame("Button", nil, affixContainer)
            icon:SetSize(iconSize, iconSize)
            icon:SetPoint("LEFT", affixContainer, "LEFT", startX + (i-1) * (iconSize + iconSpacing) + 30, -5)
            
            local texture = icon:CreateTexture(nil, "ARTWORK")
            texture:SetAllPoints()
            texture:SetTexture(AFFIXES[affixName].icon)
            
            icon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(affixName)
                GameTooltip:Show()
            end)
            
            icon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            affixIcons[i] = icon
        end
    end

    local bossLabels = {}
    for i, name in ipairs(bossNames) do
        local lbl = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", goldenFrame, "BOTTOMLEFT", 20, 10 - (i-1)*16)
        lbl:SetText(fmt("%d/%d %s", 0, 1, name))
        lbl:SetTextColor(1, 0.82, 0)
        lbl.bossName = name
        bossLabels[i] = lbl
    end
    local enemyLabel, enemyProgressFrame, enemyPercentText
    if enemiesRequired > 0 then
        enemyLabel = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        enemyLabel:SetPoint("TOPLEFT", goldenFrame, "BOTTOMLEFT", 20, 10 - #bossNames*16)
        enemyLabel:SetText("0/1 " .. MythicGetText("UI", "Enemy Forces"))
        enemyLabel:SetTextColor(1, 0.82, 0)
        
        enemyProgressFrame = CreateFrame("StatusBar", nil, timerFrame)
        enemyProgressFrame:SetSize(200, 12)
        enemyProgressFrame:SetPoint("TOPLEFT", enemyLabel, "BOTTOMLEFT", 0, -10)
        enemyProgressFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        enemyProgressFrame:SetStatusBarColor(0.2, 0.8, 0.2)
        enemyProgressFrame:SetMinMaxValues(0, 100)
        enemyProgressFrame:SetValue(0)
        
        local enemyProgressBorder = CreateFrame("Frame", nil, timerFrame, BackdropTemplateMixin and "BackdropTemplate")
        enemyProgressBorder:SetAllPoints(enemyProgressFrame)
        enemyProgressBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        enemyProgressBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        enemyPercentText = enemyProgressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        enemyPercentText:SetPoint("CENTER", enemyProgressFrame, "CENTER")
        enemyPercentText:SetText("0%")
    end

    local elapsed = 0
    timerFrame:SetScript("OnUpdate", function(self, dt)
        if self.stopped then return end
        elapsed = elapsed + dt
        local left = duration - elapsed
        if left < 0 then left = 0 end
        local m,s = floor(left/60), floor(left%60)
        local ratio = left/duration
        local color = "|cff00ff00"
        if ratio < 0.3 then color = "|cffff0000"
        elseif ratio < 0.6 then color = "|cffffff00" end
        timerText:SetText(fmt("%s%02d:%02d|r", color, m, s))
    end)

    timerFrame:Show()

    MythicBossTimerUI = {
        frame = timerFrame,
        timerText = timerText,
        scoreLabel = scoreLabel,
        labels = bossLabels,
        progressBar = progressBar,
        updateProgress = updateProgress,
        totalBosses = #bossNames,
        killedBosses = 0,
        potentialGain = potentialGain,
        penalty = 0,
        bonus = 0,
        deaths = 0,
        maxDeaths = maxDeaths,
        enemyLabel = enemyLabel,
        enemyProgressFrame = enemyProgressFrame,
        enemyPercentText = enemyPercentText,
        enemiesRequired = enemiesRequired,
        enemiesCurrent = 0
    }
end

function MythicHandlers.UpdateMythicScore(_, newPenalty, newDeaths)
    local ui = MythicBossTimerUI
    if not ui or not ui.scoreLabel then return end
    ui.penalty = tonumber(newPenalty) or ui.penalty
    ui.deaths  = tonumber(newDeaths)   or ui.deaths
    local gold  = "|cffcc9933"
    local red   = "|cffff0000"
    local green = "|cff33ff33"
    local reset = "|r"
    local scoreStr =
        gold..ui.potentialGain..reset.." ".. 
        gold.."("..reset..
        red.."-"..ui.penalty..reset..
        gold.."/"..reset..
        green.."+"..ui.bonus..reset..
        gold..")"..reset.." ".. 
        gold..ui.deaths.."/"..ui.maxDeaths..reset
    ui.scoreLabel:SetText(scoreStr)
end

function MythicHandlers.FinalizeMythicScore(_, finalPenalty, finalDeaths, finalBonus)
    local ui = MythicBossTimerUI
    if not ui or not ui.scoreLabel then return end
    ui.penalty = tonumber(finalPenalty) or ui.penalty
    ui.deaths  = tonumber(finalDeaths)  or ui.deaths
    ui.bonus   = tonumber(finalBonus)   or ui.bonus
    local gold  = "|cffcc9933"
    local red   = "|cffff0000"
    local green = "|cff33ff33"
    local reset = "|r"
    local scoreStr =
        gold..ui.potentialGain..reset.." ".. 
        gold.."("..reset..
        red.."-"..ui.penalty..reset..
        gold.."/"..reset..
        green.."+"..ui.bonus..reset..
        gold..")"..reset.." ".. 
        gold..ui.deaths.."/"..ui.maxDeaths..reset
    ui.scoreLabel:SetText(scoreStr)
end

function MythicHandlers.MarkBossKilled(_, mapId, bossIndex)
    local ui = MythicBossTimerUI
    if not ui or not ui.labels then return end
    local lbl = ui.labels[bossIndex]
    if lbl and lbl.bossName then
        lbl:SetText(fmt("|cff26c426%d/%d %s|r", 1, 1, lbl.bossName))
        ui.killedBosses = ui.killedBosses + 1
        if ui.updateProgress then
            ui.updateProgress(ui.killedBosses, ui.totalBosses)
        end
    end
end

function MythicHandlers.StopMythicTimerGUI(_, remaining)
    local ui = MythicBossTimerUI
    if ui and ui.timerText then
        if type(remaining) == "number" then
            local m, s = floor(remaining/60), floor(remaining%60)
            ui.timerText:SetText(fmt("|cffffff00%02d:%02d|r", m, s))
        end
        ui.frame.stopped = true
    end
end

function MythicHandlers.KillMythicTimerGUI()
    WatchFrame:Show(); WATCHFRAME_COLLAPSED = nil
    if MythicBossTimerUI and MythicBossTimerUI.frame then
        MythicBossTimerUI.frame.stopped = true
        MythicBossTimerUI.frame:Hide()
        MythicBossTimerUI.frame:SetScript("OnUpdate", nil)
        MythicBossTimerUI.frame:SetParent(nil)
        MythicBossTimerUI.frame = nil
    end
    MythicBossTimerUI = nil
end

function MythicHandlers.StartCountdown(_, seconds)
    seconds = tonumber(seconds) or 10
    if CountdownFrame then
        CountdownFrame:Hide()
        CountdownFrame:SetScript("OnUpdate", nil)
    end
    if not CountdownFrame then
        local frame = CreateFrame("Frame", "CountdownFrame", UIParent)
        frame:SetSize(512, 256)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:Hide()

        frame.digit1 = frame:CreateTexture(nil, "ARTWORK")
        frame.digit1:SetSize(256, 170)
        frame.digit1:SetPoint("CENTER", frame, "CENTER", -70, 0)
        frame.digit1:SetTexture("Interface\\MythicPlus\\textures\\BigTimerNumbers")

        frame.digit2 = frame:CreateTexture(nil, "ARTWORK")
        frame.digit2:SetSize(256, 170)
        frame.digit2:SetPoint("CENTER", frame, "CENTER", 70, 0)
        frame.digit2:SetTexture("Interface\\MythicPlus\\textures\\BigTimerNumbers")

        CountdownFrame = frame
    end

    local frame = CountdownFrame
    frame:Show()
    local function setDigits(num)
        local texW, texH = 1024, 512
        local digitW, digitH = 256, 170
        local columns = 4

        local n1 = math.floor(num / 10)
        local n2 = num % 10

        local function setDigit(tex, digit)
            local col = digit % columns
            local row = math.floor(digit / columns)
            local l = (col * digitW) / texW
            local r = ((col + 1) * digitW) / texW
            local t = (row * digitH) / texH
            local b = ((row + 1) * digitH) / texH
            tex:SetTexCoord(l, r, t, b)
            tex:Show()
        end
        if n1 > 0 then
            setDigit(frame.digit1, n1)
            frame.digit1:Show()
            frame.digit2:SetPoint("CENTER", frame, "CENTER", 70, 0)
        else
            frame.digit1:Hide()
            frame.digit2:SetPoint("CENTER", frame, "CENTER", 0, 0)
        end
        setDigit(frame.digit2, n2)
    end

    setDigits(seconds)
    PlaySoundFile("Interface\\MythicPlus\\sounds\\UI_BattlegroundCountdown_Timer.ogg", "master")

    local remaining = seconds
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not self.lastUpdate then self.lastUpdate = 0 end
        self.lastUpdate = self.lastUpdate + elapsed
        if self.lastUpdate >= 1 then
            self.lastUpdate = self.lastUpdate - 1
            remaining = remaining - 1
            if remaining > 0 then
                setDigits(remaining)
                PlaySoundFile("Interface\\MythicPlus\\sounds\\UI_BattlegroundCountdown_Timer.ogg", "master")
            else
                PlaySoundFile("Interface\\MythicPlus\\sounds\\UI_BattlegroundCountdown_End.ogg", "master")
                self:Hide()
                self:SetScript("OnUpdate", nil)
            end
        end
    end)
end

function MythicHandlers.UpdateVaultStatus(_, hasLoot)
    if hasLoot then
        mythicMiniButton.hasVaultLoot = true
        if not mythicMiniButton.glowTexture then
            mythicMiniButton.glowTexture = mythicMiniButton:CreateTexture(nil, "OVERLAY")
            mythicMiniButton.glowTexture:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
            mythicMiniButton.glowTexture:SetSize(48, 48)
            mythicMiniButton.glowTexture:SetPoint("CENTER")
            mythicMiniButton.glowTexture:SetBlendMode("ADD")
        end
        mythicMiniButton.glowTexture:Show()
    else
        mythicMiniButton.hasVaultLoot = false
        if mythicMiniButton.glowTexture then
            mythicMiniButton.glowTexture:Hide()
        end
    end
end

function MythicHandlers.QueryItemData(_, item1, item2, item3)
    if not MythicHiddenTooltip then
        MythicHiddenTooltip = CreateFrame("GameTooltip", "MythicHiddenTooltip", nil, "GameTooltipTemplate")
        MythicHiddenTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    
    local function QueryItem(itemId)
        if itemId and itemId > 0 then
            MythicHiddenTooltip:SetHyperlink("item:"..itemId..":0:0:0:0:0:0:0")
            MythicHiddenTooltip:Show()
        end
    end
    
    if item1 and item1 > 0 then
        QueryItem(item1)
    end
    
    if item2 and item2 > 0 then
        local item2Timer = CreateFrame("Frame")
        item2Timer.elapsed = 0
        item2Timer:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 0.1 then
                QueryItem(item2)
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
    
    if item3 and item3 > 0 then
        local item3Timer = CreateFrame("Frame")
        item3Timer.elapsed = 0
        item3Timer:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= 0.2 then
                QueryItem(item3)
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

function MythicHandlers.ShowVaultGUI(_, item1, item2, item3, tier1, tier2, tier3)
    MythicHandlers.QueryItemData(nil, item1, item2, item3)
    if VaultFrame then
        VaultFrame:Hide()
    end
    
    VaultFrame = CreateFrame("Frame", "MythicVaultFrame", UIParent)
    VaultFrame:SetSize(600, 450)
    VaultFrame:SetPoint("CENTER")
    VaultFrame:SetToplevel(true)
    
    local vaultDarkBG = VaultFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    vaultDarkBG:SetAllPoints(VaultFrame)
    vaultDarkBG:SetTexture(0.04, 0.04, 0.06, 0.78)

    local vaultBG = VaultFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    vaultBG:SetTexture("Interface\\MythicPlus\\textures\\VaultFrame")
    vaultBG:SetAllPoints(VaultFrame)
    vaultBG:SetTexCoord(0, 1, 177/1024, (1024-177)/1024)
    vaultBG:SetAlpha(0.35)

    local title = VaultFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", VaultFrame, "TOP", 0, -40)
    title:SetText(MythicGetText("UI", "Mythic+ Vault"))
    title:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    title:SetTextColor(1, 0.82, 0)
    
    local subtitle = VaultFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText(MythicGetText("UI", "Choose item reward"))
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    subtitle:SetTextColor(0.9, 0.9, 0.9)
    
    local items = {item1, item2, item3}
    local tiers = {tier1, tier2, tier3}
    local selectedIndex = nil
    local itemButtons = {}
    
    for i = 1, 3 do
        if items[i] and items[i] > 0 then
            local button = CreateFrame("Button", nil, VaultFrame)
            button:SetSize(72, 72)
            button:SetPoint("TOP", subtitle, "BOTTOM", -190 + (i-1)*190, -80)
                      
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(button)
            button.icon = icon
            
            local itemTexture = GetItemIcon(items[i])
            if itemTexture then
                icon:SetTexture(itemTexture)
            else
                icon:SetTexture("Interface\\Icons\\inv_misc_questionmark")
            end
            
            local tierLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            tierLabel:SetPoint("TOP", button, "BOTTOM", 0, -5)
            tierLabel:SetText(MythicGetText("UI", "Tier") .. " " .. (tiers[i] or "?"))
            tierLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            tierLabel:SetTextColor(1, 0.82, 0)
            button.tierLabel = tierLabel
                    
            button:SetScript("OnClick", function(self)
                selectedIndex = i
                
                for j, btn in ipairs(itemButtons) do
                    if j == i then
                        btn.icon:SetDesaturated(false)
                        btn.tierLabel:SetTextColor(1, 0.82, 0)
                    else
                        btn.icon:SetDesaturated(true)
                        btn.tierLabel:SetTextColor(0.5, 0.5, 0.5)
                    end
                end
                
                if VaultFrame.confirmButton then
                    VaultFrame.confirmButton:Enable()
                    VaultFrame.confirmButton:SetText("Confirm Selection")
                end
                
                if VaultFrame.selectionText then
                    local itemName, itemLink, itemRarity = GetItemInfo(items[i])
                    if itemLink then
                        VaultFrame.selectionText:SetText("Selected: " .. itemLink)
                    else
                        VaultFrame.selectionText:SetText("Selected: |cffffffff[Unknown Item]|r")
                    end
                    VaultFrame.selectionText:SetTextColor(1, 0.82, 0)
                end
            end)
            
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                
                local itemLink = select(2, GetItemInfo(items[i]))
                if itemLink then
                    GameTooltip:SetHyperlink(tostring(itemLink))
                else
                    print("Item link not found for item ID:", items[i])
                    local tooltipTimer = CreateFrame("Frame")
                    tooltipTimer.elapsed = 0
                    tooltipTimer:SetScript("OnUpdate", function(frame, elapsed)
                        frame.elapsed = frame.elapsed + elapsed
                        if frame.elapsed >= 0.1 then
                            local link = select(2, GetItemInfo(items[i]))
                            if link and GameTooltip:IsOwned(self) then
                                GameTooltip:SetHyperlink(link)
                            end
                            frame:SetScript("OnUpdate", nil)
                        end
                    end)
                end
                GameTooltip:Show()
                
                if selectedIndex ~= i then
                    if not self.highlightTexture then
                        self.highlightTexture = self:CreateTexture(nil, "HIGHLIGHT")
                        self.highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
                        self.highlightTexture:SetAllPoints(self)
                        self.highlightTexture:SetBlendMode("ADD")
                        self.highlightTexture:SetVertexColor(1, 1, 1, 0.3)
                    end
                    self.highlightTexture:Show()
                end
            end)
            button:SetScript("OnLeave", function(self)
                GameTooltip_Hide()
                if self.highlightTexture then
                    self.highlightTexture:Hide()
                end
            end)
            button:SetScript("OnMouseDown", function(self)
                icon:SetPoint("TOPLEFT", 1, -1)
                icon:SetPoint("BOTTOMRIGHT", 1, -1)
            end)
            button:SetScript("OnMouseUp", function(self)
                icon:SetAllPoints(self)
            end)
            itemButtons[i] = button
        end
    end
    
    local selectionText = VaultFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectionText:SetPoint("TOP", VaultFrame, "TOP", 0, -300)
    selectionText:SetText(MythicGetText("UI", "No item selected"))
    selectionText:SetTextColor(1, 0.82, 0)
    selectionText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    VaultFrame.selectionText = selectionText
    
    local confirmButton = CreateFrame("Button", nil, VaultFrame, "UIPanelButtonTemplate")
    confirmButton:SetSize(140, 30)
    confirmButton:SetPoint("BOTTOM", VaultFrame, "BOTTOM", 0, 40)
    confirmButton:SetText(MythicGetText("UI", "Select an Item"))
    confirmButton:Disable()
    VaultFrame.confirmButton = confirmButton
    confirmButton:SetScript("OnClick", function(self)
        if selectedIndex then
            AIO.Handle("AIO_Mythic", "SelectVaultItem", selectedIndex)
            VaultFrame:Hide()
        end
    end)
    
    local cancelButton = CreateFrame("Button", nil, VaultFrame, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 30)
    cancelButton:SetPoint("BOTTOMLEFT", VaultFrame, "BOTTOMLEFT", 20, 40)
    cancelButton:SetText(MythicGetText("UI", "Cancel"))
    cancelButton:SetScript("OnClick", function(self)
        VaultFrame:Hide()
    end)
    VaultFrame:SetScript("OnHide", function(self)
        selectedIndex = nil
    end)
    VaultFrame:Show()
end

function MythicHandlers.CloseVaultGUI()
    if VaultFrame then
        VaultFrame:Hide()
    end
end

function MythicHandlers.UpdateEnemyForces(_, current, required, percentage, completed)
    local ui = MythicBossTimerUI
    if not ui or not ui.enemyLabel then return end
    ui.enemiesCurrent = current
    ui.enemiesRequired = required
    local completedText = completed and "1" or "0"
    ui.enemyLabel:SetText(fmt("%s/1 %s", completedText, MythicGetText("UI", "Enemy Forces")))
    ui.enemyProgressFrame:SetValue(percentage)
    ui.enemyPercentText:SetText(fmt("%.0f%%", percentage))
    if completed then
        ui.enemyLabel:SetTextColor(0.15, 0.76, 0.15)
    else
        ui.enemyLabel:SetTextColor(1, 0.82, 0)
    end
end

function MythicHandlers.ReceiveTotalPoints(_, totalPoints, dungeonScores)
    if not frame.scoreText then return end
    currentTotalPoints = totalPoints or 0
    currentDungeonScores = dungeonScores or {}
    frame.scoreText:SetText(MythicGetText("UI", "Total Score:") .. " " .. string.format("%.2f", currentTotalPoints))
    if UpdateScoreList then
        UpdateScoreList()
    end
end

function MythicHandlers.RestoreRunState(_, runState)
    if not runState or not runState.active then
        MythicPlusCharRunState = {
            active = false,
            mapId = nil,
            tier = nil,
            duration = nil,
            elapsed = nil,
            bossNames = {},
            killedBosses = {},
            potentialGain = 0,
            penalty = 0,
            bonus = 0,
            deaths = 0,
            maxDeaths = 0,
            enemyForces = {
                current = 0,
                required = 0,
                percentage = 0,
                completed = false
            },
            saveTime = nil
        }
        return
    end
    
    MythicPlusCharRunState = runState
    MythicPlusCharRunState.saveTime = GetTime()
    
    MythicHandlers.StartMythicTimerGUI(nil, runState.mapId, runState.tier, runState.duration - runState.elapsed, runState.bossNames, runState.potentialGain, runState.enemyForces.required)
    
    if MythicBossTimerUI then
        MythicBossTimerUI.deaths = runState.deaths
        MythicBossTimerUI.penalty = runState.penalty
        MythicBossTimerUI.maxDeaths = runState.maxDeaths
        
        MythicHandlers.UpdateMythicScore(nil, runState.penalty, runState.deaths)
        
        for _, bossIndex in ipairs(runState.killedBosses) do
            MythicHandlers.MarkBossKilled(nil, runState.mapId, bossIndex)
        end
        
        if runState.enemyForces then
            MythicHandlers.UpdateEnemyForces(nil, runState.enemyForces.current, runState.enemyForces.required, runState.enemyForces.percentage, runState.enemyForces.completed)
        end
        
        if runState.overtime then
            MythicHandlers.StartOvertimeMode()
        end
    end
end

function MythicHandlers.ClearRunState()
    MythicPlusCharRunState = {
        active = false,
        mapId = nil,
        tier = nil,
        duration = nil,
        elapsed = nil,
        bossNames = {},
        killedBosses = {},
        potentialGain = 0,
        penalty = 0,
        bonus = 0,
        deaths = 0,
        maxDeaths = 0,
        enemyForces = {
            current = 0,
            required = 0,
            percentage = 0,
            completed = false
        },
        saveTime = nil
    }
end

function MythicHandlers.StartOvertimeMode()
    if MythicBossTimerUI and MythicBossTimerUI.timerText then
        MythicBossTimerUI.timerText:SetText("|cffff0000OVERTIME|r")
        MythicBossTimerUI.frame.stopped = true
    end
end