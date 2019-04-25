-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/66/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `team` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `site_id` integer NULL,
  INDEX `team_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `team_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE site ADD COLUMN register_team_help text NULL,
                 ADD COLUMN register_team_name text NULL,
                 ADD COLUMN register_show_team smallint NOT NULL DEFAULT 0;

;
ALTER TABLE user ADD COLUMN team_id integer NULL,
                 ADD INDEX user_idx_team_id (team_id),
                 ADD CONSTRAINT user_fk_team_id FOREIGN KEY (team_id) REFERENCES team (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

