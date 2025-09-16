--
-- PostgreSQL database dump
--

-- Dumped from database version 15.14
-- Dumped by pg_dump version 16.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: get_public_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_public_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	NEW.properties := jsonb_set(NEW.properties,'{public_id}',(SELECT
	'"' || resource_type.public_id_prefix || lpad(cast(coalesce(max(replace(resource.properties ->> 'public_id', resource_type.public_id_prefix, ''))::int, 0) + 1 AS text), 11, '0') || '"' as public_id
FROM
	resource_type
	left JOIN resource ON resource_type.id = resource.resource_type_id and resource.properties->>'public_id' like concat(resource_type.public_id_prefix,'%')
WHERE
	resource_type.id = NEW.resource_type_id
	
GROUP BY
	resource_type.id)::jsonb,true);

	RETURN NEW;
END;
$$;


--
-- Name: set_public_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_public_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	NEW.properties := jsonb_set(NEW.properties,'{public_id}',OLD.properties -> 'public_id',true);

	RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: action_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_type (
    id text NOT NULL,
    name text NOT NULL,
    CONSTRAINT action_type_id_check CHECK ((length(id) = 3))
);


--
-- Name: analysis_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.analysis_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS analysis_id,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::text AS analysis_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: dac_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dac_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS dac_id,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: dataset_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dataset_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS analysis_id,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::text AS dataset_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name,
    NULL::text AS creator_email,
    NULL::text AS creator_username,
    NULL::text AS creator_sub,
    NULL::text AS released_date;


--
-- Name: experiment_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.experiment_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS experiment_id,
    NULL::text AS public_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::text AS status_type_id,
    NULL::text AS experiment_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: file_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.file_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS file_id,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::text AS file_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: molecularanalysis_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.molecularanalysis_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS analysis_id,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::text AS analysis_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: molecularexperiment_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.molecularexperiment_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS experiment_id,
    NULL::text AS public_id,
    NULL::text AS title,
    NULL::text AS status_type_id,
    NULL::text AS status,
    NULL::text AS experiment_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: molecularrun_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.molecularrun_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS sample_id,
    NULL::text AS title,
    NULL::text AS public_id,
    NULL::text AS run_file_type,
    NULL::text AS sample_public_id,
    NULL::text AS experiment_public_id,
    NULL::text AS status,
    NULL::text AS status_type_id,
    NULL::text AS run_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: molecularsample_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.molecularsample_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS sample_id,
    NULL::text AS public_id,
    NULL::text AS title,
    NULL::text AS alias,
    NULL::text AS status,
    NULL::text AS sample_type,
    NULL::text AS status_type_id,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: namespace; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace (
    prefix text NOT NULL,
    uri text NOT NULL,
    name text NOT NULL
);


--
-- Name: permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permission (
    id text NOT NULL,
    name text
);


--
-- Name: policy_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.policy_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS policy_id,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::jsonb AS properties,
    NULL::text AS dac_id;


--
-- Name: predicate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.predicate (
    id integer NOT NULL,
    prefix text NOT NULL,
    name text NOT NULL,
    properties jsonb
);


--
-- Name: relationship; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationship (
    id uuid NOT NULL,
    relationship_rule_id integer NOT NULL,
    domain_resource_id uuid NOT NULL,
    predicate_id integer NOT NULL,
    range_resource_id uuid NOT NULL,
    sequence_number integer DEFAULT 1,
    is_active boolean DEFAULT true NOT NULL
);


--
-- Name: relationship_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationship_log (
    id uuid NOT NULL,
    relationship_id uuid NOT NULL,
    user_id integer NOT NULL,
    action_type_id text NOT NULL,
    action_time timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: relationship_old; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationship_old (
    id uuid,
    relationship_rule_id integer,
    domain_resource_id uuid,
    predicate_id integer,
    range_resource_id uuid,
    sequence_number integer,
    is_active boolean
);


--
-- Name: relationship_rule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationship_rule (
    id integer NOT NULL,
    domain_type_id integer NOT NULL,
    predicate_id integer NOT NULL,
    range_type_id integer NOT NULL,
    default_is_active boolean DEFAULT true
);


--
-- Name: COLUMN relationship_rule.default_is_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.relationship_rule.default_is_active IS 'default is_active value';


--
-- Name: relationship_rule_old; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationship_rule_old (
    id integer,
    domain_type_id integer,
    predicate_id integer,
    range_type_id integer
);


--
-- Name: resource_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_type (
    id integer NOT NULL,
    prefix text NOT NULL,
    name text NOT NULL,
    properties jsonb,
    public_id_prefix text,
    validator_mandatory boolean DEFAULT false
);


--
-- Name: relationship_rule_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.relationship_rule_view AS
 SELECT relationship_rule.id,
    domain_type.name AS domain_type_name,
    relationship_rule.domain_type_id,
    range_type.name AS range_type_name,
    relationship_rule.range_type_id,
    predicate.id AS predicate_id,
    predicate.name AS predicate_name,
    domain_type.prefix AS domain_prefix,
    relationship_rule.default_is_active
   FROM (((public.relationship_rule
     JOIN public.predicate ON ((predicate.id = relationship_rule.predicate_id)))
     JOIN public.resource_type domain_type ON ((relationship_rule.domain_type_id = domain_type.id)))
     JOIN public.resource_type range_type ON ((range_type.id = relationship_rule.range_type_id)));


--
-- Name: resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource (
    id uuid NOT NULL,
    properties jsonb,
    resource_type_id integer NOT NULL,
    status_type_id text NOT NULL
);


--
-- Name: relationship_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.relationship_view AS
 SELECT relationship.id,
    relationship.domain_resource_id,
    (domains.properties ->> 'public_id'::text) AS domain_public_id,
    domain_types.name AS domain_type,
    predicate.name AS predicate_name,
    relationship.range_resource_id,
    (ranges.properties ->> 'public_id'::text) AS range_public_id,
    range_types.name AS range_type,
    relationship.is_active,
    relationship_rule.id AS relationship_rule_id
   FROM ((((((public.relationship
     JOIN public.resource domains ON ((relationship.domain_resource_id = domains.id)))
     JOIN public.resource ranges ON ((relationship.range_resource_id = ranges.id)))
     JOIN public.relationship_rule ON ((relationship.relationship_rule_id = relationship_rule.id)))
     JOIN public.resource_type domain_types ON ((domains.resource_type_id = domain_types.id)))
     JOIN public.resource_type range_types ON ((ranges.resource_type_id = range_types.id)))
     JOIN public.predicate ON ((relationship_rule.predicate_id = predicate.id)));



--
-- Name: resource_acl; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_acl (
    resource_id uuid NOT NULL,
    user_id integer NOT NULL,
    role_id text NOT NULL
);


--
-- Name: resource_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_log (
    id uuid NOT NULL,
    resource_id uuid NOT NULL,
    user_id integer,
    action_type_id text NOT NULL,
    action_time timestamp without time zone DEFAULT now() NOT NULL,
    properties jsonb,
    version text,
    comment text
);



--
-- Name: resource_user_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.resource_user_view AS
SELECT
    NULL::uuid AS resource_id,
    NULL::integer AS user_id,
    NULL::text AS resource_type_name,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS status,
    NULL::text AS permissions,
    NULL::integer AS id,
    NULL::text AS preferred_username,
    NULL::text AS username,
    NULL::text AS email,
    NULL::text AS creator_sub,
    NULL::text AS role_id,
    NULL::text AS role;


--
-- Name: resource_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.resource_view AS
SELECT
    NULL::uuid AS id,
    NULL::text AS title,
    NULL::jsonb AS properties,
    NULL::text AS status_type_id,
    NULL::integer AS resource_type_id,
    NULL::text AS resource_type,
    NULL::text AS usernames,
    NULL::timestamp without time zone AS creation_date;


--
-- Name: rmq_correlation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rmq_correlation (
    correlation_id uuid NOT NULL,
    resource_id uuid NOT NULL
);


--
-- Name: role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role (
    id text NOT NULL,
    name text,
    CONSTRAINT role_id_check CHECK ((length(id) = 3))
);


--
-- Name: role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permission (
    role_id text NOT NULL,
    permission_id text NOT NULL
);


--
-- Name: run_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.run_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS sample_id,
    NULL::text AS public_id,
    NULL::text AS title,
    NULL::text AS run_file_type,
    NULL::text AS sample_public_id,
    NULL::text AS experiment_public_id,
    NULL::text AS status,
    NULL::text AS status_type_id,
    NULL::text AS run_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: sample_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.sample_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS sample_id,
    NULL::text AS public_id,
    NULL::text AS title,
    NULL::text AS alias,
    NULL::text AS status_type_id,
    NULL::text AS status,
    NULL::text AS sample_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name;


--
-- Name: sdafile_study_dataset_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.sdafile_study_dataset_view AS
 SELECT sdafiles.id AS sdafile_id,
    (sdafiles.properties ->> 'public_id'::text) AS sdafile_public_id,
    (sdafiles.properties ->> 'title'::text) AS sdafile_name,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    COALESCE(analysis_dataset.id, run_dataset.id) AS dataset_id,
    COALESCE((analysis_dataset.properties ->> 'public_id'::text), (run_dataset.properties ->> 'public_id'::text)) AS dataset_public_id
   FROM ((((((((((((((public.resource sdafiles
     JOIN public.resource_type sdafile_type ON (((sdafiles.resource_type_id = sdafile_type.id) AND (sdafile_type.name = 'SdaFile'::text))))
     JOIN public.relationship ON ((sdafiles.id = relationship.domain_resource_id)))
     JOIN public.relationship_rule_view ON (((relationship_rule_view.domain_type_name = 'SdaFile'::text) AND (relationship_rule_view.range_type_name = 'Study'::text) AND (relationship.relationship_rule_id = relationship_rule_view.id))))
     JOIN public.resource study ON ((relationship.range_resource_id = study.id)))
     LEFT JOIN public.relationship_rule_view sdafile_run_relationship_rule_view ON (((sdafile_run_relationship_rule_view.domain_type_name = 'SdaFile'::text) AND (sdafile_run_relationship_rule_view.range_type_name ~~ '%Run%'::text))))
     LEFT JOIN public.relationship sdafile_run_relationship_view ON (((sdafile_run_relationship_view.relationship_rule_id = sdafile_run_relationship_rule_view.id) AND (sdafile_run_relationship_view.domain_resource_id = sdafiles.id))))
     LEFT JOIN public.relationship_rule_view run_dataset_relationship_rule_view ON (((run_dataset_relationship_rule_view.domain_type_name ~~ '%Run%'::text) AND (run_dataset_relationship_rule_view.range_type_name ~~ '%Dataset%'::text))))
     LEFT JOIN public.relationship run_dataset_relationship_view ON (((run_dataset_relationship_view.relationship_rule_id = run_dataset_relationship_rule_view.id) AND (run_dataset_relationship_view.domain_resource_id = sdafile_run_relationship_view.range_resource_id))))
     LEFT JOIN public.resource run_dataset ON ((run_dataset_relationship_view.range_resource_id = run_dataset.id)))
     LEFT JOIN public.relationship_rule_view sdafile_analysis_relationship_rule_view ON (((sdafile_analysis_relationship_rule_view.domain_type_name = 'SdaFile'::text) AND (sdafile_analysis_relationship_rule_view.range_type_name ~~ '%Analysis%'::text))))
     LEFT JOIN public.relationship sdafile_analysis_relationship_view ON (((sdafile_analysis_relationship_view.relationship_rule_id = sdafile_analysis_relationship_rule_view.id) AND (sdafile_analysis_relationship_view.domain_resource_id = sdafiles.id))))
     LEFT JOIN public.relationship_rule_view analysis_dataset_relationship_rule_view ON (((analysis_dataset_relationship_rule_view.domain_type_name ~~ '%Analysis%'::text) AND (analysis_dataset_relationship_rule_view.range_type_name ~~ '%Dataset%'::text))))
     LEFT JOIN public.relationship analysis_dataset_relationship_view ON (((analysis_dataset_relationship_view.relationship_rule_id = analysis_dataset_relationship_rule_view.id) AND (analysis_dataset_relationship_view.domain_resource_id = sdafile_analysis_relationship_view.range_resource_id))))
     LEFT JOIN public.resource analysis_dataset ON ((analysis_dataset_relationship_view.range_resource_id = analysis_dataset.id)))
  WHERE (sdafiles.status_type_id = ANY (ARRAY['PUB'::text, 'VER'::text]));


--
-- Name: sdafile_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.sdafile_view AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS study_id,
    NULL::text AS study_public_id,
    NULL::text AS study_title,
    NULL::uuid AS file_id,
    NULL::text AS public_id,
    NULL::text AS status_type_id,
    NULL::text AS title,
    NULL::text AS status,
    NULL::text AS file_type,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::integer AS creator_id,
    NULL::text AS creator_name,
    NULL::text AS creator_username;


--
-- Name: status_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_type (
    id text NOT NULL,
    name text NOT NULL,
    class_name text,
    CONSTRAINT status_type_id_check CHECK ((length(id) = 3))
);


--
-- Name: study_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.study_view AS
SELECT
    NULL::uuid AS id,
    NULL::text AS public_id,
    NULL::text AS title,
    NULL::text AS status_type_id,
    NULL::text AS status,
    NULL::jsonb AS properties,
    NULL::timestamp without time zone AS creation_date,
    NULL::timestamp without time zone AS last_update,
    NULL::text AS released_date,
    NULL::integer AS creator_id,
    NULL::text AS creator_name,
    NULL::text AS creator_username,
    NULL::bigint AS nb_samples,
    NULL::bigint AS nb_experiments,
    NULL::bigint AS nb_runs,
    NULL::bigint AS nb_analyses,
    NULL::bigint AS nb_datasets,
    NULL::bigint AS nb_public_datasets;


--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_id_seq
    START WITH 3
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    id integer DEFAULT nextval('public.user_id_seq'::regclass) NOT NULL,
    email text NOT NULL,
    properties jsonb,
    external_id text NOT NULL,
    cega_username text
);


