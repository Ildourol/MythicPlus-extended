local AIO = AIO or require("AIO")
local L = require("MythicPlus.Mythic_Locale")
MythicHandlers = AIO.AddHandlers("AIO_Mythic", {})

local function GetLocalizedText(player, category, key)
    local localeIndex = player:GetDbLocaleIndex()
    return L:Text(category, key, localeIndex)
end

function MythicHandlers.RequestLocaleData(player, category)
    if category and L[category] and type(L[category]) == "table" then
        AIO.Handle(player, "AIO_Mythic", "ReceiveLocaleData", category, L[category])
    end
end

local AFFIX_EXCLUDE_CREATURES = {
    29830,      -- Living Mojo, Gundrak Boss Drakkari Colossus // would break its boss script
    24849       -- Proto-Drake Rider, Utgarde Keep
}

local MYTHIC_LOOT_BRACKETS = {
    ["low_tier"] = {1, 2, 3},
    ["mid_tier"] = {4, 5, 6, 7},
    ["high_tier"] = {8, 9, 10, 11, 12},
    ["endgame"] = {15, 16, 17, 18, 19, 20},
    ["pets"] = {5, 6, 7, 8, 9},
    ["all"] = "all"
}

local MythicRewardConfig = {
    pets      = true,
    mounts    = true,
    equipment = true,
    spells    = false,
}

local MythicConfig = {
    Enable               = 1,
    NoKeystoneRequired   = 0,     -- Cheat mode: 1 = no key needed, pick any tier; 0 = key strictly required
    AllowKeyReattunement = 0,     -- 0 = Blizzlike strict: key must match dungeon; 1 = allow re-attuning key at fountain
    HeroicBonusChance    = 1.25,  -- 25% higher chance for loot on Heroic
    HeroicExtraEmblem    = 1,     -- +1 extra emblem on Heroic
    HeroicGoldMultiplier = 1.5,   -- +50% gold on Heroic
    HeroicRatingMultiplier = 1.1, -- +10% rating score on Heroic
}

local REQUIRE_KEYSTONE = true
local MAX_SELECTABLE_TIER = 100

local function SaveMythicConfig()
    local writePaths = {
        "lua_scripts/MythicPlus/Mythic_Config.lua",
        "MythicPlus/Mythic_Config.lua"
    }
    for _, path in ipairs(writePaths) do
        local f = io.open(path, "w")
        if f then
            f:write("-- MythicPlus In-Game Configuration File\n")
            f:write("-- This file is dynamically read and saved by the in-game Mythic+ Settings tab.\n\n")
            f:write("MythicConfig = {\n")
            f:write(string.format("    Enable = %d,\n", MythicConfig.Enable or 1))
            f:write(string.format("    NoKeystoneRequired = %d,\n", MythicConfig.NoKeystoneRequired or 0))
            f:write(string.format("    AllowKeyReattunement = %d,\n", MythicConfig.AllowKeyReattunement or 0))
            f:write(string.format("    HeroicBonusChance = %.2f,\n", MythicConfig.HeroicBonusChance or 1.25))
            f:write(string.format("    HeroicExtraEmblem = %d,\n", MythicConfig.HeroicExtraEmblem or 1))
            f:write(string.format("    HeroicGoldMultiplier = %.2f,\n", MythicConfig.HeroicGoldMultiplier or 1.5))
            f:write(string.format("    HeroicRatingMultiplier = %.2f,\n", MythicConfig.HeroicRatingMultiplier or 1.1))
            f:write(string.format("    AllowPlayerConfig = %d,\n", MythicConfig.AllowPlayerConfig or 1))
            f:write("}\n")
            f:close()
            print("[Mythic+] Configuration saved to: " .. path)
            break
        end
    end
end

local function LoadMythicConfig()
    -- 1. Try loading pure Lua configuration file
    local luaPaths = {
        "lua_scripts/MythicPlus/Mythic_Config.lua",
        "MythicPlus/Mythic_Config.lua",
        "Mythic_Config.lua"
    }
    for _, path in ipairs(luaPaths) do
        local chunk = loadfile(path)
        if chunk then
            chunk()
            print("[Mythic+] Configuration loaded from Lua file: " .. path)
            break
        end
    end

    if not MythicConfig then
        MythicConfig = {
            Enable               = 1,
            NoKeystoneRequired   = 0,
            AllowKeyReattunement = 0,
            HeroicBonusChance    = 1.25,
            HeroicExtraEmblem    = 1,
            HeroicGoldMultiplier = 1.5,
            HeroicRatingMultiplier = 1.1,
            AllowPlayerConfig    = 1,
        }
    end

    REQUIRE_KEYSTONE = (MythicConfig.NoKeystoneRequired == 0)
    print(string.format("[Mythic+] Keystone requirement: %s (NoKeystoneRequired=%d, AllowKeyReattunement=%d)",
        REQUIRE_KEYSTONE and "ENABLED (Keys required)" or "DISABLED (Cheat mode active)",
        MythicConfig.NoKeystoneRequired or 0, MythicConfig.AllowKeyReattunement or 0))
end

LoadMythicConfig()

local VAULT_LOOT_BRACKETS = {
    ["vault_low"] = {1, 2, 3, 4, 5},
    ["vault_mid"] = {6, 7, 8, 9, 10},
    ["vault_high"] = {11, 12, 13, 14, 15},
    ["vault_legendary"] = {16, 17, 18, 19, 20},
    ["all"] = "all"
}

local VaultGenerationTracker = {
    lastProcessedDate = nil,
    eventId = nil
}

local VaultItemCache = {}
local VAULT_GAMEOBJECT_ID = 900000
local CLASS_ARMOR_TYPES = {
    [1] = 4,  -- Warrior -> Plate
    [2] = 4,  -- Paladin -> Plate
    [3] = 3,  -- Hunter -> Mail
    [4] = 2,  -- Rogue -> Leather
    [5] = 1,  -- Priest -> Cloth
    [6] = 4,  -- Death Knight -> Plate
    [7] = 3,  -- Shaman -> Mail
    [8] = 1,  -- Mage -> Cloth
    [9] = 1,  -- Warlock -> Cloth
    [11] = 2, -- Druid -> Leather
}
local WEAPON_PROFICIENCY = {
    [176] = {[3] = true, [4] = true, [1] = true}, -- Thrown
    [172] = {[6] = true, [3] = true, [2] = true, [7] = true, [1] = true}, -- Two-Handed Axes
    [43] = {[6] = true, [3] = true, [8] = true, [2] = true, [4] = true, [9] = true, [1] = true}, -- Swords
    [44] = {[6] = true, [3] = true, [2] = true, [7] = true, [1] = true}, -- Axes
    [136] = {[11] = true, [3] = true, [8] = true, [5] = true, [7] = true, [9] = true, [1] = true}, -- Staves
    [160] = {[6] = true, [11] = true, [2] = true, [7] = true, [1] = true}, -- Two-Handed Maces
    [46] = {[3] = true, [4] = true, [1] = true}, -- Guns
    [229] = {[6] = true, [3] = true, [2] = true, [1] = true}, -- Polearms
    [473] = {[11] = true, [3] = true, [4] = true, [7] = true, [1] = true}, -- Fist Weapons
    [54] = {[6] = true, [11] = true, [2] = true, [5] = true, [4] = true, [7] = true, [1] = true}, -- Maces
    [226] = {[3] = true, [4] = true, [1] = true}, -- Crossbows
    [45] = {[3] = true, [4] = true, [1] = true}, -- Bows
    [55] = {[6] = true, [3] = true, [2] = true, [1] = true}, -- Two-Handed Swords
    [228] = {[8] = true, [5] = true, [9] = true}, -- Wands
    [173] = {[11] = true, [3] = true, [8] = true, [5] = true, [4] = true, [7] = true, [9] = true, [1] = true}, -- Daggers
}

local WEAPON_SUBCLASS_TO_SKILL = {
    [0] = 44,
    [1] = 172,
    [2] = 45,
    [3] = 46,
    [4] = 54,
    [5] = 160,
    [6] = 229,
    [7] = 43,
    [8] = 55,
    [10] = 136,
    [13] = 473,
    [15] = 173,
    [16] = 176,
    [18] = 226,
    [19] = 228,
}

local BossNameCache = {
    ["enUS"] = {},
    ["deDE"] = {},
    ["esES"] = {},
    ["esMX"] = {},
    ["frFR"] = {},
    ["koKR"] = {},
    ["ruRU"] = {},
    ["zhCN"] = {},
    ["zhTW"] = {}
}

local function LoadBossNames()
    local bossEntries = {}
    local entriesStr = ""
    
    for mapId, data in pairs(MythicBosses) do
        if data.bosses then
            for _, entry in ipairs(data.bosses) do
                if not bossEntries[entry] then
                    bossEntries[entry] = true
                    if entriesStr ~= "" then
                        entriesStr = entriesStr .. ","
                    end
                    entriesStr = entriesStr .. entry
                end
            end
        end
        if data.heroicBosses then
            for _, entry in ipairs(data.heroicBosses) do
                if not bossEntries[entry] then
                    bossEntries[entry] = true
                    if entriesStr ~= "" then
                        entriesStr = entriesStr .. ","
                    end
                    entriesStr = entriesStr .. entry
                end
            end
        end
    end
    
    if entriesStr == "" then
        print("[Mythic+] No boss entries found to load names for")
        return
    end
    
    local query = WorldDBQuery("SELECT entry, name FROM creature_template WHERE entry IN (" .. entriesStr .. ")")
    local count = 0
    
    if query then
        repeat
            local entry = query:GetUInt32(0)
            local name = query:GetString(1)
            BossNameCache["enUS"][entry] = name
            count = count + 1
        until not query:NextRow()
    end
    
    local locales = {"deDE", "esES", "esMX", "frFR", "koKR", "ruRU", "zhCN", "zhTW"}
    
    for _, locale in ipairs(locales) do
        local localeQuery = WorldDBQuery(
            "SELECT entry, Name FROM creature_template_locale WHERE entry IN (" .. 
            entriesStr .. ") AND locale = '" .. locale .. "'"
        )
        
        if localeQuery then
            local localeCount = 0
            repeat
                local entry = localeQuery:GetUInt32(0)
                local name = localeQuery:GetString(1)
                BossNameCache[locale][entry] = name
                localeCount = localeCount + 1
            until not localeQuery:NextRow()
        end
    end
end

local function GetLocalizedBossNames(player, mapId)
    if not MythicBosses[mapId] or not MythicBosses[mapId].bosses then
        return {}
    end
    
    local localeIndex = player:GetDbLocaleIndex()
    local localeMap = {
        [0] = "enUS", -- Default English
        [1] = "koKR", -- Korean
        [2] = "frFR", -- French
        [3] = "deDE", -- German  
        [4] = "zhCN", -- Chinese (China)
        [5] = "zhTW", -- Chinese (Taiwan)
        [6] = "esES", -- Spanish (Spain)
        [7] = "esMX", -- Spanish (Mexico)
        [8] = "ruRU"  -- Russian
    }
    
    local locale = localeMap[localeIndex] or "enUS"
    local bossNames = {}
    local map = player:GetMap()
    local diff = map and map:GetDifficulty() or 0
    
    for _, bossId in ipairs(MythicBosses[mapId].bosses) do
        local name = BossNameCache[locale][bossId] or 
                    BossNameCache["enUS"][bossId] or 
                    ("Boss #" .. bossId)
        table.insert(bossNames, name)
    end

    if diff == 1 and MythicBosses[mapId].heroicBosses then
        for _, bossId in ipairs(MythicBosses[mapId].heroicBosses) do
            local name = BossNameCache[locale][bossId] or 
                        BossNameCache["enUS"][bossId] or 
                        ("Boss #" .. bossId)
            table.insert(bossNames, name)
        end
    end
    
    return bossNames
end

