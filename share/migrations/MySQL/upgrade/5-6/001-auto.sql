-- Convert schema '/root/GADS/share/migrations/_source/deploy/5/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `user_lastrecord` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `instance_id` integer NOT NULL,
  `user_id` bigint NOT NULL,
  INDEX `user_lastrecord_idx_instance_id` (`instance_id`),
  INDEX `user_lastrecord_idx_record_id` (`record_id`),
  INDEX `user_lastrecord_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_lastrecord_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_lastrecord_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_lastrecord_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

