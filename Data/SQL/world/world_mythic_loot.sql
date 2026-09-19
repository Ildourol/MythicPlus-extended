-- --------------------------------------------------------
-- Host:                         localhost
-- Server version:               8.0.42 - MySQL Community Server - GPL
-- Server OS:                    Linux
-- HeidiSQL Version:             12.11.0.7065
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Dumping structure for table acore_world.world_mythic_loot
DROP TABLE IF EXISTS `world_mythic_loot`;
CREATE TABLE IF NOT EXISTS `world_mythic_loot` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `itemid` int unsigned NOT NULL,
  `itemname` varchar(255) NOT NULL COMMENT 'Item name for reference only - not used by script',
  `amount` int unsigned NOT NULL DEFAULT '1',
  `type` varchar(32) NOT NULL,
  `faction` char(1) NOT NULL DEFAULT 'N',
  `loot_bracket` varchar(50) NOT NULL COMMENT 'Tier eligibility: bracket names, ranges (1-3), single tiers (5), or conditions (5+, 3-)',
  `chancePercent` float NOT NULL,
  `additionalID` int unsigned DEFAULT NULL,
  `additionalType` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table acore_world.world_mythic_loot
INSERT INTO `world_mythic_loot` (`id`, `itemid`, `itemname`, `amount`, `type`, `faction`, `loot_bracket`, `chancePercent`, `additionalID`, `additionalType`) VALUES
	-- =========================================================================
	-- LOW TIER (Tiers 1 - 3): Casual-friendly dungeon gear, currencies & consumables
	-- =========================================================================
	(1, 40752, 'Emblem of Heroism', 2, 'gear', 'N', 'low_tier', 100.0, NULL, NULL),
	(2, 40753, 'Emblem of Valor', 1, 'gear', 'N', 'low_tier', 50.0, NULL, NULL),
	(3, 37705, 'Cryptplate Girdle', 1, 'gear', 'N', 'low_tier', 25.0, NULL, NULL),
	(4, 37684, 'Gilded Armor of the Lion', 1, 'gear', 'N', 'low_tier', 25.0, NULL, NULL),
	(5, 37693, 'Dragonflayer Breastplate', 1, 'gear', 'N', 'low_tier', 25.0, NULL, NULL),
	(6, 37678, 'Breeches of the Scourge', 1, 'gear', 'N', 'low_tier', 25.0, NULL, NULL),
	(7, 37668, 'Savage Wound Band', 1, 'gear', 'N', 'low_tier', 30.0, NULL, NULL),
	(8, 37673, 'Signet of the Accord', 1, 'gear', 'N', 'low_tier', 30.0, NULL, NULL),
	(9, 37688, 'Marrowstrike', 1, 'gear', 'N', 'low_tier', 20.0, NULL, NULL),
	(10, 37691, 'Runeblade of Demonstrable Power', 1, 'gear', 'N', 'low_tier', 20.0, NULL, NULL),
	(11, 37695, 'Looming Shadow', 1, 'gear', 'N', 'low_tier', 20.0, NULL, NULL),

	-- =========================================================================
	-- MID TIER (Tiers 4 - 7): Heroic WotLK level items & Emblems of Conquest
	-- =========================================================================
	(12, 45624, 'Emblem of Conquest', 2, 'gear', 'N', 'mid_tier', 100.0, NULL, NULL),
	(13, 37193, 'Belt of the Arch-Mage', 1, 'gear', 'N', 'mid_tier', 25.0, NULL, NULL),
	(14, 37238, 'Ancient Royal Band', 1, 'gear', 'N', 'mid_tier', 25.0, NULL, NULL),
	(15, 37199, 'Greaves of the Blue Aspect', 1, 'gear', 'N', 'mid_tier', 25.0, NULL, NULL),
	(16, 37169, 'Warhelm of the Champion', 1, 'gear', 'N', 'mid_tier', 25.0, NULL, NULL),
	(17, 37177, 'Dragon\'s Call', 1, 'gear', 'N', 'mid_tier', 20.0, NULL, NULL),
	(18, 37174, 'Staff of Draconic Combat', 1, 'gear', 'N', 'mid_tier', 20.0, NULL, NULL),
	(19, 37237, 'Chitin-Clad Legguards', 1, 'gear', 'N', 'mid_tier', 25.0, NULL, NULL),
	(20, 37242, 'Titanium Spellstrike Chain', 1, 'gear', 'N', 'mid_tier', 25.0, NULL, NULL),

	-- =========================================================================
	-- HIGH TIER (Tiers 8 - 12): Raid-grade items & Emblems of Triumph
	-- =========================================================================
	(21, 47241, 'Emblem of Triumph', 3, 'gear', 'N', 'high_tier', 100.0, NULL, NULL),
	(22, 47834, 'Crusader\'s Dragonscale Bracers', 1, 'gear', 'N', 'high_tier', 20.0, NULL, NULL),
	(23, 47820, 'Girdle of the Merciless Crusader', 1, 'gear', 'N', 'high_tier', 20.0, NULL, NULL),
	(24, 47833, 'Bindings of the Ashen Saint', 1, 'gear', 'N', 'high_tier', 20.0, NULL, NULL),
	(25, 47814, 'Belt of the Fallen Wyrm', 1, 'gear', 'N', 'high_tier', 20.0, NULL, NULL),
	(26, 47817, 'Amulet of the Silent Shore', 1, 'gear', 'N', 'high_tier', 25.0, NULL, NULL),
	(27, 47819, 'Ring of the Darkmender', 1, 'gear', 'N', 'high_tier', 25.0, NULL, NULL),

	-- =========================================================================
	-- ENDGAME TIER (Tiers 15 - 20+): Pinnacle loot & Emblems of Frost
	-- =========================================================================
	(28, 49426, 'Emblem of Frost', 3, 'gear', 'N', 'endgame', 100.0, NULL, NULL),
	(29, 13262, 'Ashbringer', 1, 'gear', 'N', '11+', 2.0, NULL, NULL),
	(30, 22691, 'Corrupted Ashbringer', 1, 'gear', 'N', '11+', 2.0, NULL, NULL),

	-- =========================================================================
	-- PETS (Tier 5 - 9 and all tiers)
	-- =========================================================================
	(31, 40110, 'Haunted Memento', 1, 'pet', 'N', 'all', 5.0, NULL, NULL),
	(32, 45942, 'XS-001 Constructor Bot', 1, 'pet', 'N', 'pets', 5.0, NULL, NULL),
	(33, 18964, 'Turtle Egg (Loggerhead)', 1, 'pet', 'N', 'pets', 5.0, NULL, NULL),
	(34, 21168, 'Baby Shark', 1, 'pet', 'N', 'pets', 5.0, NULL, NULL),
	(35, 49662, 'Gryphon Hatchling', 1, 'pet', 'N', 'pets', 5.0, NULL, NULL),
	(36, 49663, 'Wind Rider Cub', 1, 'pet', 'N', 'pets', 5.0, NULL, NULL),
	(37, 45180, 'Murkimus\' Little Spear', 1, 'pet', 'N', 'pets', 5.0, NULL, NULL),

	-- =========================================================================
	-- MOUNTS (Tier 10+ bonus rewards)
	-- =========================================================================
	(38, 12354, 'Palomino Bridle', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(39, 12353, 'White Stallion Bridle', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(40, 12302, 'Reins of the Ancient Frostsaber', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(41, 12303, 'Reins of the Nightsaber', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(42, 13328, 'Black Ram', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(43, 13329, 'Frost Ram', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(44, 13327, 'Icy Blue Mechanostrider Mod A', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(45, 13326, 'White Mechanostrider Mod B', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(46, 13325, 'Fluorescent Green Mechanostrider', 1, 'mount', 'A', '10+', 2.5, NULL, NULL),
	(47, 12351, 'Horn of the Arctic Wolf', 1, 'mount', 'H', '10+', 2.5, NULL, NULL),
	(48, 12330, 'Horn of the Red Wolf', 1, 'mount', 'H', '10+', 2.5, NULL, NULL),
	(49, 15292, 'Green Kodo', 1, 'mount', 'H', '10+', 2.5, NULL, NULL),
	(50, 15293, 'Teal Kodo', 1, 'mount', 'H', '10+', 2.5, NULL, NULL),
	(51, 13317, 'Whistle of the Ivory Raptor', 1, 'mount', 'H', '10+', 2.5, NULL, NULL),
	(52, 8586, 'Whistle of the Mottled Red Raptor', 1, 'mount', 'H', '10+', 2.5, NULL, NULL),
	(53, 33809, 'Amani War Bear', 1, 'mount', 'N', '10+', 2.0, NULL, NULL),
	(54, 33976, 'Brefest Ram', 1, 'mount', 'N', '10+', 2.0, NULL, NULL),
	(55, 8630, 'Reins of the Bengal Tiger', 1, 'mount', 'N', '10+', 2.0, 828, 'spell');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
