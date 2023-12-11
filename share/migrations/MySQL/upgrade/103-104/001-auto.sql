-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/103/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `report_defaults` (
  `id` bigint NOT NULL auto_increment,
  `name` varchar(128) NOT NULL,
  `value` varchar(128) NULL,
  `data` longblob NULL,
  `type` varchar(128) NULL,
  INDEX `name_idx` (`name`),
  PRIMARY KEY (`id`)
);

;
SET foreign_key_checks=1;

;
ALTER TABLE report ADD COLUMN title varchar(128) NULL,
                   ADD COLUMN security_marking varchar(128) NULL,
                   ADD COLUMN security_marking_addendum varchar(128) NULL;

;

COMMIT;

