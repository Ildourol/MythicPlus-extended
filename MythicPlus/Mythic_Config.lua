-- MythicPlus In-Game Configuration File
-- This file is dynamically read and saved by the in-game Mythic+ Settings tab.

MythicConfig = {
    Enable = 1,
    NoKeystoneRequired = 0,     -- 0 = Strict key progression, 1 = Cheat Mode (freely choose tier 1-100 without key)
    AllowKeyReattunement = 0,   -- 0 = Blizzlike (key locked to dungeon), 1 = Allow re-attuning key to current dungeon at fountain
    HeroicBonusChance = 1.25,   -- Multiplier for loot chance on Heroic Mythic+ (e.g. 1.25 = +25% bonus chance)
    HeroicExtraEmblem = 1,      -- Extra emblems rewarded on Heroic Mythic+ completion
    HeroicGoldMultiplier = 1.5, -- Gold multiplier on Heroic Mythic+ completion
    HeroicRatingMultiplier = 1.1, -- Score rating multiplier on Heroic Mythic+ completion
    AllowPlayerConfig = 1       -- 1 = Allow any player to change settings in UI, 0 = GMs only
}
