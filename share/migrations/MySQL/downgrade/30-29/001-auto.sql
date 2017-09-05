-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/30/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE instance_group DROP FOREIGN KEY instance_group_fk_group_id,
                           DROP FOREIGN KEY instance_group_fk_instance_id;

;
DROP TABLE instance_group;

;

COMMIT;