MythicBosses = {
    -- WotLK Dungeons
    [574] = { -- Utgarde Keep
        bosses = {23953, 24200, 24201, 23954}, final = 23954, timer = 1500, enemies = 45},
    [575] = { -- Utgarde Pinnacle
        bosses = {26668, 26687, 26693, 26861}, final = 26861, timer = 1500, enemies = 52},
    [576] = { -- The Nexus
        bosses = {26731, 26763, 26794, 26723}, final = 26723, timer = 1500, enemies = 38},
    [599] = { -- Halls of Stone
        bosses = {27977, 27975, 27978}, final = 27978, timer = 1500, enemies = 41},
    [600] = { -- Drak'Tharon Keep
        bosses = {26630, 26631, 27483, 26632}, final = 26632, timer = 1500, enemies = 48},
    [601] = { -- Azjol-Nerub
        bosses = {28684, 28921, 29120}, final = 29120, timer = 1500, enemies = 33},
    [602] = { -- Halls of Lightning
        bosses = {28586, 28587, 28546, 28923}, final = 28923, timer = 1500, enemies = 42},
    [604] = { -- Gundrak (Eck the Ferocious is Heroic only)
        bosses = {29304, 29573, 29305, 29306}, heroicBosses = {29932}, final = 29306, timer = 1500, enemies = 55},
    [608] = { -- The Violet Hold
        bosses = {31134}, final = 31134, timer = 1500, enemies = 0},
    [619] = { -- Ahn'kahet: The Old Kingdom (Amanitar is Heroic only)
        bosses = {29309, 29308, 29310, 29311}, heroicBosses = {30258}, final = 29311, timer = 1500, enemies = 46},
    [578] = { -- The Oculus
        bosses = {27654, 27447, 27655, 27656}, final = 27656, timer = 1500, enemies = 35},
    [595] = { -- The Culling of Stratholme
        bosses = {26529, 26530, 26532, 26533}, final = 26533, timer = 1500, enemies = 58},
    [650] = { -- Trial of the Champion
        bosses = {35451}, final = 35451, timer = 1500, enemies = 0},
    [632] = { -- Forge of Souls
        bosses = {36497, 36502}, final = 36502, timer = 1500, enemies = 32},
    [658] = { -- Pit of Saron
        bosses = {36494, 36476, 36658}, final = 36658, timer = 1500, enemies = 44},
    [668] = { -- Halls of Reflection
        bosses = {38112, 38113, 36954}, final = 36954, timer = 1500, enemies = 0},

    -- Vanilla Dungeons
    [389] = { -- Ragefire Chasm
        bosses = {11520, 11517, 11518, 11519}, final = 11519, timer = 1200, enemies = 25},
    [36] = { -- Deadmines (Edwin VanCleef 639 as final)
        bosses = {644, 642, 643, 646, 647, 639}, final = 639, timer = 1800, enemies = 40},
    [43] = { -- Wailing Caverns
        bosses = {3671, 3669, 3670, 3673, 3653, 3674, 3654}, final = 3654, timer = 2100, enemies = 50},
    [33] = { -- Shadowfang Keep (Archmage Arugal 4275 as final)
        bosses = {3886, 3887, 4278, 4279, 4274, 4275}, final = 4275, timer = 1800, enemies = 45},
    [48] = { -- Blackfathom Deeps (Aku'mai 4829 as final)
        bosses = {4887, 4831, 4830, 4832, 4829}, final = 4829, timer = 2100, enemies = 45},
    [34] = { -- The Stockade (Bazil Thredd 1716 as final, removed rare Bruegal)
        bosses = {1666, 1717, 1663, 1665, 1716}, final = 1716, timer = 1200, enemies = 35},
    [90] = { -- Gnomeregan
        bosses = {7079, 6235, 6229, 6231, 7800}, final = 7800, timer = 2100, enemies = 50},
    [47] = { -- Razorfen Kraul
        bosses = {4424, 4428, 4420, 4421}, final = 4421, timer = 1800, enemies = 40},
    [129] = { -- Razorfen Downs (removed rare Glutton)
        bosses = {7355, 7356, 7357, 7358}, final = 7358, timer = 1800, enemies = 40},
    [189] = { -- Scarlet Monastery - Cathedral
        bosses = {4542, 3976, 3977}, final = 3977, timer = 1500, enemies = 30},
    [70] = { -- Uldaman (removed Alliance-friendly Baelog)
        bosses = {6910, 7228, 7023, 7206, 2748}, final = 2748, timer = 2100, enemies = 45},
    [209] = { -- Zul'Farrak
        bosses = {7271, 7272, 8127, 7274, 7275, 7267}, final = 7267, timer = 2100, enemies = 50},
    [349] = { -- Maraudon (Rotgrip 12208 instead of Hydrospawn)
        bosses = {12258, 12236, 12225, 12203, 12208, 12201}, final = 12201, timer = 2400, enemies = 50},
    [109] = { -- Temple of Atal'Hakkar (removed summonable Avatar of Hakkar)
        bosses = {5710, 5719, 5720, 5709}, final = 5709, timer = 2400, enemies = 50},
    [230] = { -- Blackrock Depths
        bosses = {9018, 9016, 9017, 9056, 9024, 9025, 9033, 8983, 9537, 9543, 9502, 9019}, final = 9019, timer = 3000, enemies = 70},
    [229] = { -- Blackrock Spire
        bosses = {9196, 9236, 9237, 9568, 9816, 10429, 10363}, final = 10363, timer = 3000, enemies = 65},
    [429] = { -- Dire Maul - East
        bosses = {14327, 13280, 11490, 11492}, final = 11492, timer = 1800, enemies = 35},
    [289] = { -- Scholomance (removed summonable Kormok and Kirtonos)
        bosses = {10503, 11622, 10433, 10432, 10508, 10505, 1853}, final = 1853, timer = 2400, enemies = 55},
    [329] = { -- Stratholme
        bosses = {10811, 10813, 10436, 10437, 10438, 10435, 10439, 10440}, final = 10440, timer = 2700, enemies = 65},

    -- TBC Dungeons
    [543] = { -- Hellfire Ramparts
        bosses = {17306, 17537, 17307}, final = 17307, timer = 1500, enemies = 40},
    [542] = { -- The Blood Furnace
        bosses = {17381, 17380, 17377}, final = 17377, timer = 1500, enemies = 42},
    [540] = { -- The Shattered Halls (Blood Guard Porung is Heroic only)
        bosses = {16807, 16809, 16808}, heroicBosses = {20923}, final = 16808, timer = 1800, enemies = 50},
    [547] = { -- The Slave Pens
        bosses = {17941, 17991, 17942}, final = 17942, timer = 1500, enemies = 38},
    [546] = { -- The Underbog
        bosses = {17770, 18105, 17826, 17882}, final = 17882, timer = 1500, enemies = 42},
    [545] = { -- The Steamvault
        bosses = {17797, 17796, 17798}, final = 17798, timer = 1600, enemies = 44},
    [557] = { -- Mana-Tombs
        bosses = {18341, 18343, 18344}, final = 18344, timer = 1500, enemies = 38},
    [558] = { -- Auchenai Crypts
        bosses = {18371, 18373}, final = 18373, timer = 1300, enemies = 35},
    [556] = { -- Sethekk Halls
        bosses = {18472, 18473}, final = 18473, timer = 1500, enemies = 40},
    [555] = { -- Shadow Labyrinth (Murmur 18708 as final, Vorpil 18732 added)
        bosses = {18731, 18667, 18732, 18708}, final = 18708, timer = 1800, enemies = 48},
    [560] = { -- Old Hillsbrad Foothills
        bosses = {17848, 17862, 18096}, final = 18096, timer = 1800, enemies = 35},
    [269] = { -- The Black Morass
        bosses = {17879, 17880, 17881}, final = 17881, timer = 1800, enemies = 0},
    [553] = { -- The Botanica
        bosses = {17976, 17975, 17978, 17980, 17977}, final = 17977, timer = 1800, enemies = 48},
    [552] = { -- The Arcatraz
        bosses = {20870, 20885, 20886, 20912}, final = 20912, timer = 1900, enemies = 46},
    [554] = { -- The Mechanar (Sepethrea 19221 added)
        bosses = {19219, 19221, 19220}, final = 19220, timer = 1500, enemies = 40},
    [585] = { -- Magisters' Terrace
        bosses = {24723, 24744, 24560, 24664}, final = 24664, timer = 1600, enemies = 42}
}

LoadBossNames()

local DungeonNames = {
    -- WotLK Dungeons
    [574] = "Utgarde Keep",
    [575] = "Utgarde Pinnacle",
    [576] = "The Nexus",
    [578] = "The Oculus",
    [595] = "The Culling of Stratholme",
    [599] = "Halls of Stone",
    [600] = "Drak'Tharon Keep",
    [601] = "Azjol-Nerub",
    [602] = "Halls of Lightning",
    [604] = "Gundrak",
    [608] = "The Violet Hold",
    [619] = "Ahn'kahet: The Old Kingdom",
    [632] = "The Forge of Souls",
    [650] = "Trial of the Champion",
    [658] = "Pit of Saron",
    [668] = "Halls of Reflection",

    -- Vanilla Dungeons
    [389] = "Ragefire Chasm",
    [36] = "Deadmines",
    [43] = "Wailing Caverns",
    [33] = "Shadowfang Keep",
    [48] = "Blackfathom Deeps",
    [34] = "The Stockade",
    [90] = "Gnomeregan",
    [47] = "Razorfen Kraul",
    [129] = "Razorfen Downs",
    [189] = "Scarlet Monastery",
    [70] = "Uldaman",
    [209] = "Zul'Farrak",
    [349] = "Maraudon",
    [109] = "Temple of Atal'Hakkar",
    [230] = "Blackrock Depths",
    [229] = "Blackrock Spire",
    [429] = "Dire Maul",
    [289] = "Scholomance",
    [329] = "Stratholme",

    -- TBC Dungeons
    [543] = "Hellfire Ramparts",
    [542] = "The Blood Furnace",
    [540] = "The Shattered Halls",
    [547] = "The Slave Pens",
    [546] = "The Underbog",
    [545] = "The Steamvault",
    [557] = "Mana-Tombs",
    [558] = "Auchenai Crypts",
    [556] = "Sethekk Halls",
    [555] = "Shadow Labyrinth",
    [560] = "Old Hillsbrad Foothills",
    [269] = "The Black Morass",
    [553] = "The Botanica",
    [552] = "The Arcatraz",
    [554] = "The Mechanar",
    [585] = "Magisters' Terrace"
}

local function GetLocalizedDungeonName(player, mapId)
    local nameKey = DungeonNames[mapId]
    if nameKey then
        return GetLocalizedText(player, "Dungeons", nameKey)
    else
        return nameKey or ("Unknown (" .. mapId .. ")")
    end
end

local mythicDungeonIds = {
    -- WotLK
    [574]=true, [575]=true, [576]=true, [578]=true, [595]=true,
    [599]=true, [600]=true, [601]=true, [602]=true, [604]=true,
    [608]=true, [619]=true, [632]=true, [650]=true, [658]=true, [668]=true,
    -- Vanilla
    [389]=true, [36]=true, [43]=true, [33]=true, [48]=true, [34]=true,
    [90]=true, [47]=true, [129]=true, [189]=true, [70]=true, [209]=true,
    [349]=true, [109]=true, [230]=true, [229]=true, [429]=true, [289]=true, [329]=true,
    -- TBC
    [543]=true, [542]=true, [540]=true, [547]=true, [546]=true, [545]=true,
    [557]=true, [558]=true, [556]=true, [555]=true, [560]=true, [269]=true,
    [553]=true, [552]=true, [554]=true, [585]=true
}

local allSupportedDungeonIds = {
    -- WotLK
    574, 575, 576, 578, 595, 599, 600, 601, 602, 604, 608, 619, 632, 650, 658, 668,
    -- Vanilla
    389, 36, 43, 33, 48, 34, 90, 47, 129, 189, 70, 209, 349, 109, 230, 229, 429, 289, 329,
    -- TBC
    543, 542, 540, 547, 546, 545, 557, 558, 556, 555, 560, 269, 553, 552, 554, 585
}

-- Strict mapping: ONLY the last boss of each dungeon/wing qualifies to reward the level 1 key!
local DUNGEON_LAST_BOSSES = {
    -- WotLK Dungeons
    [23954] = 574, -- Utgarde Keep: Ingvar the Plunderer
    [26861] = 575, -- Utgarde Pinnacle: King Ymiron
    [26723] = 576, -- The Nexus: Keristrasza
    [27978] = 599, -- Halls of Stone: Sjonnir The Ironshaper
    [26632] = 600, -- Drak'Tharon Keep: The Prophet Tharon'ja
    [29120] = 601, -- Azjol-Nerub: Anub'arak
    [28923] = 602, -- Halls of Lightning: Loken
    [29306] = 604, -- Gundrak: Gal'darah
    [31134] = 608, -- The Violet Hold: Cyanigosa
    [29311] = 619, -- Ahn'kahet: The Old Kingdom: Herald Volazj
    [27656] = 578, -- The Oculus: Ley-Guardian Eregos
    [26533] = 595, -- Culling of Stratholme: Mal'Ganis
    [35451] = 650, -- Trial of the Champion: The Black Knight
    [35617] = 650, -- Trial of the Champion: The Black Knight (alternate)
    [36502] = 632, -- Forge of Souls: Devourer of Souls
    [36658] = 658, -- Pit of Saron: Scourgelord Tyrannus
    [36954] = 668, -- Halls of Reflection: Escape from Arthas
    [38113] = 668, -- Halls of Reflection: Marwyn

    -- Vanilla Dungeons
    [11519] = 389, -- Ragefire Chasm: Taragaman the Hungerer
    [639]   = 36,  -- Deadmines: Edwin VanCleef
    [3654]  = 43,  -- Wailing Caverns: Mutanus the Devourer
    [4275]  = 33,  -- Shadowfang Keep: Archmage Arugal
    [4829]  = 48,  -- Blackfathom Deeps: Aku'mai
    [1716]  = 34,  -- The Stockade: Bazil Thredd
    [7800]  = 90,  -- Gnomeregan: Mekgineer Thermaplugg
    [4421]  = 47,  -- Razorfen Kraul: Charlga Razorflank
    [7358]  = 129, -- Razorfen Downs: Amnennar the Coldbringer
    -- Scarlet Monastery (Map 189 wings)
    [3977]  = 189, -- SM Cathedral: High Inquisitor Whitemane
    [3976]  = 189, -- SM Cathedral: Scarlet Commander Mograine
    [3975]  = 189, -- SM Armory: Herod
    [6487]  = 189, -- SM Library: Arcanist Doan
    [4543]  = 189, -- SM Graveyard: Bloodmage Thalnos
    [2748]  = 70,  -- Uldaman: Archaedas
    [7267]  = 209, -- Zul'Farrak: Chief Ukorz Sandscalp
    [7275]  = 209, -- Zul'Farrak: Ruuzlu
    [12201] = 349, -- Maraudon: Princess Theradras
    [5709]  = 109, -- Temple of Atal'Hakkar: Shade of Eranikus
    [9019]  = 230, -- Blackrock Depths: Emperor Dagran Thaurissan
    [10363] = 229, -- Blackrock Spire: General Drakkisath (UBRS)
    [9568]  = 229, -- Blackrock Spire: Overlord Wyrmthalak (LBRS)
    -- Dire Maul (Map 429 wings)
    [11492] = 429, -- Dire Maul East: Alzzin the Wildshaper
    [11496] = 429, -- Dire Maul North: King Gordok
    [11487] = 429, -- Dire Maul West: Prince Tortheldrin
    [11486] = 429, -- Dire Maul West: Immol'thar
    [1853]  = 289, -- Scholomance: Darkmaster Gandling
    -- Stratholme (Map 329 wings)
    [10440] = 329, -- Stratholme Undead: Baron Rivendare
    [10813] = 329, -- Stratholme Live: Balnazzar

    -- TBC Dungeons
    [17307] = 543, -- Hellfire Ramparts: Vazruden the Herald
    [17536] = 543, -- Hellfire Ramparts: Nazan
    [17377] = 542, -- The Blood Furnace: Keli'dan the Breaker
    [16808] = 540, -- The Shattered Halls: Warchief Kargath Bladefist
    [17942] = 547, -- The Slave Pens: Quagmirran
    [17882] = 546, -- The Underbog: The Black Stalker
    [17798] = 545, -- The Steamvault: Warlord Kalithresh
    [18344] = 557, -- Mana-Tombs: Nexus-Prince Shaffar
    [18373] = 558, -- Auchenai Crypts: Exarch Maladaar
    [18473] = 556, -- Sethekk Halls: Talon King Ikiss
    [18708] = 555, -- Shadow Labyrinth: Murmur
    [18096] = 560, -- Old Hillsbrad Foothills: Epoch Hunter
    [17881] = 269, -- The Black Morass: Aeonus
    [17977] = 553, -- The Botanica: Warp Splinter
    [20912] = 552, -- The Arcatraz: Harbinger Skyriss
    [19220] = 554, -- The Mechanar: Pathaleon the Calculator
    [24664] = 585, -- Magisters' Terrace: Kael'thas Sunstrider
}

local DEFAULT_FOUNTAIN_SPAWNS = {
    -- WotLK Dungeons
    [574] = {173.299, -92.1371, 12.5535, 2.75347},     -- Utgarde Keep
    [575] = {571.32, -333.858, 110.14, 0.844163},      -- Utgarde Pinnacle
    [576] = {172.834, -10.6004, -16.636, 1.61453},     -- The Nexus
    [578] = {1061.64, 995.343, 361.072, 4.26374},      -- The Oculus
    [595] = {1430.53, 549.692, 35.8522, 2.32704},      -- Culling of Stratholme
    [599] = {1133.13, 811.837, 195.835, 0.0394203},    -- Halls of Stone
    [600] = {-502.675, -513.078, 11.0454, 3.12431},    -- Drak'Tharon Keep
    [601] = {423.48, 802.589, 827.911, 4.61237},       -- Azjol-Nerub
    [602] = {1311.83, 268.017, 53.2948, 0.450539},     -- Halls of Lightning
    [604] = {1889.09, 629.347, 176.694, 2.4522},       -- Gundrak
    [608] = {1819.33, 809.071, 44.3639, 4.73869},      -- The Violet Hold
    [619] = {390.893, -1089.21, 47.3606, 2.55577},     -- Ahn'kahet: The Old Kingdom
    [632] = {4910.44, 2180.07, 638.734, 0.161806},     -- The Forge of Souls
    [650] = {799.102, 609.297, 412.364, 3.01206},      -- Trial of the Champion
    [658] = {435.35, 202.332, 528.718, 1.50715},       -- Pit of Saron
    [668] = {5231.32, 1945.65, 707.695, 5.5679},       -- Halls of Reflection
    -- Vanilla Dungeons
    [389] = {3.81, -14.82, -17.84, 4.39},              -- Ragefire Chasm
    [36]  = {-16.4, -383.07, 61.78, 1.86},             -- Deadmines
    [43]  = {-163.49, 132.9, -73.66, 5.83},            -- Wailing Caverns
    [33]  = {-229.135, 2109.18, 76.8898, 1.267},       -- Shadowfang Keep
    [48]  = {-151.89, 106.96, -39.87, 4.53},           -- Blackfathom Deeps
    [34]  = {54.23, 0.28, -18.34, 6.26},               -- The Stockade
    [90]  = {-332.22, -2.28, -150.86, 2.77},           -- Gnomeregan
    [47]  = {1943.0, 1544.63, 82.0, 1.38},             -- Razorfen Kraul
    [129] = {2592.55, 1107.5, 51.29, 4.74},            -- Razorfen Downs
    [189] = {1688.99, 1053.48, 18.6775, 0.00117},      -- Scarlet Monastery
    [70]  = {-226.8, 49.09, -46.03, 1.39},             -- Uldaman
    [209] = {1213.52, 841.59, 8.93, 6.09},             -- Zul'Farrak
    [349] = {1019.69, -458.31, -43.43, 0.31},          -- Maraudon
    [109] = {-319.24, 99.9, -131.85, 3.19},            -- Temple of Atal'Hakkar
    [230] = {456.929, 34.0923, -68.0896, 4.71239},     -- Blackrock Depths
    [229] = {78.5083, -225.044, 49.839, 5.1},          -- Blackrock Spire
    [429] = {44.4499, -154.822, -2.71201, 0},          -- Dire Maul
    [289] = {196.37, 127.05, 134.91, 6.09},            -- Scholomance
    [329] = {3593.15, -3646.56, 138.5, 5.33},          -- Stratholme
    -- TBC Dungeons
    [543] = {-1355.24, 1641.12, 68.2491, 0.6687},     -- Hellfire Ramparts
    [542] = {-3.9967, 14.6363, -44.8009, 4.88748},     -- The Blood Furnace
    [540] = {-40.8716, -19.7538, -13.8065, 1.11133},   -- The Shattered Halls
    [547] = {120.101, -131.957, -0.801547, 1.47574},   -- The Slave Pens
    [546] = {9.71391, -16.2008, -2.75334, 5.57082},    -- The Underbog
    [545] = {-13.8425, 6.7542, -4.2586, 0},            -- The Steamvault
    [557] = {0.0191, 0.9478, -0.9543, 3.03164},        -- Mana-Tombs
    [558] = {-21.8975, 0.16, -0.1206, 0.0353412},      -- Auchenai Crypts
    [556] = {-4.6811, -0.0930796, 0.0062, 0.0353424},  -- Sethekk Halls
    [555] = {0.488033, -0.215935, -1.12788, 3.15888},  -- Shadow Labyrinth
    [560] = {2741.87, 1315.25, 14.0423, 2.96016},      -- Old Hillsbrad Foothills
    [269] = {-1496.24, 7034.7, 32.5619, 1.75699},      -- The Black Morass
    [553] = {40.0395, -28.613, -1.1189, 2.35856},      -- The Botanica
    [552] = {-1.23165, 0.0143459, -0.204293, 0.0157123},-- The Arcatraz
    [554] = {-28.906, 0.680314, -1.81282, 0.0345509},  -- The Mechanar
    [585] = {7.09, -0.45, -2.8, 0.05}                  -- Magisters' Terrace
}

local MYTHIC_DUNGEON_ENTRANCES = {}

local function CalculateTeleportCoordinates(font_x, font_y, font_z, font_o)
    -- Teleport player 5 yards in front of the fountain, facing the fountain
    local dist = 5.0
    local tp_x = font_x + dist * math.cos(font_o)
    local tp_y = font_y + dist * math.sin(font_o)
    local tp_z = font_z
    local tp_o = (font_o + math.pi) % (2 * math.pi)
    return tp_x, tp_y, tp_z, tp_o
end

local function LoadDungeonEntrances()
    -- Initialize with defaults for all supported dungeons
    for map, spawn in pairs(DEFAULT_FOUNTAIN_SPAWNS) do
        local tp_x, tp_y, tp_z, tp_o = CalculateTeleportCoordinates(spawn[1], spawn[2], spawn[3], spawn[4])
        MYTHIC_DUNGEON_ENTRANCES[map] = {
            map = map,
            x = tp_x,
            y = tp_y,
            z = tp_z,
            o = tp_o
        }
    end

    local q = WorldDBQuery("SELECT map, position_x, position_y, position_z, orientation FROM creature WHERE id = 900001")
    if q then
        local count = 0
        local loaded = {}
        repeat
            local map = q:GetUInt32(0)
            if not loaded[map] then
                loaded[map] = true
                local font_x = q:GetFloat(1)
                local font_y = q:GetFloat(2)
                local font_z = q:GetFloat(3)
                local font_o = q:GetFloat(4)

                local tp_x, tp_y, tp_z, tp_o = CalculateTeleportCoordinates(font_x, font_y, font_z, font_o)

                MYTHIC_DUNGEON_ENTRANCES[map] = {
                    map = map,
                    x = tp_x,
                    y = tp_y,
                    z = tp_z,
                    o = tp_o
                }
                count = count + 1
            end
        until not q:NextRow()
        print(string.format("[Mythic+] Loaded %d dungeon entrances from DB for teleport (5 yards facing fountain).", count))
    else
        print("[Mythic+] Initialized dungeon entrances from fallback table (5 yards facing fountain).")
    end

    WorldDBExecute("UPDATE `npc_text` SET `text0_0` = 'Greetings $N, welcome to the Font of Power.\\n\\nChoose your challenge or enter a custom difficulty to begin.\\n\\nStart Mythic:', `text0_1` = 'Greetings $N, welcome to the Font of Power.\\n\\nChoose your challenge or enter a custom difficulty to begin.\\n\\nStart Mythic:' WHERE `ID` = 900001")
end

local function GetMapEntrance(mapId)
    local loc = MYTHIC_DUNGEON_ENTRANCES[mapId]
    if loc then
        return loc.x, loc.y, loc.z, loc.o
    end
    return 0, 0, 0, 0
end

VaultLootTable = {}
PlayerKeysCache = {}
PlayerVaultCache = {}
local PlayerRatingCache = {}
local PlayerNamesCache = {}
local WeeklyAffixesCache = nil
local ActiveRunsCache = {}
local InstanceKeyRewardedCache = {}
local GiveStartingKeystone

local function GetPlayersInInstance(mapId, instanceId)
    local players = {}
    for _, p in ipairs(GetPlayersInWorld()) do
        if p and p:IsInWorld() and p:GetMapId() == mapId and p:GetInstanceId() == instanceId then
            table.insert(players, p)
        end
    end
    return players
end

local LeaderboardCache = {
    topThree = {},
    dungeonTop = {},
    lastUpdate = 0
}
local LEADERBOARD_CACHE_DURATION = 900 -- 15 minutes

local function LoadPlayerCache(guid)
    if PlayerRatingCache[guid] then return end

    local colList = {}
    for _, mapId in ipairs(allSupportedDungeonIds) do
        table.insert(colList, "`" .. mapId .. "`")
    end
    local colQueryStr = table.concat(colList, ", ")

    CharDBQueryAsync(string.format([[
        SELECT total_points, total_runs, completed_runs, out_of_time_runs, too_many_death_runs,
               %s
        FROM character_mythic_rating WHERE guid = %d
    ]], colQueryStr, guid), function(result)
        if result then
            local cache = {
                total_points = result:GetDouble(0),
                total_runs = result:GetUInt32(1),
                completed_runs = result:GetUInt32(2),
                out_of_time_runs = result:GetUInt32(3),
                too_many_death_runs = result:GetUInt32(4)
            }
            for idx, mapId in ipairs(allSupportedDungeonIds) do
                cache[mapId] = result:GetUInt32(4 + idx)
            end
            PlayerRatingCache[guid] = cache
        else
            local cache = {
                total_points = 0,
                total_runs = 0,
                completed_runs = 0,
                out_of_time_runs = 0,
                too_many_death_runs = 0
            }
            for _, mapId in ipairs(allSupportedDungeonIds) do
                cache[mapId] = 0
            end
            PlayerRatingCache[guid] = cache
        end
    end)
    if not PlayerKeysCache[guid] then
        local keyQuery = CharDBQuery(string.format("SELECT mapId, tier FROM character_mythic_keys WHERE guid = %d", guid))
        if keyQuery then
            PlayerKeysCache[guid] = {
                mapId = keyQuery:GetUInt32(0),
                tier = keyQuery:GetUInt32(1)
            }
        else
            PlayerKeysCache[guid] = nil
        end
    end
end

local function SavePlayerRatingCache(guid)
    local cache = PlayerRatingCache[guid]
    if not cache then return end

    local colList = {}
    local valList = {}
    local updateList = {}

    for _, mapId in ipairs(allSupportedDungeonIds) do
        local val = cache[mapId] or 0
        table.insert(colList, "`" .. mapId .. "`")
        table.insert(valList, tostring(val))
        table.insert(updateList, string.format("`%d` = %d", mapId, val))
    end

    local query = string.format([[
        INSERT INTO character_mythic_rating 
        (guid, total_runs, total_points, completed_runs, out_of_time_runs, too_many_death_runs, %s, last_updated)
        VALUES (%d, %d, %.2f, %d, %d, %d, %s, FROM_UNIXTIME(%d))
        ON DUPLICATE KEY UPDATE
        total_runs = %d, total_points = %.2f, completed_runs = %d, out_of_time_runs = %d, too_many_death_runs = %d,
        %s, last_updated = FROM_UNIXTIME(%d)
    ]],
        table.concat(colList, ", "),
        guid, cache.total_runs, cache.total_points, cache.completed_runs, cache.out_of_time_runs, cache.too_many_death_runs,
        table.concat(valList, ", "), os.time(),
        cache.total_runs, cache.total_points, cache.completed_runs, cache.out_of_time_runs, cache.too_many_death_runs,
        table.concat(updateList, ", "), os.time()
    )

    CharDBQuery(query)
end

local function UpdateLeaderboardCache()
    local now = os.time()
    if now - LeaderboardCache.lastUpdate < LEADERBOARD_CACHE_DURATION then
        return
    end
    
    local top3Query = CharDBQuery([[ SELECT guid, total_points FROM character_mythic_rating ORDER BY total_points DESC LIMIT 3 ]])
    LeaderboardCache.topThree = {}
    if top3Query then
        repeat
            local guid = top3Query:GetUInt32(0)
            local points = top3Query:GetDouble(1)
            local name = PlayerNamesCache[guid]
            if not name then
                local nameQ = CharDBQuery("SELECT name FROM characters WHERE guid = " .. guid)
                if nameQ then
                    name = nameQ:GetString(0)
                    PlayerNamesCache[guid] = name
                else
                    name = "Unknown"
                end
            end
            table.insert(LeaderboardCache.topThree, { name = name, points = points })
        until not top3Query:NextRow()
    end
    
    LeaderboardCache.dungeonTop = {}
    for _, dungeonId in ipairs(allSupportedDungeonIds) do
        local scoreQuery = CharDBQuery("SELECT guid, `" .. dungeonId .. "` FROM character_mythic_rating ORDER BY `" .. dungeonId .. "` DESC LIMIT 1")
        if scoreQuery and scoreQuery:GetUInt32(1) > 0 then
            local guid = scoreQuery:GetUInt32(0)
            local score = scoreQuery:GetUInt32(1)
            local name = PlayerNamesCache[guid]
            if not name then
                local nameQ = CharDBQuery("SELECT name FROM characters WHERE guid = " .. guid)
                if nameQ then
                    name = nameQ:GetString(0)
                    PlayerNamesCache[guid] = name
                else
                    name = "Unknown"
                end
            end
            local bossData = MythicBosses[dungeonId]
            local timerLimit = bossData and bossData.timer or 1500
            local keyQuery = CharDBQuery(string.format([[
                SELECT h.tier, h.member_1, h.member_2, h.member_3, h.member_4, h.member_5
                FROM character_mythic_history h 
                WHERE h.mapId = %d 
                  AND h.completed = 1 
                  AND h.duration <= %d
                  AND h.duration > 0
                ORDER BY h.tier DESC 
                LIMIT 1
            ]], dungeonId, timerLimit))
            
            local highestKey = 0
            local keyHolderNames = {}
            if keyQuery then
                highestKey = keyQuery:GetUInt32(0) or 0
                for i = 1, 5 do
                    local memberGuid = keyQuery:GetUInt32(i)
                    if memberGuid and memberGuid > 0 then
                        local memberName = PlayerNamesCache[memberGuid]
                        if not memberName then
                            local nameQ = CharDBQuery("SELECT name FROM characters WHERE guid = " .. memberGuid)
                            if nameQ then
                                memberName = nameQ:GetString(0)
                                PlayerNamesCache[memberGuid] = memberName
                            else
                                memberName = "Unknown"
                            end
                        end
                        table.insert(keyHolderNames, memberName)
                    end
                end
            end
            LeaderboardCache.dungeonTop[tostring(dungeonId)] = { 
                name = name, 
                score = score,
                highestKey = highestKey,
                keyHolderNames = keyHolderNames
            }
        end
    end
    
    LeaderboardCache.lastUpdate = now
end

local PEDESTAL_NPC_ENTRY = 900001

local WEEKLY_AFFIX_POOL = {
    { spell = 8599, name = "Enrage" },
    { spell = {48441, 61301}, name = "Rejuvenating" },
    { spell = 871, name = "Turtling" },
    { spell = {57662, 57621, 58738, 8515}, name = "Shamanism" },
    { spell = {43015, 43008, 43046, 57531, 12043}, name = "Magus" },
    { spell = {48161, 48066, 6346, 48168, 15286}, name = "Priest Empowered" },
    { spell = {47893, 50589}, name = "Demonism" },
    { spell = 53201, name = "Falling Stars" }
}

local function GetCurrentMythicResetDate()
    local now = os.time()
    local t = os.date("*t", now)
    local daysToSubtract = (t.wday - 4) % 7
    t.day = t.day - daysToSubtract
    t.hour = 6
    t.min = 0
    t.sec = 0
    return os.date("%Y-%m-%d", os.time(t))
end

local function LoadOrRollWeeklyAffixes()
    if WeeklyAffixesCache then return end
    local resetDate = GetCurrentMythicResetDate()
    local result = CharDBQuery(string.format("SELECT affix1, affix2, affix3 FROM character_mythic_weekly_affixes WHERE week_start = '%s'", resetDate))
    if result then
        local names = { result:GetString(0), result:GetString(1), result:GetString(2) }
        WeeklyAffixesCache = {}
        for _, name in ipairs(names) do
            for _, affix in ipairs(WEEKLY_AFFIX_POOL) do
                if affix.name == name then
                    table.insert(WeeklyAffixesCache, affix)
                    break
                end
            end
        end
    else
        local shuffled = {}
        for i = 1, #WEEKLY_AFFIX_POOL do shuffled[i] = WEEKLY_AFFIX_POOL[i] end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        local affix1, affix2, affix3 = shuffled[1], shuffled[2], shuffled[3]
        WeeklyAffixesCache = { affix1, affix2, affix3 }
        CharDBQuery(string.format([[
            INSERT INTO character_mythic_weekly_affixes (week_start, affix1, affix2, affix3)
            VALUES ('%s', '%s', '%s', '%s')
        ]], resetDate, affix1.name, affix2.name, affix3.name))
    end
end

LoadOrRollWeeklyAffixes()

local penaltyPerDeath = 10
local fmt, floor = string.format, math.floor

if MYTHIC_BOSS_KILL_TRACKER == nil then MYTHIC_BOSS_KILL_TRACKER = {} end
if MYTHIC_FLAG_TABLE == nil then MYTHIC_FLAG_TABLE = {} end
if MYTHIC_AFFIXES_TABLE == nil then MYTHIC_AFFIXES_TABLE = {} end
if MYTHIC_LOOP_HANDLERS == nil then MYTHIC_LOOP_HANDLERS = {} end
if MYTHIC_REWARD_CHANCE_TABLE == nil then MYTHIC_REWARD_CHANCE_TABLE = {} end
if MYTHIC_ENEMY_FORCES_TRACKER == nil then MYTHIC_ENEMY_FORCES_TRACKER = {} end

local MythicLootTable = {}
local function LoadMythicLootTable()
    MythicLootTable = {}
    local q = WorldDBQuery("SELECT itemid, itemname, amount, type, faction, loot_bracket, chancePercent, additionalID, additionalType FROM world_mythic_loot")
    if q then
        repeat
            table.insert(MythicLootTable, {
                itemid         = q:GetUInt32(0),
                itemname       = q:GetString(1),
                amount         = q:GetUInt32(2),
                type           = q:GetString(3),
                faction        = q:GetString(4),
                loot_bracket   = q:GetString(5),
                chancePercent  = q:GetFloat(6),
                additionalID   = q:IsNull(7) and nil or q:GetUInt32(7),
                additionalType = q:IsNull(8) and nil or q:GetString(8),
            })
        until not q:NextRow()
    end
    print("[Mythic+] Loaded " .. #MythicLootTable .. " mythic+ loot entries.")
end

local function LoadVaultLootTable()
    local q = WorldDBQuery("SELECT itemid, loot_bracket, chancePercent, faction FROM world_vault_loot")
    if q then
        repeat
            table.insert(VaultLootTable, {
                itemid = q:GetUInt32(0),
                loot_bracket = q:GetString(1),
                chancePercent = q:GetFloat(2),
                faction = q:GetString(3)
            })
        until not q:NextRow()
    end
    print("[Mythic+] Loaded " .. #VaultLootTable .. " vault loot entries.")
end

LoadMythicLootTable()
LoadVaultLootTable()

local function CacheItemTemplate(itemId)
    if VaultItemCache[itemId] then
        return VaultItemCache[itemId]
    end
    local item = GetItemTemplate(itemId)
    if not item then
        VaultItemCache[itemId] = nil
        return nil
    end
    VaultItemCache[itemId] = {
        allowableClass = item:GetAllowableClass(),
        allowableRace = item:GetAllowableRace(),
        class = item:GetClass(),
        subClass = item:GetSubClass(),
        inventoryType = item:GetInventoryType(),
        name = item:GetName(),
        itemLevel = item:GetItemLevel()
    }
    
    return VaultItemCache[itemId]
end

local function HasClassFlag(allowableClass, playerClass)
    if allowableClass == 0 then return true end
    
    local classFlags = {
        [1] = 1,     -- Warrior
        [2] = 2,     -- Paladin  
        [3] = 4,     -- Hunter
        [4] = 8,     -- Rogue
        [5] = 16,    -- Priest
        [6] = 32,    -- Death Knight
        [7] = 64,    -- Shaman
        [8] = 128,   -- Mage
        [9] = 256,   -- Warlock
        [11] = 1024  -- Druid
    }
    
    local playerFlag = classFlags[playerClass]
    if not playerFlag then return false end

    return math.floor(allowableClass / playerFlag) % 2 == 1
end

local function HasRaceFlag(allowableRace, playerRace)
    if allowableRace == 0 then return true end
    
    local raceFlags = {
        [1] = 1,     -- Human
        [2] = 2,     -- Orc
        [3] = 4,     -- Dwarf
        [4] = 8,     -- Night Elf
        [5] = 16,    -- Undead
        [6] = 32,    -- Tauren
        [7] = 64,    -- Gnome
        [8] = 128,   -- Troll
        [10] = 512,  -- Blood Elf
        [11] = 1024  -- Draenei
    }
    
    local playerFlag = raceFlags[playerRace]
    if not playerFlag then return false end
    return math.floor(allowableRace / playerFlag) % 2 == 1
end

local function CanPlayerUseItem(player, itemId)
    local itemData = CacheItemTemplate(itemId)
    if not itemData then return false end
    local playerClass = player:GetClass()
    local playerRace = player:GetRace()
    if not HasClassFlag(itemData.allowableClass, playerClass) then
        return false
    end
    if not HasRaceFlag(itemData.allowableRace, playerRace) then
        return false
    end
    if itemData.class == 4 then
        local playerArmorType = CLASS_ARMOR_TYPES[playerClass]
        if playerArmorType and itemData.subClass > 0 then
            if itemData.subClass > playerArmorType then
                return false
            end
        end
    end
    if itemData.class == 2 then
        local skillId = WEAPON_SUBCLASS_TO_SKILL[itemData.subClass]
        if skillId and WEAPON_PROFICIENCY[skillId] then
            if not WEAPON_PROFICIENCY[skillId][playerClass] then
                return false
            end
        end
    end
    return true
end

local function GetCurrentVaultWeek()
    local now = os.time()
    local t = os.date("*t", now)
    
    -- Find last Wednesday 8 AM
    local daysToSubtract = (t.wday + 3) % 7
    if t.wday == 4 and t.hour < 8 then
        daysToSubtract = daysToSubtract + 7
    end
    
    t.day = t.day - daysToSubtract
    t.hour = 8
    t.min = 0
    t.sec = 0
    
    return os.date("%Y-%m-%d", os.time(t))
end

function LoadPlayerVaultCache(guid)
    local currentWeek = GetCurrentVaultWeek()
    local query = CharDBQuery(string.format([[
        SELECT highest_tier_1, highest_tier_2, highest_tier_3, successful_runs, 
               item_1_id, item_2_id, item_3_id, items_generated, has_collected, can_collect, week_start
        FROM character_mythic_vault 
        WHERE guid = %d AND week_start = '%s'
    ]], guid, currentWeek))
    
    if not query or (query and query:GetUInt32(9) == 0) then
        query = CharDBQuery(string.format([[
            SELECT highest_tier_1, highest_tier_2, highest_tier_3, successful_runs, 
                   item_1_id, item_2_id, item_3_id, items_generated, has_collected, can_collect, week_start
            FROM character_mythic_vault 
            WHERE guid = %d AND can_collect = 1 AND has_collected = 0
            ORDER BY week_start DESC
            LIMIT 1
        ]], guid))
    end

    if query then
        local weekStart = query:GetString(10) or currentWeek
        PlayerVaultCache[guid] = {
            week_start = weekStart,
            highest_tier_1 = query:IsNull(0) and nil or query:GetUInt32(0),
            highest_tier_2 = query:IsNull(1) and nil or query:GetUInt32(1),
            highest_tier_3 = query:IsNull(2) and nil or query:GetUInt32(2),
            successful_runs = query:GetUInt32(3),
            item_1_id = query:IsNull(4) and nil or query:GetUInt32(4),
            item_2_id = query:IsNull(5) and nil or query:GetUInt32(5),
            item_3_id = query:IsNull(6) and nil or query:GetUInt32(6),
            items_generated = query:GetUInt32(7) == 1,
            has_collected = query:GetUInt32(8) == 1,
            can_collect = query:GetUInt32(9) == 1
        }
    else
        PlayerVaultCache[guid] = {
            week_start = currentWeek,
            highest_tier_1 = nil,
            highest_tier_2 = nil,
            highest_tier_3 = nil,
            successful_runs = 0,
            item_1_id = nil,
            item_2_id = nil,
            item_3_id = nil,
            items_generated = false,
            has_collected = false,
            can_collect = false
        }
    end
end

function SavePlayerVaultCache(guid)
    local cache = PlayerVaultCache[guid]
    if not cache then return end
    
    CharDBQuery(string.format([[
        INSERT INTO character_mythic_vault 
        (guid, week_start, highest_tier_1, highest_tier_2, highest_tier_3, successful_runs, 
         item_1_id, item_2_id, item_3_id, items_generated, has_collected, can_collect)
        VALUES (%d, '%s', %s, %s, %s, %d, %s, %s, %s, %d, %d, %d)
        ON DUPLICATE KEY UPDATE
        highest_tier_1 = %s, highest_tier_2 = %s, highest_tier_3 = %s, successful_runs = %d,
        item_1_id = %s, item_2_id = %s, item_3_id = %s, items_generated = %d, has_collected = %d, can_collect = %d
    ]], 
    guid, cache.week_start,
    cache.highest_tier_1 or "NULL", cache.highest_tier_2 or "NULL", cache.highest_tier_3 or "NULL", cache.successful_runs,
    cache.item_1_id or "NULL", cache.item_2_id or "NULL", cache.item_3_id or "NULL", 
    cache.items_generated and 1 or 0, cache.has_collected and 1 or 0, cache.can_collect and 1 or 0,
    cache.highest_tier_1 or "NULL", cache.highest_tier_2 or "NULL", cache.highest_tier_3 or "NULL", cache.successful_runs,
    cache.item_1_id or "NULL", cache.item_2_id or "NULL", cache.item_3_id or "NULL",
    cache.items_generated and 1 or 0, cache.has_collected and 1 or 0, cache.can_collect and 1 or 0))
end

local function GetEligibleVaultLoot(player, tier, faction)
    local eligible = {}
    for _, loot in ipairs(VaultLootTable) do
        if loot.faction ~= "N" and loot.faction ~= faction then
            goto continue
        end
        if not isVaultTierEligibleForBracket(loot.loot_bracket, tier) then
            goto continue
        end
        if not CanPlayerUseItem(player, loot.itemid) then
            goto continue
        end
        table.insert(eligible, loot)
        ::continue::
    end
    return eligible
end

function GenerateVaultItemsForPlayer(player)
    local guid = player:GetGUIDLow()
    local cache = PlayerVaultCache[guid]
    
    if not cache or cache.items_generated or cache.successful_runs == 0 then
        return
    end
    if not player or not player:IsInWorld() then
        return
    end
    
    local faction = player:GetTeam() == 67 and "A" or (player:GetTeam() == 469 and "H" or "N")
    local tiers = {cache.highest_tier_1, cache.highest_tier_2, cache.highest_tier_3}
    local usedItems = {}
    
    for i, tier in ipairs(tiers) do
        if tier then
            local eligible = GetEligibleVaultLoot(player, tier, faction)
            if #eligible > 0 then
                local availableItems = {}

                for _, loot in ipairs(eligible) do
                    if not usedItems[loot.itemid] then
                        table.insert(availableItems, loot)
                    end
                end

                if #availableItems == 0 then
                    availableItems = eligible
                end
                
                local totalWeight = 0
                for _, loot in ipairs(availableItems) do
                    totalWeight = totalWeight + loot.chancePercent
                end
                
                if totalWeight > 0 then
                    local roll = math.random() * totalWeight
                    local currentWeight = 0
                    
                    for _, loot in ipairs(availableItems) do
                        currentWeight = currentWeight + loot.chancePercent
                        if roll <= currentWeight then
                            usedItems[loot.itemid] = true
                            if i == 1 then cache.item_1_id = loot.itemid
                            elseif i == 2 then cache.item_2_id = loot.itemid
                            elseif i == 3 then cache.item_3_id = loot.itemid
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    cache.items_generated = true
    cache.can_collect = (cache.item_1_id or cache.item_2_id or cache.item_3_id) and true or false
    SavePlayerVaultCache(guid)
end

local function UpdateVaultProgress(player, tier, wasSuccessful)
    local guid = player:GetGUIDLow()
    if not PlayerVaultCache[guid] then
        LoadPlayerVaultCache(guid)
    end
    
    local cache = PlayerVaultCache[guid]
    
    if wasSuccessful then
        cache.successful_runs = cache.successful_runs + 1
        local tiers = {cache.highest_tier_1, cache.highest_tier_2, cache.highest_tier_3}
        table.insert(tiers, tier)
        table.sort(tiers, function(a, b) return (a or 0) > (b or 0) end)
        
        cache.highest_tier_1 = tiers[1]
        cache.highest_tier_2 = tiers[2]
        cache.highest_tier_3 = tiers[3]
        
        SavePlayerVaultCache(guid)
    end
end

function WeeklyVaultInteract(event, go, player)
    local guid = player:GetGUIDLow()
    if not PlayerVaultCache[guid] then
        LoadPlayerVaultCache(guid)
    end
    
    local cache = PlayerVaultCache[guid]
    
    if not cache.can_collect or cache.has_collected then
        player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "No loot available in your vault this week."))
        return
    end

    if not cache.items_generated then
        GenerateVaultItemsForPlayer(player)
    end
    
    local tiers = {cache.highest_tier_1, cache.highest_tier_2, cache.highest_tier_3}
    local items = {cache.item_1_id or 0, cache.item_2_id or 0, cache.item_3_id or 0}
    
    local itemLevels = {0, 0, 0}
    for i, itemId in ipairs(items) do
        if itemId and itemId > 0 then
            local itemData = CacheItemTemplate(itemId)
            itemLevels[i] = itemData and itemData.itemLevel or 0
        end
    end
    
    AIO.Handle(player, "AIO_Mythic", "QueryItemData", items[1], items[2], items[3])
    AIO.Handle(player, "AIO_Mythic", "ShowVaultGUI", items[1], items[2], items[3], tiers[1] or 0, tiers[2] or 0, tiers[3] or 0, itemLevels[1], itemLevels[2], itemLevels[3])
    
    local playerGUID = player:GetGUID()
    local goX, goY, goZ = go:GetX(), go:GetY(), go:GetZ()
    local goMapId = go:GetMapId()
    local proximityEventId = CreateLuaEvent(function()
        local p = GetPlayerByGUID(playerGUID)

        if not p then
            return false
        end

        if p:GetMapId() ~= goMapId then
            AIO.Handle(p, "AIO_Mythic", "CloseVaultGUI")
            return false
        end

        local pX, pY, pZ = p:GetX(), p:GetY(), p:GetZ()
        local distance = math.sqrt((pX - goX)^2 + (pY - goY)^2 + (pZ - goZ)^2)
        
        if distance > 6 then
            AIO.Handle(p, "AIO_Mythic", "CloseVaultGUI")
            return false
        end
        
        return true
    end, 1000, 0)
end

function MythicHandlers.SelectVaultItem(player, itemIndex)
    local guid = player:GetGUIDLow()
    local cache = PlayerVaultCache[guid]
    
    if not cache or not cache.can_collect or cache.has_collected then
        player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "No loot available to collect."))
        return
    end
    
    local itemId = nil
    if itemIndex == 1 then itemId = cache.item_1_id
    elseif itemIndex == 2 then itemId = cache.item_2_id
    elseif itemIndex == 3 then itemId = cache.item_3_id
    end
    
    if itemId then
        player:AddItem(itemId, 1)
        cache.has_collected = true
        SavePlayerVaultCache(guid)
        
        local itemData = CacheItemTemplate(itemId)
        local itemName = itemData and itemData.name or "Unknown Item"
        
        AIO.Handle(player, "AIO_Mythic", "UpdateVaultStatus", false)
    end
