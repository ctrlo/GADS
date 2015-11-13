-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Fri Nov 13 16:26:27 2015
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
  INDEX `alert_cache_idx_current_id` (`current_id`),
  INDEX `alert_cache_idx_layout_id` (`layout_id`),
  INDEX `alert_cache_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `alert_cache_fk_current_id` FOREIGN KEY (`current_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_cache_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `alert_cache_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
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
  `user_id` bigint NULL,
  `type` varchar(45) NULL,
  `datetime` datetime NULL,
  `method` varchar(45) NULL,
  `url` text NULL,
  `description` text NULL,
  INDEX `audit_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `audit_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `calc`
--
CREATE TABLE `calc` (
  `id` integer NOT NULL auto_increment,
  `layout_id` integer NULL,
  `calc` mediumtext NULL,
  `return_format` varchar(45) NULL,
  INDEX `calc_idx_layout_id` (`layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `calc_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `calcval`
--
CREATE TABLE `calcval` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `value` text NULL,
  `value_text` text NULL,
  `value_int` bigint NULL,
  `value_date` date NULL,
  INDEX `calcval_idx_layout_id` (`layout_id`),
  INDEX `calcval_idx_record_id` (`record_id`),
  INDEX `calcval_idx_value` (`value`(64)),
  PRIMARY KEY (`id`),
  UNIQUE `calcval_ux_record_layout` (`record_id`, `layout_id`),
  CONSTRAINT `calcval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `calcval_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `current`
--
CREATE TABLE `current` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `parent_id` bigint NULL,
  `instance_id` integer NULL,
  `linked_id` bigint NULL,
  INDEX `current_idx_instance_id` (`instance_id`),
  INDEX `current_idx_linked_id` (`linked_id`),
  INDEX `current_idx_parent_id` (`parent_id`),
  INDEX `current_idx_record_id` (`record_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `current_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `current_fk_linked_id` FOREIGN KEY (`linked_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `current_fk_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `current_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `curval`
--
CREATE TABLE `curval` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `value` bigint NULL,
  INDEX `curval_idx_layout_id` (`layout_id`),
  INDEX `curval_idx_record_id` (`record_id`),
  INDEX `curval_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `curval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
-- Table: `date`
--
CREATE TABLE `date` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `value` date NULL,
  INDEX `date_idx_layout_id` (`layout_id`),
  INDEX `date_idx_record_id` (`record_id`),
  INDEX `date_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `date_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
  `value` varchar(45) NULL,
  INDEX `daterange_idx_layout_id` (`layout_id`),
  INDEX `daterange_idx_record_id` (`record_id`),
  INDEX `daterange_idx_from` (`from`),
  INDEX `daterange_idx_to` (`to`),
  INDEX `daterange_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `daterange_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `daterange_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `enum`
--
CREATE TABLE `enum` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `value` integer NULL,
  INDEX `enum_idx_layout_id` (`layout_id`),
  INDEX `enum_idx_record_id` (`record_id`),
  INDEX `enum_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `enum_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
  INDEX `enumval_idx_layout_id` (`layout_id`),
  INDEX `enumval_idx_parent` (`parent`),
  INDEX `enumval_idx_value` (`value`(64)),
  PRIMARY KEY (`id`),
  CONSTRAINT `enumval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `enumval_fk_parent` FOREIGN KEY (`parent`) REFERENCES `enumval` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `file`
