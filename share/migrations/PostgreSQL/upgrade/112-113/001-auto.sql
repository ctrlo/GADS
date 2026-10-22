-- Convert schema '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/112/001-auto.yml' to '/home/abeverley/git/GADS-pawel/bin/../share/migrations/_source/deploy/113/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "user" ADD COLUMN created_by_id bigint;

;
CREATE INDEX user_idx_created_by_id on "user" (created_by_id);

;
ALTER TABLE "user" ADD CONSTRAINT user_fk_created_by_id FOREIGN KEY (created_by_id)
  REFERENCES "user" (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

