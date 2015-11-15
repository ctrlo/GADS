-- Convert schema '/root/GADS/share/migrations/_source/deploy/3/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE calc ADD COLUMN decimal_places smallint NULL;

;
ALTER TABLE calcval ADD COLUMN value_numeric decimal(20, 5) NULL;

;

COMMIT;

