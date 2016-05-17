-- Convert schema '/root/GADS/share/migrations/_source/deploy/13/001-auto.yml' to '/root/GADS/share/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX record_idx_approval on record (approval);

;

COMMIT;

