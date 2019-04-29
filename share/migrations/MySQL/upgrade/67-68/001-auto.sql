-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/68/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `display_field` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `display_field_id` integer NOT NULL,
  `regex` text NULL,
  `operator` varchar(16) NULL,
  INDEX `display_field_idx_display_field_id` (`display_field_id`),
  INDEX `display_field_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `display_field_fk_display_field_id` FOREIGN KEY (`display_field_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `display_field_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE layout ADD COLUMN display_condition char(3) NULL;

;

COMMIT;

