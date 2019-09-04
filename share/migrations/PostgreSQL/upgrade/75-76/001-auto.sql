-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/75/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/76/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE graph ADD COLUMN trend character varying(45);

;
ALTER TABLE graph ADD COLUMN "from" date;

;
ALTER TABLE graph ADD COLUMN "to" date;

;
ALTER TABLE graph ADD COLUMN x_axis_range character varying(45);

;

COMMIT;

