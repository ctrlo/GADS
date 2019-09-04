-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/72/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/73/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `dashboard` (
  `id` integer NOT NULL auto_increment,
  `instance_id` integer NULL,
  `user_id` integer NULL,
  INDEX `dashboard_idx_instance_id` (`instance_id`),
  INDEX `dashboard_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `dashboard_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `dashboard_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
CREATE TABLE `widget` (
  `id` integer NOT NULL auto_increment,
  `grid_id` varchar(64) NULL,
  `dashboard_id` integer NULL,
  `type` varchar(16) NULL,
  `static` smallint NOT NULL DEFAULT 0,
  `h` smallint NULL DEFAULT 0,
  `w` smallint NULL DEFAULT 0,
  `x` smallint NULL DEFAULT 0,
  `y` smallint NULL DEFAULT 0,
  `content` text NULL,
  `view_id` integer NULL,
  `graph_id` integer NULL,
  `rows` integer NULL,
  `tl_options` text NULL,
  `globe_options` text NULL,
  INDEX `widget_idx_dashboard_id` (`dashboard_id`),
  INDEX `widget_idx_graph_id` (`graph_id`),
  INDEX `widget_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  UNIQUE `widget_ux_dashboard_grid` (`dashboard_id`, `grid_id`),
  CONSTRAINT `widget_fk_dashboard_id` FOREIGN KEY (`dashboard_id`) REFERENCES `dashboard` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `widget_fk_graph_id` FOREIGN KEY (`graph_id`) REFERENCES `graph` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `widget_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

