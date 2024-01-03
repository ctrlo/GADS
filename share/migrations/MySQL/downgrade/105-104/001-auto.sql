-- Convert schema '/home/droberts/source/gads/share/migrations/_source/deploy/105/001-auto.yml' to '/home/droberts/source/gads/share/migrations/_source/deploy/104/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance DROP COLUMN security_marking;

;
ALTER TABLE report DROP COLUMN security_marking;

;
ALTER TABLE site DROP COLUMN security_marking,
                 DROP COLUMN site_logo;

;

COMMIT;

