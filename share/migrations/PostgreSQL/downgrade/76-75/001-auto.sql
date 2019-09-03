-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/76/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph DROP COLUMN trend;

;
ALTER TABLE graph DROP COLUMN "from";

;
ALTER TABLE graph DROP COLUMN "to";

;
ALTER TABLE graph DROP COLUMN x_axis_range;

;

COMMIT;