--
-- Name: user_key_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_key_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_key_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_key_log (
    id integer DEFAULT nextval('public.user_key_log_id_seq'::regclass) NOT NULL,
    user_id integer,
    key_type text,
    key_sha text,
    action_time timestamp without time zone DEFAULT now() NOT NULL,
    action_type_id text NOT NULL
);


--
-- Name: action_type action_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_type
    ADD CONSTRAINT action_type_pkey PRIMARY KEY (id);


--
-- Name: namespace namespace_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace
    ADD CONSTRAINT namespace_pkey PRIMARY KEY (prefix);


--
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission
    ADD CONSTRAINT permission_pkey PRIMARY KEY (id);


--
-- Name: predicate predicate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.predicate
    ADD CONSTRAINT predicate_pkey PRIMARY KEY (id);


--
-- Name: relationship_log relationship_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship_log
    ADD CONSTRAINT relationship_log_pkey PRIMARY KEY (id);


--
-- Name: relationship relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_pkey PRIMARY KEY (id);


--
-- Name: relationship_rule relationship_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship_rule
    ADD CONSTRAINT relationship_rule_pkey PRIMARY KEY (id);


--
-- Name: resource_acl resource_acl_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_acl
    ADD CONSTRAINT resource_acl_pkey PRIMARY KEY (resource_id, user_id);


--
-- Name: resource_log resource_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_log
    ADD CONSTRAINT resource_log_pkey PRIMARY KEY (id);


--
-- Name: resource resource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT resource_pkey PRIMARY KEY (id);


--
-- Name: resource_type resource_type_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_type
    ADD CONSTRAINT resource_type_pkey1 PRIMARY KEY (id);


--
-- Name: rmq_correlation rmq_correlation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rmq_correlation
    ADD CONSTRAINT rmq_correlation_pkey PRIMARY KEY (correlation_id);


--
-- Name: role_permission role_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: status_type status_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_type
    ADD CONSTRAINT status_type_pkey PRIMARY KEY (id);


--
-- Name: user_key_log user_key_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_key_log
    ADD CONSTRAINT user_key_log_pkey PRIMARY KEY (id);


--
-- Name: cega_usernamex; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cega_usernamex ON public."user" USING btree (cega_username);


--
-- Name: external_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX external_idx ON public."user" USING btree (external_id);


--
-- Name: user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_idx ON public."user" USING btree (id);


--
-- Name: molecularsample_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.molecularsample_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS sample_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    (resource.properties ->> 'title'::text) AS title,
    (resource.properties ->> 'alias'::text) AS alias,
    max(status_type.name) AS status,
    resource_type.name AS sample_type,
    resource.status_type_id,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name = 'MolecularSample'::text)
  GROUP BY resource.id, study.id, resource_type.name;


--
-- Name: molecularrun_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.molecularrun_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS sample_id,
    (resource.properties ->> 'title'::text) AS title,
    (resource.properties ->> 'public_id'::text) AS public_id,
    (resource.properties ->> 'run_file_type'::text) AS run_file_type,
    (resource.properties ->> 'sample_public_id'::text) AS sample_public_id,
    (resource.properties ->> 'experiment_public_id'::text) AS experiment_public_id,
    status_type.name AS status,
    resource.status_type_id,
    resource_type.name AS run_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name = 'MolecularRun'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: molecularexperiment_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.molecularexperiment_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS experiment_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    (resource.properties ->> 'title'::text) AS title,
    resource.status_type_id,
    status_type.name AS status,
    resource_type.name AS experiment_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name = 'MolecularExperiment'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: molecularanalysis_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.molecularanalysis_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS analysis_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    resource_type.name AS analysis_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name ~~ '%Analysis%'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: file_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.file_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS file_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    resource_type.name AS file_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     LEFT JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     LEFT JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     LEFT JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name ~~ '%File%'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: analysis_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.analysis_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS analysis_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    resource_type.name AS analysis_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name ~~ '%Analysis%'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: resource_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.resource_view AS
 SELECT resource.id,
    (resource.properties ->> 'title'::text) AS title,
    resource.properties,
    resource.status_type_id,
    resource.resource_type_id,
    resource_type.name AS resource_type,
    string_agg(DISTINCT (u.properties ->> 'name'::text), ','::text) AS usernames,
    min(resource_log.action_time) AS creation_date
   FROM ((((public.resource
     JOIN public.resource_type ON ((resource.resource_type_id = resource_type.id)))
     JOIN public.resource_acl ON ((resource.id = resource_acl.resource_id)))
     JOIN public."user" u ON ((u.id = resource_acl.user_id)))
     JOIN public.resource_log ON ((resource_log.resource_id = resource.id)))
  WHERE (resource.status_type_id <> 'DEL'::text)
  GROUP BY resource.id, resource_type.id;


--
-- Name: run_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.run_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS sample_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    (resource.properties ->> 'title'::text) AS title,
    (resource.properties ->> 'run_file_type'::text) AS run_file_type,
    (resource.properties ->> 'sample_public_id'::text) AS sample_public_id,
    (resource.properties ->> 'experiment_public_id'::text) AS experiment_public_id,
    status_type.name AS status,
    resource.status_type_id,
    resource_type.name AS run_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name = 'MolecularRun'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: sample_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.sample_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS sample_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    (resource.properties ->> 'title'::text) AS title,
    (resource.properties ->> 'alias'::text) AS alias,
    resource.status_type_id,
    status_type.name AS status,
    resource_type.name AS sample_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE ((resource_type.name ~~ '%Sample%'::text) AND (resource.status_type_id <> 'DEL'::text))
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name
  ORDER BY (resource.properties ->> 'public_id'::text);


