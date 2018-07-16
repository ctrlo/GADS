-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/45/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/44/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP FOREIGN KEY layout_fk_topic_id,
                   DROP INDEX layout_idx_topic_id,
                   DROP COLUMN topic_id;

;
ALTER TABLE topic DROP FOREIGN KEY topic_fk_instance_id;

;
DROP TABLE topic;

;

COMMIT;

