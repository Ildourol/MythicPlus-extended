DELETE FROM `creature_template` WHERE (`entry` = 900001);
REPLACE INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(900001, 0, 0, 0, 0, 0, 'Font of Power', '', 'Speak', 900001, 80, 80, 0, 35, 1, 1, 1.14286, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 768, 32768, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 'MythicPedestal', 12340);

DELETE FROM `creature_template_model` WHERE (`CreatureID` = 900001);
REPLACE INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(900001, 1, 24868, 1, 1, 0);

DELETE FROM `item_template` WHERE (`entry` = 900100);
REPLACE INTO `item_template` (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`, `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`, `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`) VALUES
(900100, 12, 0, -1, 'Mythic Keystone', 62471, 4, 64, 0, 1, 0, 0, 0, -1, -1, 0, 80, 0, 0, 0, 0, 0, 0, 0, 1, 9999, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1000, 0, 0, 0, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, -1, 0, -1, 1, 'Place within the Font of Power inside the dungeon.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 0);

REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'deDE', 'Mythischer Schlüsselstein', 'Setzt ihn im Dungeon im Born der Macht ein.', 15050);
REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'esES', 'Piedra angular mítica', 'Colócala dentro de la fuente de poder que hay en la mazmorra.', 15050);
REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'esMX', 'Piedra angular mítica', 'Colócala dentro de la fuente de poder que hay en la mazmorra.', 15050);
REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'frFR', 'Clé mythique', 'À insérer dans la fontaine de puissance à l''intérieur d''un donjon.', 15050);
REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'koKR', '신화 쐐기돌', '던전 안에 있는 마력의 샘에 넣으십시오.', 15050);
REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'ruRU', 'Эпохальный ключ', 'Положите ключ в Чашу силы в подземелье.', 15050);
REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'zhCN', '[Mythic Keystone]', '[Place within the Font of Power inside the dungeon.]', 15050);
REPLACE INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES (900100, 'zhTW', '傳奇鑰石', '放置在地城裡的能量之泉內。', 15050);

REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'deDE', 'Born der Macht', '', 15050);
REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'esES', 'Fuente de poder', '', 15050);
REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'esMX', 'Fuente de poder', '', 15050);
REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'frFR', 'Fontaine de puissance', '', 15050);
REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'koKR', '마력의 샘', '', 15050);
REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'ruRU', 'Чаша силы', '', 15050);
REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'zhCN', 'Font of Power', '', 15050);
REPLACE INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`, `VerifiedBuild`) VALUES (900001, 'zhTW', '能量之泉', '', 15050);

