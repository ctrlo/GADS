-- Convert schema 'share/migrations/_source/deploy/105/001-auto.yml' to 'share/migrations/_source/deploy/106/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `calc_unique` (
  `id` bigint NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `value_text` text NULL,
  `value_int` bigint NULL,
  `value_date` date NULL,
  `value_numeric` decimal(20, 5) NULL,
  `value_date_from` datetime NULL,
  `value_date_to` datetime NULL,
  INDEX `calc_unique_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  UNIQUE `calc_unique_ux_layout_date` (`layout_id`, `value_date`),
  UNIQUE `calc_unique_ux_layout_daterange` (`layout_id`, `value_date_from`, `value_date_to`),
  UNIQUE `calc_unique_ux_layout_int` (`layout_id`, `value_int`),
  UNIQUE `calc_unique_ux_layout_numeric` (`layout_id`, `value_numeric`),
  UNIQUE `calc_unique_ux_layout_text` (`layout_id`, `value_text`),
  CONSTRAINT `calc_unique_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

