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

-- Dumping structure for table acore_characters.character_mythic_rating
DROP TABLE IF EXISTS `character_mythic_rating`;
CREATE TABLE IF NOT EXISTS `character_mythic_rating` (
  `guid` int unsigned NOT NULL,
  `total_runs` int DEFAULT '0',
  `total_points` decimal(7,2) DEFAULT '0.00',
  `completed_runs` int DEFAULT '0' COMMENT 'Successfully completed runs',
  `out_of_time_runs` int DEFAULT '0' COMMENT 'Runs that failed due to time limit',
  `too_many_death_runs` int DEFAULT '0' COMMENT 'Runs that failed due to death limit',
  -- WotLK Dungeons
  `574` int DEFAULT '0' COMMENT 'Utgarde Keep',
  `575` int DEFAULT '0' COMMENT 'Utgarde Pinnacle',
  `576` int DEFAULT '0' COMMENT 'The Nexus',
  `578` int DEFAULT '0' COMMENT 'The Oculus',
  `595` int DEFAULT '0' COMMENT 'The Culling of Stratholme',
  `599` int DEFAULT '0' COMMENT 'Halls of Stone',
  `600` int DEFAULT '0' COMMENT 'Drak''Tharon Keep',
  `601` int DEFAULT '0' COMMENT 'Azjol-Nerub',
  `602` int DEFAULT '0' COMMENT 'Halls of Lightning',
  `604` int DEFAULT '0' COMMENT 'Gundrak',
  `608` int DEFAULT '0' COMMENT 'The Violet Hold',
  `619` int DEFAULT '0' COMMENT 'Ahn''kahet: The Old Kingdom',
  `632` int DEFAULT '0' COMMENT 'The Forge of Souls',
  `650` int DEFAULT '0' COMMENT 'Trial of the Champion',
  `658` int DEFAULT '0' COMMENT 'Pit of Saron',
  `668` int DEFAULT '0' COMMENT 'Halls of Reflection',
  -- Vanilla Dungeons
  `389` int DEFAULT '0' COMMENT 'Ragefire Chasm',
  `36` int DEFAULT '0' COMMENT 'Deadmines',
  `43` int DEFAULT '0' COMMENT 'Wailing Caverns',
  `33` int DEFAULT '0' COMMENT 'Shadowfang Keep',
  `48` int DEFAULT '0' COMMENT 'Blackfathom Deeps',
  `34` int DEFAULT '0' COMMENT 'The Stockade',
  `90` int DEFAULT '0' COMMENT 'Gnomeregan',
  `47` int DEFAULT '0' COMMENT 'Razorfen Kraul',
  `129` int DEFAULT '0' COMMENT 'Razorfen Downs',
  `189` int DEFAULT '0' COMMENT 'Scarlet Monastery',
  `70` int DEFAULT '0' COMMENT 'Uldaman',
  `209` int DEFAULT '0' COMMENT 'Zul''Farrak',
  `349` int DEFAULT '0' COMMENT 'Maraudon',
  `109` int DEFAULT '0' COMMENT 'Temple of Atal''Hakkar',
  `230` int DEFAULT '0' COMMENT 'Blackrock Depths',
  `229` int DEFAULT '0' COMMENT 'Blackrock Spire',
  `429` int DEFAULT '0' COMMENT 'Dire Maul',
  `289` int DEFAULT '0' COMMENT 'Scholomance',
  `329` int DEFAULT '0' COMMENT 'Stratholme',
  -- TBC Dungeons
  `543` int DEFAULT '0' COMMENT 'Hellfire Ramparts',
  `542` int DEFAULT '0' COMMENT 'The Blood Furnace',
  `540` int DEFAULT '0' COMMENT 'The Shattered Halls',
  `547` int DEFAULT '0' COMMENT 'The Slave Pens',
  `546` int DEFAULT '0' COMMENT 'The Underbog',
  `545` int DEFAULT '0' COMMENT 'The Steamvault',
  `557` int DEFAULT '0' COMMENT 'Mana-Tombs',
  `558` int DEFAULT '0' COMMENT 'Auchenai Crypts',
  `556` int DEFAULT '0' COMMENT 'Sethekk Halls',
  `555` int DEFAULT '0' COMMENT 'Shadow Labyrinth',
  `560` int DEFAULT '0' COMMENT 'Old Hillsbrad Foothills',
  `269` int DEFAULT '0' COMMENT 'The Black Morass',
  `553` int DEFAULT '0' COMMENT 'The Botanica',
  `552` int DEFAULT '0' COMMENT 'The Arcatraz',
  `554` int DEFAULT '0' COMMENT 'The Mechanar',
  `585` int DEFAULT '0' COMMENT 'Magisters'' Terrace',
  `last_updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data exporting was unselected.

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
