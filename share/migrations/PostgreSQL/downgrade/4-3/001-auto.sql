-- Convert schema '/root/GADS/share/migrations/_source/deploy/4/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc DROP COLUMN decimal_places;

;
ALTER TABLE calcval DROP COLUMN value_numeric;

;

COMMIT;