end

function MythicHandlers.RequestVaultStatus(player)
    if not player or not player:IsInWorld() then
        return
    end
    
    local guid = player:GetGUIDLow()
    if not PlayerVaultCache[guid] then
        LoadPlayerVaultCache(guid)
    end
    
    local cache = PlayerVaultCache[guid]
    
    if cache.successful_runs > 0 and not cache.items_generated and not cache.has_collected then
        GenerateVaultItemsForPlayer(player)
    end
    
    local hasLoot = cache.can_collect and not cache.has_collected
    AIO.Handle(player, "AIO_Mythic", "UpdateVaultStatus", hasLoot)
end

local function ProcessWeeklyVaultGeneration()
    local currentWeek = GetCurrentVaultWeek()
    local query = CharDBQuery(string.format([[
        SELECT DISTINCT guid FROM character_mythic_vault 
        WHERE week_start = '%s' AND successful_runs > 0 AND NOT items_generated
    ]], currentWeek))
    
    if query then
        repeat
            local guid = query:GetUInt32(0)
            local player = GetPlayerByGUID(guid)
            
            if player then
                GenerateVaultItemsForPlayer(player)
            else
                if not PlayerVaultCache[guid] then
                    LoadPlayerVaultCache(guid)
                end

                local cache = PlayerVaultCache[guid]
                if cache then
                    cache.can_collect = true
                    SavePlayerVaultCache(guid)
                end
            end
        until not query:NextRow()
    end
