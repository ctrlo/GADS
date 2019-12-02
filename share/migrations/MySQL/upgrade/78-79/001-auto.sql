-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/78/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/79/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `filtered_value` (
  `id` integer NOT NULL auto_increment,
  `submission_id` integer NULL,
  `layout_id` integer NULL,
  `current_id` integer NULL,
  INDEX `filtered_value_idx_current_id` (`current_id`),
  INDEX `filtered_value_idx_layout_id` (`layout_id`),
  INDEX `filtered_value_idx_submission_id` (`submission_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `filtered_value_fk_current_id` FOREIGN KEY (`current_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `filtered_value_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `filtered_value_fk_submission_id` FOREIGN KEY (`submission_id`) REFERENCES `submission` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE submission ENGINE=InnoDB;

;

COMMIT;

