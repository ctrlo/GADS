--
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Jul 22 11:31:16 2024
--
;
--
-- Table: alert
--
CREATE TABLE "alert" (
  "id" serial NOT NULL,
  "view_id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  "frequency" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "alert_idx_user_id" on "alert" ("user_id");
CREATE INDEX "alert_idx_view_id" on "alert" ("view_id");

;
--
-- Table: alert_cache
--
CREATE TABLE "alert_cache" (
  "id" bigserial NOT NULL,
  "layout_id" integer NOT NULL,
  "view_id" bigint NOT NULL,
  "current_id" bigint NOT NULL,
  "user_id" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "alert_cache_idx_current_id" on "alert_cache" ("current_id");
CREATE INDEX "alert_cache_idx_layout_id" on "alert_cache" ("layout_id");
CREATE INDEX "alert_cache_idx_user_id" on "alert_cache" ("user_id");
CREATE INDEX "alert_cache_idx_view_id" on "alert_cache" ("view_id");

;
--
-- Table: alert_column
--
CREATE TABLE "alert_column" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "instance_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "alert_column_idx_instance_id" on "alert_column" ("instance_id");
CREATE INDEX "alert_column_idx_layout_id" on "alert_column" ("layout_id");

;
--
-- Table: alert_send
--
CREATE TABLE "alert_send" (
  "id" bigserial NOT NULL,
  "layout_id" integer,
  "alert_id" integer NOT NULL,
  "current_id" bigint NOT NULL,
  "status" character(7),
  PRIMARY KEY ("id"),
  CONSTRAINT "alert_send_all" UNIQUE ("layout_id", "alert_id", "current_id", "status")
);
CREATE INDEX "alert_send_idx_alert_id" on "alert_send" ("alert_id");
CREATE INDEX "alert_send_idx_current_id" on "alert_send" ("current_id");
CREATE INDEX "alert_send_idx_layout_id" on "alert_send" ("layout_id");

;
--
-- Table: audit
--
CREATE TABLE "audit" (
  "id" bigserial NOT NULL,
  "site_id" integer,
  "user_id" bigint,
  "type" character varying(45),
  "datetime" timestamp,
  "method" character varying(45),
  "url" text,
  "description" text,
  "instance_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "audit_idx_instance_id" on "audit" ("instance_id");
CREATE INDEX "audit_idx_site_id" on "audit" ("site_id");
CREATE INDEX "audit_idx_user_id" on "audit" ("user_id");
CREATE INDEX "audit_idx_datetime" on "audit" ("datetime");
CREATE INDEX "audit_idx_user_instance_datetime" on "audit" ("user_id", "instance_id", "datetime");

;
--
-- Table: authentication
--
CREATE TABLE "authentication" (
  "id" bigserial NOT NULL,
  "site_id" integer,
  "type" character varying(32),
  "name" text,
  "xml" text,
  "saml2_firstname" text,
  "saml2_surname" text,
  "enabled" smallint DEFAULT 0 NOT NULL,
  "error_messages" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "authentication_idx_site_id" on "authentication" ("site_id");

;
--
-- Table: calc
--
CREATE TABLE "calc" (
  "id" serial NOT NULL,
  "layout_id" integer,
  "calc" text,
  "code" text,
  "return_format" character varying(45),
  "decimal_places" smallint,
  PRIMARY KEY ("id")
);
CREATE INDEX "calc_idx_layout_id" on "calc" ("layout_id");

;
--
-- Table: calc_unique
--
CREATE TABLE "calc_unique" (
  "id" bigserial NOT NULL,
  "layout_id" integer NOT NULL,
  "value_text" citext,
  "value_int" bigint,
  "value_date" date,
  "value_numeric" numeric(20,5),
  "value_date_from" timestamp,
  "value_date_to" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "calc_unique_ux_layout_date" UNIQUE ("layout_id", "value_date"),
  CONSTRAINT "calc_unique_ux_layout_daterange" UNIQUE ("layout_id", "value_date_from", "value_date_to"),
  CONSTRAINT "calc_unique_ux_layout_int" UNIQUE ("layout_id", "value_int"),
  CONSTRAINT "calc_unique_ux_layout_numeric" UNIQUE ("layout_id", "value_numeric"),
  CONSTRAINT "calc_unique_ux_layout_text" UNIQUE ("layout_id", "value_text")
);
CREATE INDEX "calc_unique_idx_layout_id" on "calc_unique" ("layout_id");

;
--
-- Table: calcval
--
CREATE TABLE "calcval" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "value_text" citext,
  "value_int" bigint,
  "value_date" date,
  "value_numeric" numeric(20,5),
  "value_date_from" timestamp,
  "value_date_to" timestamp,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "calcval_idx_layout_id" on "calcval" ("layout_id");
CREATE INDEX "calcval_idx_purged_by" on "calcval" ("purged_by");
CREATE INDEX "calcval_idx_record_id" on "calcval" ("record_id");
CREATE INDEX "calcval_idx_value_text" on "calcval" ("value_text");
CREATE INDEX "calcval_idx_value_numeric" on "calcval" ("value_numeric");
CREATE INDEX "calcval_idx_value_int" on "calcval" ("value_int");
CREATE INDEX "calcval_idx_value_date" on "calcval" ("value_date");

;
--
-- Table: current
--
CREATE TABLE "current" (
  "id" bigserial NOT NULL,
  "serial" bigint,
  "parent_id" bigint,
  "instance_id" integer,
  "linked_id" bigint,
  "deleted" timestamp,
  "deletedby" bigint,
  "draftuser_id" bigint,
  PRIMARY KEY ("id"),
  CONSTRAINT "current_ux_instance_serial" UNIQUE ("instance_id", "serial")
);
CREATE INDEX "current_idx_deletedby" on "current" ("deletedby");
CREATE INDEX "current_idx_draftuser_id" on "current" ("draftuser_id");
CREATE INDEX "current_idx_instance_id" on "current" ("instance_id");
CREATE INDEX "current_idx_linked_id" on "current" ("linked_id");
CREATE INDEX "current_idx_parent_id" on "current" ("parent_id");

;
--
-- Table: curval
--
CREATE TABLE "curval" (
  "id" bigserial NOT NULL,
  "record_id" bigint,
  "layout_id" integer,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" bigint,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "curval_idx_layout_id" on "curval" ("layout_id");
CREATE INDEX "curval_idx_purged_by" on "curval" ("purged_by");
CREATE INDEX "curval_idx_record_id" on "curval" ("record_id");
CREATE INDEX "curval_idx_value" on "curval" ("value");

;
--
-- Table: curval_fields
--
CREATE TABLE "curval_fields" (
  "id" serial NOT NULL,
  "parent_id" integer NOT NULL,
  "child_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "curval_fields_idx_child_id" on "curval_fields" ("child_id");
CREATE INDEX "curval_fields_idx_parent_id" on "curval_fields" ("parent_id");

;
--
-- Table: dashboard
--
CREATE TABLE "dashboard" (
  "id" serial NOT NULL,
  "site_id" integer,
  "instance_id" integer,
  "user_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "dashboard_idx_instance_id" on "dashboard" ("instance_id");
CREATE INDEX "dashboard_idx_site_id" on "dashboard" ("site_id");
CREATE INDEX "dashboard_idx_user_id" on "dashboard" ("user_id");

;
--
-- Table: date
--
CREATE TABLE "date" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" date,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "date_idx_layout_id" on "date" ("layout_id");
CREATE INDEX "date_idx_purged_by" on "date" ("purged_by");
CREATE INDEX "date_idx_record_id" on "date" ("record_id");
CREATE INDEX "date_idx_value" on "date" ("value");

;
--
-- Table: daterange
--
CREATE TABLE "daterange" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "from" date,
  "to" date,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" citext,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "daterange_idx_layout_id" on "daterange" ("layout_id");
CREATE INDEX "daterange_idx_purged_by" on "daterange" ("purged_by");
CREATE INDEX "daterange_idx_record_id" on "daterange" ("record_id");
CREATE INDEX "daterange_idx_from" on "daterange" ("from");
CREATE INDEX "daterange_idx_to" on "daterange" ("to");
CREATE INDEX "daterange_idx_value" on "daterange" ("value");

;
--
-- Table: department
--
CREATE TABLE "department" (
  "id" serial NOT NULL,
  "name" citext,
  "site_id" integer,
  "deleted" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "department_idx_site_id" on "department" ("site_id");

;
--
-- Table: display_field
--
CREATE TABLE "display_field" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "display_field_id" integer NOT NULL,
  "regex" text,
  "operator" character varying(16),
  PRIMARY KEY ("id")
);
CREATE INDEX "display_field_idx_display_field_id" on "display_field" ("display_field_id");
CREATE INDEX "display_field_idx_layout_id" on "display_field" ("layout_id");

;
--
-- Table: enum
--
CREATE TABLE "enum" (
  "id" bigserial NOT NULL,
  "record_id" bigint,
  "layout_id" integer,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" integer,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "enum_idx_layout_id" on "enum" ("layout_id");
CREATE INDEX "enum_idx_purged_by" on "enum" ("purged_by");
CREATE INDEX "enum_idx_record_id" on "enum" ("record_id");
CREATE INDEX "enum_idx_value" on "enum" ("value");

;
--
-- Table: enumval
--
CREATE TABLE "enumval" (
  "id" serial NOT NULL,
  "value" citext,
  "layout_id" integer,
  "deleted" smallint DEFAULT 0 NOT NULL,
  "parent" integer,
  "position" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "enumval_idx_layout_id" on "enumval" ("layout_id");
CREATE INDEX "enumval_idx_parent" on "enumval" ("parent");
CREATE INDEX "enumval_idx_value" on "enumval" ("value");

;
--
-- Table: export
--
CREATE TABLE "export" (
  "id" serial NOT NULL,
  "site_id" integer,
  "user_id" bigint NOT NULL,
  "type" character varying(45),
  "started" timestamp,
  "completed" timestamp,
  "result" text,
  "result_internal" text,
  "mimetype" text,
  "content" bytea,
  PRIMARY KEY ("id")
);
CREATE INDEX "export_idx_site_id" on "export" ("site_id");
CREATE INDEX "export_idx_user_id" on "export" ("user_id");

;
--
-- Table: file
--
CREATE TABLE "file" (
  "id" bigserial NOT NULL,
  "record_id" bigint,
  "layout_id" integer,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" bigint,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "file_idx_layout_id" on "file" ("layout_id");
CREATE INDEX "file_idx_purged_by" on "file" ("purged_by");
CREATE INDEX "file_idx_record_id" on "file" ("record_id");
CREATE INDEX "file_idx_value" on "file" ("value");

;
--
-- Table: file_option
--
CREATE TABLE "file_option" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "filesize" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "file_option_idx_layout_id" on "file_option" ("layout_id");

;
--
-- Table: fileval
--
CREATE TABLE "fileval" (
  "id" bigserial NOT NULL,
  "name" text,
  "mimetype" text,
  "content" bytea,
  "is_independent" smallint DEFAULT 0 NOT NULL,
  "edit_user_id" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "fileval_idx_edit_user_id" on "fileval" ("edit_user_id");
CREATE INDEX "fileval_idx_name" on "fileval" ("name");

;
--
-- Table: filter
--
CREATE TABLE "filter" (
  "id" bigserial NOT NULL,
  "view_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "filter_idx_layout_id" on "filter" ("layout_id");
CREATE INDEX "filter_idx_view_id" on "filter" ("view_id");

;
--
-- Table: filtered_value
--
CREATE TABLE "filtered_value" (
  "id" serial NOT NULL,
  "submission_id" integer,
  "layout_id" integer,
  "current_id" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "ux_submission_layout_current" UNIQUE ("submission_id", "layout_id", "current_id")
);
CREATE INDEX "filtered_value_idx_current_id" on "filtered_value" ("current_id");
CREATE INDEX "filtered_value_idx_layout_id" on "filtered_value" ("layout_id");
CREATE INDEX "filtered_value_idx_submission_id" on "filtered_value" ("submission_id");

;
--
-- Table: graph
--
CREATE TABLE "graph" (
  "id" serial NOT NULL,
  "title" text,
  "description" text,
  "y_axis" integer,
  "y_axis_stack" character varying(45),
  "y_axis_label" text,
  "x_axis" integer,
  "x_axis_link" integer,
  "x_axis_grouping" character varying(45),
  "group_by" integer,
  "stackseries" smallint DEFAULT 0 NOT NULL,
  "as_percent" smallint DEFAULT 0 NOT NULL,
  "type" character varying(45),
  "metric_group" integer,
  "instance_id" integer,
  "is_shared" smallint DEFAULT 0 NOT NULL,
  "user_id" bigint,
  "group_id" integer,
  "trend" character varying(45),
  "from" date,
  "to" date,
  "x_axis_range" character varying(45),
  PRIMARY KEY ("id")
);
CREATE INDEX "graph_idx_group_id" on "graph" ("group_id");
CREATE INDEX "graph_idx_group_by" on "graph" ("group_by");
CREATE INDEX "graph_idx_instance_id" on "graph" ("instance_id");
CREATE INDEX "graph_idx_metric_group" on "graph" ("metric_group");
CREATE INDEX "graph_idx_user_id" on "graph" ("user_id");
CREATE INDEX "graph_idx_x_axis" on "graph" ("x_axis");
CREATE INDEX "graph_idx_x_axis_link" on "graph" ("x_axis_link");
CREATE INDEX "graph_idx_y_axis" on "graph" ("y_axis");

;
--
-- Table: graph_color
--
CREATE TABLE "graph_color" (
  "id" bigserial NOT NULL,
  "name" character varying(128),
  "color" character(6),
  PRIMARY KEY ("id"),
  CONSTRAINT "ux_graph_color_name" UNIQUE ("name")
);

;
--
-- Table: group
--
CREATE TABLE "group" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "default_read" smallint DEFAULT 0 NOT NULL,
  "default_write_new" smallint DEFAULT 0 NOT NULL,
  "default_write_existing" smallint DEFAULT 0 NOT NULL,
  "default_approve_new" smallint DEFAULT 0 NOT NULL,
  "default_approve_existing" smallint DEFAULT 0 NOT NULL,
  "default_write_new_no_approval" smallint DEFAULT 0 NOT NULL,
  "default_write_existing_no_approval" smallint DEFAULT 0 NOT NULL,
  "site_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "group_idx_site_id" on "group" ("site_id");

;
--
-- Table: import
--
CREATE TABLE "import" (
  "id" serial NOT NULL,
  "site_id" integer,
  "instance_id" integer,
  "user_id" bigint NOT NULL,
  "type" character varying(45),
  "row_count" integer DEFAULT 0 NOT NULL,
  "started" timestamp,
  "completed" timestamp,
  "written_count" integer DEFAULT 0 NOT NULL,
  "error_count" integer DEFAULT 0 NOT NULL,
  "skipped_count" integer DEFAULT 0 NOT NULL,
  "result" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "import_idx_instance_id" on "import" ("instance_id");
CREATE INDEX "import_idx_site_id" on "import" ("site_id");
CREATE INDEX "import_idx_user_id" on "import" ("user_id");

;
--
-- Table: import_row
--
CREATE TABLE "import_row" (
  "id" bigserial NOT NULL,
  "import_id" integer NOT NULL,
  "status" character varying(45),
  "content" text,
  "errors" text,
  "changes" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "import_row_idx_import_id" on "import_row" ("import_id");

;
--
-- Table: instance
--
CREATE TABLE "instance" (
  "id" serial NOT NULL,
  "name" text,
  "name_short" character varying(64),
  "site_id" integer,
  "sort_layout_id" integer,
  "sort_type" character varying(45),
  "view_limit_id" integer,
  "default_view_limit_extra_id" integer,
  "homepage_text" text,
  "homepage_text2" text,
  "record_name" text,
  "forget_history" smallint DEFAULT 0,
  "no_overnight_update" smallint DEFAULT 0,
  "api_index_layout_id" integer,
  "forward_record_after_create" smallint DEFAULT 0,
  "no_hide_blank" smallint DEFAULT 0 NOT NULL,
  "no_download_pdf" smallint DEFAULT 0 NOT NULL,
  "no_copy_record" smallint DEFAULT 0 NOT NULL,
  "hide_in_selector" smallint DEFAULT 0 NOT NULL,
  "security_marking" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "instance_idx_api_index_layout_id" on "instance" ("api_index_layout_id");
CREATE INDEX "instance_idx_default_view_limit_extra_id" on "instance" ("default_view_limit_extra_id");
CREATE INDEX "instance_idx_site_id" on "instance" ("site_id");
CREATE INDEX "instance_idx_sort_layout_id" on "instance" ("sort_layout_id");
CREATE INDEX "instance_idx_view_limit_id" on "instance" ("view_limit_id");

;
--
-- Table: instance_group
--
CREATE TABLE "instance_group" (
  "id" serial NOT NULL,
  "instance_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  "permission" character varying(45) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "instance_group_ux_instance_group_permission" UNIQUE ("instance_id", "group_id", "permission")
);
CREATE INDEX "instance_group_idx_group_id" on "instance_group" ("group_id");
CREATE INDEX "instance_group_idx_instance_id" on "instance_group" ("instance_id");

;
--
-- Table: instance_rag
--
CREATE TABLE "instance_rag" (
  "id" serial NOT NULL,
  "instance_id" integer NOT NULL,
  "rag" character varying(16) NOT NULL,
  "enabled" smallint DEFAULT 0 NOT NULL,
  "description" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "instance_rag_ux_instance_rag" UNIQUE ("instance_id", "rag")
);
CREATE INDEX "instance_rag_idx_instance_id" on "instance_rag" ("instance_id");

;
--
-- Table: intgr
--
CREATE TABLE "intgr" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" bigint,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "intgr_idx_layout_id" on "intgr" ("layout_id");
CREATE INDEX "intgr_idx_purged_by" on "intgr" ("purged_by");
CREATE INDEX "intgr_idx_record_id" on "intgr" ("record_id");
CREATE INDEX "intgr_idx_value" on "intgr" ("value");

;
--
-- Table: layout
--
CREATE TABLE "layout" (
  "id" serial NOT NULL,
  "name" text,
  "name_short" character varying(64),
  "type" character varying(45),
  "permission" integer DEFAULT 0 NOT NULL,
  "optional" smallint DEFAULT 0 NOT NULL,
  "remember" smallint DEFAULT 0 NOT NULL,
  "isunique" smallint DEFAULT 0 NOT NULL,
  "textbox" smallint DEFAULT 0 NOT NULL,
  "typeahead" smallint DEFAULT 0 NOT NULL,
  "force_regex" text,
  "position" integer,
  "ordering" character varying(45),
  "end_node_only" smallint DEFAULT 0 NOT NULL,
  "multivalue" smallint DEFAULT 0 NOT NULL,
  "can_child" smallint DEFAULT 0 NOT NULL,
  "internal" smallint DEFAULT 0 NOT NULL,
  "description" text,
  "helptext" text,
  "options" text,
  "display_field" integer,
  "display_regex" text,
  "display_condition" character(3),
  "display_matchtype" text,
  "instance_id" integer,
  "link_parent" integer,
  "related_field" integer,
  "width" integer DEFAULT 50 NOT NULL,
  "filter" text,
  "topic_id" integer,
  "aggregate" character varying(45),
  "group_display" character varying(45),
  "lookup_endpoint" text,
  "lookup_group" smallint,
  "notes" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "layout_ux_instance_name_short" UNIQUE ("instance_id", "name_short")
);
CREATE INDEX "layout_idx_display_field" on "layout" ("display_field");
CREATE INDEX "layout_idx_instance_id" on "layout" ("instance_id");
CREATE INDEX "layout_idx_link_parent" on "layout" ("link_parent");
CREATE INDEX "layout_idx_related_field" on "layout" ("related_field");
CREATE INDEX "layout_idx_topic_id" on "layout" ("topic_id");

;
--
-- Table: layout_depend
--
CREATE TABLE "layout_depend" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "depends_on" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "layout_depend_idx_depends_on" on "layout_depend" ("depends_on");
CREATE INDEX "layout_depend_idx_layout_id" on "layout_depend" ("layout_id");

;
--
-- Table: layout_group
--
CREATE TABLE "layout_group" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  "permission" character varying(45) NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "layout_group_ux_layout_group_permission" UNIQUE ("layout_id", "group_id", "permission")
);
CREATE INDEX "layout_group_idx_group_id" on "layout_group" ("group_id");
CREATE INDEX "layout_group_idx_layout_id" on "layout_group" ("layout_id");
CREATE INDEX "layout_group_idx_permission" on "layout_group" ("permission");

;
--
-- Table: metric
--
CREATE TABLE "metric" (
  "id" serial NOT NULL,
  "metric_group" integer NOT NULL,
  "x_axis_value" text,
  "target" bigint,
  "y_axis_grouping_value" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "metric_idx_metric_group" on "metric" ("metric_group");

;
--
-- Table: metric_group
--
CREATE TABLE "metric_group" (
  "id" serial NOT NULL,
  "name" text,
  "instance_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "metric_group_idx_instance_id" on "metric_group" ("instance_id");

;
--
-- Table: oauthclient
--
CREATE TABLE "oauthclient" (
  "id" bigserial NOT NULL,
  "client_id" character varying(64) NOT NULL,
  "client_secret" character varying(64) NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: oauthtoken
--
CREATE TABLE "oauthtoken" (
  "token" character varying(128) NOT NULL,
  "related_token" character varying(128) NOT NULL,
  "oauthclient_id" integer NOT NULL,
  "user_id" bigint NOT NULL,
  "type" character varying(12) NOT NULL,
  "expires" integer,
  PRIMARY KEY ("token")
);
CREATE INDEX "oauthtoken_idx_oauthclient_id" on "oauthtoken" ("oauthclient_id");
CREATE INDEX "oauthtoken_idx_user_id" on "oauthtoken" ("user_id");

;
--
-- Table: organisation
--
CREATE TABLE "organisation" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "site_id" integer,
  "deleted" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "organisation_idx_site_id" on "organisation" ("site_id");

;
--
-- Table: permission
--
CREATE TABLE "permission" (
  "id" serial NOT NULL,
  "name" character varying(128) NOT NULL,
  "description" text,
  "order" integer,
  PRIMARY KEY ("id")
);

;
--
-- Table: person
--
CREATE TABLE "person" (
  "id" bigserial NOT NULL,
  "record_id" bigint,
  "layout_id" integer,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" bigint,
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "person_idx_layout_id" on "person" ("layout_id");
CREATE INDEX "person_idx_purged_by" on "person" ("purged_by");
CREATE INDEX "person_idx_record_id" on "person" ("record_id");
CREATE INDEX "person_idx_value" on "person" ("value");

;
--
-- Table: rag
--
CREATE TABLE "rag" (
  "id" serial NOT NULL,
  "layout_id" integer NOT NULL,
  "red" text,
  "amber" text,
  "green" text,
  "code" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "rag_idx_layout_id" on "rag" ("layout_id");

;
--
-- Table: ragval
--
CREATE TABLE "ragval" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "value" character varying(16),
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id"),
  CONSTRAINT "ragval_ux_record_layout" UNIQUE ("record_id", "layout_id")
);
CREATE INDEX "ragval_idx_layout_id" on "ragval" ("layout_id");
CREATE INDEX "ragval_idx_purged_by" on "ragval" ("purged_by");
CREATE INDEX "ragval_idx_record_id" on "ragval" ("record_id");
CREATE INDEX "ragval_idx_value" on "ragval" ("value");

;
--
-- Table: record
--
CREATE TABLE "record" (
  "id" bigserial NOT NULL,
  "created" timestamp NOT NULL,
  "current_id" bigint DEFAULT 0 NOT NULL,
  "createdby" bigint,
  "approvedby" bigint,
  "record_id" bigint,
  "approval" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "record_idx_approvedby" on "record" ("approvedby");
CREATE INDEX "record_idx_createdby" on "record" ("createdby");
CREATE INDEX "record_idx_current_id" on "record" ("current_id");
CREATE INDEX "record_idx_record_id" on "record" ("record_id");
CREATE INDEX "record_idx_approval" on "record" ("approval");

;
--
-- Table: report
--
CREATE TABLE "report" (
  "id" bigserial NOT NULL,
  "name" text NOT NULL,
  "title" text,
  "description" text,
  "user_id" bigint,
  "createdby" bigint,
  "created" timestamp,
  "instance_id" bigint,
  "deleted" timestamp,
  "security_marking" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "report_idx_createdby" on "report" ("createdby");
CREATE INDEX "report_idx_instance_id" on "report" ("instance_id");
CREATE INDEX "report_idx_user_id" on "report" ("user_id");

;
--
-- Table: report_group
--
CREATE TABLE "report_group" (
  "id" serial NOT NULL,
  "report_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "report_group_idx_group_id" on "report_group" ("group_id");
CREATE INDEX "report_group_idx_report_id" on "report_group" ("report_id");

;
--
-- Table: report_layout
--
CREATE TABLE "report_layout" (
  "id" serial NOT NULL,
  "report_id" integer NOT NULL,
  "layout_id" bigint NOT NULL,
  "order" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "report_layout_idx_layout_id" on "report_layout" ("layout_id");
CREATE INDEX "report_layout_idx_report_id" on "report_layout" ("report_id");

;
--
-- Table: site
--
CREATE TABLE "site" (
  "id" serial NOT NULL,
  "host" character varying(128),
  "name" text,
  "created" timestamp,
  "email_welcome_text" text,
  "email_welcome_subject" text,
  "email_delete_text" text,
  "email_delete_subject" text,
  "email_reject_text" text,
  "email_reject_subject" text,
  "register_text" text,
  "homepage_text" text,
  "homepage_text2" text,
  "register_title_help" text,
  "register_freetext1_help" text,
  "register_freetext2_help" text,
  "register_email_help" text,
  "register_organisation_help" text,
  "register_organisation_name" text,
  "register_organisation_mandatory" smallint DEFAULT 0 NOT NULL,
  "register_department_help" text,
  "register_department_name" text,
  "register_department_mandatory" smallint DEFAULT 0 NOT NULL,
  "register_team_help" text,
  "register_team_name" text,
  "register_team_mandatory" smallint DEFAULT 0 NOT NULL,
  "register_notes_help" text,
  "register_freetext1_name" text,
  "register_freetext2_name" text,
  "register_show_organisation" smallint DEFAULT 1 NOT NULL,
  "register_show_department" smallint DEFAULT 0 NOT NULL,
  "register_show_team" smallint DEFAULT 0 NOT NULL,
  "register_show_title" smallint DEFAULT 1 NOT NULL,
  "hide_account_request" smallint DEFAULT 0 NOT NULL,
  "remember_user_location" smallint DEFAULT 1 NOT NULL,
  "user_editable_fields" text,
  "register_freetext1_placeholder" text,
  "register_freetext2_placeholder" text,
  "account_request_notes_name" text,
  "account_request_notes_placeholder" text,
  "security_marking" text,
  "site_logo" bytea,
  PRIMARY KEY ("id")
);

;
--
-- Table: sort
--
CREATE TABLE "sort" (
  "id" serial NOT NULL,
  "view_id" bigint NOT NULL,
  "layout_id" integer,
  "parent_id" integer,
  "type" character varying(45),
  "order" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "sort_idx_layout_id" on "sort" ("layout_id");
CREATE INDEX "sort_idx_parent_id" on "sort" ("parent_id");
CREATE INDEX "sort_idx_view_id" on "sort" ("view_id");

;
--
-- Table: string
--
CREATE TABLE "string" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "child_unique" smallint DEFAULT 0 NOT NULL,
  "value" citext,
  "value_index" character varying(128),
  "purged_by" bigint,
  "purged_on" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "string_idx_layout_id" on "string" ("layout_id");
CREATE INDEX "string_idx_purged_by" on "string" ("purged_by");
CREATE INDEX "string_idx_record_id" on "string" ("record_id");
CREATE INDEX "string_idx_value_index" on "string" ("value_index");

;
--
-- Table: submission
--
CREATE TABLE "submission" (
  "id" serial NOT NULL,
  "token" character varying(64) NOT NULL,
  "created" timestamp,
  "submitted" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "ux_submission_token" UNIQUE ("token", "submitted")
);

;
--
-- Table: team
--
CREATE TABLE "team" (
  "id" serial NOT NULL,
  "name" citext,
  "site_id" integer,
  "deleted" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "team_idx_site_id" on "team" ("site_id");

;
--
-- Table: title
--
CREATE TABLE "title" (
  "id" serial NOT NULL,
  "name" character varying(128),
  "site_id" integer,
  "deleted" smallint DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "title_idx_site_id" on "title" ("site_id");

;
--
-- Table: topic
--
CREATE TABLE "topic" (
  "id" serial NOT NULL,
  "instance_id" integer,
  "name" text,
  "description" text,
  "initial_state" character varying(32),
  "click_to_edit" smallint DEFAULT 0 NOT NULL,
  "prevent_edit_topic_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "topic_idx_instance_id" on "topic" ("instance_id");
CREATE INDEX "topic_idx_prevent_edit_topic_id" on "topic" ("prevent_edit_topic_id");

;
--
-- Table: user
--
CREATE TABLE "user" (
  "id" bigserial NOT NULL,
  "site_id" integer,
  "firstname" character varying(128),
  "surname" character varying(128),
  "email" citext,
  "username" citext,
  "title" integer,
  "organisation" integer,
  "department_id" integer,
  "team_id" integer,
  "freetext1" text,
  "freetext2" text,
  "password" character varying(128),
  "pwchanged" timestamp,
  "resetpw" character varying(32),
  "deleted" timestamp,
  "lastlogin" timestamp,
  "lastfail" timestamp,
  "failcount" integer DEFAULT 0 NOT NULL,
  "lastrecord" bigint,
  "lastview" bigint,
  "session_settings" text,
  "value" citext,
  "account_request" smallint DEFAULT 0,
  "account_request_notes" text,
  "aup_accepted" timestamp,
  "limit_to_view" bigint,
  "stylesheet" text,
  "created" timestamp,
  "debug_login" smallint DEFAULT 0,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_idx_department_id" on "user" ("department_id");
CREATE INDEX "user_idx_lastrecord" on "user" ("lastrecord");
CREATE INDEX "user_idx_lastview" on "user" ("lastview");
CREATE INDEX "user_idx_limit_to_view" on "user" ("limit_to_view");
CREATE INDEX "user_idx_organisation" on "user" ("organisation");
CREATE INDEX "user_idx_site_id" on "user" ("site_id");
CREATE INDEX "user_idx_team_id" on "user" ("team_id");
CREATE INDEX "user_idx_title" on "user" ("title");
CREATE INDEX "user_idx_value" on "user" ("value");
CREATE INDEX "user_idx_email" on "user" ("email");
CREATE INDEX "user_idx_username" on "user" ("username");

;
--
-- Table: user_graph
--
CREATE TABLE "user_graph" (
  "id" bigserial NOT NULL,
  "user_id" bigint NOT NULL,
  "graph_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_graph_idx_graph_id" on "user_graph" ("graph_id");
CREATE INDEX "user_graph_idx_user_id" on "user_graph" ("user_id");

;
--
-- Table: user_group
--
CREATE TABLE "user_group" (
  "id" bigserial NOT NULL,
  "user_id" bigint NOT NULL,
  "group_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_group_idx_group_id" on "user_group" ("group_id");
CREATE INDEX "user_group_idx_user_id" on "user_group" ("user_id");

;
--
-- Table: user_lastrecord
--
CREATE TABLE "user_lastrecord" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "instance_id" integer NOT NULL,
  "user_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_lastrecord_idx_instance_id" on "user_lastrecord" ("instance_id");
CREATE INDEX "user_lastrecord_idx_record_id" on "user_lastrecord" ("record_id");
CREATE INDEX "user_lastrecord_idx_user_id" on "user_lastrecord" ("user_id");

;
--
-- Table: user_permission
--
CREATE TABLE "user_permission" (
  "id" bigserial NOT NULL,
  "user_id" bigint NOT NULL,
  "permission_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_permission_idx_permission_id" on "user_permission" ("permission_id");
CREATE INDEX "user_permission_idx_user_id" on "user_permission" ("user_id");

;
--
-- Table: view
--
CREATE TABLE "view" (
  "id" bigserial NOT NULL,
  "user_id" bigint,
  "group_id" integer,
  "name" character varying(128),
  "global" smallint DEFAULT 0 NOT NULL,
  "is_admin" smallint DEFAULT 0 NOT NULL,
  "is_limit_extra" smallint DEFAULT 0 NOT NULL,
  "filter" text,
  "instance_id" integer,
  "created" timestamp,
  "createdby" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "view_idx_createdby" on "view" ("createdby");
CREATE INDEX "view_idx_group_id" on "view" ("group_id");
CREATE INDEX "view_idx_instance_id" on "view" ("instance_id");
CREATE INDEX "view_idx_user_id" on "view" ("user_id");

;
--
-- Table: view_group
--
CREATE TABLE "view_group" (
  "id" serial NOT NULL,
  "view_id" bigint NOT NULL,
  "layout_id" integer,
  "parent_id" integer,
  "order" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "view_group_idx_layout_id" on "view_group" ("layout_id");
CREATE INDEX "view_group_idx_parent_id" on "view_group" ("parent_id");
CREATE INDEX "view_group_idx_view_id" on "view_group" ("view_id");

;
--
-- Table: view_layout
--
CREATE TABLE "view_layout" (
  "id" serial NOT NULL,
  "view_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "order" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "view_layout_idx_layout_id" on "view_layout" ("layout_id");
CREATE INDEX "view_layout_idx_view_id" on "view_layout" ("view_id");

;
--
-- Table: view_limit
--
CREATE TABLE "view_limit" (
  "id" bigserial NOT NULL,
  "view_id" bigint NOT NULL,
  "user_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "view_limit_idx_user_id" on "view_limit" ("user_id");
CREATE INDEX "view_limit_idx_view_id" on "view_limit" ("view_id");

;
--
-- Table: widget
--
CREATE TABLE "widget" (
  "id" serial NOT NULL,
  "grid_id" character varying(64),
  "dashboard_id" integer,
  "type" character varying(16),
  "title" text,
  "static" smallint DEFAULT 0 NOT NULL,
  "h" smallint DEFAULT 0,
  "w" smallint DEFAULT 0,
  "x" smallint DEFAULT 0,
  "y" smallint DEFAULT 0,
  "content" text,
  "view_id" integer,
  "graph_id" integer,
  "rows" integer,
  "tl_options" text,
  "globe_options" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "widget_ux_dashboard_grid" UNIQUE ("dashboard_id", "grid_id")
);
CREATE INDEX "widget_idx_dashboard_id" on "widget" ("dashboard_id");
CREATE INDEX "widget_idx_graph_id" on "widget" ("graph_id");
CREATE INDEX "widget_idx_view_id" on "widget" ("view_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "alert" ADD CONSTRAINT "alert_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert" ADD CONSTRAINT "alert_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_current_id" FOREIGN KEY ("current_id")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_column" ADD CONSTRAINT "alert_column_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_column" ADD CONSTRAINT "alert_column_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_send" ADD CONSTRAINT "alert_send_fk_alert_id" FOREIGN KEY ("alert_id")
  REFERENCES "alert" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_send" ADD CONSTRAINT "alert_send_fk_current_id" FOREIGN KEY ("current_id")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "alert_send" ADD CONSTRAINT "alert_send_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "authentication" ADD CONSTRAINT "authentication_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calc" ADD CONSTRAINT "calc_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calc_unique" ADD CONSTRAINT "calc_unique_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calcval" ADD CONSTRAINT "calcval_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calcval" ADD CONSTRAINT "calcval_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calcval" ADD CONSTRAINT "calcval_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "current" ADD CONSTRAINT "current_fk_deletedby" FOREIGN KEY ("deletedby")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "current" ADD CONSTRAINT "current_fk_draftuser_id" FOREIGN KEY ("draftuser_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "current" ADD CONSTRAINT "current_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "current" ADD CONSTRAINT "current_fk_linked_id" FOREIGN KEY ("linked_id")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "current" ADD CONSTRAINT "current_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval" ADD CONSTRAINT "curval_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval" ADD CONSTRAINT "curval_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval" ADD CONSTRAINT "curval_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval" ADD CONSTRAINT "curval_fk_value" FOREIGN KEY ("value")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval_fields" ADD CONSTRAINT "curval_fields_fk_child_id" FOREIGN KEY ("child_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "curval_fields" ADD CONSTRAINT "curval_fields_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "dashboard" ADD CONSTRAINT "dashboard_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "dashboard" ADD CONSTRAINT "dashboard_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "dashboard" ADD CONSTRAINT "dashboard_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "date" ADD CONSTRAINT "date_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "date" ADD CONSTRAINT "date_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "date" ADD CONSTRAINT "date_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "daterange" ADD CONSTRAINT "daterange_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "daterange" ADD CONSTRAINT "daterange_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "daterange" ADD CONSTRAINT "daterange_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "department" ADD CONSTRAINT "department_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "display_field" ADD CONSTRAINT "display_field_fk_display_field_id" FOREIGN KEY ("display_field_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "display_field" ADD CONSTRAINT "display_field_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "enum" ADD CONSTRAINT "enum_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "enum" ADD CONSTRAINT "enum_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "enum" ADD CONSTRAINT "enum_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "enum" ADD CONSTRAINT "enum_fk_value" FOREIGN KEY ("value")
  REFERENCES "enumval" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "enumval" ADD CONSTRAINT "enumval_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "enumval" ADD CONSTRAINT "enumval_fk_parent" FOREIGN KEY ("parent")
  REFERENCES "enumval" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "export" ADD CONSTRAINT "export_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "export" ADD CONSTRAINT "export_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "file" ADD CONSTRAINT "file_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "file" ADD CONSTRAINT "file_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "file" ADD CONSTRAINT "file_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "file" ADD CONSTRAINT "file_fk_value" FOREIGN KEY ("value")
  REFERENCES "fileval" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "file_option" ADD CONSTRAINT "file_option_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "fileval" ADD CONSTRAINT "fileval_fk_edit_user_id" FOREIGN KEY ("edit_user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filter" ADD CONSTRAINT "filter_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filter" ADD CONSTRAINT "filter_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filtered_value" ADD CONSTRAINT "filtered_value_fk_current_id" FOREIGN KEY ("current_id")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filtered_value" ADD CONSTRAINT "filtered_value_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filtered_value" ADD CONSTRAINT "filtered_value_fk_submission_id" FOREIGN KEY ("submission_id")
  REFERENCES "submission" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_group_by" FOREIGN KEY ("group_by")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_metric_group" FOREIGN KEY ("metric_group")
  REFERENCES "metric_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_x_axis" FOREIGN KEY ("x_axis")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_x_axis_link" FOREIGN KEY ("x_axis_link")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_y_axis" FOREIGN KEY ("y_axis")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "group" ADD CONSTRAINT "group_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "import" ADD CONSTRAINT "import_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "import" ADD CONSTRAINT "import_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "import" ADD CONSTRAINT "import_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "import_row" ADD CONSTRAINT "import_row_fk_import_id" FOREIGN KEY ("import_id")
  REFERENCES "import" ("id") ON DELETE CASCADE ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance" ADD CONSTRAINT "instance_fk_api_index_layout_id" FOREIGN KEY ("api_index_layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance" ADD CONSTRAINT "instance_fk_default_view_limit_extra_id" FOREIGN KEY ("default_view_limit_extra_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance" ADD CONSTRAINT "instance_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance" ADD CONSTRAINT "instance_fk_sort_layout_id" FOREIGN KEY ("sort_layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance" ADD CONSTRAINT "instance_fk_view_limit_id" FOREIGN KEY ("view_limit_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance_group" ADD CONSTRAINT "instance_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance_group" ADD CONSTRAINT "instance_group_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance_rag" ADD CONSTRAINT "instance_rag_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "intgr" ADD CONSTRAINT "intgr_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "intgr" ADD CONSTRAINT "intgr_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "intgr" ADD CONSTRAINT "intgr_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout" ADD CONSTRAINT "layout_fk_display_field" FOREIGN KEY ("display_field")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout" ADD CONSTRAINT "layout_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout" ADD CONSTRAINT "layout_fk_link_parent" FOREIGN KEY ("link_parent")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout" ADD CONSTRAINT "layout_fk_related_field" FOREIGN KEY ("related_field")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout" ADD CONSTRAINT "layout_fk_topic_id" FOREIGN KEY ("topic_id")
  REFERENCES "topic" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout_depend" ADD CONSTRAINT "layout_depend_fk_depends_on" FOREIGN KEY ("depends_on")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout_depend" ADD CONSTRAINT "layout_depend_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout_group" ADD CONSTRAINT "layout_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "layout_group" ADD CONSTRAINT "layout_group_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "metric" ADD CONSTRAINT "metric_fk_metric_group" FOREIGN KEY ("metric_group")
  REFERENCES "metric_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "metric_group" ADD CONSTRAINT "metric_group_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "oauthtoken" ADD CONSTRAINT "oauthtoken_fk_oauthclient_id" FOREIGN KEY ("oauthclient_id")
  REFERENCES "oauthclient" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "oauthtoken" ADD CONSTRAINT "oauthtoken_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "organisation" ADD CONSTRAINT "organisation_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "person" ADD CONSTRAINT "person_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "person" ADD CONSTRAINT "person_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "person" ADD CONSTRAINT "person_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "person" ADD CONSTRAINT "person_fk_value" FOREIGN KEY ("value")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "rag" ADD CONSTRAINT "rag_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "ragval" ADD CONSTRAINT "ragval_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "ragval" ADD CONSTRAINT "ragval_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "ragval" ADD CONSTRAINT "ragval_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "record" ADD CONSTRAINT "record_fk_approvedby" FOREIGN KEY ("approvedby")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "record" ADD CONSTRAINT "record_fk_createdby" FOREIGN KEY ("createdby")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "record" ADD CONSTRAINT "record_fk_current_id" FOREIGN KEY ("current_id")
  REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "record" ADD CONSTRAINT "record_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report" ADD CONSTRAINT "report_fk_createdby" FOREIGN KEY ("createdby")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report" ADD CONSTRAINT "report_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report" ADD CONSTRAINT "report_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report_group" ADD CONSTRAINT "report_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report_group" ADD CONSTRAINT "report_group_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report_layout" ADD CONSTRAINT "report_layout_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "report_layout" ADD CONSTRAINT "report_layout_fk_report_id" FOREIGN KEY ("report_id")
  REFERENCES "report" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "sort" ADD CONSTRAINT "sort_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "sort" ADD CONSTRAINT "sort_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "sort" ADD CONSTRAINT "sort_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "string" ADD CONSTRAINT "string_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "string" ADD CONSTRAINT "string_fk_purged_by" FOREIGN KEY ("purged_by")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "string" ADD CONSTRAINT "string_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "team" ADD CONSTRAINT "team_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "title" ADD CONSTRAINT "title_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "topic" ADD CONSTRAINT "topic_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "topic" ADD CONSTRAINT "topic_fk_prevent_edit_topic_id" FOREIGN KEY ("prevent_edit_topic_id")
  REFERENCES "topic" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_department_id" FOREIGN KEY ("department_id")
  REFERENCES "department" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_lastrecord" FOREIGN KEY ("lastrecord")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_lastview" FOREIGN KEY ("lastview")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_limit_to_view" FOREIGN KEY ("limit_to_view")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_organisation" FOREIGN KEY ("organisation")
  REFERENCES "organisation" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_team_id" FOREIGN KEY ("team_id")
  REFERENCES "team" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_title" FOREIGN KEY ("title")
  REFERENCES "title" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_graph" ADD CONSTRAINT "user_graph_fk_graph_id" FOREIGN KEY ("graph_id")
  REFERENCES "graph" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_graph" ADD CONSTRAINT "user_graph_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_permission_id" FOREIGN KEY ("permission_id")
  REFERENCES "permission" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view" ADD CONSTRAINT "view_fk_createdby" FOREIGN KEY ("createdby")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view" ADD CONSTRAINT "view_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view" ADD CONSTRAINT "view_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view" ADD CONSTRAINT "view_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_group" ADD CONSTRAINT "view_group_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_group" ADD CONSTRAINT "view_group_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_group" ADD CONSTRAINT "view_group_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_layout" ADD CONSTRAINT "view_layout_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_layout" ADD CONSTRAINT "view_layout_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_limit" ADD CONSTRAINT "view_limit_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_limit" ADD CONSTRAINT "view_limit_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "widget" ADD CONSTRAINT "widget_fk_dashboard_id" FOREIGN KEY ("dashboard_id")
  REFERENCES "dashboard" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "widget" ADD CONSTRAINT "widget_fk_graph_id" FOREIGN KEY ("graph_id")
  REFERENCES "graph" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "widget" ADD CONSTRAINT "widget_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
