-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/15/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `import` (
  `id` integer NOT NULL auto_increment,
  `user_id` bigint NOT NULL,
  `type` varchar(45) NULL,
  `row_count` integer NOT NULL DEFAULT 0,
  `started` datetime NULL,
  `completed` datetime NULL,
  `written_count` integer NOT NULL DEFAULT 0,
  `error_count` integer NOT NULL DEFAULT 0,
  `skipped_count` integer NOT NULL DEFAULT 0,
  `result` text NULL,
  INDEX `import_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `import_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `import_row` (
  `id` bigint NOT NULL auto_increment,
  `import_id` integer NOT NULL,
  `status` varchar(45) NULL,
  `content` text NULL,
  `errors` text NULL,
  `changes` text NULL,
  INDEX `import_row_idx_import_id` (`import_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `import_row_fk_import_id` FOREIGN KEY (`import_id`) REFERENCES `import` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

