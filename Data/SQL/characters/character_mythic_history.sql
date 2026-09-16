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

-- Dumping structure for table acore_characters.character_mythic_history
DROP TABLE IF EXISTS `character_mythic_history`;
CREATE TABLE IF NOT EXISTS `character_mythic_history` (
  `run_id` int unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `mapId` smallint unsigned NOT NULL,
  `instanceId` int unsigned DEFAULT NULL,
  `tier` tinyint unsigned NOT NULL,
  `start_time` timestamp NULL DEFAULT NULL,
  `end_time` timestamp NULL DEFAULT NULL,
  `duration` int unsigned DEFAULT NULL,
  `deaths` tinyint unsigned DEFAULT '0',
  `completed` tinyint(1) DEFAULT '0',
  `affixes` text COLLATE utf8mb4_general_ci,
  `member_1` int unsigned DEFAULT NULL,
  `member_2` int unsigned DEFAULT NULL,
  `member_3` int unsigned DEFAULT NULL,
  `member_4` int unsigned DEFAULT NULL,
  `member_5` int unsigned DEFAULT NULL,
  PRIMARY KEY (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data exporting was unselected.

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