--
-- Name: experiment_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.experiment_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS experiment_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    status_type.id AS status_type_id,
    resource_type.name AS experiment_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE ((resource_type.name ~~ '%Experiment%'::text) AND (resource.status_type_id <> 'DEL'::text))
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: dac_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.dac_view AS
 SELECT resource.id,
    resource.id AS dac_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name
   FROM (((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
  WHERE (resource_type.name = 'DAC'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, resource_type.name;


--
-- Name: sdafile_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.sdafile_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS file_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    resource_type.name AS file_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name,
    max((creator.properties ->> 'email'::text)) AS creator_username
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     LEFT JOIN public.relationship ON ((relationship.domain_resource_id = resource.id)))
     LEFT JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     LEFT JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name ~~ '%SdaFile%'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: policy_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.policy_view AS
 SELECT resource.id,
    resource.id AS policy_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    resource.properties,
    (resource.properties ->> 'dac_id'::text) AS dac_id
   FROM ((public.resource
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
  WHERE (resource_type.name = 'Policy'::text)
  GROUP BY resource.id, status_type.id, resource_type.name;


--
-- Name: study_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.study_view AS
 SELECT studies.id,
    (studies.properties ->> 'public_id'::text) AS public_id,
    (studies.properties ->> 'title'::text) AS title,
    studies.status_type_id,
    status_type.name AS status,
    studies.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(public_datasets.released_date) AS released_date,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name,
    max((creator.properties ->> 'preferred_username'::text)) AS creator_username,
    COALESCE(samples.nb_resources, (0)::bigint) AS nb_samples,
    COALESCE(experiments.nb_resources, (0)::bigint) AS nb_experiments,
    COALESCE(runs.nb_resources, (0)::bigint) AS nb_runs,
    COALESCE(analyses.nb_resources, (0)::bigint) AS nb_analyses,
    COALESCE(datasets.nb_resources, (0)::bigint) AS nb_datasets,
    COALESCE(public_datasets.nb_resources, (0)::bigint) AS nb_public_datasets
   FROM ((((((((((((public.resource studies
     JOIN public.resource_log ON ((studies.id = resource_log.resource_id)))
     LEFT JOIN public.resource_log log_pub ON (((studies.id = log_pub.resource_id) AND ((log_pub.properties ->> 'status_type_id'::text) = 'PUB'::text))))
     JOIN public.resource_acl ON (((studies.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.resource_type study_type ON (((studies.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
     JOIN public.status_type ON ((studies.status_type_id = status_type.id)))
     LEFT JOIN ( SELECT relationship.range_resource_id AS study_id,
            count(DISTINCT relationship.domain_resource_id) AS nb_resources
           FROM ((((public.relationship
             JOIN public.resource samples_1 ON ((relationship.domain_resource_id = samples_1.id)))
             JOIN public.relationship_rule ON ((relationship.relationship_rule_id = relationship_rule.id)))
             JOIN public.resource_type range_type ON (((relationship_rule.range_type_id = range_type.id) AND (range_type.name = 'Study'::text))))
             JOIN public.resource_type domain_type ON (((relationship_rule.domain_type_id = domain_type.id) AND (domain_type.name ~~ '%Sample'::text))))
          WHERE (relationship.is_active = true)
          GROUP BY relationship.range_resource_id) samples ON ((studies.id = samples.study_id)))
     LEFT JOIN ( SELECT relationship.range_resource_id AS study_id,
            count(DISTINCT relationship.domain_resource_id) AS nb_resources
           FROM ((((public.relationship
             JOIN public.resource samples_1 ON ((relationship.domain_resource_id = samples_1.id)))
             JOIN public.relationship_rule ON ((relationship.relationship_rule_id = relationship_rule.id)))
             JOIN public.resource_type range_type ON (((relationship_rule.range_type_id = range_type.id) AND (range_type.name = 'Study'::text))))
             JOIN public.resource_type domain_type ON (((relationship_rule.domain_type_id = domain_type.id) AND (domain_type.name ~~ '%Experiment'::text))))
          WHERE (relationship.is_active = true)
          GROUP BY relationship.range_resource_id) experiments ON ((studies.id = experiments.study_id)))
     LEFT JOIN ( SELECT relationship.range_resource_id AS study_id,
            count(DISTINCT relationship.domain_resource_id) AS nb_resources
           FROM ((((public.relationship
             JOIN public.resource samples_1 ON ((relationship.domain_resource_id = samples_1.id)))
             JOIN public.relationship_rule ON ((relationship.relationship_rule_id = relationship_rule.id)))
             JOIN public.resource_type range_type ON (((relationship_rule.range_type_id = range_type.id) AND (range_type.name = 'Study'::text))))
             JOIN public.resource_type domain_type ON (((relationship_rule.domain_type_id = domain_type.id) AND (domain_type.name ~~ '%Run'::text))))
          WHERE (relationship.is_active = true)
          GROUP BY relationship.range_resource_id) runs ON ((studies.id = runs.study_id)))
     LEFT JOIN ( SELECT relationship.range_resource_id AS study_id,
            count(DISTINCT relationship.domain_resource_id) AS nb_resources
           FROM ((((public.relationship
             JOIN public.resource analyses_1 ON ((relationship.domain_resource_id = analyses_1.id)))
             JOIN public.relationship_rule ON ((relationship.relationship_rule_id = relationship_rule.id)))
             JOIN public.resource_type range_type ON (((relationship_rule.range_type_id = range_type.id) AND (range_type.name = 'Study'::text))))
             JOIN public.resource_type domain_type ON (((relationship_rule.domain_type_id = domain_type.id) AND (domain_type.name ~~ '%Analysis'::text))))
          WHERE (relationship.is_active = true)
          GROUP BY relationship.range_resource_id) analyses ON ((studies.id = analyses.study_id)))
     LEFT JOIN ( SELECT relationship.range_resource_id AS study_id,
            count(DISTINCT relationship.domain_resource_id) AS nb_resources
           FROM ((((public.relationship
             JOIN public.resource datasets_1 ON ((relationship.domain_resource_id = datasets_1.id)))
             JOIN public.relationship_rule ON ((relationship.relationship_rule_id = relationship_rule.id)))
             JOIN public.resource_type range_type ON (((relationship_rule.range_type_id = range_type.id) AND (range_type.name = 'Study'::text))))
             JOIN public.resource_type domain_type ON (((relationship_rule.domain_type_id = domain_type.id) AND (domain_type.name ~~ '%Dataset'::text))))
          WHERE (relationship.is_active = true)
          GROUP BY relationship.range_resource_id) datasets ON ((studies.id = datasets.study_id)))
     LEFT JOIN ( SELECT relationship.range_resource_id AS study_id,
            count(DISTINCT relationship.domain_resource_id) AS nb_resources,
            max((public_datasets_1.properties ->> 'released_date'::text)) AS released_date
           FROM ((((public.relationship
             JOIN public.resource public_datasets_1 ON (((relationship.domain_resource_id = public_datasets_1.id) AND (public_datasets_1.status_type_id = 'PUB'::text))))
             JOIN public.relationship_rule ON ((relationship.relationship_rule_id = relationship_rule.id)))
             JOIN public.resource_type range_type ON (((relationship_rule.range_type_id = range_type.id) AND (range_type.name = 'Study'::text))))
             JOIN public.resource_type domain_type ON (((relationship_rule.domain_type_id = domain_type.id) AND (domain_type.name ~~ '%Dataset'::text))))
          WHERE ((relationship.is_active = true) AND (((public_datasets_1.properties ->> 'released_date'::text))::date <= CURRENT_DATE))
          GROUP BY relationship.range_resource_id) public_datasets ON ((studies.id = public_datasets.study_id)))
  GROUP BY studies.id, resource_log.resource_id, resource_acl.resource_id, status_type.name, samples.nb_resources, experiments.nb_resources, runs.nb_resources, analyses.nb_resources, datasets.nb_resources, public_datasets.nb_resources;


--
-- Name: dataset_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.dataset_view AS
 SELECT resource.id,
    study.id AS study_id,
    (study.properties ->> 'public_id'::text) AS study_public_id,
    (study.properties ->> 'title'::text) AS study_title,
    resource.id AS analysis_id,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    (resource.properties ->> 'title'::text) AS title,
    status_type.name AS status,
    resource_type.name AS dataset_type,
    resource.properties,
    min(resource_log.action_time) AS creation_date,
    max(resource_log.action_time) AS last_update,
    max(creator.id) AS creator_id,
    max((creator.properties ->> 'name'::text)) AS creator_name,
    max((creator.properties ->> 'email'::text)) AS creator_email,
    max((creator.properties ->> 'preferred_username'::text)) AS creator_username,
    max((creator.properties ->> 'sub'::text)) AS creator_sub,
    (resource.properties ->> 'released_date'::text) AS released_date
   FROM ((((((((public.resource
     JOIN public.resource_log ON ((resource.id = resource_log.resource_id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public.resource_acl ON (((resource.id = resource_acl.resource_id) AND (resource_acl.role_id = 'OWN'::text))))
     JOIN public."user" creator ON ((resource_acl.user_id = creator.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.relationship ON (((relationship.domain_resource_id = resource.id) AND (relationship.is_active = true))))
     JOIN public.resource study ON ((study.id = relationship.range_resource_id)))
     JOIN public.resource_type study_type ON (((study.resource_type_id = study_type.id) AND (study_type.name = 'Study'::text))))
  WHERE (resource_type.name ~~ '%Dataset%'::text)
  GROUP BY resource.id, resource_log.resource_id, resource_acl.resource_id, status_type.id, study.id, resource_type.name;


--
-- Name: resource_user_view _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.resource_user_view AS
 SELECT resource_acl.resource_id,
    resource_acl.user_id,
    resource_type.name AS resource_type_name,
    (resource.properties ->> 'public_id'::text) AS public_id,
    resource.status_type_id,
    status_type.name AS status,
    string_agg(DISTINCT permission.name, ','::text) AS permissions,
    access_user.id,
    COALESCE((access_user.properties ->> 'preferred_username'::text), access_user.external_id) AS preferred_username,
    (access_user.properties ->> 'name'::text) AS username,
    COALESCE((access_user.properties ->> 'email'::text), access_user.email) AS email,
    COALESCE((access_user.properties ->> 'sub'::text), ''::text) AS creator_sub,
    role_permission.role_id,
    role.name AS role
   FROM (((((((public.resource_acl
     JOIN public.role_permission ON ((resource_acl.role_id = role_permission.role_id)))
     JOIN public.role ON ((role_permission.role_id = role.id)))
     JOIN public.permission ON ((role_permission.permission_id = permission.id)))
     JOIN public.resource ON ((resource_acl.resource_id = resource.id)))
     JOIN public.status_type ON ((resource.status_type_id = status_type.id)))
     JOIN public.resource_type ON ((resource_type.id = resource.resource_type_id)))
     JOIN public."user" access_user ON ((resource_acl.user_id = access_user.id)))
  GROUP BY resource_acl.user_id, resource_acl.resource_id, resource_type.id, access_user.id, role.id, role_permission.role_id, (access_user.properties ->> 'name'::text), status_type.id, resource.status_type_id, (resource.properties ->> 'public_id'::text), (access_user.properties ->> 'email'::text), access_user.email, COALESCE((access_user.properties ->> 'preferred_username'::text), access_user.external_id), COALESCE((access_user.properties ->> 'sub'::text), ''::text);


--
-- Name: resource trg_public_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_public_id BEFORE INSERT ON public.resource FOR EACH ROW EXECUTE FUNCTION public.get_public_id();


--
-- Name: resource trg_set_public_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_public_id BEFORE UPDATE ON public.resource FOR EACH ROW EXECUTE FUNCTION public.set_public_id();


--
-- Name: predicate predicate_prefix_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.predicate
    ADD CONSTRAINT predicate_prefix_fkey FOREIGN KEY (prefix) REFERENCES public.namespace(prefix) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: relationship relationship_domain_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_domain_resource_id_fkey FOREIGN KEY (domain_resource_id) REFERENCES public.resource(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: relationship_log relationship_log_action_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship_log
    ADD CONSTRAINT relationship_log_action_type_id_fkey FOREIGN KEY (action_type_id) REFERENCES public.action_type(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: relationship_log relationship_log_relationship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship_log
    ADD CONSTRAINT relationship_log_relationship_id_fkey FOREIGN KEY (relationship_id) REFERENCES public.relationship(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: relationship relationship_predicate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_predicate_id_fkey FOREIGN KEY (predicate_id) REFERENCES public.predicate(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: relationship relationship_range_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_range_resource_id_fkey FOREIGN KEY (range_resource_id) REFERENCES public.resource(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: relationship relationship_relationship_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_relationship_rule_id_fkey FOREIGN KEY (relationship_rule_id) REFERENCES public.relationship_rule(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: relationship_rule relationship_rule_domain_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship_rule
    ADD CONSTRAINT relationship_rule_domain_type_id_fkey FOREIGN KEY (domain_type_id) REFERENCES public.resource_type(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: relationship_rule relationship_rule_predicate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship_rule
    ADD CONSTRAINT relationship_rule_predicate_id_fkey FOREIGN KEY (predicate_id) REFERENCES public.predicate(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: relationship_rule relationship_rule_range_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship_rule
    ADD CONSTRAINT relationship_rule_range_type_id_fkey FOREIGN KEY (range_type_id) REFERENCES public.resource_type(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: resource_acl resource_acl_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_acl
    ADD CONSTRAINT resource_acl_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.resource(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: resource_acl resource_acl_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_acl
    ADD CONSTRAINT resource_acl_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: resource_log resource_log_action_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_log
    ADD CONSTRAINT resource_log_action_type_id_fkey FOREIGN KEY (action_type_id) REFERENCES public.action_type(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: resource_log resource_log_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_log
    ADD CONSTRAINT resource_log_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.resource(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: resource resource_resource_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT resource_resource_type_id_fkey FOREIGN KEY (resource_type_id) REFERENCES public.resource_type(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: resource resource_status_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT resource_status_type_id_fkey FOREIGN KEY (status_type_id) REFERENCES public.status_type(id) ON UPDATE RESTRICT ON DELETE RESTRICT;



--
-- Name: resource_type resource_type_prefix_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_type
    ADD CONSTRAINT resource_type_prefix_fkey FOREIGN KEY (prefix) REFERENCES public.namespace(prefix) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: rmq_correlation rmq_correlation_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rmq_correlation
    ADD CONSTRAINT rmq_correlation_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.resource(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_permission role_permission_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permission(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: role_permission role_permission_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: user_key_log user_key_log_action_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_key_log
    ADD CONSTRAINT user_key_log_action_type_id_fkey FOREIGN KEY (action_type_id) REFERENCES public.action_type(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_key_log user_key_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_key_log
    ADD CONSTRAINT user_key_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;



INSERT INTO "public"."namespace" ("prefix", "uri", "name") VALUES
('ega', 'https://ega-archive.org/', 'European Genome-phenome Archive'),
('ena', 'https://www.ebi.ac.uk/ena/', 'European Nucleotide Archive'),
('fega', 'https://ega-archive.org/about/projects-and-funders/federated-ega/', 'FEGA ontology'),
('prov', 'http://www.w3.org/ns/prov#', 'Provenance Ontology'),
('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'RDF Vocabulary'),
('rdfs', 'http://www.w3.org/2000/01/rdf-schema#', 'RDF Schema Vocabulary'),
('sra', 'https://www.ncbi.nlm.nih.gov/sra/', 'Sequence Read Archive'),
('xsd', 'http://www.w3.org/2001/XMLSchema#', 'XML Schema Datatypes')
ON CONFLICT DO NOTHING;


INSERT INTO "public"."resource_type" ("id", "prefix", "name", "properties", "public_id_prefix", "validator_mandatory") VALUES
(1, 'ega', 'DAC', '{"ui_schema": {"type": "group", "elements": [{"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"rule": {"effect": "SHOW", "condition": {"scope": "#", "schema": {"required": ["public_id"], "properties": {"public_id": {"type": "string"}}}}}, "type": "Control", "label": "FEGA DAC ID", "scope": "#/properties/public_id", "options": {"readonly": true}}, {"type": "Control", "label": "Title", "scope": "#/properties/name"}]}, {"type": "Control", "label": "Description", "scope": "#/properties/description"}]}]}, "data_schema": {"type": "object", "title": "DacRequest", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title", "description"], "properties": {"name": {"type": "string", "description": "Name of the Data Access Commitee"}, "members": {"type": "array", "items": {"type": "object", "required": ["email", "first_name", "last_name", "institution_name"], "properties": {"role": {"type": "string"}, "email": {"type": "string", "description": "Email of contact person"}, "status": {"type": "string"}, "userID": {"type": "string", "format": "uuid"}, "lastName": {"type": "string", "description": "Last name (surname) of contact person"}, "firstName": {"type": "string", "description": "First name of contact person"}}}, "uniqueItems": true}, "public_id": {"type": "string", "pattern": "^CHFEGAC[0-9]{11}", "description": "DAC public_id"}, "description": {"type": "string", "description": "Description of the DAC"}}}}', 'CHFEGAC', 'f'),
(2, 'ega', 'Dataset', '{"ui_schema": {"type": "group", "elements": [{"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"type": "VerticalLayout", "elements": [{"rule": {"effect": "SHOW", "condition": {"scope": "#", "schema": {"required": ["public_id"], "properties": {"public_id": {"type": "string"}}}}}, "type": "Control", "label": "FEGA Dataset ID", "scope": "#/properties/public_id", "options": {"readonly": true}}, {"type": "Control", "label": "Title", "scope": "#/properties/title"}, {"type": "Control", "label": "Description", "scope": "#/properties/description"}, {"type": "Control", "label": "Release Date", "scope": "#/properties/released_date", "options": {"format": "date", "dateFormat": "DD.MM.YYYY", "dateSaveFormat": "YYYY-MM-DD"}}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/extra_attributes"}]}]}, {"type": "VerticalLayout", "elements": [{"type": "Control", "label": "Dataset types", "scope": "#/properties/dataset_types"}]}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "label": "Runs", "scope": "#/properties/run_public_ids"}, {"type": "Control", "label": "Analyses", "scope": "#/properties/analysis_public_ids"}]}]}]}, "data_schema": {"type": "object", "title": "Dataset", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title", "description", "dataset_types", "run_public_ids", "released_date"], "properties": {"title": {"type": "string"}, "policy_id": {"type": ["string", "null"], "format": "uuid"}, "public_id": {"type": "string", "pattern": "^CHFEGAD[0-9]{11}"}, "description": {"type": "string"}, "dataset_types": {"type": "array", "items": {"enum": ["Whole genome sequencing", "Exome sequencing", "Genotyping by array", "Transcriptome profiling by high-throughput sequencing", "Transcriptome profiling by array", "Amplicon sequencing", "Methylation binding domain sequencing", "Methylation profiling by high-throughput sequencing", "Phenotype information", "Study summary information", "Genomic variant calling", "Chromatin accessibility profiling by high-throughput sequencing", "Histone modification profiling by high-throughput sequencing", "Chip-Seq"], "type": "string"}, "x-check": "verticalcheckbox", "uniqueItems": true}, "released_date": {"type": "string", "format": "date"}, "run_public_ids": {"type": "array", "items": {"type": "string", "pattern": "^CHFEGAR[0-9]{11}"}, "x-check": "MolecularRuns", "uniqueItems": true}, "extra_attributes": {"type": "array", "items": {"type": "object", "required": ["tag", "value", "unit"], "properties": {"tag": {"type": "string"}, "unit": {"type": "string"}, "value": {"type": "string"}}}}, "policy_public_id": {"type": ["string", "null"], "pattern": "^CHFEGAP[0-9]{11}", "x-check": "Policy", "description": "Data Access Policy Public ID", "x-check_title": "title", "x-check_value": "public_id"}, "analysis_public_ids": {"type": "array", "items": {"type": "string", "pattern": "^CHFEGAZ[0-9]{11}"}, "x-check": "MolecularAnalysis", "uniqueItems": true, "x-check_title": "title", "x-check_value": "public_id"}}, "x-resource": {"schema": {"fields": [{"name": "title", "constraints": {"required": true}}, {"name": "description", "constraints": {"required": true}}, {"name": "dataset_types", "type": "list", "constraints": {"required": true}}, {"name": "runs", "type": "list"}, {"name": "analyses", "type": "list"}], "primaryKey": ["title"], "foreignKeys": [{"type": "list", "fields": ["runs"], "reference": {"fields": ["title"], "resource": "MolecularRun"}}, {"fields": ["analyses"], "reference": {"fields": ["title"], "resource": "MolecularAnalysis"}}]}}}}', 'CHFEGAD', 't'),
(3, 'ega', 'Policy', '{"ui_schema": {"type": "group", "elements": [{"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"rule": {"effect": "SHOW", "condition": {"scope": "#", "schema": {"required": ["public_id"], "properties": {"public_id": {"type": "string"}}}}}, "type": "Control", "label": "FEGA Policy ID", "scope": "#/properties/public_id", "options": {"readonly": true}}, {"type": "Control", "label": "Title", "scope": "#/properties/title"}, {"type": "Control", "label": "Policy Url", "scope": "#/properties/url"}]}, {"type": "Control", "label": "Policy content", "scope": "#/properties/description"}]}]}, "data_schema": {"type": "object", "title": "Policy", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title"], "properties": {"url": {"type": "string", "description": "URL of the Policy"}, "title": {"type": "string", "description": "Name of the Policy"}, "dac_id": {"type": "string", "format": "uuid"}, "public_id": {"type": "string", "pattern": "^CHFEGAP[0-9]{11}", "description": "Policy public_id"}, "description": {"type": "string", "description": "The policy content"}}}}', 'CHFEGAP', 'f'),
(4, 'ena', 'Assembly', NULL, NULL, 'f'),
(5, 'ena', 'Checklist', NULL, NULL, 'f'),
(6, 'ena', 'Project', NULL, NULL, 'f'),
(7, 'sra', 'MolecularAnalysis', '{"ui_schema": {"type": "group", "elements": [{"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"type": "VerticalLayout", "elements": [{"type": "Control", "label": "Files", "scope": "#/properties/sdafile_public_ids"}, {"type": "Control", "label": "Experiments", "scope": "#/properties/molecularexperiment_public_ids"}]}, {"type": "VerticalLayout", "elements": [{"type": "Control", "label": "Samples", "scope": "#/properties/sample_public_ids"}]}]}, {"type": "HorizontalLayout", "elements": [{"type": "VerticalLayout", "elements": [{"type": "Control", "scope": "#/properties/title"}, {"type": "Control", "scope": "#/properties/description"}]}, {"type": "VerticalLayout", "elements": [{"type": "Control", "label": "Type", "scope": "#/properties/analysis_type"}, {"type": "Control", "label": "Platform", "scope": "#/properties/platform"}, {"type": "Control", "label": "Reference Genome", "scope": "#/properties/genome_id"}]}, {"type": "VerticalLayout", "elements": [{"type": "Control", "scope": "#/properties/experiment_types"}]}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/extra_attributes"}]}]}], "displayedElements": ["properties.title", "properties.analysis_type", "properties.platform", "properties.experiment_types"]}, "data_schema": {"type": "object", "title": "AnalysisRequest", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title", "description", "analysis_type", "sdafile_public_ids", "experiment_types", "genome_id", "platform", "molecularexperiment_public_ids", "sample_public_ids"], "properties": {"title": {"type": "string", "description": "Title of the analysis"}, "platform": {"type": "string", "description": "Name of the analysis platform"}, "genome_id": {"enum": ["NCBI36: GCF_000001405.12", "GRCh37: GCA_000001405.1", "GRCh37.p1: GCA_000001405.2", "GRCh37.p2: GCA_000001405.3", "GRCh37.p3: GCA_000001405.4", "GRCh37.p4: GCA_000001405.5", "GRCh37.p5: GCA_000001405.6", "GRCh37.p6: GCA_000001405.7", "GRCh37.p7: GCA_000001405.8", "GRCh37.p8: GCA_000001405.9", "GRCh37.p9: GCA_000001405.10", "GRCh37.p10: GCA_000001405.11", "GRCh37.p11: GCA_000001405.12", "GRCh37.p12: GCA_000001405.13", "GRCh37.p13: GCA_000001405.14", "GRCh38: GCA_000001405.15", "GRCh38.p2: GCA_000001405.17", "GRCh38.p3: GCA_000001405.18", "GRCh38.p4: GCA_000001405.19", "GRCh38.p5: GCA_000001405.20", "GRCh38.p6: GCA_000001405.21", "GRCh38.p7: GCA_000001405.22", "GRCh38.p8: GCA_000001405.23", "GRCh38.p9: GCA_000001405.24", "GRCh38.p10: GCA_000001405.25", "GRCh38.p11: GCA_000001405.26", "GRCh38.p12: GCA_000001405.27", "GRCh38.p13: GCA_000001405.28", "GRCh38.p14: GCA_000001405.29"], "type": "string", "description": "Genome version used in the analysis"}, "public_id": {"type": "string", "pattern": "^CHFEGAZ[0-9]{11}", "description": "Public ID of the analysis"}, "chromosomes": {"enum": [{"id": 1, "name": "chr1", "accession": "NC_000001.9", "genome_group_id": 1}, {"id": 2, "name": "chr2", "accession": "NC_000002.10", "genome_group_id": 1}, {"id": 3, "name": "chr3", "accession": "NC_000003.10", "genome_group_id": 1}, {"id": 4, "name": "chr4", "accession": "NC_000004.10", "genome_group_id": 1}, {"id": 5, "name": "chr5", "accession": "NC_000005.8", "genome_group_id": 1}, {"id": 6, "name": "chr6", "accession": "NC_000006.10", "genome_group_id": 1}, {"id": 7, "name": "chr7", "accession": "NC_000007.12", "genome_group_id": 1}, {"id": 8, "name": "chr8", "accession": "NC_000008.9", "genome_group_id": 1}, {"id": 9, "name": "chr9", "accession": "NC_000009.10", "genome_group_id": 1}, {"id": 10, "name": "chr10", "accession": "NC_000010.9", "genome_group_id": 1}, {"id": 11, "name": "chr11", "accession": "NC_000011.8", "genome_group_id": 1}, {"id": 12, "name": "chr12", "accession": "NC_000012.10", "genome_group_id": 1}, {"id": 13, "name": "chr13", "accession": "NC_000013.9", "genome_group_id": 1}, {"id": 14, "name": "chr14", "accession": "NC_000014.7", "genome_group_id": 1}, {"id": 15, "name": "chr15", "accession": "NC_000015.8", "genome_group_id": 1}, {"id": 16, "name": "chr16", "accession": "NC_000016.8", "genome_group_id": 1}, {"id": 17, "name": "chr17", "accession": "NC_000017.9", "genome_group_id": 1}, {"id": 18, "name": "chr18", "accession": "NC_000018.8", "genome_group_id": 1}, {"id": 19, "name": "chr19", "accession": "NC_000019.8", "genome_group_id": 1}, {"id": 20, "name": "chr20", "accession": "NC_000020.9", "genome_group_id": 1}, {"id": 21, "name": "chr21", "accession": "NC_000021.7", "genome_group_id": 1}, {"id": 22, "name": "chr22", "accession": "NC_000022.9", "genome_group_id": 1}, {"id": 23, "name": "chrX", "accession": "NC_000023.9", "genome_group_id": 1}, {"id": 24, "name": "chrY", "accession": "NC_000024.8", "genome_group_id": 1}, {"id": 25, "name": "1", "accession": "CM000663.1", "genome_group_id": 2}, {"id": 26, "name": "2", "accession": "CM000664.1", "genome_group_id": 2}, {"id": 27, "name": "3", "accession": "CM000665.1", "genome_group_id": 2}, {"id": 28, "name": "4", "accession": "CM000666.1", "genome_group_id": 2}, {"id": 29, "name": "5", "accession": "CM000667.1", "genome_group_id": 2}, {"id": 30, "name": "6", "accession": "CM000668.1", "genome_group_id": 2}, {"id": 31, "name": "7", "accession": "CM000669.1", "genome_group_id": 2}, {"id": 32, "name": "8", "accession": "CM000670.1", "genome_group_id": 2}, {"id": 33, "name": "9", "accession": "CM000671.1", "genome_group_id": 2}, {"id": 34, "name": "10", "accession": "CM000672.1", "genome_group_id": 2}, {"id": 35, "name": "11", "accession": "CM000673.1", "genome_group_id": 2}, {"id": 36, "name": "12", "accession": "CM000674.1", "genome_group_id": 2}, {"id": 37, "name": "13", "accession": "CM000675.1", "genome_group_id": 2}, {"id": 38, "name": "14", "accession": "CM000676.1", "genome_group_id": 2}, {"id": 39, "name": "15", "accession": "CM000677.1", "genome_group_id": 2}, {"id": 40, "name": "16", "accession": "CM000678.1", "genome_group_id": 2}, {"id": 41, "name": "17", "accession": "CM000679.1", "genome_group_id": 2}, {"id": 42, "name": "18", "accession": "CM000680.1", "genome_group_id": 2}, {"id": 43, "name": "19", "accession": "CM000681.1", "genome_group_id": 2}, {"id": 44, "name": "20", "accession": "CM000682.1", "genome_group_id": 2}, {"id": 45, "name": "21", "accession": "CM000683.1", "genome_group_id": 2}, {"id": 46, "name": "22", "accession": "CM000684.1", "genome_group_id": 2}, {"id": 47, "name": "X", "accession": "CM000685.1", "genome_group_id": 2}, {"id": 48, "name": "Y", "accession": "CM000686.1", "genome_group_id": 2}, {"id": 49, "name": "MT", "accession": "J01415.2", "genome_group_id": 2}, {"id": 50, "name": "chr1", "accession": "CM000663.2", "genome_group_id": 3}, {"id": 51, "name": "chr2", "accession": "CM000664.2", "genome_group_id": 3}, {"id": 52, "name": "chr3", "accession": "CM000665.2", "genome_group_id": 3}, {"id": 53, "name": "chr4", "accession": "CM000666.2", "genome_group_id": 3}, {"id": 54, "name": "chr5", "accession": "CM000667.2", "genome_group_id": 3}, {"id": 55, "name": "chr6", "accession": "CM000668.2", "genome_group_id": 3}, {"id": 56, "name": "chr7", "accession": "CM000669.2", "genome_group_id": 3}, {"id": 57, "name": "chr8", "accession": "CM000670.2", "genome_group_id": 3}, {"id": 58, "name": "chr9", "accession": "CM000671.2", "genome_group_id": 3}, {"id": 59, "name": "chr10", "accession": "CM000672.2", "genome_group_id": 3}, {"id": 60, "name": "chr11", "accession": "CM000673.2", "genome_group_id": 3}, {"id": 61, "name": "chr12", "accession": "CM000674.2", "genome_group_id": 3}, {"id": 62, "name": "chr13", "accession": "CM000675.2", "genome_group_id": 3}, {"id": 63, "name": "chr14", "accession": "CM000676.2", "genome_group_id": 3}, {"id": 64, "name": "chr15", "accession": "CM000677.2", "genome_group_id": 3}, {"id": 65, "name": "chr16", "accession": "CM000678.2", "genome_group_id": 3}, {"id": 66, "name": "chr17", "accession": "CM000679.2", "genome_group_id": 3}, {"id": 67, "name": "chr18", "accession": "CM000680.2", "genome_group_id": 3}, {"id": 68, "name": "chr19", "accession": "CM000681.2", "genome_group_id": 3}, {"id": 69, "name": "chr20", "accession": "CM000682.2", "genome_group_id": 3}, {"id": 70, "name": "chr21", "accession": "CM000683.2", "genome_group_id": 3}, {"id": 71, "name": "chr22", "accession": "CM000684.2", "genome_group_id": 3}, {"id": 72, "name": "chrX", "accession": "CM000685.2", "genome_group_id": 3}, {"id": 73, "name": "chrY", "accession": "CM000686.2", "genome_group_id": 3}, {"id": 74, "name": "chrM", "accession": "J01415.2", "genome_group_id": 3}], "type": "array", "items": {"type": "object", "required": ["genome_group_id", "id", "name", "accession"], "properties": {"id": {"type": "number"}, "name": {"type": "string"}, "accession": {"type": "string"}, "genome_group_id": {"type": "number"}}}, "description": "list of chromosomes analysed"}, "description": {"type": "string", "description": "Description of the analysis"}, "analysis_type": {"enum": ["REFERENCE ALIGNMENT", "SEQUENCE VARIATION", "SAMPLE PHENOTYPE"], "type": "string", "description": "Type of analysis"}, "experiment_types": {"type": "array", "items": {"enum": ["Whole genome sequencing", "Exome sequencing", "Transcriptomics", "Genotyping by sequencing", "Whole transcriptome sequencing", "Genotyping by Array", "Curation", "Target sequencing"], "type": "string"}, "description": "Types of experiment"}, "extra_attributes": {"type": "array", "items": {"type": "object", "required": ["tag", "value", "unit"], "properties": {"tag": {"type": "string"}, "unit": {"type": "string"}, "value": {"type": "string"}}}, "description": "Any extra attributes associated with the analysis"}, "sample_public_ids": {"type": "array", "items": {"type": "string", "pattern": "^CHFEGAN[0-9]{11}.*", "x-check": "Sample", "x-check_title": "title", "x-check_value": "public_id"}, "description": "List of associated sample public ids", "uniqueItems": true}, "sdafile_public_ids": {"type": "array", "items": {"type": "string", "pattern": "^CHFEGAF[0-9]{11}.*", "x-check": "SdaFile", "x-check_title": "title", "x-check_value": "public_id"}, "description": "List of associated file public ids", "uniqueItems": true}, "molecularexperiment_public_ids": {"type": "array", "items": {"type": "string", "pattern": "^CHFEGAX[0-9]{11}.*", "x-check": "MolecularExperiment", "x-check_title": "properties.design_description", "x-check_value": "public_id"}, "description": "List of associated experiment public ids", "uniqueItems": true}}, "x-resource": {"schema": {"fields": [{"name": "files", "type": "list", "aliasOf": "sdafile_public_ids", "constraints": {"required": true, "jsonSchema": {"type": "array", "items": {"type": "string"}, "uniqueItems": true}}}, {"name": "title", "constraints": {"required": true}}, {"name": "platform", "constraints": {"required": true}}, {"name": "genome_id", "constraints": {"required": true}}, {"name": "description", "constraints": {"required": true}}, {"name": "analysis_type", "constraints": {"required": true}}, {"name": "experiment_types", "type": "list", "constraints": {"required": true}}, {"name": "samples", "type": "list"}, {"name": "experiments", "type": "list"}], "primaryKey": ["title"], "foreignKeys": [{"fields": ["samples"], "reference": {"fields": ["title"], "resource": "Sample"}}, {"fields": ["experiments"], "reference": {"fields": ["title"], "resource": "MolecularExperiment"}}]}}}}', 'CHFEGAZ', 't'),
(8, 'sra', 'Common', NULL, NULL, 'f'),
(9, 'sra', 'MolecularExperiment', '{"ui_schema": {"type": "group", "elements": [{"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"rule": {"effect": "SHOW", "condition": {"scope": "#", "schema": {"required": ["public_id"], "properties": {"public_id": {"type": "string"}}}}}, "type": "Control", "label": "FEGA Experiment ID", "scope": "#/properties/public_id", "options": {"readonly": true}}, {"type": "Control", "scope": "#/properties/title"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/design_description"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/instrument_model_id"}, {"type": "Control", "scope": "#/properties/library_strategy"}, {"type": "Control", "scope": "#/properties/library_selection"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/library_name"}, {"type": "Control", "scope": "#/properties/library_layout"}, {"type": "Control", "scope": "#/properties/library_source"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/library_construction_protocol"}, {"type": "Control", "scope": "#/properties/paired_nominal_length"}, {"type": "Control", "scope": "#/properties/paired_nominal_sdev"}]}, {"type": "Control", "scope": "#/properties/extra_attributes"}]}]}, "data_schema": {"type": "object", "title": "ExperimentRequest", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title", "design_description", "instrument_model_id", "library_layout", "library_strategy", "library_source", "library_selection"], "properties": {"title": {"type": "string", "title": "title", "description": "The experiment alias"}, "public_id": {"type": "string", "title": "Public ID", "pattern": "^CHFEGAX[0-9]{11}.*", "description": "Public Identifier of the experiment"}, "library_name": {"type": "string", "title": "Library Name", "description": "The name of the sequencing library"}, "library_layout": {"enum": ["PAIRED", "SINGLE"], "type": "string", "title": "Library Layout", "default": "PAIRED", "description": "Layout (paired or single) of the sequencing library"}, "library_source": {"enum": ["GENOMIC", "GENOMIC SINGLE CELL", "TRANSCRIPTOMIC", "TRANSCRIPTOMIC SINGLE CELL", "METAGENOMIC", "METATRANSCRIPTOMIC", "SYNTHETIC", "VIRAL RNA", "OTHER"], "type": "string", "title": "Library Source", "description": "Source/type of the sequencing library"}, "extra_attributes": {"type": "array", "items": {"type": "object", "required": ["tag", "value"], "properties": {"tag": {"type": "string"}, "unit": {"type": "string"}, "value": {"type": "string"}}}, "title": "Extra Attributes", "description": "Any extra attribute(s) to describe an experiment"}, "library_strategy": {"enum": ["WGS", "WGA", "WXS", "RNA-Seq", "ssRNA-seq", "miRNA-Seq", "ncRNA-Seq", "FL-cDNA", "EST", "Hi-C", "ATAC-seq", "WCS", "RAD-Seq", "CLONE", "POOLCLONE", "AMPLICON", "CLONEEND", "FINISHING", "ChIP-Seq", "MNase-Seq", "DNase-Hypersensitivity", "Bisulfite-Seq", "CTS", "MRE-Seq", "MeDIP-Seq", "MBD-Seq", "Tn-Seq", "VALIDATION", "FAIRE-seq", "SELEX", "RIP-Seq", "ChIA-PET", "Synthetic-Long-Read", "Targeted-Capture", "Tethered Chromatin Conformation Capture", "NOMe-Seq", "ChM-Seq", "GBS", "OTHER", "snRNA-seq", "Ribo-Seq"], "type": "string", "title": "Library strategy / scope", "default": "WGS", "descripion": "Scope of the sequencing library"}, "library_selection": {"enum": ["RANDOM", "PCR", "RANDOM PCR", "RT-PCR", "HMPR", "MF", "repeat fractionation", "size fractionation", "MSLL", "cDNA", "cDNA_randomPriming", "cDNA_oligo_dT", "PolyA", "Oligo-dT", "Inverse rRNA", "Inverse rRNA selection", "ChIP", "ChIP-Seq", "MNase", "DNase", "Hybrid Selection", "Reduced Representation", "Restriction Digest", "5-methylcytidine antibody", "MBD2 protein methyl-CpG binding domain", "CAGE", "RACE", "MDA", "padlock probes capture method", "other", "unspecified"], "type": "string", "title": "Library selection", "default": "RANDOM", "description": "Method the select the genomic molecules for sequencing"}, "design_description": {"type": "string", "title": "Description", "description": "Description of the experimental design"}, "instrument_model_id": {"enum": ["ABI_SOLID: AB 5500 Genetic Analyzer", "ABI_SOLID: AB 5500xl Genetic Analyzer", "ABI_SOLID: AB 5500xl-W Genetic Analysis System", "ABI_SOLID: AB SOLiD 3 Plus System", "ABI_SOLID: AB SOLiD 4 System", "ABI_SOLID: AB SOLiD 4hq System", "ABI_SOLID: AB SOLiD PI System", "ABI_SOLID: AB SOLiD System 2.0", "ABI_SOLID: AB SOLiD System 3.0", "ABI_SOLID: AB SOLiD System", "ABI_SOLID: unspecified", "BGISEQ: BGISEQ-50", "BGISEQ: BGISEQ-500", "BGISEQ: MGISEQ-2000RS", "CAPILLARY: AB 310 Genetic Analyzer", "CAPILLARY: AB 3130 Genetic Analyzer", "CAPILLARY: AB 3130xL Genetic Analyzer", "CAPILLARY: AB 3500 Genetic Analyzer", "CAPILLARY: AB 3500xL Genetic Analyzer", "CAPILLARY: AB 3730 Genetic Analyzer", "CAPILLARY: AB 3730xL Genetic Analyzer", "CAPILLARY: unspecified", "COMPLETE_GENOMICS: Complete Genomics", "COMPLETE_GENOMICS: unspecified", "DNBSEQ: DNBSEQ-G400 FAST", "DNBSEQ: DNBSEQ-G400", "DNBSEQ: DNBSEQ-G50", "DNBSEQ: DNBSEQ-T7", "DNBSEQ: unspecified", "HELICOS: Helicos HeliScope", "HELICOS: unspecified", "ILLUMINA: HiSeq X Five", "ILLUMINA: HiSeq X Ten", "ILLUMINA: Illumina Genome Analyzer II", "ILLUMINA: Illumina Genome Analyzer IIx", "ILLUMINA: Illumina Genome Analyzer", "ILLUMINA: Illumina HiScanSQ", "ILLUMINA: Illumina HiSeq 1000", "ILLUMINA: Illumina HiSeq 1500", "ILLUMINA: Illumina HiSeq 2000", "ILLUMINA: Illumina HiSeq 2500", "ILLUMINA: Illumina HiSeq 3000", "ILLUMINA: Illumina HiSeq 4000", "ILLUMINA: Illumina HiSeq X", "ILLUMINA: Illumina iSeq 100", "ILLUMINA: Illumina MiniSeq", "ILLUMINA: Illumina MiSeq", "ILLUMINA: Illumina NovaSeq 6000", "ILLUMINA: Illumina NovaSeq X Plus", "ILLUMINA: Illumina NovaSeq X", "ILLUMINA: NextSeq 1000", "ILLUMINA: NextSeq 2000", "ILLUMINA: NextSeq 500", "ILLUMINA: NextSeq 550", "ILLUMINA: unspecified", "ION_TORRENT: Ion GeneStudio S5 Plus", "ION_TORRENT: Ion GeneStudio S5 Prime", "ION_TORRENT: Ion GeneStudio S5", "ION_TORRENT: Ion Torrent Genexus", "ION_TORRENT: Ion Torrent PGM", "ION_TORRENT: Ion Torrent Proton", "ION_TORRENT: Ion Torrent S5 XL", "ION_TORRENT: Ion Torrent S5", "ION_TORRENT: unspecified", "LS454: 454 GS 20", "LS454: 454 GS FLX Titanium", "LS454: 454 GS FLX", "LS454: 454 GS FLX+", "LS454: 454 GS Junior", "LS454: 454 GS", "LS454: unspecified", "OXFORD_NANOPORE: GridION", "OXFORD_NANOPORE: MinION", "OXFORD_NANOPORE: PromethION", "OXFORD_NANOPORE: unspecified", "PACBIO_SMRT: PacBio RS II", "PACBIO_SMRT: PacBio RS", "PACBIO_SMRT: Sequel II", "PACBIO_SMRT: Sequel IIe", "PACBIO_SMRT: Sequel", "PACBIO_SMRT: unspecified"], "type": "string", "title": "Instrument", "description": "Model of the instrument to perform the molecular analysis (sequencer)"}, "paired_nominal_sdev": {"type": "number", "title": "Standard Deviation of paired read length", "description": "The experiment paired nominal sdev"}, "paired_nominal_length": {"type": "number", "title": "Length of paired reads", "description": "The experiment paired nominal length"}, "library_construction_protocol": {"type": "string", "title": "Library Construction Protocol", "description": "The experiment library construction protocol"}}, "x-resource": {"schema": {"fields": [{"name": "title", "constraints": {"required": true}}, {"name": "library_layout", "constraints": {"required": true}}, {"name": "library_source", "constraints": {"required": true}}, {"name": "library_strategy", "constraints": {"required": true}}, {"name": "library_selection", "constraints": {"required": true}}, {"name": "design_description", "constraints": {"required": true}}, {"name": "instrument_model_id", "constraints": {"required": true}}], "primaryKey": ["title"]}}}}', 'CHFEGAX', 't'),
(10, 'sra', 'Receipt', NULL, NULL, 'f'),
(11, 'sra', 'MolecularRun', '{"ui_schema": {"type": "group", "elements": [{"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"rule": {"effect": "SHOW", "condition": {"scope": "#", "schema": {"required": ["public_id"], "properties": {"public_id": {"type": "string"}}}}}, "type": "Control", "label": "FEGA Molecular Run ID", "scope": "#/properties/public_id", "options": {"readonly": true}}, {"type": "Control", "label": "Title", "scope": "#/properties/title"}, {"type": "Control", "label": "Experiment", "scope": "#/properties/molecularexperiment_public_id"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/run_file_type"}, {"type": "Control", "label": "Sample", "scope": "#/properties/sample_public_id"}, {"type": "Control", "scope": "#/properties/sdafile_public_ids"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/extra_attributes"}]}]}]}, "data_schema": {"type": "object", "title": "RunRequest", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title", "run_file_type", "sdafile_public_ids", "molecularexperiment_public_id", "sample_public_id"], "properties": {"title": {"type": "string", "title": "title", "description": "Title of the Run"}, "public_id": {"type": "string", "title": "Public ID", "pattern": "^CHFEGAR[0-9]{11}.*", "description": "public ID of the Run"}, "run_file_type": {"enum": ["fastq", "bam", "cram", "srf", "sff", "Illumina_native", "Illumina_native_qseq", "SOLiD_native_csfasta", "PacBio_HDF5", "CompleteGenomics_native", "OxfordNanopore_native"], "type": "string", "title": "Run File type", "description": "Output file type of the Run"}, "extra_attributes": {"type": "array", "items": {"type": "object", "required": ["tag", "value"], "properties": {"tag": {"type": "string"}, "unit": {"type": "string"}, "value": {"type": "string"}}}, "description": "Any extra attributes that describes the Run"}, "sample_public_id": {"type": "string", "title": "Sample", "pattern": "^CHFEGAN[0-9]{11}.*", "x-check": "Sample", "description": "Public ID of associated sample", "x-check_title": "title", "x-check_value": "public_id"}, "sdafile_public_ids": {"type": "array", "items": {"type": "string", "pattern": "^CHFEGAF[0-9]{11}.*", "x-check": "SdaFile", "x-check_title": "title", "x-check_value": "public_id"}, "title": "File", "description": "List of associated file public ids", "uniqueItems": true}, "molecularexperiment_public_id": {"type": "string", "title": "Experiment", "pattern": "^CHFEGAX[0-9]{11}.*", "x-check": "MolecularExperiment", "description": "Public ID of associated molecular experiment", "x-check_title": "properties.title", "x-check_value": "public_id"}}, "x-resource": {"schema": {"fields": [{"name": "title", "constraints": {"required": true}}, {"name": "experiment"}, {"name": "sample"}, {"name": "files", "type": "list", "aliasOf": "sdafile_public_ids", "constraints": {"required": true, "jsonSchema": {"type": "array", "items": {"type": "string"}, "uniqueItems": true}}}, {"name": "file_type", "aliasOf": "run_file_type", "constraints": {"required": true}}], "primaryKey": ["title"], "foreignKeys": [{"fields": ["experiment"], "reference": {"fields": ["title"], "resource": "MolecularExperiment"}}, {"fields": ["sample"], "reference": {"fields": ["title"], "resource": "Sample"}}]}}}}', 'CHFEGAR', 't'),
(12, 'sra', 'Sample', '{"ui_schema": {"type": "group", "elements": [{"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"rule": {"effect": "ENABLE", "condition": {"scope": "#", "schema": {"required": ["public_id"], "properties": {"public_id": {"type": "string"}}}}}, "type": "Control", "scope": "#/properties/public_id", "options": {"readonly": true}}, {"type": "Control", "scope": "#/properties/alias"}, {"type": "Control", "scope": "#/properties/title"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/description"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/subject_id"}, {"type": "Control", "scope": "#/properties/biological_sex"}, {"type": "Control", "scope": "#/properties/phenotype"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/biosample_id"}, {"type": "Control", "scope": "#/properties/case_control"}, {"type": "Control", "scope": "#/properties/organism_part"}, {"type": "Control", "scope": "#/properties/cell_line"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/extra_attributes"}]}]}]}, "data_schema": {"type": "object", "title": "SampleRequest", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["alias", "biological_sex", "subject_id", "phenotype"], "properties": {"alias": {"type": "string", "description": "The sample alias"}, "title": {"type": "string", "description": "The sample title"}, "cell_line": {"type": "string", "label": "cell line", "description": "The sample cell line"}, "phenotype": {"type": "string", "description": "The sample phenotype"}, "public_id": {"type": "string", "pattern": "^CHFEGAN[0-9]{11}.*", "description": "Public identifier of the sample"}, "subject_id": {"type": "string", "description": "The sample subject ID"}, "description": {"type": "string", "description": "The sample description"}, "biosample_id": {"type": "string", "description": "The sample biosample ID"}, "case_control": {"enum": ["case", "control", "both", "NA"], "description": "If the sample is the case or control."}, "organism_part": {"type": "string", "description": "The sample organism part"}, "biological_sex": {"enum": ["male", "female", "hermaphrodite", "unknown"], "description": "The sample biological sex."}, "extra_attributes": {"type": "array", "items": {"type": "object", "required": ["tag", "value"], "properties": {"tag": {"type": "string"}, "unit": {"type": "string"}, "value": {"type": "string"}}}}}, "x-resource": {"schema": {"fields": [{"name": "alias", "constraints": {"required": true}}, {"name": "cell_line"}, {"name": "phenotype", "constraints": {"required": true}}, {"name": "subject_id", "constraints": {"required": true}}, {"name": "description"}, {"name": "biosample_id"}, {"name": "case_control"}, {"name": "organism_part"}, {"name": "biological_sex", "constraints": {"required": true}}], "primaryKey": ["alias"]}}}}', 'CHFEGAN', 't'),
(13, 'sra', 'Study', '{"ui_schema": {"type": "VerticalLayout", "elements": [{"type": "HorizontalLayout", "elements": [{"rule": {"effect": "SHOW", "condition": {"scope": "#", "schema": {"required": ["public_id"], "properties": {"public_id": {"type": "string"}}}}}, "type": "Control", "label": "FEGA Study ID", "scope": "#/properties/public_id", "options": {"readonly": true}}, {"type": "Control", "scope": "#/properties/title"}, {"type": "Control", "scope": "#/properties/study_type"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/description"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "label": "PubMed IDs", "scope": "#/properties/pubmed_ids"}, {"type": "Control", "scope": "#/properties/custom_tags"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/extra_attributes"}]}, {"type": "HorizontalLayout", "elements": [{"type": "Control", "scope": "#/properties/repositories"}]}]}, "data_schema": {"type": "object", "title": "StudyRequest", "x-cega": {"schema": {"foreignKeys": [{"fields": ["title"], "reference": {"fields": ["title"], "resource": "studies"}}, {"fields": ["description"], "reference": {"fields": ["description"], "resource": "studies"}}, {"fields": ["study_type"], "reference": {"fields": ["study_type"], "resource": "studies"}}, {"fields": ["pubmed_ids"], "reference": {"fields": ["pubmed_ids"], "resource": "studies"}}, {"fields": ["custom_tags"], "reference": {"fields": ["custom_tags"], "resource": "studies"}}, {"fields": ["extra_attributes"], "reference": {"fields": ["extra_attributes"], "resource": "studies"}}]}}, "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title", "study_type"], "properties": {"title": {"type": "string", "minLength": 3}, "public_id": {"type": "string", "pattern": "^CHFEGAS[0-9]{11}.*", "description": "Public identifier of the study"}, "pubmed_ids": {"type": "array", "items": {"type": "number", "x-check": "pubmed_id"}, "uniqueItems": true}, "study_type": {"enum": ["Whole Genome Sequencing", "Metagenomics", "Transcriptome Analysis", "Resequencing", "Epigenetics", "Synthetic Genomics", "Forensic or Paleo-genomics", "Gene Regulation Study", "Cancer Genomics", "Population Genomics", "RNASeq", "Exome Sequencing", "Pooled Clone Sequencing", "Transcriptome Sequencing"], "type": "string"}, "custom_tags": {"type": "array", "items": {"type": "string"}}, "description": {"type": "string"}, "repositories": {"type": "array", "items": {"type": "object", "properties": {"url": {"type": "string"}, "label": {"type": "string"}, "repository_id": {"type": "string"}}}}, "extra_attributes": {"type": "array", "items": {"type": "object", "properties": {"tag": {"type": "string"}, "unit": {"type": "string"}, "value": {"type": "string"}}}}}, "x-resource": {"schema": {"fields": [{"name": "title", "constraints": {"required": true}}, {"name": "type", "aliasOf": "study_type", "constraints": {"required": true}}, {"name": "description"}], "primaryKey": ["title"]}}}}', 'CHFEGAS', 't'),
(14, 'sra', 'Submission', '{"ui_schema": {}, "data_schema": {"type": "object", "title": "SubmissionRequest", "$schema": "http://json-schema.org/draft-07/schema#", "required": ["title", "description", "collaborators"], "properties": {"title": {"type": "string"}, "public_id": {"type": "number"}, "description": {"type": "string"}, "collaborators": {"type": "array", "items": {"type": "object", "required": ["id", "access_type", "comment"], "properties": {"id": {"type": "number"}, "comment": {"type": "string"}, "access_type": {"type": "string"}}}}}}}', 'CHFEGAB', 'f'),
(16, 'fega', 'Publication', '{"ui-schema": {}, "data_schema": {"$id": "https://fega.swiss/publication.schema.json", "type": "object", "title": "Publication", "$schema": "https://json-schema.org/draft/2020-12/schema", "required": ["id", "title", "doi"], "properties": {"id": {"type": "number", "description": "Pubmed ID of the publication"}, "doi": {"type": "string", "description": "DOI of the publication"}, "date": {"type": "string", "format": "date", "description": "publication date"}, "title": {"type": "string", "description": "Title of the publication"}, "journal": {"type": "string", "description": "Name of the journal"}}, "description": "A publication"}}', 'CHFEGAU', 'f'),
(17, 'fega', 'File', '{"ui_schema": {}, "data_schema": {"$id": "https://fega.swiss/publication.schema.json", "type": "object", "title": "File", "$schema": "https://json-schema.org/draft/2020-12/schema", "required": ["name", "original_name", "filesize", "mime_type", "md5"], "properties": {"md5": {"type": "string", "description": "MD5 checksum of file content"}, "name": {"type": "string", "description": "Name of the file. Formatted by the uploader"}, "filesize": {"type": "number", "description": "File size in bytes"}, "mime_type": {"type": "string", "description": "Mime type of the file"}, "original_name": {"type": "string", "description": "Original name of the file"}}, "description": "metadata file stored in FEGA"}}', 'CHFEGAI', 'f'),
(18, 'ega', 'SdaFile', '{"ui_schema": {}, "data_schema": {"$id": "https://fega.swiss/publication.schema.json", "type": "object", "title": "SdaFile", "$schema": "https://json-schema.org/draft/2020-12/schema", "required": ["title", "filepath", "filesize", "file_last_modified", "encrypted_checksums"], "properties": {"title": {"type": "string", "description": "Basename of the file."}, "filepath": {"type": "string", "description": "file path in SDA"}, "filesize": {"type": "number", "description": "File size in bytes"}, "public_id": {"type": "string", "pattern": "^CHFEGAF[0-9]{11}.*", "description": "Public identifier of the sample"}, "file_last_modified": {"type": "number", "description": "last modification time"}, "encrypted_checksums": {"type": "array", "items": {"type": "object", "properties": {"type": {"type": "string", "description": "checksum type. SHA256 (prefered), MD5, ..."}, "value": {"type": "string", "description": "checksum value"}}}, "description": "checksum(s) of file content"}}, "description": "metadata file stored in FEGA"}}', 'CHFEGAF', 't')
ON CONFLICT DO NOTHING;

INSERT INTO "public"."status_type" ("id", "name", "class_name") VALUES
('DEL', 'deleted', 'red'),
('DRA', 'draft', 'blue-grey'),
('PUB', 'published', 'green'),
('REV', 'revised', 'teal'),
('SUB', 'submitted', 'light-green'),
('VER', 'verified', 'light-green')
ON CONFLICT DO NOTHING;

INSERT INTO "public"."action_type" ("id", "name") VALUES
('CRE', 'create'),
('DEL', 'delete'),
('MOD', 'modify'),
('PUB', 'publish')
ON CONFLICT DO NOTHING;

INSERT INTO "public"."permission" ("id", "name") VALUES
('1', 'read'),
('2', 'review'),
('3', 'edit'),
('4', 'delete')
ON CONFLICT DO NOTHING;

INSERT INTO "public"."predicate" ("id", "prefix", "name", "properties") VALUES
(1, 'fega', 'isPartOf', NULL),
(2, 'fega', 'isProcessedIn', NULL),
(3, 'fega', 'isLinkedTo', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO "public"."relationship_rule" ("id", "domain_type_id", "predicate_id", "range_type_id", "default_is_active") VALUES
(1, 2, 1, 13, 't'),
(2, 12, 1, 13, 't'),
(3, 17, 1, 13, 't'),
(4, 9, 1, 13, 't'),
(5, 3, 1, 1, 't'),
(6, 2, 3, 3, 'f'),
(7, 7, 1, 2, 't'),
(8, 11, 1, 2, 't'),
(9, 7, 1, 13, 't'),
(10, 11, 1, 9, 't'),
(11, 7, 1, 12, 't'),
(12, 9, 1, 12, 't'),
(13, 12, 2, 11, 't'),
(14, 11, 1, 13, 't'),
(15, 18, 1, 13, 't'),
(16, 18, 1, 11, 't'),
(17, 18, 1, 7, 't')
ON CONFLICT DO NOTHING;


INSERT INTO "public"."role" ("id", "name") VALUES
('COM', 'commenter'),
('ORG', 'organizer'),
('OWN', 'owner'),
('REA', 'reader'),
('WRI', 'writer')
ON CONFLICT DO NOTHING;

INSERT INTO "public"."role_permission" ("role_id", "permission_id") VALUES
('COM', '1'),
('COM', '2'),
('ORG', '1'),
('ORG', '2'),
('ORG', '3'),
('ORG', '4'),
('OWN', '1'),
('OWN', '2'),
('OWN', '3'),
('OWN', '4'),
('REA', '1'),
('WRI', '1'),
('WRI', '2'),
('WRI', '3')
ON CONFLICT DO NOTHING;



--
-- PostgreSQL database dump complete
--
