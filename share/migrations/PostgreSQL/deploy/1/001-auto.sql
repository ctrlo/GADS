-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Sep 28 11:17:07 2015
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
  PRIMARY KEY ("id")
);
CREATE INDEX "alert_cache_idx_current_id" on "alert_cache" ("current_id");
CREATE INDEX "alert_cache_idx_layout_id" on "alert_cache" ("layout_id");
CREATE INDEX "alert_cache_idx_view_id" on "alert_cache" ("view_id");

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
  "user_id" bigint,
  "type" character varying(45),
  "datetime" timestamp,
  "method" character varying(45),
  "url" text,
  "description" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "audit_idx_user_id" on "audit" ("user_id");

;
--
-- Table: calc
--
CREATE TABLE "calc" (
  "id" serial NOT NULL,
  "layout_id" integer,
  "calc" text,
  "return_format" character varying(45),
  PRIMARY KEY ("id")
);
CREATE INDEX "calc_idx_layout_id" on "calc" ("layout_id");

;
--
-- Table: calcval
--
CREATE TABLE "calcval" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "value" citext,
  PRIMARY KEY ("id"),
  CONSTRAINT "calcval_ux_record_layout" UNIQUE ("record_id", "layout_id")
);
CREATE INDEX "calcval_idx_layout_id" on "calcval" ("layout_id");
CREATE INDEX "calcval_idx_record_id" on "calcval" ("record_id");
CREATE INDEX "calcval_idx_value" on "calcval" ("value");

;
--
-- Table: current
--
CREATE TABLE "current" (
  "id" bigserial NOT NULL,
  "serial" character varying(45),
  "record_id" bigint,
  "parent_id" bigint,
  "instance_id" integer,
  "linked_id" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "current_idx_instance_id" on "current" ("instance_id");
CREATE INDEX "current_idx_linked_id" on "current" ("linked_id");
CREATE INDEX "current_idx_parent_id" on "current" ("parent_id");
CREATE INDEX "current_idx_record_id" on "current" ("record_id");

;
--
-- Table: date
--
CREATE TABLE "date" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "value" date,
  PRIMARY KEY ("id")
);
CREATE INDEX "date_idx_layout_id" on "date" ("layout_id");
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
  "value" character varying(45),
  PRIMARY KEY ("id")
);
CREATE INDEX "daterange_idx_layout_id" on "daterange" ("layout_id");
CREATE INDEX "daterange_idx_record_id" on "daterange" ("record_id");
CREATE INDEX "daterange_idx_from" on "daterange" ("from");
CREATE INDEX "daterange_idx_to" on "daterange" ("to");
CREATE INDEX "daterange_idx_value" on "daterange" ("value");

;
--
-- Table: enum
--
CREATE TABLE "enum" (
  "id" bigserial NOT NULL,
  "record_id" bigint,
  "layout_id" integer,
  "value" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "enum_idx_layout_id" on "enum" ("layout_id");
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
  PRIMARY KEY ("id")
);
CREATE INDEX "enumval_idx_layout_id" on "enumval" ("layout_id");
CREATE INDEX "enumval_idx_parent" on "enumval" ("parent");
CREATE INDEX "enumval_idx_value" on "enumval" ("value");

;
--
-- Table: file
--
CREATE TABLE "file" (
  "id" bigserial NOT NULL,
  "record_id" bigint,
  "layout_id" integer,
  "value" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "file_idx_layout_id" on "file" ("layout_id");
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
  "mimetype" character varying(45),
  "content" bytea,
  PRIMARY KEY ("id")
);
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
-- Table: graph
--
CREATE TABLE "graph" (
  "id" serial NOT NULL,
  "title" text,
  "description" text,
  "y_axis" integer,
  "y_axis_stack" character varying(45),
  "y_axis_label" character varying(128),
  "x_axis" integer,
  "x_axis_grouping" character varying(45),
  "group_by" integer,
  "stackseries" smallint DEFAULT 0 NOT NULL,
  "type" character varying(45),
  "metric_group" integer,
  "instance_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "graph_idx_group_by" on "graph" ("group_by");
CREATE INDEX "graph_idx_instance_id" on "graph" ("instance_id");
CREATE INDEX "graph_idx_metric_group" on "graph" ("metric_group");
CREATE INDEX "graph_idx_x_axis" on "graph" ("x_axis");
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
  PRIMARY KEY ("id")
);

;
--
-- Table: instance
--
CREATE TABLE "instance" (
  "id" serial NOT NULL,
  "name" character varying(45),
  "email_welcome_text" text,
  "email_welcome_subject" character varying(128),
  "email_delete_text" text,
  "email_delete_subject" character varying(128),
  "email_reject_text" text,
  "email_reject_subject" character varying(128),
  "register_text" text,
  "sort_layout_id" integer,
  "sort_type" character varying(45),
  "homepage_text" text,
  "homepage_text2" text,
  "register_title_help" text,
  "register_telephone_help" text,
  "register_email_help" text,
  "register_organisation_help" text,
  "register_notes_help" text,
  PRIMARY KEY ("id")
);
CREATE INDEX "instance_idx_sort_layout_id" on "instance" ("sort_layout_id");

;
--
-- Table: intgr
--
CREATE TABLE "intgr" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "value" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "intgr_idx_layout_id" on "intgr" ("layout_id");
CREATE INDEX "intgr_idx_record_id" on "intgr" ("record_id");
CREATE INDEX "intgr_idx_value" on "intgr" ("value");

