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

-- Dumping structure for table acore_characters.character_mythic_vault
DROP TABLE IF EXISTS `character_mythic_vault`;
CREATE TABLE IF NOT EXISTS `character_mythic_vault` (
  `guid` int unsigned NOT NULL,
  `week_start` date NOT NULL,
  `highest_tier_1` tinyint unsigned DEFAULT NULL,
  `highest_tier_2` tinyint unsigned DEFAULT NULL,
  `highest_tier_3` tinyint unsigned DEFAULT NULL,
  `successful_runs` tinyint unsigned DEFAULT '0',
  `item_1_id` int unsigned DEFAULT NULL,
  `item_2_id` int unsigned DEFAULT NULL,
  `item_3_id` int unsigned DEFAULT NULL,
  `items_generated` tinyint(1) DEFAULT '0',
  `has_collected` tinyint(1) DEFAULT '0',
  `can_collect` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`guid`,`week_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Data exporting was unselected.

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
