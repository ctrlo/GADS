-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/93/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/92/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance_rag DROP FOREIGN KEY instance_rag_fk_instance_id;

;
DROP TABLE instance_rag;

;

COMMIT;

