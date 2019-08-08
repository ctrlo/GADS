--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.7
-- Dumped by pg_dump version 9.6.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

\c postgres

--
-- Name: alert; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE alert (
    id integer NOT NULL,
    view_id bigint NOT NULL,
    user_id bigint NOT NULL,
    frequency integer DEFAULT 0 NOT NULL
);


ALTER TABLE alert OWNER TO postgres;

--
-- Name: alert_cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE alert_cache (
    id integer NOT NULL,
    layout_id integer NOT NULL,
    view_id bigint NOT NULL,
    current_id bigint NOT NULL,
    user_id bigint
);


ALTER TABLE alert_cache OWNER TO postgres;

--
-- Name: alert_cache_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE alert_cache_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alert_cache_id_seq OWNER TO postgres;

--
-- Name: alert_cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE alert_cache_id_seq OWNED BY alert_cache.id;


--
-- Name: alert_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alert_id_seq OWNER TO postgres;

--
-- Name: alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE alert_id_seq OWNED BY alert.id;


--
-- Name: alert_send; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE alert_send (
    id integer NOT NULL,
    layout_id integer,
    alert_id integer NOT NULL,
    current_id bigint NOT NULL,
    status character(7)
);


ALTER TABLE alert_send OWNER TO postgres;

--
-- Name: alert_send_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE alert_send_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alert_send_id_seq OWNER TO postgres;

--
-- Name: alert_send_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE alert_send_id_seq OWNED BY alert_send.id;


--
-- Name: audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE audit (
    id integer NOT NULL,
    site_id integer,
    user_id bigint,
    type character varying(45),
    datetime timestamp without time zone,
    method character varying(45),
    url text,
    description text
);


ALTER TABLE audit OWNER TO postgres;

--
-- Name: audit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE audit_id_seq OWNER TO postgres;

--
-- Name: audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE audit_id_seq OWNED BY audit.id;


--
-- Name: calc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE calc (
    id integer NOT NULL,
    layout_id integer,
    calc text,
    code text,
    return_format character varying(45),
    decimal_places smallint
);


ALTER TABLE calc OWNER TO postgres;

--
-- Name: calc_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE calc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE calc_id_seq OWNER TO postgres;

--
-- Name: calc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE calc_id_seq OWNED BY calc.id;


--
-- Name: calcval; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE calcval (
    id integer NOT NULL,
    record_id bigint NOT NULL,
    layout_id integer NOT NULL,
    value_text text,
    value_int bigint,
    value_date pg_catalog.date,
    value_numeric numeric(20,5)
);


ALTER TABLE calcval OWNER TO postgres;

--
-- Name: calcval_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE calcval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE calcval_id_seq OWNER TO postgres;

--
-- Name: calcval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE calcval_id_seq OWNED BY calcval.id;


--
-- Name: current; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE current (
    id integer NOT NULL,
    parent_id bigint,
    instance_id integer,
    linked_id bigint,
    deleted timestamp without time zone,
    deletedby bigint,
    serial bigint
);


ALTER TABLE current OWNER TO postgres;

--
-- Name: current_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE current_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE current_id_seq OWNER TO postgres;

--
-- Name: current_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE current_id_seq OWNED BY current.id;


--
-- Name: curval; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE curval (
    id integer NOT NULL,
    record_id bigint,
    layout_id integer,
    child_unique smallint DEFAULT 0 NOT NULL,
    value bigint
);


ALTER TABLE curval OWNER TO postgres;

--
-- Name: curval_fields; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE curval_fields (
    id integer NOT NULL,
    parent_id integer NOT NULL,
    child_id integer NOT NULL
);


ALTER TABLE curval_fields OWNER TO postgres;

--
-- Name: curval_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE curval_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE curval_fields_id_seq OWNER TO postgres;

--
-- Name: curval_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE curval_fields_id_seq OWNED BY curval_fields.id;


--
-- Name: curval_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE curval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE curval_id_seq OWNER TO postgres;

--
-- Name: curval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE curval_id_seq OWNED BY curval.id;


--
-- Name: date; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE date (
    id integer NOT NULL,
    record_id bigint NOT NULL,
    layout_id integer NOT NULL,
    child_unique smallint DEFAULT 0 NOT NULL,
    value pg_catalog.date
);


ALTER TABLE date OWNER TO postgres;

--
-- Name: date_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE date_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE date_id_seq OWNER TO postgres;

--
-- Name: date_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE date_id_seq OWNED BY date.id;


--
-- Name: daterange; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE daterange (
    id integer NOT NULL,
    record_id bigint NOT NULL,
    layout_id integer NOT NULL,
    "from" pg_catalog.date,
    "to" pg_catalog.date,
    child_unique smallint DEFAULT 0 NOT NULL,
    value character varying(45)
);


ALTER TABLE daterange OWNER TO postgres;

--
-- Name: daterange_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE daterange_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE daterange_id_seq OWNER TO postgres;

--
-- Name: daterange_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE daterange_id_seq OWNED BY daterange.id;


--
-- Name: dbix_class_deploymenthandler_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE dbix_class_deploymenthandler_versions (
    id integer NOT NULL,
    version character varying(50) NOT NULL,
    ddl text,
    upgrade_sql text
);


ALTER TABLE dbix_class_deploymenthandler_versions OWNER TO postgres;

--
-- Name: dbix_class_deploymenthandler_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE dbix_class_deploymenthandler_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dbix_class_deploymenthandler_versions_id_seq OWNER TO postgres;

--
-- Name: dbix_class_deploymenthandler_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE dbix_class_deploymenthandler_versions_id_seq OWNED BY dbix_class_deploymenthandler_versions.id;


--
-- Name: enum; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE enum (
    id integer NOT NULL,
    record_id bigint,
    layout_id integer,
    child_unique smallint DEFAULT 0 NOT NULL,
    value integer
);


ALTER TABLE enum OWNER TO postgres;

--
-- Name: enum_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE enum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE enum_id_seq OWNER TO postgres;

--
-- Name: enum_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE enum_id_seq OWNED BY enum.id;


--
-- Name: enumval; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE enumval (
    id integer NOT NULL,
    value text,
    layout_id integer,
    deleted smallint DEFAULT 0 NOT NULL,
    parent integer
);


ALTER TABLE enumval OWNER TO postgres;

--
-- Name: enumval_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE enumval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE enumval_id_seq OWNER TO postgres;

--
-- Name: enumval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE enumval_id_seq OWNED BY enumval.id;


--
-- Name: file; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE file (
    id integer NOT NULL,
    record_id bigint,
    layout_id integer,
    child_unique smallint DEFAULT 0 NOT NULL,
    value bigint
);


ALTER TABLE file OWNER TO postgres;

--
-- Name: file_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE file_id_seq OWNER TO postgres;

--
-- Name: file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE file_id_seq OWNED BY file.id;


--
-- Name: file_option; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE file_option (
    id integer NOT NULL,
    layout_id integer NOT NULL,
    filesize integer
);


ALTER TABLE file_option OWNER TO postgres;

--
-- Name: file_option_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE file_option_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE file_option_id_seq OWNER TO postgres;

--
-- Name: file_option_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE file_option_id_seq OWNED BY file_option.id;


--
-- Name: fileval; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE fileval (
    id integer NOT NULL,
    name text,
    mimetype text,
    content bytea
);


ALTER TABLE fileval OWNER TO postgres;

--
-- Name: fileval_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE fileval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fileval_id_seq OWNER TO postgres;

--
-- Name: fileval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE fileval_id_seq OWNED BY fileval.id;


--
-- Name: filter; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE filter (
    id integer NOT NULL,
    view_id bigint NOT NULL,
    layout_id integer NOT NULL
);


ALTER TABLE filter OWNER TO postgres;

--
-- Name: filter_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE filter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE filter_id_seq OWNER TO postgres;

--
-- Name: filter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE filter_id_seq OWNED BY filter.id;


--
-- Name: graph; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE graph (
    id integer NOT NULL,
    title text,
    description text,
    y_axis integer,
    y_axis_stack character varying(45),
    y_axis_label text,
    x_axis integer,
    x_axis_grouping character varying(45),
    group_by integer,
    stackseries smallint DEFAULT 0 NOT NULL,
    as_percent smallint DEFAULT 0 NOT NULL,
    type character varying(45),
    metric_group integer,
    instance_id integer
);


ALTER TABLE graph OWNER TO postgres;

--
-- Name: graph_color; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE graph_color (
    id integer NOT NULL,
    name character varying(128),
    color character(6)
);


ALTER TABLE graph_color OWNER TO postgres;

--
-- Name: graph_color_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE graph_color_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE graph_color_id_seq OWNER TO postgres;

--
-- Name: graph_color_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE graph_color_id_seq OWNED BY graph_color.id;


--
-- Name: graph_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE graph_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE graph_id_seq OWNER TO postgres;

--
-- Name: graph_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE graph_id_seq OWNED BY graph.id;


--
-- Name: group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "group" (
    id integer NOT NULL,
    name character varying(128),
    default_read smallint DEFAULT 0 NOT NULL,
    default_write_new smallint DEFAULT 0 NOT NULL,
    default_write_existing smallint DEFAULT 0 NOT NULL,
    default_approve_new smallint DEFAULT 0 NOT NULL,
    default_approve_existing smallint DEFAULT 0 NOT NULL,
    default_write_new_no_approval smallint DEFAULT 0 NOT NULL,
    default_write_existing_no_approval smallint DEFAULT 0 NOT NULL,
    site_id integer
);


ALTER TABLE "group" OWNER TO postgres;

--
-- Name: group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE group_id_seq OWNER TO postgres;

--
-- Name: group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE group_id_seq OWNED BY "group".id;


--
-- Name: import; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE import (
    id integer NOT NULL,
    site_id integer,
    user_id bigint NOT NULL,
    type character varying(45),
    row_count integer DEFAULT 0 NOT NULL,
    started timestamp without time zone,
    completed timestamp without time zone,
    written_count integer DEFAULT 0 NOT NULL,
    error_count integer DEFAULT 0 NOT NULL,
    skipped_count integer DEFAULT 0 NOT NULL,
    result text
);


ALTER TABLE import OWNER TO postgres;

--
-- Name: import_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE import_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE import_id_seq OWNER TO postgres;

--
-- Name: import_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE import_id_seq OWNED BY import.id;


--
-- Name: import_row; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE import_row (
    id integer NOT NULL,
    import_id integer NOT NULL,
    status character varying(45),
    content text,
    errors text,
    changes text
);


ALTER TABLE import_row OWNER TO postgres;

--
-- Name: import_row_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE import_row_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE import_row_id_seq OWNER TO postgres;

--
-- Name: import_row_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE import_row_id_seq OWNED BY import_row.id;


--
-- Name: instance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE instance (
    id integer NOT NULL,
    name text,
    name_short character varying(64),
    site_id integer,
    email_welcome_text text,
    email_welcome_subject text,
    sort_layout_id integer,
    sort_type character varying(45),
    default_view_limit_extra_id integer,
    homepage_text text,
    homepage_text2 text,
    forget_history smallint DEFAULT 0,
    no_overnight_update smallint DEFAULT 0,
    api_index_layout_id integer
);


ALTER TABLE instance OWNER TO postgres;

--
-- Name: instance_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE instance_group (
    id integer NOT NULL,
    instance_id integer NOT NULL,
    group_id integer NOT NULL,
    permission character varying(45) NOT NULL
);


ALTER TABLE instance_group OWNER TO postgres;

--
-- Name: instance_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE instance_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE instance_group_id_seq OWNER TO postgres;

--
-- Name: instance_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE instance_group_id_seq OWNED BY instance_group.id;


--
-- Name: instance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE instance_id_seq OWNER TO postgres;

--
-- Name: instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE instance_id_seq OWNED BY instance.id;


--
-- Name: intgr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE intgr (
    id integer NOT NULL,
    record_id bigint NOT NULL,
    layout_id integer NOT NULL,
    child_unique smallint DEFAULT 0 NOT NULL,
    value bigint
);


ALTER TABLE intgr OWNER TO postgres;

--
-- Name: intgr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE intgr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE intgr_id_seq OWNER TO postgres;

--
-- Name: intgr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE intgr_id_seq OWNED BY intgr.id;


--
-- Name: layout; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE layout (
    id integer NOT NULL,
    name text,
    name_short text,
    type character varying(45),
    permission integer DEFAULT 0 NOT NULL,
    optional smallint DEFAULT 0 NOT NULL,
    remember smallint DEFAULT 0 NOT NULL,
    isunique smallint DEFAULT 0 NOT NULL,
    textbox smallint DEFAULT 0 NOT NULL,
    typeahead smallint DEFAULT 0 NOT NULL,
    force_regex text,
    "position" integer,
    ordering character varying(45),
    end_node_only smallint DEFAULT 0 NOT NULL,
    multivalue smallint DEFAULT 0 NOT NULL,
    description text,
    helptext text,
    options text,
    display_field integer,
    display_regex text,
    instance_id integer,
    link_parent integer,
    related_field integer,
    filter text
);


ALTER TABLE layout OWNER TO postgres;

--
-- Name: layout_depend; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE layout_depend (
    id integer NOT NULL,
    layout_id integer NOT NULL,
    depends_on integer NOT NULL
);


ALTER TABLE layout_depend OWNER TO postgres;

--
-- Name: layout_depend_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE layout_depend_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE layout_depend_id_seq OWNER TO postgres;

--
-- Name: layout_depend_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE layout_depend_id_seq OWNED BY layout_depend.id;


--
-- Name: layout_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE layout_group (
    id integer NOT NULL,
    layout_id integer NOT NULL,
    group_id integer NOT NULL,
    permission character varying(45) NOT NULL
);


ALTER TABLE layout_group OWNER TO postgres;

--
-- Name: layout_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE layout_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE layout_group_id_seq OWNER TO postgres;

--
-- Name: layout_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE layout_group_id_seq OWNED BY layout_group.id;


--
-- Name: layout_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE layout_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE layout_id_seq OWNER TO postgres;

--
-- Name: layout_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE layout_id_seq OWNED BY layout.id;


--
-- Name: metric; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE metric (
    id integer NOT NULL,
    metric_group integer NOT NULL,
    x_axis_value text,
    target bigint,
    y_axis_grouping_value text
);


ALTER TABLE metric OWNER TO postgres;

--
-- Name: metric_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE metric_group (
    id integer NOT NULL,
    name text,
    instance_id integer
);


ALTER TABLE metric_group OWNER TO postgres;

--
-- Name: metric_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE metric_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metric_group_id_seq OWNER TO postgres;

--
-- Name: metric_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE metric_group_id_seq OWNED BY metric_group.id;


--
-- Name: metric_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE metric_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metric_id_seq OWNER TO postgres;

--
-- Name: metric_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE metric_id_seq OWNED BY metric.id;


--
-- Name: oauthclient; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE oauthclient (
    id integer NOT NULL,
    client_id character varying(64) NOT NULL,
    client_secret character varying(64) NOT NULL
);


ALTER TABLE oauthclient OWNER TO postgres;

--
-- Name: oauthclient_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE oauthclient_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE oauthclient_id_seq OWNER TO postgres;

--
-- Name: oauthclient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE oauthclient_id_seq OWNED BY oauthclient.id;


--
-- Name: oauthtoken; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE oauthtoken (
    token character varying(128) NOT NULL,
    related_token character varying(128) NOT NULL,
    oauthclient_id integer NOT NULL,
    user_id bigint NOT NULL,
    type character varying(12) NOT NULL,
    expires integer
);


ALTER TABLE oauthtoken OWNER TO postgres;

--
-- Name: organisation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE organisation (
    id integer NOT NULL,
    name character varying(128),
    site_id integer
);


ALTER TABLE organisation OWNER TO postgres;

--
-- Name: organisation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE organisation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE organisation_id_seq OWNER TO postgres;

--
-- Name: organisation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE organisation_id_seq OWNED BY organisation.id;


--
-- Name: permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE permission (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    description text,
    "order" integer
);


ALTER TABLE permission OWNER TO postgres;

--
-- Name: permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE permission_id_seq OWNER TO postgres;

--
-- Name: permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE permission_id_seq OWNED BY permission.id;


--
-- Name: person; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE person (
    id integer NOT NULL,
    record_id bigint,
    layout_id integer,
    child_unique smallint DEFAULT 0 NOT NULL,
    value bigint
);


ALTER TABLE person OWNER TO postgres;

--
-- Name: person_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE person_id_seq OWNER TO postgres;

--
-- Name: person_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE person_id_seq OWNED BY person.id;


--
-- Name: rag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE rag (
    id integer NOT NULL,
    layout_id integer NOT NULL,
    red text,
    amber text,
    green text,
    code text
);


ALTER TABLE rag OWNER TO postgres;

--
-- Name: rag_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE rag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rag_id_seq OWNER TO postgres;

--
-- Name: rag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE rag_id_seq OWNED BY rag.id;


--
-- Name: ragval; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE ragval (
    id integer NOT NULL,
    record_id bigint NOT NULL,
    layout_id integer NOT NULL,
    value character varying(16)
);


ALTER TABLE ragval OWNER TO postgres;

--
-- Name: ragval_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ragval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ragval_id_seq OWNER TO postgres;

--
-- Name: ragval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE ragval_id_seq OWNED BY ragval.id;


--
-- Name: record; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE record (
    id integer NOT NULL,
    created timestamp without time zone NOT NULL,
    current_id bigint DEFAULT 0 NOT NULL,
    createdby bigint,
    approvedby bigint,
    record_id bigint,
    approval smallint DEFAULT 0 NOT NULL
);


ALTER TABLE record OWNER TO postgres;

--
-- Name: record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE record_id_seq OWNER TO postgres;

--
-- Name: record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE record_id_seq OWNED BY record.id;


--
-- Name: site; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE site (
    id integer NOT NULL,
    host character varying(128),
    created timestamp without time zone,
    email_welcome_text text,
    email_welcome_subject text,
    email_delete_text text,
    email_delete_subject text,
    email_reject_text text,
    email_reject_subject text,
    register_text text,
    homepage_text text,
    homepage_text2 text,
    register_title_help text,
    register_freetext1_help text,
    register_freetext2_help text,
    register_email_help text,
    register_organisation_help text,
    register_organisation_name text,
    register_notes_help text,
    register_freetext1_name text,
    register_freetext2_name text,
    register_show_organisation smallint DEFAULT 1 NOT NULL,
    register_show_title smallint DEFAULT 1 NOT NULL
);


ALTER TABLE site OWNER TO postgres;

--
-- Name: site_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE site_id_seq OWNER TO postgres;

--
-- Name: site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE site_id_seq OWNED BY site.id;


--
-- Name: sort; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE sort (
    id integer NOT NULL,
    view_id bigint NOT NULL,
    layout_id integer,
    type character varying(45)
);


ALTER TABLE sort OWNER TO postgres;

