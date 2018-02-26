-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/31/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE current ADD COLUMN deleted datetime NULL,
                    ADD COLUMN deletedby bigint NULL,
                    ADD INDEX current_idx_deletedby (deletedby),
                    ADD CONSTRAINT current_fk_deletedby FOREIGN KEY (deletedby) REFERENCES user (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

