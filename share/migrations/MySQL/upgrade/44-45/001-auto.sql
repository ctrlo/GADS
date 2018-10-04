-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/44/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/45/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `topic` (
  `id` integer NOT NULL auto_increment,
  `instance_id` integer NULL,
  `name` text NULL,
  `initial_state` varchar(32) NULL,
  `click_to_edit` smallint NOT NULL DEFAULT 0,
  INDEX `topic_idx_instance_id` (`instance_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `topic_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE layout ADD COLUMN topic_id integer NULL,
                   ADD INDEX layout_idx_topic_id (topic_id),
                   ADD CONSTRAINT layout_fk_topic_id FOREIGN KEY (topic_id) REFERENCES topic (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