--
-- Name: sort_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE sort_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sort_id_seq OWNER TO postgres;

--
-- Name: sort_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE sort_id_seq OWNED BY sort.id;


--
-- Name: string; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE string (
    id integer NOT NULL,
    record_id bigint NOT NULL,
    layout_id integer NOT NULL,
    child_unique smallint DEFAULT 0 NOT NULL,
    value text,
    value_index character varying(128)
);


ALTER TABLE string OWNER TO postgres;

--
-- Name: string_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE string_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE string_id_seq OWNER TO postgres;

--
-- Name: string_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE string_id_seq OWNED BY string.id;


--
-- Name: title; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE title (
    id integer NOT NULL,
    name character varying(128),
    site_id integer
);


ALTER TABLE title OWNER TO postgres;

--
-- Name: title_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE title_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE title_id_seq OWNER TO postgres;

--
-- Name: title_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE title_id_seq OWNED BY title.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "user" (
    id integer NOT NULL,
    site_id integer,
    firstname character varying(128),
    surname character varying(128),
    email text,
    username text,
    title integer,
    organisation integer,
    freetext1 text,
    freetext2 text,
    password character varying(128),
    pwchanged timestamp without time zone,
    resetpw character varying(32),
    deleted timestamp without time zone,
    lastlogin timestamp without time zone,
    lastfail timestamp without time zone,
    failcount integer DEFAULT 0 NOT NULL,
    lastrecord bigint,
    lastview bigint,
    session_settings text,
    value text,
    account_request smallint DEFAULT 0,
    account_request_notes text,
    aup_accepted timestamp without time zone,
    limit_to_view bigint,
    stylesheet text
);


ALTER TABLE "user" OWNER TO postgres;

--
-- Name: user_graph; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE user_graph (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    graph_id integer NOT NULL
);


ALTER TABLE user_graph OWNER TO postgres;

--
-- Name: user_graph_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_graph_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_graph_id_seq OWNER TO postgres;

--
-- Name: user_graph_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE user_graph_id_seq OWNED BY user_graph.id;


