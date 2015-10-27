-- Convert schema '/root/GADS/share/migrations/_source/deploy/1/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `curval` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `value` bigint NULL,
  INDEX `curval_idx_layout_id` (`layout_id`),
  INDEX `curval_idx_record_id` (`record_id`),
  INDEX `curval_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `curval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `curval_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `curval_fk_value` FOREIGN KEY (`value`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `curval_fields` (
  `id` integer NOT NULL auto_increment,
  `parent_id` integer NOT NULL,
  `child_id` integer NOT NULL,
  INDEX `curval_fields_idx_child_id` (`child_id`),
  INDEX `curval_fields_idx_parent_id` (`parent_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `curval_fields_fk_child_id` FOREIGN KEY (`child_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `curval_fields_fk_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE calcval ADD COLUMN value_text text NULL,
                    ADD COLUMN value_int bigint NULL,
                    ADD COLUMN value_date date NULL;

;
ALTER TABLE instance CHANGE COLUMN name name text NULL;

;
ALTER TABLE layout DROP COLUMN hidden;

;
ALTER TABLE user ADD COLUMN limit_to_view bigint NULL,
                 CHANGE COLUMN email email text NULL,
                 CHANGE COLUMN username username text NULL,
                 ADD INDEX user_idx_limit_to_view (limit_to_view),
                 ADD INDEX user_idx_email (email(64)),
                 ADD INDEX user_idx_username (username(64)),
                 ADD CONSTRAINT user_fk_limit_to_view FOREIGN KEY (limit_to_view) REFERENCES view (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

