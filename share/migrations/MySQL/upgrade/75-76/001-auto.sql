-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/76/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph ADD COLUMN trend varchar(45) NULL,
                  ADD COLUMN `from` date NULL,
                  ADD COLUMN `to` date NULL,
                  ADD COLUMN x_axis_range varchar(45) NULL;

;

COMMIT;