end

local function ScheduleVaultGeneration()
    if VaultGenerationTracker.eventId then
        RemoveEventById(VaultGenerationTracker.eventId)
    end
    
    local now = os.time()
    local t = os.date("*t", now)
    
    local nextWednesday = os.time(t)
    local daysUntilWednesday = (11 - t.wday) % 7
    if daysUntilWednesday == 0 and t.hour >= 8 then
        daysUntilWednesday = 7
    end
    
    nextWednesday = nextWednesday + (daysUntilWednesday * 24 * 60 * 60)
    local wednesdayTable = os.date("*t", nextWednesday)
    wednesdayTable.hour = 8
    wednesdayTable.min = 0
    wednesdayTable.sec = 0
    
    local targetTime = os.time(wednesdayTable)
    local delayMs = (targetTime - now) * 1000
    
    VaultGenerationTracker.eventId = CreateLuaEvent(function()
        local currentDate = os.date("%Y-%m-%d")
        local currentTime = os.date("*t")
        
        if currentTime.wday == 4 and currentTime.hour >= 8 and 
           VaultGenerationTracker.lastProcessedDate ~= currentDate then
            
            VaultGenerationTracker.lastProcessedDate = currentDate
            ProcessWeeklyVaultGeneration()
            print("[Mythic+] Weekly vault generation processed for " .. currentDate)
        end
        
        ScheduleVaultGeneration()
    end, delayMs, 1)
end

local function CheckAndProcessVaultOnStartup()
    local now = os.time()
    local t = os.date("*t", now)
    local currentDate = os.date("%Y-%m-%d")
    
    if t.wday == 4 and t.hour >= 8 and 
       VaultGenerationTracker.lastProcessedDate ~= currentDate then
        
        VaultGenerationTracker.lastProcessedDate = currentDate
        ProcessWeeklyVaultGeneration()
        print("[Mythic+] Weekly vault generation processed on startup for " .. currentDate)
    end
    
    ScheduleVaultGeneration()
end

local function GetAffixSet(tier)
    local affixes = {}
    local baseAffixes = math.min(tier, 4)
    for i = 1, baseAffixes do
        local affix = WeeklyAffixesCache[i]
        if affix then
            if type(affix.spell) == "table" then
                for _, s in ipairs(affix.spell) do
                    table.insert(affixes, s)
                end
            else
                table.insert(affixes, affix.spell)
            end
        end
    end
    
    if tier >= 5 then
        table.insert(affixes, 58549)
    end
    
    return affixes
end

local function GetAffixNameSet(tier)
    local names = {}
    for i = 1, tier do
        local affix = WeeklyAffixesCache[i]
        if affix then
            table.insert(names, affix.name)
        end
    end
    return table.concat(names, ", ")
end

local function LeaveDungeonMap(event, player)
    local mapId = player:GetMapId()
    if not mythicDungeonIds[mapId] then
        AIO.Handle(player, "AIO_Mythic", "KillMythicTimerGUI")
    end
end

