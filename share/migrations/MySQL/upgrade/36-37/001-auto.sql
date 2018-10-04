-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/36/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/37/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `oauthclient` (
  `id` bigint NOT NULL auto_increment,
  `client_id` varchar(64) NOT NULL,
  `client_secret` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
CREATE TABLE `oauthtoken` (
  `token` varchar(128) NOT NULL,
  `related_token` varchar(128) NOT NULL,
  `oauthclient_id` integer NOT NULL,
  `user_id` bigint NOT NULL,
  `type` varchar(12) NOT NULL,
  `expires` integer NULL,
  INDEX `oauthtoken_idx_oauthclient_id` (`oauthclient_id`),
  INDEX `oauthtoken_idx_user_id` (`user_id`),
  PRIMARY KEY (`token`),
  CONSTRAINT `oauthtoken_fk_oauthclient_id` FOREIGN KEY (`oauthclient_id`) REFERENCES `oauthclient` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `oauthtoken_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