--
-- Name: user_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE user_group (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE user_group OWNER TO postgres;

--
-- Name: user_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_group_id_seq OWNER TO postgres;

--
-- Name: user_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE user_group_id_seq OWNED BY user_group.id;


--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_id_seq OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE user_id_seq OWNED BY "user".id;


--
-- Name: user_lastrecord; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE user_lastrecord (
    id integer NOT NULL,
    record_id bigint NOT NULL,
    instance_id integer NOT NULL,
    user_id bigint NOT NULL
);


ALTER TABLE user_lastrecord OWNER TO postgres;

--
-- Name: user_lastrecord_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_lastrecord_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_lastrecord_id_seq OWNER TO postgres;

--
-- Name: user_lastrecord_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE user_lastrecord_id_seq OWNED BY user_lastrecord.id;


--
-- Name: user_permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE user_permission (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE user_permission OWNER TO postgres;

--
-- Name: user_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_permission_id_seq OWNER TO postgres;

--
-- Name: user_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE user_permission_id_seq OWNED BY user_permission.id;


--
-- Name: view; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE view (
    id integer NOT NULL,
    user_id bigint,
    group_id integer,
    name character varying(128),
    global smallint DEFAULT 0 NOT NULL,
    is_admin smallint DEFAULT 0 NOT NULL,
    is_limit_extra smallint DEFAULT 0 NOT NULL,
    filter text,
    instance_id integer
);


ALTER TABLE view OWNER TO postgres;

--
-- Name: view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE view_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE view_id_seq OWNER TO postgres;

--
-- Name: view_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE view_id_seq OWNED BY view.id;


--
-- Name: view_layout; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE view_layout (
    id integer NOT NULL,
    view_id bigint NOT NULL,
    layout_id integer NOT NULL,
    "order" integer
);


ALTER TABLE view_layout OWNER TO postgres;

--
-- Name: view_layout_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE view_layout_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE view_layout_id_seq OWNER TO postgres;

--
-- Name: view_layout_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE view_layout_id_seq OWNED BY view_layout.id;


--
-- Name: view_limit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE view_limit (
    id integer NOT NULL,
    view_id bigint NOT NULL,
    user_id bigint NOT NULL
);


ALTER TABLE view_limit OWNER TO postgres;

--
-- Name: view_limit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE view_limit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE view_limit_id_seq OWNER TO postgres;

--
-- Name: view_limit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE view_limit_id_seq OWNED BY view_limit.id;


--
-- Name: alert id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert ALTER COLUMN id SET DEFAULT nextval('alert_id_seq'::regclass);


--
-- Name: alert_cache id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_cache ALTER COLUMN id SET DEFAULT nextval('alert_cache_id_seq'::regclass);


--
-- Name: alert_send id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_send ALTER COLUMN id SET DEFAULT nextval('alert_send_id_seq'::regclass);


--
-- Name: audit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY audit ALTER COLUMN id SET DEFAULT nextval('audit_id_seq'::regclass);


--
-- Name: calc id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calc ALTER COLUMN id SET DEFAULT nextval('calc_id_seq'::regclass);


--
-- Name: calcval id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calcval ALTER COLUMN id SET DEFAULT nextval('calcval_id_seq'::regclass);


--
-- Name: current id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY current ALTER COLUMN id SET DEFAULT nextval('current_id_seq'::regclass);


--
-- Name: curval id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval ALTER COLUMN id SET DEFAULT nextval('curval_id_seq'::regclass);


--
-- Name: curval_fields id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval_fields ALTER COLUMN id SET DEFAULT nextval('curval_fields_id_seq'::regclass);


--
-- Name: date id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY date ALTER COLUMN id SET DEFAULT nextval('date_id_seq'::regclass);


--
-- Name: daterange id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY daterange ALTER COLUMN id SET DEFAULT nextval('daterange_id_seq'::regclass);


--
-- Name: dbix_class_deploymenthandler_versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dbix_class_deploymenthandler_versions ALTER COLUMN id SET DEFAULT nextval('dbix_class_deploymenthandler_versions_id_seq'::regclass);


--
-- Name: enum id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enum ALTER COLUMN id SET DEFAULT nextval('enum_id_seq'::regclass);


--
-- Name: enumval id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enumval ALTER COLUMN id SET DEFAULT nextval('enumval_id_seq'::regclass);


--
-- Name: file id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file ALTER COLUMN id SET DEFAULT nextval('file_id_seq'::regclass);


--
-- Name: file_option id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_option ALTER COLUMN id SET DEFAULT nextval('file_option_id_seq'::regclass);


--
-- Name: fileval id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY fileval ALTER COLUMN id SET DEFAULT nextval('fileval_id_seq'::regclass);


--
-- Name: filter id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY filter ALTER COLUMN id SET DEFAULT nextval('filter_id_seq'::regclass);


--
-- Name: graph id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph ALTER COLUMN id SET DEFAULT nextval('graph_id_seq'::regclass);


--
-- Name: graph_color id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph_color ALTER COLUMN id SET DEFAULT nextval('graph_color_id_seq'::regclass);


--
-- Name: group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "group" ALTER COLUMN id SET DEFAULT nextval('group_id_seq'::regclass);


--
-- Name: import id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY import ALTER COLUMN id SET DEFAULT nextval('import_id_seq'::regclass);


--
-- Name: import_row id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY import_row ALTER COLUMN id SET DEFAULT nextval('import_row_id_seq'::regclass);


--
-- Name: instance id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance ALTER COLUMN id SET DEFAULT nextval('instance_id_seq'::regclass);


--
-- Name: instance_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance_group ALTER COLUMN id SET DEFAULT nextval('instance_group_id_seq'::regclass);


--
-- Name: intgr id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intgr ALTER COLUMN id SET DEFAULT nextval('intgr_id_seq'::regclass);


--
-- Name: layout id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout ALTER COLUMN id SET DEFAULT nextval('layout_id_seq'::regclass);


--
-- Name: layout_depend id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_depend ALTER COLUMN id SET DEFAULT nextval('layout_depend_id_seq'::regclass);


--
-- Name: layout_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_group ALTER COLUMN id SET DEFAULT nextval('layout_group_id_seq'::regclass);


--
-- Name: metric id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric ALTER COLUMN id SET DEFAULT nextval('metric_id_seq'::regclass);


--
-- Name: metric_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_group ALTER COLUMN id SET DEFAULT nextval('metric_group_id_seq'::regclass);


--
-- Name: oauthclient id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY oauthclient ALTER COLUMN id SET DEFAULT nextval('oauthclient_id_seq'::regclass);


--
-- Name: organisation id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY organisation ALTER COLUMN id SET DEFAULT nextval('organisation_id_seq'::regclass);


--
-- Name: permission id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY permission ALTER COLUMN id SET DEFAULT nextval('permission_id_seq'::regclass);


--
-- Name: person id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);


--
-- Name: rag id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rag ALTER COLUMN id SET DEFAULT nextval('rag_id_seq'::regclass);


--
-- Name: ragval id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ragval ALTER COLUMN id SET DEFAULT nextval('ragval_id_seq'::regclass);


--
-- Name: record id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY record ALTER COLUMN id SET DEFAULT nextval('record_id_seq'::regclass);


--
-- Name: site id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY site ALTER COLUMN id SET DEFAULT nextval('site_id_seq'::regclass);


--
-- Name: sort id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sort ALTER COLUMN id SET DEFAULT nextval('sort_id_seq'::regclass);


--
-- Name: string id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY string ALTER COLUMN id SET DEFAULT nextval('string_id_seq'::regclass);


--
-- Name: title id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY title ALTER COLUMN id SET DEFAULT nextval('title_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user" ALTER COLUMN id SET DEFAULT nextval('user_id_seq'::regclass);


--
-- Name: user_graph id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_graph ALTER COLUMN id SET DEFAULT nextval('user_graph_id_seq'::regclass);


--
-- Name: user_group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_group ALTER COLUMN id SET DEFAULT nextval('user_group_id_seq'::regclass);


--
-- Name: user_lastrecord id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_lastrecord ALTER COLUMN id SET DEFAULT nextval('user_lastrecord_id_seq'::regclass);


--
-- Name: user_permission id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_permission ALTER COLUMN id SET DEFAULT nextval('user_permission_id_seq'::regclass);


--
-- Name: view id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view ALTER COLUMN id SET DEFAULT nextval('view_id_seq'::regclass);


--
-- Name: view_layout id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_layout ALTER COLUMN id SET DEFAULT nextval('view_layout_id_seq'::regclass);


--
-- Name: view_limit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_limit ALTER COLUMN id SET DEFAULT nextval('view_limit_id_seq'::regclass);


--
-- Data for Name: alert; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY alert (id, view_id, user_id, frequency) FROM stdin;
\.


--
-- Data for Name: alert_cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY alert_cache (id, layout_id, view_id, current_id, user_id) FROM stdin;
\.


--
-- Name: alert_cache_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('alert_cache_id_seq', 1, false);


--
-- Name: alert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('alert_id_seq', 1, false);


--
-- Data for Name: alert_send; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY alert_send (id, layout_id, alert_id, current_id, status) FROM stdin;
\.


--
-- Name: alert_send_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('alert_send_id_seq', 1, false);


--
-- Data for Name: audit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY audit (id, site_id, user_id, type, datetime, method, url, description) FROM stdin;
1	1	\N	login_change	2018-05-31 07:23:01	\N	\N	Password reset request for a.beverley@ctrlo.com
2	1	\N	login_change	2018-05-31 07:27:16	\N	\N	Password reset request for a.beverley@ctrlo.com
3	1	1	login_change	2018-05-31 07:28:02	\N	\N	Password reset performed for user ID 1
4	1	1	login_success	2018-05-31 07:28:11	\N	\N	Successful login by username a.beverley@ctrlo.com
5	1	1	user_action	2018-05-31 07:28:11	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
6	1	1	user_action	2018-05-31 07:29:19	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
7	1	1	user_action	2018-05-31 07:29:30	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
8	1	1	user_action	2018-05-31 07:31:09	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
9	1	1	user_action	2018-05-31 07:31:17	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
10	1	1	user_action	2018-05-31 07:32:16	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
11	1	1	user_action	2018-05-31 07:33:19	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
12	1	1	user_action	2018-05-31 07:33:23	GET	/user/	User "a.beverley@ctrlo.com" made "GET" request to "/user/"
13	1	1	user_action	2018-05-31 07:33:25	GET	/user/1	User "a.beverley@ctrlo.com" made "GET" request to "/user/1"
14	1	1	user_action	2018-05-31 07:33:31	POST	/user/1	User "a.beverley@ctrlo.com" made "POST" request to "/user/1"
15	1	1	login_change	2018-05-31 07:33:31	\N	\N	User updated: ID 1, username: a.beverley@ctrlo.com, groups: , permissions:
16	1	1	user_action	2018-05-31 07:33:31	GET	/user	User "a.beverley@ctrlo.com" made "GET" request to "/user"
17	1	1	user_action	2018-05-31 07:33:40	GET	/user	User "a.beverley@ctrlo.com" made "GET" request to "/user"
18	1	1	user_action	2018-05-31 07:33:44	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
19	1	1	user_action	2018-05-31 07:36:36	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
20	1	1	user_action	2018-05-31 07:36:40	GET	/user/	User "a.beverley@ctrlo.com" made "GET" request to "/user/"
21	1	1	user_action	2018-05-31 07:36:44	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
22	1	1	user_action	2018-05-31 07:36:45	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
23	1	1	user_action	2018-05-31 07:36:48	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
24	1	1	user_action	2018-05-31 07:36:48	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
25	1	1	user_action	2018-05-31 07:36:59	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
26	1	1	user_action	2018-05-31 07:37:04	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
27	1	1	user_action	2018-05-31 07:37:13	GET	/group	User "a.beverley@ctrlo.com" made "GET" request to "/group"
28	1	1	user_action	2018-05-31 07:37:18	GET	/user	User "a.beverley@ctrlo.com" made "GET" request to "/user"
29	1	1	user_action	2018-05-31 07:37:22	GET	/group/	User "a.beverley@ctrlo.com" made "GET" request to "/group/"
30	1	1	user_action	2018-05-31 07:38:16	GET	/group/	User "a.beverley@ctrlo.com" made "GET" request to "/group/"
31	1	1	user_action	2018-05-31 07:38:17	GET	/group/0	User "a.beverley@ctrlo.com" made "GET" request to "/group/0"
32	1	1	user_action	2018-05-31 07:38:23	POST	/group/0	User "a.beverley@ctrlo.com" made "POST" request to "/group/0"
33	1	1	user_action	2018-05-31 07:38:23	GET	/group	User "a.beverley@ctrlo.com" made "GET" request to "/group"
34	1	1	user_action	2018-05-31 07:38:29	GET	/user/	User "a.beverley@ctrlo.com" made "GET" request to "/user/"
35	1	1	user_action	2018-05-31 07:38:30	GET	/user/1	User "a.beverley@ctrlo.com" made "GET" request to "/user/1"
36	1	1	user_action	2018-05-31 07:38:50	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
37	1	1	user_action	2018-05-31 07:38:52	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
38	1	1	user_action	2018-05-31 07:39:04	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
39	1	1	user_action	2018-05-31 07:40:40	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
40	1	1	user_action	2018-05-31 07:40:42	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
41	1	1	user_action	2018-05-31 07:40:44	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
42	1	1	user_action	2018-05-31 07:40:52	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
43	1	1	user_action	2018-05-31 07:40:54	GET	/layout/1	User "a.beverley@ctrlo.com" made "GET" request to "/layout/1"
44	1	1	user_action	2018-05-31 07:40:54	GET	/tree1527752548122/1	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527752548122/1" with query "&id=%23"
45	1	1	user_action	2018-05-31 07:40:58	GET	/user/	User "a.beverley@ctrlo.com" made "GET" request to "/user/"
46	1	1	user_action	2018-05-31 07:40:59	GET	/user/1	User "a.beverley@ctrlo.com" made "GET" request to "/user/1"
47	1	1	user_action	2018-05-31 07:41:02	POST	/user/1	User "a.beverley@ctrlo.com" made "POST" request to "/user/1"
48	1	1	login_change	2018-05-31 07:41:02	\N	\N	User updated: ID 1, username: a.beverley@ctrlo.com, groups: 1, permissions: superadmin, useradmin
49	1	1	user_action	2018-05-31 07:41:02	GET	/user	User "a.beverley@ctrlo.com" made "GET" request to "/user"
50	1	1	user_action	2018-05-31 07:41:04	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
51	1	1	user_action	2018-05-31 07:41:06	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
52	1	1	user_action	2018-05-31 07:41:09	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
53	1	1	user_action	2018-05-31 07:41:22	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
54	1	1	user_action	2018-05-31 07:41:22	GET	/layout/2	User "a.beverley@ctrlo.com" made "GET" request to "/layout/2"
55	1	1	user_action	2018-05-31 07:41:23	GET	/tree1527752576738/2	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527752576738/2" with query "&id=%23"
56	1	1	user_action	2018-05-31 07:41:31	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
57	1	1	user_action	2018-05-31 07:41:32	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
58	1	1	user_action	2018-05-31 07:42:04	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
59	1	1	user_action	2018-05-31 07:42:04	GET	/layout/3	User "a.beverley@ctrlo.com" made "GET" request to "/layout/3"
60	1	1	user_action	2018-05-31 07:42:05	GET	/tree1527752618740/3	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527752618740/3" with query "&id=%23"
61	1	1	user_action	2018-05-31 07:42:14	POST	/layout/3	User "a.beverley@ctrlo.com" made "POST" request to "/layout/3"
62	1	1	user_action	2018-05-31 07:42:14	GET	/layout/3	User "a.beverley@ctrlo.com" made "GET" request to "/layout/3"
63	1	1	user_action	2018-05-31 07:42:15	GET	/tree1527752628498/3	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527752628498/3" with query "&id=%23"
64	1	1	user_action	2018-05-31 07:42:15	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
65	1	1	user_action	2018-05-31 07:42:44	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
66	1	1	user_action	2018-05-31 07:42:46	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
67	1	1	user_action	2018-05-31 07:43:33	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
68	1	1	user_action	2018-05-31 07:43:33	GET	/layout/4	User "a.beverley@ctrlo.com" made "GET" request to "/layout/4"
69	1	1	user_action	2018-05-31 07:43:34	GET	/tree1527752707400/4	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527752707400/4" with query "&id=%23"
70	1	1	user_action	2018-05-31 07:43:35	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
71	1	1	user_action	2018-05-31 07:43:40	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
72	1	1	user_action	2018-05-31 07:43:45	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
73	1	1	user_action	2018-05-31 07:43:47	GET	/layout/4	User "a.beverley@ctrlo.com" made "GET" request to "/layout/4"
74	1	1	user_action	2018-05-31 07:43:48	GET	/tree1527752721314/4	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527752721314/4" with query "&id=%23"
75	1	1	user_action	2018-05-31 07:43:52	POST	/layout/4	User "a.beverley@ctrlo.com" made "POST" request to "/layout/4"
76	1	1	user_action	2018-05-31 07:43:52	GET	/layout/4	User "a.beverley@ctrlo.com" made "GET" request to "/layout/4"
77	1	1	user_action	2018-05-31 07:43:53	GET	/tree1527752726444/4	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527752726444/4" with query "&id=%23"
78	1	1	user_action	2018-05-31 07:43:54	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
79	1	1	user_action	2018-05-31 07:43:56	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
80	1	1	user_action	2018-05-31 07:44:08	POST	/edit/	User "a.beverley@ctrlo.com" made "POST" request to "/edit/"
81	1	1	user_action	2018-05-31 07:44:09	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
82	1	\N	login_change	2018-05-31 07:48:56	\N	\N	Password reset request for a.beverley@ctrlo.com
83	1	1	login_change	2018-05-31 07:49:05	\N	\N	Password reset performed for user ID 1
84	1	1	login_success	2018-05-31 07:49:27	\N	\N	Successful login by username a.beverley@ctrlo.com
85	1	1	user_action	2018-05-31 07:49:27	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
86	1	1	user_action	2018-05-31 07:49:30	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
87	1	1	user_action	2018-05-31 07:49:53	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
88	1	1	user_action	2018-05-31 07:49:54	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
89	1	1	user_action	2018-05-31 07:50:17	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
90	1	1	user_action	2018-05-31 07:50:18	GET	/layout/5	User "a.beverley@ctrlo.com" made "GET" request to "/layout/5"
91	1	1	user_action	2018-05-31 07:50:19	GET	/tree1527753019098/5	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527753019098/5" with query "&id=%23"
92	1	1	user_action	2018-05-31 07:50:19	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
93	1	1	user_action	2018-05-31 07:50:22	GET	/edit/1	User "a.beverley@ctrlo.com" made "GET" request to "/edit/1"
94	1	1	user_action	2018-05-31 07:50:31	POST	/edit/1	User "a.beverley@ctrlo.com" made "POST" request to "/edit/1"
95	1	1	user_action	2018-05-31 07:50:31	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
96	1	1	user_action	2018-05-31 07:50:34	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data" with query "viewtype=timeline"
97	1	1	user_action	2018-05-31 07:50:45	GET	/graph/	User "a.beverley@ctrlo.com" made "GET" request to "/graph/"
98	1	1	user_action	2018-05-31 07:50:46	GET	/graph/0	User "a.beverley@ctrlo.com" made "GET" request to "/graph/0"
99	1	1	user_action	2018-05-31 07:51:00	POST	/graph/0	User "a.beverley@ctrlo.com" made "POST" request to "/graph/0"
100	1	1	user_action	2018-05-31 07:51:00	GET	/graph	User "a.beverley@ctrlo.com" made "GET" request to "/graph"
101	1	1	user_action	2018-05-31 07:51:02	GET	/account/graph	User "a.beverley@ctrlo.com" made "GET" request to "/account/graph"
102	1	1	user_action	2018-05-31 07:51:05	POST	/account/graph	User "a.beverley@ctrlo.com" made "POST" request to "/account/graph"
103	1	1	user_action	2018-05-31 07:51:05	GET	/account/graph	User "a.beverley@ctrlo.com" made "GET" request to "/account/graph"
104	1	1	user_action	2018-05-31 07:51:07	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
105	1	1	user_action	2018-05-31 07:51:09	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data" with query "viewtype=graph"
106	1	1	user_action	2018-05-31 07:51:10	GET	/data_graph/1/1527753071007	User "a.beverley@ctrlo.com" made "GET" request to "/data_graph/1/1527753071007"
107	1	1	user_action	2018-05-31 07:51:15	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data" with query "viewtype=table"
108	1	1	user_action	2018-05-31 07:58:06	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
109	1	1	user_action	2018-05-31 07:58:08	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
110	1	1	user_action	2018-05-31 07:58:24	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
111	1	1	user_action	2018-05-31 07:58:25	GET	/layout/6	User "a.beverley@ctrlo.com" made "GET" request to "/layout/6"
112	1	1	user_action	2018-05-31 07:58:26	GET	/tree1527753506171/6	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527753506171/6" with query "&id=%23"
116	1	1	user_action	2018-05-31 07:58:51	GET	/tree1527753531189/6	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527753531189/6" with query "&id=%23"
119	1	1	user_action	2018-05-31 07:59:04	GET	/tree1527753544191/6	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527753544191/6" with query "ids=&id=%23"
113	1	1	user_action	2018-05-31 07:58:47	POST	/tree/6	User "a.beverley@ctrlo.com" made "POST" request to "/tree/6"
117	1	1	user_action	2018-05-31 07:58:57	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
114	1	1	user_action	2018-05-31 07:58:49	POST	/layout/6	User "a.beverley@ctrlo.com" made "POST" request to "/layout/6"
115	1	1	user_action	2018-05-31 07:58:49	GET	/layout/6	User "a.beverley@ctrlo.com" made "GET" request to "/layout/6"
118	1	1	user_action	2018-05-31 07:59:02	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
120	1	1	user_action	2018-05-31 08:05:38	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
121	1	1	user_action	2018-05-31 08:06:05	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
122	1	1	user_action	2018-05-31 08:06:06	GET	/tree1527753966792/6	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527753966792/6" with query "ids=&id=%23"
123	1	1	user_action	2018-05-31 08:06:32	POST	/edit/	User "a.beverley@ctrlo.com" made "POST" request to "/edit/"
124	1	1	user_action	2018-05-31 08:06:32	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
125	1	1	user_action	2018-05-31 08:06:52	GET	/user/	User "a.beverley@ctrlo.com" made "GET" request to "/user/"
126	1	1	user_action	2018-05-31 08:06:54	GET	/user/0	User "a.beverley@ctrlo.com" made "GET" request to "/user/0"
127	1	1	user_action	2018-05-31 08:07:15	POST	/user/0	User "a.beverley@ctrlo.com" made "POST" request to "/user/0"
128	1	1	login_change	2018-05-31 08:07:16	\N	\N	User created, id: 2, username: gads@ctrlo.local
129	1	1	login_change	2018-05-31 08:07:16	\N	\N	User updated: ID 2, username: gads@ctrlo.local, groups: 1, permissions: superadmin, useradmin
130	1	1	user_action	2018-05-31 08:07:17	GET	/user	User "a.beverley@ctrlo.com" made "GET" request to "/user"
131	1	2	login_change	2018-05-31 08:07:30	\N	\N	Password reset performed for user ID 2
132	1	1	user_action	2018-05-31 08:07:34	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
133	1	2	login_success	2018-05-31 08:07:45	\N	\N	Successful login by username gads@ctrlo.local
134	1	2	user_action	2018-05-31 08:07:45	GET	/	User "gads@ctrlo.local" made "GET" request to "/"
135	1	2	user_action	2018-05-31 08:07:53	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
136	1	2	user_action	2018-05-31 08:08:09	GET	/edit/	User "gads@ctrlo.local" made "GET" request to "/edit/"
137	1	2	user_action	2018-05-31 08:08:09	GET	/tree1527754089462/6	User "gads@ctrlo.local" made "GET" request to "/tree1527754089462/6" with query "ids=&id=%23"
138	1	1	user_action	2018-05-31 08:08:27	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
139	1	1	user_action	2018-05-31 08:08:32	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
140	1	1	user_action	2018-05-31 08:08:36	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
141	1	1	user_action	2018-05-31 08:08:40	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
142	1	1	user_action	2018-05-31 08:08:42	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
143	1	1	user_action	2018-05-31 08:08:47	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
144	1	2	user_action	2018-05-31 08:08:49	POST	/edit/	User "gads@ctrlo.local" made "POST" request to "/edit/"
145	1	2	user_action	2018-05-31 08:08:49	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
146	1	1	user_action	2018-05-31 08:08:49	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
147	1	1	user_action	2018-05-31 08:08:52	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
148	1	1	user_action	2018-05-31 08:09:27	GET	/view/0	User "a.beverley@ctrlo.com" made "GET" request to "/view/0"
149	1	2	user_action	2018-05-31 08:09:28	GET	/view/0	User "gads@ctrlo.local" made "GET" request to "/view/0"
150	1	1	user_action	2018-05-31 08:09:47	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
151	1	2	user_action	2018-05-31 08:09:48	POST	/view/0	User "gads@ctrlo.local" made "POST" request to "/view/0"
152	1	2	user_action	2018-05-31 08:09:49	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
153	1	1	user_action	2018-05-31 08:09:53	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
154	1	1	user_action	2018-05-31 08:09:58	GET	/view/0	User "a.beverley@ctrlo.com" made "GET" request to "/view/0"
155	1	2	user_action	2018-05-31 08:09:59	GET	/view/1	User "gads@ctrlo.local" made "GET" request to "/view/1"
156	1	2	user_action	2018-05-31 08:10:16	GET	/match/layout/3	User "gads@ctrlo.local" made "GET" request to "/match/layout/3" with query "q=h&oi=1"
157	1	2	user_action	2018-05-31 08:10:16	GET	/match/layout/3	User "gads@ctrlo.local" made "GET" request to "/match/layout/3" with query "q=ho&oi=1"
158	1	2	user_action	2018-05-31 08:10:16	GET	/match/layout/3	User "gads@ctrlo.local" made "GET" request to "/match/layout/3" with query "q=h&oi=1"
159	1	2	user_action	2018-05-31 08:10:17	GET	/match/layout/3	User "gads@ctrlo.local" made "GET" request to "/match/layout/3" with query "q=H&oi=1"
160	1	2	user_action	2018-05-31 08:10:17	GET	/match/layout/3	User "gads@ctrlo.local" made "GET" request to "/match/layout/3" with query "q=Ho&oi=1"
161	1	2	user_action	2018-05-31 08:10:17	GET	/match/layout/3	User "gads@ctrlo.local" made "GET" request to "/match/layout/3" with query "q=Hol&oi=1"
162	1	2	user_action	2018-05-31 08:10:17	GET	/match/layout/3	User "gads@ctrlo.local" made "GET" request to "/match/layout/3" with query "q=Holl&oi=1"
163	1	2	user_action	2018-05-31 08:10:23	POST	/view/1	User "gads@ctrlo.local" made "POST" request to "/view/1"
164	1	2	user_action	2018-05-31 08:10:23	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
165	1	1	user_action	2018-05-31 08:10:27	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
166	1	2	user_action	2018-05-31 08:10:29	GET	/view/1	User "gads@ctrlo.local" made "GET" request to "/view/1"
167	1	2	user_action	2018-05-31 08:10:39	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
168	1	1	user_action	2018-05-31 08:10:41	GET	/view/0	User "a.beverley@ctrlo.com" made "GET" request to "/view/0"
169	1	1	user_action	2018-05-31 08:10:53	POST	/view/0	User "a.beverley@ctrlo.com" made "POST" request to "/view/0"
170	1	1	user_action	2018-05-31 08:10:54	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
171	1	2	user_action	2018-05-31 08:12:37	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
172	1	2	user_action	2018-05-31 08:12:41	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "view=2"
173	1	2	user_action	2018-05-31 08:13:06	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=timeline"
177	1	1	user_action	2018-05-31 08:14:20	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data" with query "viewtype=graph"
181	1	2	user_action	2018-05-31 08:14:32	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "view=2"
186	1	2	user_action	2018-05-31 08:14:59	POST	/account/graph	User "gads@ctrlo.local" made "POST" request to "/account/graph"
174	1	1	user_action	2018-05-31 08:13:08	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data" with query "viewtype=timeline"
178	1	1	user_action	2018-05-31 08:14:21	GET	/data_graph/1/1527754461716	User "a.beverley@ctrlo.com" made "GET" request to "/data_graph/1/1527754461716"
182	1	2	user_action	2018-05-31 08:14:42	GET	/account/graph	User "gads@ctrlo.local" made "GET" request to "/account/graph"
187	1	2	user_action	2018-05-31 08:14:59	GET	/account/graph	User "gads@ctrlo.local" made "GET" request to "/account/graph"
175	1	2	user_action	2018-05-31 08:13:44	POST	/data	User "gads@ctrlo.local" made "POST" request to "/data" with query "viewtype=timeline"
179	1	2	user_action	2018-05-31 08:14:23	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=graph"
184	1	2	user_action	2018-05-31 08:14:50	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
189	1	2	user_action	2018-05-31 08:15:02	GET	/data_graph/1/1527754502696	User "gads@ctrlo.local" made "GET" request to "/data_graph/1/1527754502696"
176	1	2	user_action	2018-05-31 08:14:15	POST	/data	User "gads@ctrlo.local" made "POST" request to "/data" with query "viewtype=timeline"
180	1	2	user_action	2018-05-31 08:14:25	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=graph"
185	1	2	user_action	2018-05-31 08:14:54	GET	/account/graph	User "gads@ctrlo.local" made "GET" request to "/account/graph"
183	1	2	user_action	2018-05-31 08:14:48	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
188	1	2	user_action	2018-05-31 08:15:02	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
190	1	2	user_action	2018-05-31 08:15:22	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=calendar"
191	1	2	user_action	2018-05-31 08:15:22	GET	/data_calendar/1527754522962	User "gads@ctrlo.local" made "GET" request to "/data_calendar/1527754522962" with query "from=1525125600000&to=1527804000000"
192	1	2	user_action	2018-05-31 08:15:40	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=timeline"
193	1	1	user_action	2018-05-31 08:16:00	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data" with query "viewtype=table"
194	1	2	user_action	2018-05-31 08:16:03	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=table"
195	1	1	user_action	2018-05-31 08:16:21	GET	/edit/1	User "a.beverley@ctrlo.com" made "GET" request to "/edit/1"
196	1	1	user_action	2018-05-31 08:16:22	GET	/tree1527754582502/6	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527754582502/6" with query "ids=&id=%23"
197	1	2	user_action	2018-05-31 08:16:25	GET	/edit/1	User "gads@ctrlo.local" made "GET" request to "/edit/1"
198	1	2	user_action	2018-05-31 08:16:25	GET	/tree1527754585865/6	User "gads@ctrlo.local" made "GET" request to "/tree1527754585865/6" with query "ids=&id=%23"
199	1	1	user_action	2018-05-31 08:23:48	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
200	1	2	user_action	2018-05-31 08:23:55	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
201	1	2	user_action	2018-05-31 08:27:45	GET	/layout/	User "gads@ctrlo.local" made "GET" request to "/layout/"
202	1	1	user_action	2018-05-31 08:27:45	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
203	1	1	user_action	2018-05-31 08:27:54	GET	/layout/1	User "a.beverley@ctrlo.com" made "GET" request to "/layout/1"
204	1	1	user_action	2018-05-31 08:27:55	GET	/tree1527755275640/1	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527755275640/1" with query "&id=%23"
205	1	2	user_action	2018-05-31 08:27:55	GET	/layout/1	User "gads@ctrlo.local" made "GET" request to "/layout/1"
206	1	2	user_action	2018-05-31 08:27:56	GET	/tree1527755276008/1	User "gads@ctrlo.local" made "GET" request to "/tree1527755276008/1" with query "&id=%23"
207	1	1	user_action	2018-05-31 08:29:41	GET	/layout/1	User "a.beverley@ctrlo.com" made "GET" request to "/layout/1"
208	1	1	user_action	2018-05-31 08:29:42	GET	/tree1527755382445/1	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527755382445/1" with query "&id=%23"
209	1	2	user_action	2018-05-31 08:29:53	GET	/group/	User "gads@ctrlo.local" made "GET" request to "/group/"
210	1	2	user_action	2018-05-31 08:29:59	GET	/group/0	User "gads@ctrlo.local" made "GET" request to "/group/0"
211	1	2	user_action	2018-05-31 08:30:06	POST	/group/0	User "gads@ctrlo.local" made "POST" request to "/group/0"
212	1	2	user_action	2018-05-31 08:30:06	GET	/group	User "gads@ctrlo.local" made "GET" request to "/group"
213	1	2	user_action	2018-05-31 08:30:17	GET	/layout/	User "gads@ctrlo.local" made "GET" request to "/layout/"
214	1	2	user_action	2018-05-31 08:30:19	GET	/layout/1	User "gads@ctrlo.local" made "GET" request to "/layout/1"
215	1	2	user_action	2018-05-31 08:30:19	GET	/tree1527755419308/1	User "gads@ctrlo.local" made "GET" request to "/tree1527755419308/1" with query "&id=%23"
216	1	1	user_action	2018-05-31 08:31:43	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
217	1	2	user_action	2018-05-31 08:31:48	GET	/layout/	User "gads@ctrlo.local" made "GET" request to "/layout/"
218	1	2	user_action	2018-05-31 08:31:50	GET	/layout/0	User "gads@ctrlo.local" made "GET" request to "/layout/0"
219	1	1	user_action	2018-05-31 08:31:51	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
220	1	2	user_action	2018-05-31 08:32:52	POST	/layout/0	User "gads@ctrlo.local" made "POST" request to "/layout/0"
221	1	2	user_action	2018-05-31 08:32:52	GET	/layout/7	User "gads@ctrlo.local" made "GET" request to "/layout/7"
222	1	2	user_action	2018-05-31 08:32:53	GET	/tree1527755573161/7	User "gads@ctrlo.local" made "GET" request to "/tree1527755573161/7" with query "&id=%23"
223	1	2	user_action	2018-05-31 08:33:00	POST	/layout/7	User "gads@ctrlo.local" made "POST" request to "/layout/7"
224	1	2	user_action	2018-05-31 08:33:00	GET	/layout/7	User "gads@ctrlo.local" made "GET" request to "/layout/7"
225	1	2	user_action	2018-05-31 08:33:00	GET	/tree1527755580805/7	User "gads@ctrlo.local" made "GET" request to "/tree1527755580805/7" with query "&id=%23"
226	1	2	user_action	2018-05-31 08:33:09	GET	/layout/	User "gads@ctrlo.local" made "GET" request to "/layout/"
227	1	2	user_action	2018-05-31 08:33:14	GET	/layout/7	User "gads@ctrlo.local" made "GET" request to "/layout/7"
228	1	2	user_action	2018-05-31 08:33:14	GET	/tree1527755594265/7	User "gads@ctrlo.local" made "GET" request to "/tree1527755594265/7" with query "&id=%23"
229	1	2	user_action	2018-05-31 08:33:18	POST	/layout/7	User "gads@ctrlo.local" made "POST" request to "/layout/7"
230	1	2	user_action	2018-05-31 08:33:19	GET	/layout/7	User "gads@ctrlo.local" made "GET" request to "/layout/7"
231	1	2	user_action	2018-05-31 08:33:19	GET	/tree1527755599311/7	User "gads@ctrlo.local" made "GET" request to "/tree1527755599311/7" with query "&id=%23"
232	1	2	user_action	2018-05-31 08:35:34	GET	/	User "gads@ctrlo.local" made "GET" request to "/"
233	1	2	user_action	2018-05-31 08:35:35	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
234	1	2	user_action	2018-05-31 08:35:37	GET	/edit/1	User "gads@ctrlo.local" made "GET" request to "/edit/1"
235	1	2	user_action	2018-05-31 08:35:37	GET	/tree1527755737961/6	User "gads@ctrlo.local" made "GET" request to "/tree1527755737961/6" with query "ids=&id=%23"
236	1	1	user_action	2018-05-31 08:35:38	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
237	1	1	user_action	2018-05-31 08:35:41	GET	/edit/1	User "a.beverley@ctrlo.com" made "GET" request to "/edit/1"
238	1	1	user_action	2018-05-31 08:35:43	GET	/tree1527755743281/6	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527755743281/6" with query "ids=&id=%23"
239	1	2	user_action	2018-05-31 08:48:21	GET	/approval/	User "gads@ctrlo.local" made "GET" request to "/approval/"
244	1	2	user_action	2018-05-31 08:48:54	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=timeline"
253	1	1	user_action	2018-05-31 21:37:20	POST	/table/0	User "a.beverley@ctrlo.com" made "POST" request to "/table/0"
256	1	1	user_action	2018-05-31 21:37:31	POST	/table/1	User "a.beverley@ctrlo.com" made "POST" request to "/table/1"
240	1	2	user_action	2018-05-31 08:48:22	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
245	1	2	user_action	2018-05-31 08:54:57	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data"
251	1	1	user_action	2018-05-31 21:37:00	GET	/table/	User "a.beverley@ctrlo.com" made "GET" request to "/table/"
254	1	1	user_action	2018-05-31 21:37:20	GET	/table	User "a.beverley@ctrlo.com" made "GET" request to "/table"
257	1	1	user_action	2018-05-31 21:37:31	GET	/table	User "a.beverley@ctrlo.com" made "GET" request to "/table"
241	1	2	user_action	2018-05-31 08:48:29	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=graph"
246	1	2	user_action	2018-05-31 08:55:00	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=table"
242	1	2	user_action	2018-05-31 08:48:29	GET	/data_graph/1/1527756509784	User "gads@ctrlo.local" made "GET" request to "/data_graph/1/1527756509784"
247	1	2	user_action	2018-05-31 08:55:01	GET	/edit/2	User "gads@ctrlo.local" made "GET" request to "/edit/2"
249	1	1	login_success	2018-05-31 21:36:55	\N	\N	Successful login by username a.beverley@ctrlo.com
252	1	1	user_action	2018-05-31 21:37:02	GET	/table/0	User "a.beverley@ctrlo.com" made "GET" request to "/table/0"
255	1	1	user_action	2018-05-31 21:37:22	GET	/table/1	User "a.beverley@ctrlo.com" made "GET" request to "/table/1"
258	1	1	user_action	2018-05-31 21:37:33	GET	/table/1	User "a.beverley@ctrlo.com" made "GET" request to "/table/1"
243	1	2	user_action	2018-05-31 08:48:32	GET	/data	User "gads@ctrlo.local" made "GET" request to "/data" with query "viewtype=table"
248	1	2	user_action	2018-05-31 08:55:02	GET	/tree1527756902078/6	User "gads@ctrlo.local" made "GET" request to "/tree1527756902078/6" with query "ids=13&id=%23"
250	1	1	user_action	2018-05-31 21:36:55	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
259	1	1	user_action	2018-05-31 21:37:40	GET	/table/1	User "a.beverley@ctrlo.com" made "GET" request to "/table/1" with query "instance=2"
260	1	1	user_action	2018-05-31 21:37:42	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
261	1	1	user_action	2018-05-31 21:37:44	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
262	1	1	user_action	2018-05-31 21:38:01	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
263	1	1	user_action	2018-05-31 21:38:02	GET	/layout/8	User "a.beverley@ctrlo.com" made "GET" request to "/layout/8"
264	1	1	user_action	2018-05-31 21:38:02	GET	/tree1527802777354/8	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527802777354/8" with query "&id=%23"
265	1	1	user_action	2018-05-31 21:38:06	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
266	1	1	user_action	2018-05-31 21:38:08	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
267	1	1	user_action	2018-05-31 21:38:35	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
268	1	1	user_action	2018-05-31 21:38:36	GET	/layout/9	User "a.beverley@ctrlo.com" made "GET" request to "/layout/9"
269	1	1	user_action	2018-05-31 21:38:37	GET	/tree1527802811444/9	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527802811444/9" with query "&id=%23"
270	1	1	user_action	2018-05-31 21:38:38	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
271	1	1	user_action	2018-05-31 21:38:38	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
272	1	1	user_action	2018-05-31 21:39:10	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
273	1	1	user_action	2018-05-31 21:39:13	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
274	1	1	user_action	2018-05-31 21:40:16	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
275	1	1	user_action	2018-05-31 21:40:19	GET	/	User "a.beverley@ctrlo.com" made "GET" request to "/"
276	1	1	user_action	2018-05-31 21:40:21	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
277	1	1	user_action	2018-05-31 21:40:25	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
278	1	1	user_action	2018-05-31 21:40:36	POST	/edit/	User "a.beverley@ctrlo.com" made "POST" request to "/edit/"
279	1	1	user_action	2018-05-31 21:40:38	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
280	1	1	user_action	2018-05-31 21:40:40	GET	/edit/	User "a.beverley@ctrlo.com" made "GET" request to "/edit/"
281	1	1	user_action	2018-05-31 21:40:46	POST	/edit/	User "a.beverley@ctrlo.com" made "POST" request to "/edit/"
282	1	1	user_action	2018-05-31 21:40:47	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
283	1	1	user_action	2018-05-31 21:40:59	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
284	1	1	user_action	2018-05-31 21:41:00	GET	/layout/0	User "a.beverley@ctrlo.com" made "GET" request to "/layout/0"
285	1	1	user_action	2018-05-31 21:41:35	POST	/layout/0	User "a.beverley@ctrlo.com" made "POST" request to "/layout/0"
286	1	1	user_action	2018-05-31 21:41:36	GET	/layout/10	User "a.beverley@ctrlo.com" made "GET" request to "/layout/10"
287	1	1	user_action	2018-05-31 21:41:37	GET	/tree1527802991786/10	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527802991786/10" with query "&id=%23"
288	1	1	user_action	2018-05-31 21:41:38	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
289	1	1	user_action	2018-05-31 21:41:40	GET	/edit/4	User "a.beverley@ctrlo.com" made "GET" request to "/edit/4"
290	1	1	user_action	2018-05-31 21:41:46	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
291	1	1	user_action	2018-05-31 21:41:48	GET	/layout/10	User "a.beverley@ctrlo.com" made "GET" request to "/layout/10"
292	1	1	user_action	2018-05-31 21:41:49	GET	/tree1527803004124/10	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527803004124/10" with query "&id=%23"
293	1	1	user_action	2018-05-31 21:41:53	POST	/layout/10	User "a.beverley@ctrlo.com" made "POST" request to "/layout/10"
294	1	1	user_action	2018-05-31 21:41:53	GET	/layout/10	User "a.beverley@ctrlo.com" made "GET" request to "/layout/10"
295	1	1	user_action	2018-05-31 21:41:54	GET	/tree1527803008762/10	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527803008762/10" with query "&id=%23"
296	1	1	user_action	2018-05-31 21:41:55	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
297	1	1	user_action	2018-05-31 21:41:56	GET	/edit/4	User "a.beverley@ctrlo.com" made "GET" request to "/edit/4"
298	1	1	user_action	2018-05-31 21:42:01	POST	/edit/4	User "a.beverley@ctrlo.com" made "POST" request to "/edit/4"
299	1	1	user_action	2018-05-31 21:42:04	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
300	1	1	user_action	2018-05-31 21:42:07	GET	/layout/	User "a.beverley@ctrlo.com" made "GET" request to "/layout/"
301	1	1	user_action	2018-05-31 21:42:09	GET	/layout/9	User "a.beverley@ctrlo.com" made "GET" request to "/layout/9"
302	1	1	user_action	2018-05-31 21:42:09	GET	/tree1527803024510/9	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527803024510/9" with query "&id=%23"
303	1	1	user_action	2018-05-31 21:42:12	POST	/layout/9	User "a.beverley@ctrlo.com" made "POST" request to "/layout/9"
304	1	1	user_action	2018-05-31 21:42:12	GET	/layout/9	User "a.beverley@ctrlo.com" made "GET" request to "/layout/9"
305	1	1	user_action	2018-05-31 21:42:13	GET	/tree1527803027686/9	User "a.beverley@ctrlo.com" made "GET" request to "/tree1527803027686/9" with query "&id=%23"
306	1	1	user_action	2018-05-31 21:42:13	GET	/data	User "a.beverley@ctrlo.com" made "GET" request to "/data"
\.


--
-- Name: audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('audit_id_seq', 306, true);


--
-- Data for Name: calc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY calc (id, layout_id, calc, code, return_format, decimal_places) FROM stdin;
\.


--
-- Name: calc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('calc_id_seq', 1, false);


--
-- Data for Name: calcval; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY calcval (id, record_id, layout_id, value_text, value_int, value_date, value_numeric) FROM stdin;
\.


--
-- Name: calcval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('calcval_id_seq', 1, false);


--
-- Data for Name: current; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY current (id, parent_id, instance_id, linked_id, deleted, deletedby, serial) FROM stdin;
1	\N	1	\N	\N	\N	1
2	\N	1	\N	\N	\N	2
3	\N	1	\N	\N	\N	3
4	\N	2	\N	\N	\N	1
5	\N	2	\N	\N	\N	2
\.


--
-- Name: current_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('current_id_seq', 5, true);


--
-- Data for Name: curval; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY curval (id, record_id, layout_id, child_unique, value) FROM stdin;
1	5	9	0	1
2	6	9	0	3
3	7	10	0	1
4	7	10	0	3
5	7	9	0	1
\.


--
-- Data for Name: curval_fields; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY curval_fields (id, parent_id, child_id) FROM stdin;
1	9	1
2	9	2
3	10	1
4	10	2
\.


--
-- Name: curval_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('curval_fields_id_seq', 4, true);


--
-- Name: curval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('curval_id_seq', 5, true);


--
-- Data for Name: date; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY date (id, record_id, layout_id, child_unique, value) FROM stdin;
\.


--
-- Name: date_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('date_id_seq', 1, false);


--
-- Data for Name: daterange; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY daterange (id, record_id, layout_id, "from", "to", child_unique, value) FROM stdin;
1	2	5	2018-07-11	2018-07-27	0	11-07-2018 to 27-07-2018
2	3	5	2018-05-08	2018-05-24	0	08-05-2018 to 24-05-2018
3	4	5	2018-05-31	2018-06-16	0	31-05-2018 to 16-06-2018
\.


--
-- Name: daterange_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('daterange_id_seq', 3, true);


--
-- Data for Name: dbix_class_deploymenthandler_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY dbix_class_deploymenthandler_versions (id, version, ddl, upgrade_sql) FROM stdin;
1	40	CREATE TABLE "dbix_class_deploymenthandler_versions" ( "id" serial NOT NULL, "version" character varying(50) NOT NULL, "ddl" text, "upgrade_sql" text, PRIMARY KEY ("id"), CONSTRAINT "dbix_class_deploymenthandler_versions_version" UNIQUE ("version") )CREATE TABLE "alert" ( "id" serial NOT NULL, "view_id" bigint NOT NULL, "user_id" bigint NOT NULL, "frequency" integer DEFAULT 0 NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "alert_idx_user_id" on "alert" ("user_id")\nCREATE INDEX "alert_idx_view_id" on "alert" ("view_id")\nCREATE TABLE "alert_cache" ( "id" serial NOT NULL, "layout_id" integer NOT NULL, "view_id" bigint NOT NULL, "current_id" bigint NOT NULL, "user_id" bigint, PRIMARY KEY ("id") )\nCREATE INDEX "alert_cache_idx_current_id" on "alert_cache" ("current_id")\nCREATE INDEX "alert_cache_idx_layout_id" on "alert_cache" ("layout_id")\nCREATE INDEX "alert_cache_idx_user_id" on "alert_cache" ("user_id")\nCREATE INDEX "alert_cache_idx_view_id" on "alert_cache" ("view_id")\nCREATE TABLE "alert_send" ( "id" serial NOT NULL, "layout_id" integer, "alert_id" integer NOT NULL, "current_id" bigint NOT NULL, "status" character(7), PRIMARY KEY ("id"), CONSTRAINT "alert_send_all" UNIQUE ("layout_id", "alert_id", "current_id", "status") )\nCREATE INDEX "alert_send_idx_alert_id" on "alert_send" ("alert_id")\nCREATE INDEX "alert_send_idx_current_id" on "alert_send" ("current_id")\nCREATE INDEX "alert_send_idx_layout_id" on "alert_send" ("layout_id")\nCREATE TABLE "audit" ( "id" serial NOT NULL, "site_id" integer, "user_id" bigint, "type" character varying(45), "datetime" timestamp, "method" character varying(45), "url" text, "description" text, PRIMARY KEY ("id") )\nCREATE INDEX "audit_idx_site_id" on "audit" ("site_id")\nCREATE INDEX "audit_idx_user_id" on "audit" ("user_id")\nCREATE TABLE "calc" ( "id" serial NOT NULL, "layout_id" integer, "calc" text, "code" text, "return_format" character varying(45), "decimal_places" smallint, PRIMARY KEY ("id") )\nCREATE INDEX "calc_idx_layout_id" on "calc" ("layout_id")\nCREATE TABLE "calcval" ( "id" serial NOT NULL, "record_id" bigint NOT NULL, "layout_id" integer NOT NULL, "value_text" text, "value_int" bigint, "value_date" date, "value_numeric" numeric(20,5), PRIMARY KEY ("id"), CONSTRAINT "calcval_ux_record_layout" UNIQUE ("record_id", "layout_id") )\nCREATE INDEX "calcval_idx_layout_id" on "calcval" ("layout_id")\nCREATE INDEX "calcval_idx_record_id" on "calcval" ("record_id")\nCREATE INDEX "calcval_idx_value_text" on "calcval" ("value_text")\nCREATE INDEX "calcval_idx_value_numeric" on "calcval" ("value_numeric")\nCREATE INDEX "calcval_idx_value_int" on "calcval" ("value_int")\nCREATE INDEX "calcval_idx_value_date" on "calcval" ("value_date")\nCREATE TABLE "current" ( "id" serial NOT NULL, "parent_id" bigint, "instance_id" integer, "linked_id" bigint, "deleted" timestamp, "deletedby" bigint, PRIMARY KEY ("id") )\nCREATE INDEX "current_idx_deletedby" on "current" ("deletedby")\nCREATE INDEX "current_idx_instance_id" on "current" ("instance_id")\nCREATE INDEX "current_idx_linked_id" on "current" ("linked_id")\nCREATE INDEX "current_idx_parent_id" on "current" ("parent_id")\nCREATE TABLE "curval" ( "id" serial NOT NULL, "record_id" bigint, "layout_id" integer, "child_unique" smallint DEFAULT 0 NOT NULL, "value" bigint, PRIMARY KEY ("id") )\nCREATE INDEX "curval_idx_layout_id" on "curval" ("layout_id")\nCREATE INDEX "curval_idx_record_id" on "curval" ("record_id")\nCREATE INDEX "curval_idx_value" on "curval" ("value")\nCREATE TABLE "curval_fields" ( "id" serial NOT NULL, "parent_id" integer NOT NULL, "child_id" integer NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "curval_fields_idx_child_id" on "curval_fields" ("child_id")\nCREATE INDEX "curval_fields_idx_parent_id" on "curval_fields" ("parent_id")\nCREATE TABLE "date" ( "id" serial NOT NULL, "record_id" bigint NOT NULL, "layout_id" integer NOT NULL, "child_unique" smallint DEFAULT 0 NOT NULL, "value" date, PRIMARY KEY ("id") )\nCREATE INDEX "date_idx_layout_id" on "date" ("layout_id")\nCREATE INDEX "date_idx_record_id" on "date" ("record_id")\nCREATE INDEX "date_idx_value" on "date" ("value")\nCREATE TABLE "daterange" ( "id" serial NOT NULL, "record_id" bigint NOT NULL, "layout_id" integer NOT NULL, "from" date, "to" date, "child_unique" smallint DEFAULT 0 NOT NULL, "value" character varying(45), PRIMARY KEY ("id") )\nCREATE INDEX "daterange_idx_layout_id" on "daterange" ("layout_id")\nCREATE INDEX "daterange_idx_record_id" on "daterange" ("record_id")\nCREATE INDEX "daterange_idx_from" on "daterange" ("from")\nCREATE INDEX "daterange_idx_to" on "daterange" ("to")\nCREATE INDEX "daterange_idx_value" on "daterange" ("value")\nCREATE TABLE "enum" ( "id" serial NOT NULL, "record_id" bigint, "layout_id" integer, "child_unique" smallint DEFAULT 0 NOT NULL, "value" integer, PRIMARY KEY ("id") )\nCREATE INDEX "enum_idx_layout_id" on "enum" ("layout_id")\nCREATE INDEX "enum_idx_record_id" on "enum" ("record_id")\nCREATE INDEX "enum_idx_value" on "enum" ("value")\nCREATE TABLE "enumval" ( "id" serial NOT NULL, "value" text, "layout_id" integer, "deleted" smallint DEFAULT 0 NOT NULL, "parent" integer, PRIMARY KEY ("id") )\nCREATE INDEX "enumval_idx_layout_id" on "enumval" ("layout_id")\nCREATE INDEX "enumval_idx_parent" on "enumval" ("parent")\nCREATE INDEX "enumval_idx_value" on "enumval" ("value")\nCREATE TABLE "file" ( "id" serial NOT NULL, "record_id" bigint, "layout_id" integer, "child_unique" smallint DEFAULT 0 NOT NULL, "value" bigint, PRIMARY KEY ("id") )\nCREATE INDEX "file_idx_layout_id" on "file" ("layout_id")\nCREATE INDEX "file_idx_record_id" on "file" ("record_id")\nCREATE INDEX "file_idx_value" on "file" ("value")\nCREATE TABLE "file_option" ( "id" serial NOT NULL, "layout_id" integer NOT NULL, "filesize" integer, PRIMARY KEY ("id") )\nCREATE INDEX "file_option_idx_layout_id" on "file_option" ("layout_id")\nCREATE TABLE "fileval" ( "id" serial NOT NULL, "name" text, "mimetype" text, "content" bytea, PRIMARY KEY ("id") )\nCREATE INDEX "fileval_idx_name" on "fileval" ("name")\nCREATE TABLE "filter" ( "id" serial NOT NULL, "view_id" bigint NOT NULL, "layout_id" integer NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "filter_idx_layout_id" on "filter" ("layout_id")\nCREATE INDEX "filter_idx_view_id" on "filter" ("view_id")\nCREATE TABLE "graph" ( "id" serial NOT NULL, "title" text, "description" text, "y_axis" integer, "y_axis_stack" character varying(45), "y_axis_label" text, "x_axis" integer, "x_axis_grouping" character varying(45), "group_by" integer, "stackseries" smallint DEFAULT 0 NOT NULL, "as_percent" smallint DEFAULT 0 NOT NULL, "type" character varying(45), "metric_group" integer, "instance_id" integer, PRIMARY KEY ("id") )\nCREATE INDEX "graph_idx_group_by" on "graph" ("group_by")\nCREATE INDEX "graph_idx_instance_id" on "graph" ("instance_id")\nCREATE INDEX "graph_idx_metric_group" on "graph" ("metric_group")\nCREATE INDEX "graph_idx_x_axis" on "graph" ("x_axis")\nCREATE INDEX "graph_idx_y_axis" on "graph" ("y_axis")\nCREATE TABLE "graph_color" ( "id" serial NOT NULL, "name" character varying(128), "color" character(6), PRIMARY KEY ("id"), CONSTRAINT "ux_graph_color_name" UNIQUE ("name") )\nCREATE TABLE "group" ( "id" serial NOT NULL, "name" character varying(128), "default_read" smallint DEFAULT 0 NOT NULL, "default_write_new" smallint DEFAULT 0 NOT NULL, "default_write_existing" smallint DEFAULT 0 NOT NULL, "default_approve_new" smallint DEFAULT 0 NOT NULL, "default_approve_existing" smallint DEFAULT 0 NOT NULL, "default_write_new_no_approval" smallint DEFAULT 0 NOT NULL, "default_write_existing_no_approval" smallint DEFAULT 0 NOT NULL, "site_id" integer, PRIMARY KEY ("id") )\nCREATE INDEX "group_idx_site_id" on "group" ("site_id")\nCREATE TABLE "import" ( "id" serial NOT NULL, "site_id" integer, "user_id" bigint NOT NULL, "type" character varying(45), "row_count" integer DEFAULT 0 NOT NULL, "started" timestamp, "completed" timestamp, "written_count" integer DEFAULT 0 NOT NULL, "error_count" integer DEFAULT 0 NOT NULL, "skipped_count" integer DEFAULT 0 NOT NULL, "result" text, PRIMARY KEY ("id") )\nCREATE INDEX "import_idx_site_id" on "import" ("site_id")\nCREATE INDEX "import_idx_user_id" on "import" ("user_id")\nCREATE TABLE "import_row" ( "id" serial NOT NULL, "import_id" integer NOT NULL, "status" character varying(45), "content" text, "errors" text, "changes" text, PRIMARY KEY ("id") )\nCREATE INDEX "import_row_idx_import_id" on "import_row" ("import_id")\nCREATE TABLE "instance" ( "id" serial NOT NULL, "name" text, "name_short" character varying(64), "site_id" integer, "email_welcome_text" text, "email_welcome_subject" text, "sort_layout_id" integer, "sort_type" character varying(45), "default_view_limit_extra_id" integer, "homepage_text" text, "homepage_text2" text, "forget_history" smallint DEFAULT 0, "no_overnight_update" smallint DEFAULT 0, PRIMARY KEY ("id") )\nCREATE INDEX "instance_idx_default_view_limit_extra_id" on "instance" ("default_view_limit_extra_id")\nCREATE INDEX "instance_idx_site_id" on "instance" ("site_id")\nCREATE INDEX "instance_idx_sort_layout_id" on "instance" ("sort_layout_id")\nCREATE TABLE "instance_group" ( "id" serial NOT NULL, "instance_id" integer NOT NULL, "group_id" integer NOT NULL, "permission" character varying(45) NOT NULL, PRIMARY KEY ("id"), CONSTRAINT "instance_group_ux_instance_group_permission" UNIQUE ("instance_id", "group_id", "permission") )\nCREATE INDEX "instance_group_idx_group_id" on "instance_group" ("group_id")\nCREATE INDEX "instance_group_idx_instance_id" on "instance_group" ("instance_id")\nCREATE TABLE "intgr" ( "id" serial NOT NULL, "record_id" bigint NOT NULL, "layout_id" integer NOT NULL, "child_unique" smallint DEFAULT 0 NOT NULL, "value" bigint, PRIMARY KEY ("id") )\nCREATE INDEX "intgr_idx_layout_id" on "intgr" ("layout_id")\nCREATE INDEX "intgr_idx_record_id" on "intgr" ("record_id")\nCREATE INDEX "intgr_idx_value" on "intgr" ("value")\nCREATE TABLE "layout" ( "id" serial NOT NULL, "name" text, "name_short" text, "type" character varying(45), "permission" integer DEFAULT 0 NOT NULL, "optional" smallint DEFAULT 0 NOT NULL, "remember" smallint DEFAULT 0 NOT NULL, "isunique" smallint DEFAULT 0 NOT NULL, "textbox" smallint DEFAULT 0 NOT NULL, "typeahead" smallint DEFAULT 0 NOT NULL, "force_regex" text, "position" integer, "ordering" character varying(45), "end_node_only" smallint DEFAULT 0 NOT NULL, "multivalue" smallint DEFAULT 0 NOT NULL, "description" text, "helptext" text, "options" text, "display_field" integer, "display_regex" text, "instance_id" integer, "link_parent" integer, "related_field" integer, "filter" text, PRIMARY KEY ("id") )\nCREATE INDEX "layout_idx_display_field" on "layout" ("display_field")\nCREATE INDEX "layout_idx_instance_id" on "layout" ("instance_id")\nCREATE INDEX "layout_idx_link_parent" on "layout" ("link_parent")\nCREATE INDEX "layout_idx_related_field" on "layout" ("related_field")\nCREATE TABLE "layout_depend" ( "id" serial NOT NULL, "layout_id" integer NOT NULL, "depends_on" integer NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "layout_depend_idx_depends_on" on "layout_depend" ("depends_on")\nCREATE INDEX "layout_depend_idx_layout_id" on "layout_depend" ("layout_id")\nCREATE TABLE "layout_group" ( "id" serial NOT NULL, "layout_id" integer NOT NULL, "group_id" integer NOT NULL, "permission" character varying(45) NOT NULL, PRIMARY KEY ("id"), CONSTRAINT "layout_group_ux_layout_group_permission" UNIQUE ("layout_id", "group_id", "permission") )\nCREATE INDEX "layout_group_idx_group_id" on "layout_group" ("group_id")\nCREATE INDEX "layout_group_idx_layout_id" on "layout_group" ("layout_id")\nCREATE INDEX "layout_group_idx_permission" on "layout_group" ("permission")\nCREATE TABLE "metric" ( "id" serial NOT NULL, "metric_group" integer NOT NULL, "x_axis_value" text, "target" bigint, "y_axis_grouping_value" text, PRIMARY KEY ("id") )\nCREATE INDEX "metric_idx_metric_group" on "metric" ("metric_group")\nCREATE TABLE "metric_group" ( "id" serial NOT NULL, "name" text, "instance_id" integer, PRIMARY KEY ("id") )\nCREATE INDEX "metric_group_idx_instance_id" on "metric_group" ("instance_id")\nCREATE TABLE "oauthclient" ( "id" serial NOT NULL, "client_id" character varying(64) NOT NULL, "client_secret" character varying(64) NOT NULL, PRIMARY KEY ("id") )\nCREATE TABLE "oauthtoken" ( "token" character varying(128) NOT NULL, "related_token" character varying(128) NOT NULL, "oauthclient_id" integer NOT NULL, "user_id" bigint NOT NULL, "type" character varying(12) NOT NULL, "expires" integer, PRIMARY KEY ("token") )\nCREATE INDEX "oauthtoken_idx_oauthclient_id" on "oauthtoken" ("oauthclient_id")\nCREATE INDEX "oauthtoken_idx_user_id" on "oauthtoken" ("user_id")\nCREATE TABLE "organisation" ( "id" serial NOT NULL, "name" character varying(128), "site_id" integer, PRIMARY KEY ("id") )\nCREATE INDEX "organisation_idx_site_id" on "organisation" ("site_id")\nCREATE TABLE "permission" ( "id" serial NOT NULL, "name" character varying(128) NOT NULL, "description" text, "order" integer, PRIMARY KEY ("id") )\nCREATE TABLE "person" ( "id" serial NOT NULL, "record_id" bigint, "layout_id" integer, "child_unique" smallint DEFAULT 0 NOT NULL, "value" bigint, PRIMARY KEY ("id") )\nCREATE INDEX "person_idx_layout_id" on "person" ("layout_id")\nCREATE INDEX "person_idx_record_id" on "person" ("record_id")\nCREATE INDEX "person_idx_value" on "person" ("value")\nCREATE TABLE "rag" ( "id" serial NOT NULL, "layout_id" integer NOT NULL, "red" text, "amber" text, "green" text, "code" text, PRIMARY KEY ("id") )\nCREATE INDEX "rag_idx_layout_id" on "rag" ("layout_id")\nCREATE TABLE "ragval" ( "id" serial NOT NULL, "record_id" bigint NOT NULL, "layout_id" integer NOT NULL, "value" character varying(16), PRIMARY KEY ("id"), CONSTRAINT "ragval_ux_record_layout" UNIQUE ("record_id", "layout_id") )\nCREATE INDEX "ragval_idx_layout_id" on "ragval" ("layout_id")\nCREATE INDEX "ragval_idx_record_id" on "ragval" ("record_id")\nCREATE INDEX "ragval_idx_value" on "ragval" ("value")\nCREATE TABLE "record" ( "id" serial NOT NULL, "created" timestamp NOT NULL, "current_id" bigint DEFAULT 0 NOT NULL, "createdby" bigint, "approvedby" bigint, "record_id" bigint, "approval" smallint DEFAULT 0 NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "record_idx_approvedby" on "record" ("approvedby")\nCREATE INDEX "record_idx_createdby" on "record" ("createdby")\nCREATE INDEX "record_idx_current_id" on "record" ("current_id")\nCREATE INDEX "record_idx_record_id" on "record" ("record_id")\nCREATE INDEX "record_idx_approval" on "record" ("approval")\nCREATE TABLE "site" ( "id" serial NOT NULL, "host" character varying(128), "created" timestamp, "email_welcome_text" text, "email_welcome_subject" text, "email_delete_text" text, "email_delete_subject" text, "email_reject_text" text, "email_reject_subject" text, "register_text" text, "homepage_text" text, "homepage_text2" text, "register_title_help" text, "register_freetext1_help" text, "register_freetext2_help" text, "register_email_help" text, "register_organisation_help" text, "register_organisation_name" text, "register_notes_help" text, "register_freetext1_name" text, "register_freetext2_name" text, "register_show_organisation" smallint DEFAULT 1 NOT NULL, "register_show_title" smallint DEFAULT 1 NOT NULL, PRIMARY KEY ("id") )\nCREATE TABLE "sort" ( "id" serial NOT NULL, "view_id" bigint NOT NULL, "layout_id" integer, "type" character varying(45), PRIMARY KEY ("id") )\nCREATE INDEX "sort_idx_layout_id" on "sort" ("layout_id")\nCREATE INDEX "sort_idx_view_id" on "sort" ("view_id")\nCREATE TABLE "string" ( "id" serial NOT NULL, "record_id" bigint NOT NULL, "layout_id" integer NOT NULL, "child_unique" smallint DEFAULT 0 NOT NULL, "value" text, "value_index" character varying(128), PRIMARY KEY ("id") )\nCREATE INDEX "string_idx_layout_id" on "string" ("layout_id")\nCREATE INDEX "string_idx_record_id" on "string" ("record_id")\nCREATE INDEX "string_idx_value_index" on "string" ("value_index")\nCREATE TABLE "title" ( "id" serial NOT NULL, "name" character varying(128), "site_id" integer, PRIMARY KEY ("id") )\nCREATE INDEX "title_idx_site_id" on "title" ("site_id")\nCREATE TABLE "user" ( "id" serial NOT NULL, "site_id" integer, "firstname" character varying(128), "surname" character varying(128), "email" text, "username" text, "title" integer, "organisation" integer, "freetext1" text, "freetext2" text, "password" character varying(128), "pwchanged" timestamp, "resetpw" character varying(32), "deleted" timestamp, "lastlogin" timestamp, "lastfail" timestamp, "failcount" integer DEFAULT 0 NOT NULL, "lastrecord" bigint, "lastview" bigint, "session_settings" text, "value" text, "account_request" smallint DEFAULT 0, "account_request_notes" text, "aup_accepted" timestamp, "limit_to_view" bigint, "stylesheet" text, PRIMARY KEY ("id") )\nCREATE INDEX "user_idx_lastrecord" on "user" ("lastrecord")\nCREATE INDEX "user_idx_lastview" on "user" ("lastview")\nCREATE INDEX "user_idx_limit_to_view" on "user" ("limit_to_view")\nCREATE INDEX "user_idx_organisation" on "user" ("organisation")\nCREATE INDEX "user_idx_site_id" on "user" ("site_id")\nCREATE INDEX "user_idx_title" on "user" ("title")\nCREATE INDEX "user_idx_value" on "user" ("value")\nCREATE INDEX "user_idx_email" on "user" ("email")\nCREATE INDEX "user_idx_username" on "user" ("username")\nCREATE TABLE "user_graph" ( "id" serial NOT NULL, "user_id" bigint NOT NULL, "graph_id" integer NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "user_graph_idx_graph_id" on "user_graph" ("graph_id")\nCREATE INDEX "user_graph_idx_user_id" on "user_graph" ("user_id")\nCREATE TABLE "user_group" ( "id" serial NOT NULL, "user_id" bigint NOT NULL, "group_id" integer NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "user_group_idx_group_id" on "user_group" ("group_id")\nCREATE INDEX "user_group_idx_user_id" on "user_group" ("user_id")\nCREATE TABLE "user_lastrecord" ( "id" serial NOT NULL, "record_id" bigint NOT NULL, "instance_id" integer NOT NULL, "user_id" bigint NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "user_lastrecord_idx_instance_id" on "user_lastrecord" ("instance_id")\nCREATE INDEX "user_lastrecord_idx_record_id" on "user_lastrecord" ("record_id")\nCREATE INDEX "user_lastrecord_idx_user_id" on "user_lastrecord" ("user_id")\nCREATE TABLE "user_permission" ( "id" serial NOT NULL, "user_id" bigint NOT NULL, "permission_id" integer NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "user_permission_idx_permission_id" on "user_permission" ("permission_id")\nCREATE INDEX "user_permission_idx_user_id" on "user_permission" ("user_id")\nCREATE TABLE "view" ( "id" serial NOT NULL, "user_id" bigint, "group_id" integer, "name" character varying(128), "global" smallint DEFAULT 0 NOT NULL, "is_admin" smallint DEFAULT 0 NOT NULL, "is_limit_extra" smallint DEFAULT 0 NOT NULL, "filter" text, "instance_id" integer, PRIMARY KEY ("id") )\nCREATE INDEX "view_idx_group_id" on "view" ("group_id")\nCREATE INDEX "view_idx_instance_id" on "view" ("instance_id")\nCREATE INDEX "view_idx_user_id" on "view" ("user_id")\nCREATE TABLE "view_layout" ( "id" serial NOT NULL, "view_id" bigint NOT NULL, "layout_id" integer NOT NULL, "order" integer, PRIMARY KEY ("id") )\nCREATE INDEX "view_layout_idx_layout_id" on "view_layout" ("layout_id")\nCREATE INDEX "view_layout_idx_view_id" on "view_layout" ("view_id")\nCREATE TABLE "view_limit" ( "id" serial NOT NULL, "view_id" bigint NOT NULL, "user_id" bigint NOT NULL, PRIMARY KEY ("id") )\nCREATE INDEX "view_limit_idx_user_id" on "view_limit" ("user_id")\nCREATE INDEX "view_limit_idx_view_id" on "view_limit" ("view_id")\nALTER TABLE "alert" ADD CONSTRAINT "alert_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert" ADD CONSTRAINT "alert_fk_view_id" FOREIGN KEY ("view_id") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_current_id" FOREIGN KEY ("current_id") REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert_cache" ADD CONSTRAINT "alert_cache_fk_view_id" FOREIGN KEY ("view_id") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert_send" ADD CONSTRAINT "alert_send_fk_alert_id" FOREIGN KEY ("alert_id") REFERENCES "alert" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert_send" ADD CONSTRAINT "alert_send_fk_current_id" FOREIGN KEY ("current_id") REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "alert_send" ADD CONSTRAINT "alert_send_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "audit" ADD CONSTRAINT "audit_fk_site_id" FOREIGN KEY ("site_id") REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "audit" ADD CONSTRAINT "audit_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "calc" ADD CONSTRAINT "calc_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "calcval" ADD CONSTRAINT "calcval_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "calcval" ADD CONSTRAINT "calcval_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "current" ADD CONSTRAINT "current_fk_deletedby" FOREIGN KEY ("deletedby") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "current" ADD CONSTRAINT "current_fk_instance_id" FOREIGN KEY ("instance_id") REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "current" ADD CONSTRAINT "current_fk_linked_id" FOREIGN KEY ("linked_id") REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "current" ADD CONSTRAINT "current_fk_parent_id" FOREIGN KEY ("parent_id") REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "curval" ADD CONSTRAINT "curval_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "curval" ADD CONSTRAINT "curval_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "curval" ADD CONSTRAINT "curval_fk_value" FOREIGN KEY ("value") REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "curval_fields" ADD CONSTRAINT "curval_fields_fk_child_id" FOREIGN KEY ("child_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "curval_fields" ADD CONSTRAINT "curval_fields_fk_parent_id" FOREIGN KEY ("parent_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "date" ADD CONSTRAINT "date_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "date" ADD CONSTRAINT "date_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "daterange" ADD CONSTRAINT "daterange_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "daterange" ADD CONSTRAINT "daterange_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "enum" ADD CONSTRAINT "enum_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "enum" ADD CONSTRAINT "enum_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "enum" ADD CONSTRAINT "enum_fk_value" FOREIGN KEY ("value") REFERENCES "enumval" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "enumval" ADD CONSTRAINT "enumval_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "enumval" ADD CONSTRAINT "enumval_fk_parent" FOREIGN KEY ("parent") REFERENCES "enumval" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "file" ADD CONSTRAINT "file_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "file" ADD CONSTRAINT "file_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "file" ADD CONSTRAINT "file_fk_value" FOREIGN KEY ("value") REFERENCES "fileval" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "file_option" ADD CONSTRAINT "file_option_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "filter" ADD CONSTRAINT "filter_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "filter" ADD CONSTRAINT "filter_fk_view_id" FOREIGN KEY ("view_id") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "graph" ADD CONSTRAINT "graph_fk_group_by" FOREIGN KEY ("group_by") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "graph" ADD CONSTRAINT "graph_fk_instance_id" FOREIGN KEY ("instance_id") REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "graph" ADD CONSTRAINT "graph_fk_metric_group" FOREIGN KEY ("metric_group") REFERENCES "metric_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "graph" ADD CONSTRAINT "graph_fk_x_axis" FOREIGN KEY ("x_axis") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "graph" ADD CONSTRAINT "graph_fk_y_axis" FOREIGN KEY ("y_axis") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "group" ADD CONSTRAINT "group_fk_site_id" FOREIGN KEY ("site_id") REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "import" ADD CONSTRAINT "import_fk_site_id" FOREIGN KEY ("site_id") REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "import" ADD CONSTRAINT "import_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "import_row" ADD CONSTRAINT "import_row_fk_import_id" FOREIGN KEY ("import_id") REFERENCES "import" ("id") ON DELETE CASCADE ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "instance" ADD CONSTRAINT "instance_fk_default_view_limit_extra_id" FOREIGN KEY ("default_view_limit_extra_id") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "instance" ADD CONSTRAINT "instance_fk_site_id" FOREIGN KEY ("site_id") REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "instance" ADD CONSTRAINT "instance_fk_sort_layout_id" FOREIGN KEY ("sort_layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "instance_group" ADD CONSTRAINT "instance_group_fk_group_id" FOREIGN KEY ("group_id") REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "instance_group" ADD CONSTRAINT "instance_group_fk_instance_id" FOREIGN KEY ("instance_id") REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "intgr" ADD CONSTRAINT "intgr_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "intgr" ADD CONSTRAINT "intgr_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout" ADD CONSTRAINT "layout_fk_display_field" FOREIGN KEY ("display_field") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout" ADD CONSTRAINT "layout_fk_instance_id" FOREIGN KEY ("instance_id") REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout" ADD CONSTRAINT "layout_fk_link_parent" FOREIGN KEY ("link_parent") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout" ADD CONSTRAINT "layout_fk_related_field" FOREIGN KEY ("related_field") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout_depend" ADD CONSTRAINT "layout_depend_fk_depends_on" FOREIGN KEY ("depends_on") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout_depend" ADD CONSTRAINT "layout_depend_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout_group" ADD CONSTRAINT "layout_group_fk_group_id" FOREIGN KEY ("group_id") REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "layout_group" ADD CONSTRAINT "layout_group_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "metric" ADD CONSTRAINT "metric_fk_metric_group" FOREIGN KEY ("metric_group") REFERENCES "metric_group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "metric_group" ADD CONSTRAINT "metric_group_fk_instance_id" FOREIGN KEY ("instance_id") REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "oauthtoken" ADD CONSTRAINT "oauthtoken_fk_oauthclient_id" FOREIGN KEY ("oauthclient_id") REFERENCES "oauthclient" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "oauthtoken" ADD CONSTRAINT "oauthtoken_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "organisation" ADD CONSTRAINT "organisation_fk_site_id" FOREIGN KEY ("site_id") REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "person" ADD CONSTRAINT "person_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "person" ADD CONSTRAINT "person_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "person" ADD CONSTRAINT "person_fk_value" FOREIGN KEY ("value") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "rag" ADD CONSTRAINT "rag_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "ragval" ADD CONSTRAINT "ragval_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "ragval" ADD CONSTRAINT "ragval_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "record" ADD CONSTRAINT "record_fk_approvedby" FOREIGN KEY ("approvedby") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "record" ADD CONSTRAINT "record_fk_createdby" FOREIGN KEY ("createdby") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "record" ADD CONSTRAINT "record_fk_current_id" FOREIGN KEY ("current_id") REFERENCES "current" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "record" ADD CONSTRAINT "record_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "sort" ADD CONSTRAINT "sort_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "sort" ADD CONSTRAINT "sort_fk_view_id" FOREIGN KEY ("view_id") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "string" ADD CONSTRAINT "string_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "string" ADD CONSTRAINT "string_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "title" ADD CONSTRAINT "title_fk_site_id" FOREIGN KEY ("site_id") REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user" ADD CONSTRAINT "user_fk_lastrecord" FOREIGN KEY ("lastrecord") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user" ADD CONSTRAINT "user_fk_lastview" FOREIGN KEY ("lastview") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user" ADD CONSTRAINT "user_fk_limit_to_view" FOREIGN KEY ("limit_to_view") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user" ADD CONSTRAINT "user_fk_organisation" FOREIGN KEY ("organisation") REFERENCES "organisation" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user" ADD CONSTRAINT "user_fk_site_id" FOREIGN KEY ("site_id") REFERENCES "site" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user" ADD CONSTRAINT "user_fk_title" FOREIGN KEY ("title") REFERENCES "title" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_graph" ADD CONSTRAINT "user_graph_fk_graph_id" FOREIGN KEY ("graph_id") REFERENCES "graph" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_graph" ADD CONSTRAINT "user_graph_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_group_id" FOREIGN KEY ("group_id") REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_instance_id" FOREIGN KEY ("instance_id") REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_record_id" FOREIGN KEY ("record_id") REFERENCES "record" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_lastrecord" ADD CONSTRAINT "user_lastrecord_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_permission_id" FOREIGN KEY ("permission_id") REFERENCES "permission" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "view" ADD CONSTRAINT "view_fk_group_id" FOREIGN KEY ("group_id") REFERENCES "group" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "view" ADD CONSTRAINT "view_fk_instance_id" FOREIGN KEY ("instance_id") REFERENCES "instance" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "view" ADD CONSTRAINT "view_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "view_layout" ADD CONSTRAINT "view_layout_fk_layout_id" FOREIGN KEY ("layout_id") REFERENCES "layout" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "view_layout" ADD CONSTRAINT "view_layout_fk_view_id" FOREIGN KEY ("view_id") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "view_limit" ADD CONSTRAINT "view_limit_fk_user_id" FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE\nALTER TABLE "view_limit" ADD CONSTRAINT "view_limit_fk_view_id" FOREIGN KEY ("view_id") REFERENCES "view" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE	\N
2	41		ALTER TABLE instance ADD COLUMN api_index_layout_id integer\nCREATE INDEX instance_idx_api_index_layout_id on instance (api_index_layout_id)\nALTER TABLE instance ADD CONSTRAINT instance_fk_api_index_layout_id FOREIGN KEY (api_index_layout_id) REFERENCES layout (id) ON DELETE NO ACTION ON UPDATE NO ACTION DEFERRABLE
3	42		ALTER TABLE current ADD COLUMN serial bigint\nALTER TABLE current ADD CONSTRAINT current_ux_instance_serial UNIQUE (instance_id, serial)
\.


--
-- Name: dbix_class_deploymenthandler_versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('dbix_class_deploymenthandler_versions_id_seq', 3, true);


--
-- Data for Name: enum; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY enum (id, record_id, layout_id, child_unique, value) FROM stdin;
1	1	3	0	1
2	1	4	0	5
3	1	4	0	6
4	1	4	0	7
5	2	3	0	1
6	2	4	0	5
7	2	4	0	6
8	2	4	0	7
9	3	3	0	2
10	3	4	0	5
11	3	4	0	6
12	3	4	0	7
13	3	6	0	13
14	4	3	0	1
15	4	4	0	7
16	4	4	0	8
17	4	6	0	13
\.


--
-- Name: enum_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('enum_id_seq', 17, true);


--
-- Data for Name: enumval; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY enumval (id, value, layout_id, deleted, parent) FROM stdin;
1	Holland	3	0	\N
2	Germany	3	0	\N
3	England	3	0	\N
4	Scotland	3	0	\N
5	Italian	4	0	\N
6	Chinese	4	0	\N
7	Indian	4	0	\N
8	French	4	0	\N
9	Thai	4	0	\N
10	Node 1	6	0	\N
11	Leaf 1	6	0	10
12	Leaf 2	6	0	10
13	Node 2	6	0	\N
14	Node 3	6	0	\N
\.


--
-- Name: enumval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('enumval_id_seq', 14, true);


--
-- Data for Name: file; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY file (id, record_id, layout_id, child_unique, value) FROM stdin;
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('file_id_seq', 1, false);


--
-- Data for Name: file_option; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY file_option (id, layout_id, filesize) FROM stdin;
\.


--
-- Name: file_option_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('file_option_id_seq', 1, false);


--
-- Data for Name: fileval; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY fileval (id, name, mimetype, content) FROM stdin;
\.


--
-- Name: fileval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('fileval_id_seq', 1, false);


--
-- Data for Name: filter; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY filter (id, view_id, layout_id) FROM stdin;
1	1	3
\.


--
-- Name: filter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('filter_id_seq', 1, true);


--
-- Data for Name: graph; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY graph (id, title, description, y_axis, y_axis_stack, y_axis_label, x_axis, x_axis_grouping, group_by, stackseries, as_percent, type, metric_group, instance_id) FROM stdin;
1	Favourite foods		1	count		4	\N	\N	0	0	bar	\N	1
\.


--
-- Data for Name: graph_color; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY graph_color (id, name, color) FROM stdin;
1	1	F9DDB6
2		F37970
3	Node 2	97C9B3
\.


--
-- Name: graph_color_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('graph_color_id_seq', 3, true);


--
-- Name: graph_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('graph_id_seq', 1, true);


--
-- Data for Name: group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "group" (id, name, default_read, default_write_new, default_write_existing, default_approve_new, default_approve_existing, default_write_new_no_approval, default_write_existing_no_approval, site_id) FROM stdin;
1	All read/write	0	0	0	0	0	0	0	1
\.


--
-- Name: group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('group_id_seq', 2, true);


--
-- Data for Name: import; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY import (id, site_id, user_id, type, row_count, started, completed, written_count, error_count, skipped_count, result) FROM stdin;
\.


--
-- Name: import_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('import_id_seq', 1, false);


--
-- Data for Name: import_row; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY import_row (id, import_id, status, content, errors, changes) FROM stdin;
\.


--
-- Name: import_row_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('import_row_id_seq', 1, false);


--
-- Data for Name: instance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY instance (id, name, name_short, site_id, email_welcome_text, email_welcome_subject, sort_layout_id, sort_type, default_view_limit_extra_id, homepage_text, homepage_text2, forget_history, no_overnight_update, api_index_layout_id) FROM stdin;
2	Tasks		1	\N	\N	\N	\N	\N	\N	\N	0	0	\N
1	People		1	\N	\N	\N	\N	\N	\N	\N	0	0	\N
\.


--
-- Data for Name: instance_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY instance_group (id, instance_id, group_id, permission) FROM stdin;
1	2	1	delete
2	2	1	purge
3	2	1	download
4	2	1	layout
5	2	1	message
6	2	1	view_create
7	2	1	view_group
8	2	1	create_child
9	2	1	bulk_update
10	2	1	link
11	2	1	view_limit_extra
12	1	1	delete
13	1	1	purge
14	1	1	download
15	1	1	layout
16	1	1	message
17	1	1	view_create
18	1	1	view_group
19	1	1	create_child
20	1	1	bulk_update
21	1	1	link
22	1	1	view_limit_extra
\.


--
-- Name: instance_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('instance_group_id_seq', 22, true);


--
-- Name: instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('instance_id_seq', 2, true);


--
-- Data for Name: intgr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY intgr (id, record_id, layout_id, child_unique, value) FROM stdin;
\.


--
-- Name: intgr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('intgr_id_seq', 1, false);


--
-- Data for Name: layout; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY layout (id, name, name_short, type, permission, optional, remember, isunique, textbox, typeahead, force_regex, "position", ordering, end_node_only, multivalue, description, helptext, options, display_field, display_regex, instance_id, link_parent, related_field, filter) FROM stdin;
1	Surname		string	0	0	0	0	0	0		1	\N	0	0			{}	\N	\N	1	\N	\N	{}
2	Forename		string	0	0	0	0	0	0		2	\N	0	0			{}	\N	\N	1	\N	\N	{}
3	Country		enum	0	0	0	0	0	0	\N	3	\N	0	0			{}	\N	\N	1	\N	\N	{}
4	Favourite foods		enum	0	0	0	0	0	0	\N	4	\N	0	1			{}	\N	\N	1	\N	\N	{}
5	Holiday dates		daterange	0	0	0	0	0	0	\N	5	\N	0	0			{"show_datepicker":"1"}	\N	\N	1	\N	\N	{}
6	Tree		tree	0	0	0	0	0	0	\N	6	\N	0	0			{}	\N	\N	1	\N	\N	{}
7	oooo		enum	0	1	0	0	0	0	\N	7	\N	0	0			{}	\N	\N	1	\N	\N	{}
8	Task name		string	0	0	0	0	0	0		8	\N	0	0			{}	\N	\N	2	\N	\N	{}
10	People (multiple)		curval	0	1	0	0	0	0	\N	10	\N	0	1			{"override_permissions":"0"}	\N	\N	2	\N	\N	{}
9	Person assigned		curval	0	1	0	0	0	0	\N	9	\N	0	0			{"override_permissions":"0"}	\N	\N	2	\N	\N	{}
\.


--
-- Data for Name: layout_depend; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY layout_depend (id, layout_id, depends_on) FROM stdin;
\.


--
-- Name: layout_depend_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('layout_depend_id_seq', 1, false);


--
-- Data for Name: layout_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY layout_group (id, layout_id, group_id, permission) FROM stdin;
1	1	1	approve_existing
2	1	1	approve_new
3	1	1	read
4	1	1	write_existing
5	1	1	write_existing_no_approval
6	1	1	write_new
7	1	1	write_new_no_approval
8	2	1	approve_existing
9	2	1	approve_new
10	2	1	read
11	2	1	write_existing
12	2	1	write_existing_no_approval
13	2	1	write_new
14	2	1	write_new_no_approval
15	3	1	approve_existing
16	3	1	approve_new
17	3	1	read
18	3	1	write_existing
19	3	1	write_existing_no_approval
20	3	1	write_new
21	3	1	write_new_no_approval
22	4	1	approve_existing
23	4	1	approve_new
24	4	1	read
25	4	1	write_existing
26	4	1	write_existing_no_approval
27	4	1	write_new
28	4	1	write_new_no_approval
29	5	1	approve_existing
30	5	1	approve_new
31	5	1	read
32	5	1	write_existing
33	5	1	write_existing_no_approval
34	5	1	write_new
35	5	1	write_new_no_approval
36	6	1	approve_existing
37	6	1	approve_new
38	6	1	read
39	6	1	write_existing
40	6	1	write_existing_no_approval
41	6	1	write_new
42	6	1	write_new_no_approval
43	8	1	approve_existing
44	8	1	approve_new
45	8	1	read
46	8	1	write_existing
47	8	1	write_existing_no_approval
48	8	1	write_new
49	8	1	write_new_no_approval
50	9	1	approve_existing
51	9	1	approve_new
52	9	1	read
53	9	1	write_existing
54	9	1	write_existing_no_approval
55	9	1	write_new
56	9	1	write_new_no_approval
57	10	1	approve_existing
58	10	1	approve_new
59	10	1	read
60	10	1	write_existing
61	10	1	write_existing_no_approval
62	10	1	write_new
63	10	1	write_new_no_approval
\.


--
-- Name: layout_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('layout_group_id_seq', 63, true);


--
-- Name: layout_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('layout_id_seq', 10, true);


--
-- Data for Name: metric; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY metric (id, metric_group, x_axis_value, target, y_axis_grouping_value) FROM stdin;
\.


--
-- Data for Name: metric_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY metric_group (id, name, instance_id) FROM stdin;
\.


--
-- Name: metric_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('metric_group_id_seq', 1, false);


--
-- Name: metric_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('metric_id_seq', 1, false);


--
-- Data for Name: oauthclient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY oauthclient (id, client_id, client_secret) FROM stdin;
\.


--
-- Name: oauthclient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('oauthclient_id_seq', 1, false);


--
-- Data for Name: oauthtoken; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY oauthtoken (token, related_token, oauthclient_id, user_id, type, expires) FROM stdin;
\.


--
-- Data for Name: organisation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY organisation (id, name, site_id) FROM stdin;
\.


--
-- Name: organisation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('organisation_id_seq', 1, false);


--
-- Data for Name: permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY permission (id, name, description, "order") FROM stdin;
1	delete	delete records without approval	1
10	audit	access user logs	11
3	useradmin	manage other user accounts	3
9	link	link records between tables	10
11	bulk_update	User can bulk update records	9
8	create_child	create child records and edit fields of existing child records	8
4	download	download data	4
5	layout	User can administer layout, views and graph	5
7	view_create	User can create, modify and delete views	7
2	delete_noneed_approval	delete records but requires approval	2
6	message	send messages	6
12	superadmin	\N	\N
13	useradmin	\N	\N
\.


--
-- Name: permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('permission_id_seq', 13, true);


--
-- Data for Name: person; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY person (id, record_id, layout_id, child_unique, value) FROM stdin;
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('person_id_seq', 1, false);


--
-- Data for Name: rag; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY rag (id, layout_id, red, amber, green, code) FROM stdin;
\.


--
-- Name: rag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('rag_id_seq', 1, false);


--
-- Data for Name: ragval; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY ragval (id, record_id, layout_id, value) FROM stdin;
\.


--
-- Name: ragval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('ragval_id_seq', 1, false);


--
-- Data for Name: record; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY record (id, created, current_id, createdby, approvedby, record_id, approval) FROM stdin;
1	2018-05-31 07:44:08	1	1	\N	\N	0
2	2018-05-31 07:50:31	1	1	\N	\N	0
3	2018-05-31 08:06:32	2	1	\N	\N	0
4	2018-05-31 08:08:49	3	2	\N	\N	0
5	2018-05-31 21:40:37	4	1	\N	\N	0
6	2018-05-31 21:40:47	5	1	\N	\N	0
7	2018-05-31 21:42:02	4	1	\N	\N	0
\.


--
-- Name: record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('record_id_seq', 7, true);


--
-- Data for Name: site; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY site (id, host, created, email_welcome_text, email_welcome_subject, email_delete_text, email_delete_subject, email_reject_text, email_reject_subject, register_text, homepage_text, homepage_text2, register_title_help, register_freetext1_help, register_freetext2_help, register_email_help, register_organisation_help, register_organisation_name, register_notes_help, register_freetext1_name, register_freetext2_name, register_show_organisation, register_show_title) FROM stdin;
1	localhost	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	Organisation	\N	\N	\N	1	1
\.


--
-- Name: site_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('site_id_seq', 1, true);


--
-- Data for Name: sort; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY sort (id, view_id, layout_id, type) FROM stdin;
\.


--
-- Name: sort_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('sort_id_seq', 1, false);


--
-- Data for Name: string; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY string (id, record_id, layout_id, child_unique, value, value_index) FROM stdin;
1	1	1	0	Beverley	beverley
2	1	2	0	Andy	andy
3	2	1	0	Beverley	beverley
4	2	2	0	Andy	andy
5	3	1	0	Smith	smith
6	3	2	0	John	john
7	4	1	0	Egger	egger
8	4	2	0	Flurin	flurin
9	5	8	0	Cut the grass	cut the grass
10	6	8	0	Cook dinner	cook dinner
11	7	8	0	Cut the grass	cut the grass
\.


--
-- Name: string_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('string_id_seq', 11, true);


--
-- Data for Name: title; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY title (id, name, site_id) FROM stdin;
\.


--
-- Name: title_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('title_id_seq', 1, false);


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "user" (id, site_id, firstname, surname, email, username, title, organisation, freetext1, freetext2, password, pwchanged, resetpw, deleted, lastlogin, lastfail, failcount, lastrecord, lastview, session_settings, value, account_request, account_request_notes, aup_accepted, limit_to_view, stylesheet) FROM stdin;
2	1	John	Doe	gads@ctrlo.local	gads@ctrlo.local	\N	\N	\N	\N	{SSHA512}WXu9TYHSpuH2DpDhhYjo5Qyjh1LBAIAow5sRp8WVBLeguP2KMDFcg4X9+gtzq3NxXiA0tZ34jB7ZpQuJeizZjC77bXo=	2018-05-31 08:07:30	\N	\N	2018-05-31 08:07:45	\N	0	\N	\N	{"viewtype":{"1":"table"},"instance_id":"1","tl_options":{"1":{"group":"3","color":"6","label":"1"}},"view_limit_extra":{},"view":{"1":"2"}}	Doe, John	0		\N	\N	\N
1	1	Andy	Beverley	a.beverley@ctrlo.com	a.beverley@ctrlo.com	\N	\N	\N	\N	{SSHA512}GEpQZ7GeQGPQoKQfXTC/zlJCS4FPdpOGOX+F5Ybrcxu4tiz7eM49IYHxYpqE/DR3xt6NlpuQZsFH6oNXo+pXmVUFm8w=	2018-05-31 07:49:05	\N	\N	2018-05-31 21:36:55	\N	0	\N	\N	{"instance_id":"2","view":{"1":"2"},"view_limit_extra":{},"viewtype":{"1":"table"},"tl_options":{}}	Beverley, Andy	0		\N	\N	\N
\.


--
-- Data for Name: user_graph; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY user_graph (id, user_id, graph_id) FROM stdin;
1	1	1
2	2	1
\.


--
-- Name: user_graph_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('user_graph_id_seq', 2, true);


--
-- Data for Name: user_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY user_group (id, user_id, group_id) FROM stdin;
1	1	1
2	2	1
\.


--
-- Name: user_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('user_group_id_seq', 2, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('user_id_seq', 2, true);


--
-- Data for Name: user_lastrecord; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY user_lastrecord (id, record_id, instance_id, user_id) FROM stdin;
1	3	1	1
2	4	1	2
3	6	2	1
\.


--
-- Name: user_lastrecord_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('user_lastrecord_id_seq', 3, true);


--
-- Data for Name: user_permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY user_permission (id, user_id, permission_id) FROM stdin;
1	1	1
4	1	9
5	1	11
6	1	8
7	1	4
8	1	5
9	1	7
10	1	2
11	1	6
12	1	12
13	1	13
14	2	13
15	2	12
\.


--
-- Name: user_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('user_permission_id_seq', 15, true);


--
-- Data for Name: view; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY view (id, user_id, group_id, name, global, is_admin, is_limit_extra, filter, instance_id) FROM stdin;
1	2	\N	Holidays	0	0	0	{"rules":[{"value":"Holland","field":"3","type":"string","id":"3","operator":"equal"}],"condition":"AND"}	1
2	\N	\N	Summary	1	0	0	{}	1
\.


--
-- Name: view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('view_id_seq', 2, true);


--
-- Data for Name: view_layout; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY view_layout (id, view_id, layout_id, "order") FROM stdin;
1	1	1	\N
2	1	2	\N
3	1	5	\N
4	2	1	\N
5	2	2	\N
6	2	3	\N
7	2	4	\N
8	2	5	\N
\.


--
-- Name: view_layout_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('view_layout_id_seq', 8, true);


--
-- Data for Name: view_limit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY view_limit (id, view_id, user_id) FROM stdin;
\.


--
-- Name: view_limit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('view_limit_id_seq', 1, false);


--
-- Name: alert_cache alert_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_cache
    ADD CONSTRAINT alert_cache_pkey PRIMARY KEY (id);


--
-- Name: alert alert_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert
    ADD CONSTRAINT alert_pkey PRIMARY KEY (id);


--
-- Name: alert_send alert_send_all; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_send
    ADD CONSTRAINT alert_send_all UNIQUE (layout_id, alert_id, current_id, status);


--
-- Name: alert_send alert_send_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_send
    ADD CONSTRAINT alert_send_pkey PRIMARY KEY (id);


--
-- Name: audit audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY audit
    ADD CONSTRAINT audit_pkey PRIMARY KEY (id);


--
-- Name: calc calc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calc
    ADD CONSTRAINT calc_pkey PRIMARY KEY (id);


--
-- Name: calcval calcval_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calcval
    ADD CONSTRAINT calcval_pkey PRIMARY KEY (id);


--
-- Name: calcval calcval_ux_record_layout; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calcval
    ADD CONSTRAINT calcval_ux_record_layout UNIQUE (record_id, layout_id);


--
-- Name: current current_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY current
    ADD CONSTRAINT current_pkey PRIMARY KEY (id);


--
-- Name: current current_ux_instance_serial; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY current
    ADD CONSTRAINT current_ux_instance_serial UNIQUE (instance_id, serial);


--
-- Name: curval_fields curval_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval_fields
    ADD CONSTRAINT curval_fields_pkey PRIMARY KEY (id);


--
-- Name: curval curval_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval
    ADD CONSTRAINT curval_pkey PRIMARY KEY (id);


--
-- Name: date date_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY date
    ADD CONSTRAINT date_pkey PRIMARY KEY (id);


--
-- Name: daterange daterange_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY daterange
    ADD CONSTRAINT daterange_pkey PRIMARY KEY (id);


--
-- Name: dbix_class_deploymenthandler_versions dbix_class_deploymenthandler_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dbix_class_deploymenthandler_versions
    ADD CONSTRAINT dbix_class_deploymenthandler_versions_pkey PRIMARY KEY (id);


--
-- Name: dbix_class_deploymenthandler_versions dbix_class_deploymenthandler_versions_version; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY dbix_class_deploymenthandler_versions
    ADD CONSTRAINT dbix_class_deploymenthandler_versions_version UNIQUE (version);


--
-- Name: enum enum_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enum
    ADD CONSTRAINT enum_pkey PRIMARY KEY (id);


--
-- Name: enumval enumval_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enumval
    ADD CONSTRAINT enumval_pkey PRIMARY KEY (id);


--
-- Name: file_option file_option_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_option
    ADD CONSTRAINT file_option_pkey PRIMARY KEY (id);


--
-- Name: file file_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (id);


--
-- Name: fileval fileval_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY fileval
    ADD CONSTRAINT fileval_pkey PRIMARY KEY (id);


--
-- Name: filter filter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY filter
    ADD CONSTRAINT filter_pkey PRIMARY KEY (id);


--
-- Name: graph_color graph_color_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph_color
    ADD CONSTRAINT graph_color_pkey PRIMARY KEY (id);


--
-- Name: graph graph_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph
    ADD CONSTRAINT graph_pkey PRIMARY KEY (id);


--
-- Name: group group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "group"
    ADD CONSTRAINT group_pkey PRIMARY KEY (id);


--
-- Name: import import_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY import
    ADD CONSTRAINT import_pkey PRIMARY KEY (id);


--
-- Name: import_row import_row_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY import_row
    ADD CONSTRAINT import_row_pkey PRIMARY KEY (id);


--
-- Name: instance_group instance_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance_group
    ADD CONSTRAINT instance_group_pkey PRIMARY KEY (id);


--
-- Name: instance_group instance_group_ux_instance_group_permission; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance_group
    ADD CONSTRAINT instance_group_ux_instance_group_permission UNIQUE (instance_id, group_id, permission);


--
-- Name: instance instance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT instance_pkey PRIMARY KEY (id);


--
-- Name: intgr intgr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intgr
    ADD CONSTRAINT intgr_pkey PRIMARY KEY (id);


--
-- Name: layout_depend layout_depend_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_depend
    ADD CONSTRAINT layout_depend_pkey PRIMARY KEY (id);


--
-- Name: layout_group layout_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_group
    ADD CONSTRAINT layout_group_pkey PRIMARY KEY (id);


--
-- Name: layout_group layout_group_ux_layout_group_permission; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_group
    ADD CONSTRAINT layout_group_ux_layout_group_permission UNIQUE (layout_id, group_id, permission);


--
-- Name: layout layout_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout
    ADD CONSTRAINT layout_pkey PRIMARY KEY (id);


--
-- Name: metric_group metric_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_group
    ADD CONSTRAINT metric_group_pkey PRIMARY KEY (id);


--
-- Name: metric metric_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric
    ADD CONSTRAINT metric_pkey PRIMARY KEY (id);


--
-- Name: oauthclient oauthclient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY oauthclient
    ADD CONSTRAINT oauthclient_pkey PRIMARY KEY (id);


--
-- Name: oauthtoken oauthtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY oauthtoken
    ADD CONSTRAINT oauthtoken_pkey PRIMARY KEY (token);


--
-- Name: organisation organisation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY organisation
    ADD CONSTRAINT organisation_pkey PRIMARY KEY (id);


--
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT permission_pkey PRIMARY KEY (id);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: rag rag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rag
    ADD CONSTRAINT rag_pkey PRIMARY KEY (id);


--
-- Name: ragval ragval_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ragval
    ADD CONSTRAINT ragval_pkey PRIMARY KEY (id);


--
-- Name: ragval ragval_ux_record_layout; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ragval
    ADD CONSTRAINT ragval_ux_record_layout UNIQUE (record_id, layout_id);


--
-- Name: record record_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY record
    ADD CONSTRAINT record_pkey PRIMARY KEY (id);


--
-- Name: site site_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY site
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: sort sort_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sort
    ADD CONSTRAINT sort_pkey PRIMARY KEY (id);


--
-- Name: string string_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY string
    ADD CONSTRAINT string_pkey PRIMARY KEY (id);


--
-- Name: title title_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY title
    ADD CONSTRAINT title_pkey PRIMARY KEY (id);


--
-- Name: user_graph user_graph_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_graph
    ADD CONSTRAINT user_graph_pkey PRIMARY KEY (id);


--
-- Name: user_group user_group_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_group
    ADD CONSTRAINT user_group_pkey PRIMARY KEY (id);


--
-- Name: user_lastrecord user_lastrecord_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_lastrecord
    ADD CONSTRAINT user_lastrecord_pkey PRIMARY KEY (id);


--
-- Name: user_permission user_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: graph_color ux_graph_color_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph_color
    ADD CONSTRAINT ux_graph_color_name UNIQUE (name);


--
-- Name: view_layout view_layout_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_layout
    ADD CONSTRAINT view_layout_pkey PRIMARY KEY (id);


--
-- Name: view_limit view_limit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_limit
    ADD CONSTRAINT view_limit_pkey PRIMARY KEY (id);


--
-- Name: view view_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view
    ADD CONSTRAINT view_pkey PRIMARY KEY (id);


--
-- Name: alert_cache_idx_current_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_cache_idx_current_id ON alert_cache USING btree (current_id);


--
-- Name: alert_cache_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_cache_idx_layout_id ON alert_cache USING btree (layout_id);


--
-- Name: alert_cache_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_cache_idx_user_id ON alert_cache USING btree (user_id);


--
-- Name: alert_cache_idx_view_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_cache_idx_view_id ON alert_cache USING btree (view_id);


--
-- Name: alert_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_idx_user_id ON alert USING btree (user_id);


--
-- Name: alert_idx_view_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_idx_view_id ON alert USING btree (view_id);


--
-- Name: alert_send_idx_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_send_idx_alert_id ON alert_send USING btree (alert_id);


--
-- Name: alert_send_idx_current_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_send_idx_current_id ON alert_send USING btree (current_id);


--
-- Name: alert_send_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX alert_send_idx_layout_id ON alert_send USING btree (layout_id);


--
-- Name: audit_idx_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_idx_site_id ON audit USING btree (site_id);


--
-- Name: audit_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX audit_idx_user_id ON audit USING btree (user_id);


--
-- Name: calc_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX calc_idx_layout_id ON calc USING btree (layout_id);


--
-- Name: calcval_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX calcval_idx_layout_id ON calcval USING btree (layout_id);


--
-- Name: calcval_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX calcval_idx_record_id ON calcval USING btree (record_id);


--
-- Name: calcval_idx_value_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX calcval_idx_value_date ON calcval USING btree (value_date);


--
-- Name: calcval_idx_value_int; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX calcval_idx_value_int ON calcval USING btree (value_int);


--
-- Name: calcval_idx_value_numeric; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX calcval_idx_value_numeric ON calcval USING btree (value_numeric);


--
-- Name: calcval_idx_value_text; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX calcval_idx_value_text ON calcval USING btree (value_text);


--
-- Name: current_idx_deletedby; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX current_idx_deletedby ON current USING btree (deletedby);


--
-- Name: current_idx_instance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX current_idx_instance_id ON current USING btree (instance_id);


--
-- Name: current_idx_linked_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX current_idx_linked_id ON current USING btree (linked_id);


--
-- Name: current_idx_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX current_idx_parent_id ON current USING btree (parent_id);


--
-- Name: curval_fields_idx_child_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX curval_fields_idx_child_id ON curval_fields USING btree (child_id);


--
-- Name: curval_fields_idx_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX curval_fields_idx_parent_id ON curval_fields USING btree (parent_id);


--
-- Name: curval_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX curval_idx_layout_id ON curval USING btree (layout_id);


--
-- Name: curval_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX curval_idx_record_id ON curval USING btree (record_id);


--
-- Name: curval_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX curval_idx_value ON curval USING btree (value);


--
-- Name: date_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX date_idx_layout_id ON date USING btree (layout_id);


--
-- Name: date_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX date_idx_record_id ON date USING btree (record_id);


--
-- Name: date_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX date_idx_value ON date USING btree (value);


--
-- Name: daterange_idx_from; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX daterange_idx_from ON daterange USING btree ("from");


--
-- Name: daterange_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX daterange_idx_layout_id ON daterange USING btree (layout_id);


--
-- Name: daterange_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX daterange_idx_record_id ON daterange USING btree (record_id);


--
-- Name: daterange_idx_to; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX daterange_idx_to ON daterange USING btree ("to");


--
-- Name: daterange_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX daterange_idx_value ON daterange USING btree (value);


--
-- Name: enum_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX enum_idx_layout_id ON enum USING btree (layout_id);


--
-- Name: enum_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX enum_idx_record_id ON enum USING btree (record_id);


--
-- Name: enum_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX enum_idx_value ON enum USING btree (value);


--
-- Name: enumval_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX enumval_idx_layout_id ON enumval USING btree (layout_id);


--
-- Name: enumval_idx_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX enumval_idx_parent ON enumval USING btree (parent);


--
-- Name: enumval_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX enumval_idx_value ON enumval USING btree (value);


--
-- Name: file_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_idx_layout_id ON file USING btree (layout_id);


--
-- Name: file_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_idx_record_id ON file USING btree (record_id);


--
-- Name: file_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_idx_value ON file USING btree (value);


--
-- Name: file_option_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX file_option_idx_layout_id ON file_option USING btree (layout_id);


--
-- Name: fileval_idx_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fileval_idx_name ON fileval USING btree (name);


--
-- Name: filter_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX filter_idx_layout_id ON filter USING btree (layout_id);


--
-- Name: filter_idx_view_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX filter_idx_view_id ON filter USING btree (view_id);


--
-- Name: graph_idx_group_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX graph_idx_group_by ON graph USING btree (group_by);


--
-- Name: graph_idx_instance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX graph_idx_instance_id ON graph USING btree (instance_id);


--
-- Name: graph_idx_metric_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX graph_idx_metric_group ON graph USING btree (metric_group);


--
-- Name: graph_idx_x_axis; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX graph_idx_x_axis ON graph USING btree (x_axis);


--
-- Name: graph_idx_y_axis; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX graph_idx_y_axis ON graph USING btree (y_axis);


--
-- Name: group_idx_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX group_idx_site_id ON "group" USING btree (site_id);


--
-- Name: import_idx_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX import_idx_site_id ON import USING btree (site_id);


--
-- Name: import_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX import_idx_user_id ON import USING btree (user_id);


--
-- Name: import_row_idx_import_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX import_row_idx_import_id ON import_row USING btree (import_id);


--
-- Name: instance_group_idx_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX instance_group_idx_group_id ON instance_group USING btree (group_id);


--
-- Name: instance_group_idx_instance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX instance_group_idx_instance_id ON instance_group USING btree (instance_id);


--
-- Name: instance_idx_api_index_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX instance_idx_api_index_layout_id ON instance USING btree (api_index_layout_id);


--
-- Name: instance_idx_default_view_limit_extra_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX instance_idx_default_view_limit_extra_id ON instance USING btree (default_view_limit_extra_id);


--
-- Name: instance_idx_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX instance_idx_site_id ON instance USING btree (site_id);


--
-- Name: instance_idx_sort_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX instance_idx_sort_layout_id ON instance USING btree (sort_layout_id);


--
-- Name: intgr_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX intgr_idx_layout_id ON intgr USING btree (layout_id);


--
-- Name: intgr_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX intgr_idx_record_id ON intgr USING btree (record_id);


--
-- Name: intgr_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX intgr_idx_value ON intgr USING btree (value);


--
-- Name: layout_depend_idx_depends_on; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_depend_idx_depends_on ON layout_depend USING btree (depends_on);


--
-- Name: layout_depend_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_depend_idx_layout_id ON layout_depend USING btree (layout_id);


--
-- Name: layout_group_idx_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_group_idx_group_id ON layout_group USING btree (group_id);


--
-- Name: layout_group_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_group_idx_layout_id ON layout_group USING btree (layout_id);


--
-- Name: layout_group_idx_permission; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_group_idx_permission ON layout_group USING btree (permission);


--
-- Name: layout_idx_display_field; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_idx_display_field ON layout USING btree (display_field);


--
-- Name: layout_idx_instance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_idx_instance_id ON layout USING btree (instance_id);


--
-- Name: layout_idx_link_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_idx_link_parent ON layout USING btree (link_parent);


--
-- Name: layout_idx_related_field; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX layout_idx_related_field ON layout USING btree (related_field);


--
-- Name: metric_group_idx_instance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX metric_group_idx_instance_id ON metric_group USING btree (instance_id);


--
-- Name: metric_idx_metric_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX metric_idx_metric_group ON metric USING btree (metric_group);


--
-- Name: oauthtoken_idx_oauthclient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX oauthtoken_idx_oauthclient_id ON oauthtoken USING btree (oauthclient_id);


--
-- Name: oauthtoken_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX oauthtoken_idx_user_id ON oauthtoken USING btree (user_id);


--
-- Name: organisation_idx_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX organisation_idx_site_id ON organisation USING btree (site_id);


--
-- Name: person_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX person_idx_layout_id ON person USING btree (layout_id);


--
-- Name: person_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX person_idx_record_id ON person USING btree (record_id);


--
-- Name: person_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX person_idx_value ON person USING btree (value);


--
-- Name: rag_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX rag_idx_layout_id ON rag USING btree (layout_id);


--
-- Name: ragval_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ragval_idx_layout_id ON ragval USING btree (layout_id);


--
-- Name: ragval_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ragval_idx_record_id ON ragval USING btree (record_id);


--
-- Name: ragval_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ragval_idx_value ON ragval USING btree (value);


--
-- Name: record_idx_approval; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX record_idx_approval ON record USING btree (approval);


--
-- Name: record_idx_approvedby; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX record_idx_approvedby ON record USING btree (approvedby);


--
-- Name: record_idx_createdby; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX record_idx_createdby ON record USING btree (createdby);


--
-- Name: record_idx_current_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX record_idx_current_id ON record USING btree (current_id);


--
-- Name: record_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX record_idx_record_id ON record USING btree (record_id);


--
-- Name: sort_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sort_idx_layout_id ON sort USING btree (layout_id);


--
-- Name: sort_idx_view_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sort_idx_view_id ON sort USING btree (view_id);


--
-- Name: string_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX string_idx_layout_id ON string USING btree (layout_id);


--
-- Name: string_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX string_idx_record_id ON string USING btree (record_id);


--
-- Name: string_idx_value_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX string_idx_value_index ON string USING btree (value_index);


--
-- Name: title_idx_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX title_idx_site_id ON title USING btree (site_id);


--
-- Name: user_graph_idx_graph_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_graph_idx_graph_id ON user_graph USING btree (graph_id);


--
-- Name: user_graph_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_graph_idx_user_id ON user_graph USING btree (user_id);


--
-- Name: user_group_idx_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_group_idx_group_id ON user_group USING btree (group_id);


--
-- Name: user_group_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_group_idx_user_id ON user_group USING btree (user_id);


--
-- Name: user_idx_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_email ON "user" USING btree (email);


--
-- Name: user_idx_lastrecord; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_lastrecord ON "user" USING btree (lastrecord);


--
-- Name: user_idx_lastview; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_lastview ON "user" USING btree (lastview);


--
-- Name: user_idx_limit_to_view; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_limit_to_view ON "user" USING btree (limit_to_view);


--
-- Name: user_idx_organisation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_organisation ON "user" USING btree (organisation);


--
-- Name: user_idx_site_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_site_id ON "user" USING btree (site_id);


--
-- Name: user_idx_title; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_title ON "user" USING btree (title);


--
-- Name: user_idx_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_username ON "user" USING btree (username);


--
-- Name: user_idx_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_idx_value ON "user" USING btree (value);


--
-- Name: user_lastrecord_idx_instance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_lastrecord_idx_instance_id ON user_lastrecord USING btree (instance_id);


--
-- Name: user_lastrecord_idx_record_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_lastrecord_idx_record_id ON user_lastrecord USING btree (record_id);


--
-- Name: user_lastrecord_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_lastrecord_idx_user_id ON user_lastrecord USING btree (user_id);


--
-- Name: user_permission_idx_permission_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_permission_idx_permission_id ON user_permission USING btree (permission_id);


--
-- Name: user_permission_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_permission_idx_user_id ON user_permission USING btree (user_id);


--
-- Name: view_idx_group_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_idx_group_id ON view USING btree (group_id);


--
-- Name: view_idx_instance_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_idx_instance_id ON view USING btree (instance_id);


--
-- Name: view_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_idx_user_id ON view USING btree (user_id);


--
-- Name: view_layout_idx_layout_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_layout_idx_layout_id ON view_layout USING btree (layout_id);


--
-- Name: view_layout_idx_view_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_layout_idx_view_id ON view_layout USING btree (view_id);


--
-- Name: view_limit_idx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_limit_idx_user_id ON view_limit USING btree (user_id);


--
-- Name: view_limit_idx_view_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX view_limit_idx_view_id ON view_limit USING btree (view_id);


--
-- Name: alert_cache alert_cache_fk_current_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_cache
    ADD CONSTRAINT alert_cache_fk_current_id FOREIGN KEY (current_id) REFERENCES current(id) DEFERRABLE;


--
-- Name: alert_cache alert_cache_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_cache
    ADD CONSTRAINT alert_cache_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: alert_cache alert_cache_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_cache
    ADD CONSTRAINT alert_cache_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: alert_cache alert_cache_fk_view_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_cache
    ADD CONSTRAINT alert_cache_fk_view_id FOREIGN KEY (view_id) REFERENCES view(id) DEFERRABLE;


--
-- Name: alert alert_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert
    ADD CONSTRAINT alert_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: alert alert_fk_view_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert
    ADD CONSTRAINT alert_fk_view_id FOREIGN KEY (view_id) REFERENCES view(id) DEFERRABLE;


--
-- Name: alert_send alert_send_fk_alert_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_send
    ADD CONSTRAINT alert_send_fk_alert_id FOREIGN KEY (alert_id) REFERENCES alert(id) DEFERRABLE;


--
-- Name: alert_send alert_send_fk_current_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_send
    ADD CONSTRAINT alert_send_fk_current_id FOREIGN KEY (current_id) REFERENCES current(id) DEFERRABLE;


--
-- Name: alert_send alert_send_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alert_send
    ADD CONSTRAINT alert_send_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: audit audit_fk_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY audit
    ADD CONSTRAINT audit_fk_site_id FOREIGN KEY (site_id) REFERENCES site(id) DEFERRABLE;


--
-- Name: audit audit_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY audit
    ADD CONSTRAINT audit_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: calc calc_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calc
    ADD CONSTRAINT calc_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: calcval calcval_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calcval
    ADD CONSTRAINT calcval_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: calcval calcval_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY calcval
    ADD CONSTRAINT calcval_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: current current_fk_deletedby; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY current
    ADD CONSTRAINT current_fk_deletedby FOREIGN KEY (deletedby) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: current current_fk_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY current
    ADD CONSTRAINT current_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance(id) DEFERRABLE;


--
-- Name: current current_fk_linked_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY current
    ADD CONSTRAINT current_fk_linked_id FOREIGN KEY (linked_id) REFERENCES current(id) DEFERRABLE;


--
-- Name: current current_fk_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY current
    ADD CONSTRAINT current_fk_parent_id FOREIGN KEY (parent_id) REFERENCES current(id) DEFERRABLE;


--
-- Name: curval_fields curval_fields_fk_child_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval_fields
    ADD CONSTRAINT curval_fields_fk_child_id FOREIGN KEY (child_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: curval_fields curval_fields_fk_parent_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval_fields
    ADD CONSTRAINT curval_fields_fk_parent_id FOREIGN KEY (parent_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: curval curval_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval
    ADD CONSTRAINT curval_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: curval curval_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval
    ADD CONSTRAINT curval_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: curval curval_fk_value; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY curval
    ADD CONSTRAINT curval_fk_value FOREIGN KEY (value) REFERENCES current(id) DEFERRABLE;


--
-- Name: date date_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY date
    ADD CONSTRAINT date_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: date date_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY date
    ADD CONSTRAINT date_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: daterange daterange_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY daterange
    ADD CONSTRAINT daterange_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: daterange daterange_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY daterange
    ADD CONSTRAINT daterange_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: enum enum_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enum
    ADD CONSTRAINT enum_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: enum enum_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enum
    ADD CONSTRAINT enum_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: enum enum_fk_value; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enum
    ADD CONSTRAINT enum_fk_value FOREIGN KEY (value) REFERENCES enumval(id) DEFERRABLE;


--
-- Name: enumval enumval_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enumval
    ADD CONSTRAINT enumval_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: enumval enumval_fk_parent; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY enumval
    ADD CONSTRAINT enumval_fk_parent FOREIGN KEY (parent) REFERENCES enumval(id) DEFERRABLE;


--
-- Name: file file_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: file file_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: file file_fk_value; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_fk_value FOREIGN KEY (value) REFERENCES fileval(id) DEFERRABLE;


--
-- Name: file_option file_option_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY file_option
    ADD CONSTRAINT file_option_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: filter filter_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY filter
    ADD CONSTRAINT filter_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: filter filter_fk_view_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY filter
    ADD CONSTRAINT filter_fk_view_id FOREIGN KEY (view_id) REFERENCES view(id) DEFERRABLE;


--
-- Name: graph graph_fk_group_by; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph
    ADD CONSTRAINT graph_fk_group_by FOREIGN KEY (group_by) REFERENCES layout(id) DEFERRABLE;


--
-- Name: graph graph_fk_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph
    ADD CONSTRAINT graph_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance(id) DEFERRABLE;


--
-- Name: graph graph_fk_metric_group; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph
    ADD CONSTRAINT graph_fk_metric_group FOREIGN KEY (metric_group) REFERENCES metric_group(id) DEFERRABLE;


--
-- Name: graph graph_fk_x_axis; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph
    ADD CONSTRAINT graph_fk_x_axis FOREIGN KEY (x_axis) REFERENCES layout(id) DEFERRABLE;


--
-- Name: graph graph_fk_y_axis; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY graph
    ADD CONSTRAINT graph_fk_y_axis FOREIGN KEY (y_axis) REFERENCES layout(id) DEFERRABLE;


--
-- Name: group group_fk_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "group"
    ADD CONSTRAINT group_fk_site_id FOREIGN KEY (site_id) REFERENCES site(id) DEFERRABLE;


--
-- Name: import import_fk_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY import
    ADD CONSTRAINT import_fk_site_id FOREIGN KEY (site_id) REFERENCES site(id) DEFERRABLE;


--
-- Name: import import_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY import
    ADD CONSTRAINT import_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: import_row import_row_fk_import_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY import_row
    ADD CONSTRAINT import_row_fk_import_id FOREIGN KEY (import_id) REFERENCES import(id) ON DELETE CASCADE DEFERRABLE;


--
-- Name: instance instance_fk_api_index_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT instance_fk_api_index_layout_id FOREIGN KEY (api_index_layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: instance instance_fk_default_view_limit_extra_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT instance_fk_default_view_limit_extra_id FOREIGN KEY (default_view_limit_extra_id) REFERENCES view(id) DEFERRABLE;


--
-- Name: instance instance_fk_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT instance_fk_site_id FOREIGN KEY (site_id) REFERENCES site(id) DEFERRABLE;


--
-- Name: instance instance_fk_sort_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance
    ADD CONSTRAINT instance_fk_sort_layout_id FOREIGN KEY (sort_layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: instance_group instance_group_fk_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance_group
    ADD CONSTRAINT instance_group_fk_group_id FOREIGN KEY (group_id) REFERENCES "group"(id) DEFERRABLE;


--
-- Name: instance_group instance_group_fk_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instance_group
    ADD CONSTRAINT instance_group_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance(id) DEFERRABLE;


--
-- Name: intgr intgr_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intgr
    ADD CONSTRAINT intgr_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: intgr intgr_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intgr
    ADD CONSTRAINT intgr_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: layout_depend layout_depend_fk_depends_on; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_depend
    ADD CONSTRAINT layout_depend_fk_depends_on FOREIGN KEY (depends_on) REFERENCES layout(id) DEFERRABLE;


--
-- Name: layout_depend layout_depend_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_depend
    ADD CONSTRAINT layout_depend_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: layout layout_fk_display_field; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout
    ADD CONSTRAINT layout_fk_display_field FOREIGN KEY (display_field) REFERENCES layout(id) DEFERRABLE;


--
-- Name: layout layout_fk_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout
    ADD CONSTRAINT layout_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance(id) DEFERRABLE;


--
-- Name: layout layout_fk_link_parent; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout
    ADD CONSTRAINT layout_fk_link_parent FOREIGN KEY (link_parent) REFERENCES layout(id) DEFERRABLE;


--
-- Name: layout layout_fk_related_field; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout
    ADD CONSTRAINT layout_fk_related_field FOREIGN KEY (related_field) REFERENCES layout(id) DEFERRABLE;


--
-- Name: layout_group layout_group_fk_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_group
    ADD CONSTRAINT layout_group_fk_group_id FOREIGN KEY (group_id) REFERENCES "group"(id) DEFERRABLE;


--
-- Name: layout_group layout_group_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY layout_group
    ADD CONSTRAINT layout_group_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: metric metric_fk_metric_group; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric
    ADD CONSTRAINT metric_fk_metric_group FOREIGN KEY (metric_group) REFERENCES metric_group(id) DEFERRABLE;


--
-- Name: metric_group metric_group_fk_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY metric_group
    ADD CONSTRAINT metric_group_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance(id) DEFERRABLE;


--
-- Name: oauthtoken oauthtoken_fk_oauthclient_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY oauthtoken
    ADD CONSTRAINT oauthtoken_fk_oauthclient_id FOREIGN KEY (oauthclient_id) REFERENCES oauthclient(id) DEFERRABLE;


--
-- Name: oauthtoken oauthtoken_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY oauthtoken
    ADD CONSTRAINT oauthtoken_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: organisation organisation_fk_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY organisation
    ADD CONSTRAINT organisation_fk_site_id FOREIGN KEY (site_id) REFERENCES site(id) DEFERRABLE;


--
-- Name: person person_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY person
    ADD CONSTRAINT person_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: person person_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY person
    ADD CONSTRAINT person_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: person person_fk_value; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY person
    ADD CONSTRAINT person_fk_value FOREIGN KEY (value) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: rag rag_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY rag
    ADD CONSTRAINT rag_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: ragval ragval_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ragval
    ADD CONSTRAINT ragval_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: ragval ragval_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY ragval
    ADD CONSTRAINT ragval_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: record record_fk_approvedby; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY record
    ADD CONSTRAINT record_fk_approvedby FOREIGN KEY (approvedby) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: record record_fk_createdby; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY record
    ADD CONSTRAINT record_fk_createdby FOREIGN KEY (createdby) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: record record_fk_current_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY record
    ADD CONSTRAINT record_fk_current_id FOREIGN KEY (current_id) REFERENCES current(id) DEFERRABLE;


--
-- Name: record record_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY record
    ADD CONSTRAINT record_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: sort sort_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sort
    ADD CONSTRAINT sort_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: sort sort_fk_view_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sort
    ADD CONSTRAINT sort_fk_view_id FOREIGN KEY (view_id) REFERENCES view(id) DEFERRABLE;


--
-- Name: string string_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY string
    ADD CONSTRAINT string_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: string string_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY string
    ADD CONSTRAINT string_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: title title_fk_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY title
    ADD CONSTRAINT title_fk_site_id FOREIGN KEY (site_id) REFERENCES site(id) DEFERRABLE;


--
-- Name: user user_fk_lastrecord; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_fk_lastrecord FOREIGN KEY (lastrecord) REFERENCES record(id) DEFERRABLE;


--
-- Name: user user_fk_lastview; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_fk_lastview FOREIGN KEY (lastview) REFERENCES view(id) DEFERRABLE;


--
-- Name: user user_fk_limit_to_view; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_fk_limit_to_view FOREIGN KEY (limit_to_view) REFERENCES view(id) DEFERRABLE;


--
-- Name: user user_fk_organisation; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_fk_organisation FOREIGN KEY (organisation) REFERENCES organisation(id) DEFERRABLE;


--
-- Name: user user_fk_site_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_fk_site_id FOREIGN KEY (site_id) REFERENCES site(id) DEFERRABLE;


--
-- Name: user user_fk_title; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_fk_title FOREIGN KEY (title) REFERENCES title(id) DEFERRABLE;


--
-- Name: user_graph user_graph_fk_graph_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_graph
    ADD CONSTRAINT user_graph_fk_graph_id FOREIGN KEY (graph_id) REFERENCES graph(id) DEFERRABLE;


--
-- Name: user_graph user_graph_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_graph
    ADD CONSTRAINT user_graph_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: user_group user_group_fk_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_group
    ADD CONSTRAINT user_group_fk_group_id FOREIGN KEY (group_id) REFERENCES "group"(id) DEFERRABLE;


--
-- Name: user_group user_group_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_group
    ADD CONSTRAINT user_group_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: user_lastrecord user_lastrecord_fk_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_lastrecord
    ADD CONSTRAINT user_lastrecord_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance(id) DEFERRABLE;


--
-- Name: user_lastrecord user_lastrecord_fk_record_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_lastrecord
    ADD CONSTRAINT user_lastrecord_fk_record_id FOREIGN KEY (record_id) REFERENCES record(id) DEFERRABLE;


--
-- Name: user_lastrecord user_lastrecord_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_lastrecord
    ADD CONSTRAINT user_lastrecord_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: user_permission user_permission_fk_permission_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_fk_permission_id FOREIGN KEY (permission_id) REFERENCES permission(id) DEFERRABLE;


--
-- Name: user_permission user_permission_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY user_permission
    ADD CONSTRAINT user_permission_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: view view_fk_group_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view
    ADD CONSTRAINT view_fk_group_id FOREIGN KEY (group_id) REFERENCES "group"(id) DEFERRABLE;


--
-- Name: view view_fk_instance_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view
    ADD CONSTRAINT view_fk_instance_id FOREIGN KEY (instance_id) REFERENCES instance(id) DEFERRABLE;


--
-- Name: view view_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view
    ADD CONSTRAINT view_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: view_layout view_layout_fk_layout_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_layout
    ADD CONSTRAINT view_layout_fk_layout_id FOREIGN KEY (layout_id) REFERENCES layout(id) DEFERRABLE;


--
-- Name: view_layout view_layout_fk_view_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_layout
    ADD CONSTRAINT view_layout_fk_view_id FOREIGN KEY (view_id) REFERENCES view(id) DEFERRABLE;


--
-- Name: view_limit view_limit_fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_limit
    ADD CONSTRAINT view_limit_fk_user_id FOREIGN KEY (user_id) REFERENCES "user"(id) DEFERRABLE;


--
-- Name: view_limit view_limit_fk_view_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY view_limit
    ADD CONSTRAINT view_limit_fk_view_id FOREIGN KEY (view_id) REFERENCES view(id) DEFERRABLE;


--
-- PostgreSQL database dump complete
--