local function GetRandomMythicMapId()
    local ids = {}
    for mapId, _ in pairs(mythicDungeonIds) do
        table.insert(ids, mapId)
    end
    return ids[math.random(1, #ids)]
end

local function PlayerHasAnyKeystone(player)
    return player:HasItem(900100)
end

local function IsRunActive(instanceId)
    return MYTHIC_FLAG_TABLE[instanceId] == true
end

local function HasValidKeyForCurrentDungeon(player)
    local guid = player:GetGUIDLow()
    local mapId = player:GetMapId()
    local keyData = PlayerKeysCache[guid]
    return keyData and keyData.mapId == mapId
end

local function CalculateMythicRating(tier, timeRemainingPercent)
    -- https://www.wowhead.com/guide/blizzard-mythic-plus-rating-score-in-game
    -- base rating: 37.5 + (tier * 7.5) + (affixes * 7.5)
    local baseRating = 37.5 + (tier * 7.5)
    local affixCount = math.min(tier, 3)
    local affixBonus = affixCount * 7.5
    
    local totalBaseRating = baseRating + affixBonus
    
    local timeBonus = 0
    if timeRemainingPercent > 0 then
        local bonusPercent = math.min(timeRemainingPercent, 40) / 40
        timeBonus = bonusPercent * 7.5
    else
        local penaltyPercent = math.min(math.abs(timeRemainingPercent), 40) / 40
        timeBonus = -penaltyPercent * 15
    end

    return math.max(0, totalBaseRating + timeBonus)
end

local function CalculateKeystoneUpgrade(timeRemainingPercent, completed)
    if not completed then
        return -1
    end
    
    if timeRemainingPercent >= 40 then
        return 3
    elseif timeRemainingPercent >= 20 then
        return 2
    elseif timeRemainingPercent > 0 then
        return 1
    else
        return -1
    end
end

local function CalculateLootBonus(tier, upgradeLevel)
    tier = tier or 1
    upgradeLevel = upgradeLevel or 0

    local chanceMultiplier = 1.0 + (tier * 0.05)
    local maxItems = 1

    if tier >= 15 then
        maxItems = 3
    elseif tier >= 8 then
        maxItems = 2
    else
        maxItems = 1
    end

    if upgradeLevel == 2 then
        chanceMultiplier = chanceMultiplier * 1.25
    elseif upgradeLevel >= 3 then
        chanceMultiplier = chanceMultiplier * 1.5
        maxItems = maxItems + 1
    end

    return chanceMultiplier, maxItems
end

local function RecalculateTotalPoints(guid)
    local cache = PlayerRatingCache[guid]
    if not cache then return end
    
    local total = 0
    for _, mapId in ipairs(allSupportedDungeonIds) do
        total = total + (cache[mapId] or 0)
    end
    
    local avg = total / #allSupportedDungeonIds
    cache.total_points = avg
    
    SavePlayerRatingCache(guid)
end

local function ApplyAuraToNearbyCreatures(player, affixes, tier)
    local seen = {}
    local map = player:GetMap()
    if not map then
        return
    end

    local MYTHIC_SCAN_RADIUS = 240
    local count = 0

    local creatures = player:GetCreaturesInRange(MYTHIC_SCAN_RADIUS, nil, 1, 1)
    for _, creature in ipairs(creatures) do
        local guid = creature:GetGUIDLow()
        local entry = creature:GetEntry()
        local faction = creature:GetFaction()
        local shouldExclude = false
        for _, excludeId in ipairs(AFFIX_EXCLUDE_CREATURES) do
            if entry == excludeId then
                shouldExclude = true
                break
            end
        end

        if not seen[guid]
            and creature:IsAlive()
            and creature:IsInWorld()
            and not creature:IsPlayer()
            and creature:IsElite()
            and not shouldExclude
            and faction ~= 2 and faction ~= 3 and faction ~= 4
            and faction ~= 31 and faction ~= 35 and faction ~= 188 and faction ~= 1629
            and faction ~= 114 and faction ~= 115 and faction ~= 1
        then
            seen[guid] = true
            count = count + 1
            
            for _, spellId in ipairs(affixes) do
                if spellId == 58549 then
                    if tier >= 5 then
                        local stacks = tier - 4
                        if not creature:HasAura(58549) then
                            creature:AddAura(58549, creature)
                        end
                        local aura = creature:GetAura(58549)
                        if aura then
                            aura:SetStackAmount(stacks)
                        end
                    end
                else
                    if not creature:HasAura(spellId) then
                        creature:AddAura(spellId, creature)
                    end
                end
            end
        end
    end
end

local function DowngradeKeystoneOnFail(player, tier)
    if not REQUIRE_KEYSTONE then return end
    if not player or not player:IsInWorld() then return end
    local guid = player:GetGUIDLow()
    
    local map = player:GetMap()
    local currentMapId = map and map:GetMapId()
    local keyData = PlayerKeysCache[guid]
    local newMapId = (keyData and keyData.mapId) or currentMapId or GetRandomMythicMapId()
    local newTier = math.max(1, (tier or 2) - 1)
    PlayerKeysCache[guid] = {mapId = newMapId, tier = newTier}
    CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, newMapId, newTier))
    
    if not player:HasItem(900100) then
        player:AddItem(900100, 1)
    end
    
    local dungeonName = GetLocalizedDungeonName(player, newMapId)
    player:SendBroadcastMessage(string.format("[Mythic+] %s (%s)", 
        GetLocalizedText(player, "UI", "Your keystone has been downgraded to Tier %d."):format(newTier),
        dungeonName
    ))
    
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then
            MythicHandlers.RequestMapNameAndTier(p)
        end
    end, 200, 1)
end

local function SetEndOfRunUnitFlags(player)
    if not player or not player:IsInWorld() then return end
    local map = player:GetMap()
    if not map then return end
    local instanceId = map:GetInstanceId()

    local UNIT_FLAG_NOT_SELECTABLE = 33554432
    local UNIT_FLAG_NON_ATTACKABLE = 2
    local UNIT_FLAG_IMMUNE_TO_PC = 256
    local UNIT_FLAG_IMMUNE_TO_NPC = 512

    local flagsToAdd = UNIT_FLAG_NOT_SELECTABLE + UNIT_FLAG_NON_ATTACKABLE + UNIT_FLAG_IMMUNE_TO_PC + UNIT_FLAG_IMMUNE_TO_NPC

    local function bitwise_or(a, b)
        local result, bitval = 0, 1
        while a > 0 or b > 0 do
            if (a % 2 == 1) or (b % 2 == 1) then
                result = result + bitval
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            bitval = bitval * 2
        end
        return result
    end

    local creatures = player:GetCreaturesInRange(2000, nil, 1, 1)
    for _, creature in ipairs(creatures) do
        local cMap = creature:GetMap()
        if cMap and cMap:GetInstanceId() == instanceId then
            local currentFlags = creature:GetUnitFlags() or 0
            local newFlags = bitwise_or(currentFlags, flagsToAdd)
            if newFlags ~= currentFlags then
                creature:SetUnitFlags(newFlags)
            end
        end
    end
end

local function CheckHallsOfReflectionProgress(event, player)
    if player:GetMapId() ~= 668 then return end
    local instanceId = player:GetMap():GetInstanceId()
    if not IsRunActive(instanceId) then return end
    local tracker = MYTHIC_BOSS_KILL_TRACKER[instanceId]
    if not tracker then return end
    
    local lichKingStillRemaining = false
    for _, bossEntry in ipairs(tracker.remaining) do
        if bossEntry == 36954 then
            lichKingStillRemaining = true
            break
        end
    end
    
    if not lichKingStillRemaining then return end
    local x, y = player:GetX(), player:GetY()
    local completionPoint = {x = 5265.987, y = 1682.8047}
    local function getDistance2D(x1, y1, x2, y2)
        return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    end
    local distance = getDistance2D(x, y, completionPoint.x, completionPoint.y)
    if distance <= 15 then
        local group = player:GetGroup()
        local members = group and group:GetMembers() or { player }
        for _, member in ipairs(members) do
            if member:IsInWorld() and member:GetMapId() == 668 then
                member:KilledMonsterCredit(36954)
            end
        end

        for i, bossEntry in ipairs(tracker.remaining) do
            if bossEntry == 36954 then
                table.remove(tracker.remaining, i)
                local bossIndex = tracker.indexMap[36954]
                
                for _, member in ipairs(members) do
                    if member:IsInWorld() and member:GetMapId() == 668 then
                        AIO.Handle(member, "AIO_Mythic", "MarkBossKilled", 668, bossIndex)
                    end
                end
                break
            end
        end
        CheckRunCompletion(instanceId, 668)
    end
end

local function StartAuraLoop(player, instanceId, mapId, affixes, interval, tier)
    local guid = player:GetGUIDLow()
    if MYTHIC_LOOP_HANDLERS[instanceId] then
        RemoveEventById(MYTHIC_LOOP_HANDLERS[instanceId])
    end
    local eventId = CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if not p then return end
        if not MYTHIC_FLAG_TABLE[instanceId] then return end
        if p:GetMapId() ~= mapId then
            if p:HasAura(8326) then
                return
            end
            local runData = ActiveRunsCache[instanceId]
            if runData and runData.run_id then
                local now = os.time()
                local duration = math.max(0, now - runData.start_time)
                CharDBQuery(string.format([[ 
                    UPDATE character_mythic_history 
                    SET completed = 2,
                        end_time = FROM_UNIXTIME(%d),
                        duration = %d
                    WHERE run_id = %d
                ]], now, duration, runData.run_id))
                p:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(p, "UI", "You left the dungeon. The run is over."))
                local validPlayer = GetPlayerByGUID(guid)
                if validPlayer and validPlayer:IsInWorld() then
                    SetEndOfRunUnitFlags(validPlayer)
                end
                DowngradeKeystoneOnFail(p, runData.tier)
            end
            AIO.Handle(p, "AIO_Mythic", "KillMythicTimerGUI")
            MYTHIC_FLAG_TABLE[instanceId] = nil
            MYTHIC_AFFIXES_TABLE[instanceId] = nil
            MYTHIC_LOOP_HANDLERS[instanceId] = nil
            MYTHIC_REWARD_CHANCE_TABLE[instanceId] = nil
            ActiveRunsCache[instanceId] = nil
            if eventId ~= nil then
                RemoveEventById(eventId)
            end
            return
        end

        local bossData = MythicBosses[mapId]
        if bossData then
            local runData = ActiveRunsCache[instanceId]
            if runData then
                local now = os.time()
                local elapsed = now - runData.start_time
                
                if elapsed >= (bossData.timer or 900) then
                    local runData = ActiveRunsCache[instanceId]
                    if runData and not runData.overtime_started then
                        runData.overtime_started = true
                        runData.overtime_start_time = now
                        
                        local group = p:GetGroup()
                        local members = group and group:GetMembers() or { p }
                        
                        for _, member in ipairs(members) do
                            if member:IsInWorld() and member:GetMapId() == mapId then
                                AIO.Handle(member, "AIO_Mythic", "StartOvertimeMode")
                                
                                DowngradeKeystoneOnFail(member, runData.tier)
                                
                                member:SendBroadcastMessage(string.format(
                                    "[Mythic+] " .. GetLocalizedText(member, "UI", "Time expired! Tier %d failed. You can continue in overtime for the chance of loot."),
                                    runData.tier
                                ))
                            end
                        end
                        
                        CharDBQuery(string.format([[ 
                            UPDATE character_mythic_history 
                            SET completed = 3
                            WHERE run_id = %d
                        ]], runData.run_id))
                    end
                end
            end
        end

        ApplyAuraToNearbyCreatures(p, affixes, tier)
        if mapId == 668 then
            CheckHallsOfReflectionProgress(nil, p)
        end
    end, interval, 0)
    MYTHIC_LOOP_HANDLERS[instanceId] = eventId
end

local function StartMythicRun(player, creature, tier)
    local map = player:GetMap()
    if not map then
        player:GossipComplete()
        return
    end

    local guid = player:GetGUIDLow()
    local mapId = player:GetMapId()
    local instanceId = map:GetInstanceId()

    if MYTHIC_FLAG_TABLE[instanceId] or ActiveRunsCache[instanceId] then
        player:SendBroadcastMessage("[Mythic+] A Mythic+ challenge is already active in this instance!")
        player:GossipComplete()
        return
    end

    local now = os.time()
    local group = player:GetGroup()
    local members = group and group:GetMembers() or {player}
    local today = os.date("%Y-%m-%d")
    local affixes = GetAffixSet(tier)
    local affixNames = {}

    for i = 1, math.min(tier, 4) do
        local affix = WeeklyAffixesCache[i]
        if affix then
            table.insert(affixNames, affix.name)
        end
    end

    local safeAffixNames = table.concat(affixNames, ", "):gsub("'", "''")
    
    for _, member in ipairs(members) do
        if member:IsInWorld() and member:GetMapId() == mapId then
            local mguid = member:GetGUIDLow()
            if not PlayerRatingCache[mguid] then
                LoadPlayerCache(mguid)
            end
            
            local cache = PlayerRatingCache[mguid]
            if cache then
                cache.total_runs = cache.total_runs + 1
                SavePlayerRatingCache(mguid)
            end
        end
    end

    local guids = {}
    for i = 1, 5 do guids[i] = 0 end
    for i, member in ipairs(members) do
        if i > 5 then break end
        guids[i] = member:GetGUIDLow()
    end

    CharDBQuery(string.format([[ 
        INSERT INTO character_mythic_history (member_1, member_2, member_3, member_4, member_5, date, mapId, instanceId, tier, completed, deaths, affixes)
        VALUES (%d, %d, %d, %d, %d, '%s', %d, %d, %d, 0, 0, '%s');
    ]], guids[1], guids[2], guids[3], guids[4], guids[5], today, mapId, instanceId, tier, safeAffixNames))
    
    local runIdQuery = CharDBQuery("SELECT LAST_INSERT_ID()")
    local runId = runIdQuery and runIdQuery:GetUInt32(0) or 0
    
    local diff = map and map:GetDifficulty() or 0
    ActiveRunsCache[instanceId] = {
        guid = guid,
        mapId = mapId,
        tier = tier,
        diff = diff,
        start_time = nil,
        deaths = 0,
        run_id = runId,
        members = {}
    }
    
    for _, member in ipairs(members) do
        if member:IsInWorld() and member:GetMapId() == mapId then
            table.insert(ActiveRunsCache[instanceId].members, member:GetGUIDLow())
        end
    end

    MYTHIC_FLAG_TABLE[instanceId] = false
    MYTHIC_AFFIXES_TABLE[instanceId] = affixes
    MYTHIC_REWARD_CHANCE_TABLE[instanceId] = tier <= 2 and 1.5 or tier <= 4 and 2.0 or 5.0

    local cache = PlayerRatingCache[guid]
    local currentRating = cache and cache[mapId] or 0
    local potentialGain = CalculateMythicRating(tier, 0)

    -- Teleport party ~5 yards in front of the Font of Power (facing away from it into the dungeon)
    local front_x, front_y, front_z, player_o
    if creature then
        local font_x, font_y, font_z, font_o = creature:GetX(), creature:GetY(), creature:GetZ(), creature:GetO()
        local dist = 5.0
        front_x = font_x + dist * math.cos(font_o)
        front_y = font_y + dist * math.sin(font_o)
        front_z = font_z
        player_o = font_o -- Looking the opposite way of the font (away from it into the dungeon)
    else
        local map_x, map_y, map_z, map_o = GetMapEntrance(mapId)
        front_x, front_y, front_z, player_o = map_x, map_y, map_z, map_o
    end

    local memberGuids = {}
    for _, member in ipairs(members) do
        if member:IsInWorld() and member:GetMapId() == mapId then
            table.insert(memberGuids, member:GetGUID())
            member:NearTeleport(front_x, front_y, front_z, player_o)
            member:SetRooted(true)
        end
    end

    local dungeoncreatures = player:GetCreaturesInRange(2000, nil, 0, 2)
    for _, c in ipairs(dungeoncreatures) do
        c:Respawn()
    end

    for _, memberGuid in ipairs(memberGuids) do
        local member = GetPlayerByGUID(memberGuid)
        if member and member:IsInWorld() and member:GetMapId() == mapId then
            AIO.Handle(member, "AIO_Mythic", "StartCountdown", 10)
        end
    end

    local starterGuid = player:GetGUID()

    CreateLuaEvent(function()
        local starter = GetPlayerByGUID(starterGuid)
        if not starter then return end

        for _, memberGuid in ipairs(memberGuids) do
            local member = GetPlayerByGUID(memberGuid)
            if member and member:IsInWorld() and member:GetMapId() == mapId then
                member:SetRooted(false)
            end
        end
        MYTHIC_FLAG_TABLE[instanceId] = true
        ApplyAuraToNearbyCreatures(starter, affixes, tier)
        StartAuraLoop(starter, instanceId, mapId, affixes, 6000, tier)
        StartBossScanLoop(starter, instanceId, mapId, tier)
        local bossData = MythicBosses[mapId]
        if bossData then
            local tracker = { remaining = {}, indexMap = {}, tier = tier }
            for idx, entry in ipairs(bossData.bosses) do
                tracker.remaining[#tracker.remaining + 1] = entry
                tracker.indexMap[entry] = idx
            end
            MYTHIC_BOSS_KILL_TRACKER[instanceId] = tracker

            local actualStartTime = os.time()
            if ActiveRunsCache[instanceId] then
                ActiveRunsCache[instanceId].start_time = actualStartTime
                
                CharDBQuery(string.format([[
                    UPDATE character_mythic_history
                    SET start_time = FROM_UNIXTIME(%d)
                    WHERE run_id = %d
                ]], actualStartTime, ActiveRunsCache[instanceId].run_id))
            end

            for _, memberGuid in ipairs(memberGuids) do
                local member = GetPlayerByGUID(memberGuid)
                if member and member:IsInWorld() and member:GetMapId() == mapId then
                    AIO.Handle(member, "AIO_Mythic", "StartMythicTimerGUI", mapId, tier, bossData.timer or 900, GetLocalizedBossNames(member, mapId), potentialGain, bossData.enemies or 50)
                end
            end
        end
    end, 10000, 1)

    player:GossipComplete()
end

local function ShowPedestalTierMenu(player, creature)
    player:GossipClearMenu()

    for t = 1, 5 do
        player:GossipMenuAddItem(0, string.format("Tier %d", t), 0, 1000 + t)
    end

    player:GossipMenuAddItem(0, "Desired Tier", 0, 950, true, "Enter Mythic+ Tier (1 - 100):")

    player:GossipMenuAddItem(2, GetLocalizedText(player, "UI", "Step away"), 0, 999)
    player:GossipSendMenu(900001, creature)
end

function Pedestal_OnGossipHello(_, player, creature)
    local map = player:GetMap()
    if not map then
        player:GossipComplete()
        return
    end

    local currentMapId = player:GetMapId()
    local instanceId = map:GetInstanceId()

    if MYTHIC_FLAG_TABLE[instanceId] or ActiveRunsCache[instanceId] then
        player:SendBroadcastMessage("[Mythic+] A Mythic+ challenge is already active in this instance!")
        player:GossipComplete()
        return
    end

    if not mythicDungeonIds[currentMapId] then
        player:SendBroadcastMessage("[Mythic+] This area is not a registered Mythic+ dungeon.")
        player:GossipComplete()
        return
    end

    player:GossipClearMenu()

    if not REQUIRE_KEYSTONE then
        ShowPedestalTierMenu(player, creature)
        return
    end

    if not player:HasItem(900100) then
        player:GossipClearMenu()
        player:GossipComplete()
        player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "You do not have a Mythic Keystone."))
        return
    end

    local guid = player:GetGUIDLow()
    local keyData = PlayerKeysCache[guid]
    if not keyData then
        local keyQuery = CharDBQuery(string.format("SELECT mapId, tier FROM character_mythic_keys WHERE guid = %d", guid))
        if keyQuery then
            keyData = { mapId = keyQuery:GetUInt32(0), tier = keyQuery:GetUInt32(1) }
            PlayerKeysCache[guid] = keyData
        end
    end

    if not keyData then
        player:GossipClearMenu()
        player:GossipComplete()
        player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "You do not have a Mythic Keystone."))
        return
    end

    local tier = keyData.tier or 1

    if not HasValidKeyForCurrentDungeon(player) then
        local keyDungeonName = keyData.mapId and GetLocalizedDungeonName(player, keyData.mapId) or "Unknown"
        local currentDungeonName = GetLocalizedDungeonName(player, currentMapId)

        if MythicConfig.AllowKeyReattunement == 1 then
            player:SendBroadcastMessage(string.format("[Mythic+] Your keystone is attuned to: %s (Tier %d).", keyDungeonName, tier))
            player:GossipMenuAddItem(0, string.format("Keystone attuned to: %s (Tier %d)", keyDungeonName, tier), 0, 999)
            if mythicDungeonIds[currentMapId] then
                player:GossipMenuAddItem(0, string.format("Attune Keystone to %s (Tier %d)", currentDungeonName, tier), 0, 200)
            end
            player:GossipMenuAddItem(2, GetLocalizedText(player, "UI", "Step away"), 0, 999)
            player:GossipSendMenu(900001, creature)
        else
            player:SendBroadcastMessage(string.format("[Mythic+] Your keystone does not fit this dungeon. It is attuned to: %s (Tier %d).", keyDungeonName, tier))
            player:GossipClearMenu()
            player:GossipComplete()
        end
        return
    end

    player:GossipMenuAddItem(5, GetLocalizedText(player, "UI", "Insert Keystone (Tier %d)"):format(tier), 0, 100, false, "", 0)
    if player:IsGM() then
        player:GossipMenuAddItem(0, "[GM] Change Keystone Tier", 0, 951, true, "Enter desired Keystone Tier (1 - 100):")
    end
    player:GossipMenuAddItem(2, GetLocalizedText(player, "UI", "Step away"), 0, 999)
    player:GossipSendMenu(900001, creature)
