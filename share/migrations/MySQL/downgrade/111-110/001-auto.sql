-- Convert schema '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/111/001-auto.yml' to '/home/pwlodarski/src/GADS/bin/../share/migrations/_source/deploy/110/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `file_option` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `filesize` integer NULL,
  INDEX `file_option_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `file_option_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

