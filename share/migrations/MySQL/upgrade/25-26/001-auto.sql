-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/25/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/26/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `view_limit` (
  `id` bigint NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  INDEX `view_limit_idx_user_id` (`user_id`),
  INDEX `view_limit_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `view_limit_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_limit_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