end

function Pedestal_OnGossipSelect(_, player, creature, _, intid, code)
    if intid == 999 then 
        player:GossipComplete()
        return 
    end

    if intid == 950 then
        if not code or code == "" then
            player:SendBroadcastMessage("[Mythic+] No tier entered.")
            player:GossipComplete()
            return
        end
        local chosenTier = tonumber(code)
        if not chosenTier or chosenTier < 1 then
            player:SendBroadcastMessage(string.format("[Mythic+] Invalid tier '%s'. Please enter a positive number (1 - 100).", tostring(code)))
            player:GossipComplete()
            return
        end
        chosenTier = math.floor(chosenTier)
        if chosenTier > 100 then
            player:SendBroadcastMessage("[Mythic+] Maximum selectable tier is 100.")
            player:GossipComplete()
            return
        end
        player:GossipComplete()
        StartMythicRun(player, creature, chosenTier)
        return
    end

    if intid == 951 then
        if REQUIRE_KEYSTONE and not player:IsGM() then
            player:GossipComplete()
            return
        end
        if not code or code == "" then
            player:SendBroadcastMessage("[Mythic+] No tier entered.")
            player:GossipComplete()
            return
        end
        local chosenTier = tonumber(code)
        if not chosenTier or chosenTier < 1 then
            player:SendBroadcastMessage(string.format("[Mythic+] Invalid tier '%s'. Please enter a positive number (1 - 100).", tostring(code)))
            player:GossipComplete()
            return
        end
        chosenTier = math.floor(chosenTier)
        if chosenTier > 100 then
            player:SendBroadcastMessage("[Mythic+] Maximum selectable tier is 100.")
            player:GossipComplete()
            return
        end
        local currentMapId = player:GetMapId()
        local guid = player:GetGUIDLow()
        PlayerKeysCache[guid] = {mapId = currentMapId, tier = chosenTier}
        CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, currentMapId, chosenTier))
        local currentDungeonName = GetLocalizedDungeonName(player, currentMapId)
        player:SendBroadcastMessage(string.format("[Mythic+] Keystone attuned to: %s (Tier %d)!", currentDungeonName, chosenTier))
        Pedestal_OnGossipHello(_, player, creature)
        return
    end

    if intid == 200 then
        if REQUIRE_KEYSTONE and MythicConfig.AllowKeyReattunement ~= 1 and not player:IsGM() then
            player:SendBroadcastMessage("[Mythic+] Keystone re-attunement is disabled on this server.")
            player:GossipComplete()
            return
        end
        local currentMapId = player:GetMapId()
        if not mythicDungeonIds[currentMapId] then
            player:SendBroadcastMessage("[Mythic+] This area is not a registered Mythic+ dungeon.")
            player:GossipComplete()
            return
        end

        local guid = player:GetGUIDLow()
        local keyData = PlayerKeysCache[guid]
        local tier = keyData and keyData.tier or 1
        PlayerKeysCache[guid] = {mapId = currentMapId, tier = tier}
        CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, currentMapId, tier))
        
        local currentDungeonName = GetLocalizedDungeonName(player, currentMapId)
        player:SendBroadcastMessage(string.format("[Mythic+] Keystone successfully attuned to: %s (Tier %d)!", currentDungeonName, tier))
        
        Pedestal_OnGossipHello(_, player, creature)
        return
    end

    if not REQUIRE_KEYSTONE and intid >= 1001 and intid <= (1000 + MAX_SELECTABLE_TIER) then
        local selectedTier = intid - 1000
        StartMythicRun(player, creature, selectedTier)
        return
    end

    if REQUIRE_KEYSTONE and intid == 100 then
        if not player:HasItem(900100) then
            player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "You do not have a Mythic Keystone."))
            player:GossipComplete()
            return
        end

        if not HasValidKeyForCurrentDungeon(player) then
            player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "This keystone is not for this dungeon."))
            player:GossipComplete()
            return
        end

        local guid = player:GetGUIDLow()
        local keyData = PlayerKeysCache[guid]
        local tier = keyData and keyData.tier or 1
        StartMythicRun(player, creature, tier)
        return
    end
end

function StartBossScanLoop(player, instanceId, mapId, tier)
    local bosses = MythicBosses[mapId]
    if not bosses or not bosses.bosses then
        print("[Mythic+][Error] No boss data for mapId: " .. mapId)
        return
    end

    local map = player:GetMap()
    local diff = map and map:GetDifficulty() or 0
    local allActiveBosses = {}

    MYTHIC_BOSS_KILL_TRACKER[instanceId] = {
        remaining = {},
        indexMap = {},
        tier = tier,
        diff = diff
    }

    for _, entry in ipairs(bosses.bosses) do
        table.insert(allActiveBosses, entry)
    end

    if diff == 1 and bosses.heroicBosses then
        for _, entry in ipairs(bosses.heroicBosses) do
            table.insert(allActiveBosses, entry)
        end
    end

    for idx, entry in ipairs(allActiveBosses) do
        table.insert(MYTHIC_BOSS_KILL_TRACKER[instanceId].remaining, entry)
        MYTHIC_BOSS_KILL_TRACKER[instanceId].indexMap[entry] = idx
    end
end

local function HandleDungeonEndbossReward(creature, killer)
    if not creature then return end
    local map = creature:GetMap()
    if not map then return end
    local mapId = map:GetMapId()
    if not mythicDungeonIds[mapId] then return end

    local instanceId = map:GetInstanceId()
    if MYTHIC_FLAG_TABLE[instanceId] or ActiveRunsCache[instanceId] then return end

    local entry = creature:GetEntry()
    local targetMapId = DUNGEON_LAST_BOSSES[entry]

    -- STRICT REQUIREMENT: Only the true LAST boss of this dungeon/wing awards the level 1 Mythic Keystone!
    if not targetMapId or targetMapId ~= mapId then
        return
    end

    if InstanceKeyRewardedCache[instanceId] then
        return
    end
    InstanceKeyRewardedCache[instanceId] = true

    local player = nil
    if killer then
        if killer:IsPlayer() then
            player = killer:ToPlayer()
        elseif killer.GetOwner and killer:GetOwner() and killer:GetOwner():IsPlayer() then
            player = killer:GetOwner():ToPlayer()
        end
    end

    local members = {}
    if player and player:IsInWorld() and player:GetMapId() == mapId then
        local group = player:GetGroup()
        members = group and group:GetMembers() or { player }
    else
        members = creature:GetPlayersInRange(250)
        if #members == 0 then
            members = GetPlayersInInstance(mapId, instanceId)
        end
    end

    for _, member in ipairs(members) do
        if member and member:IsInWorld() and member:GetMapId() == mapId then
            GiveStartingKeystone(member, mapId)
        end
    end
end

local function ProcessBossDeath(creature, killer)
    if not creature then return end
    local map = creature:GetMap()
    if not map then return end
    local mapId = map:GetMapId()
    local instanceId = map:GetInstanceId()
    local entry = creature:GetEntry()

    local player = nil
    if killer then
        if killer:IsPlayer() then
            player = killer:ToPlayer()
        elseif killer.GetOwner and killer:GetOwner() and killer:GetOwner():IsPlayer() then
            player = killer:GetOwner():ToPlayer()
        end
    end

    if IsRunActive(instanceId) then
        local tracker = MYTHIC_BOSS_KILL_TRACKER[instanceId]
        if tracker and tracker.remaining then
            local NO_CORPSE_REMOVE_IDS = {
                [26692] = true, -- 'Ymirjar Harpooner' in Utgarde Pinnacle // would not spawn harpoons otherwise
                [28585] = true, -- 'Slag' in Halls of Lightning // respawn would be too fast
            }

            if not NO_CORPSE_REMOVE_IDS[entry] then
                creature:RemoveCorpse()
            end

            for i, bossEntry in ipairs(tracker.remaining) do
                if bossEntry == entry then
                    table.remove(tracker.remaining, i)
                    local bossIndex = tracker.indexMap and tracker.indexMap[entry] or 1
                    local members = {}
                    if player and player:IsInWorld() and player:GetMapId() == mapId then
                        local group = player:GetGroup()
                        members = group and group:GetMembers() or { player }
                    else
                        members = GetPlayersInInstance(mapId, instanceId)
                    end
                    for _, member in ipairs(members) do
                        if member and member:IsInWorld() and member:GetMapId() == mapId then
                            AIO.Handle(member, "AIO_Mythic", "MarkBossKilled", mapId, bossIndex)
                        end
                    end
                    break
                end
            end

            if #tracker.remaining == 0 then
                CheckRunCompletion(instanceId, mapId)
            end
        end
    else
        HandleDungeonEndbossReward(creature, killer)
    end
end

local function MythicBossKillCheck(event, player, killed)
    ProcessBossDeath(killed, player)
end

if MYTHIC_ENEMY_FORCES_TRACKER == nil then MYTHIC_ENEMY_FORCES_TRACKER = {} end
local function MythicEnemyKillCheck(event, player, killed)
    local map = player:GetMap()
    if not map then return end
    local mapId = map:GetMapId()
    local instanceId = map:GetInstanceId()
    if not IsRunActive(instanceId) then return end
    local entry = killed:GetEntry()
    local bossData = MythicBosses[mapId]
    if not bossData then return end
    if not bossData.enemies or bossData.enemies == 0 then
        return
    end
    for _, bossEntry in ipairs(bossData.bosses) do
        if bossEntry == entry then
            return
        end
    end

    local faction = killed:GetFaction()
    if faction == 2 or faction == 3 or faction == 4 or faction == 31 or faction == 35 or 
       faction == 188 or faction == 1629 or faction == 114 or faction == 115 or faction == 1 then
        return
    end

    if not MYTHIC_ENEMY_FORCES_TRACKER[instanceId] then
        MYTHIC_ENEMY_FORCES_TRACKER[instanceId] = {
            current = 0,
            required = bossData.enemies or 50,
            completed = false
        }
    end

    local tracker = MYTHIC_ENEMY_FORCES_TRACKER[instanceId]
    tracker.current = tracker.current + 1
    local percentage = math.min((tracker.current / tracker.required) * 100, 100)
    if tracker.current >= tracker.required and not tracker.completed then
        tracker.completed = true
    end

    local group = player:GetGroup()
    local members = group and group:GetMembers() or { player }
    for _, member in ipairs(members) do
        if member:IsInWorld() and member:GetMapId() == mapId then
            AIO.Handle(member, "AIO_Mythic", "UpdateEnemyForces", tracker.current, tracker.required, percentage, tracker.completed)
        end
    end
    CheckRunCompletion(instanceId, mapId)
end

function CheckRunCompletion(instanceId, mapId)
    local bossTracker = MYTHIC_BOSS_KILL_TRACKER[instanceId]
    local enemyTracker = MYTHIC_ENEMY_FORCES_TRACKER[instanceId]
    local bossData = MythicBosses[mapId]
    local bossesComplete = bossTracker and #bossTracker.remaining == 0
    local enemyForcesComplete = true
    if bossData and bossData.enemies and bossData.enemies > 0 then
        enemyForcesComplete = enemyTracker and enemyTracker.completed
    end
    
    if bossesComplete and enemyForcesComplete then
        local runData = ActiveRunsCache[instanceId]
        if not runData then return end
        
        local player = GetPlayerByGUID(runData.guid)
        local members = {}
        if player and player:IsInWorld() and player:GetMapId() == mapId then
            local group = player:GetGroup()
            members = group and group:GetMembers() or { player }
        else
            for _, p in ipairs(GetPlayersInInstance(mapId, instanceId)) do
                if p:IsInWorld() then
                    local grp = p:GetGroup()
                    members = grp and grp:GetMembers() or { p }
                    player = p
                    break
                end
            end
        end
        if not player or #members == 0 then return end
        
        local now = os.time()
        local bossData = MythicBosses[mapId]
        local timerTotal = bossData and bossData.timer or 900

        if not runData.start_time then return end
        
        local startTimeRaw = runData.start_time
        local deaths = runData.deaths or 0
        local duration = math.max(0, now - startTimeRaw)
        local remainingTime = math.max(0, timerTotal - duration)
        local runId = runData.run_id
        local wasOvertime = runData.overtime_started or false

        if runId and runId > 0 then
            CharDBQuery(string.format([[ 
                UPDATE character_mythic_history
                SET completed = 1,
                    end_time  = FROM_UNIXTIME(%d),
                    duration  = %d
                WHERE run_id = %d;
            ]], now, duration, runId))
        end

        local diff = (bossTracker and bossTracker.diff) or (runData and runData.diff) or (map and map:GetDifficulty()) or 0
        for _, member in ipairs(members) do
            if member:IsInWorld() and member:GetMapId() == mapId then
                if wasOvertime then
                    AwardOvertimeLoot(member, bossTracker.tier, diff)
                else
                    AwardMythicPoints(member, bossTracker.tier, duration, deaths, remainingTime, diff)
                end
                SetEndOfRunUnitFlags(member)
            end
        end

        MYTHIC_BOSS_KILL_TRACKER[instanceId] = nil
        MYTHIC_ENEMY_FORCES_TRACKER[instanceId] = nil
        MYTHIC_FLAG_TABLE[instanceId] = nil
        MYTHIC_AFFIXES_TABLE[instanceId] = nil
        MYTHIC_REWARD_CHANCE_TABLE[instanceId] = nil
        ActiveRunsCache[instanceId] = nil
        InstanceKeyRewardedCache[instanceId] = nil
        if MYTHIC_LOOP_HANDLERS[instanceId] then
            RemoveEventById(MYTHIC_LOOP_HANDLERS[instanceId])
            MYTHIC_LOOP_HANDLERS[instanceId] = nil
        end
    end
