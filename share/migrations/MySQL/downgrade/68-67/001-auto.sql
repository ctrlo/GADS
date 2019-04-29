-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/68/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/67/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE layout DROP COLUMN display_condition;

;
ALTER TABLE display_field DROP FOREIGN KEY display_field_fk_display_field_id,
                          DROP FOREIGN KEY display_field_fk_layout_id;

;
DROP TABLE display_field;

;

COMMIT;

