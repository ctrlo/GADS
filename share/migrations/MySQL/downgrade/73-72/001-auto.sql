-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/73/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/72/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE dashboard DROP FOREIGN KEY dashboard_fk_instance_id,
                      DROP FOREIGN KEY dashboard_fk_user_id;

;
DROP TABLE dashboard;

;
ALTER TABLE widget DROP FOREIGN KEY widget_fk_dashboard_id,
                   DROP FOREIGN KEY widget_fk_graph_id,
                   DROP FOREIGN KEY widget_fk_view_id;

;
DROP TABLE widget;

;

COMMIT;

