-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/89/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/90/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `export` (
  `id` integer NOT NULL auto_increment,
  `site_id` integer NULL,
  `user_id` bigint NOT NULL,
  `type` varchar(45) NULL,
  `started` datetime NULL,
  `completed` datetime NULL,
  `result` text NULL,
  `mimetype` text NULL,
  `content` longblob NULL,
  INDEX `export_idx_site_id` (`site_id`),
  INDEX `export_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `export_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `export_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