end

local function MythicPlayerDeath(event, killer, killed)
    local map = killed:GetMap()
    if not map then return end

    local instanceId = map:GetInstanceId()
    local runData = ActiveRunsCache[instanceId]
    if not runData then return end

    runData.deaths = runData.deaths + 1
    local newDeaths = runData.deaths
    local tier = runData.tier
    CharDBQuery("UPDATE character_mythic_history SET deaths = " .. newDeaths .. " WHERE run_id = " .. runData.run_id)
    local penalty = newDeaths * penaltyPerDeath
    local group   = killed:GetGroup()
    local members = group and group:GetMembers() or { killed }
    for _, member in ipairs(members) do
        if member:IsInWorld() and member:GetMapId() == map:GetMapId() then
            AIO.Handle(member, "AIO_Mythic", "UpdateMythicScore", penalty, newDeaths)
        end
    end

    local limit = (tier == 1) and 6 or 4
    if newDeaths >= limit then
        local now = os.time()
        local startTime = runData.start_time
        if not startTime then return end
        local duration = math.max(0, now - startTime)
        local runId = runData.run_id
        CharDBQuery(string.format([[ 
            UPDATE character_mythic_history 
            SET completed = 2,
                end_time = FROM_UNIXTIME(%d),
                duration = %d
            WHERE run_id = %d
        ]], now, duration, runId))

        for _, member in ipairs(members) do
            if member:IsInWorld() and member:GetMapId() == map:GetMapId() then
                local mguid = member:GetGUIDLow()
                local cache = PlayerRatingCache[mguid]
                if cache then
                    cache.too_many_death_runs = cache.too_many_death_runs + 1
                    SavePlayerRatingCache(mguid)
                end
                AIO.Handle(member, "AIO_Mythic", "StopMythicTimerGUI", 0)
                DowngradeKeystoneOnFail(member, tier)
            end
        end

        MYTHIC_FLAG_TABLE[instanceId] = nil
        MYTHIC_AFFIXES_TABLE[instanceId] = nil
        MYTHIC_REWARD_CHANCE_TABLE[instanceId] = nil
        ActiveRunsCache[instanceId] = nil
        MYTHIC_ENEMY_FORCES_TRACKER[instanceId] = nil
        if MYTHIC_LOOP_HANDLERS[instanceId] then
            RemoveEventById(MYTHIC_LOOP_HANDLERS[instanceId])
            MYTHIC_LOOP_HANDLERS[instanceId] = nil
        end
    end
end

GiveStartingKeystone = function(player, targetMapId)
    if not player or not player:IsInWorld() then return false end
    local guid = player:GetGUIDLow()

    local newMapId = targetMapId
    if not newMapId or not mythicDungeonIds[newMapId] then
        newMapId = GetRandomMythicMapId()
    end
    local newTier = 1

    -- Ensure PlayerKeysCache is loaded
    if not PlayerKeysCache[guid] then
        local q = CharDBQuery(string.format("SELECT mapId, tier FROM character_mythic_keys WHERE guid = %d", guid))
        if q then
            PlayerKeysCache[guid] = { mapId = q:GetUInt32(0), tier = q:GetUInt32(1) }
        end
    end

    -- If player already has a keystone in bags and DB with tier > 1, protect their higher tier progression
    if PlayerHasAnyKeystone(player) and PlayerKeysCache[guid] and PlayerKeysCache[guid].tier > 1 then
        player:SendBroadcastMessage(string.format("[Mythic+] You completed the dungeon! Your higher-tier keystone (+%d) is preserved.", PlayerKeysCache[guid].tier))
        return false
    end

    PlayerKeysCache[guid] = { mapId = newMapId, tier = newTier }
    CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, newMapId, newTier))

    if not player:HasItem(900100) then
        player:AddItem(900100, 1)
    end

    local dungeonName = GetLocalizedDungeonName(player, newMapId)
    player:SendBroadcastMessage(string.format("[Mythic+] %s (%s - Mythic +%d)", 
        GetLocalizedText(player, "UI", "You received a Mythic Keystone!"), dungeonName, newTier))

    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then
            MythicHandlers.RequestMapNameAndTier(p)
        end
    end, 200, 1)

    return true
end

local function CheckMalGanisEvade(event, creature)
    if creature:GetEntry() ~= 26533 then return end
    local map = creature:GetMap()
    if not map or map:GetMapId() ~= 595 then return end
    local instanceId = map:GetInstanceId()
    if creature:IsInEvadeMode() then
        local players = creature:GetPlayersInRange(100)
        if IsRunActive(instanceId) then
            for _, player in ipairs(players) do
                if player:IsInWorld() and player:GetMapId() == 595 then
                    player:KilledMonsterCredit(26533)
                    local group = player:GetGroup()
                    local members = group and group:GetMembers() or { player }
                    local tracker = MYTHIC_BOSS_KILL_TRACKER[instanceId]
                    if tracker then
                        for i, bossEntry in ipairs(tracker.remaining) do
                            if bossEntry == 26533 then
                                table.remove(tracker.remaining, i)
                                local bossIndex = tracker.indexMap and tracker.indexMap[26533] or 4
                                for _, member in ipairs(members) do
                                    if member:IsInWorld() and member:GetMapId() == 595 then
                                        AIO.Handle(member, "AIO_Mythic", "MarkBossKilled", 595, bossIndex)
                                    end
                                end
                                break
                            end
                        end
                        if #tracker.remaining == 0 then
                            CheckRunCompletion(instanceId, 595)
                        end
                    end
                end
            end
        else
            if not InstanceKeyRewardedCache[instanceId] then
                InstanceKeyRewardedCache[instanceId] = true
                for _, player in ipairs(players) do
                    if player:IsInWorld() and player:GetMapId() == 595 then
                        GiveStartingKeystone(player, 595)
                    end
                end
            end
        end
    end
end

local function isTierEligibleForBracket(bracket, tier)
    if MYTHIC_LOOT_BRACKETS[bracket] then
        local bracketData = MYTHIC_LOOT_BRACKETS[bracket]
        if bracketData == "all" then
            return true
        elseif type(bracketData) == "table" then
            for _, validTier in ipairs(bracketData) do
                if validTier == tier then
                    return true
                end
            end
            return false
        end
    end
    
    if bracket == "all" then
        return true
    end

    local singleTier = tonumber(bracket)
    if singleTier then
        return tier == singleTier
    end
    
    local rangeStart, rangeEnd = bracket:match("^(%d+)-(%d+)$")
    if rangeStart and rangeEnd then
        rangeStart, rangeEnd = tonumber(rangeStart), tonumber(rangeEnd)
        return tier >= rangeStart and tier <= rangeEnd
    end
    
    local minTier = bracket:match("^(%d+)%+$")
    if minTier then
        minTier = tonumber(minTier)
        return tier >= minTier
    end
    
    local maxTier = bracket:match("^(%d+)-$")
    if maxTier then
        maxTier = tonumber(maxTier)
        return tier <= maxTier
    end
    return false
end

function isVaultTierEligibleForBracket(bracket, tier)
    if bracket == "vault_legendary" and tier >= 16 then
        return true
    end

    if VAULT_LOOT_BRACKETS[bracket] then
        local bracketData = VAULT_LOOT_BRACKETS[bracket]
        if bracketData == "all" then
            return true
        elseif type(bracketData) == "table" then
            for _, validTier in ipairs(bracketData) do
                if validTier == tier then
                    return true
                end
            end
            return false
        end
    end
    
    if bracket == "all" then
        return true
    end
    
    local singleTier = tonumber(bracket)
    if singleTier then
        return tier == singleTier
    end
    
    local rangeStart, rangeEnd = bracket:match("^(%d+)-(%d+)$")
    if rangeStart and rangeEnd then
        rangeStart, rangeEnd = tonumber(rangeStart), tonumber(rangeEnd)
        return tier >= rangeStart and tier <= rangeEnd
    end
    
    local minTier = bracket:match("^(%d+)%+$")
    if minTier then
        minTier = tonumber(minTier)
        return tier >= minTier
    end
    
    local maxTier = bracket:match("^(%d+)-$")
    if maxTier then
        maxTier = tonumber(maxTier)
        return tier <= maxTier
    end
    
    return false
end

local function TryRewardMythicLoot(player, tier, upgradeLevel, diff)
    tier = tier or 1
    upgradeLevel = upgradeLevel or 0
    diff = diff or 0
    local isHeroic = (diff == 1)
    local faction = player:GetTeam() == 67 and "A" or (player:GetTeam() == 469 and "H" or "N")
    local eligible = {}
    local chanceMultiplier, maxItems = CalculateLootBonus(tier, upgradeLevel)
    if isHeroic then
        chanceMultiplier = chanceMultiplier * (MythicConfig.HeroicBonusChance or 1.25)
        maxItems = maxItems + 1
        player:SendBroadcastMessage("[Mythic+] (Heroic Bonus) Enhanced loot chances applied!")
    end

    for _, loot in ipairs(MythicLootTable) do
        if loot.type == "pet"   and not MythicRewardConfig.pets      then goto continue end
        if loot.type == "mount" and not MythicRewardConfig.mounts    then goto continue end
        if loot.type == "gear"  and not MythicRewardConfig.equipment then goto continue end
        if loot.type == "spell" and not MythicRewardConfig.spells    then goto continue end
        if not isTierEligibleForBracket(loot.loot_bracket, tier) then goto continue end
        if loot.faction ~= "N" and loot.faction ~= faction then goto continue end
        if loot.type == "gear" then
            if not CanPlayerUseItem(player, loot.itemid) then goto continue end
        end

        table.insert(eligible, loot)
        ::continue::
    end

    local rewardsGiven = 0
    local awardedItems = {}

    local function DeliverReward(reward)
        if reward.type == "gear" or reward.type == "pet" or reward.type == "mount" or reward.type == "item" then
            player:AddItem(reward.itemid, reward.amount or 1)
            local itemData = CacheItemTemplate(reward.itemid)
            local itemName = itemData and itemData.name or reward.itemname or "Item #" .. tostring(reward.itemid)
            player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "Reward:") .. " " .. itemName)
        elseif reward.type == "spell" then
            player:LearnSpell(reward.itemid)
            player:SendBroadcastMessage("[Mythic+] " .. GetLocalizedText(player, "UI", "Reward: Spell learned!"))
        end

        if reward.additionalID and reward.additionalType then
            if reward.additionalType == "item" then
                player:AddItem(reward.additionalID, 1)
            elseif reward.additionalType == "spell" then
                player:LearnSpell(reward.additionalID)
            elseif reward.additionalType == "skill" then
                player:AdvanceSkill(reward.additionalID, 1)
            end
        end

        awardedItems[reward.itemid] = true
        rewardsGiven = rewardsGiven + 1
    end

    -- 1. Attempt bonus rolls on eligible items
    if #eligible > 0 then
        for attempt = 1, maxItems do
            if rewardsGiven >= maxItems then break end
            
            local availableItems = {}
            for _, loot in ipairs(eligible) do
                if not awardedItems[loot.itemid] then
                    table.insert(availableItems, loot)
                end
            end
            
            if #availableItems == 0 then break end
            
            local reward = availableItems[math.random(1, #availableItems)]
            local adjustedChance = reward.chancePercent * chanceMultiplier
            if math.random() * 100 <= adjustedChance then
                DeliverReward(reward)
            end
        end

        -- 2. Guaranteed Loot: if RNG didn't give any item, guarantee at least 1 eligible item (casual-friendly)
        if rewardsGiven == 0 then
            local availableItems = {}
            for _, loot in ipairs(eligible) do
                if not awardedItems[loot.itemid] then
                    table.insert(availableItems, loot)
                end
            end
            if #availableItems > 0 then
                local guaranteedReward = availableItems[math.random(1, #availableItems)]
                DeliverReward(guaranteedReward)
            end
        end
    end

    -- 3. Universal Fallback Currency Guarantee:
    -- If no eligible items existed or were granted, guarantee currency based on tier progression
    if rewardsGiven == 0 then
        local emblemId = 40752 -- Emblem of Heroism default
        local emblemAmount = 1 + math.min(math.floor(tier / 3), 4)

        if tier >= 10 then
            emblemId = 49426 -- Emblem of Frost
        elseif tier >= 5 then
            emblemId = 47241 -- Emblem of Triumph
        elseif tier >= 3 then
            emblemId = 45624 -- Emblem of Conquest
        end

        if isHeroic then
            emblemAmount = emblemAmount + (MythicConfig.HeroicExtraEmblem or 1)
        end

        player:AddItem(emblemId, emblemAmount)
        local itemData = CacheItemTemplate(emblemId)
        local emblemName = itemData and itemData.name or "Emblem"
        player:SendBroadcastMessage(string.format("[Mythic+] %s %dx %s", GetLocalizedText(player, "UI", "Reward:"), emblemAmount, emblemName))

        -- Gold reward scaling with tier
        local goldAmount = (tier * 100000) -- 10g per tier in copper
        if isHeroic then
            goldAmount = math.floor(goldAmount * (MythicConfig.HeroicGoldMultiplier or 1.5))
        end
        player:ModifyMoney(goldAmount)
        rewardsGiven = rewardsGiven + 1
    end

    if upgradeLevel >= 2 then
        local upgradeText = upgradeLevel == 2 and GetLocalizedText(player, "UI", "+2 Performance") or GetLocalizedText(player, "UI", "+3 Performance")
        player:SendBroadcastMessage("[Mythic+] " .. upgradeText .. " - " .. GetLocalizedText(player, "UI", "Enhanced loot chances applied!"))
    end
end

function AwardMythicPoints(player, tier, duration, deaths, remainingTime, diff)
    local now = os.time()
    local map = player:GetMap()
    if not map then return end
    local mapId = map:GetMapId()
    local instanceId = map:GetInstanceId()
    local guid = player:GetGUIDLow()
    diff = diff or 0

    local cache = PlayerRatingCache[guid]
    if not cache then
        cache = {
            total_points = 0, total_runs = 0, completed_runs = 0, out_of_time_runs = 0, too_many_death_runs = 0,
            [mapId] = 0
        }
        PlayerRatingCache[guid] = cache
    end

    local previous = cache[mapId] or 0
    local bossData = MythicBosses[mapId]
    local timerTotal = bossData and bossData.timer or 900
    local timeRemainingPercent = (remainingTime / timerTotal) * 100
    local gainedRating = CalculateMythicRating(tier, timeRemainingPercent)
    local deathPenalty = deaths * 10
    local finalRating = math.max(0, gainedRating - deathPenalty)
    if diff == 1 then
        finalRating = math.floor(finalRating * (MythicConfig.HeroicRatingMultiplier or 1.1))
    end
    local newRating = math.max(previous, finalRating)

    cache[mapId] = newRating
    cache.completed_runs = cache.completed_runs + 1
    cache.total_runs = cache.total_runs + 1

    SavePlayerRatingCache(guid)
    RecalculateTotalPoints(guid)

    local upgradeLevel = CalculateKeystoneUpgrade(timeRemainingPercent, true)
    
    AIO.Handle(player, "AIO_Mythic", "StopMythicTimerGUI", remainingTime)
    AIO.Handle(player, "AIO_Mythic", "FinalizeMythicScore", deathPenalty, deaths, finalRating - gainedRating + deathPenalty)

    local dfmt = string.format("%02d:%02d", math.floor(duration/60), duration%60)
    
    local upgradeText = ""
    if upgradeLevel > 0 then
        upgradeText = string.format(" (Key +%d)", upgradeLevel)
    elseif upgradeLevel < 0 then
        upgradeText = " (Key -1)"
    end
    
    player:SendBroadcastMessage(string.format(
        "[Mythic+] %s\n%s",
        GetLocalizedText(player, "UI", "Tier %d completed in %s%s."):format(tier, dfmt, upgradeText),
        GetLocalizedText(player, "UI", "Rating: %d (+%d gained, -%d death penalty)"):format(newRating, gainedRating, deathPenalty)
    ))

    if REQUIRE_KEYSTONE then
        local effectiveUpgrade = math.max(1, upgradeLevel)
        local newTier = tier + effectiveUpgrade
        local newMapId = mapId
        
        PlayerKeysCache[guid] = {mapId = newMapId, tier = newTier}
        CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, newMapId, newTier))
        
        if not player:HasItem(900100) then
            player:AddItem(900100, 1)
        end

        local newDungeonName = GetLocalizedDungeonName(player, newMapId)
        player:SendBroadcastMessage(string.format("[Mythic+] %s (%s)", 
            GetLocalizedText(player, "UI", "You received a Tier %d Mythic Keystone!"):format(newTier),
            newDungeonName
        ))

        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if p then
                MythicHandlers.RequestMapNameAndTier(p)
            end
        end, 200, 1)
    end

    TryRewardMythicLoot(player, tier, upgradeLevel, diff)
    UpdateVaultProgress(player, tier, true)
    LeaderboardCache.lastUpdate = 0
end

function AwardOvertimeLoot(player, tier, diff)
    local map = player:GetMap()
    if not map then return end
    local mapId = map:GetMapId()
    local guid = player:GetGUIDLow()
    diff = diff or 0
    local cache = PlayerRatingCache[guid]
    if cache then
        cache.completed_runs = cache.completed_runs + 1
        SavePlayerRatingCache(guid)
    end

    AIO.Handle(player, "AIO_Mythic", "StopMythicTimerGUI", 0)
    
    player:SendBroadcastMessage(string.format(
        "[Mythic+] %s",
        GetLocalizedText(player, "UI", "Tier %d completed in overtime."):format(tier)
    ))

    TryRewardMythicLoot(player, tier, 0, diff)
    LeaderboardCache.lastUpdate = 0
end

function BindKeystoneToDungeon(event, player, item, count)
    local guid = player:GetGUIDLow()
    
    if item:GetEntry() == 900100 then
        local existingKey = PlayerKeysCache[guid]
        if not existingKey then
            local newMapId = GetRandomMythicMapId()
            local newTier = 1
            
            PlayerKeysCache[guid] = {mapId = newMapId, tier = newTier}
            CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, newMapId, newTier))
        end
        
        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if p then
                MythicHandlers.RequestMapNameAndTier(p)
            end
        end, 100, 1)
    end
