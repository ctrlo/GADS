-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/46/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/45/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE topic DROP CONSTRAINT topic_fk_prevent_edit_topic_id;

;
DROP INDEX topic_idx_prevent_edit_topic_id;

;
ALTER TABLE topic DROP COLUMN prevent_edit_topic_id;

;

COMMIT;

