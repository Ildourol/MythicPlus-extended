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
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table acore_world.world_mythic_loot: ~27 rows (approximately)
INSERT INTO `world_mythic_loot` (`id`, `itemid`, `itemname`, `amount`, `type`, `faction`, `loot_bracket`, `chancePercent`, `additionalID`, `additionalType`) VALUES
	(1, 12354, 'Palomino Bridle', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(2, 12353, 'White Stallion Bridle', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(3, 12302, 'Reins of the Ancient Frostsaber', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(4, 12303, 'Reins of the Nightsaber', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(5, 13328, 'Black Ram', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(6, 13329, 'Frost Ram', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(7, 13327, 'Icy Blue Mechanostrider Mod A', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(8, 13326, 'White Mechanostrider Mod B', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(9, 13325, 'Fluorescent Green Mechanostrider', 1, 'mount', 'A', '10+', 0.2, NULL, NULL),
	(10, 12351, 'Horn of the Arctic Wolf', 1, 'mount', 'H', '10+', 0.2, NULL, NULL),
	(11, 12330, 'Horn of the Red Wolf', 1, 'mount', 'H', '10+', 0.2, NULL, NULL),
	(12, 15292, 'Green Kodo', 1, 'mount', 'H', '10+', 0.2, NULL, NULL),
	(13, 15293, 'Teal Kodo', 1, 'mount', 'H', '10+', 0.2, NULL, NULL),
	(14, 13317, 'Whistle of the Ivory Raptor', 1, 'mount', 'H', '10+', 0.2, NULL, NULL),
	(15, 8586, 'Whistle of the Mottled Red Raptor', 1, 'mount', 'H', '10+', 0.2, NULL, NULL),
	(16, 33809, 'Amani War Bear', 1, 'mount', 'N', '10+', 0.2, NULL, NULL),
	(17, 33976, 'Brefest Ram', 1, 'mount', 'N', '10+', 0.2, NULL, NULL),
	(18, 8630, 'Reins of the Bengal Tiger', 1, 'mount', 'N', '10+', 0.2, 828, 'spell'),
	(19, 40110, 'Haunted Memento', 1, 'pet', 'N', 'all', 0.2, NULL, NULL),
	(20, 45942, 'XS-001 Constructor Bot', 1, 'pet', 'N', 'pets', 0.2, NULL, NULL),
	(21, 18964, 'Turtle Egg (Loggerhead)', 1, 'pet', 'N', 'pets', 0.2, NULL, NULL),
	(22, 21168, 'Baby Shark', 1, 'pet', 'N', 'pets', 0.2, NULL, NULL),
	(23, 49662, 'Gryphon Hatchling', 1, 'pet', 'N', 'pets', 0.2, NULL, NULL),
	(24, 49663, 'Wind Rider Cub', 1, 'pet', 'N', 'pets', 0.2, NULL, NULL),
	(25, 45180, 'Murkimus\' Little Spear', 1, 'pet', 'N', 'pets', 0.2, NULL, NULL),
	(26, 13262, 'Ashbringer', 1, 'gear', 'N', '11+', 0.2, NULL, NULL),
	(27, 22691, 'Corrupted Ashbringer', 1, 'gear', 'N', '11+', 0.2, NULL, NULL);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
