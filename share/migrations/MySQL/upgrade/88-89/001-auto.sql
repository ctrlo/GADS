-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/88/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/89/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN view_limit_id integer NULL,
                     ADD INDEX instance_idx_view_limit_id (view_limit_id),
                     ADD CONSTRAINT instance_fk_view_limit_id FOREIGN KEY (view_limit_id) REFERENCES view (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;

COMMIT;

