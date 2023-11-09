-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/100/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/101/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `report` (
  `id` bigint NOT NULL auto_increment,
  `name` varchar(128) NOT NULL,
  `description` varchar(128) NULL,
  `user_id` bigint NULL,
  `createdby` bigint NULL,
  `created` datetime NULL,
  `instance_id` bigint NULL,
  `deleted` datetime NULL,
  INDEX `report_idx_createdby` (`createdby`),
  INDEX `report_idx_instance_id` (`instance_id`),
  INDEX `report_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `report_fk_createdby` FOREIGN KEY (`createdby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `report_instance` (
  `id` integer NOT NULL auto_increment,
  `report_id` integer NOT NULL,
  `layout_id` bigint NOT NULL,
  `order` integer NULL,
  INDEX `report_instance_idx_layout_id` (`layout_id`),
  INDEX `report_instance_idx_report_id` (`report_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `report_instance_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_instance_fk_report_id` FOREIGN KEY (`report_id`) REFERENCES `report` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

