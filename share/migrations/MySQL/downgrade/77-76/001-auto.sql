-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/77/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/76/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calcval DROP COLUMN value_date_from,
                    DROP COLUMN value_date_to;

;

COMMIT;

