-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/29/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/30/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `instance_group` (
  `id` integer NOT NULL auto_increment,
  `instance_id` integer NOT NULL,
  `group_id` integer NOT NULL,
  `permission` varchar(45) NOT NULL,
  INDEX `instance_group_idx_group_id` (`group_id`),
  INDEX `instance_group_idx_instance_id` (`instance_id`),
  PRIMARY KEY (`id`),
  UNIQUE `instance_group_ux_instance_group_permission` (`instance_id`, `group_id`, `permission`),
  CONSTRAINT `instance_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `instance_group_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