REPLACE INTO `creature` (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
-- WotLK Dungeons (spawnMask 3 = Normal & Heroic)
(900001, 574, 0, 0, 3, 1, 0, 173.299, -92.1371, 12.5535, 2.75347, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Utgarde Keep'),
(900001, 575, 0, 0, 3, 1, 0, 571.32, -333.858, 110.14, 0.844163, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Utgarde Pinnacle'),
(900001, 576, 0, 0, 3, 1, 0, 172.834, -10.6004, -16.636, 1.61453, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Nexus'),
(900001, 578, 0, 0, 3, 1, 0, 1061.64, 995.343, 361.072, 4.26374, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Oculus'),
(900001, 595, 0, 0, 3, 1, 0, 1430.53, 549.692, 35.8522, 2.32704, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Culling of Stratholme'),
(900001, 599, 0, 0, 3, 1, 0, 1133.13, 811.837, 195.835, 0.0394203, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Halls of Stone'),
(900001, 600, 0, 0, 3, 1, 0, -502.675, -513.078, 11.0454, 3.12431, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Drak''Tharon Keep'),
(900001, 601, 0, 0, 3, 1, 0, 423.48, 802.589, 827.911, 4.61237, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Azjol-Nerub'),
(900001, 602, 0, 0, 3, 1, 0, 1311.83, 268.017, 53.2948, 0.450539, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Halls of Lightning'),
(900001, 604, 0, 0, 3, 1, 0, 1889.09, 629.347, 176.694, 2.4522, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Gundrak North'),
(900001, 604, 0, 0, 3, 1, 0, 1886.73, 855.669, 176.694, 3.92115, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Gundrak South'),
(900001, 608, 0, 0, 3, 1, 0, 1819.33, 809.071, 44.3639, 4.73869, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Violet Hold'),
(900001, 619, 0, 0, 3, 1, 0, 390.893, -1089.21, 47.3606, 2.55577, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Ahn''kahet: The Old Kingdom'),
(900001, 632, 0, 0, 3, 1, 0, 4910.44, 2180.07, 638.734, 0.161806, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Forge of Souls'),
(900001, 650, 0, 0, 3, 1, 0, 799.102, 609.297, 412.364, 3.01206, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Trial of the Champion'),
(900001, 658, 0, 0, 3, 1, 0, 435.35, 202.332, 528.718, 1.50715, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Pit of Saron'),
(900001, 668, 0, 0, 3, 1, 0, 5231.32, 1945.65, 707.695, 5.5679, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Halls of Reflection'),
-- Vanilla Dungeons (spawnMask 1 = Normal only in client DBC)
(900001, 389, 0, 0, 1, 1, 0, 3.81, -14.82, -17.84, 4.39, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Ragefire Chasm'),
(900001, 36, 0, 0, 1, 1, 0, -16.4, -383.07, 61.78, 1.86, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Deadmines'),
(900001, 43, 0, 0, 1, 1, 0, -163.49, 132.9, -73.66, 5.83, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Wailing Caverns'),
(900001, 33, 0, 0, 1, 1, 0, -229.135, 2109.18, 76.8898, 1.267, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Shadowfang Keep'),
(900001, 48, 0, 0, 1, 1, 0, -151.89, 106.96, -39.87, 4.53, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Blackfathom Deeps'),
(900001, 34, 0, 0, 1, 1, 0, 54.23, 0.28, -18.34, 6.26, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Stockade'),
(900001, 90, 0, 0, 1, 1, 0, -332.22, -2.28, -150.86, 2.77, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Gnomeregan'),
(900001, 47, 0, 0, 1, 1, 0, 1943.0, 1544.63, 82.0, 1.38, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Razorfen Kraul'),
(900001, 129, 0, 0, 1, 1, 0, 2592.55, 1107.5, 51.29, 4.74, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Razorfen Downs'),
(900001, 189, 0, 0, 1, 1, 0, 1688.99, 1053.48, 18.6775, 0.00117, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Scarlet Monastery - Graveyard'),
(900001, 189, 0, 0, 1, 1, 0, 255.346, -209.09, 18.6773, 6.26656, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Scarlet Monastery - Library'),
(900001, 189, 0, 0, 1, 1, 0, 1610.83, -323.433, 18.6738, 6.28022, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Scarlet Monastery - Armory'),
(900001, 189, 0, 0, 1, 1, 0, 855.683, 1321.5, 18.6709, 0.001747, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Scarlet Monastery - Cathedral'),
(900001, 70, 0, 0, 1, 1, 0, -226.8, 49.09, -46.03, 1.39, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Uldaman'),
(900001, 209, 0, 0, 1, 1, 0, 1213.52, 841.59, 8.93, 6.09, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Zul''Farrak'),
(900001, 349, 0, 0, 1, 1, 0, 1019.69, -458.31, -43.43, 0.31, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Maraudon'),
(900001, 109, 0, 0, 1, 1, 0, -319.24, 99.9, -131.85, 3.19, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Temple of Atal''Hakkar'),
(900001, 230, 0, 0, 1, 1, 0, 456.929, 34.0923, -68.0896, 4.71239, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Blackrock Depths'),
(900001, 229, 0, 0, 1, 1, 0, 78.5083, -225.044, 49.839, 5.1, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Blackrock Spire'),
(900001, 429, 0, 0, 1, 1, 0, 44.4499, -154.822, -2.71201, 0, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Dire Maul'),
(900001, 289, 0, 0, 1, 1, 0, 196.37, 127.05, 134.91, 6.09, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Scholomance'),
(900001, 329, 0, 0, 1, 1, 0, 3593.15, -3646.56, 138.5, 5.33, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Stratholme'),
-- TBC Dungeons
(900001, 543, 0, 0, 3, 1, 0, -1355.24, 1641.12, 68.2491, 0.6687, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Hellfire Ramparts'),
(900001, 542, 0, 0, 3, 1, 0, -3.9967, 14.6363, -44.8009, 4.88748, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Blood Furnace'),
(900001, 540, 0, 0, 3, 1, 0, -40.8716, -19.7538, -13.8065, 1.11133, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Shattered Halls'),
(900001, 547, 0, 0, 3, 1, 0, 120.101, -131.957, -0.801547, 1.47574, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Slave Pens'),
(900001, 546, 0, 0, 3, 1, 0, 9.71391, -16.2008, -2.75334, 5.57082, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Underbog'),
(900001, 545, 0, 0, 3, 1, 0, -13.8425, 6.7542, -4.2586, 0, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Steamvault'),
(900001, 557, 0, 0, 3, 1, 0, 0.0191, 0.9478, -0.9543, 3.03164, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Mana-Tombs'),
(900001, 558, 0, 0, 3, 1, 0, -21.8975, 0.16, -0.1206, 0.0353412, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Auchenai Crypts'),
(900001, 556, 0, 0, 3, 1, 0, -4.6811, -0.0930796, 0.0062, 0.0353424, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Sethekk Halls'),
(900001, 555, 0, 0, 3, 1, 0, 0.488033, -0.215935, -1.12788, 3.15888, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Shadow Labyrinth'),
(900001, 560, 0, 0, 3, 1, 0, 2741.87, 1315.25, 14.0423, 2.96016, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Old Hillsbrad Foothills'),
(900001, 269, 0, 0, 3, 1, 0, -1496.24, 7034.7, 32.5619, 1.75699, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Black Morass'),
(900001, 553, 0, 0, 3, 1, 0, 40.0395, -28.613, -1.1189, 2.35856, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Botanica'),
(900001, 552, 0, 0, 3, 1, 0, -1.23165, 0.0143459, -0.204293, 0.0157123, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Arcatraz'),
(900001, 554, 0, 0, 3, 1, 0, -28.906, 0.680314, -1.81282, 0.0345509, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'The Mechanar'),
(900001, 585, 0, 0, 3, 1, 0, 7.09, -0.45, -2.8, 0.05, 300, 0, 0, 5342, 0, 0, 0, 0, 0, '', NULL, 0, 'Magisters'' Terrace');

DELETE FROM `gameobject_template` WHERE `entry`=900000;
REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES 
(900000, 3, 8685, 'Mythic Vault', '', '', '', 2.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0);

REPLACE INTO `gameobject` (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES 
(900000, 571, 0, 0, 1, 1, 5732.36, 515.232, 647.452, 0.358227, 0, 0, 0.178157, 0.984002, 300, 0, 1, '', NULL, NULL);

DELETE FROM `npc_text` WHERE `ID` = 900001;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`) VALUES 
(900001, 'Greetings $N, welcome to the Font of Power.\n\nChoose your challenge or enter a custom difficulty to begin.\n\nStart Mythic:', 'Greetings $N, welcome to the Font of Power.\n\nChoose your challenge or enter a custom difficulty to begin.\n\nStart Mythic:', 0);

REPLACE INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (900001, 900001);
