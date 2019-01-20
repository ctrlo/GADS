-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/57/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/58/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `department` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `site_id` integer NULL,
  INDEX `department_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `department_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE site ADD COLUMN register_department_help text NULL,
                 ADD COLUMN register_department_name text NULL,
                 ADD COLUMN register_show_department smallint NOT NULL DEFAULT 0;

;
ALTER TABLE user ADD COLUMN department_id integer NULL,
                 ADD INDEX user_idx_department_id (department_id),
                 ADD CONSTRAINT user_fk_department_id FOREIGN KEY (department_id) REFERENCES department (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