;
--
-- Table: layout
--
CREATE TABLE "layout" (
  "id" serial NOT NULL,
  "name" character varying(45),
  "type" character varying(45),
  "permission" integer DEFAULT 0 NOT NULL,
  "optional" smallint DEFAULT 0 NOT NULL,
  "remember" smallint DEFAULT 0 NOT NULL,
  "position" integer,
  "ordering" character varying(45),
  "end_node_only" smallint DEFAULT 0 NOT NULL,
  "description" text,
  "helptext" text,
  "display_field" integer,
  "display_regex" text,
  "hidden" smallint DEFAULT 0 NOT NULL,
  "instance_id" integer,
  "link_parent" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "layout_idx_display_field" on "layout" ("display_field");
CREATE INDEX "layout_idx_instance_id" on "layout" ("instance_id");
CREATE INDEX "layout_idx_link_parent" on "layout" ("link_parent");

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
  "target" integer,
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
-- Table: organisation
--
CREATE TABLE "organisation" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

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
  "value" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "person_idx_layout_id" on "person" ("layout_id");
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
  PRIMARY KEY ("id"),
  CONSTRAINT "ragval_ux_record_layout" UNIQUE ("record_id", "layout_id")
);
CREATE INDEX "ragval_idx_layout_id" on "ragval" ("layout_id");
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

;
--
-- Table: sort
--
CREATE TABLE "sort" (
  "id" serial NOT NULL,
  "view_id" bigint NOT NULL,
  "layout_id" integer,
  "type" character varying(45),
  PRIMARY KEY ("id")
);
CREATE INDEX "sort_idx_layout_id" on "sort" ("layout_id");
CREATE INDEX "sort_idx_view_id" on "sort" ("view_id");

;
--
-- Table: string
--
CREATE TABLE "string" (
  "id" bigserial NOT NULL,
  "record_id" bigint NOT NULL,
  "layout_id" integer NOT NULL,
  "value" citext,
  PRIMARY KEY ("id")
);
CREATE INDEX "string_idx_layout_id" on "string" ("layout_id");
CREATE INDEX "string_idx_record_id" on "string" ("record_id");
CREATE INDEX "string_idx_value" on "string" ("value");

;
--
-- Table: title
--
CREATE TABLE "title" (
  "id" serial NOT NULL,
  "name" character varying(128),
  PRIMARY KEY ("id")
);

;
--
-- Table: user
--
CREATE TABLE "user" (
  "id" bigserial NOT NULL,
  "firstname" character varying(45),
  "surname" character varying(45),
  "email" citext,
  "username" citext,
  "title" integer,
  "organisation" integer,
  "telephone" character varying(128),
  "permission" smallint DEFAULT 0 NOT NULL,
  "password" character varying(128),
  "pwchanged" timestamp,
  "resetpw" character varying(32),
  "deleted" timestamp,
  "lastlogin" timestamp,
  "lastrecord" bigint,
  "lastview" bigint,
  "value" citext,
  "account_request" smallint DEFAULT 0,
  "account_request_notes" text,
  "aup_accepted" timestamp,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_idx_lastrecord" on "user" ("lastrecord");
CREATE INDEX "user_idx_lastview" on "user" ("lastview");
CREATE INDEX "user_idx_organisation" on "user" ("organisation");
CREATE INDEX "user_idx_title" on "user" ("title");
CREATE INDEX "user_idx_value" on "user" ("value");

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
  "name" character varying(128),
  "global" smallint DEFAULT 0 NOT NULL,
  "filter" text,
  "instance_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "view_idx_instance_id" on "view" ("instance_id");
CREATE INDEX "view_idx_user_id" on "view" ("user_id");

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
ALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "audit" ADD CONSTRAINT "audit_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calc" ADD CONSTRAINT "calc_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calcval" ADD CONSTRAINT "calcval_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "calcval" ADD CONSTRAINT "calcval_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "current" ADD CONSTRAINT "current_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "date" ADD CONSTRAINT "date_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "date" ADD CONSTRAINT "date_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "daterange" ADD CONSTRAINT "daterange_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "daterange" ADD CONSTRAINT "daterange_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "enum" ADD CONSTRAINT "enum_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "file" ADD CONSTRAINT "file_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "filter" ADD CONSTRAINT "filter_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "filter" ADD CONSTRAINT "filter_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_x_axis" FOREIGN KEY ("x_axis")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "graph" ADD CONSTRAINT "graph_fk_y_axis" FOREIGN KEY ("y_axis")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "instance" ADD CONSTRAINT "instance_fk_sort_layout_id" FOREIGN KEY ("sort_layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "intgr" ADD CONSTRAINT "intgr_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "person" ADD CONSTRAINT "person_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "sort" ADD CONSTRAINT "sort_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "sort" ADD CONSTRAINT "sort_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "string" ADD CONSTRAINT "string_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "string" ADD CONSTRAINT "string_fk_record_id" FOREIGN KEY ("record_id")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_lastrecord" FOREIGN KEY ("lastrecord")
  REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_lastview" FOREIGN KEY ("lastview")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user" ADD CONSTRAINT "user_fk_organisation" FOREIGN KEY ("organisation")
  REFERENCES "organisation" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

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
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_permission_id" FOREIGN KEY ("permission_id")
  REFERENCES "permission" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view" ADD CONSTRAINT "view_fk_instance_id" FOREIGN KEY ("instance_id")
  REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view" ADD CONSTRAINT "view_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_layout" ADD CONSTRAINT "view_layout_fk_layout_id" FOREIGN KEY ("layout_id")
  REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
ALTER TABLE "view_layout" ADD CONSTRAINT "view_layout_fk_view_id" FOREIGN KEY ("view_id")
  REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE;

;
