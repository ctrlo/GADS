-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/92/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/93/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `instance_rag` (
  `id` integer NOT NULL auto_increment,
  `instance_id` integer NOT NULL,
  `rag` varchar(16) NOT NULL,
  `enabled` smallint NOT NULL DEFAULT 0,
  `description` text NULL,
  INDEX `instance_rag_idx_instance_id` (`instance_id`),
  PRIMARY KEY (`id`),
  UNIQUE `instance_rag_ux_instance_rag` (`instance_id`, `rag`),
  CONSTRAINT `instance_rag_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