--
CREATE TABLE `file` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NULL,
  `layout_id` integer NULL,
  `value` bigint NULL,
  INDEX `file_idx_layout_id` (`layout_id`),
  INDEX `file_idx_record_id` (`record_id`),
  INDEX `file_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `file_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
  `content` longblob NULL,
  INDEX `fileval_idx_name` (`name`(64)),
  PRIMARY KEY (`id`)
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
  `x_axis_grouping` varchar(45) NULL,
  `group_by` integer NULL,
  `stackseries` smallint NOT NULL DEFAULT 0,
  `type` varchar(45) NULL,
  `metric_group` integer NULL,
  `instance_id` integer NULL,
  INDEX `graph_idx_group_by` (`group_by`),
  INDEX `graph_idx_instance_id` (`instance_id`),
  INDEX `graph_idx_metric_group` (`metric_group`),
  INDEX `graph_idx_x_axis` (`x_axis`),
  INDEX `graph_idx_y_axis` (`y_axis`),
  PRIMARY KEY (`id`),
  CONSTRAINT `graph_fk_group_by` FOREIGN KEY (`group_by`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_metric_group` FOREIGN KEY (`metric_group`) REFERENCES `metric_group` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `graph_fk_x_axis` FOREIGN KEY (`x_axis`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `instance`
--
CREATE TABLE `instance` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `email_welcome_text` text NULL,
  `email_welcome_subject` text NULL,
  `email_delete_text` text NULL,
  `email_delete_subject` text NULL,
  `email_reject_text` text NULL,
  `email_reject_subject` text NULL,
  `register_text` text NULL,
  `sort_layout_id` integer NULL,
  `sort_type` varchar(45) NULL,
  `homepage_text` text NULL,
  `homepage_text2` text NULL,
  `register_title_help` text NULL,
  `register_telephone_help` text NULL,
  `register_email_help` text NULL,
  `register_organisation_help` text NULL,
  `register_notes_help` text NULL,
  INDEX `instance_idx_sort_layout_id` (`sort_layout_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `instance_fk_sort_layout_id` FOREIGN KEY (`sort_layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `intgr`
--
CREATE TABLE `intgr` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `value` bigint NULL,
  INDEX `intgr_idx_layout_id` (`layout_id`),
  INDEX `intgr_idx_record_id` (`record_id`),
  INDEX `intgr_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `intgr_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `intgr_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `layout`
--
CREATE TABLE `layout` (
  `id` integer NOT NULL auto_increment,
  `name` text NULL,
  `type` varchar(45) NULL,
  `permission` integer NOT NULL DEFAULT 0,
  `optional` smallint NOT NULL DEFAULT 0,
  `remember` smallint NOT NULL DEFAULT 0,
  `position` integer NULL,
  `ordering` varchar(45) NULL,
  `end_node_only` smallint NOT NULL DEFAULT 0,
  `description` text NULL,
  `helptext` text NULL,
  `display_field` integer NULL,
  `display_regex` text NULL,
  `instance_id` integer NULL,
  `link_parent` integer NULL,
  INDEX `layout_idx_display_field` (`display_field`),
  INDEX `layout_idx_instance_id` (`instance_id`),
  INDEX `layout_idx_link_parent` (`link_parent`),
  PRIMARY KEY (`id`),
  CONSTRAINT `layout_fk_display_field` FOREIGN KEY (`display_field`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `layout_fk_link_parent` FOREIGN KEY (`link_parent`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
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
-- Table: `organisation`
--
CREATE TABLE `organisation` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
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
  `value` bigint NULL,
  INDEX `person_idx_layout_id` (`layout_id`),
  INDEX `person_idx_record_id` (`record_id`),
  INDEX `person_idx_value` (`value`),
  PRIMARY KEY (`id`),
  CONSTRAINT `person_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
  INDEX `ragval_idx_layout_id` (`layout_id`),
  INDEX `ragval_idx_record_id` (`record_id`),
  INDEX `ragval_idx_value` (`value`),
  PRIMARY KEY (`id`),
  UNIQUE `ragval_ux_record_layout` (`record_id`, `layout_id`),
  CONSTRAINT `ragval_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
  PRIMARY KEY (`id`),
  CONSTRAINT `record_fk_approvedby` FOREIGN KEY (`approvedby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `record_fk_createdby` FOREIGN KEY (`createdby`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `record_fk_current_id` FOREIGN KEY (`current_id`) REFERENCES `current` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `record_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `sort`
--
CREATE TABLE `sort` (
  `id` integer NOT NULL auto_increment,
  `view_id` bigint NOT NULL,
  `layout_id` integer NULL,
  `type` varchar(45) NULL,
  INDEX `sort_idx_layout_id` (`layout_id`),
  INDEX `sort_idx_view_id` (`view_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `sort_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sort_fk_view_id` FOREIGN KEY (`view_id`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `string`
--
CREATE TABLE `string` (
  `id` bigint NOT NULL auto_increment,
  `record_id` bigint NOT NULL,
  `layout_id` integer NOT NULL,
  `value` text NULL,
  INDEX `string_idx_layout_id` (`layout_id`),
  INDEX `string_idx_record_id` (`record_id`),
  INDEX `string_idx_value` (`value`(64)),
  PRIMARY KEY (`id`),
  CONSTRAINT `string_fk_layout_id` FOREIGN KEY (`layout_id`) REFERENCES `layout` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `string_fk_record_id` FOREIGN KEY (`record_id`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;
--
-- Table: `title`
--
CREATE TABLE `title` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(128) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `user`
--
CREATE TABLE `user` (
  `id` bigint NOT NULL auto_increment,
  `firstname` varchar(128) NULL,
  `surname` varchar(128) NULL,
  `email` text NULL,
  `username` text NULL,
  `title` integer NULL,
  `organisation` integer NULL,
  `telephone` varchar(128) NULL,
  `password` varchar(128) NULL,
  `pwchanged` datetime NULL,
  `resetpw` varchar(32) NULL,
  `deleted` datetime NULL,
  `lastlogin` datetime NULL,
  `lastrecord` bigint NULL,
  `lastview` bigint NULL,
  `value` text NULL,
  `account_request` smallint NULL DEFAULT 0,
  `account_request_notes` text NULL,
  `aup_accepted` datetime NULL,
  `limit_to_view` bigint NULL,
  `stylesheet` text NULL,
  INDEX `user_idx_lastrecord` (`lastrecord`),
  INDEX `user_idx_lastview` (`lastview`),
  INDEX `user_idx_limit_to_view` (`limit_to_view`),
  INDEX `user_idx_organisation` (`organisation`),
  INDEX `user_idx_title` (`title`),
  INDEX `user_idx_value` (`value`(64)),
  INDEX `user_idx_email` (`email`(64)),
  INDEX `user_idx_username` (`username`(64)),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_fk_lastrecord` FOREIGN KEY (`lastrecord`) REFERENCES `record` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_lastview` FOREIGN KEY (`lastview`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_limit_to_view` FOREIGN KEY (`limit_to_view`) REFERENCES `view` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `user_fk_organisation` FOREIGN KEY (`organisation`) REFERENCES `organisation` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
  `name` varchar(128) NULL,
  `global` smallint NOT NULL DEFAULT 0,
  `filter` text NULL,
  `instance_id` integer NULL,
  INDEX `view_idx_instance_id` (`instance_id`),
  INDEX `view_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `view_fk_instance_id` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `view_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
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
SET foreign_key_checks=1;
