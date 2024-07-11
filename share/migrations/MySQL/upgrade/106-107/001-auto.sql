-- Convert schema '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/106/001-auto.yml' to '/home/droberts/source/gads/bin/../share/migrations/_source/deploy/107/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `report_group` (
  `id` integer NOT NULL auto_increment,
  `report_id` integer NOT NULL,
  `group_id` integer NOT NULL,
  INDEX `report_group_idx_group_id` (`group_id`),
  INDEX `report_group_idx_report_id` (`report_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `report_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_group_fk_report_id` FOREIGN KEY (`report_id`) REFERENCES `report` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

