-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/76/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph DROP COLUMN trend,
                  DROP COLUMN `from`,
                  DROP COLUMN `to`,
                  DROP COLUMN x_axis_range;

;

COMMIT;

