-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/45/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/46/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE topic ADD COLUMN prevent_edit_topic_id integer;

;
CREATE INDEX topic_idx_prevent_edit_topic_id on topic (prevent_edit_topic_id);

;
ALTER TABLE topic ADD CONSTRAINT topic_fk_prevent_edit_topic_id FOREIGN KEY (prevent_edit_topic_id)
  REFERENCES topic (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;

COMMIT;

