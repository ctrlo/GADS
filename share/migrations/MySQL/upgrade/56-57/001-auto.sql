-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/56/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/57/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `submission` (
  `id` integer NOT NULL auto_increment,
  `token` varchar(64) NOT NULL,
  `created` datetime NULL,
  `submitted` smallint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE `ux_submission_token` (`token`)
);

;
SET foreign_key_checks=1;

;

COMMIT;

