-- Convert schema 'share/migrations/_source/deploy/106/001-auto.yml' to 'share/migrations/_source/deploy/105/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc_unique DROP FOREIGN KEY calc_unique_fk_layout_id;

;
DROP TABLE calc_unique;

;

COMMIT;

