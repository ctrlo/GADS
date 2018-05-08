-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/39/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/40/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance ADD COLUMN default_view_limit_extra_id integer NULL,
                     ADD INDEX instance_idx_default_view_limit_extra_id (default_view_limit_extra_id),
                     ADD CONSTRAINT instance_fk_default_view_limit_extra_id FOREIGN KEY (default_view_limit_extra_id) REFERENCES view (id) ON DELETE NO ACTION ON UPDATE NO ACTION;

;
ALTER TABLE view ADD COLUMN is_limit_extra smallint NOT NULL DEFAULT 0;

;

COMMIT;

