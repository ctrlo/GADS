--
-- Created by SQL::Translator::Producer::MySQL
-- Created on Fri Oct 10 15:24:49 2025
--
;
SET foreign_key_checks=0;
--
-- Table: `alert`
--
CREATE TABLE `alert` (
  `id` integer NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `frequency` integer NOT NULL DEFAULT 0,
  INDEX `alert_idx_user_id` (`user_id`),
  INDEX `alert_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `alert_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `alert_cache`
--
CREATE TABLE `alert_cache` (
  `id` bigint NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `view_id` bigint NOT NULL,
  `current_id` bigint NOT NULL,
  `user_id` bigint NULL,
  INDEX `alert_cache_idx_current_id` (`current_id`),
  INDEX `alert_cache_idx_layout_id` (`layout_id`),
  INDEX `alert_cache_idx_user_id` (`user_id`),
  INDEX `alert_cache_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `alert_cache_fk_current_id` FOREIGN KEY (`current_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_cache_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_cache_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_cache_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `alert_column`
--
CREATE TABLE `alert_column` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `instance_id` integer NOT NULL,
  INDEX `alert_column_idx_instance_id` (`instance_id`),
  INDEX `alert_column_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `alert_column_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_column_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `alert_send`
--
CREATE TABLE `alert_send` (
  `id` bigint NOT NULL auto_increment,
  `layout_id` integer NULL,
  `alert_id` integer NOT NULL,
  `current_id` bigint NOT NULL,
  `status` char(7) NULL,
  INDEX `alert_send_idx_alert_id` (`alert_id`),
  INDEX `alert_send_idx_current_id` (`current_id`),
  INDEX `alert_send_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  UNIQUE `alert_send_all` (`layout_id`, `alert_id`, `current_id`, `status`),
  CONSTRAINT `alert_send_fk_alert_id` FOREIGN KEY (`alert_id`) REFERENCES `alert` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_send_fk_current_id` FOREIGN KEY (`current_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_send_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `audit`
--
CREATE TABLE `audit` (
  `id` bigint NOT NULL auto_increment,
  `site_id` integer NULL,
  `user_id` bigint NULL,
  `type` varchar(45) NULL,
  `datetime` datetime NULL,
  `method` varchar(45) NULL,
  `url` text NULL,
  `description` text NULL,
  `instance_id` integer NULL,
  INDEX `audit_idx_instance_id` (`instance_id`),
  INDEX `audit_idx_site_id` (`site_id`),
  INDEX `audit_idx_user_id` (`user_id`),
  INDEX `audit_idx_datetime` (`datetime`),
  INDEX `audit_idx_user_instance_datetime` (`user_id`, `instance_id`, `datetime`),
  PRIMARY KEY (`id`),
  CONSTRAINT `audit_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `audit_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `audit_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `authentication`
--
CREATE TABLE `authentication` (
  `id` bigint NOT NULL auto_increment,
  `site_id` integer NULL,
  `type` varchar(255) NOT NULL DEFAULT '1',
  `name` text NULL,
  `xml` text NULL,
  `cacert` text NULL,
  `sp_cert` text NULL,
  `sp_key` text NULL,
  `saml2_firstname` text NULL,
  `saml2_surname` text NULL,
  `saml2_groupname` text NULL,
  `saml2_relaystate` varchar(80) NULL,
  `enabled` smallint NOT NULL DEFAULT 0,
  `saml2_unique_id` varchar(80) NULL,
  `saml2_nameid` varchar(30) NULL,
  `error_messages` text NULL,
  INDEX `authentication_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  UNIQUE `authentication_ux_saml2_relaystate` (`saml2_relaystate`),
  UNIQUE `authentication_ux_saml2_unique_id` (`saml2_unique_id`),
  CONSTRAINT `authentication_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `calc`
--
CREATE TABLE `calc` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NULL,
  `calc` mediumtext NULL,
  `code` mediumtext NULL,
  `return_format` varchar(45) NULL,
  `decimal_places` smallint NULL,
  INDEX `calc_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `calc_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `calc_unique`
--
CREATE TABLE `calc_unique` (
  `id` bigint NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `value_text` text NULL,
  `value_int` bigint NULL,
  `value_date` date NULL,
  `value_numeric` decimal(20, 5) NULL,
  `value_date_from` datetime NULL,
  `value_date_to` datetime NULL,
  INDEX `calc_unique_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  UNIQUE `calc_unique_ux_layout_date` (`layout_id`, `value_date`),
  UNIQUE `calc_unique_ux_layout_daterange` (`layout_id`, `value_date_from`, `value_date_to`),
  UNIQUE `calc_unique_ux_layout_int` (`layout_id`, `value_int`),
  UNIQUE `calc_unique_ux_layout_numeric` (`layout_id`, `value_numeric`),
  UNIQUE `calc_unique_ux_layout_text` (`layout_id`, `value_text`),
  CONSTRAINT `calc_unique_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `calcval`
--
CREATE TABLE `calcval` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `value_text` text NULL,
  `value_int` bigint NULL,
  `value_date` date NULL,
  `value_numeric` decimal(20, 5) NULL,
  `value_date_from` datetime NULL,
  `value_date_to` datetime NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `calcval_idx_layout_id` (`layout_id`),
  INDEX `calcval_idx_purged_by` (`purged_by`),
  INDEX `calcval_idx_record_id` (`record_id`),
  INDEX `calcval_idx_value_text` (`value_text`(64)),
  INDEX `calcval_idx_value_numeric` (`value_numeric`),
  INDEX `calcval_idx_value_int` (`value_int`),
  INDEX `calcval_idx_value_date` (`value_date`),
  PRIMARY KEY (`id`),
  CONSTRAINT `calcval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `calcval_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `calcval_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `current`
--
CREATE TABLE `current` (
  `id` bigint NOT NULL auto_increment,
  `serial` bigint NULL,
  `parent_id` bigint NULL,
  `instance_id` integer NULL,
  `linked_id` bigint NULL,
  `deleted` datetime NULL,
  `deletedby` bigint NULL,
  `draftuser_id` bigint NULL,
  INDEX `current_idx_deletedby` (`deletedby`),
  INDEX `current_idx_draftuser_id` (`draftuser_id`),
  INDEX `current_idx_instance_id` (`instance_id`),
  INDEX `current_idx_linked_id` (`linked_id`),
  INDEX `current_idx_parent_id` (`parent_id`),
  PRIMARY KEY (`id`),
  UNIQUE `current_ux_instance_serial` (`instance_id`, `serial`),
  CONSTRAINT `current_fk_deletedby` FOREIGN KEY (`deletedby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `current_fk_draftuser_id` FOREIGN KEY (`draftuser_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `current_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `current_fk_linked_id` FOREIGN KEY (`linked_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `current_fk_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `curval`
--
CREATE TABLE `curval` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` bigint NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `curval_idx_layout_id` (`layout_id`),
  INDEX `curval_idx_purged_by` (`purged_by`),
  INDEX `curval_idx_record_id` (`record_id`),
  INDEX `curval_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `curval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `curval_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `curval_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `curval_fk_value` FOREIGN KEY (`value`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `curval_fields`
--
CREATE TABLE `curval_fields` (
  `id` integer NOT NULL auto_increment,
  `parent_id` integer NOT NULL,
  `child_id` integer NOT NULL,
  INDEX `curval_fields_idx_child_id` (`child_id`),
  INDEX `curval_fields_idx_parent_id` (`parent_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `curval_fields_fk_child_id` FOREIGN KEY (`child_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `curval_fields_fk_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `dashboard`
--
CREATE TABLE `dashboard` (
  `id` integer NOT NULL auto_increment,
  `site_id` integer NULL,
  `instance_id` integer NULL,
  `user_id` integer NULL,
  INDEX `dashboard_idx_instance_id` (`instance_id`),
  INDEX `dashboard_idx_site_id` (`site_id`),
  INDEX `dashboard_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `dashboard_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `dashboard_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `dashboard_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `date`
--
CREATE TABLE `date` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` date NULL,
  `purged_by` bigint NULL,
  `purged_on` timestamp NULL,
  INDEX `date_idx_layout_id` (`layout_id`),
  INDEX `date_idx_purged_by` (`purged_by`),
  INDEX `date_idx_record_id` (`record_id`),
  INDEX `date_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `date_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `date_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `date_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `daterange`
--
CREATE TABLE `daterange` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `from` date NULL,
  `to` date NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` varchar(45) NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `daterange_idx_layout_id` (`layout_id`),
  INDEX `daterange_idx_purged_by` (`purged_by`),
  INDEX `daterange_idx_record_id` (`record_id`),
  INDEX `daterange_idx_from` (`from`),
  INDEX `daterange_idx_to` (`to`),
  INDEX `daterange_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `daterange_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `daterange_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `daterange_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `department`
--
CREATE TABLE `department` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `site_id` integer NULL,
  `deleted` smallint NOT NULL DEFAULT 0,
  INDEX `department_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `department_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `display_field`
--
CREATE TABLE `display_field` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `display_field_id` integer NOT NULL,
  `regex` text NULL,
  `operator` varchar(16) NULL,
  INDEX `display_field_idx_display_field_id` (`display_field_id`),
  INDEX `display_field_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `display_field_fk_display_field_id` FOREIGN KEY (`display_field_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `display_field_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `enum`
--
CREATE TABLE `enum` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` integer NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `enum_idx_layout_id` (`layout_id`),
  INDEX `enum_idx_purged_by` (`purged_by`),
  INDEX `enum_idx_record_id` (`record_id`),
  INDEX `enum_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `enum_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `enum_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `enum_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `enum_fk_value` FOREIGN KEY (`value`) REFERENCES `enumval` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `enumval`
--
CREATE TABLE `enumval` (
  `id` integer NOT NULL auto_increment,
  `value` text NULL,
  `layout_id` integer NULL,
  `deleted` smallint NOT NULL DEFAULT 0,
  `parent` integer NULL,
  `position` integer NULL,
  INDEX `enumval_idx_layout_id` (`layout_id`),
  INDEX `enumval_idx_parent` (`parent`),
  INDEX `enumval_idx_value` (`value`(64)),
  PRIMARY KEY (`id`),
  CONSTRAINT `enumval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `enumval_fk_parent` FOREIGN KEY (`parent`) REFERENCES `enumval` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `export`
--
CREATE TABLE `export` (
  `id` integer NOT NULL auto_increment,
  `site_id` integer NULL,
  `user_id` bigint NOT NULL,
  `type` varchar(45) NULL,
  `started` datetime NULL,
  `completed` datetime NULL,
  `result` text NULL,
  `result_internal` text NULL,
  `mimetype` text NULL,
  `content` longblob NULL,
  INDEX `export_idx_site_id` (`site_id`),
  INDEX `export_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `export_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `export_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `file`
--
CREATE TABLE `file` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` bigint NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `file_idx_layout_id` (`layout_id`),
  INDEX `file_idx_purged_by` (`purged_by`),
  INDEX `file_idx_record_id` (`record_id`),
  INDEX `file_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `file_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `file_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `file_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `file_fk_value` FOREIGN KEY (`value`) REFERENCES `fileval` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `file_option`
--
CREATE TABLE `file_option` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `filesize` integer NULL,
  INDEX `file_option_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `file_option_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `fileval`
--
CREATE TABLE `fileval` (
  `id` bigint NOT NULL auto_increment,
  `name` text NULL,
  `mimetype` text NULL,
  `is_independent` smallint NOT NULL DEFAULT 0,
  `edit_user_id` bigint NULL,
  INDEX `fileval_idx_edit_user_id` (`edit_user_id`),
  INDEX `fileval_idx_name` (`name`(64)),
  PRIMARY KEY (`id`),
  CONSTRAINT `fileval_fk_edit_user_id` FOREIGN KEY (`edit_user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `filter`
--
CREATE TABLE `filter` (
  `id` bigint NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  INDEX `filter_idx_layout_id` (`layout_id`),
  INDEX `filter_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `filter_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `filter_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `filtered_value`
--
CREATE TABLE `filtered_value` (
  `id` integer NOT NULL auto_increment,
  `submission_id` integer NULL,
  `layout_id` integer NULL,
  `current_id` integer NULL,
  INDEX `filtered_value_idx_current_id` (`current_id`),
  INDEX `filtered_value_idx_layout_id` (`layout_id`),
  INDEX `filtered_value_idx_submission_id` (`submission_id`),
  PRIMARY KEY (`id`),
  UNIQUE `ux_submission_layout_current` (`submission_id`, `layout_id`, `current_id`),
  CONSTRAINT `filtered_value_fk_current_id` FOREIGN KEY (`current_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `filtered_value_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `filtered_value_fk_submission_id` FOREIGN KEY (`submission_id`) REFERENCES `submission` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `graph`
--
CREATE TABLE `graph` (
  `id` integer NOT NULL auto_increment,
  `title` text NULL,
  `description` text NULL,
  `y_axis` integer NULL,
  `y_axis_stack` varchar(45) NULL,
  `y_axis_label` text NULL,
  `x_axis` integer NULL,
  `x_axis_link` integer NULL,
  `x_axis_grouping` varchar(45) NULL,
  `group_by` integer NULL,
  `stackseries` smallint NOT NULL DEFAULT 0,
  `as_percent` smallint NOT NULL DEFAULT 0,
  `type` varchar(45) NULL,
  `metric_group` integer NULL,
  `instance_id` integer NULL,
  `is_shared` smallint NOT NULL DEFAULT 0,
  `user_id` bigint NULL,
  `group_id` integer NULL,
  `trend` varchar(45) NULL,
  `from` date NULL,
  `to` date NULL,
  `x_axis_range` varchar(45) NULL,
  INDEX `graph_idx_group_id` (`group_id`),
  INDEX `graph_idx_group_by` (`group_by`),
  INDEX `graph_idx_instance_id` (`instance_id`),
  INDEX `graph_idx_metric_group` (`metric_group`),
  INDEX `graph_idx_user_id` (`user_id`),
  INDEX `graph_idx_x_axis` (`x_axis`),
  INDEX `graph_idx_x_axis_link` (`x_axis_link`),
  INDEX `graph_idx_y_axis` (`y_axis`),
  PRIMARY KEY (`id`),
  CONSTRAINT `graph_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_group_by` FOREIGN KEY (`group_by`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_metric_group` FOREIGN KEY (`metric_group`) REFERENCES `metric_group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_x_axis` FOREIGN KEY (`x_axis`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_x_axis_link` FOREIGN KEY (`x_axis_link`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_y_axis` FOREIGN KEY (`y_axis`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `graph_color`
--
CREATE TABLE `graph_color` (
  `id` bigint NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `color` char(6) NULL,
  PRIMARY KEY (`id`),
  UNIQUE `ux_graph_color_name` (`name`)
);
--
-- Table: `group`
--
CREATE TABLE `group` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `default_read` smallint NOT NULL DEFAULT 0,
  `default_write_new` smallint NOT NULL DEFAULT 0,
  `default_write_existing` smallint NOT NULL DEFAULT 0,
  `default_approve_new` smallint NOT NULL DEFAULT 0,
  `default_approve_existing` smallint NOT NULL DEFAULT 0,
  `default_write_new_no_approval` smallint NOT NULL DEFAULT 0,
  `default_write_existing_no_approval` smallint NOT NULL DEFAULT 0,
  `site_id` integer NULL,
  INDEX `group_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `group_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `import`
--
CREATE TABLE `import` (
  `id` integer NOT NULL auto_increment,
  `site_id` integer NULL,
  `instance_id` integer NULL,
  `user_id` bigint NOT NULL,
  `type` varchar(45) NULL,
  `row_count` integer NOT NULL DEFAULT 0,
  `started` datetime NULL,
  `completed` datetime NULL,
  `written_count` integer NOT NULL DEFAULT 0,
  `error_count` integer NOT NULL DEFAULT 0,
  `skipped_count` integer NOT NULL DEFAULT 0,
  `result` text NULL,
  INDEX `import_idx_instance_id` (`instance_id`),
  INDEX `import_idx_site_id` (`site_id`),
  INDEX `import_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `import_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `import_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `import_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `import_row`
--
CREATE TABLE `import_row` (
  `id` bigint NOT NULL auto_increment,
  `import_id` integer NOT NULL,
  `status` varchar(45) NULL,
  `content` text NULL,
  `errors` text NULL,
  `changes` text NULL,
  INDEX `import_row_idx_import_id` (`import_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `import_row_fk_import_id` FOREIGN KEY (`import_id`) REFERENCES `import` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `instance`
--
CREATE TABLE `instance` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `name_short` varchar(64) NULL,
  `site_id` integer NULL,
  `sort_layout_id` integer NULL,
  `sort_type` varchar(45) NULL,
  `view_limit_id` integer NULL,
  `default_view_limit_extra_id` integer NULL,
  `homepage_text` text NULL,
  `homepage_text2` text NULL,
  `record_name` text NULL,
  `forget_history` smallint NULL DEFAULT 0,
  `no_overnight_update` smallint NULL DEFAULT 0,
  `api_index_layout_id` integer NULL,
  `forward_record_after_create` smallint NULL DEFAULT 0,
  `no_hide_blank` smallint NOT NULL DEFAULT 0,
  `no_download_pdf` smallint NOT NULL DEFAULT 0,
  `no_copy_record` smallint NOT NULL DEFAULT 0,
  `hide_in_selector` smallint NOT NULL DEFAULT 0,
  `security_marking` text NULL,
  INDEX `instance_idx_api_index_layout_id` (`api_index_layout_id`),
  INDEX `instance_idx_default_view_limit_extra_id` (`default_view_limit_extra_id`),
  INDEX `instance_idx_site_id` (`site_id`),
  INDEX `instance_idx_sort_layout_id` (`sort_layout_id`),
  INDEX `instance_idx_view_limit_id` (`view_limit_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `instance_fk_api_index_layout_id` FOREIGN KEY (`api_index_layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `instance_fk_default_view_limit_extra_id` FOREIGN KEY (`default_view_limit_extra_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `instance_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `instance_fk_sort_layout_id` FOREIGN KEY (`sort_layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `instance_fk_view_limit_id` FOREIGN KEY (`view_limit_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `instance_group`
--
CREATE TABLE `instance_group` (
  `id` integer NOT NULL auto_increment,
  `instance_id` integer NOT NULL,
  `group_id` integer NOT NULL,
  `permission` varchar(45) NOT NULL,
  INDEX `instance_group_idx_group_id` (`group_id`),
  INDEX `instance_group_idx_instance_id` (`instance_id`),
  PRIMARY KEY (`id`),
  UNIQUE `instance_group_ux_instance_group_permission` (`instance_id`, `group_id`, `permission`),
  CONSTRAINT `instance_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `instance_group_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `instance_rag`
--
CREATE TABLE `instance_rag` (
  `id` integer NOT NULL auto_increment,
  `instance_id` integer NOT NULL,
  `rag` varchar(16) NOT NULL,
  `enabled` smallint NOT NULL DEFAULT 0,
  `description` text NULL,
  INDEX `instance_rag_idx_instance_id` (`instance_id`),
  PRIMARY KEY (`id`),
  UNIQUE `instance_rag_ux_instance_rag` (`instance_id`, `rag`),
  CONSTRAINT `instance_rag_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `intgr`
--
CREATE TABLE `intgr` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` bigint NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `intgr_idx_layout_id` (`layout_id`),
  INDEX `intgr_idx_purged_by` (`purged_by`),
  INDEX `intgr_idx_record_id` (`record_id`),
  INDEX `intgr_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `intgr_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `intgr_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `intgr_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `layout`
--
CREATE TABLE `layout` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `name_short` varchar(64) NULL,
  `type` varchar(45) NULL,
  `permission` integer NOT NULL DEFAULT 0,
  `optional` smallint NOT NULL DEFAULT 0,
  `remember` smallint NOT NULL DEFAULT 0,
  `isunique` smallint NOT NULL DEFAULT 0,
  `textbox` smallint NOT NULL DEFAULT 0,
  `typeahead` smallint NOT NULL DEFAULT 0,
  `force_regex` text NULL,
  `position` integer NULL,
  `ordering` varchar(45) NULL,
  `end_node_only` smallint NOT NULL DEFAULT 0,
  `multivalue` smallint NOT NULL DEFAULT 0,
  `can_child` smallint NOT NULL DEFAULT 0,
  `internal` smallint NOT NULL DEFAULT 0,
  `description` text NULL,
  `helptext` text NULL,
  `options` text NULL,
  `display_field` integer NULL,
  `display_regex` text NULL,
  `display_condition` char(3) NULL,
  `display_matchtype` text NULL,
  `instance_id` integer NULL,
  `link_parent` integer NULL,
  `related_field` integer NULL,
  `width` integer NOT NULL DEFAULT 50,
  `filter` text NULL,
  `topic_id` integer NULL,
  `aggregate` varchar(45) NULL,
  `group_display` varchar(45) NULL,
  `lookup_endpoint` text NULL,
  `lookup_group` smallint NULL,
  `notes` text NULL,
  INDEX `layout_idx_display_field` (`display_field`),
  INDEX `layout_idx_instance_id` (`instance_id`),
  INDEX `layout_idx_link_parent` (`link_parent`),
  INDEX `layout_idx_related_field` (`related_field`),
  INDEX `layout_idx_topic_id` (`topic_id`),
  PRIMARY KEY (`id`),
  UNIQUE `layout_ux_instance_name_short` (`instance_id`, `name_short`),
  CONSTRAINT `layout_fk_display_field` FOREIGN KEY (`display_field`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_fk_link_parent` FOREIGN KEY (`link_parent`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_fk_related_field` FOREIGN KEY (`related_field`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_fk_topic_id` FOREIGN KEY (`topic_id`) REFERENCES `topic` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `layout_depend`
--
CREATE TABLE `layout_depend` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `depends_on` integer NOT NULL,
  INDEX `layout_depend_idx_depends_on` (`depends_on`),
  INDEX `layout_depend_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `layout_depend_fk_depends_on` FOREIGN KEY (`depends_on`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_depend_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `layout_group`
--
CREATE TABLE `layout_group` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `group_id` integer NOT NULL,
  `permission` varchar(45) NOT NULL,
  INDEX `layout_group_idx_group_id` (`group_id`),
  INDEX `layout_group_idx_layout_id` (`layout_id`),
  INDEX `layout_group_idx_permission` (`permission`),
  PRIMARY KEY (`id`),
  UNIQUE `layout_group_ux_layout_group_permission` (`layout_id`, `group_id`, `permission`),
  CONSTRAINT `layout_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_group_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `metric`
--
CREATE TABLE `metric` (
  `id` integer NOT NULL auto_increment,
  `metric_group` integer NOT NULL,
  `x_axis_value` text NULL,
  `target` bigint NULL,
  `y_axis_grouping_value` text NULL,
  INDEX `metric_idx_metric_group` (`metric_group`),
  PRIMARY KEY (`id`),
  CONSTRAINT `metric_fk_metric_group` FOREIGN KEY (`metric_group`) REFERENCES `metric_group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `metric_group`
--
CREATE TABLE `metric_group` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `instance_id` integer NULL,
  INDEX `metric_group_idx_instance_id` (`instance_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `metric_group_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `oauthclient`
--
CREATE TABLE `oauthclient` (
  `id` bigint NOT NULL auto_increment,
  `client_id` varchar(64) NOT NULL,
  `client_secret` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `oauthtoken`
--
CREATE TABLE `oauthtoken` (
  `token` varchar(128) NOT NULL,
  `related_token` varchar(128) NOT NULL,
  `oauthclient_id` integer NOT NULL,
  `user_id` bigint NOT NULL,
  `type` varchar(12) NOT NULL,
  `expires` integer NULL,
  INDEX `oauthtoken_idx_oauthclient_id` (`oauthclient_id`),
  INDEX `oauthtoken_idx_user_id` (`user_id`),
  PRIMARY KEY (`token`),
  CONSTRAINT `oauthtoken_fk_oauthclient_id` FOREIGN KEY (`oauthclient_id`) REFERENCES `oauthclient` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `oauthtoken_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `organisation`
--
CREATE TABLE `organisation` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `site_id` integer NULL,
  `deleted` smallint NOT NULL DEFAULT 0,
  INDEX `organisation_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `organisation_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `permission`
--
CREATE TABLE `permission` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NOT NULL,
  `description` text NULL,
  `order` integer NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `person`
--
CREATE TABLE `person` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` bigint NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `person_idx_layout_id` (`layout_id`),
  INDEX `person_idx_purged_by` (`purged_by`),
  INDEX `person_idx_record_id` (`record_id`),
  INDEX `person_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `person_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `person_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `person_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `person_fk_value` FOREIGN KEY (`value`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `rag`
--
CREATE TABLE `rag` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NOT NULL,
  `red` text NULL,
  `amber` text NULL,
  `green` text NULL,
  `code` mediumtext NULL,
  INDEX `rag_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `rag_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `ragval`
--
CREATE TABLE `ragval` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `value` varchar(16) NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `ragval_idx_layout_id` (`layout_id`),
  INDEX `ragval_idx_purged_by` (`purged_by`),
  INDEX `ragval_idx_record_id` (`record_id`),
  INDEX `ragval_idx_value` (`value`),
  PRIMARY KEY (`id`),
  UNIQUE `ragval_ux_record_layout` (`record_id`, `layout_id`),
  CONSTRAINT `ragval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `ragval_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `ragval_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `record`
--
CREATE TABLE `record` (
  `id` bigint NOT NULL auto_increment,
  `created` datetime NOT NULL,
  `current_id` bigint NOT NULL DEFAULT 0,
  `createdby` bigint NULL,
  `approvedby` bigint NULL,
  `record_id` bigint NULL,
  `approval` smallint NOT NULL DEFAULT 0,
  INDEX `record_idx_approvedby` (`approvedby`),
  INDEX `record_idx_createdby` (`createdby`),
  INDEX `record_idx_current_id` (`current_id`),
  INDEX `record_idx_record_id` (`record_id`),
  INDEX `record_idx_approval` (`approval`),
  PRIMARY KEY (`id`),
  CONSTRAINT `record_fk_approvedby` FOREIGN KEY (`approvedby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `record_fk_createdby` FOREIGN KEY (`createdby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `record_fk_current_id` FOREIGN KEY (`current_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `record_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `report`
--
CREATE TABLE `report` (
  `id` bigint NOT NULL auto_increment,
  `name` text NOT NULL,
  `title` text NULL,
  `description` text NULL,
  `user_id` bigint NULL,
  `createdby` bigint NULL,
  `created` datetime NULL,
  `instance_id` bigint NULL,
  `deleted` datetime NULL,
  `security_marking` text NULL,
  INDEX `report_idx_createdby` (`createdby`),
  INDEX `report_idx_instance_id` (`instance_id`),
  INDEX `report_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `report_fk_createdby` FOREIGN KEY (`createdby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `report_group`
--
CREATE TABLE `report_group` (
  `id` integer NOT NULL auto_increment,
  `report_id` integer NOT NULL,
  `group_id` integer NOT NULL,
  INDEX `report_group_idx_group_id` (`group_id`),
  INDEX `report_group_idx_report_id` (`report_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `report_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_group_fk_report_id` FOREIGN KEY (`report_id`) REFERENCES `report` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `report_layout`
--
CREATE TABLE `report_layout` (
  `id` integer NOT NULL auto_increment,
  `report_id` integer NOT NULL,
  `layout_id` bigint NOT NULL,
  `order` integer NULL,
  INDEX `report_layout_idx_layout_id` (`layout_id`),
  INDEX `report_layout_idx_report_id` (`report_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `report_layout_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `report_layout_fk_report_id` FOREIGN KEY (`report_id`) REFERENCES `report` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `site`
--
CREATE TABLE `site` (
  `id` integer NOT NULL auto_increment,
  `host` varchar(128) NULL,
  `name` text NULL,
  `created` datetime NULL,
  `email_welcome_text` text NULL,
  `email_welcome_subject` text NULL,
  `email_delete_text` text NULL,
  `email_delete_subject` text NULL,
  `email_reject_text` text NULL,
  `email_reject_subject` text NULL,
  `register_text` text NULL,
  `homepage_text` text NULL,
  `homepage_text2` text NULL,
  `register_title_help` text NULL,
  `register_freetext1_help` text NULL,
  `register_freetext2_help` text NULL,
  `register_email_help` text NULL,
  `register_organisation_help` text NULL,
  `register_organisation_name` text NULL,
  `register_organisation_mandatory` smallint NOT NULL DEFAULT 0,
  `register_department_help` text NULL,
  `register_department_name` text NULL,
  `register_department_mandatory` smallint NOT NULL DEFAULT 0,
  `register_team_help` text NULL,
  `register_team_name` text NULL,
  `register_team_mandatory` smallint NOT NULL DEFAULT 0,
  `register_notes_help` text NULL,
  `register_freetext1_name` text NULL,
  `register_freetext2_name` text NULL,
  `register_show_organisation` smallint NOT NULL DEFAULT 1,
  `register_show_department` smallint NOT NULL DEFAULT 0,
  `register_show_team` smallint NOT NULL DEFAULT 0,
  `register_show_title` smallint NOT NULL DEFAULT 1,
  `register_show_provider` smallint NOT NULL DEFAULT 0,
  `hide_account_request` smallint NOT NULL DEFAULT 0,
  `remember_user_location` smallint NOT NULL DEFAULT 1,
  `user_editable_fields` text NULL,
  `register_freetext1_placeholder` text NULL,
  `register_freetext2_placeholder` text NULL,
  `account_request_notes_name` text NULL,
  `account_request_notes_placeholder` text NULL,
  `security_marking` text NULL,
  `site_logo` longblob NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `sort`
--
CREATE TABLE `sort` (
  `id` integer NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `layout_id` integer NULL,
  `parent_id` integer NULL,
  `type` varchar(45) NULL,
  `order` integer NULL,
  INDEX `sort_idx_layout_id` (`layout_id`),
  INDEX `sort_idx_parent_id` (`parent_id`),
  INDEX `sort_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `sort_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sort_fk_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sort_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `string`
--
CREATE TABLE `string` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `child_unique` smallint NOT NULL DEFAULT 0,
  `value` text NULL,
  `value_index` varchar(128) NULL,
  `purged_by` bigint NULL,
  `purged_on` datetime NULL,
  INDEX `string_idx_layout_id` (`layout_id`),
  INDEX `string_idx_purged_by` (`purged_by`),
  INDEX `string_idx_record_id` (`record_id`),
  INDEX `string_idx_value_index` (`value_index`),
  PRIMARY KEY (`id`),
  CONSTRAINT `string_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `string_fk_purged_by` FOREIGN KEY (`purged_by`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `string_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `submission`
--
CREATE TABLE `submission` (
  `id` integer NOT NULL auto_increment,
  `token` varchar(64) NOT NULL,
  `created` datetime NULL,
  `submitted` smallint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE `ux_submission_token` (`token`, `submitted`)
) ENGINE=InnoDB;
--
-- Table: `team`
--
CREATE TABLE `team` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `site_id` integer NULL,
  `deleted` smallint NOT NULL DEFAULT 0,
  INDEX `team_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `team_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `title`
--
CREATE TABLE `title` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  `site_id` integer NULL,
  `deleted` smallint NOT NULL DEFAULT 0,
  INDEX `title_idx_site_id` (`site_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `title_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `topic`
--
CREATE TABLE `topic` (
  `id` integer NOT NULL auto_increment,
  `instance_id` integer NULL,
  `name` text NULL,
  `description` text NULL,
  `initial_state` varchar(32) NULL,
  `click_to_edit` smallint NOT NULL DEFAULT 0,
  `prevent_edit_topic_id` integer NULL,
  INDEX `topic_idx_instance_id` (`instance_id`),
  INDEX `topic_idx_prevent_edit_topic_id` (`prevent_edit_topic_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `topic_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `topic_fk_prevent_edit_topic_id` FOREIGN KEY (`prevent_edit_topic_id`) REFERENCES `topic` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `user`
--
CREATE TABLE `user` (
  `id` bigint NOT NULL auto_increment,
  `site_id` integer NULL,
  `firstname` varchar(128) NULL,
  `surname` varchar(128) NULL,
  `email` text NULL,
  `username` text NULL,
  `title` integer NULL,
  `organisation` integer NULL,
  `department_id` integer NULL,
  `team_id` integer NULL,
  `freetext1` text NULL,
  `freetext2` text NULL,
  `password` varchar(128) NULL,
  `pwchanged` datetime NULL,
  `resetpw` varchar(32) NULL,
  `deleted` datetime NULL,
  `lastlogin` datetime NULL,
  `lastfail` datetime NULL,
  `failcount` integer NOT NULL DEFAULT 0,
  `lastrecord` bigint NULL,
  `lastview` bigint NULL,
  `session_settings` text NULL,
  `value` text NULL,
  `account_request` smallint NULL DEFAULT 0,
  `account_request_notes` text NULL,
  `aup_accepted` datetime NULL,
  `limit_to_view` bigint NULL,
  `stylesheet` text NULL,
  `created` datetime NULL,
  `debug_login` smallint NULL DEFAULT 0,
  `provider` integer NULL,
  INDEX `user_idx_department_id` (`department_id`),
  INDEX `user_idx_lastrecord` (`lastrecord`),
  INDEX `user_idx_lastview` (`lastview`),
  INDEX `user_idx_limit_to_view` (`limit_to_view`),
  INDEX `user_idx_organisation` (`organisation`),
  INDEX `user_idx_provider` (`provider`),
  INDEX `user_idx_site_id` (`site_id`),
  INDEX `user_idx_team_id` (`team_id`),
  INDEX `user_idx_title` (`title`),
  INDEX `user_idx_value` (`value`(64)),
  INDEX `user_idx_email` (`email`(64)),
  INDEX `user_idx_username` (`username`(64)),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_fk_department_id` FOREIGN KEY (`department_id`) REFERENCES `department` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_lastrecord` FOREIGN KEY (`lastrecord`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_lastview` FOREIGN KEY (`lastview`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_limit_to_view` FOREIGN KEY (`limit_to_view`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_organisation` FOREIGN KEY (`organisation`) REFERENCES `organisation` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_provider` FOREIGN KEY (`provider`) REFERENCES `authentication` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_team_id` FOREIGN KEY (`team_id`) REFERENCES `team` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_title` FOREIGN KEY (`title`) REFERENCES `title` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `user_graph`
--
CREATE TABLE `user_graph` (
  `id` bigint NOT NULL auto_increment,
  `user_id` bigint NOT NULL,
  `graph_id` integer NOT NULL,
  INDEX `user_graph_idx_graph_id` (`graph_id`),
  INDEX `user_graph_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_graph_fk_graph_id` FOREIGN KEY (`graph_id`) REFERENCES `graph` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_graph_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `user_group`
--
CREATE TABLE `user_group` (
  `id` bigint NOT NULL auto_increment,
  `user_id` bigint NOT NULL,
  `group_id` integer NOT NULL,
  INDEX `user_group_idx_group_id` (`group_id`),
  INDEX `user_group_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_group_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `user_lastrecord`
--
CREATE TABLE `user_lastrecord` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `instance_id` integer NOT NULL,
  `user_id` bigint NOT NULL,
  INDEX `user_lastrecord_idx_instance_id` (`instance_id`),
  INDEX `user_lastrecord_idx_record_id` (`record_id`),
  INDEX `user_lastrecord_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_lastrecord_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_lastrecord_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_lastrecord_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `user_permission`
--
CREATE TABLE `user_permission` (
  `id` bigint NOT NULL auto_increment,
  `user_id` bigint NOT NULL,
  `permission_id` integer NOT NULL,
  INDEX `user_permission_idx_permission_id` (`permission_id`),
  INDEX `user_permission_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_permission_fk_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_permission_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `view`
--
CREATE TABLE `view` (
  `id` bigint NOT NULL auto_increment,
  `user_id` bigint NULL,
  `group_id` integer NULL,
  `name` varchar(128) NULL,
  `global` smallint NOT NULL DEFAULT 0,
  `is_admin` smallint NOT NULL DEFAULT 0,
  `is_limit_extra` smallint NOT NULL DEFAULT 0,
  `filter` text NULL,
  `instance_id` integer NULL,
  `created` datetime NULL,
  `createdby` bigint NULL,
  INDEX `view_idx_createdby` (`createdby`),
  INDEX `view_idx_group_id` (`group_id`),
  INDEX `view_idx_instance_id` (`instance_id`),
  INDEX `view_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `view_fk_createdby` FOREIGN KEY (`createdby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `view_group`
--
CREATE TABLE `view_group` (
  `id` integer NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `layout_id` integer NULL,
  `parent_id` integer NULL,
  `order` integer NULL,
  INDEX `view_group_idx_layout_id` (`layout_id`),
  INDEX `view_group_idx_parent_id` (`parent_id`),
  INDEX `view_group_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `view_group_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_group_fk_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_group_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `view_layout`
--
CREATE TABLE `view_layout` (
  `id` integer NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `order` integer NULL,
  INDEX `view_layout_idx_layout_id` (`layout_id`),
  INDEX `view_layout_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `view_layout_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_layout_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `view_limit`
--
CREATE TABLE `view_limit` (
  `id` bigint NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  INDEX `view_limit_idx_user_id` (`user_id`),
  INDEX `view_limit_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `view_limit_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_limit_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `widget`
--
CREATE TABLE `widget` (
  `id` integer NOT NULL auto_increment,
  `grid_id` varchar(64) NULL,
  `dashboard_id` integer NULL,
  `type` varchar(16) NULL,
  `title` text NULL,
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
SET foreign_key_checks=1;
