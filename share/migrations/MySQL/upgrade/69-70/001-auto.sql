-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/69/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/70/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `view_group` (
  `id` integer NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `layout_id` integer NULL,
  `parent_id` integer NULL,
  `order` integer NULL,
  INDEX `view_group_idx_layout_id` (`layout_id`),
  INDEX `view_group_idx_parent_id` (`parent_id`),
  INDEX `view_group_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `view_group_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_group_fk_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_group_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE sort ADD COLUMN `order` integer NULL,
                 ADD INDEX sort_idx_layout_id (layout_id),
                 ADD CONSTRAINT sort_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

