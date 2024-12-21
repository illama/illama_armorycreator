Un script facile d'utilisation permettant de créer des armoires à armes pour des métiers choisis. Fonctionnant sous ESX 1.11.4 (minimum).

Fonctionnalités Principales
- Distribution d'armes,
- Distribution du nombre de munitions,
- Création des armoires via la commande en jeu (createarmory),
- Possibilité de voir les transactions des armes.

Installation
- Téléchargez et placez le script dans votre dossier resources.
- Ajoutez la ressource à votre fichier server.cfg :
- ensure illama_armorycreator
Créez les tables MySQL nécessaires en exécutant la requête suivante :

  ```CREATE TABLE IF NOT EXISTS `illama_armories` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `job` varchar(50) NOT NULL,
      `coords` varchar(255) NOT NULL,
      `weapons` longtext NOT NULL,
      PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;```
  
  ```CREATE TABLE IF NOT EXISTS `illama_armoryguns` (
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
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;;```

    Redémarrez votre serveur FiveM.

Prérequis
- ESX Legacy (ou compatible).
- MySQL-Async pour la gestion des bases de données.
- ox_inventory pour gérer les objets clés.

Crédits
- Développé par Illama.