end

function MythicHandlers.RequestMapNameAndTier(player)
    local guid = player:GetGUIDLow()
    local keyData = PlayerKeysCache[guid]

    if keyData then
        local mapName = GetLocalizedDungeonName(player, keyData.mapId)
        AIO.Handle(player, "AIO_Mythic", "ReceiveMapNameAndTier", mapName, keyData.tier)
    else
        AIO.Handle(player, "AIO_Mythic", "ReceiveMapNameAndTier", 
            GetLocalizedText(player, "UI", "No Keystone"), 0)
    end
end

local function DungeonEndbossKeyReward(event, player, killed)
    HandleDungeonEndbossReward(killed, player)
end

local function OnPlayerLogin(event, player)
    local guid = player:GetGUIDLow()
    LoadPlayerCache(guid)
    LoadPlayerVaultCache(guid)
    PlayerNamesCache[guid] = player:GetName()
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then
            MythicHandlers.RequestVaultStatus(p)
        end
    end, 2000, 1)
end

local function OnPlayerLogout(event, player)
    local guid = player:GetGUIDLow()
    if PlayerRatingCache[guid] then
        SavePlayerRatingCache(guid)
    end
end

local function HandleKeystoneChatCommand(event, player, msg, Type, lang)
    if msg:sub(1, 4) == "#key" or msg:sub(1, 9) == "#keystone" then
        local guid = player:GetGUIDLow()
        local currentMapId = player:GetMapId()
        local keyData = PlayerKeysCache[guid]

        local parts = {}
        for w in msg:gmatch("%S+") do table.insert(parts, w) end
        local cmd = parts[2] and parts[2]:lower() or ""

        if cmd == "here" or cmd == "attune" then
            if not player:IsGM() and MythicConfig.AllowKeyReattunement ~= 1 then
                player:SendBroadcastMessage("[Mythic+] Keystone re-attunement is disabled on this server.")
                return false
            end
            if not mythicDungeonIds[currentMapId] then
                player:SendBroadcastMessage("[Mythic+] You are not inside a valid Mythic+ dungeon.")
                return false
            end
            local tier = keyData and keyData.tier or 1
            if not player:HasItem(900100) then
                player:AddItem(900100, 1)
            end
            PlayerKeysCache[guid] = {mapId = currentMapId, tier = tier}
            CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, currentMapId, tier))
            local dungeonName = GetLocalizedDungeonName(player, currentMapId)
            player:SendBroadcastMessage(string.format("[Mythic+] Keystone attuned to: |cffffd100%s (Tier %d)|r!", dungeonName, tier))
            CreateLuaEvent(function()
                local p = GetPlayerByGUID(guid)
                if p then MythicHandlers.RequestMapNameAndTier(p) end
            end, 100, 1)
            return false
        elseif cmd == "set" then
            if not player:IsGM() and MythicConfig.NoKeystoneRequired ~= 1 then
                player:SendBroadcastMessage("[Mythic+] Setting keystone tier manually is restricted to Game Masters.")
                return false
            end
            local newTier = tonumber(parts[3]) or 1
            if not mythicDungeonIds[currentMapId] then
                player:SendBroadcastMessage("[Mythic+] You are not inside a valid Mythic+ dungeon.")
                return false
            end
            if not player:HasItem(900100) then
                player:AddItem(900100, 1)
            end
            PlayerKeysCache[guid] = {mapId = currentMapId, tier = newTier}
            CharDBQuery(string.format("REPLACE INTO character_mythic_keys (guid, mapId, tier) VALUES (%d, %d, %d)", guid, currentMapId, newTier))
            local dungeonName = GetLocalizedDungeonName(player, currentMapId)
            player:SendBroadcastMessage(string.format("[Mythic+] Keystone set to: |cffffd100%s (Tier %d)|r!", dungeonName, newTier))
            CreateLuaEvent(function()
                local p = GetPlayerByGUID(guid)
                if p then MythicHandlers.RequestMapNameAndTier(p) end
            end, 100, 1)
            return false
        else
            if keyData and keyData.mapId then
                local dungeonName = GetLocalizedDungeonName(player, keyData.mapId)
                player:SendBroadcastMessage(string.format("[Mythic+] Your Keystone is for: |cffffd100%s (Tier %d)|r.", dungeonName, keyData.tier or 1))
                if MythicConfig.AllowKeyReattunement == 1 or player:IsGM() then
                    player:SendBroadcastMessage("[Mythic+] Inside any dungeon, type |cff00ff00#key here|r to attune it to your current location!")
                end
            else
                player:SendBroadcastMessage("[Mythic+] You do not have an active Mythic Keystone. Complete any dungeon to receive one!")
            end
            return false
        end
    end
end

RegisterCreatureGossipEvent(PEDESTAL_NPC_ENTRY, 1, Pedestal_OnGossipHello)
RegisterCreatureGossipEvent(PEDESTAL_NPC_ENTRY, 2, Pedestal_OnGossipSelect)
RegisterPlayerEvent(7, MythicBossKillCheck)
RegisterPlayerEvent(7, DungeonEndbossKeyReward)
RegisterPlayerEvent(7, MythicEnemyKillCheck)
RegisterPlayerEvent(8, MythicPlayerDeath)
RegisterPlayerEvent(18, HandleKeystoneChatCommand)
RegisterPlayerEvent(42, HandleKeystoneChatCommand)
RegisterPlayerEvent(53, BindKeystoneToDungeon)
RegisterPlayerEvent(28, LeaveDungeonMap)
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)
RegisterCreatureEvent(26533, 1, CheckMalGanisEvade)

local function RegisterAllBossDeathEvents()
    local registered = {}
    for mapId, data in pairs(MythicBosses) do
        if data.bosses then
            for _, entry in ipairs(data.bosses) do
                if not registered[entry] then
                    registered[entry] = true
                    RegisterCreatureEvent(entry, 4, function(event, creature, killer)
                        ProcessBossDeath(creature, killer)
                    end)
                end
            end
        end
        if data.heroicBosses then
            for _, entry in ipairs(data.heroicBosses) do
                if not registered[entry] then
                    registered[entry] = true
                    RegisterCreatureEvent(entry, 4, function(event, creature, killer)
                        ProcessBossDeath(creature, killer)
                    end)
                end
            end
        end
    end
    for entry, _ in pairs(DUNGEON_LAST_BOSSES) do
        if not registered[entry] then
            registered[entry] = true
            RegisterCreatureEvent(entry, 4, function(event, creature, killer)
                ProcessBossDeath(creature, killer)
            end)
        end
    end
end
RegisterAllBossDeathEvents()

RegisterGameObjectEvent(VAULT_GAMEOBJECT_ID, 14, WeeklyVaultInteract)
CheckAndProcessVaultOnStartup()
LoadDungeonEntrances()

function MythicHandlers.RequestWeeklyAffixes(player)
    if WeeklyAffixesCache and #WeeklyAffixesCache >= 3 then
        local affix1 = WeeklyAffixesCache[1].name
        local affix2 = WeeklyAffixesCache[2].name or "-"
        local affix3 = WeeklyAffixesCache[3].name or "-"
        AIO.Handle(player, "AIO_Mythic", "ReceiveWeeklyAffixes", affix1, affix2, affix3)
    else
        AIO.Handle(player, "AIO_Mythic", "ReceiveWeeklyAffixes", "?", "?", "?")
    end
end

function MythicHandlers.RequestTotalPoints(player)
    local guid = player:GetGUIDLow()
    local cache = PlayerRatingCache[guid]

    if not cache then
        LoadPlayerCache(guid)
        AIO.Handle(player, "AIO_Mythic", "ReceiveTotalPoints", 0, {})
        return
    end

    local dungeonScores = {}
    for _, mapId in ipairs(allSupportedDungeonIds) do
        dungeonScores[tostring(mapId)] = cache[mapId] or 0
    end

    AIO.Handle(player, "AIO_Mythic", "ReceiveTotalPoints", cache.total_points, dungeonScores)
end

function MythicHandlers.RequestLeaderboard(player)
    UpdateLeaderboardCache()
    AIO.Handle(player, "AIO_Mythic", "ReceiveLeaderboard", LeaderboardCache.topThree, LeaderboardCache.dungeonTop)
end

function MythicHandlers.RequestRunState(player)
    local map = player:GetMap()
    if not map then return end
    
    local mapId = map:GetMapId()
    local instanceId = map:GetInstanceId()
    
    if not IsRunActive(instanceId) then 
        AIO.Handle(player, "AIO_Mythic", "ClearRunState")
        return 
    end
    
    local runData = ActiveRunsCache[instanceId]
    if not runData then 
        AIO.Handle(player, "AIO_Mythic", "ClearRunState")
        return 
    end
    
    local bossData = MythicBosses[mapId]
    if not bossData then 
        AIO.Handle(player, "AIO_Mythic", "ClearRunState")
        return 
    end
    
    local now = os.time()
    local elapsed = now - runData.start_time
    local duration = bossData.timer or 900
    local bossTracker = MYTHIC_BOSS_KILL_TRACKER[instanceId]
    local enemyTracker = MYTHIC_ENEMY_FORCES_TRACKER[instanceId]
    
    local killedBosses = {}
    if bossTracker then
        for idx, entry in ipairs(bossData.bosses) do
            local killed = true
            for _, remaining in ipairs(bossTracker.remaining) do
                if remaining == entry then
                    killed = false
                    break
                end
            end
            if killed then
                table.insert(killedBosses, idx)
            end
        end
    end
    
    local enemyForces = {
        current = 0,
        required = bossData.enemies or 0,
        percentage = 0,
        completed = false
    }
    
    if enemyTracker then
        enemyForces.current = enemyTracker.current
        enemyForces.required = enemyTracker.required
        enemyForces.percentage = math.min((enemyTracker.current / enemyTracker.required) * 100, 100)
        enemyForces.completed = enemyTracker.completed
    end
    
    local cache = PlayerRatingCache[player:GetGUIDLow()]
    local currentRating = cache and cache[mapId] or 0
    local potentialGain = CalculateMythicRating(runData.tier, 0)
    
    AIO.Handle(player, "AIO_Mythic", "RestoreRunState", {
        active = true,
        mapId = mapId,
        tier = runData.tier,
        duration = duration,
        elapsed = elapsed,
        bossNames = GetLocalizedBossNames(player, mapId),
        killedBosses = killedBosses,
        potentialGain = potentialGain,
        penalty = runData.deaths * penaltyPerDeath,
        deaths = runData.deaths,
        maxDeaths = (runData.tier == 1) and 6 or 4,
        enemyForces = enemyForces,
        overtime = runData.overtime_started or false
    })
end

function MythicHandlers.TeleportToDungeon(player, mapId)
    local status, err = xpcall(function()
        local pName = player and player:GetName() or "nil"
        local curMapId = player and player:GetMapId() or -1
        print(string.format("[Mythic+] Teleport requested by %s (curMap: %d) for targetMap: %s", pName, curMapId, tostring(mapId)))
        if not player or not player:IsInWorld() then
            print("[Mythic+] Abort: player not in world")
            return
        end
        mapId = tonumber(mapId)
        if not mapId then
            print("[Mythic+] Abort: mapId is nil")
            return
        end

        if not player:IsAlive() then
            print("[Mythic+] Abort: player is dead")
            player:SendBroadcastMessage("[Mythic+] You cannot teleport while dead!")
            return
        end

        if player:IsInCombat() then
            print("[Mythic+] Abort: player is in combat")
            player:SendBroadcastMessage("[Mythic+] You cannot teleport while in combat!")
            return
        end

        local loc = MYTHIC_DUNGEON_ENTRANCES[mapId]
        if not loc then
            LoadDungeonEntrances()
            loc = MYTHIC_DUNGEON_ENTRANCES[mapId]
        end

        if loc then
            local dungeonName = GetLocalizedDungeonName(player, mapId)
            print(string.format("[Mythic+] Teleporting %s to %s (map %d: %f, %f, %f, %f)", pName, dungeonName, loc.map, loc.x, loc.y, loc.z, loc.o))
            if player:GetMapId() == loc.map then
                player:NearTeleport(loc.x, loc.y, loc.z, loc.o)
                player:SendBroadcastMessage(string.format("[Mythic+] Teleporting to %s...", dungeonName))
            else
                local res = player:Teleport(loc.map, loc.x, loc.y, loc.z, loc.o)
                print(string.format("[Mythic+] player:Teleport returned: %s", tostring(res)))
                if res then
                    player:SendBroadcastMessage(string.format("[Mythic+] Teleporting to %s...", dungeonName))
                else
                    player:SendBroadcastMessage(string.format("[Mythic+] Could not teleport to %s. Check instance difficulty or requirements.", dungeonName))
                end
            end
        else
            print(string.format("[Mythic+] Abort: no loc found for map %d", mapId))
            player:SendBroadcastMessage(string.format("[Mythic+] Teleport location not found for dungeon %d.", mapId))
        end
    end, debug.traceback)
    if not status then
        print("[Mythic+] ERROR in TeleportToDungeon: " .. tostring(err))
    end
end

function MythicHandlers.RequestConfig(player)
    AIO.Handle(player, "AIO_Mythic", "ReceiveConfig", MythicConfig)
end

function MythicHandlers.SaveConfig(player, newConfig)
    if not newConfig or type(newConfig) ~= "table" then
        return
    end

    local isAuthorized = player:IsGM() or (player.GetSecurity and player:GetSecurity() >= 1) or (MythicConfig.AllowPlayerConfig == 1)
    if not isAuthorized then
        player:SendBroadcastMessage("|cffff0000[Mythic+] You do not have permission to modify Mythic+ settings.|r")
        return
    end

    if newConfig.NoKeystoneRequired ~= nil then
        MythicConfig.NoKeystoneRequired = tonumber(newConfig.NoKeystoneRequired) or 0
        REQUIRE_KEYSTONE = (MythicConfig.NoKeystoneRequired ~= 1)
    end
    if newConfig.AllowKeyReattunement ~= nil then
        MythicConfig.AllowKeyReattunement = tonumber(newConfig.AllowKeyReattunement) or 0
    end
    if newConfig.HeroicBonusChance ~= nil then
        MythicConfig.HeroicBonusChance = tonumber(newConfig.HeroicBonusChance) or 1.25
    end
    if newConfig.HeroicExtraEmblem ~= nil then
        MythicConfig.HeroicExtraEmblem = math.floor(tonumber(newConfig.HeroicExtraEmblem) or 1)
    end
    if newConfig.HeroicGoldMultiplier ~= nil then
        MythicConfig.HeroicGoldMultiplier = tonumber(newConfig.HeroicGoldMultiplier) or 1.5
    end
    if newConfig.HeroicRatingMultiplier ~= nil then
        MythicConfig.HeroicRatingMultiplier = tonumber(newConfig.HeroicRatingMultiplier) or 1.1
    end

    SaveMythicConfig()

    AIO.Handle(player, "AIO_Mythic", "ReceiveConfig", MythicConfig)
    player:SendBroadcastMessage("|cff00ff00[Mythic+] Settings saved and updated successfully!|r")
end