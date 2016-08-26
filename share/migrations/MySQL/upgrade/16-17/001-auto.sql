-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/16/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `site` (
  `id` integer NOT NULL auto_increment,
  `host` varchar(128) NULL,
  `created` datetime NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE audit ADD COLUMN site_id integer NULL,
                  ADD INDEX audit_idx_site_id (site_id),
                  ADD CONSTRAINT audit_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE "group" ADD COLUMN site_id integer NULL,
                  ADD INDEX group_idx_site_id (site_id),
                  ADD CONSTRAINT group_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE import ADD COLUMN site_id integer NULL,
                   ADD INDEX import_idx_site_id (site_id),
                   ADD CONSTRAINT import_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE instance ADD COLUMN site_id integer NULL,
                     ADD INDEX instance_idx_site_id (site_id),
                     ADD CONSTRAINT instance_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE organisation ADD COLUMN site_id integer NULL,
                         ADD INDEX organisation_idx_site_id (site_id),
                         ADD CONSTRAINT organisation_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE title ADD COLUMN site_id integer NULL,
                  ADD INDEX title_idx_site_id (site_id),
                  ADD CONSTRAINT title_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE user ADD COLUMN site_id integer NULL,
                 ADD INDEX user_idx_site_id (site_id),
                 ADD CONSTRAINT user_fk_site_id FOREIGN KEY (site_id) REFERENCES site (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

