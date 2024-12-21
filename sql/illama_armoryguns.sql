CREATE TABLE IF NOT EXISTS `illama_armories` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `job` varchar(50) NOT NULL,
    `coords` varchar(255) NOT NULL,
    `weapons` longtext NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `illama_armoryguns` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `serial` varchar(50) NOT NULL,
    `weapon` varchar(50) NOT NULL,
    `job` varchar(50) NOT NULL,
    `owner` varchar(50) DEFAULT NULL,
    `status` enum('stored','taken') NOT NULL DEFAULT 'stored',
    `last_action_date` datetime NOT NULL,
    `last_action_by` varchar(50) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;