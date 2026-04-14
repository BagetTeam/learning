--
-- PostgreSQL database dump
--

\restrict EKxL6mS7eCSueQ2A2JEAIoEMagaWYhxUb5Jfncl4rW8X7Ht15BLnUy8GOxMCLSw

-- Dumped from database version 14.22 (Debian 14.22-1.pgdg13+1)
-- Dumped by pg_dump version 14.22 (Debian 14.22-1.pgdg13+1)

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
-- Name: channel_bookmark_type; Type: TYPE; Schema: public; Owner: mmuser
--

CREATE TYPE public.channel_bookmark_type AS ENUM (
    'link',
    'file'
);


ALTER TYPE public.channel_bookmark_type OWNER TO mmuser;

--
-- Name: channel_type; Type: TYPE; Schema: public; Owner: mmuser
--

CREATE TYPE public.channel_type AS ENUM (
    'P',
    'G',
    'O',
    'D'
);


ALTER TYPE public.channel_type OWNER TO mmuser;

--
-- Name: outgoingoauthconnections_granttype; Type: TYPE; Schema: public; Owner: mmuser
--

CREATE TYPE public.outgoingoauthconnections_granttype AS ENUM (
    'client_credentials',
    'password'
);


ALTER TYPE public.outgoingoauthconnections_granttype OWNER TO mmuser;

--
-- Name: property_field_type; Type: TYPE; Schema: public; Owner: mmuser
--

CREATE TYPE public.property_field_type AS ENUM (
    'text',
    'select',
    'multiselect',
    'date',
    'user',
    'multiuser'
);


ALTER TYPE public.property_field_type OWNER TO mmuser;

--
-- Name: team_type; Type: TYPE; Schema: public; Owner: mmuser
--

CREATE TYPE public.team_type AS ENUM (
    'I',
    'O'
);


ALTER TYPE public.team_type OWNER TO mmuser;

--
-- Name: upload_session_type; Type: TYPE; Schema: public; Owner: mmuser
--

CREATE TYPE public.upload_session_type AS ENUM (
    'attachment',
    'import'
);


ALTER TYPE public.upload_session_type OWNER TO mmuser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accesscontrolpolicies; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.accesscontrolpolicies (
    id character varying(26) NOT NULL,
    name character varying(128) NOT NULL,
    type character varying(128) NOT NULL,
    active boolean NOT NULL,
    createat bigint NOT NULL,
    revision integer NOT NULL,
    version character varying(8) NOT NULL,
    data jsonb,
    props jsonb
);


ALTER TABLE public.accesscontrolpolicies OWNER TO mmuser;

--
-- Name: accesscontrolpolicyhistory; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.accesscontrolpolicyhistory (
    id character varying(26) NOT NULL,
    name character varying(128) NOT NULL,
    type character varying(128) NOT NULL,
    createat bigint NOT NULL,
    revision integer NOT NULL,
    version character varying(8) NOT NULL,
    data jsonb,
    props jsonb
);


ALTER TABLE public.accesscontrolpolicyhistory OWNER TO mmuser;

--
-- Name: propertyfields; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.propertyfields (
    id character varying(26) NOT NULL,
    groupid character varying(26) NOT NULL,
    name character varying(255) NOT NULL,
    type public.property_field_type,
    attrs jsonb,
    targetid character varying(255),
    targettype character varying(255),
    createat bigint NOT NULL,
    updateat bigint NOT NULL,
    deleteat bigint NOT NULL
);


ALTER TABLE public.propertyfields OWNER TO mmuser;

--
-- Name: propertyvalues; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.propertyvalues (
    id character varying(26) NOT NULL,
    targetid character varying(255) NOT NULL,
    targettype character varying(255) NOT NULL,
    groupid character varying(26) NOT NULL,
    fieldid character varying(26) NOT NULL,
    value jsonb NOT NULL,
    createat bigint NOT NULL,
    updateat bigint NOT NULL,
    deleteat bigint NOT NULL
);


ALTER TABLE public.propertyvalues OWNER TO mmuser;

--
-- Name: attributeview; Type: MATERIALIZED VIEW; Schema: public; Owner: mmuser
--

CREATE MATERIALIZED VIEW public.attributeview AS
 SELECT pv.groupid,
    pv.targetid,
    pv.targettype,
    jsonb_object_agg(pf.name,
        CASE
            WHEN (pf.type = 'select'::public.property_field_type) THEN ( SELECT to_jsonb(options.name) AS to_jsonb
               FROM jsonb_to_recordset((pf.attrs -> 'options'::text)) options(id text, name text)
              WHERE (options.id = (pv.value #>> '{}'::text[]))
             LIMIT 1)
            WHEN ((pf.type = 'multiselect'::public.property_field_type) AND (jsonb_typeof(pv.value) = 'array'::text)) THEN ( SELECT jsonb_agg(option_names.name) AS jsonb_agg
               FROM (jsonb_array_elements_text(pv.value) option_id(value)
                 JOIN jsonb_to_recordset((pf.attrs -> 'options'::text)) option_names(id text, name text) ON ((option_id.value = option_names.id))))
            ELSE pv.value
        END) AS attributes
   FROM (public.propertyvalues pv
     LEFT JOIN public.propertyfields pf ON (((pf.id)::text = (pv.fieldid)::text)))
  WHERE (((pv.deleteat = 0) OR (pv.deleteat IS NULL)) AND ((pf.deleteat = 0) OR (pf.deleteat IS NULL)))
  GROUP BY pv.groupid, pv.targetid, pv.targettype
  WITH NO DATA;


ALTER TABLE public.attributeview OWNER TO mmuser;

--
-- Name: audits; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.audits (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    action character varying(512),
    extrainfo character varying(1024),
    ipaddress character varying(64),
    sessionid character varying(26)
);


ALTER TABLE public.audits OWNER TO mmuser;

--
-- Name: bots; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.bots (
    userid character varying(26) NOT NULL,
    description character varying(1024),
    ownerid character varying(190),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    lasticonupdate bigint
);


ALTER TABLE public.bots OWNER TO mmuser;

--
-- Name: channels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.channels (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    teamid character varying(26),
    type public.channel_type,
    displayname character varying(64),
    name character varying(64),
    header character varying(1024),
    purpose character varying(250),
    lastpostat bigint,
    totalmsgcount bigint,
    extraupdateat bigint,
    creatorid character varying(26),
    schemeid character varying(26),
    groupconstrained boolean,
    shared boolean,
    totalmsgcountroot bigint,
    lastrootpostat bigint DEFAULT '0'::bigint,
    bannerinfo jsonb,
    defaultcategoryname character varying(64) DEFAULT ''::character varying NOT NULL,
    autotranslation boolean DEFAULT false NOT NULL
);


ALTER TABLE public.channels OWNER TO mmuser;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.posts (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    userid character varying(26),
    channelid character varying(26),
    rootid character varying(26),
    originalid character varying(26),
    message character varying(65535),
    type character varying(26),
    props jsonb,
    hashtags character varying(1000),
    filenames character varying(4000),
    fileids character varying(300),
    hasreactions boolean,
    editat bigint,
    ispinned boolean,
    remoteid character varying(26)
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.posts OWNER TO mmuser;

--
-- Name: bot_posts_by_team_day; Type: MATERIALIZED VIEW; Schema: public; Owner: mmuser
--

CREATE MATERIALIZED VIEW public.bot_posts_by_team_day AS
 SELECT (to_timestamp(((p.createat / 1000))::double precision))::date AS day,
    count(*) AS num,
    c.teamid
   FROM ((public.posts p
     JOIN public.bots b ON (((p.userid)::text = (b.userid)::text)))
     JOIN public.channels c ON (((p.channelid)::text = (c.id)::text)))
  GROUP BY ((to_timestamp(((p.createat / 1000))::double precision))::date), c.teamid
  WITH NO DATA;


ALTER TABLE public.bot_posts_by_team_day OWNER TO mmuser;

--
-- Name: calls; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.calls (
    id character varying(26) NOT NULL,
    channelid character varying(26),
    startat bigint,
    endat bigint,
    createat bigint,
    deleteat bigint,
    title character varying(256),
    postid character varying(26),
    threadid character varying(26),
    ownerid character varying(26),
    participants jsonb NOT NULL,
    stats jsonb NOT NULL,
    props jsonb NOT NULL
);


ALTER TABLE public.calls OWNER TO mmuser;

--
-- Name: calls_channels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.calls_channels (
    channelid character varying(26) NOT NULL,
    enabled boolean,
    props jsonb NOT NULL
);


ALTER TABLE public.calls_channels OWNER TO mmuser;

--
-- Name: calls_jobs; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.calls_jobs (
    id character varying(26) NOT NULL,
    callid character varying(26),
    type character varying(64),
    creatorid character varying(26),
    initat bigint,
    startat bigint,
    endat bigint,
    props jsonb NOT NULL
);


ALTER TABLE public.calls_jobs OWNER TO mmuser;

--
-- Name: calls_sessions; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.calls_sessions (
    id character varying(26) NOT NULL,
    callid character varying(26),
    userid character varying(26),
    joinat bigint,
    unmuted boolean,
    raisedhand bigint
);


ALTER TABLE public.calls_sessions OWNER TO mmuser;

--
-- Name: channelbookmarks; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.channelbookmarks (
    id character varying(26) NOT NULL,
    ownerid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    fileinfoid character varying(26) DEFAULT NULL::character varying,
    createat bigint DEFAULT 0,
    updateat bigint DEFAULT 0,
    deleteat bigint DEFAULT 0,
    displayname text DEFAULT ''::text,
    sortorder integer DEFAULT 0,
    linkurl text,
    imageurl text,
    emoji character varying(64) DEFAULT NULL::character varying,
    type public.channel_bookmark_type DEFAULT 'link'::public.channel_bookmark_type,
    originalid character varying(26) DEFAULT NULL::character varying,
    parentid character varying(26) DEFAULT NULL::character varying
);


ALTER TABLE public.channelbookmarks OWNER TO mmuser;

--
-- Name: channelmemberhistory; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.channelmemberhistory (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    jointime bigint NOT NULL,
    leavetime bigint
);


ALTER TABLE public.channelmemberhistory OWNER TO mmuser;

--
-- Name: channelmembers; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.channelmembers (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    roles character varying(256),
    lastviewedat bigint,
    msgcount bigint,
    mentioncount bigint,
    notifyprops jsonb,
    lastupdateat bigint,
    schemeuser boolean,
    schemeadmin boolean,
    schemeguest boolean,
    mentioncountroot bigint,
    msgcountroot bigint,
    urgentmentioncount bigint,
    autotranslation boolean DEFAULT false NOT NULL
);


ALTER TABLE public.channelmembers OWNER TO mmuser;

--
-- Name: clusterdiscovery; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.clusterdiscovery (
    id character varying(26) NOT NULL,
    type character varying(64),
    clustername character varying(64),
    hostname character varying(512),
    gossipport integer,
    port integer,
    createat bigint,
    lastpingat bigint
);


ALTER TABLE public.clusterdiscovery OWNER TO mmuser;

--
-- Name: commands; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.commands (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    teamid character varying(26),
    trigger character varying(128),
    method character varying(1),
    username character varying(64),
    iconurl character varying(1024),
    autocomplete boolean,
    autocompletedesc character varying(1024),
    autocompletehint character varying(1024),
    displayname character varying(64),
    description character varying(128),
    url character varying(1024),
    pluginid character varying(190)
);


ALTER TABLE public.commands OWNER TO mmuser;

--
-- Name: commandwebhooks; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.commandwebhooks (
    id character varying(26) NOT NULL,
    createat bigint,
    commandid character varying(26),
    userid character varying(26),
    channelid character varying(26),
    rootid character varying(26),
    usecount integer
);


ALTER TABLE public.commandwebhooks OWNER TO mmuser;

--
-- Name: compliances; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.compliances (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    status character varying(64),
    count integer,
    "desc" character varying(512),
    type character varying(64),
    startat bigint,
    endat bigint,
    keywords character varying(512),
    emails character varying(1024)
);


ALTER TABLE public.compliances OWNER TO mmuser;

--
-- Name: contentflaggingcommonreviewers; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.contentflaggingcommonreviewers (
    userid character varying(26) NOT NULL
);


ALTER TABLE public.contentflaggingcommonreviewers OWNER TO mmuser;

--
-- Name: contentflaggingteamreviewers; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.contentflaggingteamreviewers (
    teamid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL
);


ALTER TABLE public.contentflaggingteamreviewers OWNER TO mmuser;

--
-- Name: contentflaggingteamsettings; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.contentflaggingteamsettings (
    teamid character varying(26) NOT NULL,
    enabled boolean
);


ALTER TABLE public.contentflaggingteamsettings OWNER TO mmuser;

--
-- Name: db_lock; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.db_lock (
    id character varying(64) NOT NULL,
    expireat bigint
);


ALTER TABLE public.db_lock OWNER TO mmuser;

--
-- Name: db_migrations; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.db_migrations (
    version bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.db_migrations OWNER TO mmuser;

--
-- Name: db_migrations_calls; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.db_migrations_calls (
    version bigint NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.db_migrations_calls OWNER TO mmuser;

--
-- Name: desktoptokens; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.desktoptokens (
    token character varying(64) NOT NULL,
    createat bigint NOT NULL,
    userid character varying(26) NOT NULL
);


ALTER TABLE public.desktoptokens OWNER TO mmuser;

--
-- Name: drafts; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.drafts (
    createat bigint,
    updateat bigint,
    deleteat bigint,
    userid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    rootid character varying(26) DEFAULT ''::character varying NOT NULL,
    message character varying(65535),
    props character varying(8000),
    fileids character varying(300),
    priority text,
    type text
);


ALTER TABLE public.drafts OWNER TO mmuser;

--
-- Name: emoji; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.emoji (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    name character varying(64)
);


ALTER TABLE public.emoji OWNER TO mmuser;

--
-- Name: fileinfo; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.fileinfo (
    id character varying(26) NOT NULL,
    creatorid character varying(26),
    postid character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    path character varying(512),
    thumbnailpath character varying(512),
    previewpath character varying(512),
    name character varying(256),
    extension character varying(64),
    size bigint,
    mimetype character varying(256),
    width integer,
    height integer,
    haspreviewimage boolean,
    minipreview bytea,
    content text,
    remoteid character varying(26),
    archived boolean DEFAULT false NOT NULL,
    channelid character varying(26)
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.fileinfo OWNER TO mmuser;

--
-- Name: file_stats; Type: MATERIALIZED VIEW; Schema: public; Owner: mmuser
--

CREATE MATERIALIZED VIEW public.file_stats AS
 SELECT count(*) AS num,
    COALESCE(sum(fileinfo.size), (0)::numeric) AS usage
   FROM public.fileinfo
  WHERE (fileinfo.deleteat = 0)
  WITH NO DATA;


ALTER TABLE public.file_stats OWNER TO mmuser;

--
-- Name: groupchannels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.groupchannels (
    groupid character varying(26) NOT NULL,
    autoadd boolean,
    schemeadmin boolean,
    createat bigint,
    deleteat bigint,
    updateat bigint,
    channelid character varying(26) NOT NULL
);


ALTER TABLE public.groupchannels OWNER TO mmuser;

--
-- Name: groupmembers; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.groupmembers (
    groupid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    createat bigint,
    deleteat bigint
);


ALTER TABLE public.groupmembers OWNER TO mmuser;

--
-- Name: groupteams; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.groupteams (
    groupid character varying(26) NOT NULL,
    autoadd boolean,
    schemeadmin boolean,
    createat bigint,
    deleteat bigint,
    updateat bigint,
    teamid character varying(26) NOT NULL
);


ALTER TABLE public.groupteams OWNER TO mmuser;

--
-- Name: incomingwebhooks; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.incomingwebhooks (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    userid character varying(26),
    channelid character varying(26),
    teamid character varying(26),
    displayname character varying(64),
    description character varying(500),
    username character varying(255),
    iconurl character varying(1024),
    channellocked boolean
);


ALTER TABLE public.incomingwebhooks OWNER TO mmuser;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.jobs (
    id character varying(26) NOT NULL,
    type character varying(32),
    priority bigint,
    createat bigint,
    startat bigint,
    lastactivityat bigint,
    status character varying(32),
    progress bigint,
    data jsonb
);


ALTER TABLE public.jobs OWNER TO mmuser;

--
-- Name: licenses; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.licenses (
    id character varying(26) NOT NULL,
    createat bigint,
    bytes character varying(10000)
);


ALTER TABLE public.licenses OWNER TO mmuser;

--
-- Name: linkmetadata; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.linkmetadata (
    hash bigint NOT NULL,
    url character varying(2048),
    "timestamp" bigint,
    type character varying(16),
    data jsonb
);


ALTER TABLE public.linkmetadata OWNER TO mmuser;

--
-- Name: llm_postmeta; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.llm_postmeta (
    rootpostid text NOT NULL,
    title text NOT NULL
);


ALTER TABLE public.llm_postmeta OWNER TO mmuser;

--
-- Name: notifyadmin; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.notifyadmin (
    userid character varying(26) NOT NULL,
    createat bigint,
    requiredplan character varying(100) NOT NULL,
    requiredfeature character varying(255) NOT NULL,
    trial boolean NOT NULL,
    sentat bigint
);


ALTER TABLE public.notifyadmin OWNER TO mmuser;

--
-- Name: oauthaccessdata; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.oauthaccessdata (
    token character varying(26) NOT NULL,
    refreshtoken character varying(26),
    redirecturi character varying(256),
    clientid character varying(26),
    userid character varying(26),
    expiresat bigint,
    scope character varying(128),
    audience character varying(512) DEFAULT ''::character varying
);


ALTER TABLE public.oauthaccessdata OWNER TO mmuser;

--
-- Name: oauthapps; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.oauthapps (
    id character varying(26) NOT NULL,
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    clientsecret character varying(128),
    name character varying(64),
    description character varying(512),
    callbackurls character varying(1024),
    homepage character varying(256),
    istrusted boolean,
    iconurl character varying(512),
    mattermostappid character varying(32) DEFAULT ''::character varying NOT NULL,
    isdynamicallyregistered boolean DEFAULT false
);


ALTER TABLE public.oauthapps OWNER TO mmuser;

--
-- Name: oauthauthdata; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.oauthauthdata (
    clientid character varying(26),
    userid character varying(26),
    code character varying(128) NOT NULL,
    expiresin integer,
    createat bigint,
    redirecturi character varying(256),
    state character varying(1024),
    scope character varying(128),
    codechallenge character varying(128) DEFAULT ''::character varying,
    codechallengemethod character varying(10) DEFAULT ''::character varying,
    resource character varying(512) DEFAULT ''::character varying
);


ALTER TABLE public.oauthauthdata OWNER TO mmuser;

--
-- Name: outgoingoauthconnections; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.outgoingoauthconnections (
    id character varying(26) NOT NULL,
    name character varying(64),
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    clientid character varying(255),
    clientsecret character varying(255),
    credentialsusername character varying(255),
    credentialspassword character varying(255),
    oauthtokenurl text,
    granttype public.outgoingoauthconnections_granttype DEFAULT 'client_credentials'::public.outgoingoauthconnections_granttype,
    audiences character varying(1024)
);


ALTER TABLE public.outgoingoauthconnections OWNER TO mmuser;

--
-- Name: outgoingwebhooks; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.outgoingwebhooks (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    creatorid character varying(26),
    channelid character varying(26),
    teamid character varying(26),
    triggerwords character varying(1024),
    callbackurls character varying(1024),
    displayname character varying(64),
    contenttype character varying(128),
    triggerwhen integer,
    username character varying(64),
    iconurl character varying(1024),
    description character varying(500)
);


ALTER TABLE public.outgoingwebhooks OWNER TO mmuser;

--
-- Name: persistentnotifications; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.persistentnotifications (
    postid character varying(26) NOT NULL,
    createat bigint,
    lastsentat bigint,
    deleteat bigint,
    sentcount smallint
);


ALTER TABLE public.persistentnotifications OWNER TO mmuser;

--
-- Name: pluginkeyvaluestore; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.pluginkeyvaluestore (
    pluginid character varying(190) NOT NULL,
    pkey character varying(150) NOT NULL,
    pvalue bytea,
    expireat bigint
);


ALTER TABLE public.pluginkeyvaluestore OWNER TO mmuser;

--
-- Name: postacknowledgements; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.postacknowledgements (
    postid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    acknowledgedat bigint,
    remoteid character varying(26) DEFAULT ''::character varying,
    channelid character varying(26) DEFAULT ''::character varying
);


ALTER TABLE public.postacknowledgements OWNER TO mmuser;

--
-- Name: postreminders; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.postreminders (
    postid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    targettime bigint
);


ALTER TABLE public.postreminders OWNER TO mmuser;

--
-- Name: posts_by_team_day; Type: MATERIALIZED VIEW; Schema: public; Owner: mmuser
--

CREATE MATERIALIZED VIEW public.posts_by_team_day AS
 SELECT (to_timestamp(((p.createat / 1000))::double precision))::date AS day,
    count(*) AS num,
    c.teamid
   FROM (public.posts p
     JOIN public.channels c ON (((p.channelid)::text = (c.id)::text)))
  GROUP BY ((to_timestamp(((p.createat / 1000))::double precision))::date), c.teamid
  WITH NO DATA;


ALTER TABLE public.posts_by_team_day OWNER TO mmuser;

--
-- Name: postspriority; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.postspriority (
    postid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    priority character varying(32) NOT NULL,
    requestedack boolean,
    persistentnotifications boolean
);


ALTER TABLE public.postspriority OWNER TO mmuser;

--
-- Name: poststats; Type: MATERIALIZED VIEW; Schema: public; Owner: mmuser
--

CREATE MATERIALIZED VIEW public.poststats AS
 SELECT posts.userid,
    (to_timestamp(((posts.createat / 1000))::double precision))::date AS day,
    count(*) AS numposts,
    max(posts.createat) AS lastpostdate
   FROM public.posts
  GROUP BY posts.userid, ((to_timestamp(((posts.createat / 1000))::double precision))::date)
  WITH NO DATA;


ALTER TABLE public.poststats OWNER TO mmuser;

--
-- Name: preferences; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.preferences (
    userid character varying(26) NOT NULL,
    category character varying(32) NOT NULL,
    name character varying(32) NOT NULL,
    value text
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.preferences OWNER TO mmuser;

--
-- Name: productnoticeviewstate; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.productnoticeviewstate (
    userid character varying(26) NOT NULL,
    noticeid character varying(26) NOT NULL,
    viewed integer,
    "timestamp" bigint
);


ALTER TABLE public.productnoticeviewstate OWNER TO mmuser;

--
-- Name: propertygroups; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.propertygroups (
    id character varying(26) NOT NULL,
    name character varying(64) NOT NULL
);


ALTER TABLE public.propertygroups OWNER TO mmuser;

--
-- Name: publicchannels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.publicchannels (
    id character varying(26) NOT NULL,
    deleteat bigint,
    teamid character varying(26),
    displayname character varying(64),
    name character varying(64),
    header character varying(1024),
    purpose character varying(250)
);


ALTER TABLE public.publicchannels OWNER TO mmuser;

--
-- Name: reactions; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.reactions (
    userid character varying(26) NOT NULL,
    postid character varying(26) NOT NULL,
    emojiname character varying(64) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    remoteid character varying(26),
    channelid character varying(26) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.reactions OWNER TO mmuser;

--
-- Name: readreceipts; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.readreceipts (
    postid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    expireat bigint NOT NULL
);


ALTER TABLE public.readreceipts OWNER TO mmuser;

--
-- Name: recapchannels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.recapchannels (
    id character varying(26) NOT NULL,
    recapid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    channelname character varying(64) NOT NULL,
    highlights text,
    actionitems text,
    sourcepostids text,
    createat bigint NOT NULL
);


ALTER TABLE public.recapchannels OWNER TO mmuser;

--
-- Name: recaps; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.recaps (
    id character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    title character varying(255) NOT NULL,
    createat bigint NOT NULL,
    updateat bigint NOT NULL,
    deleteat bigint NOT NULL,
    totalmessagecount integer NOT NULL,
    status character varying(32) NOT NULL,
    readat bigint DEFAULT 0 NOT NULL,
    botid character varying(26) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.recaps OWNER TO mmuser;

--
-- Name: recentsearches; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.recentsearches (
    userid character(26) NOT NULL,
    searchpointer integer NOT NULL,
    query jsonb,
    createat bigint NOT NULL
);


ALTER TABLE public.recentsearches OWNER TO mmuser;

--
-- Name: remoteclusters; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.remoteclusters (
    remoteid character varying(26) NOT NULL,
    remoteteamid character varying(26),
    name character varying(64) NOT NULL,
    displayname character varying(64),
    siteurl character varying(512),
    createat bigint,
    lastpingat bigint,
    token character varying(26),
    remotetoken character varying(26),
    topics character varying(512),
    creatorid character varying(26),
    pluginid character varying(190) DEFAULT ''::character varying NOT NULL,
    options smallint DEFAULT 0 NOT NULL,
    defaultteamid character varying(26) DEFAULT ''::character varying,
    deleteat bigint DEFAULT 0,
    lastglobalusersyncat bigint DEFAULT 0
);


ALTER TABLE public.remoteclusters OWNER TO mmuser;

--
-- Name: retentionidsfordeletion; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.retentionidsfordeletion (
    id character varying(26) NOT NULL,
    tablename character varying(64),
    ids character varying(26)[]
);


ALTER TABLE public.retentionidsfordeletion OWNER TO mmuser;

--
-- Name: retentionpolicies; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.retentionpolicies (
    id character varying(26) NOT NULL,
    displayname character varying(64),
    postduration bigint
);


ALTER TABLE public.retentionpolicies OWNER TO mmuser;

--
-- Name: retentionpolicieschannels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.retentionpolicieschannels (
    policyid character varying(26),
    channelid character varying(26) NOT NULL
);


ALTER TABLE public.retentionpolicieschannels OWNER TO mmuser;

--
-- Name: retentionpoliciesteams; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.retentionpoliciesteams (
    policyid character varying(26),
    teamid character varying(26) NOT NULL
);


ALTER TABLE public.retentionpoliciesteams OWNER TO mmuser;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.roles (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    permissions text,
    schememanaged boolean,
    builtin boolean
);


ALTER TABLE public.roles OWNER TO mmuser;

--
-- Name: scheduledposts; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.scheduledposts (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    userid character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    rootid character varying(26),
    message character varying(65535),
    props character varying(8000),
    fileids character varying(300),
    priority text,
    scheduledat bigint NOT NULL,
    processedat bigint,
    errorcode character varying(200),
    type text
);


ALTER TABLE public.scheduledposts OWNER TO mmuser;

--
-- Name: schemes; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.schemes (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    scope character varying(32),
    defaultteamadminrole character varying(64),
    defaultteamuserrole character varying(64),
    defaultchanneladminrole character varying(64),
    defaultchanneluserrole character varying(64),
    defaultteamguestrole character varying(64),
    defaultchannelguestrole character varying(64),
    defaultplaybookadminrole character varying(64) DEFAULT ''::character varying,
    defaultplaybookmemberrole character varying(64) DEFAULT ''::character varying,
    defaultrunadminrole character varying(64) DEFAULT ''::character varying,
    defaultrunmemberrole character varying(64) DEFAULT ''::character varying
);


ALTER TABLE public.schemes OWNER TO mmuser;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.sessions (
    id character varying(26) NOT NULL,
    token character varying(26),
    createat bigint,
    expiresat bigint,
    lastactivityat bigint,
    userid character varying(26),
    deviceid character varying(512),
    roles character varying(256),
    isoauth boolean,
    props jsonb,
    expirednotify boolean
);


ALTER TABLE public.sessions OWNER TO mmuser;

--
-- Name: sharedchannelattachments; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.sharedchannelattachments (
    id character varying(26) NOT NULL,
    fileid character varying(26),
    remoteid character varying(26),
    createat bigint,
    lastsyncat bigint
);


ALTER TABLE public.sharedchannelattachments OWNER TO mmuser;

--
-- Name: sharedchannelremotes; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.sharedchannelremotes (
    id character varying(26) NOT NULL,
    channelid character varying(26) NOT NULL,
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    isinviteaccepted boolean,
    isinviteconfirmed boolean,
    remoteid character varying(26),
    lastpostupdateat bigint,
    lastpostid character varying(26),
    lastpostcreateat bigint DEFAULT 0 NOT NULL,
    lastpostcreateid character varying(26),
    deleteat bigint DEFAULT 0,
    lastmemberssyncat bigint DEFAULT 0
);


ALTER TABLE public.sharedchannelremotes OWNER TO mmuser;

--
-- Name: sharedchannels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.sharedchannels (
    channelid character varying(26) NOT NULL,
    teamid character varying(26),
    home boolean,
    readonly boolean,
    sharename character varying(64),
    sharedisplayname character varying(64),
    sharepurpose character varying(250),
    shareheader character varying(1024),
    creatorid character varying(26),
    createat bigint,
    updateat bigint,
    remoteid character varying(26)
);


ALTER TABLE public.sharedchannels OWNER TO mmuser;

--
-- Name: sharedchannelusers; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.sharedchannelusers (
    id character varying(26) NOT NULL,
    userid character varying(26),
    remoteid character varying(26),
    createat bigint,
    lastsyncat bigint,
    channelid character varying(26),
    lastmembershipsyncat bigint DEFAULT 0
);


ALTER TABLE public.sharedchannelusers OWNER TO mmuser;

--
-- Name: sidebarcategories; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.sidebarcategories (
    id character varying(128) NOT NULL,
    userid character varying(26),
    teamid character varying(26),
    sortorder bigint,
    sorting character varying(64),
    type character varying(64),
    displayname character varying(64),
    muted boolean,
    collapsed boolean
);


ALTER TABLE public.sidebarcategories OWNER TO mmuser;

--
-- Name: sidebarchannels; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.sidebarchannels (
    channelid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    categoryid character varying(128) NOT NULL,
    sortorder bigint
);


ALTER TABLE public.sidebarchannels OWNER TO mmuser;

--
-- Name: status; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.status (
    userid character varying(26) NOT NULL,
    status character varying(32),
    manual boolean,
    lastactivityat bigint,
    dndendtime bigint,
    prevstatus character varying(32)
);


ALTER TABLE public.status OWNER TO mmuser;

--
-- Name: systems; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.systems (
    name character varying(64) NOT NULL,
    value character varying(1024)
);


ALTER TABLE public.systems OWNER TO mmuser;

--
-- Name: teammembers; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.teammembers (
    teamid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    roles character varying(256),
    deleteat bigint,
    schemeuser boolean,
    schemeadmin boolean,
    schemeguest boolean,
    createat bigint DEFAULT 0
);


ALTER TABLE public.teammembers OWNER TO mmuser;

--
-- Name: teams; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.teams (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    displayname character varying(64),
    name character varying(64),
    description character varying(255),
    email character varying(128),
    type public.team_type,
    companyname character varying(64),
    alloweddomains character varying(1000),
    inviteid character varying(32),
    schemeid character varying(26),
    allowopeninvite boolean,
    lastteamiconupdate bigint,
    groupconstrained boolean,
    cloudlimitsarchived boolean DEFAULT false NOT NULL
);


ALTER TABLE public.teams OWNER TO mmuser;

--
-- Name: temporaryposts; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.temporaryposts (
    postid character varying(26) NOT NULL,
    type character varying(26) NOT NULL,
    expireat bigint NOT NULL,
    message character varying(65535),
    fileids character varying(300)
);


ALTER TABLE public.temporaryposts OWNER TO mmuser;

--
-- Name: termsofservice; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.termsofservice (
    id character varying(26) NOT NULL,
    createat bigint,
    userid character varying(26),
    text character varying(65535)
);


ALTER TABLE public.termsofservice OWNER TO mmuser;

--
-- Name: threadmemberships; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.threadmemberships (
    postid character varying(26) NOT NULL,
    userid character varying(26) NOT NULL,
    following boolean,
    lastviewed bigint,
    lastupdated bigint,
    unreadmentions bigint
)
WITH (autovacuum_vacuum_scale_factor='0.1', autovacuum_analyze_scale_factor='0.05');


ALTER TABLE public.threadmemberships OWNER TO mmuser;

--
-- Name: threads; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.threads (
    postid character varying(26) NOT NULL,
    replycount bigint,
    lastreplyat bigint,
    participants jsonb,
    channelid character varying(26),
    threaddeleteat bigint,
    threadteamid character varying(26)
);


ALTER TABLE public.threads OWNER TO mmuser;

--
-- Name: tokens; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.tokens (
    token character varying(64) NOT NULL,
    createat bigint,
    type character varying(64),
    extra character varying(2048)
);


ALTER TABLE public.tokens OWNER TO mmuser;

--
-- Name: translations; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.translations (
    objectid character varying(26) NOT NULL,
    dstlang character varying NOT NULL,
    objecttype character varying,
    providerid character varying NOT NULL,
    normhash character(64) NOT NULL,
    text text NOT NULL,
    confidence real,
    meta jsonb,
    updateat bigint NOT NULL
);


ALTER TABLE public.translations OWNER TO mmuser;

--
-- Name: uploadsessions; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.uploadsessions (
    id character varying(26) NOT NULL,
    type public.upload_session_type,
    createat bigint,
    userid character varying(26),
    channelid character varying(26),
    filename character varying(256),
    path character varying(512),
    filesize bigint,
    fileoffset bigint,
    remoteid character varying(26),
    reqfileid character varying(26)
);


ALTER TABLE public.uploadsessions OWNER TO mmuser;

--
-- Name: useraccesstokens; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.useraccesstokens (
    id character varying(26) NOT NULL,
    token character varying(26),
    userid character varying(26),
    description character varying(512),
    isactive boolean
);


ALTER TABLE public.useraccesstokens OWNER TO mmuser;

--
-- Name: usergroups; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.usergroups (
    id character varying(26) NOT NULL,
    name character varying(64),
    displayname character varying(128),
    description character varying(1024),
    source character varying(64),
    remoteid character varying(48),
    createat bigint,
    updateat bigint,
    deleteat bigint,
    allowreference boolean
);


ALTER TABLE public.usergroups OWNER TO mmuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.users (
    id character varying(26) NOT NULL,
    createat bigint,
    updateat bigint,
    deleteat bigint,
    username character varying(64),
    password character varying(128),
    authdata character varying(128),
    authservice character varying(32),
    email character varying(128),
    emailverified boolean,
    nickname character varying(64),
    firstname character varying(64),
    lastname character varying(64),
    roles character varying(256),
    allowmarketing boolean,
    props jsonb,
    notifyprops jsonb,
    lastpasswordupdate bigint,
    lastpictureupdate bigint,
    failedattempts integer,
    locale character varying(5),
    mfaactive boolean,
    mfasecret character varying(128),
    "position" character varying(128),
    timezone jsonb,
    remoteid character varying(26),
    lastlogin bigint DEFAULT 0 NOT NULL,
    mfausedtimestamps jsonb
);


ALTER TABLE public.users OWNER TO mmuser;

--
-- Name: usertermsofservice; Type: TABLE; Schema: public; Owner: mmuser
--

CREATE TABLE public.usertermsofservice (
    userid character varying(26) NOT NULL,
    termsofserviceid character varying(26),
    createat bigint
);


ALTER TABLE public.usertermsofservice OWNER TO mmuser;

--
-- Data for Name: accesscontrolpolicies; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.accesscontrolpolicies (id, name, type, active, createat, revision, version, data, props) FROM stdin;
\.


--
-- Data for Name: accesscontrolpolicyhistory; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.accesscontrolpolicyhistory (id, name, type, createat, revision, version, data, props) FROM stdin;
\.


--
-- Data for Name: audits; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.audits (id, createat, userid, action, extrainfo, ipaddress, sessionid) FROM stdin;
xi5nperd4jgnbdybsj7g7g3xkr	1773126750827		/api/v4/users/login	attempt - login_id=admin	172.17.0.1	
3bzmh7uy6p81mph4kdejzrgzee	1773126750835		/api/v4/users/login	failure - login_id=admin	172.17.0.1	
xpcx95eh5jyhujdd1xbpiqpxjh	1773126751340		/api/v4/users/login	attempt - login_id=admin	172.17.0.1	
mxcx58pispgn5jc937hebcfuhe	1773126751811	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/users/login	authenticated	172.17.0.1	
4cun4epcjtndmf4jcf79nz3tqa	1773126751819	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/users/login	success session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3a1k8kyza3ba5jqeybfjzkksze	1773126752578	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
q74u6c8cmp8ppriqzxxkxgf9pe	1773126753199	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
zkmoi9ydwffcdrnqedoj7pyspy	1773126753400	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nmq117c77jrizxt3yccro7ne4y	1773126754043	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ywecfbkw5jye8mhh7cet96t7we	1773126754720	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
z3h51qugwtgr7c7d7xmnddfnuc	1773126755384	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
mt4xknzqnjfdfxhfwon5q59efo	1773126756066	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
hno5p8gcqtrtjcffz3nkkfx99h	1773126756274	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/config	updateConfig	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
k1ng8xmribdypydcwhpesxuo5r	1773126764992	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=project-alpha	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
4b7gi6z3itdmfeisg4iezn7oih	1773126765023	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
4gizkn68ojdezcnpbsgz65rxeh	1773126765046	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
7qo9nqtrh3rbjx4rqpb7rwdbph	1773126765075	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3tpuop7zotrnurxa5huai5d45o	1773126765103	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1erq58hh5pbpjyu8ow1g3pbyie	1773126765133	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
jxhbm3hympgkjf1nfnxx7nbxre	1773126765156	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
wd64h8nbgfyh5rf6zund8hmqjr	1773126765178	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
fr9wez4hft8m9nfsm6w8yenrih	1773126765201	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
mh46uyc5xfyduyso8kudrsnxhy	1773126765224	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
p7so4gj99jrhifxtuh68rxawfa	1773126765246	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/xbdo3t9uq7gxmgnk4xopy1pkee/members	name=project-alpha user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
za99yxg6mjg9xpeisc61qui9ha	1773126765278	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=project-beta	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3i9kkxh7m7y9zdjrhxob7j1agy	1773126765307	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
48undckqgbg5pnno6f3p7f5i8r	1773126765328	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
bpqf8jz33bbe3nk5ymnh5acogw	1773126765349	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
9i81g8hbijrhuxidaoxxferuhh	1773126765370	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
h8mk4gcw8b8b7njnu1hqh6ikye	1773126765398	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
epkmdj6bs3y1xkxmmbj4wot5ho	1773126765419	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
jkmsb6n1jj8wpyhm3pe3td66uo	1773126765440	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
f9domgt47tykfcfbagxbg9q8ty	1773126765462	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
kbd33zgrmtyntfg4nzhrctetzo	1773126765484	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ptwn3gwt5b8p9j1rspp39gdybc	1773126765506	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qk4rrkf1stnn5ydh15bgh16nth/members	name=project-beta user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
88so7has8f8hxp8cp9fftmq5zc	1773126765536	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=deployments	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
r4yizjimo7nmbx5bpcfwpx53ao	1773126765565	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
7hhoy7p4einjtmrmsbr6n5no3h	1773126765586	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
rbztifbj83dn5cebm5tfhpn3ur	1773126773434		/api/v4/users/login	attempt - login_id=grace.lee session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
yqhwikp5cfdqjp8es9ukimcd5r	1773126765608	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
acxhk3th1b8qpbguyc3h717ina	1773126765629	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
utzopq3s3789xxx7ut9s5n3ctw	1773126765656	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3h564m3wdtg9bmn8ib8wuo461h	1773126765699	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
6n81bzi9mpnqtkdq9asidbjjnr	1773126765721	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
zk3opooq3trs9cr63sbdypbo4h	1773126765743	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
wbipfsb13tyi7efcsmnsrxtn1e	1773126765764	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
rfg9qk618jboiexz5hr85ogsoh	1773126765794	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=code-reviews	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
jucqsappabyybjphddrcht5eny	1773126765822	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
8hq5bpbpkfg3drrs6apsf1cenw	1773126765864	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
w8pfbg4fu3rzz8bm43ner9r9aa	1773126765913	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
grs59wgtrtf3bypmdckishsqfe	1773126765935	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
5sne8z48jfga9qy5jni8psss3r	1773126765956	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
eoynwmno6pnkzn9xxz9owbnq1e	1773126765999	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
hf4m3d7t83gybygwx11qa9ffpr	1773126766020	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
djn9t9heybd9pfqnaci3fg8ifo	1773126766050	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=bugs-and-issues	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nseu3yq8zpynzp4k8hnq9htd5c	1773126766078	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
dz6s7iu6y3dqug17o9qhbqt7dy	1773126766120	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
q3rhreisopgqdmdak56eu87ngo	1773126766230	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
iazhucqzdpg3pb8kdmhzsq6bpe	1773126766273	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
q1py9ppk5pdo5desraej4iy1xe	1773126766398	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
4m5363nuftbcxx7q6opsw7yhae	1773126766426	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
pkdxsini3t8iz8uirsnghbtzio	1773126766488	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
tdid9atampboixzjbij3rw3adh	1773126766510	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
n1mrbbrmajg7mmzhs9wshnrqby	1773126766531	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
jz7ds6914jdcpq9ho767coribw	1773126766563	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=tech-discussions	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
f5wmk66qaiyaidhwntpoaeetor	1773126766590	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
kzxqod595t8xtp1qyn7x4q9mce	1773126766611	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
n4b6iyripj8afkh1nsngccq5zy	1773126766632	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
dfny57kqftr87bpy8n8zdqhmgh	1773126766652	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1p8wp85qmfgaxb17poi18pp9tw	1773126766679	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
b7hp7zcowi8f8rhuwxytqueppw	1773126766700	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1drziueg3ibezp8rgokgo348nr	1773126766721	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
jjzypqz4eigxjgto455krn1xto	1773126766743	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
6t8iny33ufd7fkng96ogeh54ie	1773126765677	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/j443od6puifhjf85mfwk55h8ec/members	name=deployments user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
9ucz7t834jydjppszkdkgupyoh	1773126765843	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
pg7k6yy7eb81jdc3ihec1w3wph	1773126765886	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
z6t976zmjffeu8fy7mt6m1ndor	1773126765977	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/dewd9f48ij85xgq7tfte859qfa/members	name=code-reviews user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
rrm6gshxo7bp8nxai6ksq9k8nr	1773126766098	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
81k8o8wyytfwpnapct697wpiyr	1773126766140	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
izcgot34g7yi9yxxo79z9zstmo	1773126766167	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
99yadjountgr9r6fj8iph4yqoc	1773126766188	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
kpopri8pnib35ygtstgzfcaq7o	1773126766208	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
o5rfi5na1jrk8gimw67ty3d3ar	1773126766252	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/bbekt5pgxfnc5qmpwaxux3py1a/members	name=bugs-and-issues user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
mrh54g4yopy3bcd7a87uu9grqe	1773126766303	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=standup-notes	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
a94hxuc8zi8xxnpa4tmi8kfjjw	1773126766330	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
itnf74m11bfg7xa47p9y754c4h	1773126766356	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
fms76idd5irh5jwcmty58u483o	1773126766377	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
wunysipdttn6bm1dyqd33471nc	1773126766446	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
pjd8mgugwpbome5at8r4g9c7dc	1773126766467	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/wnrktfozbffs7dpb5u86mga3uy/members	name=standup-notes user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
r9qgbz9b13rmfg61hsfb9eiq8a	1773126766888	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
afyw1k8df78izctpy9omum67ja	1773126766909	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ktqmj15usjfj3nmiz7b1n5zama	1773126766957	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
o7izc7ki93d3uy385daptixx7r	1773126767036	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ktiu869o7bgk8kymgof73sobfh	1773126767057	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
7tnkxu9z7t8tbxggzf38ysg7na	1773126767209	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ujyi967a7t8suj19u9djrbj4gy	1773126767318	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
67w9sofa5irkxrbbemm86sj9fr	1773126767347	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=campaigns	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
cz5pq6kokigg3qn4z4poobyxgr	1773126767376	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/scj33w14etykfdaydd3cqcae5w/members	name=campaigns user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
jckexi1oa7nd3rtob85r6ywqto	1773126767577	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7ijgcabphifx7mwe9g6w9paemy/members	name=social-media user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nyfj6cjz6fg7dgnepepjweotjc	1773126767598	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7ijgcabphifx7mwe9g6w9paemy/members	name=social-media user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ducawfa4ytd43fdbejm1fpeb8c	1773126767619	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7ijgcabphifx7mwe9g6w9paemy/members	name=social-media user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
mzw9sb4yeiyqxnkudjt8fpyskc	1773126767649	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=analytics	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
n6c74dkaxinfdgpxswkb9x98wa	1773126767676	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qiiq57tw6jbru8zhkytut8i64e/members	name=analytics user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
izehrowuain3zb9u4kj34f4gjr	1773126767877	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/4rt4rx5mt38b38y9ec93k89boo/members	name=content-calendar user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
mrdcaus7z38t3dutkkqhhkcrny	1773126767952	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=design-requests	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nj7tqbuutfd3xcgd7ocuiq1tbr	1773126767979	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/3zf3d5jjnfymug7cq1ucdwqrmo/members	name=design-requests user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
s9pwwnqf3tfibqfb1nai7g8ach	1773126768026	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/3zf3d5jjnfymug7cq1ucdwqrmo/members	name=design-requests user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
aruo8io84pdi9dgz8nah71m9eh	1773126766765	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
wph1b7xt4fyozr9jimw1as313o	1773126766787	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/rmsexzhn3jgy7f4kbgnczsa3sa/members	name=tech-discussions user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
8qx3qpzr4jbopmby9r9dgrmh4o	1773126766817	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=devops	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
r6uqzw1jxiyy7q61z3446qtcah	1773126766845	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
po69kp1pmpdcjfzojbmy8sugqo	1773126766867	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
4s9m8wer1byf8mpyxobc6zywqr	1773126766937	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
8u1a9zwsff8pudd8yg7us5bech	1773126766980	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
pcjwidba4jyzdfbj3b3w3h3fcw	1773126767014	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/et85fk3eqpgrip4z9eydcg4weo/members	name=devops user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nxcnci171jy9imqw1n95fec85o	1773126767089	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=security-alerts	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
bjhot1hm7pfe5mhacaq6b4z4or	1773126767117	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3m66ry886jgebjhzifym7puj5c	1773126767139	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
fewyoce4x78izrwdti8du33fxh	1773126767160	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
q8d53i1f73gtpnih6y6ttr63xy	1773126767181	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
j39tkdgot7d5dybbb4iczc33to	1773126767231	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
w7ds5mfygj8u8bxwj3wootq34y	1773126767253	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
qkfkhjeya7d1ipkoqj6hr33jyw	1773126767276	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nc1qwxh13bb7fbabuor8u73i6c	1773126767296	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/mjjwsjpbnt8rxyp7n5mt1f3syw/members	name=security-alerts user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
mbwrcgw6itgd3yx77tyg9ydejy	1773126767405	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/scj33w14etykfdaydd3cqcae5w/members	name=campaigns user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1mqesja347838y8sjt9isk86ye	1773126767426	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/scj33w14etykfdaydd3cqcae5w/members	name=campaigns user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ezrbob4ezpni9b94pjidzatacw	1773126767448	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/scj33w14etykfdaydd3cqcae5w/members	name=campaigns user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
e9r68yc79py83g89qyy6saj5aa	1773126767470	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/scj33w14etykfdaydd3cqcae5w/members	name=campaigns user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
uxhtozax43869mswmoso8w64wh	1773126767500	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=social-media	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1obk95psw7r9uf71kfo3kkk99e	1773126767528	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7ijgcabphifx7mwe9g6w9paemy/members	name=social-media user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ifrermqypfbrpytztizdtbqjda	1773126767556	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7ijgcabphifx7mwe9g6w9paemy/members	name=social-media user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
u6hmxwjirjdm5ftggjyt3iihhw	1773126767704	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qiiq57tw6jbru8zhkytut8i64e/members	name=analytics user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
k1r7ogy3jjrrmyn5ygbt64cpby	1773126767726	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qiiq57tw6jbru8zhkytut8i64e/members	name=analytics user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
qg11pznaif8zind3x3pbj3g4fc	1773126767747	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qiiq57tw6jbru8zhkytut8i64e/members	name=analytics user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
e585q4ahtjnz3regwnr1e6nrqe	1773126767768	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/qiiq57tw6jbru8zhkytut8i64e/members	name=analytics user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
q7orn13h93nkxrmib8tghznhnc	1773126767796	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=content-calendar	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ctuyp6cnhirm3jwq8hn4nu3oxh	1773126767824	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/4rt4rx5mt38b38y9ec93k89boo/members	name=content-calendar user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
weq9ztcqdpnzpgrmoa1a84tx3w	1773126767853	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/4rt4rx5mt38b38y9ec93k89boo/members	name=content-calendar user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
8yx7131babnktgwkw8of3k3tpo	1773126767900	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/4rt4rx5mt38b38y9ec93k89boo/members	name=content-calendar user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
qxu8uo4g97y3zdc1rkagaqftua	1773126767921	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/4rt4rx5mt38b38y9ec93k89boo/members	name=content-calendar user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
g1srhc45utritb4uxyeo74wxqe	1773126768005	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/3zf3d5jjnfymug7cq1ucdwqrmo/members	name=design-requests user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
kkcc87fmefbxbp3qyycojz8pow	1773126768143	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
gi61zu9gbtysbxsbp1dsuqae3w	1773126768046	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/3zf3d5jjnfymug7cq1ucdwqrmo/members	name=design-requests user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nr4bks6xtpnbix1gg1rpmxqh3r	1773126768067	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/3zf3d5jjnfymug7cq1ucdwqrmo/members	name=design-requests user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
9j4mgwuy57ycxxz4mxzdn78uue	1773126768096	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=announcements	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
gzmdrp8t3i8pupgxyxy3w4zz4a	1773126768123	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
wxaoitt913gsdp3uc5rj4qxz8w	1773126768254	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
oackzi11kpb93x7zb1wk9zx1yc	1773126768296	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1aqmyxtdairfxxfmj9uyg4nekc	1773126768318	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
en6gx4yxh7gi3ri9trxbf8o4bh	1773126768338	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
omfnngmmki85d8se1kbztjqkea	1773126768380	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
9mf7535kpbrpipb3nbum8km7qa	1773126768423	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
sb1yfpkxjbn99nfaqjwg39zfbh	1773126768614	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
y4puc7kt9pbo3ctm7mt4jn1d8w	1773126768635	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
a8wfsm6p4bbddyurcqrwnx4car	1773126768698	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
xotnmbtrciy8dge33rwrs491or	1773126768740	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
f4dt4zti77f45jcymza3zamace	1773126768784	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
cpp46k5keb8qbmytt19jhqw6wa	1773126768925	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
pcnxbfkno7bm9b35ap5o1x7c3w	1773126769013	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
d11p3rya9jg63ch71aseeddmto	1773126769034	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ury5mssghtyhuk6cnkodoe5sby	1773126769054	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3gu1myq5hjgyfef7w59178q76w	1773126769095	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
gu9s9coinfgnjjhmus67h8t3jh	1773126769137	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
srdb7qntxfddxrwndcznaf7cdr	1773126769276	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ef9rbkjtc38j9gqhbfujopog7h	1773126769324	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
e9afdkzuwf85imharo31pn5cqy	1773126769346	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
rf71u3p1pif38nxnnfj3a74hyh	1773126769367	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
wh6eogxhffg4889err8icx3qge	1773126769388	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
e83gqx3dptysug3uc878ork3pa	1773126769450	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
w9pqsn3ry78uje1uix816zdcoa	1773126769493	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ghga7n5tz7y19qufcsi898q7be	1773126769524	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=help-desk	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
psx5r6f6ntry8rmuyfj7xr4mhw	1773126769552	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
sw4bg14cj7ba8qxq7z3uo5suhh	1773126769614	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ty5ndm5mi3ngbqyqyxgffqaaeh	1773126769634	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
x4cgxtcmzjdsijbr3jqm9ebjaw	1773126769661	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
taok8r7zf7r65ghmxn8o7pqi9e	1773126769683	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
8koj7ek5ftf7tj7oazucdsdsae	1773126768164	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
oztxb4raspnj3ej6ngz4fqom4r	1773126768185	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
eej68d1op7rh8yh8c7n16uxepa	1773126768206	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
idhmt8fakbbb9ndcx3b5wob7dr	1773126768233	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1qeg3banat89z8z5yqo543a47e	1773126768276	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
9etxq9in5tbupq68e47b53ts9w	1773126768359	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
m5owehtqs7fxdpk5jkea8a6n7h	1773126768403	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/5b4hke3753y73feti3hhtfbgiy/members	name=announcements user_id=udhm7t7fqfgc9k9funqdejmeea	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nyptpcqgsbg19cw3x5duztpaha	1773126768453	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=random	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
anoouefybpdsieb5snmn714trw	1773126768481	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
j9nkffdy13d6tmbgnb5u89xada	1773126768504	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
tsm3b3y81ifp3fdmncbas3uh4e	1773126768525	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
54ff1585z7gkpg63aeeoe47nzh	1773126768546	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
bedo4fiknidztjgbudngpc9fzh	1773126768567	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
cqu559i7zffumdi9hd3ca6w91o	1773126768593	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
czax3b69wtbypyxthktc3gce6a	1773126768656	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
fz7id48ntt8ozpq1kfsj93uzpr	1773126768677	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1pcjq4awx7gyxdngmko9qrko6y	1773126768719	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
s55y8jeudinijyao55ofo9w14r	1773126768762	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/1s9nagudoiboirmb7ckj1mukfy/members	name=random user_id=udhm7t7fqfgc9k9funqdejmeea	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3fw96fbe3igbtjkgn899gwrgia	1773126768814	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=watercooler	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
cok14yfzbiyz8ddgwa1brbsx4h	1773126768841	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
tpyfneaqsj8bbmbc7i51jhutec	1773126768862	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
aaeu8ntt3pdg5nbz7c58x7ex9o	1773126768883	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
r7ht3p5qnbnktx96nwne1xmncc	1773126768904	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
4e9i5i1nfjr35bzcqp5hdepdoa	1773126768955	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
d566xwdjxjg6jpxaxbuu3iw8io	1773126768975	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
z3s85w1zzbb1mqozo539xf6pxw	1773126768994	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
kean8u78uj81ijfqyweny7hwwo	1773126769075	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
csdudsumgi8hjgms3gd41omkke	1773126769116	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/8k1ahz7c8pgmjyco414pgi5f4y/members	name=watercooler user_id=udhm7t7fqfgc9k9funqdejmeea	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
fwra9xzhfjg1jpeycmqqwsz91w	1773126769166	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=events	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
j5dc9t1r63fmjg5xpnwdt5mo9a	1773126769195	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
x9bhajmzajgq8pcyxduprunste	1773126769215	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
6aarwyrw4f8jjm6omrni6ksj9e	1773126769235	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
eq5wxkjhm7dc7rcmzfcth4q1do	1773126769256	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
q516t6dp7bnr8y515e6rxtc3xr	1773126769304	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
r1fjojauf3na7xdx78ghnjnwqc	1773126769409	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
5c6n75qqrtbp5kg5qdzujq78wc	1773126769429	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
kj5p5ewzgpdyxxs4cj5acq4axa	1773126769471	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/7aqugqd4dprbzcfcnm8ouuqczc/members	name=events user_id=udhm7t7fqfgc9k9funqdejmeea	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
edmjeqc68jrzdq8jqdtgubsqew	1773126769573	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
c4b1aobrajd9zfh93s1i75pmcy	1773126769594	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
97c11ft6jbf5mnb6h747kpijpc	1773126769725	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
nga7qq8xojdp5k47ng93gikxfc	1773126769851	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
6hf6fwueqfy8jc4jrchcbrz43y	1773126769952	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
b3pap81xxibzbb81koebkffise	1773126769972	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
jcb5p4jj5j8kurur4fme57tg8e	1773126770020	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
11p5amisxpnczqosb5wsi46mua	1773126770064	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
hzekei1hrib3tcckyqw8ggkz1c	1773126770085	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
86r34j7gspbabqgqsaybsk1qac	1773126770106	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
34yq1nefrpynbytcx7foo3dzsa	1773126770127	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
u3sj6sgh3frzimwmqgtb5wbgso	1773126770685	x916bcascjyyjrc5y8e5hbrgna	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1fwix9cmnff8mm7ydxwxmxbe7o	1773126770690	x916bcascjyyjrc5y8e5hbrgna	/api/v4/users/login	success session_user=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	hkx93uuuobfe7mxrafocn394zh
eyippyw8ffgdixazo44phde9oo	1773126770697		/api/v4/users/login	attempt - login_id=jane.smith session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
31gdk8ciptgm7nhzsczniyt6so	1773126771068	4zd57afzr3f4mbydt14j5mzqza	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
m3bnwj78aify7mis4m5qys9y5c	1773126771073	4zd57afzr3f4mbydt14j5mzqza	/api/v4/users/login	success session_user=4zd57afzr3f4mbydt14j5mzqza	172.17.0.1	9ybi6pe1n3rtzmyh6m7ud45oue
349ab63gybrxdnr7n9bhk4cwrw	1773126771078		/api/v4/users/login	attempt - login_id=bob.wilson session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ap41ahiy37y83jaiz3rftot8gh	1773126771414	46fd55wk57bdzq89debc4cxugr	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
y3fk6cigkbgb8pkoyrpp9p46ec	1773126771418	46fd55wk57bdzq89debc4cxugr	/api/v4/users/login	success session_user=46fd55wk57bdzq89debc4cxugr	172.17.0.1	8r8wh45ou7nddcwq1i7wybowdr
5xf8ztw613dqfp5a54jwzhciso	1773126771423		/api/v4/users/login	attempt - login_id=alice.johnson session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
pyujfg4gwpbb9may8btbasksqh	1773126771754	6a4bti99g3rtdmx11dhnihhg6r	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ox4gpgs5ifgt9cuyxjcbop5nmh	1773126771757	6a4bti99g3rtdmx11dhnihhg6r	/api/v4/users/login	success session_user=6a4bti99g3rtdmx11dhnihhg6r	172.17.0.1	s5rtznf6ktguteuzh9xd99r5cw
gei8kdw61pnsi887o1a676xtgh	1773126771761		/api/v4/users/login	attempt - login_id=charlie.brown session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
o3kqtksaridhmkbtkh97a3ptwr	1773126772229	ccmjk1p1abffx87a4zni7n4uoh	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
em35ah779jb7m8eihk9fbxh5ur	1773126772233	ccmjk1p1abffx87a4zni7n4uoh	/api/v4/users/login	success session_user=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	tom49sb8yty69kujdu9wbx3g7h
ugd148f6qbgcdjkj1t1zk5wh6o	1773126772238		/api/v4/users/login	attempt - login_id=diana.prince session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
djths4j86brqjjb6mcdcuu8mgr	1773126772589	3bekgg684bb5iq6tfq1h95az3r	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3ofngbwer7rmpmn4x7uo6u49ze	1773126772594	3bekgg684bb5iq6tfq1h95az3r	/api/v4/users/login	success session_user=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	pr894dfjbpn9pkhx9ek8u1r4ka
g99ymrgidtfg888a9bczqajwte	1773126772599		/api/v4/users/login	attempt - login_id=emma.davis session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ufiefkqbrbg3xqe7tpdnd78hmw	1773126773066	93n7axewi7n9xpsis8z5d99bre	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
3zjngwscbfyxzcuouugk6g4bxh	1773126773071	93n7axewi7n9xpsis8z5d99bre	/api/v4/users/login	success session_user=93n7axewi7n9xpsis8z5d99bre	172.17.0.1	max74b3qxfnqdk4bandpipanwo
ed1naszaxindtggkxx115dmbna	1773126773076		/api/v4/users/login	attempt - login_id=frank.miller session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
cqoz54dutpg888qr5bkr8ymqka	1773126773425	m16j1q6rkfdpxguuksz7wmpuba	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
tfkina1tebbh5bqb1nggqficaw	1773126773429	m16j1q6rkfdpxguuksz7wmpuba	/api/v4/users/login	success session_user=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	3a8dcq77dfd4d8mshdks4hx47r
ns4o35wxbpneude3tq96ptahbw	1773126769704	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=ccmjk1p1abffx87a4zni7n4uoh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
mhxaikktjpyxjfj8ops6cd5h9w	1773126769746	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
5ej8sdbzzinxtxtohsjw615o6o	1773126769767	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
eby7t8wqyjrdipra4qyycyaiqa	1773126769788	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
6xcny3nsfidni88ibzmp7k4x9a	1773126769810	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
aao4gpjcpjbrzqsb93x1jwaw9o	1773126769830	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/i14jg6ym6tbfmpa93dq5usgrty/members	name=help-desk user_id=udhm7t7fqfgc9k9funqdejmeea	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
n1ch8q9c5ffdug53eqgs5jh7fh	1773126769882	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels	name=new-joiners	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
1sosdfhzdjbsz8dwn88weuwgyr	1773126769910	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=3bekgg684bb5iq6tfq1h95az3r	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
xgfbpe3jwtd3dctgumf4e9ewiw	1773126769931	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=46fd55wk57bdzq89debc4cxugr	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
xbdh6pfmqtf1mczgh5n5znkiqr	1773126769993	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
cxkx6b7g8fgzteqwatzpaqb3jw	1773126770042	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
r6zh7h4xm3nc8f6muhgix7himo	1773126770149	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
x3c71cd353gbxx155e1o9em63h	1773126770170	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=m16j1q6rkfdpxguuksz7wmpuba	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
h5dok9jzz7nyugqu8eu8dbsh7a	1773126770192	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=udhm7t7fqfgc9k9funqdejmeea	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
8ejhd17fkfn37npt99i5mr13je	1773126770214	7kq76ce63id48nkz4hcp5rg3xh	/api/v4/channels/h4d4ekghxin7bnutsuomgd776w/members	name=new-joiners user_id=x916bcascjyyjrc5y8e5hbrgna	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
n6g5t1t9effgz88mdmo19nri8r	1773126770218		/api/v4/users/login	attempt - login_id=john.doe session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
hpcjjhw5jtn5imf4mh6nuw6jae	1773126773902	dp4jszrpsjnjpjw1mth4ygithy	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
799nm1qsxpro7rnakff5xy5oay	1773126773906	dp4jszrpsjnjpjw1mth4ygithy	/api/v4/users/login	success session_user=dp4jszrpsjnjpjw1mth4ygithy	172.17.0.1	4bt89yqgxbdy5xmc9ku3nnymfw
t3qk3xw8xfr8u8gbnsxjecibqr	1773126773911		/api/v4/users/login	attempt - login_id=henry.taylor session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
habcsjqdhtnxjftys5ccjqsihr	1773126774378	udhm7t7fqfgc9k9funqdejmeea	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
7mdyutbkzi8j3qbra49is6kgma	1773126774383	udhm7t7fqfgc9k9funqdejmeea	/api/v4/users/login	success session_user=udhm7t7fqfgc9k9funqdejmeea	172.17.0.1	76dj35jg7jdfdb8u8cnqheh76o
rf8pkhtsy3y75yfxa8yrtd6y9r	1773126774388		/api/v4/users/login	attempt - login_id=ivy.chen session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
rsxdcjnfibdxjniro49nczch8a	1773126774855	7e4ojpbykjntdmpu94y5ekub1c	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
dwucpkgbqid9fnz7qx9ejhz54a	1773126774860	7e4ojpbykjntdmpu94y5ekub1c	/api/v4/users/login	success session_user=7e4ojpbykjntdmpu94y5ekub1c	172.17.0.1	kf1f3jyuhbge9bwfyc8hi3xd7w
rk17btpnkbf6pqkax9jo674fxc	1773126774865		/api/v4/users/login	attempt - login_id=kevin.martinez session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
naw1dfm4wfbgunhtcygzen7qtw	1773126775333	9mbmdxz1kidnmemmqi9ou5w1ah	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
n9q7owhcxfrndg5qma4sddur6h	1773126775337	9mbmdxz1kidnmemmqi9ou5w1ah	/api/v4/users/login	success session_user=9mbmdxz1kidnmemmqi9ou5w1ah	172.17.0.1	6exy4c3qq7ga5n473jj9ccoyic
wrxtjhsaq7d63jsnxpb78tg7jw	1773126775342		/api/v4/users/login	attempt - login_id=lisa.wang session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
ippig1k5cjdrpq97mmwm5jxbyy	1773126775692	g7r88gtyqjfdzgnwhr9xyumzce	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
5cyz8d6nbjfd7mef64tz1nzpih	1773126775697	g7r88gtyqjfdzgnwhr9xyumzce	/api/v4/users/login	success session_user=g7r88gtyqjfdzgnwhr9xyumzce	172.17.0.1	hsrn7w3gc7fszgc9dywmcwdmhy
wjecnxdb6pg73y1rfy4xm8u5iy	1773126775702		/api/v4/users/login	attempt - login_id=mike.ross session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
m3icms987jdy8enidg3pg77sbc	1773126776028	cxtqjdhuqiydtmdmtdc1mesbfo	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
p1iywqe4ijyadyejjgypwbph7o	1773126776033	cxtqjdhuqiydtmdmtdc1mesbfo	/api/v4/users/login	success session_user=cxtqjdhuqiydtmdmtdc1mesbfo	172.17.0.1	adzdgzmk4fbnzj61sz63abzw6c
fgw9hrit4tdizmfgr7c83tj1qw	1773126776038		/api/v4/users/login	attempt - login_id=natalie.kim session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
udn4nbssatdpmfgdfqhfy889ah	1773126776506	hacoqz1mijy8db1u95mwsgt6pe	/api/v4/users/login	authenticated session_user=7kq76ce63id48nkz4hcp5rg3xh	172.17.0.1	m7jzkjttu7d83qfe34bdmgietw
hiusjpur63f9xyxigipb9fksge	1773126776510	hacoqz1mijy8db1u95mwsgt6pe	/api/v4/users/login	success session_user=hacoqz1mijy8db1u95mwsgt6pe	172.17.0.1	hufgu63bftypzdskouugwzh8qc
\.


--
-- Data for Name: bots; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.bots (userid, description, ownerid, createat, updateat, deleteat, lasticonupdate) FROM stdin;
uw9ayeotajnate67greqnm1t6w	Calls Bot	com.mattermost.calls	1773126731114	1773126731114	0	0
\.


--
-- Data for Name: calls; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.calls (id, channelid, startat, endat, createat, deleteat, title, postid, threadid, ownerid, participants, stats, props) FROM stdin;
\.


--
-- Data for Name: calls_channels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.calls_channels (channelid, enabled, props) FROM stdin;
\.


--
-- Data for Name: calls_jobs; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.calls_jobs (id, callid, type, creatorid, initat, startat, endat, props) FROM stdin;
\.


--
-- Data for Name: calls_sessions; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.calls_sessions (id, callid, userid, joinat, unmuted, raisedhand) FROM stdin;
\.


--
-- Data for Name: channelbookmarks; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.channelbookmarks (id, ownerid, channelid, fileinfoid, createat, updateat, deleteat, displayname, sortorder, linkurl, imageurl, emoji, type, originalid, parentid) FROM stdin;
\.


--
-- Data for Name: channelmemberhistory; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.channelmemberhistory (channelid, userid, jointime, leavetime) FROM stdin;
jy91zp8mu7yk5gb5hy9qhdcfeh	7kq76ce63id48nkz4hcp5rg3xh	1773126763221	\N
q9g6zsqkfty78mguucajfoqcir	7kq76ce63id48nkz4hcp5rg3xh	1773126763249	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	x916bcascjyyjrc5y8e5hbrgna	1773126763295	\N
q9g6zsqkfty78mguucajfoqcir	x916bcascjyyjrc5y8e5hbrgna	1773126763318	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	4zd57afzr3f4mbydt14j5mzqza	1773126763364	\N
q9g6zsqkfty78mguucajfoqcir	4zd57afzr3f4mbydt14j5mzqza	1773126763381	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	46fd55wk57bdzq89debc4cxugr	1773126763415	\N
q9g6zsqkfty78mguucajfoqcir	46fd55wk57bdzq89debc4cxugr	1773126763432	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	6a4bti99g3rtdmx11dhnihhg6r	1773126763467	\N
q9g6zsqkfty78mguucajfoqcir	6a4bti99g3rtdmx11dhnihhg6r	1773126763484	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	ccmjk1p1abffx87a4zni7n4uoh	1773126763519	\N
q9g6zsqkfty78mguucajfoqcir	ccmjk1p1abffx87a4zni7n4uoh	1773126763535	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	3bekgg684bb5iq6tfq1h95az3r	1773126763569	\N
q9g6zsqkfty78mguucajfoqcir	3bekgg684bb5iq6tfq1h95az3r	1773126763586	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	9mbmdxz1kidnmemmqi9ou5w1ah	1773126763621	\N
q9g6zsqkfty78mguucajfoqcir	9mbmdxz1kidnmemmqi9ou5w1ah	1773126763638	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	g7r88gtyqjfdzgnwhr9xyumzce	1773126763672	\N
q9g6zsqkfty78mguucajfoqcir	g7r88gtyqjfdzgnwhr9xyumzce	1773126763689	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	cxtqjdhuqiydtmdmtdc1mesbfo	1773126763725	\N
q9g6zsqkfty78mguucajfoqcir	cxtqjdhuqiydtmdmtdc1mesbfo	1773126763742	\N
jy91zp8mu7yk5gb5hy9qhdcfeh	hacoqz1mijy8db1u95mwsgt6pe	1773126763775	\N
q9g6zsqkfty78mguucajfoqcir	hacoqz1mijy8db1u95mwsgt6pe	1773126763791	\N
c8sz8dja63nu7ms3jjtyws3ora	7kq76ce63id48nkz4hcp5rg3xh	1773126763835	\N
oqcewxpjqtdgxn91q6ehrqgzdr	7kq76ce63id48nkz4hcp5rg3xh	1773126763852	\N
c8sz8dja63nu7ms3jjtyws3ora	93n7axewi7n9xpsis8z5d99bre	1773126763888	\N
oqcewxpjqtdgxn91q6ehrqgzdr	93n7axewi7n9xpsis8z5d99bre	1773126763904	\N
c8sz8dja63nu7ms3jjtyws3ora	m16j1q6rkfdpxguuksz7wmpuba	1773126763940	\N
oqcewxpjqtdgxn91q6ehrqgzdr	m16j1q6rkfdpxguuksz7wmpuba	1773126763955	\N
c8sz8dja63nu7ms3jjtyws3ora	dp4jszrpsjnjpjw1mth4ygithy	1773126763986	\N
oqcewxpjqtdgxn91q6ehrqgzdr	dp4jszrpsjnjpjw1mth4ygithy	1773126764002	\N
c8sz8dja63nu7ms3jjtyws3ora	7e4ojpbykjntdmpu94y5ekub1c	1773126764036	\N
oqcewxpjqtdgxn91q6ehrqgzdr	7e4ojpbykjntdmpu94y5ekub1c	1773126764053	\N
c8sz8dja63nu7ms3jjtyws3ora	9mbmdxz1kidnmemmqi9ou5w1ah	1773126764087	\N
oqcewxpjqtdgxn91q6ehrqgzdr	9mbmdxz1kidnmemmqi9ou5w1ah	1773126764104	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	7kq76ce63id48nkz4hcp5rg3xh	1773126764149	\N
nih4d7rfsir4xpi8tidfcunqrr	7kq76ce63id48nkz4hcp5rg3xh	1773126764166	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	x916bcascjyyjrc5y8e5hbrgna	1773126764212	\N
nih4d7rfsir4xpi8tidfcunqrr	x916bcascjyyjrc5y8e5hbrgna	1773126764229	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	4zd57afzr3f4mbydt14j5mzqza	1773126764262	\N
nih4d7rfsir4xpi8tidfcunqrr	4zd57afzr3f4mbydt14j5mzqza	1773126764278	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	46fd55wk57bdzq89debc4cxugr	1773126764312	\N
nih4d7rfsir4xpi8tidfcunqrr	46fd55wk57bdzq89debc4cxugr	1773126764329	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	6a4bti99g3rtdmx11dhnihhg6r	1773126764363	\N
nih4d7rfsir4xpi8tidfcunqrr	6a4bti99g3rtdmx11dhnihhg6r	1773126764379	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	ccmjk1p1abffx87a4zni7n4uoh	1773126764413	\N
nih4d7rfsir4xpi8tidfcunqrr	ccmjk1p1abffx87a4zni7n4uoh	1773126764429	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	3bekgg684bb5iq6tfq1h95az3r	1773126764463	\N
nih4d7rfsir4xpi8tidfcunqrr	3bekgg684bb5iq6tfq1h95az3r	1773126764480	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	93n7axewi7n9xpsis8z5d99bre	1773126764514	\N
nih4d7rfsir4xpi8tidfcunqrr	93n7axewi7n9xpsis8z5d99bre	1773126764531	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	m16j1q6rkfdpxguuksz7wmpuba	1773126764566	\N
nih4d7rfsir4xpi8tidfcunqrr	m16j1q6rkfdpxguuksz7wmpuba	1773126764583	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	dp4jszrpsjnjpjw1mth4ygithy	1773126764618	\N
nih4d7rfsir4xpi8tidfcunqrr	dp4jszrpsjnjpjw1mth4ygithy	1773126764636	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	udhm7t7fqfgc9k9funqdejmeea	1773126764670	\N
nih4d7rfsir4xpi8tidfcunqrr	udhm7t7fqfgc9k9funqdejmeea	1773126764687	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	7e4ojpbykjntdmpu94y5ekub1c	1773126764723	\N
nih4d7rfsir4xpi8tidfcunqrr	7e4ojpbykjntdmpu94y5ekub1c	1773126764740	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	9mbmdxz1kidnmemmqi9ou5w1ah	1773126764776	\N
nih4d7rfsir4xpi8tidfcunqrr	9mbmdxz1kidnmemmqi9ou5w1ah	1773126764793	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	g7r88gtyqjfdzgnwhr9xyumzce	1773126764830	\N
nih4d7rfsir4xpi8tidfcunqrr	g7r88gtyqjfdzgnwhr9xyumzce	1773126764847	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	cxtqjdhuqiydtmdmtdc1mesbfo	1773126764881	\N
nih4d7rfsir4xpi8tidfcunqrr	cxtqjdhuqiydtmdmtdc1mesbfo	1773126764899	\N
ody3wrq1o7rpjpzxsx7sqtdqdo	hacoqz1mijy8db1u95mwsgt6pe	1773126764934	\N
nih4d7rfsir4xpi8tidfcunqrr	hacoqz1mijy8db1u95mwsgt6pe	1773126764952	\N
xbdo3t9uq7gxmgnk4xopy1pkee	7kq76ce63id48nkz4hcp5rg3xh	1773126764984	\N
xbdo3t9uq7gxmgnk4xopy1pkee	3bekgg684bb5iq6tfq1h95az3r	1773126765022	\N
xbdo3t9uq7gxmgnk4xopy1pkee	46fd55wk57bdzq89debc4cxugr	1773126765045	\N
xbdo3t9uq7gxmgnk4xopy1pkee	4zd57afzr3f4mbydt14j5mzqza	1773126765074	\N
xbdo3t9uq7gxmgnk4xopy1pkee	6a4bti99g3rtdmx11dhnihhg6r	1773126765103	\N
xbdo3t9uq7gxmgnk4xopy1pkee	9mbmdxz1kidnmemmqi9ou5w1ah	1773126765133	\N
xbdo3t9uq7gxmgnk4xopy1pkee	ccmjk1p1abffx87a4zni7n4uoh	1773126765155	\N
xbdo3t9uq7gxmgnk4xopy1pkee	cxtqjdhuqiydtmdmtdc1mesbfo	1773126765178	\N
xbdo3t9uq7gxmgnk4xopy1pkee	g7r88gtyqjfdzgnwhr9xyumzce	1773126765200	\N
xbdo3t9uq7gxmgnk4xopy1pkee	hacoqz1mijy8db1u95mwsgt6pe	1773126765223	\N
xbdo3t9uq7gxmgnk4xopy1pkee	x916bcascjyyjrc5y8e5hbrgna	1773126765246	\N
qk4rrkf1stnn5ydh15bgh16nth	7kq76ce63id48nkz4hcp5rg3xh	1773126765269	\N
qk4rrkf1stnn5ydh15bgh16nth	3bekgg684bb5iq6tfq1h95az3r	1773126765307	\N
qk4rrkf1stnn5ydh15bgh16nth	46fd55wk57bdzq89debc4cxugr	1773126765328	\N
qk4rrkf1stnn5ydh15bgh16nth	4zd57afzr3f4mbydt14j5mzqza	1773126765348	\N
qk4rrkf1stnn5ydh15bgh16nth	6a4bti99g3rtdmx11dhnihhg6r	1773126765369	\N
qk4rrkf1stnn5ydh15bgh16nth	9mbmdxz1kidnmemmqi9ou5w1ah	1773126765397	\N
qk4rrkf1stnn5ydh15bgh16nth	ccmjk1p1abffx87a4zni7n4uoh	1773126765419	\N
qk4rrkf1stnn5ydh15bgh16nth	cxtqjdhuqiydtmdmtdc1mesbfo	1773126765440	\N
qk4rrkf1stnn5ydh15bgh16nth	g7r88gtyqjfdzgnwhr9xyumzce	1773126765461	\N
qk4rrkf1stnn5ydh15bgh16nth	hacoqz1mijy8db1u95mwsgt6pe	1773126765483	\N
qk4rrkf1stnn5ydh15bgh16nth	x916bcascjyyjrc5y8e5hbrgna	1773126765505	\N
j443od6puifhjf85mfwk55h8ec	7kq76ce63id48nkz4hcp5rg3xh	1773126765528	\N
j443od6puifhjf85mfwk55h8ec	ccmjk1p1abffx87a4zni7n4uoh	1773126765676	\N
dewd9f48ij85xgq7tfte859qfa	7kq76ce63id48nkz4hcp5rg3xh	1773126765786	\N
dewd9f48ij85xgq7tfte859qfa	46fd55wk57bdzq89debc4cxugr	1773126765842	\N
dewd9f48ij85xgq7tfte859qfa	6a4bti99g3rtdmx11dhnihhg6r	1773126765885	\N
dewd9f48ij85xgq7tfte859qfa	g7r88gtyqjfdzgnwhr9xyumzce	1773126765976	\N
bbekt5pgxfnc5qmpwaxux3py1a	7kq76ce63id48nkz4hcp5rg3xh	1773126766042	\N
bbekt5pgxfnc5qmpwaxux3py1a	46fd55wk57bdzq89debc4cxugr	1773126766097	\N
bbekt5pgxfnc5qmpwaxux3py1a	6a4bti99g3rtdmx11dhnihhg6r	1773126766139	\N
bbekt5pgxfnc5qmpwaxux3py1a	9mbmdxz1kidnmemmqi9ou5w1ah	1773126766166	\N
bbekt5pgxfnc5qmpwaxux3py1a	ccmjk1p1abffx87a4zni7n4uoh	1773126766187	\N
bbekt5pgxfnc5qmpwaxux3py1a	cxtqjdhuqiydtmdmtdc1mesbfo	1773126766208	\N
bbekt5pgxfnc5qmpwaxux3py1a	hacoqz1mijy8db1u95mwsgt6pe	1773126766251	\N
wnrktfozbffs7dpb5u86mga3uy	3bekgg684bb5iq6tfq1h95az3r	1773126766330	\N
wnrktfozbffs7dpb5u86mga3uy	46fd55wk57bdzq89debc4cxugr	1773126766355	\N
wnrktfozbffs7dpb5u86mga3uy	4zd57afzr3f4mbydt14j5mzqza	1773126766376	\N
wnrktfozbffs7dpb5u86mga3uy	ccmjk1p1abffx87a4zni7n4uoh	1773126766446	\N
wnrktfozbffs7dpb5u86mga3uy	cxtqjdhuqiydtmdmtdc1mesbfo	1773126766466	\N
rmsexzhn3jgy7f4kbgnczsa3sa	7kq76ce63id48nkz4hcp5rg3xh	1773126766554	\N
et85fk3eqpgrip4z9eydcg4weo	7kq76ce63id48nkz4hcp5rg3xh	1773126766809	\N
et85fk3eqpgrip4z9eydcg4weo	4zd57afzr3f4mbydt14j5mzqza	1773126766887	\N
et85fk3eqpgrip4z9eydcg4weo	6a4bti99g3rtdmx11dhnihhg6r	1773126766909	\N
et85fk3eqpgrip4z9eydcg4weo	ccmjk1p1abffx87a4zni7n4uoh	1773126766957	\N
et85fk3eqpgrip4z9eydcg4weo	hacoqz1mijy8db1u95mwsgt6pe	1773126767035	\N
et85fk3eqpgrip4z9eydcg4weo	x916bcascjyyjrc5y8e5hbrgna	1773126767057	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	7kq76ce63id48nkz4hcp5rg3xh	1773126767081	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	9mbmdxz1kidnmemmqi9ou5w1ah	1773126767208	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	x916bcascjyyjrc5y8e5hbrgna	1773126767317	\N
scj33w14etykfdaydd3cqcae5w	7e4ojpbykjntdmpu94y5ekub1c	1773126767375	\N
7ijgcabphifx7mwe9g6w9paemy	7kq76ce63id48nkz4hcp5rg3xh	1773126767492	\N
7ijgcabphifx7mwe9g6w9paemy	9mbmdxz1kidnmemmqi9ou5w1ah	1773126767576	\N
7ijgcabphifx7mwe9g6w9paemy	dp4jszrpsjnjpjw1mth4ygithy	1773126767598	\N
7ijgcabphifx7mwe9g6w9paemy	m16j1q6rkfdpxguuksz7wmpuba	1773126767618	\N
qiiq57tw6jbru8zhkytut8i64e	7e4ojpbykjntdmpu94y5ekub1c	1773126767676	\N
4rt4rx5mt38b38y9ec93k89boo	7kq76ce63id48nkz4hcp5rg3xh	1773126767789	\N
4rt4rx5mt38b38y9ec93k89boo	9mbmdxz1kidnmemmqi9ou5w1ah	1773126767876	\N
3zf3d5jjnfymug7cq1ucdwqrmo	7e4ojpbykjntdmpu94y5ekub1c	1773126767978	\N
3zf3d5jjnfymug7cq1ucdwqrmo	9mbmdxz1kidnmemmqi9ou5w1ah	1773126768025	\N
3zf3d5jjnfymug7cq1ucdwqrmo	dp4jszrpsjnjpjw1mth4ygithy	1773126768045	\N
3zf3d5jjnfymug7cq1ucdwqrmo	m16j1q6rkfdpxguuksz7wmpuba	1773126768066	\N
5b4hke3753y73feti3hhtfbgiy	3bekgg684bb5iq6tfq1h95az3r	1773126768122	\N
5b4hke3753y73feti3hhtfbgiy	9mbmdxz1kidnmemmqi9ou5w1ah	1773126768253	\N
5b4hke3753y73feti3hhtfbgiy	cxtqjdhuqiydtmdmtdc1mesbfo	1773126768296	\N
5b4hke3753y73feti3hhtfbgiy	dp4jszrpsjnjpjw1mth4ygithy	1773126768317	\N
5b4hke3753y73feti3hhtfbgiy	g7r88gtyqjfdzgnwhr9xyumzce	1773126768338	\N
5b4hke3753y73feti3hhtfbgiy	m16j1q6rkfdpxguuksz7wmpuba	1773126768379	\N
5b4hke3753y73feti3hhtfbgiy	x916bcascjyyjrc5y8e5hbrgna	1773126768422	\N
1s9nagudoiboirmb7ckj1mukfy	7kq76ce63id48nkz4hcp5rg3xh	1773126768445	\N
1s9nagudoiboirmb7ckj1mukfy	9mbmdxz1kidnmemmqi9ou5w1ah	1773126768613	\N
1s9nagudoiboirmb7ckj1mukfy	ccmjk1p1abffx87a4zni7n4uoh	1773126768634	\N
1s9nagudoiboirmb7ckj1mukfy	g7r88gtyqjfdzgnwhr9xyumzce	1773126768697	\N
1s9nagudoiboirmb7ckj1mukfy	m16j1q6rkfdpxguuksz7wmpuba	1773126768740	\N
1s9nagudoiboirmb7ckj1mukfy	x916bcascjyyjrc5y8e5hbrgna	1773126768783	\N
8k1ahz7c8pgmjyco414pgi5f4y	7kq76ce63id48nkz4hcp5rg3xh	1773126768805	\N
8k1ahz7c8pgmjyco414pgi5f4y	7e4ojpbykjntdmpu94y5ekub1c	1773126768924	\N
8k1ahz7c8pgmjyco414pgi5f4y	cxtqjdhuqiydtmdmtdc1mesbfo	1773126769013	\N
8k1ahz7c8pgmjyco414pgi5f4y	dp4jszrpsjnjpjw1mth4ygithy	1773126769033	\N
8k1ahz7c8pgmjyco414pgi5f4y	g7r88gtyqjfdzgnwhr9xyumzce	1773126769053	\N
8k1ahz7c8pgmjyco414pgi5f4y	m16j1q6rkfdpxguuksz7wmpuba	1773126769094	\N
8k1ahz7c8pgmjyco414pgi5f4y	x916bcascjyyjrc5y8e5hbrgna	1773126769136	\N
7aqugqd4dprbzcfcnm8ouuqczc	7kq76ce63id48nkz4hcp5rg3xh	1773126769158	\N
7aqugqd4dprbzcfcnm8ouuqczc	7e4ojpbykjntdmpu94y5ekub1c	1773126769276	\N
7aqugqd4dprbzcfcnm8ouuqczc	9mbmdxz1kidnmemmqi9ou5w1ah	1773126769323	\N
7aqugqd4dprbzcfcnm8ouuqczc	ccmjk1p1abffx87a4zni7n4uoh	1773126769345	\N
7aqugqd4dprbzcfcnm8ouuqczc	cxtqjdhuqiydtmdmtdc1mesbfo	1773126769366	\N
7aqugqd4dprbzcfcnm8ouuqczc	dp4jszrpsjnjpjw1mth4ygithy	1773126769387	\N
7aqugqd4dprbzcfcnm8ouuqczc	m16j1q6rkfdpxguuksz7wmpuba	1773126769449	\N
7aqugqd4dprbzcfcnm8ouuqczc	x916bcascjyyjrc5y8e5hbrgna	1773126769492	\N
i14jg6ym6tbfmpa93dq5usgrty	3bekgg684bb5iq6tfq1h95az3r	1773126769552	\N
i14jg6ym6tbfmpa93dq5usgrty	6a4bti99g3rtdmx11dhnihhg6r	1773126769614	\N
i14jg6ym6tbfmpa93dq5usgrty	7e4ojpbykjntdmpu94y5ekub1c	1773126769634	\N
i14jg6ym6tbfmpa93dq5usgrty	93n7axewi7n9xpsis8z5d99bre	1773126769661	\N
i14jg6ym6tbfmpa93dq5usgrty	9mbmdxz1kidnmemmqi9ou5w1ah	1773126769682	\N
i14jg6ym6tbfmpa93dq5usgrty	ccmjk1p1abffx87a4zni7n4uoh	1773126769703	\N
i14jg6ym6tbfmpa93dq5usgrty	dp4jszrpsjnjpjw1mth4ygithy	1773126769745	\N
i14jg6ym6tbfmpa93dq5usgrty	g7r88gtyqjfdzgnwhr9xyumzce	1773126769766	\N
i14jg6ym6tbfmpa93dq5usgrty	hacoqz1mijy8db1u95mwsgt6pe	1773126769788	\N
i14jg6ym6tbfmpa93dq5usgrty	m16j1q6rkfdpxguuksz7wmpuba	1773126769809	\N
i14jg6ym6tbfmpa93dq5usgrty	udhm7t7fqfgc9k9funqdejmeea	1773126769829	\N
h4d4ekghxin7bnutsuomgd776w	3bekgg684bb5iq6tfq1h95az3r	1773126769909	\N
h4d4ekghxin7bnutsuomgd776w	46fd55wk57bdzq89debc4cxugr	1773126769930	\N
h4d4ekghxin7bnutsuomgd776w	7e4ojpbykjntdmpu94y5ekub1c	1773126769992	\N
h4d4ekghxin7bnutsuomgd776w	9mbmdxz1kidnmemmqi9ou5w1ah	1773126770041	\N
h4d4ekghxin7bnutsuomgd776w	hacoqz1mijy8db1u95mwsgt6pe	1773126770148	\N
h4d4ekghxin7bnutsuomgd776w	m16j1q6rkfdpxguuksz7wmpuba	1773126770170	\N
h4d4ekghxin7bnutsuomgd776w	udhm7t7fqfgc9k9funqdejmeea	1773126770191	\N
h4d4ekghxin7bnutsuomgd776w	x916bcascjyyjrc5y8e5hbrgna	1773126770213	\N
j443od6puifhjf85mfwk55h8ec	3bekgg684bb5iq6tfq1h95az3r	1773126765564	\N
j443od6puifhjf85mfwk55h8ec	46fd55wk57bdzq89debc4cxugr	1773126765586	\N
j443od6puifhjf85mfwk55h8ec	4zd57afzr3f4mbydt14j5mzqza	1773126765607	\N
j443od6puifhjf85mfwk55h8ec	6a4bti99g3rtdmx11dhnihhg6r	1773126765628	\N
j443od6puifhjf85mfwk55h8ec	9mbmdxz1kidnmemmqi9ou5w1ah	1773126765656	\N
j443od6puifhjf85mfwk55h8ec	cxtqjdhuqiydtmdmtdc1mesbfo	1773126765698	\N
j443od6puifhjf85mfwk55h8ec	g7r88gtyqjfdzgnwhr9xyumzce	1773126765720	\N
j443od6puifhjf85mfwk55h8ec	hacoqz1mijy8db1u95mwsgt6pe	1773126765742	\N
j443od6puifhjf85mfwk55h8ec	x916bcascjyyjrc5y8e5hbrgna	1773126765764	\N
dewd9f48ij85xgq7tfte859qfa	3bekgg684bb5iq6tfq1h95az3r	1773126765821	\N
dewd9f48ij85xgq7tfte859qfa	4zd57afzr3f4mbydt14j5mzqza	1773126765864	\N
dewd9f48ij85xgq7tfte859qfa	9mbmdxz1kidnmemmqi9ou5w1ah	1773126765912	\N
dewd9f48ij85xgq7tfte859qfa	ccmjk1p1abffx87a4zni7n4uoh	1773126765934	\N
dewd9f48ij85xgq7tfte859qfa	cxtqjdhuqiydtmdmtdc1mesbfo	1773126765956	\N
dewd9f48ij85xgq7tfte859qfa	hacoqz1mijy8db1u95mwsgt6pe	1773126765998	\N
dewd9f48ij85xgq7tfte859qfa	x916bcascjyyjrc5y8e5hbrgna	1773126766019	\N
bbekt5pgxfnc5qmpwaxux3py1a	3bekgg684bb5iq6tfq1h95az3r	1773126766077	\N
bbekt5pgxfnc5qmpwaxux3py1a	4zd57afzr3f4mbydt14j5mzqza	1773126766119	\N
bbekt5pgxfnc5qmpwaxux3py1a	g7r88gtyqjfdzgnwhr9xyumzce	1773126766229	\N
bbekt5pgxfnc5qmpwaxux3py1a	x916bcascjyyjrc5y8e5hbrgna	1773126766272	\N
wnrktfozbffs7dpb5u86mga3uy	7kq76ce63id48nkz4hcp5rg3xh	1773126766294	\N
wnrktfozbffs7dpb5u86mga3uy	6a4bti99g3rtdmx11dhnihhg6r	1773126766397	\N
wnrktfozbffs7dpb5u86mga3uy	9mbmdxz1kidnmemmqi9ou5w1ah	1773126766425	\N
wnrktfozbffs7dpb5u86mga3uy	g7r88gtyqjfdzgnwhr9xyumzce	1773126766487	\N
wnrktfozbffs7dpb5u86mga3uy	hacoqz1mijy8db1u95mwsgt6pe	1773126766509	\N
wnrktfozbffs7dpb5u86mga3uy	x916bcascjyyjrc5y8e5hbrgna	1773126766530	\N
rmsexzhn3jgy7f4kbgnczsa3sa	3bekgg684bb5iq6tfq1h95az3r	1773126766590	\N
rmsexzhn3jgy7f4kbgnczsa3sa	46fd55wk57bdzq89debc4cxugr	1773126766610	\N
rmsexzhn3jgy7f4kbgnczsa3sa	4zd57afzr3f4mbydt14j5mzqza	1773126766631	\N
rmsexzhn3jgy7f4kbgnczsa3sa	6a4bti99g3rtdmx11dhnihhg6r	1773126766651	\N
rmsexzhn3jgy7f4kbgnczsa3sa	9mbmdxz1kidnmemmqi9ou5w1ah	1773126766679	\N
rmsexzhn3jgy7f4kbgnczsa3sa	ccmjk1p1abffx87a4zni7n4uoh	1773126766700	\N
rmsexzhn3jgy7f4kbgnczsa3sa	cxtqjdhuqiydtmdmtdc1mesbfo	1773126766720	\N
rmsexzhn3jgy7f4kbgnczsa3sa	g7r88gtyqjfdzgnwhr9xyumzce	1773126766742	\N
rmsexzhn3jgy7f4kbgnczsa3sa	hacoqz1mijy8db1u95mwsgt6pe	1773126766764	\N
rmsexzhn3jgy7f4kbgnczsa3sa	x916bcascjyyjrc5y8e5hbrgna	1773126766786	\N
et85fk3eqpgrip4z9eydcg4weo	3bekgg684bb5iq6tfq1h95az3r	1773126766844	\N
et85fk3eqpgrip4z9eydcg4weo	46fd55wk57bdzq89debc4cxugr	1773126766866	\N
et85fk3eqpgrip4z9eydcg4weo	9mbmdxz1kidnmemmqi9ou5w1ah	1773126766936	\N
et85fk3eqpgrip4z9eydcg4weo	cxtqjdhuqiydtmdmtdc1mesbfo	1773126766979	\N
et85fk3eqpgrip4z9eydcg4weo	g7r88gtyqjfdzgnwhr9xyumzce	1773126767014	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	3bekgg684bb5iq6tfq1h95az3r	1773126767117	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	46fd55wk57bdzq89debc4cxugr	1773126767139	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	4zd57afzr3f4mbydt14j5mzqza	1773126767159	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	6a4bti99g3rtdmx11dhnihhg6r	1773126767180	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	ccmjk1p1abffx87a4zni7n4uoh	1773126767230	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	cxtqjdhuqiydtmdmtdc1mesbfo	1773126767253	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	g7r88gtyqjfdzgnwhr9xyumzce	1773126767275	\N
mjjwsjpbnt8rxyp7n5mt1f3syw	hacoqz1mijy8db1u95mwsgt6pe	1773126767295	\N
scj33w14etykfdaydd3cqcae5w	7kq76ce63id48nkz4hcp5rg3xh	1773126767339	\N
scj33w14etykfdaydd3cqcae5w	93n7axewi7n9xpsis8z5d99bre	1773126767404	\N
scj33w14etykfdaydd3cqcae5w	9mbmdxz1kidnmemmqi9ou5w1ah	1773126767425	\N
scj33w14etykfdaydd3cqcae5w	dp4jszrpsjnjpjw1mth4ygithy	1773126767447	\N
scj33w14etykfdaydd3cqcae5w	m16j1q6rkfdpxguuksz7wmpuba	1773126767470	\N
7ijgcabphifx7mwe9g6w9paemy	7e4ojpbykjntdmpu94y5ekub1c	1773126767527	\N
7ijgcabphifx7mwe9g6w9paemy	93n7axewi7n9xpsis8z5d99bre	1773126767555	\N
qiiq57tw6jbru8zhkytut8i64e	7kq76ce63id48nkz4hcp5rg3xh	1773126767640	\N
qiiq57tw6jbru8zhkytut8i64e	93n7axewi7n9xpsis8z5d99bre	1773126767704	\N
qiiq57tw6jbru8zhkytut8i64e	9mbmdxz1kidnmemmqi9ou5w1ah	1773126767725	\N
qiiq57tw6jbru8zhkytut8i64e	dp4jszrpsjnjpjw1mth4ygithy	1773126767747	\N
qiiq57tw6jbru8zhkytut8i64e	m16j1q6rkfdpxguuksz7wmpuba	1773126767768	\N
4rt4rx5mt38b38y9ec93k89boo	7e4ojpbykjntdmpu94y5ekub1c	1773126767824	\N
4rt4rx5mt38b38y9ec93k89boo	93n7axewi7n9xpsis8z5d99bre	1773126767853	\N
4rt4rx5mt38b38y9ec93k89boo	dp4jszrpsjnjpjw1mth4ygithy	1773126767899	\N
4rt4rx5mt38b38y9ec93k89boo	m16j1q6rkfdpxguuksz7wmpuba	1773126767921	\N
3zf3d5jjnfymug7cq1ucdwqrmo	7kq76ce63id48nkz4hcp5rg3xh	1773126767944	\N
3zf3d5jjnfymug7cq1ucdwqrmo	93n7axewi7n9xpsis8z5d99bre	1773126768005	\N
5b4hke3753y73feti3hhtfbgiy	7kq76ce63id48nkz4hcp5rg3xh	1773126768088	\N
5b4hke3753y73feti3hhtfbgiy	46fd55wk57bdzq89debc4cxugr	1773126768143	\N
5b4hke3753y73feti3hhtfbgiy	4zd57afzr3f4mbydt14j5mzqza	1773126768164	\N
5b4hke3753y73feti3hhtfbgiy	6a4bti99g3rtdmx11dhnihhg6r	1773126768185	\N
5b4hke3753y73feti3hhtfbgiy	7e4ojpbykjntdmpu94y5ekub1c	1773126768205	\N
5b4hke3753y73feti3hhtfbgiy	93n7axewi7n9xpsis8z5d99bre	1773126768233	\N
5b4hke3753y73feti3hhtfbgiy	ccmjk1p1abffx87a4zni7n4uoh	1773126768275	\N
5b4hke3753y73feti3hhtfbgiy	hacoqz1mijy8db1u95mwsgt6pe	1773126768359	\N
5b4hke3753y73feti3hhtfbgiy	udhm7t7fqfgc9k9funqdejmeea	1773126768402	\N
1s9nagudoiboirmb7ckj1mukfy	3bekgg684bb5iq6tfq1h95az3r	1773126768480	\N
1s9nagudoiboirmb7ckj1mukfy	46fd55wk57bdzq89debc4cxugr	1773126768502	\N
1s9nagudoiboirmb7ckj1mukfy	4zd57afzr3f4mbydt14j5mzqza	1773126768524	\N
1s9nagudoiboirmb7ckj1mukfy	6a4bti99g3rtdmx11dhnihhg6r	1773126768545	\N
1s9nagudoiboirmb7ckj1mukfy	7e4ojpbykjntdmpu94y5ekub1c	1773126768567	\N
1s9nagudoiboirmb7ckj1mukfy	93n7axewi7n9xpsis8z5d99bre	1773126768593	\N
1s9nagudoiboirmb7ckj1mukfy	cxtqjdhuqiydtmdmtdc1mesbfo	1773126768655	\N
1s9nagudoiboirmb7ckj1mukfy	dp4jszrpsjnjpjw1mth4ygithy	1773126768676	\N
1s9nagudoiboirmb7ckj1mukfy	hacoqz1mijy8db1u95mwsgt6pe	1773126768718	\N
1s9nagudoiboirmb7ckj1mukfy	udhm7t7fqfgc9k9funqdejmeea	1773126768761	\N
8k1ahz7c8pgmjyco414pgi5f4y	3bekgg684bb5iq6tfq1h95az3r	1773126768841	\N
8k1ahz7c8pgmjyco414pgi5f4y	46fd55wk57bdzq89debc4cxugr	1773126768861	\N
8k1ahz7c8pgmjyco414pgi5f4y	4zd57afzr3f4mbydt14j5mzqza	1773126768883	\N
8k1ahz7c8pgmjyco414pgi5f4y	6a4bti99g3rtdmx11dhnihhg6r	1773126768903	\N
8k1ahz7c8pgmjyco414pgi5f4y	93n7axewi7n9xpsis8z5d99bre	1773126768954	\N
8k1ahz7c8pgmjyco414pgi5f4y	9mbmdxz1kidnmemmqi9ou5w1ah	1773126768974	\N
8k1ahz7c8pgmjyco414pgi5f4y	ccmjk1p1abffx87a4zni7n4uoh	1773126768993	\N
8k1ahz7c8pgmjyco414pgi5f4y	hacoqz1mijy8db1u95mwsgt6pe	1773126769074	\N
8k1ahz7c8pgmjyco414pgi5f4y	udhm7t7fqfgc9k9funqdejmeea	1773126769115	\N
7aqugqd4dprbzcfcnm8ouuqczc	3bekgg684bb5iq6tfq1h95az3r	1773126769194	\N
7aqugqd4dprbzcfcnm8ouuqczc	46fd55wk57bdzq89debc4cxugr	1773126769214	\N
7aqugqd4dprbzcfcnm8ouuqczc	4zd57afzr3f4mbydt14j5mzqza	1773126769234	\N
7aqugqd4dprbzcfcnm8ouuqczc	6a4bti99g3rtdmx11dhnihhg6r	1773126769255	\N
7aqugqd4dprbzcfcnm8ouuqczc	93n7axewi7n9xpsis8z5d99bre	1773126769303	\N
7aqugqd4dprbzcfcnm8ouuqczc	g7r88gtyqjfdzgnwhr9xyumzce	1773126769408	\N
7aqugqd4dprbzcfcnm8ouuqczc	hacoqz1mijy8db1u95mwsgt6pe	1773126769428	\N
7aqugqd4dprbzcfcnm8ouuqczc	udhm7t7fqfgc9k9funqdejmeea	1773126769471	\N
i14jg6ym6tbfmpa93dq5usgrty	7kq76ce63id48nkz4hcp5rg3xh	1773126769515	\N
i14jg6ym6tbfmpa93dq5usgrty	46fd55wk57bdzq89debc4cxugr	1773126769572	\N
i14jg6ym6tbfmpa93dq5usgrty	4zd57afzr3f4mbydt14j5mzqza	1773126769593	\N
i14jg6ym6tbfmpa93dq5usgrty	cxtqjdhuqiydtmdmtdc1mesbfo	1773126769724	\N
i14jg6ym6tbfmpa93dq5usgrty	x916bcascjyyjrc5y8e5hbrgna	1773126769850	\N
h4d4ekghxin7bnutsuomgd776w	7kq76ce63id48nkz4hcp5rg3xh	1773126769874	\N
h4d4ekghxin7bnutsuomgd776w	4zd57afzr3f4mbydt14j5mzqza	1773126769952	\N
h4d4ekghxin7bnutsuomgd776w	6a4bti99g3rtdmx11dhnihhg6r	1773126769972	\N
h4d4ekghxin7bnutsuomgd776w	93n7axewi7n9xpsis8z5d99bre	1773126770020	\N
h4d4ekghxin7bnutsuomgd776w	ccmjk1p1abffx87a4zni7n4uoh	1773126770063	\N
h4d4ekghxin7bnutsuomgd776w	cxtqjdhuqiydtmdmtdc1mesbfo	1773126770084	\N
h4d4ekghxin7bnutsuomgd776w	dp4jszrpsjnjpjw1mth4ygithy	1773126770105	\N
h4d4ekghxin7bnutsuomgd776w	g7r88gtyqjfdzgnwhr9xyumzce	1773126770127	\N
5swgwrkocprjmrngo4qj4o74io	x916bcascjyyjrc5y8e5hbrgna	1773126782914	\N
5swgwrkocprjmrngo4qj4o74io	4zd57afzr3f4mbydt14j5mzqza	1773126782915	\N
ik8xxjatdfn75comxgxnq189iw	9mbmdxz1kidnmemmqi9ou5w1ah	1773126782982	\N
ik8xxjatdfn75comxgxnq189iw	93n7axewi7n9xpsis8z5d99bre	1773126782983	\N
ofr41qz4pjdtiyzza51qu7bxny	46fd55wk57bdzq89debc4cxugr	1773126783046	\N
ofr41qz4pjdtiyzza51qu7bxny	g7r88gtyqjfdzgnwhr9xyumzce	1773126783047	\N
5xxxy5dojj8pmbg441q5og511e	6a4bti99g3rtdmx11dhnihhg6r	1773126783121	\N
5xxxy5dojj8pmbg441q5og511e	cxtqjdhuqiydtmdmtdc1mesbfo	1773126783122	\N
e4yfhpb1rjbizxy8ygcf3u7w1r	udhm7t7fqfgc9k9funqdejmeea	1773126783197	\N
e4yfhpb1rjbizxy8ygcf3u7w1r	x916bcascjyyjrc5y8e5hbrgna	1773126783198	\N
qk34pb8dffr4ibk69r3xkzmy9o	3bekgg684bb5iq6tfq1h95az3r	1773126783271	\N
qk34pb8dffr4ibk69r3xkzmy9o	ccmjk1p1abffx87a4zni7n4uoh	1773126783271	\N
rffhn6t6jbfkiebs9cmahu7gae	7kq76ce63id48nkz4hcp5rg3xh	1773126783341	\N
rffhn6t6jbfkiebs9cmahu7gae	4zd57afzr3f4mbydt14j5mzqza	1773126783347	\N
rffhn6t6jbfkiebs9cmahu7gae	x916bcascjyyjrc5y8e5hbrgna	1773126783354	\N
rffhn6t6jbfkiebs9cmahu7gae	9mbmdxz1kidnmemmqi9ou5w1ah	1773126783361	\N
f3kpgwu4biddpbpyf18nbu6mpe	7kq76ce63id48nkz4hcp5rg3xh	1773126783505	\N
f3kpgwu4biddpbpyf18nbu6mpe	93n7axewi7n9xpsis8z5d99bre	1773126783512	\N
f3kpgwu4biddpbpyf18nbu6mpe	m16j1q6rkfdpxguuksz7wmpuba	1773126783518	\N
f3kpgwu4biddpbpyf18nbu6mpe	dp4jszrpsjnjpjw1mth4ygithy	1773126783525	\N
f3kpgwu4biddpbpyf18nbu6mpe	7e4ojpbykjntdmpu94y5ekub1c	1773126783533	\N
\.


--
-- Data for Name: channelmembers; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.channelmembers (channelid, userid, roles, lastviewedat, msgcount, mentioncount, notifyprops, lastupdateat, schemeuser, schemeadmin, schemeguest, mentioncountroot, msgcountroot, urgentmentioncount, autotranslation) FROM stdin;
jy91zp8mu7yk5gb5hy9qhdcfeh	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763215	t	t	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763242	t	t	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	x916bcascjyyjrc5y8e5hbrgna		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763288	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	x916bcascjyyjrc5y8e5hbrgna		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763310	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	4zd57afzr3f4mbydt14j5mzqza		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763357	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	4zd57afzr3f4mbydt14j5mzqza		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763374	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	46fd55wk57bdzq89debc4cxugr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763408	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	46fd55wk57bdzq89debc4cxugr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763425	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	6a4bti99g3rtdmx11dhnihhg6r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763460	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	6a4bti99g3rtdmx11dhnihhg6r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763477	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	ccmjk1p1abffx87a4zni7n4uoh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763512	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	ccmjk1p1abffx87a4zni7n4uoh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763529	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	3bekgg684bb5iq6tfq1h95az3r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763562	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	3bekgg684bb5iq6tfq1h95az3r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763579	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763614	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763631	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	g7r88gtyqjfdzgnwhr9xyumzce		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763665	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	g7r88gtyqjfdzgnwhr9xyumzce		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763682	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763717	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763735	t	f	f	0	0	0	f
jy91zp8mu7yk5gb5hy9qhdcfeh	hacoqz1mijy8db1u95mwsgt6pe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763769	t	f	f	0	0	0	f
q9g6zsqkfty78mguucajfoqcir	hacoqz1mijy8db1u95mwsgt6pe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763785	t	f	f	0	0	0	f
c8sz8dja63nu7ms3jjtyws3ora	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763828	t	t	f	0	0	0	f
oqcewxpjqtdgxn91q6ehrqgzdr	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763845	t	t	f	0	0	0	f
c8sz8dja63nu7ms3jjtyws3ora	93n7axewi7n9xpsis8z5d99bre		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763881	t	f	f	0	0	0	f
oqcewxpjqtdgxn91q6ehrqgzdr	93n7axewi7n9xpsis8z5d99bre		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763897	t	f	f	0	0	0	f
c8sz8dja63nu7ms3jjtyws3ora	7e4ojpbykjntdmpu94y5ekub1c		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764029	t	f	f	0	0	0	f
oqcewxpjqtdgxn91q6ehrqgzdr	7e4ojpbykjntdmpu94y5ekub1c		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764046	t	f	f	0	0	0	f
c8sz8dja63nu7ms3jjtyws3ora	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764080	t	f	f	0	0	0	f
oqcewxpjqtdgxn91q6ehrqgzdr	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764097	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764142	t	t	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	3bekgg684bb5iq6tfq1h95az3r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764456	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	3bekgg684bb5iq6tfq1h95az3r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764473	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	93n7axewi7n9xpsis8z5d99bre		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764507	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	93n7axewi7n9xpsis8z5d99bre		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764524	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	m16j1q6rkfdpxguuksz7wmpuba		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764559	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	m16j1q6rkfdpxguuksz7wmpuba		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764576	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	dp4jszrpsjnjpjw1mth4ygithy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764611	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	dp4jszrpsjnjpjw1mth4ygithy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764629	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	udhm7t7fqfgc9k9funqdejmeea		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764663	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	udhm7t7fqfgc9k9funqdejmeea		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764680	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	7e4ojpbykjntdmpu94y5ekub1c		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764716	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	7e4ojpbykjntdmpu94y5ekub1c		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764733	t	f	f	0	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	6a4bti99g3rtdmx11dhnihhg6r		1773126776776	8	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126777663	t	f	f	0	2	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	3bekgg684bb5iq6tfq1h95az3r		1773126777636	19	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126777636	t	f	f	0	4	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	9mbmdxz1kidnmemmqi9ou5w1ah		1773126777482	14	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126777482	t	f	f	0	3	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	46fd55wk57bdzq89debc4cxugr		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126777564	t	f	f	1	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765162	t	f	f	1	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	4zd57afzr3f4mbydt14j5mzqza		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126776525	t	f	f	2	0	0	f
c8sz8dja63nu7ms3jjtyws3ora	m16j1q6rkfdpxguuksz7wmpuba		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763934	t	f	f	0	0	0	f
oqcewxpjqtdgxn91q6ehrqgzdr	m16j1q6rkfdpxguuksz7wmpuba		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763948	t	f	f	0	0	0	f
c8sz8dja63nu7ms3jjtyws3ora	dp4jszrpsjnjpjw1mth4ygithy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763980	t	f	f	0	0	0	f
oqcewxpjqtdgxn91q6ehrqgzdr	dp4jszrpsjnjpjw1mth4ygithy		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126763995	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764159	t	t	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	x916bcascjyyjrc5y8e5hbrgna		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764205	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	x916bcascjyyjrc5y8e5hbrgna		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764222	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	4zd57afzr3f4mbydt14j5mzqza		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764255	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	4zd57afzr3f4mbydt14j5mzqza		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764271	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	46fd55wk57bdzq89debc4cxugr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764305	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	46fd55wk57bdzq89debc4cxugr		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764322	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	6a4bti99g3rtdmx11dhnihhg6r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764356	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	6a4bti99g3rtdmx11dhnihhg6r		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764373	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	ccmjk1p1abffx87a4zni7n4uoh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764406	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	ccmjk1p1abffx87a4zni7n4uoh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764422	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764769	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764786	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	g7r88gtyqjfdzgnwhr9xyumzce		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764823	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	g7r88gtyqjfdzgnwhr9xyumzce		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764840	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764875	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764891	t	f	f	0	0	0	f
ody3wrq1o7rpjpzxsx7sqtdqdo	hacoqz1mijy8db1u95mwsgt6pe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764927	t	f	f	0	0	0	f
nih4d7rfsir4xpi8tidfcunqrr	hacoqz1mijy8db1u95mwsgt6pe		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764945	t	f	f	0	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126764977	t	t	f	0	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765184	t	f	f	1	0	0	f
qk4rrkf1stnn5ydh15bgh16nth	4zd57afzr3f4mbydt14j5mzqza		1773126777779	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126777779	t	f	f	0	1	0	f
qk4rrkf1stnn5ydh15bgh16nth	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765312	t	f	f	1	0	0	f
qk4rrkf1stnn5ydh15bgh16nth	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765334	t	f	f	1	0	0	f
qk4rrkf1stnn5ydh15bgh16nth	9mbmdxz1kidnmemmqi9ou5w1ah		1773126777967	7	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126777967	t	f	f	0	2	0	f
qk4rrkf1stnn5ydh15bgh16nth	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765447	t	f	f	1	0	0	f
qk4rrkf1stnn5ydh15bgh16nth	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765512	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	ccmjk1p1abffx87a4zni7n4uoh		1773126778453	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126778453	t	f	f	0	1	0	f
j443od6puifhjf85mfwk55h8ec	46fd55wk57bdzq89debc4cxugr		1773126778323	11	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126778323	t	f	f	0	3	0	f
j443od6puifhjf85mfwk55h8ec	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765634	t	f	f	1	0	0	f
j443od6puifhjf85mfwk55h8ec	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765662	t	f	f	1	0	0	f
j443od6puifhjf85mfwk55h8ec	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765704	t	f	f	1	0	0	f
j443od6puifhjf85mfwk55h8ec	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765727	t	f	f	1	0	0	f
j443od6puifhjf85mfwk55h8ec	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765748	t	f	f	1	0	0	f
j443od6puifhjf85mfwk55h8ec	3bekgg684bb5iq6tfq1h95az3r		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126778379	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765827	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765870	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765919	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	cxtqjdhuqiydtmdmtdc1mesbfo		1773126778967	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126778967	t	f	f	0	2	0	f
dewd9f48ij85xgq7tfte859qfa	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766005	t	f	f	1	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	x916bcascjyyjrc5y8e5hbrgna		1773126776519	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126776519	t	f	f	0	1	0	f
j443od6puifhjf85mfwk55h8ec	4zd57afzr3f4mbydt14j5mzqza		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126778326	t	f	f	2	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765208	t	f	f	1	0	0	f
xbdo3t9uq7gxmgnk4xopy1pkee	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765230	t	f	f	1	0	0	f
qk4rrkf1stnn5ydh15bgh16nth	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765262	t	t	f	0	0	0	f
qk4rrkf1stnn5ydh15bgh16nth	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765375	t	f	f	1	0	0	f
qk4rrkf1stnn5ydh15bgh16nth	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765425	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	6a4bti99g3rtdmx11dhnihhg6r		1773126779594	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779594	t	f	f	0	2	0	f
qk4rrkf1stnn5ydh15bgh16nth	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765490	t	f	f	1	0	0	f
j443od6puifhjf85mfwk55h8ec	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765521	t	t	f	0	0	0	f
j443od6puifhjf85mfwk55h8ec	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765683	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765780	t	t	f	0	0	0	f
dewd9f48ij85xgq7tfte859qfa	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765849	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765891	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126765983	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766035	t	t	f	0	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766104	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	4zd57afzr3f4mbydt14j5mzqza		1773126779691	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779691	t	f	f	0	1	0	f
bbekt5pgxfnc5qmpwaxux3py1a	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766173	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766194	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766214	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766258	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	3bekgg684bb5iq6tfq1h95az3r		1773126779742	5	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779742	t	f	f	0	5	0	f
wnrktfozbffs7dpb5u86mga3uy	46fd55wk57bdzq89debc4cxugr		1773126779730	4	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779730	t	f	f	0	4	0	f
qk4rrkf1stnn5ydh15bgh16nth	g7r88gtyqjfdzgnwhr9xyumzce		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126777896	t	f	f	1	0	0	f
dewd9f48ij85xgq7tfte859qfa	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766026	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	3bekgg684bb5iq6tfq1h95az3r		1773126779474	1	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779552	t	f	f	0	1	0	f
bbekt5pgxfnc5qmpwaxux3py1a	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766124	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766236	t	f	f	1	0	0	f
bbekt5pgxfnc5qmpwaxux3py1a	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766279	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766288	t	t	f	0	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	4zd57afzr3f4mbydt14j5mzqza		1773126779767	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779767	t	f	f	0	1	0	f
wnrktfozbffs7dpb5u86mga3uy	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766431	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766494	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766516	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766537	t	f	f	1	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766596	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	46fd55wk57bdzq89debc4cxugr		1773126780069	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780069	t	f	f	0	1	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	g7r88gtyqjfdzgnwhr9xyumzce		1773126779959	7	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779959	t	f	f	0	2	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766657	t	f	f	1	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766685	t	f	f	1	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766706	t	f	f	1	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766727	t	f	f	1	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	46fd55wk57bdzq89debc4cxugr		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779985	t	f	f	1	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766771	t	f	f	1	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766792	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766850	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	6a4bti99g3rtdmx11dhnihhg6r		1773126779706	2	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779706	t	f	f	0	2	0	f
7ijgcabphifx7mwe9g6w9paemy	dp4jszrpsjnjpjw1mth4ygithy		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780654	t	f	f	2	0	0	f
rmsexzhn3jgy7f4kbgnczsa3sa	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766547	t	t	f	0	0	0	f
et85fk3eqpgrip4z9eydcg4weo	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766802	t	t	f	0	0	0	f
et85fk3eqpgrip4z9eydcg4weo	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766894	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766915	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766964	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767042	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767064	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767073	t	t	f	0	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767215	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767323	t	f	f	1	0	0	f
scj33w14etykfdaydd3cqcae5w	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767381	t	f	f	1	0	0	f
7ijgcabphifx7mwe9g6w9paemy	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767485	t	t	f	0	0	0	f
7ijgcabphifx7mwe9g6w9paemy	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767583	t	f	f	1	0	0	f
7ijgcabphifx7mwe9g6w9paemy	m16j1q6rkfdpxguuksz7wmpuba		1773126780648	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780648	t	f	f	0	1	0	f
qiiq57tw6jbru8zhkytut8i64e	7e4ojpbykjntdmpu94y5ekub1c		1773126780759	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780759	t	f	f	0	1	0	f
4rt4rx5mt38b38y9ec93k89boo	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767783	t	t	f	0	0	0	f
4rt4rx5mt38b38y9ec93k89boo	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767830	t	f	f	1	0	0	f
4rt4rx5mt38b38y9ec93k89boo	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767882	t	f	f	1	0	0	f
3zf3d5jjnfymug7cq1ucdwqrmo	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767985	t	f	f	1	0	0	f
3zf3d5jjnfymug7cq1ucdwqrmo	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768031	t	f	f	1	0	0	f
3zf3d5jjnfymug7cq1ucdwqrmo	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768052	t	f	f	1	0	0	f
wnrktfozbffs7dpb5u86mga3uy	ccmjk1p1abffx87a4zni7n4uoh		1773126779718	3	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779718	t	f	f	0	3	0	f
et85fk3eqpgrip4z9eydcg4weo	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766942	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126766986	t	f	f	1	0	0	f
et85fk3eqpgrip4z9eydcg4weo	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767021	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767123	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767145	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767165	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767186	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767236	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767259	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767302	t	f	f	1	0	0	f
scj33w14etykfdaydd3cqcae5w	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767332	t	t	f	0	0	0	f
scj33w14etykfdaydd3cqcae5w	93n7axewi7n9xpsis8z5d99bre		1773126780499	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780499	t	f	f	0	2	0	f
scj33w14etykfdaydd3cqcae5w	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767431	t	f	f	1	0	0	f
scj33w14etykfdaydd3cqcae5w	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767453	t	f	f	1	0	0	f
scj33w14etykfdaydd3cqcae5w	m16j1q6rkfdpxguuksz7wmpuba		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767476	t	f	f	1	0	0	f
7ijgcabphifx7mwe9g6w9paemy	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767533	t	f	f	1	0	0	f
7ijgcabphifx7mwe9g6w9paemy	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767561	t	f	f	1	0	0	f
qiiq57tw6jbru8zhkytut8i64e	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767634	t	t	f	0	0	0	f
qiiq57tw6jbru8zhkytut8i64e	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767709	t	f	f	1	0	0	f
qiiq57tw6jbru8zhkytut8i64e	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767731	t	f	f	1	0	0	f
qiiq57tw6jbru8zhkytut8i64e	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767753	t	f	f	1	0	0	f
qiiq57tw6jbru8zhkytut8i64e	m16j1q6rkfdpxguuksz7wmpuba		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767773	t	f	f	1	0	0	f
mjjwsjpbnt8rxyp7n5mt1f3syw	g7r88gtyqjfdzgnwhr9xyumzce		1773126780203	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780203	t	f	f	0	1	0	f
4rt4rx5mt38b38y9ec93k89boo	m16j1q6rkfdpxguuksz7wmpuba		1773126780875	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780875	t	f	f	0	1	0	f
4rt4rx5mt38b38y9ec93k89boo	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767906	t	f	f	1	0	0	f
3zf3d5jjnfymug7cq1ucdwqrmo	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126767937	t	t	f	0	0	0	f
3zf3d5jjnfymug7cq1ucdwqrmo	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768011	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768081	t	t	f	0	0	0	f
5b4hke3753y73feti3hhtfbgiy	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768148	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768170	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768190	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768212	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768239	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768281	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768365	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	udhm7t7fqfgc9k9funqdejmeea		1773126781324	7	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126781324	t	f	f	0	2	0	f
1s9nagudoiboirmb7ckj1mukfy	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768486	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768530	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	46fd55wk57bdzq89debc4cxugr		1773126781995	12	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126781995	t	f	f	0	3	0	f
1s9nagudoiboirmb7ckj1mukfy	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768573	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768599	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768662	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768683	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768725	t	f	f	1	0	0	f
4rt4rx5mt38b38y9ec93k89boo	93n7axewi7n9xpsis8z5d99bre		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780882	t	f	f	2	0	0	f
1s9nagudoiboirmb7ckj1mukfy	6a4bti99g3rtdmx11dhnihhg6r		1773126781672	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126781672	t	f	f	0	1	0	f
5b4hke3753y73feti3hhtfbgiy	x916bcascjyyjrc5y8e5hbrgna		1773126781529	13	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126781529	t	f	f	0	3	0	f
5b4hke3753y73feti3hhtfbgiy	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768128	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768260	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768303	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768324	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768344	t	f	f	1	0	0	f
5b4hke3753y73feti3hhtfbgiy	m16j1q6rkfdpxguuksz7wmpuba		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768387	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	m16j1q6rkfdpxguuksz7wmpuba		1773126781817	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126781817	t	f	f	0	2	0	f
1s9nagudoiboirmb7ckj1mukfy	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768438	t	t	f	0	0	0	f
1s9nagudoiboirmb7ckj1mukfy	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768620	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768641	t	f	f	1	0	0	f
1s9nagudoiboirmb7ckj1mukfy	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768704	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	dp4jszrpsjnjpjw1mth4ygithy		1773126782132	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782132	t	f	f	0	1	0	f
1s9nagudoiboirmb7ckj1mukfy	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768790	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768799	t	t	f	0	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768931	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769019	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769060	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	m16j1q6rkfdpxguuksz7wmpuba		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769101	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769143	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769152	t	t	f	0	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769282	t	f	f	1	0	0	f
3zf3d5jjnfymug7cq1ucdwqrmo	m16j1q6rkfdpxguuksz7wmpuba		1773126780980	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126780980	t	f	f	0	1	0	f
1s9nagudoiboirmb7ckj1mukfy	udhm7t7fqfgc9k9funqdejmeea		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768769	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768846	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768868	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768889	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768909	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768960	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768980	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126768999	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769081	t	f	f	1	0	0	f
8k1ahz7c8pgmjyco414pgi5f4y	udhm7t7fqfgc9k9funqdejmeea		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769121	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769200	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769220	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769240	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769261	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769309	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769330	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769415	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769435	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	cxtqjdhuqiydtmdmtdc1mesbfo		1773126782526	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782526	t	f	f	0	1	0	f
i14jg6ym6tbfmpa93dq5usgrty	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769508	t	t	f	0	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769578	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769599	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	udhm7t7fqfgc9k9funqdejmeea		1773126782274	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782274	t	f	f	0	1	0	f
7aqugqd4dprbzcfcnm8ouuqczc	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769352	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769373	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769394	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	m16j1q6rkfdpxguuksz7wmpuba		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769456	t	f	f	1	0	0	f
7aqugqd4dprbzcfcnm8ouuqczc	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769499	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769558	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769620	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769640	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	udhm7t7fqfgc9k9funqdejmeea		1773126782742	1	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782742	t	f	f	0	1	0	f
i14jg6ym6tbfmpa93dq5usgrty	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769689	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769709	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769752	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769773	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	93n7axewi7n9xpsis8z5d99bre		1773126782654	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782654	t	f	f	0	2	0	f
i14jg6ym6tbfmpa93dq5usgrty	m16j1q6rkfdpxguuksz7wmpuba		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769816	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	udhm7t7fqfgc9k9funqdejmeea		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769836	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	3bekgg684bb5iq6tfq1h95az3r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769915	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	46fd55wk57bdzq89debc4cxugr		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769937	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	7e4ojpbykjntdmpu94y5ekub1c		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769999	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	9mbmdxz1kidnmemmqi9ou5w1ah		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770048	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	hacoqz1mijy8db1u95mwsgt6pe		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770155	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	m16j1q6rkfdpxguuksz7wmpuba		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770177	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	hacoqz1mijy8db1u95mwsgt6pe		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782604	t	f	f	1	0	0	f
i14jg6ym6tbfmpa93dq5usgrty	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769858	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	7kq76ce63id48nkz4hcp5rg3xh		0	0	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769867	t	t	f	0	0	0	f
h4d4ekghxin7bnutsuomgd776w	4zd57afzr3f4mbydt14j5mzqza		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769958	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	6a4bti99g3rtdmx11dhnihhg6r		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126769978	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	93n7axewi7n9xpsis8z5d99bre		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770026	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	ccmjk1p1abffx87a4zni7n4uoh		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770069	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	cxtqjdhuqiydtmdmtdc1mesbfo		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770091	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	dp4jszrpsjnjpjw1mth4ygithy		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770112	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	g7r88gtyqjfdzgnwhr9xyumzce		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770133	t	f	f	1	0	0	f
h4d4ekghxin7bnutsuomgd776w	x916bcascjyyjrc5y8e5hbrgna		0	0	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126770220	t	f	f	1	0	0	f
j443od6puifhjf85mfwk55h8ec	x916bcascjyyjrc5y8e5hbrgna		0	0	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126778326	t	f	f	2	0	0	f
wnrktfozbffs7dpb5u86mga3uy	cxtqjdhuqiydtmdmtdc1mesbfo		1773126779755	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126779755	t	f	f	0	6	0	f
ik8xxjatdfn75comxgxnq189iw	93n7axewi7n9xpsis8z5d99bre		1773126783028	4	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783028	t	f	f	0	4	0	f
5swgwrkocprjmrngo4qj4o74io	x916bcascjyyjrc5y8e5hbrgna		1773126782952	3	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782965	t	f	f	1	3	0	f
5swgwrkocprjmrngo4qj4o74io	4zd57afzr3f4mbydt14j5mzqza		1773126782962	4	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126782962	t	f	f	0	4	0	f
ik8xxjatdfn75comxgxnq189iw	9mbmdxz1kidnmemmqi9ou5w1ah		1773126783017	3	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783030	t	f	f	1	3	0	f
ofr41qz4pjdtiyzza51qu7bxny	46fd55wk57bdzq89debc4cxugr		1773126783091	4	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783104	t	f	f	1	4	0	f
ofr41qz4pjdtiyzza51qu7bxny	g7r88gtyqjfdzgnwhr9xyumzce		1773126783102	5	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783102	t	f	f	0	5	0	f
5xxxy5dojj8pmbg441q5og511e	cxtqjdhuqiydtmdmtdc1mesbfo		1773126783167	4	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783181	t	f	f	1	4	0	f
5xxxy5dojj8pmbg441q5og511e	6a4bti99g3rtdmx11dhnihhg6r		1773126783178	5	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783178	t	f	f	0	5	0	f
e4yfhpb1rjbizxy8ygcf3u7w1r	x916bcascjyyjrc5y8e5hbrgna		1773126783242	4	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783255	t	f	f	1	4	0	f
e4yfhpb1rjbizxy8ygcf3u7w1r	udhm7t7fqfgc9k9funqdejmeea		1773126783253	5	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783253	t	f	f	0	5	0	f
qk34pb8dffr4ibk69r3xkzmy9o	3bekgg684bb5iq6tfq1h95az3r		1773126783307	3	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783320	t	f	f	1	3	0	f
qk34pb8dffr4ibk69r3xkzmy9o	ccmjk1p1abffx87a4zni7n4uoh		1773126783318	4	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783318	t	f	f	0	4	0	f
rffhn6t6jbfkiebs9cmahu7gae	4zd57afzr3f4mbydt14j5mzqza		1773126783470	5	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783485	t	f	f	1	5	0	f
rffhn6t6jbfkiebs9cmahu7gae	7kq76ce63id48nkz4hcp5rg3xh		0	0	6	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783485	t	f	f	6	0	0	f
rffhn6t6jbfkiebs9cmahu7gae	x916bcascjyyjrc5y8e5hbrgna		1773126783459	4	2	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783485	t	f	f	2	4	0	f
rffhn6t6jbfkiebs9cmahu7gae	9mbmdxz1kidnmemmqi9ou5w1ah		1773126783482	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783482	t	f	f	0	6	0	f
f3kpgwu4biddpbpyf18nbu6mpe	93n7axewi7n9xpsis8z5d99bre		1773126783653	5	1	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783667	t	f	f	1	5	0	f
f3kpgwu4biddpbpyf18nbu6mpe	7e4ojpbykjntdmpu94y5ekub1c		1773126783665	6	0	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783665	t	f	f	0	6	0	f
f3kpgwu4biddpbpyf18nbu6mpe	7kq76ce63id48nkz4hcp5rg3xh		0	0	6	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783667	t	f	f	6	0	0	f
f3kpgwu4biddpbpyf18nbu6mpe	dp4jszrpsjnjpjw1mth4ygithy		1773126783600	3	3	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783667	t	f	f	3	3	0	f
f3kpgwu4biddpbpyf18nbu6mpe	m16j1q6rkfdpxguuksz7wmpuba		1773126783576	2	4	{"push": "default", "email": "default", "desktop": "default", "mark_unread": "all", "ignore_channel_mentions": "default", "channel_auto_follow_threads": "off"}	1773126783667	t	f	f	4	2	0	f
\.


--
-- Data for Name: channels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.channels (id, createat, updateat, deleteat, teamid, type, displayname, name, header, purpose, lastpostat, totalmsgcount, extraupdateat, creatorid, schemeid, groupconstrained, shared, totalmsgcountroot, lastrootpostat, bannerinfo, defaultcategoryname, autotranslation) FROM stdin;
c8sz8dja63nu7ms3jjtyws3ora	1773126763810	1773126763810	0	s8e39snm5tnbxbgpeia5kpwzuo	O	Town Square	town-square			1773126764087	0	0		\N	\N	\N	0	1773126764087	\N		f
oqcewxpjqtdgxn91q6ehrqgzdr	1773126763813	1773126763813	0	s8e39snm5tnbxbgpeia5kpwzuo	O	Off-Topic	off-topic			1773126764104	0	0		\N	\N	\N	0	1773126764104	\N		f
3zf3d5jjnfymug7cq1ucdwqrmo	1773126767933	1773126767933	0	s8e39snm5tnbxbgpeia5kpwzuo	O	Design Requests	design-requests	Use the pinned template for new requests | SLA: 3 business days	Submit and track design requests	1773126781082	5	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126780980	\N		f
ody3wrq1o7rpjpzxsx7sqtdqdo	1773126764123	1773126764123	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	Town Square	town-square			1773126764935	0	0		\N	\N	\N	0	1773126764935	\N		f
nih4d7rfsir4xpi8tidfcunqrr	1773126764127	1773126764127	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	Off-Topic	off-topic			1773126764952	0	0		\N	\N	\N	0	1773126764952	\N		f
j443od6puifhjf85mfwk55h8ec	1773126765518	1773126765518	0	tufgabb37pdmzfspeitber78oa	O	Deployments	deployments	Check #runbooks before deploying | On-call: Bob Wilson	Deployment coordination and status updates	1773126778415	14	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	3	1773126778323	\N		f
1s9nagudoiboirmb7ckj1mukfy	1773126768435	1773126768435	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	Random	random	Keep it friendly and respectful!	Non-work banter and fun stuff	1773126782101	16	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	3	1773126781995	\N		f
dewd9f48ij85xgq7tfte859qfa	1773126765776	1773126765776	0	tufgabb37pdmzfspeitber78oa	O	Code Reviews	code-reviews	Please include PR link and brief description when requesting reviews	Request and discuss code reviews	1773126779447	9	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	2	1773126778967	\N		f
qiiq57tw6jbru8zhkytut8i64e	1773126767630	1773126767630	0	s8e39snm5tnbxbgpeia5kpwzuo	O	Analytics	analytics	Weekly report due every Friday by 3pm	Marketing analytics and reporting	1773126780837	4	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126780759	\N		f
7ijgcabphifx7mwe9g6w9paemy	1773126767482	1773126767482	0	s8e39snm5tnbxbgpeia5kpwzuo	O	Social Media	social-media	Posting schedule: Mon/Wed/Fri | Tools: Hootsuite, Canva	Social media strategy and content planning	1773126780727	4	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126780648	\N		f
scj33w14etykfdaydd3cqcae5w	1773126767329	1773126767329	0	s8e39snm5tnbxbgpeia5kpwzuo	O	Campaigns	campaigns	Q1 Campaign: 'Innovate Together' | Budget: $50K	Plan and track marketing campaigns	1773126780611	10	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	2	1773126780499	\N		f
qk4rrkf1stnn5ydh15bgh16nth	1773126765259	1773126765259	0	tufgabb37pdmzfspeitber78oa	O	Project Beta	project-beta	Project Beta | Planning Phase | Lead: Jane Smith	Internal dashboard redesign project	1773126778022	9	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	2	1773126777967	\N		f
jy91zp8mu7yk5gb5hy9qhdcfeh	1773126763192	1773126763192	0	tufgabb37pdmzfspeitber78oa	O	Town Square	town-square			1773126763776	0	0		\N	\N	\N	0	1773126763776	\N		f
q9g6zsqkfty78mguucajfoqcir	1773126763197	1773126763197	0	tufgabb37pdmzfspeitber78oa	O	Off-Topic	off-topic			1773126763792	0	0		\N	\N	\N	0	1773126763792	\N		f
rmsexzhn3jgy7f4kbgnczsa3sa	1773126766543	1773126766543	0	tufgabb37pdmzfspeitber78oa	O	Tech Discussions	tech-discussions	Share interesting articles, discuss tech trends, and propose RFCs	Technical discussions, architecture decisions, and knowledge sharing	1773126780036	10	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	2	1773126779959	\N		f
wnrktfozbffs7dpb5u86mga3uy	1773126766284	1773126766284	0	tufgabb37pdmzfspeitber78oa	O	Standup Notes	standup-notes	Format: Yesterday | Today | Blockers	Daily standup updates from the engineering team	1773126779755	6	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	6	1773126779755	\N		f
et85fk3eqpgrip4z9eydcg4weo	1773126766798	1773126766798	0	tufgabb37pdmzfspeitber78oa	O	DevOps	devops	AWS Status: Green | K8s Cluster: Healthy	Infrastructure, CI/CD, and operations	1773126780175	5	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126780069	\N		f
bbekt5pgxfnc5qmpwaxux3py1a	1773126766032	1773126766032	0	tufgabb37pdmzfspeitber78oa	O	Bugs and Issues	bugs-and-issues	Use format: [PROJECT] Brief description | Priority: High/Med/Low	Report and track bugs across all projects	1773126779668	9	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	2	1773126779594	\N		f
mjjwsjpbnt8rxyp7n5mt1f3syw	1773126767069	1773126767069	0	tufgabb37pdmzfspeitber78oa	P	Security Alerts	security-alerts	CONFIDENTIAL - Do not share outside this channel	Security vulnerabilities and incident reports	1773126780317	5	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126780203	\N		f
4rt4rx5mt38b38y9ec93k89boo	1773126767779	1773126767779	0	s8e39snm5tnbxbgpeia5kpwzuo	O	Content Calendar	content-calendar	Next blog post due: March 15 | Author: Frank Miller	Blog posts, newsletters, and content scheduling	1773126780953	4	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126780875	\N		f
i14jg6ym6tbfmpa93dq5usgrty	1773126769505	1773126769505	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	Help Desk	help-desk	For urgent issues, contact IT at ext. 5555	IT support and general help requests	1773126782720	9	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	2	1773126782654	\N		f
5b4hke3753y73feti3hhtfbgiy	1773126768078	1773126768078	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	Announcements	announcements	Only managers and above can post here	Company-wide announcements and news	1773126781636	17	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	3	1773126781529	\N		f
8k1ahz7c8pgmjyco414pgi5f4y	1773126768795	1773126768795	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	Water Cooler	watercooler	What's everyone watching this weekend?	Casual conversations and team bonding	1773126782243	5	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126782132	\N		f
7aqugqd4dprbzcfcnm8ouuqczc	1773126769148	1773126769148	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	Events	events	Next event: Team Lunch - March 20 at Bella Italia	Company events, team outings, and celebrations	1773126782517	7	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126782274	\N		f
xbdo3t9uq7gxmgnk4xopy1pkee	1773126764972	1773126764972	0	tufgabb37pdmzfspeitber78oa	O	Project Alpha	project-alpha	Project Alpha | Sprint 12 | Release: March 30	Discussion and updates for Project Alpha - our new customer portal	1773126777747	23	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	4	1773126777636	\N		f
5swgwrkocprjmrngo4qj4o74io	1773126782906	1773126782906	0		D		4zd57afzr3f4mbydt14j5mzqza__x916bcascjyyjrc5y8e5hbrgna			1773126782962	4	0	x916bcascjyyjrc5y8e5hbrgna	\N	\N	f	4	1773126782962	\N		f
qk34pb8dffr4ibk69r3xkzmy9o	1773126783264	1773126783264	0		D		3bekgg684bb5iq6tfq1h95az3r__ccmjk1p1abffx87a4zni7n4uoh			1773126783318	4	0	3bekgg684bb5iq6tfq1h95az3r	\N	\N	f	4	1773126783318	\N		f
ik8xxjatdfn75comxgxnq189iw	1773126782974	1773126782974	0		D		93n7axewi7n9xpsis8z5d99bre__9mbmdxz1kidnmemmqi9ou5w1ah			1773126783028	4	0	9mbmdxz1kidnmemmqi9ou5w1ah	\N	\N	f	4	1773126783028	\N		f
ofr41qz4pjdtiyzza51qu7bxny	1773126783039	1773126783039	0		D		46fd55wk57bdzq89debc4cxugr__g7r88gtyqjfdzgnwhr9xyumzce			1773126783102	5	0	46fd55wk57bdzq89debc4cxugr	\N	\N	f	5	1773126783102	\N		f
rffhn6t6jbfkiebs9cmahu7gae	1773126783330	1773126783330	0		G	admin, jane.smith, john.doe, kevin.martinez	b29057c84f852748be174f8787c5b240c46449ea			1773126783482	6	0		\N	\N	f	6	1773126783482	\N		f
h4d4ekghxin7bnutsuomgd776w	1773126769864	1773126769864	0	dehiwb8q9bnoi8f4mxzsh8dayr	O	New Joiners	new-joiners	Welcome to TechCorp! Check pinned posts for onboarding guide	Welcome new team members and onboarding info	1773126782897	5	0	7kq76ce63id48nkz4hcp5rg3xh	\N	\N	\N	1	1773126782742	\N		f
5xxxy5dojj8pmbg441q5og511e	1773126783114	1773126783114	0		D		6a4bti99g3rtdmx11dhnihhg6r__cxtqjdhuqiydtmdmtdc1mesbfo			1773126783178	5	0	6a4bti99g3rtdmx11dhnihhg6r	\N	\N	f	5	1773126783178	\N		f
f3kpgwu4biddpbpyf18nbu6mpe	1773126783495	1773126783495	0		G	admin, emma.davis, frank.miller, grace.lee, ivy.chen	dd68759a1d56710ebcc6ae5667000c2503880ed3			1773126783665	6	0		\N	\N	f	6	1773126783665	\N		f
e4yfhpb1rjbizxy8ygcf3u7w1r	1773126783190	1773126783190	0		D		udhm7t7fqfgc9k9funqdejmeea__x916bcascjyyjrc5y8e5hbrgna			1773126783253	5	0	udhm7t7fqfgc9k9funqdejmeea	\N	\N	f	5	1773126783253	\N		f
\.


--
-- Data for Name: clusterdiscovery; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.clusterdiscovery (id, type, clustername, hostname, gossipport, port, createat, lastpingat) FROM stdin;
\.


--
-- Data for Name: commands; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.commands (id, token, createat, updateat, deleteat, creatorid, teamid, trigger, method, username, iconurl, autocomplete, autocompletedesc, autocompletehint, displayname, description, url, pluginid) FROM stdin;
\.


--
-- Data for Name: commandwebhooks; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.commandwebhooks (id, createat, commandid, userid, channelid, rootid, usecount) FROM stdin;
\.


--
-- Data for Name: compliances; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.compliances (id, createat, userid, status, count, "desc", type, startat, endat, keywords, emails) FROM stdin;
\.


--
-- Data for Name: contentflaggingcommonreviewers; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.contentflaggingcommonreviewers (userid) FROM stdin;
\.


--
-- Data for Name: contentflaggingteamreviewers; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.contentflaggingteamreviewers (teamid, userid) FROM stdin;
\.


--
-- Data for Name: contentflaggingteamsettings; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.contentflaggingteamsettings (teamid, enabled) FROM stdin;
\.


--
-- Data for Name: db_lock; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.db_lock (id, expireat) FROM stdin;
\.


--
-- Data for Name: db_migrations; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.db_migrations (version, name) FROM stdin;
1	create_teams
2	create_team_members
3	create_cluster_discovery
4	create_command_webhooks
5	create_compliances
6	create_emojis
7	create_user_groups
8	create_group_members
9	create_group_teams
10	create_group_channels
11	create_link_metadata
12	create_commands
13	create_incoming_webhooks
14	create_outgoing_webhooks
15	create_systems
16	create_reactions
17	create_roles
18	create_schemes
19	create_licenses
20	create_posts
21	create_product_notice_view_state
22	create_sessions
23	create_terms_of_service
24	create_audits
25	create_oauth_access_data
26	create_preferences
27	create_status
28	create_tokens
29	create_bots
30	create_user_access_tokens
31	create_remote_clusters
32	create_sharedchannels
33	create_sidebar_channels
34	create_oauthauthdata
35	create_sharedchannelattachments
36	create_sharedchannelusers
37	create_sharedchannelremotes
38	create_jobs
39	create_channel_member_history
40	create_sidebar_categories
41	create_upload_sessions
42	create_threads
43	thread_memberships
44	create_user_terms_of_service
45	create_plugin_key_value_store
46	create_users
47	create_file_info
48	create_oauth_apps
49	create_channels
50	create_channelmembers
51	create_msg_root_count
52	create_public_channels
53	create_retention_policies
54	create_crt_channelmembership_count
55	create_crt_thread_count_and_unreads
56	upgrade_channels_v6.0
57	upgrade_command_webhooks_v6.0
58	upgrade_channelmembers_v6.0
59	upgrade_users_v6.0
60	upgrade_jobs_v6.0
61	upgrade_link_metadata_v6.0
62	upgrade_sessions_v6.0
63	upgrade_threads_v6.0
64	upgrade_status_v6.0
65	upgrade_groupchannels_v6.0
66	upgrade_posts_v6.0
67	upgrade_channelmembers_v6.1
68	upgrade_teammembers_v6.1
69	upgrade_jobs_v6.1
70	upgrade_cte_v6.1
71	upgrade_sessions_v6.1
72	upgrade_schemes_v6.3
73	upgrade_plugin_key_value_store_v6.3
74	upgrade_users_v6.3
75	alter_upload_sessions_index
76	upgrade_lastrootpostat
77	upgrade_users_v6.5
78	create_oauth_mattermost_app_id
79	usergroups_displayname_index
80	posts_createat_id
81	threads_deleteat
82	upgrade_oauth_mattermost_app_id
83	threads_threaddeleteat
84	recent_searches
85	fileinfo_add_archived_column
86	add_cloud_limits_archived
87	sidebar_categories_index
88	remaining_migrations
89	add-channelid-to-reaction
90	create_enums
91	create_post_reminder
92	add_createat_to_teamembers
93	notify_admin
94	threads_teamid
95	remove_posts_parentid
96	threads_threadteamid
97	create_posts_priority
98	create_post_acknowledgements
99	create_drafts
100	add_draft_priority_column
101	create_true_up_review_history
102	posts_originalid_index
103	add_sentat_to_notifyadmin
104	upgrade_notifyadmin
105	remove_tokens
106	fileinfo_channelid
107	threadmemberships_cleanup
108	remove_orphaned_oauth_preferences
109	create_persistent_notifications
111	update_vacuuming
112	rework_desktop_tokens
113	create_retentionidsfordeletion_table
114	sharedchannelremotes_drop_nextsyncat_description
115	user_reporting_changes
116	create_outgoing_oauth_connections
117	msteams_shared_channels
118	create_index_poststats
119	msteams_shared_channels_opts
120	create_channelbookmarks_table
121	remove_true_up_review_history
122	preferences_value_length
123	remove_upload_file_permission
124	remove_manage_team_permission
125	remoteclusters_add_default_team_id
126	sharedchannels_remotes_add_deleteat
127	add_mfa_used_ts_to_users
128	create_scheduled_posts
129	add_property_system_architecture
130	system_console_stats
131	create_index_pagination_on_property_values
132	create_index_pagination_on_property_fields
133	add_channel_banner_fields
134	create_access_control_policies
135	sidebarchannels_categoryid
136	create_attribute_view
137	update_attribute_view
138	add_default_category_name_to_channel
139	remoteclusters_add_last_global_user_sync_at
140	add_lastmemberssyncat_to_sharedchannelremotes
141	add_remoteid_channelid_to_post_acknowledgements
142	create_content_flagging_tables
143	content_flagging_table_index
144	add_dcr_fields_to_oauth_apps
145	add_pkce_to_oauthauthdata
146	add_audience_and_resource_to_oauth
147	create_autotranslation_tables
148	add_burn_on_read_messages
149	create_recaps
\.


--
-- Data for Name: db_migrations_calls; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.db_migrations_calls (version, name) FROM stdin;
1	create_calls_channels
2	create_calls
3	create_calls_sessions
4	create_calls_jobs
\.


--
-- Data for Name: desktoptokens; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.desktoptokens (token, createat, userid) FROM stdin;
\.


--
-- Data for Name: drafts; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.drafts (createat, updateat, deleteat, userid, channelid, rootid, message, props, fileids, priority, type) FROM stdin;
\.


--
-- Data for Name: emoji; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.emoji (id, createat, updateat, deleteat, creatorid, name) FROM stdin;
\.


--
-- Data for Name: fileinfo; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.fileinfo (id, creatorid, postid, createat, updateat, deleteat, path, thumbnailpath, previewpath, name, extension, size, mimetype, width, height, haspreviewimage, minipreview, content, remoteid, archived, channelid) FROM stdin;
\.


--
-- Data for Name: groupchannels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.groupchannels (groupid, autoadd, schemeadmin, createat, deleteat, updateat, channelid) FROM stdin;
\.


--
-- Data for Name: groupmembers; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.groupmembers (groupid, userid, createat, deleteat) FROM stdin;
\.


--
-- Data for Name: groupteams; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.groupteams (groupid, autoadd, schemeadmin, createat, deleteat, updateat, teamid) FROM stdin;
\.


--
-- Data for Name: incomingwebhooks; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.incomingwebhooks (id, createat, updateat, deleteat, userid, channelid, teamid, displayname, description, username, iconurl, channellocked) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.jobs (id, type, priority, createat, startat, lastactivityat, status, progress, data) FROM stdin;
3ydb7wj7cbrt7niopasrgdm6sa	delete_dms_preferences_migration	0	1773126729288	1773126747413	1773126748420	success	100	{}
6zsac9jyd7yh5ejhprt9sps4bh	delete_orphan_drafts_migration	0	1773126729286	1773126747413	1773126748420	success	100	{}
ms94cp36hidnzytkok6k1mpx6e	delete_empty_drafts_migration	0	1773126729284	1773126747413	1773126748420	success	100	{}
\.


--
-- Data for Name: licenses; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.licenses (id, createat, bytes) FROM stdin;
\.


--
-- Data for Name: linkmetadata; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.linkmetadata (hash, url, "timestamp", type, data) FROM stdin;
1903005241	https://github.com/techcorp/portal/pull/142	1773126000000	opengraph	{"url": "https://github.com/techcorp/portal/pull/142", "type": "", "title": "Build software better, together", "audios": null, "images": [{"url": "https://github.githubassets.com/assets/github-logo-55c5b9a1fe52.png", "type": "image/png", "width": 1200, "height": 1200, "secure_url": ""}, {"url": "https://github.githubassets.com/assets/github-mark-57519b92ca4e.png", "type": "image/png", "width": 1200, "height": 620, "secure_url": ""}, {"url": "https://github.githubassets.com/assets/github-octocat-13c86b8b336d.png", "type": "image/png", "width": 1200, "height": 620, "secure_url": ""}], "locale": "", "videos": null, "site_name": "GitHub", "determiner": "", "description": "GitHub is where people build software. More than 150 million people use GitHub to discover, fork, and contribute to over 420 million projects.", "locales_alternate": null}
2642609942	https://github.githubassets.com/assets/github-logo-55c5b9a1fe52.png	1773126000000	image	{"width": 1200, "format": "png", "height": 1200, "frame_count": 0}
2485478110	https://github.githubassets.com/assets/github-mark-57519b92ca4e.png	1773126000000	image	{"width": 1200, "format": "png", "height": 630, "frame_count": 0}
2402168838	https://github.githubassets.com/assets/github-octocat-13c86b8b336d.png	1773126000000	image	{"width": 1200, "format": "png", "height": 630, "frame_count": 0}
3947683283	https://github.com/techcorp/api/pull/287	1773126000000	opengraph	{"url": "https://github.com/techcorp/api/pull/287", "type": "", "title": "Build software better, together", "audios": null, "images": [{"url": "https://github.githubassets.com/assets/github-logo-55c5b9a1fe52.png", "type": "image/png", "width": 1200, "height": 1200, "secure_url": ""}, {"url": "https://github.githubassets.com/assets/github-mark-57519b92ca4e.png", "type": "image/png", "width": 1200, "height": 620, "secure_url": ""}, {"url": "https://github.githubassets.com/assets/github-octocat-13c86b8b336d.png", "type": "image/png", "width": 1200, "height": 620, "secure_url": ""}], "locale": "", "videos": null, "site_name": "GitHub", "determiner": "", "description": "GitHub is where people build software. More than 150 million people use GitHub to discover, fork, and contribute to over 420 million projects.", "locales_alternate": null}
1886227534	https://github.com/techcorp/portal/pull/156	1773126000000	opengraph	{"url": "https://github.com/techcorp/portal/pull/156", "type": "", "title": "Build software better, together", "audios": null, "images": [{"url": "https://github.githubassets.com/assets/github-logo-55c5b9a1fe52.png", "type": "image/png", "width": 1200, "height": 1200, "secure_url": ""}, {"url": "https://github.githubassets.com/assets/github-mark-57519b92ca4e.png", "type": "image/png", "width": 1200, "height": 620, "secure_url": ""}, {"url": "https://github.githubassets.com/assets/github-octocat-13c86b8b336d.png", "type": "image/png", "width": 1200, "height": 620, "secure_url": ""}], "locale": "", "videos": null, "site_name": "GitHub", "determiner": "", "description": "GitHub is where people build software. More than 150 million people use GitHub to discover, fork, and contribute to over 420 million projects.", "locales_alternate": null}
3915957730	https://wiki.techcorp.com/dev-setup	1773126000000	none	null
1566875294	https://handbook.techcorp.com	1773126000000	none	null
\.


--
-- Data for Name: llm_postmeta; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.llm_postmeta (rootpostid, title) FROM stdin;
\.


--
-- Data for Name: notifyadmin; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.notifyadmin (userid, createat, requiredplan, requiredfeature, trial, sentat) FROM stdin;
\.


--
-- Data for Name: oauthaccessdata; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.oauthaccessdata (token, refreshtoken, redirecturi, clientid, userid, expiresat, scope, audience) FROM stdin;
\.


--
-- Data for Name: oauthapps; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.oauthapps (id, creatorid, createat, updateat, clientsecret, name, description, callbackurls, homepage, istrusted, iconurl, mattermostappid, isdynamicallyregistered) FROM stdin;
\.


--
-- Data for Name: oauthauthdata; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.oauthauthdata (clientid, userid, code, expiresin, createat, redirecturi, state, scope, codechallenge, codechallengemethod, resource) FROM stdin;
\.


--
-- Data for Name: outgoingoauthconnections; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.outgoingoauthconnections (id, name, creatorid, createat, updateat, clientid, clientsecret, credentialsusername, credentialspassword, oauthtokenurl, granttype, audiences) FROM stdin;
\.


--
-- Data for Name: outgoingwebhooks; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.outgoingwebhooks (id, token, createat, updateat, deleteat, creatorid, channelid, teamid, triggerwords, callbackurls, displayname, contenttype, triggerwhen, username, iconurl, description) FROM stdin;
\.


--
-- Data for Name: persistentnotifications; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.persistentnotifications (postid, createat, lastsentat, deleteat, sentcount) FROM stdin;
\.


--
-- Data for Name: pluginkeyvaluestore; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.pluginkeyvaluestore (pluginid, pkey, pvalue, expireat) FROM stdin;
com.mattermost.calls	mmi_botid	\\x7577396179656f74616a6e6174653637677265716e6d31743677	0
\.


--
-- Data for Name: postacknowledgements; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.postacknowledgements (postid, userid, acknowledgedat, remoteid, channelid) FROM stdin;
\.


--
-- Data for Name: postreminders; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.postreminders (postid, userid, targettime) FROM stdin;
\.


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.posts (id, createat, updateat, deleteat, userid, channelid, rootid, originalid, message, type, props, hashtags, filenames, fileids, hasreactions, editat, ispinned, remoteid) FROM stdin;
xupk4wsko3g98xgk6dhad4djca	1773126763222	1773126763222	0	7kq76ce63id48nkz4hcp5rg3xh	jy91zp8mu7yk5gb5hy9qhdcfeh			admin joined the team.	system_join_team	{"username": "admin"}		[]	[]	f	0	f	\N
d61epujwmpfiinshpsspas7x3e	1773126763250	1773126763250	0	7kq76ce63id48nkz4hcp5rg3xh	q9g6zsqkfty78mguucajfoqcir			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
uexpwgreiib7mdf6zw9gkpgfnr	1773126763295	1773126763295	0	x916bcascjyyjrc5y8e5hbrgna	jy91zp8mu7yk5gb5hy9qhdcfeh			john.doe joined the team.	system_join_team	{"username": "john.doe"}		[]	[]	f	0	f	\N
9ho7xoiqetgtbpmmdfsergm6cr	1773126763318	1773126763318	0	x916bcascjyyjrc5y8e5hbrgna	q9g6zsqkfty78mguucajfoqcir			john.doe joined the channel.	system_join_channel	{"username": "john.doe"}		[]	[]	f	0	f	\N
xifznygfyff89cnbcuuuiaux4h	1773126763364	1773126763364	0	4zd57afzr3f4mbydt14j5mzqza	jy91zp8mu7yk5gb5hy9qhdcfeh			jane.smith joined the team.	system_join_team	{"username": "jane.smith"}		[]	[]	f	0	f	\N
yxqtr8txx38g3ran456mmkppky	1773126763381	1773126763381	0	4zd57afzr3f4mbydt14j5mzqza	q9g6zsqkfty78mguucajfoqcir			jane.smith joined the channel.	system_join_channel	{"username": "jane.smith"}		[]	[]	f	0	f	\N
4kneoou953gxtpxruuij9yj7dc	1773126763416	1773126763416	0	46fd55wk57bdzq89debc4cxugr	jy91zp8mu7yk5gb5hy9qhdcfeh			bob.wilson joined the team.	system_join_team	{"username": "bob.wilson"}		[]	[]	f	0	f	\N
ds8oe6s533rbjgezo794mfyypo	1773126763433	1773126763433	0	46fd55wk57bdzq89debc4cxugr	q9g6zsqkfty78mguucajfoqcir			bob.wilson joined the channel.	system_join_channel	{"username": "bob.wilson"}		[]	[]	f	0	f	\N
tstt5rnpstdiufr9dcz5npnmhw	1773126763468	1773126763468	0	6a4bti99g3rtdmx11dhnihhg6r	jy91zp8mu7yk5gb5hy9qhdcfeh			alice.johnson joined the team.	system_join_team	{"username": "alice.johnson"}		[]	[]	f	0	f	\N
k3z4pbgucjbkum38nqrrh3d89y	1773126763484	1773126763484	0	6a4bti99g3rtdmx11dhnihhg6r	q9g6zsqkfty78mguucajfoqcir			alice.johnson joined the channel.	system_join_channel	{"username": "alice.johnson"}		[]	[]	f	0	f	\N
ybcwui7cypri5qqt394k3ukkar	1773126763519	1773126763519	0	ccmjk1p1abffx87a4zni7n4uoh	jy91zp8mu7yk5gb5hy9qhdcfeh			charlie.brown joined the team.	system_join_team	{"username": "charlie.brown"}		[]	[]	f	0	f	\N
xwcq773bsf8xfe1a3bftw55epa	1773126763536	1773126763536	0	ccmjk1p1abffx87a4zni7n4uoh	q9g6zsqkfty78mguucajfoqcir			charlie.brown joined the channel.	system_join_channel	{"username": "charlie.brown"}		[]	[]	f	0	f	\N
tzmtaxwfq7b6fmypwa11exwb3a	1773126763570	1773126763570	0	3bekgg684bb5iq6tfq1h95az3r	jy91zp8mu7yk5gb5hy9qhdcfeh			diana.prince joined the team.	system_join_team	{"username": "diana.prince"}		[]	[]	f	0	f	\N
c6o56cr8ytdougn4pb1exb1k8y	1773126763587	1773126763587	0	3bekgg684bb5iq6tfq1h95az3r	q9g6zsqkfty78mguucajfoqcir			diana.prince joined the channel.	system_join_channel	{"username": "diana.prince"}		[]	[]	f	0	f	\N
5tyuiqa4qpdwxpz6xztikyxcry	1773126763622	1773126763622	0	9mbmdxz1kidnmemmqi9ou5w1ah	jy91zp8mu7yk5gb5hy9qhdcfeh			kevin.martinez joined the team.	system_join_team	{"username": "kevin.martinez"}		[]	[]	f	0	f	\N
wzjuh5imjireuys1w8mrbm33my	1773126763638	1773126763638	0	9mbmdxz1kidnmemmqi9ou5w1ah	q9g6zsqkfty78mguucajfoqcir			kevin.martinez joined the channel.	system_join_channel	{"username": "kevin.martinez"}		[]	[]	f	0	f	\N
1o15j1az6trypxrakqai7opjqh	1773126763673	1773126763673	0	g7r88gtyqjfdzgnwhr9xyumzce	jy91zp8mu7yk5gb5hy9qhdcfeh			lisa.wang joined the team.	system_join_team	{"username": "lisa.wang"}		[]	[]	f	0	f	\N
jjgj5wob67ygp8f3grjfrenq1e	1773126763690	1773126763690	0	g7r88gtyqjfdzgnwhr9xyumzce	q9g6zsqkfty78mguucajfoqcir			lisa.wang joined the channel.	system_join_channel	{"username": "lisa.wang"}		[]	[]	f	0	f	\N
rbtjk5cy5fyn3pkxw4wrzxqgah	1773126763725	1773126763725	0	cxtqjdhuqiydtmdmtdc1mesbfo	jy91zp8mu7yk5gb5hy9qhdcfeh			mike.ross joined the team.	system_join_team	{"username": "mike.ross"}		[]	[]	f	0	f	\N
rdcwsagh8fgu5yes4txwdjgckh	1773126763743	1773126763743	0	cxtqjdhuqiydtmdmtdc1mesbfo	q9g6zsqkfty78mguucajfoqcir			mike.ross joined the channel.	system_join_channel	{"username": "mike.ross"}		[]	[]	f	0	f	\N
aguk8kq6pi8k5nsny93pqwyrbh	1773126763776	1773126763776	0	hacoqz1mijy8db1u95mwsgt6pe	jy91zp8mu7yk5gb5hy9qhdcfeh			natalie.kim joined the team.	system_join_team	{"username": "natalie.kim"}		[]	[]	f	0	f	\N
kh445smx9pgj7nr6bs31qmp6go	1773126763792	1773126763792	0	hacoqz1mijy8db1u95mwsgt6pe	q9g6zsqkfty78mguucajfoqcir			natalie.kim joined the channel.	system_join_channel	{"username": "natalie.kim"}		[]	[]	f	0	f	\N
3g3ikxx1nif5jmuwcn9fuxiuqy	1773126763836	1773126763836	0	7kq76ce63id48nkz4hcp5rg3xh	c8sz8dja63nu7ms3jjtyws3ora			admin joined the team.	system_join_team	{"username": "admin"}		[]	[]	f	0	f	\N
ife7znf14tyabx7zuen6motprc	1773126763852	1773126763852	0	7kq76ce63id48nkz4hcp5rg3xh	oqcewxpjqtdgxn91q6ehrqgzdr			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
8bgazrbr1fg5fk9zm6nm44sase	1773126763889	1773126763889	0	93n7axewi7n9xpsis8z5d99bre	c8sz8dja63nu7ms3jjtyws3ora			emma.davis joined the team.	system_join_team	{"username": "emma.davis"}		[]	[]	f	0	f	\N
mdn4o86dbb8fpjx1tfti6xzecc	1773126763905	1773126763905	0	93n7axewi7n9xpsis8z5d99bre	oqcewxpjqtdgxn91q6ehrqgzdr			emma.davis joined the channel.	system_join_channel	{"username": "emma.davis"}		[]	[]	f	0	f	\N
6e3eaey1ktd4uckiruz1sozcdc	1773126763940	1773126763940	0	m16j1q6rkfdpxguuksz7wmpuba	c8sz8dja63nu7ms3jjtyws3ora			frank.miller joined the team.	system_join_team	{"username": "frank.miller"}		[]	[]	f	0	f	\N
oja4n967bin8zn89ng9mgn6g3e	1773126763956	1773126763956	0	m16j1q6rkfdpxguuksz7wmpuba	oqcewxpjqtdgxn91q6ehrqgzdr			frank.miller joined the channel.	system_join_channel	{"username": "frank.miller"}		[]	[]	f	0	f	\N
phedncijmf88jf6jx9hcegpf4c	1773126763987	1773126763987	0	dp4jszrpsjnjpjw1mth4ygithy	c8sz8dja63nu7ms3jjtyws3ora			grace.lee joined the team.	system_join_team	{"username": "grace.lee"}		[]	[]	f	0	f	\N
djw3a5bcs7ng5gi3ijiei9m7kw	1773126764002	1773126764002	0	dp4jszrpsjnjpjw1mth4ygithy	oqcewxpjqtdgxn91q6ehrqgzdr			grace.lee joined the channel.	system_join_channel	{"username": "grace.lee"}		[]	[]	f	0	f	\N
ub1igzua8pbxjy49zr3gnjp1fe	1773126764037	1773126764037	0	7e4ojpbykjntdmpu94y5ekub1c	c8sz8dja63nu7ms3jjtyws3ora			ivy.chen joined the team.	system_join_team	{"username": "ivy.chen"}		[]	[]	f	0	f	\N
fuw16i3q9ffoup4gjagbo5tpbc	1773126764054	1773126764054	0	7e4ojpbykjntdmpu94y5ekub1c	oqcewxpjqtdgxn91q6ehrqgzdr			ivy.chen joined the channel.	system_join_channel	{"username": "ivy.chen"}		[]	[]	f	0	f	\N
mfm3mm6njfrytjq8yjmce5zqfe	1773126764087	1773126764087	0	9mbmdxz1kidnmemmqi9ou5w1ah	c8sz8dja63nu7ms3jjtyws3ora			kevin.martinez joined the team.	system_join_team	{"username": "kevin.martinez"}		[]	[]	f	0	f	\N
4kwzath9bibujgu64bgmkso66a	1773126764104	1773126764104	0	9mbmdxz1kidnmemmqi9ou5w1ah	oqcewxpjqtdgxn91q6ehrqgzdr			kevin.martinez joined the channel.	system_join_channel	{"username": "kevin.martinez"}		[]	[]	f	0	f	\N
w65f1smpi7fxxfx83jx3ie4bsa	1773126764150	1773126764150	0	7kq76ce63id48nkz4hcp5rg3xh	ody3wrq1o7rpjpzxsx7sqtdqdo			admin joined the team.	system_join_team	{"username": "admin"}		[]	[]	f	0	f	\N
wdr656gwpb8rfqbm33tywwoyqw	1773126764464	1773126764464	0	3bekgg684bb5iq6tfq1h95az3r	ody3wrq1o7rpjpzxsx7sqtdqdo			diana.prince joined the team.	system_join_team	{"username": "diana.prince"}		[]	[]	f	0	f	\N
jnei1enadfgxj887gwtbobxshy	1773126764480	1773126764480	0	3bekgg684bb5iq6tfq1h95az3r	nih4d7rfsir4xpi8tidfcunqrr			diana.prince joined the channel.	system_join_channel	{"username": "diana.prince"}		[]	[]	f	0	f	\N
uir8xuj4rjfb9kszygyem9nqoy	1773126764515	1773126764515	0	93n7axewi7n9xpsis8z5d99bre	ody3wrq1o7rpjpzxsx7sqtdqdo			emma.davis joined the team.	system_join_team	{"username": "emma.davis"}		[]	[]	f	0	f	\N
ous1ysopstn8xg6jscxkaj43xw	1773126764532	1773126764532	0	93n7axewi7n9xpsis8z5d99bre	nih4d7rfsir4xpi8tidfcunqrr			emma.davis joined the channel.	system_join_channel	{"username": "emma.davis"}		[]	[]	f	0	f	\N
fok3ecina3n1mc311hqbr6hnnw	1773126764566	1773126764566	0	m16j1q6rkfdpxguuksz7wmpuba	ody3wrq1o7rpjpzxsx7sqtdqdo			frank.miller joined the team.	system_join_team	{"username": "frank.miller"}		[]	[]	f	0	f	\N
o1h3he6kqidabbmqrofjk7m7ar	1773126764583	1773126764583	0	m16j1q6rkfdpxguuksz7wmpuba	nih4d7rfsir4xpi8tidfcunqrr			frank.miller joined the channel.	system_join_channel	{"username": "frank.miller"}		[]	[]	f	0	f	\N
md4tduusw7d83ysj4qp5thhwyh	1773126764618	1773126764618	0	dp4jszrpsjnjpjw1mth4ygithy	ody3wrq1o7rpjpzxsx7sqtdqdo			grace.lee joined the team.	system_join_team	{"username": "grace.lee"}		[]	[]	f	0	f	\N
ykgqh85nr7n57bx7fz5omqy47h	1773126764636	1773126764636	0	dp4jszrpsjnjpjw1mth4ygithy	nih4d7rfsir4xpi8tidfcunqrr			grace.lee joined the channel.	system_join_channel	{"username": "grace.lee"}		[]	[]	f	0	f	\N
wps4y6s1oinafmi1t865br71xa	1773126764670	1773126764670	0	udhm7t7fqfgc9k9funqdejmeea	ody3wrq1o7rpjpzxsx7sqtdqdo			henry.taylor joined the team.	system_join_team	{"username": "henry.taylor"}		[]	[]	f	0	f	\N
xrjstwgkdjnstd51n5ap9nf86a	1773126764687	1773126764687	0	udhm7t7fqfgc9k9funqdejmeea	nih4d7rfsir4xpi8tidfcunqrr			henry.taylor joined the channel.	system_join_channel	{"username": "henry.taylor"}		[]	[]	f	0	f	\N
xs3phtsi5pdjtywsn6fk1y1pka	1773126764723	1773126764723	0	7e4ojpbykjntdmpu94y5ekub1c	ody3wrq1o7rpjpzxsx7sqtdqdo			ivy.chen joined the team.	system_join_team	{"username": "ivy.chen"}		[]	[]	f	0	f	\N
mkypwf5myjfomdmbnnejioqbkw	1773126764741	1773126764741	0	7e4ojpbykjntdmpu94y5ekub1c	nih4d7rfsir4xpi8tidfcunqrr			ivy.chen joined the channel.	system_join_channel	{"username": "ivy.chen"}		[]	[]	f	0	f	\N
73egocj61pfrtrgzciujyirwhh	1773126765076	1773126765076	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
me5zms8zdfya38pxec93txu5fw	1773126765157	1773126765157	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
wn3zhkaktpgnzm4gcbtdrjt5qy	1773126765201	1773126765201	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
nfc1wr7a6jgo7gwxwo4di8uqoa	1773126765224	1773126765224	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
ptwyaf1awtbpfcj9ggttfea6fh	1773126765370	1773126765370	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
rk5hhgn7btf3fkeu4uyhy3kstc	1773126765420	1773126765420	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
wpwuyxzwubfozj3qa4tas9dfpa	1773126765462	1773126765462	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
3uehgzmmijft88o5uz597d6e6e	1773126765484	1773126765484	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
tk1jehfekigmtnzjx6qsmcb75y	1773126765677	1773126765677	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
ig8f7cghff8npc77xhapinpgbw	1773126765843	1773126765843	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
f6aebmf6bi8o8x1m9k6s9tzazr	1773126765865	1773126765865	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
73t3mdi897b4iewhbdfb3pejzr	1773126764166	1773126764166	0	7kq76ce63id48nkz4hcp5rg3xh	nih4d7rfsir4xpi8tidfcunqrr			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
95x4jukes7rzxj9f8eshmpq6ya	1773126764213	1773126764213	0	x916bcascjyyjrc5y8e5hbrgna	ody3wrq1o7rpjpzxsx7sqtdqdo			john.doe joined the team.	system_join_team	{"username": "john.doe"}		[]	[]	f	0	f	\N
cta3hmway3ymiyi3popxz3qcsh	1773126764229	1773126764229	0	x916bcascjyyjrc5y8e5hbrgna	nih4d7rfsir4xpi8tidfcunqrr			john.doe joined the channel.	system_join_channel	{"username": "john.doe"}		[]	[]	f	0	f	\N
eja3eoqdk3nj8joj5w5kzkjtso	1773126764263	1773126764263	0	4zd57afzr3f4mbydt14j5mzqza	ody3wrq1o7rpjpzxsx7sqtdqdo			jane.smith joined the team.	system_join_team	{"username": "jane.smith"}		[]	[]	f	0	f	\N
eritfdmcap8h5nrkgmzgrggqor	1773126764279	1773126764279	0	4zd57afzr3f4mbydt14j5mzqza	nih4d7rfsir4xpi8tidfcunqrr			jane.smith joined the channel.	system_join_channel	{"username": "jane.smith"}		[]	[]	f	0	f	\N
o1qftrkw6jnridy11pq4d4g55c	1773126764313	1773126764313	0	46fd55wk57bdzq89debc4cxugr	ody3wrq1o7rpjpzxsx7sqtdqdo			bob.wilson joined the team.	system_join_team	{"username": "bob.wilson"}		[]	[]	f	0	f	\N
i9mr74zrgfrnbgbmu49sh9ebcr	1773126764329	1773126764329	0	46fd55wk57bdzq89debc4cxugr	nih4d7rfsir4xpi8tidfcunqrr			bob.wilson joined the channel.	system_join_channel	{"username": "bob.wilson"}		[]	[]	f	0	f	\N
tgerphzuojr75q7wgzaeyt61ga	1773126764363	1773126764363	0	6a4bti99g3rtdmx11dhnihhg6r	ody3wrq1o7rpjpzxsx7sqtdqdo			alice.johnson joined the team.	system_join_team	{"username": "alice.johnson"}		[]	[]	f	0	f	\N
ifa3nygqk7dizfwn4isamrurqw	1773126764380	1773126764380	0	6a4bti99g3rtdmx11dhnihhg6r	nih4d7rfsir4xpi8tidfcunqrr			alice.johnson joined the channel.	system_join_channel	{"username": "alice.johnson"}		[]	[]	f	0	f	\N
if4i4dnw9pb59mf6cg3ppnsrgh	1773126764413	1773126764413	0	ccmjk1p1abffx87a4zni7n4uoh	ody3wrq1o7rpjpzxsx7sqtdqdo			charlie.brown joined the team.	system_join_team	{"username": "charlie.brown"}		[]	[]	f	0	f	\N
cxqtnjz7rpd3ubwbumcmy8yjeo	1773126764430	1773126764430	0	ccmjk1p1abffx87a4zni7n4uoh	nih4d7rfsir4xpi8tidfcunqrr			charlie.brown joined the channel.	system_join_channel	{"username": "charlie.brown"}		[]	[]	f	0	f	\N
t5dc9ssr1jr19ya6u61pdqo4ra	1773126764776	1773126764776	0	9mbmdxz1kidnmemmqi9ou5w1ah	ody3wrq1o7rpjpzxsx7sqtdqdo			kevin.martinez joined the team.	system_join_team	{"username": "kevin.martinez"}		[]	[]	f	0	f	\N
sayy3khen3gofm7yfkg1fz1dny	1773126764794	1773126764794	0	9mbmdxz1kidnmemmqi9ou5w1ah	nih4d7rfsir4xpi8tidfcunqrr			kevin.martinez joined the channel.	system_join_channel	{"username": "kevin.martinez"}		[]	[]	f	0	f	\N
6y1u1e9ci7rgfpgaxt4k3xb8oo	1773126764830	1773126764830	0	g7r88gtyqjfdzgnwhr9xyumzce	ody3wrq1o7rpjpzxsx7sqtdqdo			lisa.wang joined the team.	system_join_team	{"username": "lisa.wang"}		[]	[]	f	0	f	\N
mtqskxb9kibni8ejiet7ejtbwe	1773126764847	1773126764847	0	g7r88gtyqjfdzgnwhr9xyumzce	nih4d7rfsir4xpi8tidfcunqrr			lisa.wang joined the channel.	system_join_channel	{"username": "lisa.wang"}		[]	[]	f	0	f	\N
1xr4pscwqfyfbgtafaic35rq7y	1773126764882	1773126764882	0	cxtqjdhuqiydtmdmtdc1mesbfo	ody3wrq1o7rpjpzxsx7sqtdqdo			mike.ross joined the team.	system_join_team	{"username": "mike.ross"}		[]	[]	f	0	f	\N
hcceqmmbjjnwufofjycyn731pw	1773126764899	1773126764899	0	cxtqjdhuqiydtmdmtdc1mesbfo	nih4d7rfsir4xpi8tidfcunqrr			mike.ross joined the channel.	system_join_channel	{"username": "mike.ross"}		[]	[]	f	0	f	\N
whbzpq4o8fgupqij49qfbgofja	1773126764935	1773126764935	0	hacoqz1mijy8db1u95mwsgt6pe	ody3wrq1o7rpjpzxsx7sqtdqdo			natalie.kim joined the team.	system_join_team	{"username": "natalie.kim"}		[]	[]	f	0	f	\N
y77wcabdnf8yide7azn9tqfnjy	1773126764952	1773126764952	0	hacoqz1mijy8db1u95mwsgt6pe	nih4d7rfsir4xpi8tidfcunqrr			natalie.kim joined the channel.	system_join_channel	{"username": "natalie.kim"}		[]	[]	f	0	f	\N
dk87ja3dxj8tunz9iqog784ikh	1773126764985	1773126764985	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
4qj48o7rpbd3fk98oyn6dqat3r	1773126765023	1773126765023	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
k79ygi4rpp8oicpg13kt41ia8h	1773126765046	1773126765046	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
4td4qahhr7dcipku8eoris75tr	1773126765104	1773126765104	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
aohi7yf5a7fo7nag4a1wj3591c	1773126765134	1773126765134	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
qy56xhk3pjd9mbu1qi6468ug4e	1773126765179	1773126765179	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
b1aenimwajyz3gsgyuic4y4i1a	1773126765247	1773126765247	0	7kq76ce63id48nkz4hcp5rg3xh	xbdo3t9uq7gxmgnk4xopy1pkee			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
xcurfesz47npbmke1me48tf1ty	1773126765270	1773126765270	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
xiegyyewkbb9mcfgmu7m8xkz8y	1773126765308	1773126765308	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
n5ux1gbygigtt8gmuygbyw3wec	1773126765329	1773126765329	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
e7q434eg83do7f3ughjsoheqya	1773126765349	1773126765349	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
rpn45cwj9bbr9p1ynj5owe65to	1773126765398	1773126765398	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
3rzzzo1utfrofk91fm4hpw55oa	1773126765441	1773126765441	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
6hy4m9jiebnoipkht1hqaqri1y	1773126765506	1773126765506	0	7kq76ce63id48nkz4hcp5rg3xh	qk4rrkf1stnn5ydh15bgh16nth			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
kmayqz6rnibauc9c43diwedprc	1773126765529	1773126765529	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
py6hurpihjnz9r4q1hyei5enyo	1773126765565	1773126765565	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
zsoidf31zjrxjr366mdigb6rxw	1773126765587	1773126765587	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
y3yu1oabe3ddm8jzajupe634uh	1773126765608	1773126765608	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
pg7jjs1jwpnbjkf44enrdnzw7h	1773126765630	1773126765630	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
ym73wnphxfygzr9k4f5efy35ay	1773126765657	1773126765657	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
yjr8sahkujrktj75fdubd4d9wy	1773126765699	1773126765699	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
4n8x1p6r43dqf89hbuk5ptcnoe	1773126765721	1773126765721	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
re8s98g6o3gj58q9u8auabp86a	1773126765743	1773126765743	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
796dgmu1htgd9p6on9bzwx98pe	1773126765765	1773126765765	0	7kq76ce63id48nkz4hcp5rg3xh	j443od6puifhjf85mfwk55h8ec			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
wccit4pbep8q9c5g3z5w1fogjy	1773126765787	1773126765787	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
jhpjry3fzb8uxehdwhoj155mye	1773126765822	1773126765822	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
bxw55dn9tpry9dg9sjuzrqbt1c	1773126765914	1773126765914	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
ht3reu1spt8oxpnt7j8xedjwqr	1773126765935	1773126765935	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
pw7cib41w7d4fgjaaydghoy33a	1773126765957	1773126765957	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
ipumpiqh9ifp8m4ras1am3chdy	1773126765999	1773126765999	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
9sfrktn96bdr7es635bkjg5f3e	1773126776669	1773126776669	0	ccmjk1p1abffx87a4zni7n4uoh	xbdo3t9uq7gxmgnk4xopy1pkee	fd51e1ms8fbfubjycuye8mairh		For the backend, should we use JWT or session-based auth? I'd recommend JWT with refresh tokens for the API.		{}		[]	[]	f	0	f	
aw1o3s4gr7fy8e6y3i4bznwrsr	1773126765886	1773126765886	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
mhozifo4x78r3dneqd54t4ciyy	1773126765977	1773126765977	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
67sjzzhgx7ggdyipdskzzrp5bc	1773126766099	1773126766099	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
rofuypm4z3rhiq3t6i3oodrgdh	1773126766140	1773126766140	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
x5ui9hmyqjfxmgmafk3f7p5zur	1773126766167	1773126766167	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
sut85xubztftzewm7bwctwenrw	1773126766188	1773126766188	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
h3rund3zeigrtnrt9neuwfokpw	1773126766209	1773126766209	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
b9kptb7hotfufynn5tswxtbwdo	1773126766252	1773126766252	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
r8gm9jciobdgpeng5jw7s7fnow	1773126766273	1773126766273	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
bt4e7dhb13rjbpzxs9icrscafh	1773126766295	1773126766295	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
jqt8nt9f5jdctxqqs4e6thmg9c	1773126766331	1773126766331	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
mi8pqfz3wifdbjce3wd9fs6jkw	1773126766356	1773126766356	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
rfp9jc37ijynmrr7bicz5tuj3h	1773126766377	1773126766377	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
1a445on6dj8jxq95p5679xdtdr	1773126766447	1773126766447	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
mf1c86b9giymjf7kngdxn8ts9e	1773126766467	1773126766467	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
tyucwfw49ff5pdb6gmk666n3hr	1773126766888	1773126766888	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
g974kf7897f6dgr658iij5xajy	1773126766910	1773126766910	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
cca1mg4pw7yu9e4kccf7bbpnih	1773126766958	1773126766958	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
kb9sx7cs4pgnirnj9ou9mmhu4e	1773126767036	1773126767036	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
embbqk7u77b3bdxpbm657m8yiw	1773126767058	1773126767058	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
9hjmgs5gf7d9zf7trhjdmz4qtw	1773126767160	1773126767160	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
hwy85iy6zfy8xngdfkm657yrpy	1773126766020	1773126766020	0	7kq76ce63id48nkz4hcp5rg3xh	dewd9f48ij85xgq7tfte859qfa			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
igwck77q6fg7xjnydkody5g18y	1773126766042	1773126766042	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
chdhafdf77gdzku5en4t6em31e	1773126766078	1773126766078	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
tjqgjgg363gg9bffajxbdxeyuo	1773126766120	1773126766120	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
dgyx1yeexjgxfmro75yq6x5yjy	1773126766231	1773126766231	0	7kq76ce63id48nkz4hcp5rg3xh	bbekt5pgxfnc5qmpwaxux3py1a			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
885bhg9wz7gfuy86b58r4abfba	1773126766398	1773126766398	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
jxukce9ctins883wyaqgtene7c	1773126766426	1773126766426	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
ukpqhn3r1fbricbqk1ucbd9mpc	1773126766488	1773126766488	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
i87uopio57gi5piho71tdygt5h	1773126766510	1773126766510	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
kye1jondwt8fpfz45mxfi64xor	1773126766531	1773126766531	0	7kq76ce63id48nkz4hcp5rg3xh	wnrktfozbffs7dpb5u86mga3uy			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
jay9deucrfg7pxr14xpzayjewe	1773126766555	1773126766555	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
ojapfgp9nfd7bq6momjm9pwyje	1773126766591	1773126766591	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
kksx89xtcfdf3gqzft3dx87psr	1773126766611	1773126766611	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
7r68xfhrp3gh5fj1xwkf1sbnah	1773126766632	1773126766632	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
pjtwf9bdyfyejczei5kxpz3fbh	1773126766652	1773126766652	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
1181t34zziro3kgnh9hrwmdqne	1773126766680	1773126766680	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
3rihujozhpne988eoi9px5dzay	1773126766700	1773126766700	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
13khs1c4afb17fmgh5kwuzp8bo	1773126766721	1773126766721	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
nufhimuw1pyxdgoq3933945f6a	1773126766743	1773126766743	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
zgnwmxmhxjywx8ywemc4zhy7hc	1773126766765	1773126766765	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
6fuw9mub37ro5p5e34szqqxtao	1773126766787	1773126766787	0	7kq76ce63id48nkz4hcp5rg3xh	rmsexzhn3jgy7f4kbgnczsa3sa			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
b76ehk9c6jy538n14pc71gjo5c	1773126766809	1773126766809	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
5zoywydeuidrjbhrsetoywy8oo	1773126766845	1773126766845	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
ppmwuc9ecpyrxbeu7oyhe51ite	1773126766867	1773126766867	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
8n7cnh8oajb3drs5eg3fktys1o	1773126766937	1773126766937	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
bkmntdxhb7bdxxy4p7p84k5shc	1773126766980	1773126766980	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
g83w88xxk3ra8rcnhe4wiwgdbc	1773126767015	1773126767015	0	7kq76ce63id48nkz4hcp5rg3xh	et85fk3eqpgrip4z9eydcg4weo			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
zm4ei8ahp7rppfhy8o3xz64e3c	1773126767081	1773126767081	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
4sjy8cs5zjb79nqdzuygzzcrrw	1773126767118	1773126767118	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
d1y1s6raapnj3koyreahpkkwue	1773126767140	1773126767140	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
3hahsouk8in9xeo5qfymx4ix4a	1773126767181	1773126767181	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
sj66zmabkfrw98yg9ifm5p44rc	1773126767231	1773126767231	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
jusp4iywrid7pep63citftsgzo	1773126767254	1773126767254	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
65tsowrjgj8nx8xr9714um78mo	1773126767276	1773126767276	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
d885gqn8zbfdjybbim776kzeuo	1773126767297	1773126767297	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
gbysyucsbjrtjphmz3qk8nwprw	1773126767405	1773126767405	0	7kq76ce63id48nkz4hcp5rg3xh	scj33w14etykfdaydd3cqcae5w			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
8m14xoukotgstbsripi1s6897h	1773126767426	1773126767426	0	7kq76ce63id48nkz4hcp5rg3xh	scj33w14etykfdaydd3cqcae5w			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
e7q1a7neg7gppn7c3i4r351t5y	1773126767448	1773126767448	0	7kq76ce63id48nkz4hcp5rg3xh	scj33w14etykfdaydd3cqcae5w			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
ra7jrfhmb3fhddqthcy8f7shaa	1773126767471	1773126767471	0	7kq76ce63id48nkz4hcp5rg3xh	scj33w14etykfdaydd3cqcae5w			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
9qx8ecd5i7gpzdooefg4e6r9wr	1773126767492	1773126767492	0	7kq76ce63id48nkz4hcp5rg3xh	7ijgcabphifx7mwe9g6w9paemy			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
x4feasjjtig38xhtbwf4ebyhbc	1773126767528	1773126767528	0	7kq76ce63id48nkz4hcp5rg3xh	7ijgcabphifx7mwe9g6w9paemy			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
omit8b517frxtncbhehb11o1mr	1773126767557	1773126767557	0	7kq76ce63id48nkz4hcp5rg3xh	7ijgcabphifx7mwe9g6w9paemy			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
xxh38oa1yj8e3q54zp1g7gca3c	1773126767705	1773126767705	0	7kq76ce63id48nkz4hcp5rg3xh	qiiq57tw6jbru8zhkytut8i64e			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
us33h7bwsbbx3dgs8zqct1nzjc	1773126780088	1773126780088	0	x916bcascjyyjrc5y8e5hbrgna	et85fk3eqpgrip4z9eydcg4weo	bfyx5zu8k7b45mkmhe4ex4srwc		Good report. The p99 spike - was that related to the 3-min outage?		{}		[]	[]	f	0	f	
eraccoe63jbhudsc47qe1zq85h	1773126767209	1773126767209	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
tp3s5pfpmpbw3ka7wgji1z7xxe	1773126767318	1773126767318	0	7kq76ce63id48nkz4hcp5rg3xh	mjjwsjpbnt8rxyp7n5mt1f3syw			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
8nbt715h3jfwx8k1hrkrg6pmea	1773126767339	1773126767339	0	7kq76ce63id48nkz4hcp5rg3xh	scj33w14etykfdaydd3cqcae5w			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
63adug4f5fyopnhfixhp6zxhqr	1773126767376	1773126767376	0	7kq76ce63id48nkz4hcp5rg3xh	scj33w14etykfdaydd3cqcae5w			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
w48mu7qx6fd9imebz67jqm8ydc	1773126767577	1773126767577	0	7kq76ce63id48nkz4hcp5rg3xh	7ijgcabphifx7mwe9g6w9paemy			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
shso3xd4htn1bnknw75ycm6sfo	1773126767598	1773126767598	0	7kq76ce63id48nkz4hcp5rg3xh	7ijgcabphifx7mwe9g6w9paemy			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
oufuygaiwtr7xjjag5mpj7eakr	1773126767619	1773126767619	0	7kq76ce63id48nkz4hcp5rg3xh	7ijgcabphifx7mwe9g6w9paemy			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
419r4bt3cff63xagdwozbdpieo	1773126767641	1773126767641	0	7kq76ce63id48nkz4hcp5rg3xh	qiiq57tw6jbru8zhkytut8i64e			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
datguy4btiyi8j7r1iaxccoz1r	1773126767677	1773126767677	0	7kq76ce63id48nkz4hcp5rg3xh	qiiq57tw6jbru8zhkytut8i64e			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
76ndzwbfqfggpdjdkn6qsbfymh	1773126767877	1773126767877	0	7kq76ce63id48nkz4hcp5rg3xh	4rt4rx5mt38b38y9ec93k89boo			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
8pyepan35pnhjnq9fohm1trfra	1773126767944	1773126767944	0	7kq76ce63id48nkz4hcp5rg3xh	3zf3d5jjnfymug7cq1ucdwqrmo			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
3kpnjf1g33ndpd95jgmr7nrnzr	1773126767979	1773126767979	0	7kq76ce63id48nkz4hcp5rg3xh	3zf3d5jjnfymug7cq1ucdwqrmo			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
7oztzoiqwjyrxx3rp453d5tupw	1773126768026	1773126768026	0	7kq76ce63id48nkz4hcp5rg3xh	3zf3d5jjnfymug7cq1ucdwqrmo			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
7zqowj4p7jrwugxqssajis94qr	1773126768046	1773126768046	0	7kq76ce63id48nkz4hcp5rg3xh	3zf3d5jjnfymug7cq1ucdwqrmo			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
t1cucjw63fdpbb5fm511f4npeh	1773126768067	1773126768067	0	7kq76ce63id48nkz4hcp5rg3xh	3zf3d5jjnfymug7cq1ucdwqrmo			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
idm4kz7prjfgzyihbuamzc6rde	1773126768088	1773126768088	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
inzc9uc4gbdw9g797ok1n1c8dy	1773126768123	1773126768123	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
bpnudp15effemfa9a8o495tudo	1773126768254	1773126768254	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
b8gdsbjaz3gy7pr6h5gnes5s1e	1773126768297	1773126768297	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
syahk61h33rypn1mnkx1y3ypda	1773126768318	1773126768318	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
m4mrx13i6pdydq3sg9xjb69s3a	1773126768339	1773126768339	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
ntpnkk5dyjnrxjjis8ihg5i9ne	1773126768380	1773126768380	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
d57ofjb9wtykir7ek39bn45pna	1773126767726	1773126767726	0	7kq76ce63id48nkz4hcp5rg3xh	qiiq57tw6jbru8zhkytut8i64e			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
euiqhgfsobnapx7nzonsiqcp3h	1773126767748	1773126767748	0	7kq76ce63id48nkz4hcp5rg3xh	qiiq57tw6jbru8zhkytut8i64e			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
4knabuxtk7r7mbmtuuj6xcyach	1773126767769	1773126767769	0	7kq76ce63id48nkz4hcp5rg3xh	qiiq57tw6jbru8zhkytut8i64e			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
6w8ffudne3bn8fq8fk9qmnk8xo	1773126767789	1773126767789	0	7kq76ce63id48nkz4hcp5rg3xh	4rt4rx5mt38b38y9ec93k89boo			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
ygqfehw1c7yatkp1ocikpzzdfo	1773126767825	1773126767825	0	7kq76ce63id48nkz4hcp5rg3xh	4rt4rx5mt38b38y9ec93k89boo			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
5ttrz9i7op833dr8aesz74cfuo	1773126767854	1773126767854	0	7kq76ce63id48nkz4hcp5rg3xh	4rt4rx5mt38b38y9ec93k89boo			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
1sidwn9q4frjzxn4htu1ejuhch	1773126767900	1773126767900	0	7kq76ce63id48nkz4hcp5rg3xh	4rt4rx5mt38b38y9ec93k89boo			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
gc5ectm6epddjkebr6ts9yjr9y	1773126767922	1773126767922	0	7kq76ce63id48nkz4hcp5rg3xh	4rt4rx5mt38b38y9ec93k89boo			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
rx8pwwo8d7nsmd4bpeb79e7p1c	1773126768006	1773126768006	0	7kq76ce63id48nkz4hcp5rg3xh	3zf3d5jjnfymug7cq1ucdwqrmo			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
hs4wcgwpx38k3ppd191t84nonr	1773126768144	1773126768144	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
m6q61okdpjgwfbshtrsuriojkc	1773126768165	1773126768165	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
mqn7mety7fn7tk9kyocd7u7tfc	1773126768185	1773126768185	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
za6shy468fbj5j88sprrr7j48a	1773126768206	1773126768206	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
mxhtf3e7j7dm7xdk31gw8zitby	1773126768234	1773126768234	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
mywwmn1ztt8e5fuqjy9whiwf7a	1773126768276	1773126768276	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
fho5yj71rpgn7c16waaqna5dsr	1773126768360	1773126768360	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
nd8crfb3zpri5fw14zmuh1nr3c	1773126768403	1773126768403	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			henry.taylor added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "udhm7t7fqfgc9k9funqdejmeea", "addedUsername": "henry.taylor"}		[]	[]	f	0	f	\N
jhh8xk6y47nz8k7tidytrgptpc	1773126768445	1773126768445	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
t7tbgh48rpgz9rdiekq3ewhmho	1773126768481	1773126768481	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
rqqbm3fuxbdkmgf7j4qdonkr1e	1773126768504	1773126768504	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
9izspe5a8pdztfdnf7mffj6f7c	1773126768525	1773126768525	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
zuhjiobhmjytpfg85g5uynqqry	1773126782952	1773126782952	0	x916bcascjyyjrc5y8e5hbrgna	5swgwrkocprjmrngo4qj4o74io			You've earned it. The promotion committee meets next week. I'll submit my recommendation today. Keep up the great work!		{}		[]	[]	f	0	f	
sq3r7mtg63n37nn47xhbqok5zc	1773126768423	1773126768423	0	7kq76ce63id48nkz4hcp5rg3xh	5b4hke3753y73feti3hhtfbgiy			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
mku4479aj78z3ny87bed5usa1a	1773126768614	1773126768614	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
ous6xxjjkb88pbc6zrkin7e61a	1773126768635	1773126768635	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
gmur6k4cgfyd8pm8ytrx8n113r	1773126768698	1773126768698	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
zbssocibbbyydmay8sehrt6sya	1773126768741	1773126768741	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
imwbgfp1ptbn9qqcjyu9rck8hc	1773126768784	1773126768784	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
yykn9iohwpfsxq5ipn6zh8tutc	1773126768925	1773126768925	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
sjkf4isfsigi3c3s3g4p7mdxrh	1773126769014	1773126769014	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
y3s6jxxsijfzzfz6qbmmbo4cba	1773126769034	1773126769034	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
jxgfet5xgbns5bnhxj8emh3bse	1773126769054	1773126769054	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
gkqargpaubyk3mxda917z3nugw	1773126769095	1773126769095	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
49hqus3yzino7xb31ra3kuca3e	1773126769137	1773126769137	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
c3c3ozse3ida7n5dex31otyhxr	1773126769277	1773126769277	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
1w3qa67m4jb4dxpjmco7wquxfr	1773126769324	1773126769324	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
rkm1ngsnwjbtzequchxei3mxqr	1773126769346	1773126769346	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
a6xmjq5x7bdpdj9ppc96eo5psa	1773126769367	1773126769367	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
65yigj6t7ffm7ewaf66awf17fe	1773126769388	1773126769388	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
nfrg31knh7repgpbh1hwqicg7w	1773126769450	1773126769450	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
7rwdkc3kb7gbtfzjzynaty63mh	1773126769493	1773126769493	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
sks91fhzt7gxbfjnz8yf88h9ow	1773126769516	1773126769516	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
zaf94npzabn55n63xfdwe8o1ke	1773126769553	1773126769553	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
radwzyf3qbgepr6u3r1pzkixtw	1773126768546	1773126768546	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
1a5szaw1mbyd5bpddabnszy6yw	1773126768567	1773126768567	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
ui43bq5nmfr6jgpb5xmpcaeito	1773126768594	1773126768594	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
oij5omrr9injtnseizugo7iqrr	1773126768656	1773126768656	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
mgcyiutcofbqzxyktpsnz9yz3r	1773126768677	1773126768677	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
zt45d6d3gj8j7gqc4gxytndafr	1773126768719	1773126768719	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
ay93jrihw3yz7dcpa6rn74w64o	1773126768763	1773126768763	0	7kq76ce63id48nkz4hcp5rg3xh	1s9nagudoiboirmb7ckj1mukfy			henry.taylor added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "udhm7t7fqfgc9k9funqdejmeea", "addedUsername": "henry.taylor"}		[]	[]	f	0	f	\N
i75qfqkteb84pm58w4oefdnj7e	1773126768806	1773126768806	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
bo67smfth3dcudcjexykopmogy	1773126768841	1773126768841	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
dbedh7hhmfdgxnr78qogw3eukc	1773126768862	1773126768862	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
j13q9pzxh7g9t8eyacfnxdya8o	1773126768884	1773126768884	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
5rtxb5ypxi8x9m537jcymdk53c	1773126768904	1773126768904	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
weqwfxzniff6ixn6ga9m4knihw	1773126768955	1773126768955	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
x7prp3s9n7yimbj6fzuqaba58h	1773126768975	1773126768975	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
ehxrdfwjcbdei8tr8h59pjs9ch	1773126768994	1773126768994	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
wf64ahm897n97kk41n6q4y3p6a	1773126769075	1773126769075	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
5ejx6i1ff3rnfxzrjsa95j4egr	1773126769116	1773126769116	0	7kq76ce63id48nkz4hcp5rg3xh	8k1ahz7c8pgmjyco414pgi5f4y			henry.taylor added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "udhm7t7fqfgc9k9funqdejmeea", "addedUsername": "henry.taylor"}		[]	[]	f	0	f	\N
aeukugdutt8qxjgsa4bqk8bhme	1773126769159	1773126769159	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
4p9wq7u9ntdt8xrtgzbp4566uy	1773126769195	1773126769195	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
x9fodjb5kpdginuqfexf5jcede	1773126769215	1773126769215	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
iher56t67fykip1qw9z6xx73za	1773126769235	1773126769235	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
m8ywkf97qffnt8he1f84c453by	1773126783017	1773126783017	0	9mbmdxz1kidnmemmqi9ou5w1ah	ik8xxjatdfn75comxgxnq189iw			Absolutely. I want to increase the Q2 budget to $75K based on these results. Can you put together a revised plan by Friday?		{}		[]	[]	f	0	f	
diekxzhep3fyx8b9sk5mu4bu6o	1773126769256	1773126769256	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
w4b6jhhzebdz7x1afhhxtm8yoy	1773126769304	1773126769304	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
3s57m51b93do7ey4xm61u5w4qr	1773126769409	1773126769409	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
5bk3jz5erfn1bgkdjdnzh5onac	1773126769429	1773126769429	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
3577xamasfg3ig6ts8d7pows6o	1773126769472	1773126769472	0	7kq76ce63id48nkz4hcp5rg3xh	7aqugqd4dprbzcfcnm8ouuqczc			henry.taylor added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "udhm7t7fqfgc9k9funqdejmeea", "addedUsername": "henry.taylor"}		[]	[]	f	0	f	\N
gjfziicest8j3mgkugfixcj61h	1773126769573	1773126769573	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
t58pcqaiw7gh3ee91jm79c7ofe	1773126769594	1773126769594	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
ofiftwgw3irf3rzbewxb6r3kmo	1773126769851	1773126769851	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
qr6iird35tgs3fz4sm3s46gb9e	1773126769952	1773126769952	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			jane.smith added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "4zd57afzr3f4mbydt14j5mzqza", "addedUsername": "jane.smith"}		[]	[]	f	0	f	\N
e8adn415qjyn9f5k7yk3fyn4jh	1773126769973	1773126769973	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
tqysdkbnptf4um71afobo468zy	1773126770021	1773126770021	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
zu8wraxeiibjtrcm4dwms3bmir	1773126770064	1773126770064	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
y3z11bie7jgji85kaxyykezgao	1773126770085	1773126770085	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
4cujo9nkxpn15ewrndqupyxe8y	1773126770106	1773126770106	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
aq9odb6mgjnjjrqw5m16zrxmsa	1773126770128	1773126770128	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
nmkt8pnouirjzn1cd46oq9jioc	1773126776705	1773126776705	0	4zd57afzr3f4mbydt14j5mzqza	xbdo3t9uq7gxmgnk4xopy1pkee	fd51e1ms8fbfubjycuye8mairh		JWT with refresh tokens sounds good. Let's set access token expiry to 15 minutes and refresh token to 7 days.		{}		[]	[]	f	0	f	
d7h7zfa94jbtmyipqx9gy5mfco	1773126777351	1773126777351	0	cxtqjdhuqiydtmdmtdc1mesbfo	xbdo3t9uq7gxmgnk4xopy1pkee	smhfusfpcirhbgq9js6gwybwsh		I can work on the chart widgets if you need help. I've been working with Recharts and it integrates nicely with our stack.		{}		[]	[]	f	0	f	
uto6fr5grjgxxmzhn6zsqtcdfo	1773126777450	1773126777450	0	6a4bti99g3rtdmx11dhnihhg6r	xbdo3t9uq7gxmgnk4xopy1pkee	smhfusfpcirhbgq9js6gwybwsh		RTL for unit tests, Cypress for the E2E flows. Let's discuss in standup tomorrow.		{}		[]	[]	f	0	f	
kpns3ktfqfrrujt4d7sxmsroko	1773126777497	1773126777497	0	ccmjk1p1abffx87a4zni7n4uoh	xbdo3t9uq7gxmgnk4xopy1pkee	5oezr9ccrbncuxdhtxuhjo6pho		We'll need WebSocket support for real-time notifications. I can set up a Socket.io server alongside our REST API.		{}		[]	[]	f	0	f	
iknbw8xaj7fsfg6iti1g68skro	1773126777653	1773126777653	0	x916bcascjyyjrc5y8e5hbrgna	xbdo3t9uq7gxmgnk4xopy1pkee	cm7g4nhuyjbq9fr1furyz7emph		Thanks Diana. The Safari issue is P1. @alice.johnson can you look into this today?		{}		[]	[]	f	0	f	
hxf8iqc1kj8hdnabas7yjewhor	1773126769614	1773126769614	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			alice.johnson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "6a4bti99g3rtdmx11dhnihhg6r", "addedUsername": "alice.johnson"}		[]	[]	f	0	f	\N
quo3izpj3jrqmr37omw85merqa	1773126769635	1773126769635	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
a6kxqb4tc7nq8phuhbyhh55k9e	1773126769662	1773126769662	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			emma.davis added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "93n7axewi7n9xpsis8z5d99bre", "addedUsername": "emma.davis"}		[]	[]	f	0	f	\N
9sozkr8msfyftd5g58xi5k9eec	1773126769683	1773126769683	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
aa7uu7ieo7rnindgxhtt44ztoh	1773126769704	1773126769704	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			charlie.brown added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "ccmjk1p1abffx87a4zni7n4uoh", "addedUsername": "charlie.brown"}		[]	[]	f	0	f	\N
bh4moazidffrupkhouy5gn1u1o	1773126769725	1773126769725	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			mike.ross added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "cxtqjdhuqiydtmdmtdc1mesbfo", "addedUsername": "mike.ross"}		[]	[]	f	0	f	\N
csqpr9e93fre8gqsszo351qamc	1773126769746	1773126769746	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			grace.lee added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "dp4jszrpsjnjpjw1mth4ygithy", "addedUsername": "grace.lee"}		[]	[]	f	0	f	\N
fndfmqkmj3nh9xsk9gb1cbrf4o	1773126769768	1773126769768	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			lisa.wang added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "g7r88gtyqjfdzgnwhr9xyumzce", "addedUsername": "lisa.wang"}		[]	[]	f	0	f	\N
s9kqac6o5i8p3nqnsu19d8qmha	1773126769789	1773126769789	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
obcg41hkqpf75xht11wpm588jy	1773126769810	1773126769810	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
swxstm158jbwpqjxgtch9qhcba	1773126769830	1773126769830	0	7kq76ce63id48nkz4hcp5rg3xh	i14jg6ym6tbfmpa93dq5usgrty			henry.taylor added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "udhm7t7fqfgc9k9funqdejmeea", "addedUsername": "henry.taylor"}		[]	[]	f	0	f	\N
swm6ur5fn3r5zk8zh9tttjodbw	1773126769875	1773126769875	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			admin joined the channel.	system_join_channel	{"username": "admin"}		[]	[]	f	0	f	\N
hshcgkssk7nn5ge5xqjk7cxkbe	1773126769910	1773126769910	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			diana.prince added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "3bekgg684bb5iq6tfq1h95az3r", "addedUsername": "diana.prince"}		[]	[]	f	0	f	\N
c74qrt47efgxtqimt66csf6a5h	1773126769931	1773126769931	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			bob.wilson added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "46fd55wk57bdzq89debc4cxugr", "addedUsername": "bob.wilson"}		[]	[]	f	0	f	\N
x5iotxpsgfgh9xnccf4uhq6zte	1773126769993	1773126769993	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			ivy.chen added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "7e4ojpbykjntdmpu94y5ekub1c", "addedUsername": "ivy.chen"}		[]	[]	f	0	f	\N
fdfiac599tgcdf4aqn78z13dry	1773126770042	1773126770042	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			kevin.martinez added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "9mbmdxz1kidnmemmqi9ou5w1ah", "addedUsername": "kevin.martinez"}		[]	[]	f	0	f	\N
odfofo6pfpbk9d63krqe1dkepy	1773126770150	1773126770150	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			natalie.kim added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "hacoqz1mijy8db1u95mwsgt6pe", "addedUsername": "natalie.kim"}		[]	[]	f	0	f	\N
fdkwnrwy93ycxcx6mttzxeky7c	1773126770171	1773126770171	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			frank.miller added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "m16j1q6rkfdpxguuksz7wmpuba", "addedUsername": "frank.miller"}		[]	[]	f	0	f	\N
37iboutej383umcjj4zmrygpgy	1773126770192	1773126770192	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			henry.taylor added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "udhm7t7fqfgc9k9funqdejmeea", "addedUsername": "henry.taylor"}		[]	[]	f	0	f	\N
esws4oc96tgub8qei8kujozmty	1773126770214	1773126770214	0	7kq76ce63id48nkz4hcp5rg3xh	h4d4ekghxin7bnutsuomgd776w			john.doe added to the channel by admin.	system_add_to_channel	{"userId": "7kq76ce63id48nkz4hcp5rg3xh", "username": "admin", "addedUserId": "x916bcascjyyjrc5y8e5hbrgna", "addedUsername": "john.doe"}		[]	[]	f	0	f	\N
ephfrwgmypn1dga7uo6o73wgwy	1773126776597	1773126776597	0	6a4bti99g3rtdmx11dhnihhg6r	xbdo3t9uq7gxmgnk4xopy1pkee	fd51e1ms8fbfubjycuye8mairh		I can handle the frontend components for the login/signup pages. Should I use the new design system components?		{}		[]	[]	f	0	f	
56xiczr6ufdgujka4rurk1iaph	1773126776559	1773126776559	0	4zd57afzr3f4mbydt14j5mzqza	xbdo3t9uq7gxmgnk4xopy1pkee	fd51e1ms8fbfubjycuye8mairh		Sure John! I've been looking into OAuth 2.0 with PKCE flow. I think we should support both Google and GitHub SSO along with email/password.		{}		[]	[]	f	0	f	
5wt4bzqoapbb8d986tohk1a69w	1773126776636	1773126776636	0	x916bcascjyyjrc5y8e5hbrgna	xbdo3t9uq7gxmgnk4xopy1pkee	fd51e1ms8fbfubjycuye8mairh		Yes, use the new design system. @grace.lee already finalized the auth page mockups.		{}		[]	[]	f	0	f	
suwnzum7ppn5tbeag1ga6k1r7w	1773126776742	1773126776742	0	9mbmdxz1kidnmemmqi9ou5w1ah	xbdo3t9uq7gxmgnk4xopy1pkee	fd51e1ms8fbfubjycuye8mairh		Just a heads up - the customer demo is scheduled for March 28. We need the auth flow working end-to-end by March 25 at the latest.		{}		[]	[]	f	0	f	
fd51e1ms8fbfubjycuye8mairh	1773126776519	1773126776742	0	x916bcascjyyjrc5y8e5hbrgna	xbdo3t9uq7gxmgnk4xopy1pkee			Team, I want to kick off the Sprint 12 planning for Project Alpha. We need to finalize the customer portal authentication flow and the dashboard widgets. @jane.smith can you take the lead on the auth module?		{}		[]	[]	f	0	f	
ffba6jnqe7nk7nwcuahjtbcipr	1773126777414	1773126777414	0	3bekgg684bb5iq6tfq1h95az3r	xbdo3t9uq7gxmgnk4xopy1pkee	smhfusfpcirhbgq9js6gwybwsh		I'll start writing test cases for the dashboard components. Should I use React Testing Library or Cypress for this?		{}		[]	[]	f	0	f	
sibhbpry5jgxtys5od11kojq9c	1773126777524	1773126777524	0	4zd57afzr3f4mbydt14j5mzqza	xbdo3t9uq7gxmgnk4xopy1pkee	5oezr9ccrbncuxdhtxuhjo6pho		Let's also add a notification preferences page so users can choose which alerts they want. Email, in-app, or both.		{}		[]	[]	f	0	f	
awws37kx8trsfbewqagotgzxew	1773126777684	1773126777684	0	6a4bti99g3rtdmx11dhnihhg6r	xbdo3t9uq7gxmgnk4xopy1pkee	cm7g4nhuyjbq9fr1furyz7emph		On it. I think it's related to the autofill event handler. Safari handles it differently from Chrome/Firefox.		{}		[]	[]	f	0	f	
i1so6ggaqid5mpcz7ep7wgmdww	1773126777889	1773126777889	0	x916bcascjyyjrc5y8e5hbrgna	qk4rrkf1stnn5ydh15bgh16nth	oq4um7bawtd48fr4tfchj6zkce		Looks solid. Let's schedule an architecture review meeting for Friday. I want @lisa.wang to review the security aspects too.		{}		[]	[]	f	0	f	
oq4um7bawtd48fr4tfchj6zkce	1773126777779	1773126777930	0	4zd57afzr3f4mbydt14j5mzqza	qk4rrkf1stnn5ydh15bgh16nth			Starting the architecture planning for Project Beta (Internal Dashboard Redesign). Here's my proposal:\n\n**Tech Stack:**\n- Frontend: Next.js 14 with App Router\n- State Management: Zustand\n- UI: Tailwind CSS + Radix UI\n- Charts: D3.js for custom visualizations\n- API: tRPC for type-safe API calls\n\nThoughts?		{}		[]	[]	f	0	f	
u9b7ehb3kbnz5dkohhn3s6rt9y	1773126777967	1773126778022	0	9mbmdxz1kidnmemmqi9ou5w1ah	qk4rrkf1stnn5ydh15bgh16nth			Here are the key metrics we need to display on the new internal dashboard:\n\n1. **Sales Metrics:** Revenue, orders, avg order value, conversion rate\n2. **User Metrics:** DAU, MAU, retention, churn rate\n3. **System Health:** API latency, error rate, uptime\n4. **Support Metrics:** Open tickets, avg response time, CSAT score\n\nEach section should be a separate dashboard page with drill-down capabilities.		{}		[]	[]	f	0	f	
9upnak7pjfyjzn3j17o8iy7bzo	1773126778069	1773126778069	0	4zd57afzr3f4mbydt14j5mzqza	j443od6puifhjf85mfwk55h8ec	uargsrccatrg5j17n9r7tq5ube		Acknowledged. I'll monitor the error rates during the deployment.		{}		[]	[]	f	0	f	
cfs4bsmsjibf8b8zotfia1wqpa	1773126778126	1773126778126	0	46fd55wk57bdzq89debc4cxugr	j443od6puifhjf85mfwk55h8ec	uargsrccatrg5j17n9r7tq5ube		Let's keep it at 100 for now and monitor. We can adjust without redeploying since it reads from the ConfigMap.		{}		[]	[]	f	0	f	
xo3z7e6dy3859ks1eaywm89nxa	1773126778191	1773126778191	0	46fd55wk57bdzq89debc4cxugr	j443od6puifhjf85mfwk55h8ec	uargsrccatrg5j17n9r7tq5ube		:white_check_mark: Deployment complete! All health checks passing. Monitoring for the next hour.		{}		[]	[]	f	0	f	
7fm86ot5ipdszcxnsxkxjbga1r	1773126778339	1773126778339	0	4zd57afzr3f4mbydt14j5mzqza	j443od6puifhjf85mfwk55h8ec	zs7apgtgpfn3bnxr9cxznwjpry		Auth Service v1.8.0 is ready. All tests passing. I'll do the deployment Monday morning.		{}		[]	[]	f	0	f	
zs7apgtgpfn3bnxr9cxznwjpry	1773126778323	1773126778415	0	46fd55wk57bdzq89debc4cxugr	j443od6puifhjf85mfwk55h8ec			**Weekly Deployment Schedule (March 10-14):**\n\n| Day | Service | Version | Owner |\n|---|---|---|---|\n| Mon | Auth Service | v1.8.0 | Jane |\n| Tue | Payment Gateway | v3.2.1 | Charlie |\n| Wed | No deployments (Change Freeze) | - | - |\n| Thu | Frontend Bundle | v5.1.0 | Alice |\n| Fri | No deployments (End of week) | - | - |\n\nAll deployments require at least 1 approval from @john.doe or @jane.smith.		{}		[]	[]	f	0	f	
rrdusfgbf3gf7qrahwjai64wuw	1773126778880	1773126778880	0	ccmjk1p1abffx87a4zni7n4uoh	dewd9f48ij85xgq7tfte859qfa	rtdewtn5ein8uqwxqjq71jkiqh		Max 3 retries, starting at 1s, ceiling at 8s. So: 1s, 2s, 4s then fail.		{}		[]	[]	f	0	f	
8aszoweqztnrib6brw1mjhgc1o	1773126779387	1773126779387	0	6a4bti99g3rtdmx11dhnihhg6r	dewd9f48ij85xgq7tfte859qfa	zj6hkh4ttpfazbhyrsz79ncedw		Welcome to the review process Mike! I'll take a look. One thing I noticed quickly - you should use our `useTheme()` hook for the color palette instead of hardcoded values.		{}		[]	[]	f	0	f	
dtm34z6fcidc7y8sswpcbkymmw	1773126779447	1773126779447	0	cxtqjdhuqiydtmdmtdc1mesbfo	dewd9f48ij85xgq7tfte859qfa	zj6hkh4ttpfazbhyrsz79ncedw		Thanks for the feedback! I'll address all comments and push an update today.		{}		[]	[]	f	0	f	
zj6hkh4ttpfazbhyrsz79ncedw	1773126778967	1773126779447	0	cxtqjdhuqiydtmdmtdc1mesbfo	dewd9f48ij85xgq7tfte859qfa			My first PR! :tada: Added the user activity heatmap component for the dashboard.\n\nhttps://github.com/techcorp/portal/pull/156\n\nUsed D3.js for the calendar heatmap visualization. Would appreciate thorough feedback since I'm still learning our codebase.		{}		[]	[]	f	0	f	
d1exfgh3m7bxxmjtjhgj9phe3a	1773126779491	1773126779491	0	ccmjk1p1abffx87a4zni7n4uoh	bbekt5pgxfnc5qmpwaxux3py1a	urspsr5koirhbfi6ekpezr18hh		Found it. There's a floating point issue in the discount calculation. `price * (1 - discount/100)` becomes `price * 0` when discount is stored as an integer. Fixing now.		{}		[]	[]	f	0	f	
jzatzsxbjigbfeoadkd47adqbo	1773126779570	1773126779570	0	3bekgg684bb5iq6tfq1h95az3r	bbekt5pgxfnc5qmpwaxux3py1a	urspsr5koirhbfi6ekpezr18hh		:white_check_mark: Verified! All 5 test cases pass now. Marking as resolved.		{}		[]	[]	f	0	f	
rfz56tr14fb4mfun7jg55nhpgo	1773126779642	1773126779642	0	cxtqjdhuqiydtmdmtdc1mesbfo	bbekt5pgxfnc5qmpwaxux3py1a	s38d45f3u3yuj8t8auhrmdgtor		I can help with this! I worked on a similar image loading solution at my previous job. Want me to pair on it?		{}		[]	[]	f	0	f	
3d8anecuktd8xcj5syf3e6yqsr	1773126777305	1773126777305	0	4zd57afzr3f4mbydt14j5mzqza	xbdo3t9uq7gxmgnk4xopy1pkee	smhfusfpcirhbgq9js6gwybwsh		Looks great! Left a few comments on the PR. Mainly about the responsive breakpoints - I think we should add a tablet view.		{}		[]	[]	f	0	f	
bkj86behcjbtibfb5ahstom6ho	1773126777383	1773126777383	0	6a4bti99g3rtdmx11dhnihhg6r	xbdo3t9uq7gxmgnk4xopy1pkee	smhfusfpcirhbgq9js6gwybwsh		That would be awesome Mike! Let me create tickets for the individual widgets. We need: line chart, bar chart, pie chart, and a KPI card widget.		{}		[]	[]	f	0	f	
smhfusfpcirhbgq9js6gwybwsh	1773126776776	1773126777450	0	6a4bti99g3rtdmx11dhnihhg6r	xbdo3t9uq7gxmgnk4xopy1pkee			I've pushed the initial PR for the dashboard layout: https://github.com/techcorp/portal/pull/142. It includes the grid system and the widget container components. Would love some feedback!		{}		[]	[]	f	0	f	
ej487k53ypdy8ewwj4xphpka7y	1773126777556	1773126777556	0	x916bcascjyyjrc5y8e5hbrgna	xbdo3t9uq7gxmgnk4xopy1pkee	5oezr9ccrbncuxdhtxuhjo6pho		Good call. @bob.wilson can we use Redis pub/sub for the notification queue in our k8s setup?		{}		[]	[]	f	0	f	
chs7z14yafnctgkmuh7gn6591c	1773126777598	1773126777598	0	46fd55wk57bdzq89debc4cxugr	xbdo3t9uq7gxmgnk4xopy1pkee	5oezr9ccrbncuxdhtxuhjo6pho		Yes, we already have a Redis cluster running. I'll configure a dedicated channel for notifications. Should be straightforward.		{}		[]	[]	f	0	f	
5oezr9ccrbncuxdhtxuhjo6pho	1773126777482	1773126777598	0	9mbmdxz1kidnmemmqi9ou5w1ah	xbdo3t9uq7gxmgnk4xopy1pkee			Product update: Based on customer feedback, we're adding a notification center to the portal. Users want real-time alerts for order status changes, payment confirmations, and system alerts. Adding this to the Sprint 12 backlog.		{}		[]	[]	f	0	f	
s39bgqohhjyoie8zdks8s46s7a	1773126777747	1773126777747	0	3bekgg684bb5iq6tfq1h95az3r	xbdo3t9uq7gxmgnk4xopy1pkee	cm7g4nhuyjbq9fr1furyz7emph		I'll re-run the failed tests once fixes are in. Also setting up automated Safari testing in our CI pipeline with BrowserStack.		{}		[]	[]	f	0	f	
cb5bo13q6jnz7eemsf4rygcuph	1773126777797	1773126777797	0	ccmjk1p1abffx87a4zni7n4uoh	qk4rrkf1stnn5ydh15bgh16nth	oq4um7bawtd48fr4tfchj6zkce		I like the tRPC choice. It'll save us a lot of boilerplate compared to REST. Can we also use Prisma for the ORM?		{}		[]	[]	f	0	f	
fqmwa7qr1iy3bqcuypq5s89r6y	1773126777857	1773126777857	0	4zd57afzr3f4mbydt14j5mzqza	qk4rrkf1stnn5ydh15bgh16nth	oq4um7bawtd48fr4tfchj6zkce		Yes, Prisma is great with tRPC. And Zustand has excellent DevTools support now. I'll create the RFC document and share it by Thursday.		{}		[]	[]	f	0	f	
o7phrmn6xtf63boarkfocke3ea	1773126778371	1773126778371	0	ccmjk1p1abffx87a4zni7n4uoh	j443od6puifhjf85mfwk55h8ec	zs7apgtgpfn3bnxr9cxznwjpry		Payment Gateway v3.2.1 includes the Stripe API upgrade. @diana.prince can you run the payment flow tests on staging Monday evening?		{}		[]	[]	f	0	f	
6z6c9wb5ajn4id1s4q3dt96ade	1773126777713	1773126777713	0	ccmjk1p1abffx87a4zni7n4uoh	xbdo3t9uq7gxmgnk4xopy1pkee	cm7g4nhuyjbq9fr1furyz7emph		I'll fix the concurrent cart update issue. Likely a race condition in the transaction handling. Should have a fix by EOD.		{}		[]	[]	f	0	f	
cm7g4nhuyjbq9fr1furyz7emph	1773126777636	1773126777747	0	3bekgg684bb5iq6tfq1h95az3r	xbdo3t9uq7gxmgnk4xopy1pkee			QA Report for Sprint 11:\n\n**Passed:** 45/52 test cases\n**Failed:** 7 test cases\n**Blockers:**\n- Login page crashes on Safari 16 when using autofill\n- Payment form validation not triggered on mobile keyboards\n- API returns 500 on concurrent cart updates\n\n**Notes:** Overall good quality. The Safari issue is the most critical since 15% of our users are on Safari.		{}		[]	[]	f	0	f	
9bna44iqzfy43e8uoak44ik59w	1773126777824	1773126777824	0	6a4bti99g3rtdmx11dhnihhg6r	qk4rrkf1stnn5ydh15bgh16nth	oq4um7bawtd48fr4tfchj6zkce		Zustand over Redux? I'm in favor - much simpler API and less boilerplate. But we need to make sure the DevTools support is adequate.		{}		[]	[]	f	0	f	
wkwi9rchqt8hpe6fgjapkqs7qh	1773126777930	1773126777930	0	g7r88gtyqjfdzgnwhr9xyumzce	qk4rrkf1stnn5ydh15bgh16nth	oq4um7bawtd48fr4tfchj6zkce		I'll be there. Main concerns will be around data access controls and API authentication for internal tools.		{}		[]	[]	f	0	f	
y3puxmddyb853gf7m7b5u5d67y	1773126777991	1773126777991	0	4zd57afzr3f4mbydt14j5mzqza	qk4rrkf1stnn5ydh15bgh16nth	u9b7ehb3kbnz5dkohhn3s6rt9y		Perfect. Let's set up a meeting with Ivy to map out the data pipeline. We'll need real-time updates for system health and hourly updates for business metrics.		{}		[]	[]	f	0	f	
r4k6i9w6wtb5irsne8xwpkqizw	1773126778022	1773126778022	0	cxtqjdhuqiydtmdmtdc1mesbfo	qk4rrkf1stnn5ydh15bgh16nth	u9b7ehb3kbnz5dkohhn3s6rt9y		Should I start prototyping the chart components? I can create a Storybook with sample visualizations for each metric type.		{}		[]	[]	f	0	f	
3rs6g6qonbgjici8xxftq151yh	1773126778096	1773126778096	0	ccmjk1p1abffx87a4zni7n4uoh	j443od6puifhjf85mfwk55h8ec	uargsrccatrg5j17n9r7tq5ube		The rate limiting config is in the ConfigMap. Default is 100 req/min per API key. Should we adjust for the initial rollout?		{}		[]	[]	f	0	f	
wi3oxnhyobrt78rpb4ie5uaagy	1773126778155	1773126778155	0	3bekgg684bb5iq6tfq1h95az3r	j443od6puifhjf85mfwk55h8ec	uargsrccatrg5j17n9r7tq5ube		I'll run the smoke tests right after deployment. Estimated 15 min for the full suite.		{}		[]	[]	f	0	f	
uargsrccatrg5j17n9r7tq5ube	1773126778050	1773126778191	0	46fd55wk57bdzq89debc4cxugr	j443od6puifhjf85mfwk55h8ec			:rocket: **Deployment Notice**\n\n**Service:** Customer API v2.4.1\n**Environment:** Production\n**Time:** Today, 2:00 PM EST\n**Changes:**\n- Fix for payment processing timeout\n- New rate limiting middleware\n- Updated error response format\n\n**Rollback Plan:** Revert to v2.4.0 via Helm chart\n**Monitoring:** Grafana dashboard #12\n\nPlease hold off on non-critical deploys until 3:00 PM.		{}		[]	[]	f	0	f	
pu9a8q8ftjyhpehzsdqkjg4bpw	1773126778238	1773126778238	0	x916bcascjyyjrc5y8e5hbrgna	j443od6puifhjf85mfwk55h8ec	os3wyshrxtgkiqrypugky1zmyr		Thanks for the heads up. Everyone please wrap up your staging testing before 11 PM.		{}		[]	[]	f	0	f	
tq9yno6x4bf18gxa19nxq8pjxw	1773126778266	1773126778266	0	g7r88gtyqjfdzgnwhr9xyumzce	j443od6puifhjf85mfwk55h8ec	os3wyshrxtgkiqrypugky1zmyr		Bob, can we also enable automated log rotation while you're at it? The pg_log directory is growing unbounded.		{}		[]	[]	f	0	f	
dzq34q3wffg4dqb5eawpt6kmca	1773126778296	1773126778296	0	46fd55wk57bdzq89debc4cxugr	j443od6puifhjf85mfwk55h8ec	os3wyshrxtgkiqrypugky1zmyr		Good catch Lisa. I'll add log rotation config. Max 7 days retention, 100MB per file.		{}		[]	[]	f	0	f	
os3wyshrxtgkiqrypugky1zmyr	1773126778223	1773126778296	0	46fd55wk57bdzq89debc4cxugr	j443od6puifhjf85mfwk55h8ec			:warning: **Infrastructure Alert**\n\nOur staging environment database (PostgreSQL) is running low on disk space. Current usage: 87%. I'm scheduling a cleanup of old test data and will increase the volume size from 50GB to 100GB tonight.\n\nThis will require a brief downtime of the staging environment from 11 PM to 12 AM EST.		{}		[]	[]	f	0	f	
md5qr4hkginc5mn7p71pgp81oa	1773126778415	1773126778415	0	3bekgg684bb5iq6tfq1h95az3r	j443od6puifhjf85mfwk55h8ec	zs7apgtgpfn3bnxr9cxznwjpry		Will do. I'll have the test results ready by Tuesday morning before the deployment.		{}		[]	[]	f	0	f	
kb6b67dssidjirgprn1mc6je1r	1773126778846	1773126778846	0	4zd57afzr3f4mbydt14j5mzqza	dewd9f48ij85xgq7tfte859qfa	rtdewtn5ein8uqwxqjq71jkiqh		I'll review this afternoon. The retry logic sounds important - what's the max retry count and backoff ceiling?		{}		[]	[]	f	0	f	
1a91fqzypf8ozr4px889kxfggh	1773126778906	1773126778906	0	g7r88gtyqjfdzgnwhr9xyumzce	dewd9f48ij85xgq7tfte859qfa	rtdewtn5ein8uqwxqjq71jkiqh		Security review note: Make sure the retry logic doesn't retry on 4xx errors, only 5xx and network timeouts. Otherwise we might duplicate payments.		{}		[]	[]	f	0	f	
44c7r9cigbd6jbpx94kjcuspeh	1773126778939	1773126778939	0	ccmjk1p1abffx87a4zni7n4uoh	dewd9f48ij85xgq7tfte859qfa	rtdewtn5ein8uqwxqjq71jkiqh		Great point Lisa! I've already handled that - only retrying on 502, 503, 504, and ECONNRESET. 4xx errors fail immediately.		{}		[]	[]	f	0	f	
rtdewtn5ein8uqwxqjq71jkiqh	1773126778453	1773126778939	0	ccmjk1p1abffx87a4zni7n4uoh	dewd9f48ij85xgq7tfte859qfa			Need a review on PR #287: Refactored the order processing pipeline to use async/await instead of callbacks. Also added retry logic with exponential backoff for payment API calls.\n\nhttps://github.com/techcorp/api/pull/287\n\nKey changes:\n- `OrderService.processOrder()` is now async\n- Added `RetryHelper` utility class\n- Updated 12 test files		{}		[]	[]	f	0	f	
4hwd73tkp7bztjjnftbbpppahw	1773126779416	1773126779416	0	4zd57afzr3f4mbydt14j5mzqza	dewd9f48ij85xgq7tfte859qfa	zj6hkh4ttpfazbhyrsz79ncedw		Nice work for a first PR! A few suggestions:\n1. Extract the D3 rendering into a custom hook\n2. Add error boundary around the chart\n3. Memoize the data transformation\n\nOverall structure is good though!		{}		[]	[]	f	0	f	
uu9kdc1fyb8r78qwb7gg1ziwgy	1773126779519	1773126779519	0	3bekgg684bb5iq6tfq1h95az3r	bbekt5pgxfnc5qmpwaxux3py1a	urspsr5koirhbfi6ekpezr18hh		Thanks Charlie. I have 5 related test cases ready. Let me know when the fix is pushed and I'll verify.		{}		[]	[]	f	0	f	
dnthbdzpkjf93jzc5idgrbtoxc	1773126779545	1773126779545	0	ccmjk1p1abffx87a4zni7n4uoh	bbekt5pgxfnc5qmpwaxux3py1a	urspsr5koirhbfi6ekpezr18hh		Fix pushed in commit `a3f8d2e`. Changed the discount to use `BigDecimal` for price calculations. @diana.prince ready for verification.		{}		[]	[]	f	0	f	
urspsr5koirhbfi6ekpezr18hh	1773126779474	1773126779570	0	3bekgg684bb5iq6tfq1h95az3r	bbekt5pgxfnc5qmpwaxux3py1a			[ALPHA] **Critical Bug** - Shopping cart total shows $0.00 when applying a percentage discount code.\n\n**Steps to Reproduce:**\n1. Add any product to cart\n2. Apply discount code 'SAVE20'\n3. Cart total shows $0.00 instead of the discounted price\n\n**Expected:** Total should show original price minus 20%\n**Actual:** Total shows $0.00\n**Browser:** Chrome 121, Firefox 122\n**Priority:** High		{}		[]	[]	f	0	f	
55jyy9ap8pnk9jzxz14mk7dpya	1773126779691	1773126779691	0	4zd57afzr3f4mbydt14j5mzqza	wnrktfozbffs7dpb5u86mga3uy			**Standup - Monday March 10**\n\n**Yesterday:** Finalized OAuth 2.0 architecture design, reviewed 3 PRs\n**Today:** Start implementing the auth middleware, set up token refresh endpoint\n**Blockers:** Need AWS Cognito access from Bob		{}		[]	[]	f	0	f	
fo7oc1q5o3r4mrjkfca75ortpr	1773126779706	1773126779706	0	6a4bti99g3rtdmx11dhnihhg6r	wnrktfozbffs7dpb5u86mga3uy			**Standup - Monday March 10**\n\n**Yesterday:** Pushed dashboard grid layout PR, started on responsive fixes\n**Today:** Fix Safari autofill bug (P1), tablet responsive view\n**Blockers:** None		{}		[]	[]	f	0	f	
muhj7wuujby69xgytoh7up5yxr	1773126779718	1773126779718	0	ccmjk1p1abffx87a4zni7n4uoh	wnrktfozbffs7dpb5u86mga3uy			**Standup - Monday March 10**\n\n**Yesterday:** Fixed cart discount calculation bug, started async refactor for order pipeline\n**Today:** Complete async refactor, add retry logic for payment API\n**Blockers:** Need staging environment access to test payment flow		{}		[]	[]	f	0	f	
xhadbiw4jpfxudc6ocs9s4fhih	1773126779730	1773126779730	0	46fd55wk57bdzq89debc4cxugr	wnrktfozbffs7dpb5u86mga3uy			**Standup - Monday March 10**\n\n**Yesterday:** Completed staging DB disk expansion, set up log rotation\n**Today:** Deploy Auth Service v1.8.0, configure Redis notification channel\n**Blockers:** None		{}		[]	[]	f	0	f	
sexyarrk3fde7nbbg9i1p3txio	1773126779742	1773126779742	0	3bekgg684bb5iq6tfq1h95az3r	wnrktfozbffs7dpb5u86mga3uy			**Standup - Monday March 10**\n\n**Yesterday:** Wrote Sprint 11 QA report, set up BrowserStack for Safari CI\n**Today:** Verify cart bug fix, prepare payment flow test suite for Tuesday\n**Blockers:** None		{}		[]	[]	f	0	f	
gz1tmmyerifnzkc1enb8heicur	1773126779755	1773126779755	0	cxtqjdhuqiydtmdmtdc1mesbfo	wnrktfozbffs7dpb5u86mga3uy			**Standup - Monday March 10**\n\n**Yesterday:** Worked on activity heatmap component, addressed PR feedback\n**Today:** Pair with Alice on image loading fix, update heatmap PR\n**Blockers:** Still waiting for D3.js license clarification from legal		{}		[]	[]	f	0	f	
bip86rfrfpgi8fdpa4wp6iyprr	1773126779785	1773126779785	0	ccmjk1p1abffx87a4zni7n4uoh	rmsexzhn3jgy7f4kbgnczsa3sa	hn887u9w6pypuqkpqj3a8u1j6y		I agree with URL path versioning. It's the most explicit and easiest to debug. We can use a reverse proxy to route between versions.		{}		[]	[]	f	0	f	
ruzdqybad7ddup37qq9pcf66ka	1773126779842	1773126779842	0	x916bcascjyyjrc5y8e5hbrgna	rmsexzhn3jgy7f4kbgnczsa3sa	hn887u9w6pypuqkpqj3a8u1j6y		Let's go with URL path versioning. Please document this in our architecture decision records (ADR). I'll create ADR-015 for this.		{}		[]	[]	f	0	f	
buaif73es7r6pycz4piafcbr3c	1773126780006	1773126780006	0	46fd55wk57bdzq89debc4cxugr	rmsexzhn3jgy7f4kbgnczsa3sa	zgcemj5typgct8zb5mh4a7kxue		Will do. I'll add them to Monday's deployment. The lodash update might need some testing since we use it heavily.		{}		[]	[]	f	0	f	
zgcemj5typgct8zb5mh4a7kxue	1773126779959	1773126780036	0	g7r88gtyqjfdzgnwhr9xyumzce	rmsexzhn3jgy7f4kbgnczsa3sa			**Security Update:** I've completed the quarterly dependency audit. Here are the findings:\n\n:red_circle: **Critical:** 2 vulnerabilities in `lodash` (prototype pollution) - PR #301 ready\n:orange_circle: **High:** 1 vulnerability in `jsonwebtoken` < 9.0.0 - PR #302 ready\n:yellow_circle: **Medium:** 3 vulnerabilities in dev dependencies - tracking in JIRA\n\nPRs #301 and #302 should be merged and deployed this week.		{}		[]	[]	f	0	f	
czed4ajgb7byjbpg854mikegzy	1773126780117	1773126780117	0	46fd55wk57bdzq89debc4cxugr	et85fk3eqpgrip4z9eydcg4weo	bfyx5zu8k7b45mkmhe4ex4srwc		Yes, it was caused by a PostgreSQL connection pool exhaustion. I've increased the pool size from 20 to 50 connections and added connection timeout handling.		{}		[]	[]	f	0	f	
4hnjptbpmpnmzgdqdth51qxt3y	1773126780203	1773126780317	0	g7r88gtyqjfdzgnwhr9xyumzce	mjjwsjpbnt8rxyp7n5mt1f3syw			:rotating_light: **Security Incident Report - March 8**\n\n**Severity:** Medium\n**Type:** Unauthorized API access attempt\n**Details:** Detected 500+ failed authentication attempts from IP range 203.0.113.0/24 targeting `/api/v1/admin/users` endpoint over a 2-hour period.\n\n**Actions Taken:**\n1. IP range blocked at WAF level\n2. Rate limiting tightened on admin endpoints (10 req/min)\n3. All admin accounts verified - no breach detected\n4. Enhanced logging enabled for admin endpoints\n\n**Recommendation:** Implement IP-based progressive lockout for failed auth attempts.		{}		[]	[]	f	0	f	
xcehaj96npbzxqd1nysufq4ziy	1773126780372	1773126780372	0	m16j1q6rkfdpxguuksz7wmpuba	scj33w14etykfdaydd3cqcae5w	uwc5r816rfnodbnn35erk8ejgo		I'll start drafting the blog series. Thinking 6 posts over 3 months: customer stories, product deep-dives, and thought leadership pieces.		{}		[]	[]	f	0	f	
pft8prc1t3rt8jgewa7wbefjhe	1773126780434	1773126780434	0	93n7axewi7n9xpsis8z5d99bre	scj33w14etykfdaydd3cqcae5w	uwc5r816rfnodbnn35erk8ejgo		Start with a mood board Grace. Let's align on the visual direction before investing in full mockups.		{}		[]	[]	f	0	f	
uwc5r816rfnodbnn35erk8ejgo	1773126780352	1773126780465	0	93n7axewi7n9xpsis8z5d99bre	scj33w14etykfdaydd3cqcae5w			Team, let's kick off planning for our Q2 campaign: **'Innovate Together'**\n\n**Objective:** Increase brand awareness and drive 30% more sign-ups\n**Budget:** $50,000\n**Timeline:** April 1 - June 30\n**Channels:** Social media, email, content marketing, paid ads\n\nI've created the campaign brief in our shared drive. Let's discuss the strategy in our Thursday meeting.		{}		[]	[]	f	0	f	
ixsb3fxxcifpxgwsu9yg9skbaa	1773126780515	1773126780515	0	m16j1q6rkfdpxguuksz7wmpuba	scj33w14etykfdaydd3cqcae5w	duk3c7xk9bnemr57t3kda66zwh		Amazing results! The 'Customer Success Stories' blog series got the most organic traffic. I think we should continue this format in Q2.		{}		[]	[]	f	0	f	
wucyg7xnhiftirdr3f9cjhxc7h	1773126780666	1773126780666	0	dp4jszrpsjnjpjw1mth4ygithy	7ijgcabphifx7mwe9g6w9paemy	1yfw8sxcrpym3c69odw39n155e		Carousel images will be ready by tonight. I'm using the new brand photography from last week's photoshoot.		{}		[]	[]	f	0	f	
y9izo9o5c78w7ged6goqcd1aec	1773126779617	1773126779617	0	6a4bti99g3rtdmx11dhnihhg6r	bbekt5pgxfnc5qmpwaxux3py1a	s38d45f3u3yuj8t8auhrmdgtor		That would be great Grace. I'll implement blur-up using next/image's `placeholder='blur'` prop which generates a base64 preview automatically.		{}		[]	[]	f	0	f	
ri75x8awspgb3morrrhyg4ybur	1773126779668	1773126779668	0	6a4bti99g3rtdmx11dhnihhg6r	bbekt5pgxfnc5qmpwaxux3py1a	s38d45f3u3yuj8t8auhrmdgtor		Sure Mike, let's pair tomorrow morning. Grab the 10 AM slot on my calendar.		{}		[]	[]	f	0	f	
s38d45f3u3yuj8t8auhrmdgtor	1773126779594	1773126779668	0	6a4bti99g3rtdmx11dhnihhg6r	bbekt5pgxfnc5qmpwaxux3py1a			[ALPHA] **UI Bug** - Product images not loading on slow connections (3G simulation).\n\nThe lazy loading implementation doesn't have a proper fallback. Users on slow connections see broken image icons for 10+ seconds before images load.\n\n**Suggested Fix:** Add skeleton placeholders and progressive image loading (blur-up technique).\n**Priority:** Medium		{}		[]	[]	f	0	f	
81nsskmsmprzt8mg8emyo4pzuo	1773126779882	1773126779882	0	hacoqz1mijy8db1u95mwsgt6pe	rmsexzhn3jgy7f4kbgnczsa3sa	hn887u9w6pypuqkpqj3a8u1j6y		I'll update our API documentation template to include version information prominently. Should I also add a deprecation notice section?		{}		[]	[]	f	0	f	
hn887u9w6pypuqkpqj3a8u1j6y	1773126779767	1773126779923	0	4zd57afzr3f4mbydt14j5mzqza	rmsexzhn3jgy7f4kbgnczsa3sa			I've been evaluating different approaches for our API versioning strategy. Here are the options:\n\n1. **URL Path Versioning:** `/api/v1/users`, `/api/v2/users`\n2. **Header Versioning:** `Accept: application/vnd.techcorp.v2+json`\n3. **Query Parameter:** `/api/users?version=2`\n\nI'm leaning towards option 1 (URL path) for simplicity. Thoughts?		{}		[]	[]	f	0	f	
b8j99sd48bd1dmy157b5tobzuh	1773126780036	1773126780036	0	ccmjk1p1abffx87a4zni7n4uoh	rmsexzhn3jgy7f4kbgnczsa3sa	zgcemj5typgct8zb5mh4a7kxue		I'll run the full test suite against the lodash update today. We use `_.merge`, `_.cloneDeep`, and `_.debounce` extensively.		{}		[]	[]	f	0	f	
fkxh6g5t5384bddst1z6cb9pfw	1773126780144	1773126780144	0	g7r88gtyqjfdzgnwhr9xyumzce	et85fk3eqpgrip4z9eydcg4weo	bfyx5zu8k7b45mkmhe4ex4srwc		Can we set up an alert for when the connection pool goes above 80% utilization? That way we catch it before it becomes an outage.		{}		[]	[]	f	0	f	
upe9bsxhhbfu9ksj1666j88w7h	1773126780252	1773126780252	0	46fd55wk57bdzq89debc4cxugr	mjjwsjpbnt8rxyp7n5mt1f3syw	4hnjptbpmpnmzgdqdth51qxt3y		I've verified the WAF rules are in place. Also added the IP range to our permanent block list. The attack pattern looks like a credential stuffing attempt.		{}		[]	[]	f	0	f	
p85km154r7f9tkxnxgmnerrzsa	1773126780317	1773126780317	0	g7r88gtyqjfdzgnwhr9xyumzce	mjjwsjpbnt8rxyp7n5mt1f3syw	4hnjptbpmpnmzgdqdth51qxt3y		Yes, CAPTCHA is a good idea. I'll add it to the security backlog. Also scheduling a post-incident review for Tuesday at 2 PM.		{}		[]	[]	f	0	f	
6w7wiqqgn7nodm3pfyux6g1ipy	1773126780403	1773126780403	0	dp4jszrpsjnjpjw1mth4ygithy	scj33w14etykfdaydd3cqcae5w	uwc5r816rfnodbnn35erk8ejgo		I'll work on the visual identity for the campaign. Should I create a mood board first or go straight to mockups?		{}		[]	[]	f	0	f	
a1ehszmb3byjzd3zu88ugdn88e	1773126780575	1773126780575	0	dp4jszrpsjnjpjw1mth4ygithy	scj33w14etykfdaydd3cqcae5w	duk3c7xk9bnemr57t3kda66zwh		The carousel posts on Instagram had 3x the engagement of single images. Let's make carousels our default format for Q2.		{}		[]	[]	f	0	f	
duk3c7xk9bnemr57t3kda66zwh	1773126780499	1773126780611	0	93n7axewi7n9xpsis8z5d99bre	scj33w14etykfdaydd3cqcae5w			**Q1 Campaign Results: 'Build Better'**\n\n:chart_with_upwards_trend: **Results:**\n- Website traffic: +42% (target was +25%)\n- New sign-ups: 3,847 (target was 3,000)\n- Email open rate: 28.3% (industry avg: 21%)\n- Social engagement: +65% across all platforms\n- Cost per acquisition: $12.40 (target was $15)\n\n:tada: Great work everyone! The content series by Frank and Grace's social graphics were the top performers.		{}		[]	[]	f	0	f	
1yfw8sxcrpym3c69odw39n155e	1773126780648	1773126780727	0	m16j1q6rkfdpxguuksz7wmpuba	7ijgcabphifx7mwe9g6w9paemy			**Content Schedule - Week of March 10:**\n\n**Monday:** LinkedIn - Blog post share: '5 Ways to Streamline Your Workflow'\n**Tuesday:** Twitter/X - Product tip thread (5 tweets)\n**Wednesday:** Instagram - Behind-the-scenes team photo carousel\n**Thursday:** LinkedIn - Industry insights article\n**Friday:** All platforms - 'Feature Friday' spotlight\n\nAll drafts are in Hootsuite. @grace.lee the Instagram carousel images are pending.		{}		[]	[]	f	0	f	
tjgc4793ifgufkna1frhjmniec	1773126780777	1773126780777	0	93n7axewi7n9xpsis8z5d99bre	qiiq57tw6jbru8zhkytut8i64e	i9a9qqzfginezb1o6b8a3siuoh		Great report Ivy. The pricing page analytics are important - can we also A/B test two different pricing layouts?		{}		[]	[]	f	0	f	
hhigzptwetywzb3g7hhhhjdw8e	1773126780837	1773126780837	0	7e4ojpbykjntdmpu94y5ekub1c	qiiq57tw6jbru8zhkytut8i64e	i9a9qqzfginezb1o6b8a3siuoh		Good question Kevin. 312 demo requests from 3,200 views = 9.75% conversion. That's above our 8% benchmark. The new demo page design is working well.		{}		[]	[]	f	0	f	
g1thz8ok3jbzmbmurpq3z73qoc	1773126781052	1773126781052	0	93n7axewi7n9xpsis8z5d99bre	3zf3d5jjnfymug7cq1ucdwqrmo	ayb41zzfr3nrzq8x9w39eabrhw		Grace, can you also create social media versions (1080x1080 for Instagram, 1200x628 for LinkedIn) while you're at it?		{}		[]	[]	f	0	f	
nobtntitt3nq8yt941g4xkx6dh	1773126781131	1773126781131	0	93n7axewi7n9xpsis8z5d99bre	5b4hke3753y73feti3hhtfbgiy	q3ij1tnz7pfcmjkw13u57kpyie		Congratulations everyone! I'll be sharing this on our social channels. So proud of this team!		{}		[]	[]	f	0	f	
befjnjnmtpfytk1h7hsqgjq17h	1773126781188	1773126781188	0	4zd57afzr3f4mbydt14j5mzqza	5b4hke3753y73feti3hhtfbgiy	q3ij1tnz7pfcmjkw13u57kpyie		This is amazing news! Looking forward to the celebration!		{}		[]	[]	f	0	f	
5179ryz3f38zmxrfmqzcxaexbr	1773126781263	1773126781263	0	9mbmdxz1kidnmemmqi9ou5w1ah	5b4hke3753y73feti3hhtfbgiy	q3ij1tnz7pfcmjkw13u57kpyie		:clap: Incredible! Our Glassdoor reviews and employee satisfaction scores made this possible. Keep the feedback coming!		{}		[]	[]	f	0	f	
7phgkxh6tpfrd8n591p9xbwfna	1773126779812	1773126779812	0	g7r88gtyqjfdzgnwhr9xyumzce	rmsexzhn3jgy7f4kbgnczsa3sa	hn887u9w6pypuqkpqj3a8u1j6y		From a security perspective, URL path versioning also makes it easier to apply different rate limiting and auth policies per version.		{}		[]	[]	f	0	f	
bux3753twfdwfqhucctakteedc	1773126779923	1773126779923	0	4zd57afzr3f4mbydt14j5mzqza	rmsexzhn3jgy7f4kbgnczsa3sa	hn887u9w6pypuqkpqj3a8u1j6y		Yes please Natalie. We should have clear deprecation timelines: announce 6 months before, sunset 3 months after the new version is stable.		{}		[]	[]	f	0	f	
659yasm3djdqdkfxnp8w5ifcbc	1773126779975	1773126779975	0	x916bcascjyyjrc5y8e5hbrgna	rmsexzhn3jgy7f4kbgnczsa3sa	zgcemj5typgct8zb5mh4a7kxue		Thanks Lisa. PRs #301 and #302 are approved. @bob.wilson please prioritize deploying these patches.		{}		[]	[]	f	0	f	
f6res95infnufy3u4m1cnzxmcw	1773126780727	1773126780727	0	7e4ojpbykjntdmpu94y5ekub1c	7ijgcabphifx7mwe9g6w9paemy	1yfw8sxcrpym3c69odw39n155e		Last week's posts peaked at 2-3 PM EST. I'd recommend scheduling all posts for 2 PM.		{}		[]	[]	f	0	f	
hj3zeoh3ytnq3biyxywxo5x7qe	1773126780998	1773126780998	0	dp4jszrpsjnjpjw1mth4ygithy	3zf3d5jjnfymug7cq1ucdwqrmo	ayb41zzfr3nrzq8x9w39eabrhw		Got it! I'll have the first two ready by Wednesday. For the 'Customer Spotlight' one - do we have DataFlow's logo and brand colors I can incorporate?		{}		[]	[]	f	0	f	
ayb41zzfr3nrzq8x9w39eabrhw	1773126780980	1773126781082	0	m16j1q6rkfdpxguuksz7wmpuba	3zf3d5jjnfymug7cq1ucdwqrmo			**Design Request**\n\n**Type:** Blog header images\n**Quantity:** 4 images for March blog posts\n**Dimensions:** 1200x630px (OG image compatible)\n**Style:** Clean, modern, matching our brand guidelines\n**Deadline:** March 14\n\nBlog titles:\n1. '5 Ways to Streamline Your Workflow'\n2. 'The Future of Enterprise Collaboration'\n3. 'Customer Spotlight: DataFlow Inc'\n4. 'Q1 Product Roundup'\n\nBrand assets are in the shared Figma library.		{}		[]	[]	f	0	f	
3w51tomfpjgbbmufzyhk14zysr	1773126781158	1773126781158	0	x916bcascjyyjrc5y8e5hbrgna	5b4hke3753y73feti3hhtfbgiy	q3ij1tnz7pfcmjkw13u57kpyie		Well deserved! The engineering team is the best I've ever worked with.		{}		[]	[]	f	0	f	
sxeu94wf87gh7xnj147tp1a4za	1773126781339	1773126781339	0	4zd57afzr3f4mbydt14j5mzqza	5b4hke3753y73feti3hhtfbgiy	zj5n1igz83g7bnoujg81u9c9kh		Welcome Mike! I've already sent you a calendar invite for our first 1:1 on Monday. Looking forward to working with you!		{}		[]	[]	f	0	f	
xrt77eu7ojddb8qdeg9xyh1msw	1773126781398	1773126781398	0	cxtqjdhuqiydtmdmtdc1mesbfo	5b4hke3753y73feti3hhtfbgiy	zj5n1igz83g7bnoujg81u9c9kh		Thanks everyone! Super excited to be here. Looking forward to contributing to the team!		{}		[]	[]	f	0	f	
xqeqrppc3frtjr651rtjuap9ge	1773126781472	1773126781472	0	6a4bti99g3rtdmx11dhnihhg6r	5b4hke3753y73feti3hhtfbgiy	zj5n1igz83g7bnoujg81u9c9kh		Welcome to the team! If you need any help navigating the codebase or our tools, don't hesitate to ask!		{}		[]	[]	f	0	f	
ye5cpd3o67ytzq94om3fupwjuy	1773126781573	1773126781573	0	46fd55wk57bdzq89debc4cxugr	5b4hke3753y73feti3hhtfbgiy	ituauyjmk7n35jriu16fre44eh		Yes, the EKS migration is on track for Q2. I'll cover the timeline and migration plan in the all-hands.		{}		[]	[]	f	0	f	
q78ka1bd53ntbc3nox7nqkbo7a	1773126781636	1773126781636	0	9mbmdxz1kidnmemmqi9ou5w1ah	5b4hke3753y73feti3hhtfbgiy	ituauyjmk7n35jriu16fre44eh		I'll present the updated Q2 product roadmap as well. Some exciting features coming up!		{}		[]	[]	f	0	f	
qdhoqtm8rpdn5km6tjp9suqcir	1773126781717	1773126781717	0	cxtqjdhuqiydtmdmtdc1mesbfo	1s9nagudoiboirmb7ckj1mukfy	sd8n1zw1obngingpzu9dnpz9xe		Haven't started it yet but it's on my list! No spoilers please!		{}		[]	[]	f	0	f	
4sc58pn37pfgxyx7e7aqw5trzo	1773126781781	1773126781781	0	46fd55wk57bdzq89debc4cxugr	1s9nagudoiboirmb7ckj1mukfy	sd8n1zw1obngingpzu9dnpz9xe		The DevOps character is surprisingly accurate. They even got the 'everything is on fire but we're fine' energy right :fire:		{}		[]	[]	f	0	f	
hinchs99fifopei3nc9q4yi9nc	1773126781857	1773126781857	0	udhm7t7fqfgc9k9funqdejmeea	1s9nagudoiboirmb7ckj1mukfy	bq74ebs4zbyn8msgbpijcfj5rc		The new machine was a popular request in our last employee survey. Enjoy!		{}		[]	[]	f	0	f	
dy4s6hc34pghu88q3t6d6hydbc	1773126781921	1773126781921	0	3bekgg684bb5iq6tfq1h95az3r	1s9nagudoiboirmb7ckj1mukfy	bq74ebs4zbyn8msgbpijcfj5rc		Can we do a virtual session too for the remote folks? I'd love to participate from home!		{}		[]	[]	f	0	f	
p69g8rh7zjfwxxwqb71c1p4pqo	1773126782101	1773126782101	0	46fd55wk57bdzq89debc4cxugr	1s9nagudoiboirmb7ckj1mukfy	c3xjtk6dt7gg3puenbx5qtqz8r		Jane, the Keychron K2 is a great starter. Wireless, hot-swappable, and works great with Mac. Around $80.		{}		[]	[]	f	0	f	
hryzg9m3fpnefe7uezi1d6631a	1773126782150	1773126782150	0	93n7axewi7n9xpsis8z5d99bre	8k1ahz7c8pgmjyco414pgi5f4y	dmpbf4epffrkmd9biy83m5qitw		YES PLEASE! Your cooking is always incredible. Should I bring anything to complement it?		{}		[]	[]	f	0	f	
wmxbedrqgpnymn61qta9imprfh	1773126782208	1773126782208	0	7e4ojpbykjntdmpu94y5ekub1c	8k1ahz7c8pgmjyco414pgi5f4y	dmpbf4epffrkmd9biy83m5qitw		Can you share the recipe? I've been trying to perfect my fried chicken game.		{}		[]	[]	f	0	f	
5aqd9k5z6bn8fnmmyqxzo3z5do	1773126782321	1773126782321	0	4zd57afzr3f4mbydt14j5mzqza	7aqugqd4dprbzcfcnm8ouuqczc	8p613yhn3tr5zjiuy8ebxazfih		Count me in for everything except trivia night - I have a prior commitment.		{}		[]	[]	f	0	f	
gbs4qox5dffsjxi6isz11rm1ph	1773126782386	1773126782386	0	udhm7t7fqfgc9k9funqdejmeea	7aqugqd4dprbzcfcnm8ouuqczc	8p613yhn3tr5zjiuy8ebxazfih		Mix of both Mike! 5 rounds: General Knowledge, Tech & Science, Pop Culture, Geography, and a Mystery Round.		{}		[]	[]	f	0	f	
kmgnwspdzpnc8qf8x3fs86reky	1773126782274	1773126782516	1773126782516	udhm7t7fqfgc9k9funqdejmeea	7aqugqd4dprbzcfcnm8ouuqczc		8p613yhn3tr5zjiuy8ebxazfih	:calendar: **Upcoming Events:**\n\n**March 14** - Engineering All-Hands (10:00 AM, Virtual)\n**March 15** - Team Trivia Night (6:00 PM, Slack #trivia-night)\n**March 20** - Team Lunch at Bella Italia (12:30 PM)\n**March 22** - Volunteer Day at City Food Bank (9:00 AM - 1:00 PM)\n**March 28** - Project Alpha Customer Demo (2:00 PM, Conference Room A)\n**March 31** - Q1 Company Town Hall (3:00 PM, Virtual)\n\nRSVP in the thread below! :point_down:		{}	#trivia-night	[]	[]	f	0	f	
qkrfhk9y7idoxbohh8dzaxqaxo	1773126782526	1773126782627	0	cxtqjdhuqiydtmdmtdc1mesbfo	i14jg6ym6tbfmpa93dq5usgrty			Hi! I'm having trouble connecting to the VPN from home. I installed GlobalProtect but it's giving me a 'Gateway Timeout' error. I'm on macOS Sonoma 14.3. Any help?		{}		[]	[]	f	0	f	
ze9ojmmy8bnytgr3kb3zbxxc6o	1773126782925	1773126782925	0	x916bcascjyyjrc5y8e5hbrgna	5swgwrkocprjmrngo4qj4o74io			Hey Jane, wanted to chat privately about the tech lead role. I'm recommending you for the promotion. Your work on Project Alpha has been outstanding.		{}		[]	[]	f	0	f	
wh6cfo9krpnfbfsjdroq43swiy	1773126780175	1773126780175	0	46fd55wk57bdzq89debc4cxugr	et85fk3eqpgrip4z9eydcg4weo	bfyx5zu8k7b45mkmhe4ex4srwc		Good idea. I'll add a Prometheus alert rule: `pg_stat_activity_count / pg_settings_max_connections > 0.8` triggers a warning.		{}		[]	[]	f	0	f	
bfyx5zu8k7b45mkmhe4ex4srwc	1773126780069	1773126780175	0	46fd55wk57bdzq89debc4cxugr	et85fk3eqpgrip4z9eydcg4weo			**Infrastructure Status Report - Week of March 10**\n\n**Production:**\n- Uptime: 99.97% (1 brief outage on Wed, 3 min)\n- Avg API Latency: 45ms (p99: 180ms)\n- Error Rate: 0.02%\n- CPU Utilization: 35% avg, 62% peak\n\n**Kubernetes:**\n- Cluster nodes: 8 (3 spot instances)\n- Pod restarts this week: 2 (payment-service OOM, fixed)\n- HPA events: 4 scale-ups during peak hours\n\n**Action Items:**\n- Increase payment-service memory limit from 512MB to 768MB\n- Investigate p99 latency spike on Wednesday		{}		[]	[]	f	0	f	
e3tt6urnibby9xpii7y6dtxqmh	1773126780222	1773126780222	0	x916bcascjyyjrc5y8e5hbrgna	mjjwsjpbnt8rxyp7n5mt1f3syw	4hnjptbpmpnmzgdqdth51qxt3y		Thanks for the quick response Lisa. Let's add the progressive lockout to Sprint 12.		{}		[]	[]	f	0	f	
1cq9eeiecb89b8tyeacdxhhqka	1773126780282	1773126780282	0	4zd57afzr3f4mbydt14j5mzqza	mjjwsjpbnt8rxyp7n5mt1f3syw	4hnjptbpmpnmzgdqdth51qxt3y		Should we also implement CAPTCHA after 3 failed login attempts on the admin portal? That would add another layer of defense.		{}		[]	[]	f	0	f	
wg7stb4cp3nqpmensnghpjspry	1773126780465	1773126780465	0	7e4ojpbykjntdmpu94y5ekub1c	scj33w14etykfdaydd3cqcae5w	uwc5r816rfnodbnn35erk8ejgo		I've set up tracking in Google Analytics for the campaign. UTM parameters are ready: `utm_campaign=innovate-together-q2`. I'll create a real-time dashboard for tracking.		{}		[]	[]	f	0	f	
qbkmjzfr8pfj3pse6co7nqa39r	1773126780544	1773126780544	0	7e4ojpbykjntdmpu94y5ekub1c	scj33w14etykfdaydd3cqcae5w	duk3c7xk9bnemr57t3kda66zwh		The data shows that Tuesday and Thursday posts performed 2.3x better than other days. I recommend we focus our publishing schedule on those days.		{}		[]	[]	f	0	f	
jdpidyoxh3fs3jb4ddkf3sgw4h	1773126780611	1773126780611	0	9mbmdxz1kidnmemmqi9ou5w1ah	scj33w14etykfdaydd3cqcae5w	duk3c7xk9bnemr57t3kda66zwh		Excellent ROI on this campaign. I'll share these results with the leadership team. This should help with the Q2 budget approval.		{}		[]	[]	f	0	f	
yb7gmtpmw7rop86siecd7rj3nr	1773126780696	1773126780696	0	93n7axewi7n9xpsis8z5d99bre	7ijgcabphifx7mwe9g6w9paemy	1yfw8sxcrpym3c69odw39n155e		Let's also add a poll to the Friday post. Something like 'Which feature do you use most?' with 4 options. Polls boost engagement by ~40%.		{}		[]	[]	f	0	f	
m7p1aodzsprf3m1dzzz1mguawe	1773126780805	1773126780805	0	9mbmdxz1kidnmemmqi9ou5w1ah	qiiq57tw6jbru8zhkytut8i64e	i9a9qqzfginezb1o6b8a3siuoh		The demo page conversion looks good at 3,200 views. How many actually booked a demo?		{}		[]	[]	f	0	f	
i9a9qqzfginezb1o6b8a3siuoh	1773126780759	1773126780837	0	7e4ojpbykjntdmpu94y5ekub1c	qiiq57tw6jbru8zhkytut8i64e			**Weekly Marketing Analytics Report - March 3-9**\n\n**Website:**\n- Sessions: 45,230 (+12% WoW)\n- Unique visitors: 32,100 (+8% WoW)\n- Bounce rate: 38% (improved from 42%)\n- Avg session duration: 3:42\n\n**Top Pages:**\n1. /features - 8,200 views\n2. /pricing - 6,100 views\n3. /blog/workflow-tips - 4,800 views\n4. /demo - 3,200 views\n\n**Conversion Funnel:**\n- Landing page → Sign-up page: 15%\n- Sign-up page → Registration: 42%\n- Registration → First action: 68%\n\n**Recommendation:** The pricing page has high traffic but we're not tracking scroll depth. I'll add heatmap tracking this week.		{}		[]	[]	f	0	f	
wknmy9j1q7n6m8r81a9b5gcwne	1773126780927	1773126780927	0	m16j1q6rkfdpxguuksz7wmpuba	4rt4rx5mt38b38y9ec93k89boo	ssjhm5cqwtgazfouy7phuxnyho		That would be fantastic Natalie! Let's sync tomorrow to divide up the sections. I'll handle the narrative, you handle data & visuals.		{}		[]	[]	f	0	f	
raasuoy85i81ib6xocne3d4kee	1773126781025	1773126781025	0	m16j1q6rkfdpxguuksz7wmpuba	3zf3d5jjnfymug7cq1ucdwqrmo	ayb41zzfr3nrzq8x9w39eabrhw		Yes, their brand kit is in the `Partner Assets` folder on Google Drive. Primary color is #2563EB.		{}		[]	[]	f	0	f	
bs4xtahfk7nk3qwp6wm3csrm3w	1773126781082	1773126781082	0	dp4jszrpsjnjpjw1mth4ygithy	3zf3d5jjnfymug7cq1ucdwqrmo	ayb41zzfr3nrzq8x9w39eabrhw		Sure! I'll export all three sizes for each blog post. That makes it 12 images total. Will update the deadline to March 15.		{}		[]	[]	f	0	f	
1tw3ym747ffczfmd157pdxgfba	1773126781223	1773126781223	0	m16j1q6rkfdpxguuksz7wmpuba	5b4hke3753y73feti3hhtfbgiy	q3ij1tnz7pfcmjkw13u57kpyie		I'll draft a press release and blog post about this. Should be live by tomorrow.		{}		[]	[]	f	0	f	
qqd6qtamwi8bmbtwr5bezx39qw	1773126781112	1773126781314	1773126781314	udhm7t7fqfgc9k9funqdejmeea	5b4hke3753y73feti3hhtfbgiy		q3ij1tnz7pfcmjkw13u57kpyie	:mega: **Company Announcement**\n\nI'm thrilled to announce that TechCorp has been named one of the **Top 50 Places to Work in Tech** by TechReview Magazine! :trophy:\n\nThis achievement reflects our commitment to building an inclusive, innovative, and supportive workplace. Thank you all for making TechCorp a great place to work!\n\nWe'll be celebrating with a company-wide virtual happy hour this Friday at 4 PM. Details to follow.		{}		[]	[]	f	0	f	
zj5n1igz83g7bnoujg81u9c9kh	1773126781324	1773126781521	0	udhm7t7fqfgc9k9funqdejmeea	5b4hke3753y73feti3hhtfbgiy			:wave: **New Hire Announcement**\n\nPlease join me in welcoming our newest team members joining this month:\n\n- **Mike Ross** - Junior Developer (Engineering)\n- **Natalie Kim** - Technical Writer (Engineering)\n\nBoth will be going through onboarding this week. Please make them feel welcome and don't hesitate to reach out if you see them in the channels!\n\nOnboarding buddy assignments:\n- Mike → Jane Smith\n- Natalie → Frank Miller		{}		[]	[]	f	0	t	\N
gxy8xanwxtd8py184qqbzh5cac	1773126782037	1773126782037	0	6a4bti99g3rtdmx11dhnihhg6r	1s9nagudoiboirmb7ckj1mukfy	c3xjtk6dt7gg3puenbx5qtqz8r		I use a HHKB Professional Classic. The Topre switches are addictive once you get used to them.		{}		[]	[]	f	0	f	
c3xjtk6dt7gg3puenbx5qtqz8r	1773126781995	1773126782101	0	46fd55wk57bdzq89debc4cxugr	1s9nagudoiboirmb7ckj1mukfy			I found this amazing mechanical keyboard on sale - the Keychron Q1 Pro with Gateron Jupiter Banana switches. It types like a dream and the sound is so satisfying. Anyone else here a keyboard enthusiast?		{}		[]	[]	f	0	f	
dmpbf4epffrkmd9biy83m5qitw	1773126782132	1773126782243	0	dp4jszrpsjnjpjw1mth4ygithy	8k1ahz7c8pgmjyco414pgi5f4y			I tried a new recipe this weekend - Korean fried chicken with gochujang glaze. It turned out amazing! I'll bring some for the team lunch on Wednesday if anyone's interested :yum:		{}		[]	[]	f	0	f	
ktgb7pxapfgypqfdy5ef49xrmo	1773126782941	1773126782941	0	4zd57afzr3f4mbydt14j5mzqza	5swgwrkocprjmrngo4qj4o74io			Wow, thank you John! That means a lot. I've really enjoyed leading the technical direction for the project.		{}		[]	[]	f	0	f	
r3tnuxkzspr8md9bgfx86716zr	1773126780894	1773126780894	0	93n7axewi7n9xpsis8z5d99bre	4rt4rx5mt38b38y9ec93k89boo	ssjhm5cqwtgazfouy7phuxnyho		I'll send the intro email today. Their PM is Sarah Chen - she's very responsive. CC me on the thread.		{}		[]	[]	f	0	f	
1gjpx1hybpgbfqtxdz3yrpgsfw	1773126780953	1773126780953	0	dp4jszrpsjnjpjw1mth4ygithy	4rt4rx5mt38b38y9ec93k89boo	ssjhm5cqwtgazfouy7phuxnyho		I'll start on the whitepaper cover design and infographics. Frank, can you share the key stats I should highlight?		{}		[]	[]	f	0	f	
ssjhm5cqwtgazfouy7phuxnyho	1773126780875	1773126780953	0	m16j1q6rkfdpxguuksz7wmpuba	4rt4rx5mt38b38y9ec93k89boo			**March Content Calendar:**\n\n| Date | Type | Title | Status |\n|---|---|---|---|\n| Mar 11 | Blog | 5 Ways to Streamline Your Workflow | Draft Ready |\n| Mar 15 | Case Study | How Acme Corp Saved 40% with TechCorp | In Progress |\n| Mar 18 | Newsletter | Monthly Product Update - March | Not Started |\n| Mar 22 | Blog | The Future of Enterprise Collaboration | Outline Done |\n| Mar 25 | Whitepaper | 2024 Industry Trends Report | In Progress |\n| Mar 29 | Blog | Customer Spotlight: DataFlow Inc | Not Started |\n\n@emma.davis I need interview quotes from the Acme Corp PM for the case study. Can you intro me?		{}		[]	[]	f	0	f	
4nnbm8yretdr5e1tw45hxpr6tc	1773126782627	1773126782627	0	hacoqz1mijy8db1u95mwsgt6pe	i14jg6ym6tbfmpa93dq5usgrty	qkrfhk9y7idoxbohh8dzaxqaxo		On it! I'll add it to the IT Knowledge Base by end of day.		{}		[]	[]	f	0	f	
ewxppxk96py8brn8j6pk5zteia	1773126782695	1773126782695	0	46fd55wk57bdzq89debc4cxugr	i14jg6ym6tbfmpa93dq5usgrty	ydy7j6ux17n73y6cezo43mopay		Update: Jira is back to normal. The issue was caused by a runaway automation rule that was processing 10K tickets in a loop. I've disabled it and will work with the Jira admins to fix it.		{}		[]	[]	f	0	f	
byzf6nnqnbb6fbbsta4f1uh4or	1773126782786	1773126782786	0	4zd57afzr3f4mbydt14j5mzqza	h4d4ekghxin7bnutsuomgd776w	jba7dsp5apbq5pm4z575nndqfa		Mike, the dev setup guide is in our Engineering wiki: https://wiki.techcorp.com/dev-setup. I'll walk you through it in our 1:1 tomorrow.		{}		[]	[]	f	0	f	
4yr9d5eox38wfkaqbzm9pyx1gw	1773126782852	1773126782852	0	udhm7t7fqfgc9k9funqdejmeea	h4d4ekghxin7bnutsuomgd776w	jba7dsp5apbq5pm4z575nndqfa		Sorry about that Natalie! Here's the correct link: https://handbook.techcorp.com. I'll update the pinned post.		{}		[]	[]	f	0	f	
yxhboujortrcxyz4ih67bf6q6w	1773126782962	1773126782962	0	4zd57afzr3f4mbydt14j5mzqza	5swgwrkocprjmrngo4qj4o74io			I really appreciate your support. I'll make sure Project Alpha is a success. Let me know if you need anything from me for the submission.		{}		[]	[]	f	0	f	
5kc5ab44g3b6zezno8sa55y8fo	1773126782992	1773126782992	0	9mbmdxz1kidnmemmqi9ou5w1ah	ik8xxjatdfn75comxgxnq189iw			Emma, great results on the Q1 campaign! I showed the numbers to the CEO and she was very impressed.		{}		[]	[]	f	0	f	
k8myj7uiwffz7gufq149xjf4zr	1773126783006	1773126783006	0	93n7axewi7n9xpsis8z5d99bre	ik8xxjatdfn75comxgxnq189iw			That's wonderful to hear! The team really came together on this one. Frank's content strategy and Grace's design work were standout.		{}		[]	[]	f	0	f	
1kn56cs8o3g3pf37kyk5r8an4a	1773126783091	1773126783091	0	46fd55wk57bdzq89debc4cxugr	ofr41qz4pjdtiyzza51qu7bxny			Different IP range. Looks like it was a misconfigured test container that was running a webhook to an external service. I've shut it down and added egress filtering for staging.		{}		[]	[]	f	0	f	
bh9hcrzu8j817xe7tr3ajacxjw	1773126783102	1773126783102	0	g7r88gtyqjfdzgnwhr9xyumzce	ofr41qz4pjdtiyzza51qu7bxny			Thanks for the quick response. I'll update the security report. Let's also add egress allowlisting to our deployment checklist.		{}		[]	[]	f	0	f	
yids79qst3yiurj581ac8g47zw	1773126783130	1773126783130	0	6a4bti99g3rtdmx11dhnihhg6r	5xxxy5dojj8pmbg441q5og511e			Hey Mike! Ready for our pairing session tomorrow? We'll be working on the image loading optimization.		{}		[]	[]	f	0	f	
whi5d7iq93yczek5f3fayyd4ga	1773126783156	1773126783156	0	6a4bti99g3rtdmx11dhnihhg6r	5xxxy5dojj8pmbg441q5og511e			Blurhash is great! We actually considered it but went with next/image's built-in blur placeholder since we're already using Next.js. But good research!		{}		[]	[]	f	0	f	
hzcew17kup85pc4e63x9f7h58a	1773126783178	1773126783178	0	6a4bti99g3rtdmx11dhnihhg6r	5xxxy5dojj8pmbg441q5og511e			Perfect! Bring your laptop to the 3rd floor collaboration area. I'll book the space from 10-12.		{}		[]	[]	f	0	f	
35dnzm8awfdatmoo66ixcw33sh	1773126783231	1773126783231	0	udhm7t7fqfgc9k9funqdejmeea	e4yfhpb1rjbizxy8ygcf3u7w1r			Two areas flagged: work-life balance (some folks mentioned on-call stress) and career growth (junior devs want more mentorship). Overall though, the team is very happy.		{}		[]	[]	f	0	f	
7bodxmdnbinspkh48nfee9b8eh	1773126783279	1773126783279	0	3bekgg684bb5iq6tfq1h95az3r	qk34pb8dffr4ibk69r3xkzmy9o			Charlie, I found another edge case in the payment flow. When a user applies two discount codes simultaneously, the second one overwrites the first instead of stacking.		{}		[]	[]	f	0	f	
amyjhumqbbdwpkpoiqbkog8ppo	1773126783370	1773126783370	0	x916bcascjyyjrc5y8e5hbrgna	rffhn6t6jbfkiebs9cmahu7gae			Quick sync about the Project Alpha demo on March 28. Kevin, what are the client's main expectations?		{}		[]	[]	f	0	f	
ifmwji4ostr1bjguq3o6zc3iqw	1773126783387	1773126783387	0	9mbmdxz1kidnmemmqi9ou5w1ah	rffhn6t6jbfkiebs9cmahu7gae			They want to see: 1) The authentication flow with SSO, 2) The dashboard with real-time data, 3) The notification center. They're particularly excited about the real-time features.		{}		[]	[]	f	0	f	
9hexqk8fttdc5nj6bo59cdbymr	1773126783470	1773126783470	0	4zd57afzr3f4mbydt14j5mzqza	rffhn6t6jbfkiebs9cmahu7gae			Will do. I'll set up a separate staging instance with the demo data preloaded.		{}		[]	[]	f	0	f	
po71fwaigj8s5kchtqdoojp6se	1773126783482	1773126783482	0	9mbmdxz1kidnmemmqi9ou5w1ah	rffhn6t6jbfkiebs9cmahu7gae			Perfect. I'll also prepare the slide deck with the product roadmap. The client wants to know about upcoming features for Q3-Q4.		{}		[]	[]	f	0	f	
74r39eijx3fjxe89tjpw8swqdc	1773126783633	1773126783633	0	7e4ojpbykjntdmpu94y5ekub1c	f3kpgwu4biddpbpyf18nbu6mpe			Weekly analytics report is ready and shared in #analytics. Key highlight: organic search traffic is up 18% month-over-month. Our SEO efforts are paying off.		{}	#analytics	[]	[]	f	0	f	
1q1f84cbzpg3metmbgn74g81hh	1773126783653	1773126783653	0	93n7axewi7n9xpsis8z5d99bre	f3kpgwu4biddpbpyf18nbu6mpe			Great progress everyone! Grace, follow up with DataFlow today on the logo. Ivy, can you add a section on competitor analysis to next week's report?		{}		[]	[]	f	0	f	
td41en7gzfb1pq1iy9csrdug4c	1773126783665	1773126783665	0	7e4ojpbykjntdmpu94y5ekub1c	f3kpgwu4biddpbpyf18nbu6mpe			Sure thing. I'll pull data from SEMrush and SimilarWeb for the competitive analysis.		{}		[]	[]	f	0	f	
q3ij1tnz7pfcmjkw13u57kpyie	1773126781112	1773126781314	0	udhm7t7fqfgc9k9funqdejmeea	5b4hke3753y73feti3hhtfbgiy			:mega: **Company Announcement**\n\nI'm thrilled to announce that TechCorp has been named one of the **Top 50 Places to Work in Tech** by TechReview Magazine! :trophy:\n\nThis achievement reflects our commitment to building an inclusive, innovative, and supportive workplace. Thank you all for making TechCorp a great place to work!\n\nWe'll be celebrating with a company-wide virtual happy hour this Friday at 4 PM. Details to follow.		{}		[]	[]	f	0	t	\N
uufw1pyz3387jj17m5sn3ffdie	1773126781368	1773126781368	0	m16j1q6rkfdpxguuksz7wmpuba	5b4hke3753y73feti3hhtfbgiy	zj5n1igz83g7bnoujg81u9c9kh		Welcome Natalie! I'll give you a tour of our content systems and documentation tools. See you Monday!		{}		[]	[]	f	0	f	
8uq51fxo678iimsg6kt8ko47qo	1773126781433	1773126781433	0	hacoqz1mijy8db1u95mwsgt6pe	5b4hke3753y73feti3hhtfbgiy	zj5n1igz83g7bnoujg81u9c9kh		Thank you for the warm welcome! I've already started reading through the existing docs. Really impressed with the codebase!		{}		[]	[]	f	0	f	
ew7a6ozya388bxdgqfk7u6wsxe	1773126781324	1773126781521	1773126781521	udhm7t7fqfgc9k9funqdejmeea	5b4hke3753y73feti3hhtfbgiy		zj5n1igz83g7bnoujg81u9c9kh	:wave: **New Hire Announcement**\n\nPlease join me in welcoming our newest team members joining this month:\n\n- **Mike Ross** - Junior Developer (Engineering)\n- **Natalie Kim** - Technical Writer (Engineering)\n\nBoth will be going through onboarding this week. Please make them feel welcome and don't hesitate to reach out if you see them in the channels!\n\nOnboarding buddy assignments:\n- Mike → Jane Smith\n- Natalie → Frank Miller		{}		[]	[]	f	0	f	
99umt5rf8fffbn78p3q8zkfu4w	1773126781544	1773126781544	0	ccmjk1p1abffx87a4zni7n4uoh	5b4hke3753y73feti3hhtfbgiy	ituauyjmk7n35jriu16fre44eh		Question for the infra section: Are we still planning to migrate from AWS ECS to EKS in Q2?		{}		[]	[]	f	0	f	
98bzoc5ba3gstmj4164tbm1p4y	1773126781603	1773126781603	0	3bekgg684bb5iq6tfq1h95az3r	5b4hke3753y73feti3hhtfbgiy	ituauyjmk7n35jriu16fre44eh		Can we also discuss the testing infrastructure? I'd like to propose adding visual regression testing to our CI pipeline.		{}		[]	[]	f	0	f	
ituauyjmk7n35jriu16fre44eh	1773126781529	1773126781636	0	x916bcascjyyjrc5y8e5hbrgna	5b4hke3753y73feti3hhtfbgiy			:calendar: **Engineering All-Hands - March 14, 10:00 AM**\n\nAgenda:\n1. Q1 OKR Review\n2. Project Alpha demo and timeline\n3. Project Beta kickoff\n4. Infrastructure roadmap update\n5. Open Q&A\n\nPlease submit your questions in advance using the thread below. Recording will be available for those who can't attend.		{}		[]	[]	f	0	f	
i41yafdyq3bsxdbpfqhfkz1jyc	1773126781690	1773126781690	0	ccmjk1p1abffx87a4zni7n4uoh	1s9nagudoiboirmb7ckj1mukfy	sd8n1zw1obngingpzu9dnpz9xe		YES! And the scene where they deployed to production on a Friday night... I felt that in my soul :skull:		{}		[]	[]	f	0	f	
f57gugone7rqjdh6atfdun9kbe	1773126781747	1773126781747	0	4zd57afzr3f4mbydt14j5mzqza	1s9nagudoiboirmb7ckj1mukfy	sd8n1zw1obngingpzu9dnpz9xe		The rubber duck debugging scene in episode 3 is peak comedy :duck:		{}		[]	[]	f	0	f	
sd8n1zw1obngingpzu9dnpz9xe	1773126781672	1773126781781	0	6a4bti99g3rtdmx11dhnihhg6r	1s9nagudoiboirmb7ckj1mukfy			Anyone else watching the new season of 'The Developer' on Netflix? The episode about the startup pivoting from B2B to B2C was SO relatable :joy:		{}		[]	[]	f	0	f	
bc3mmchumibubxikjfrgb8ztdo	1773126781831	1773126781831	0	dp4jszrpsjnjpjw1mth4ygithy	1s9nagudoiboirmb7ckj1mukfy	bq74ebs4zbyn8msgbpijcfj5rc		Count me in! I've been trying to learn the rosetta pour for months.		{}		[]	[]	f	0	f	
a4fztqz4h7y9uk93j5c4hao1uy	1773126781887	1773126781887	0	93n7axewi7n9xpsis8z5d99bre	1s9nagudoiboirmb7ckj1mukfy	bq74ebs4zbyn8msgbpijcfj5rc		I'll bring some specialty beans from that local roaster I mentioned. They have an amazing Ethiopian single origin.		{}		[]	[]	f	0	f	
ocubq4zospfnuyorsj65ytbbar	1773126781960	1773126781960	0	m16j1q6rkfdpxguuksz7wmpuba	1s9nagudoiboirmb7ckj1mukfy	bq74ebs4zbyn8msgbpijcfj5rc		Great idea Diana! I'll set up a camera at the coffee station and stream it on Zoom.		{}		[]	[]	f	0	f	
bq74ebs4zbyn8msgbpijcfj5rc	1773126781817	1773126781960	0	m16j1q6rkfdpxguuksz7wmpuba	1s9nagudoiboirmb7ckj1mukfy			Our office coffee machine has been upgraded! We now have a proper espresso machine in the kitchen. Who wants to learn latte art? I'm hosting an informal session this Thursday during lunch :coffee:		{}		[]	[]	f	0	f	
udxp4waofjf65kecnnb1959fpa	1773126782009	1773126782009	0	ccmjk1p1abffx87a4zni7n4uoh	1s9nagudoiboirmb7ckj1mukfy	c3xjtk6dt7gg3puenbx5qtqz8r		Fellow mech keyboard nerd here! I'm rocking a ZSA Moonlander with Kailh Box Whites. Split ergonomic is the way to go.		{}		[]	[]	f	0	f	
8zgtrf57nbd6ufityossynaoyc	1773126782067	1773126782067	0	4zd57afzr3f4mbydt14j5mzqza	1s9nagudoiboirmb7ckj1mukfy	c3xjtk6dt7gg3puenbx5qtqz8r		You all are making me want to upgrade from my basic Apple keyboard... any recommendations for a first mechanical?		{}		[]	[]	f	0	f	
pkeng1g3k7n57xdgm68k65r46y	1773126782179	1773126782179	0	ccmjk1p1abffx87a4zni7n4uoh	8k1ahz7c8pgmjyco414pgi5f4y	dmpbf4epffrkmd9biy83m5qitw		Grace's cooking is legendary. Last time she brought homemade ramen and I still think about it.		{}		[]	[]	f	0	f	
5f1eqpqt7fnombbdi4thssq4sy	1773126782243	1773126782243	0	dp4jszrpsjnjpjw1mth4ygithy	8k1ahz7c8pgmjyco414pgi5f4y	dmpbf4epffrkmd9biy83m5qitw		Of course! The secret is double-frying at different temperatures. I'll share the full recipe in a doc after lunch.		{}		[]	[]	f	0	f	
w4f989j9s7br5nnz7s4oynydry	1773126782293	1773126782293	0	6a4bti99g3rtdmx11dhnihhg6r	7aqugqd4dprbzcfcnm8ouuqczc	8p613yhn3tr5zjiuy8ebxazfih		I'll be at the team lunch and volunteer day! :raised_hand:		{}		[]	[]	f	0	f	
sc9ckir4u3n75nqw6i6ttj3wcw	1773126782352	1773126782352	0	cxtqjdhuqiydtmdmtdc1mesbfo	7aqugqd4dprbzcfcnm8ouuqczc	8p613yhn3tr5zjiuy8ebxazfih		Excited for trivia night! Is it general knowledge or tech-themed?		{}		[]	[]	f	0	f	
7c9cox7rttg4bb1jx4fmrrmz8h	1773126782472	1773126782472	0	udhm7t7fqfgc9k9funqdejmeea	7aqugqd4dprbzcfcnm8ouuqczc	8p613yhn3tr5zjiuy8ebxazfih		We have 20 spots for the food bank. First come, first served. 12 signed up so far.		{}		[]	[]	f	0	f	
a1qqgcxwa3dujmnyz5xm735dyy	1773126782597	1773126782597	0	46fd55wk57bdzq89debc4cxugr	i14jg6ym6tbfmpa93dq5usgrty	qkrfhk9y7idoxbohh8dzaxqaxo		Glad it worked! I should add this to our IT FAQ. @natalie.kim could you add a troubleshooting section for VPN on the latest macOS?		{}		[]	[]	f	0	f	
7c9u8kanbbdhig1w4nsxy8b7qw	1773126782420	1773126782420	0	m16j1q6rkfdpxguuksz7wmpuba	7aqugqd4dprbzcfcnm8ouuqczc	8p613yhn3tr5zjiuy8ebxazfih		Volunteer day sounds great! How many spots are available?		{}		[]	[]	f	0	f	
8p613yhn3tr5zjiuy8ebxazfih	1773126782274	1773126782516	0	udhm7t7fqfgc9k9funqdejmeea	7aqugqd4dprbzcfcnm8ouuqczc			:calendar: **Upcoming Events:**\n\n**March 14** - Engineering All-Hands (10:00 AM, Virtual)\n**March 15** - Team Trivia Night (6:00 PM, Slack #trivia-night)\n**March 20** - Team Lunch at Bella Italia (12:30 PM)\n**March 22** - Volunteer Day at City Food Bank (9:00 AM - 1:00 PM)\n**March 28** - Project Alpha Customer Demo (2:00 PM, Conference Room A)\n**March 31** - Q1 Company Town Hall (3:00 PM, Virtual)\n\nRSVP in the thread below! :point_down:		{}	#trivia-night	[]	[]	f	0	t	\N
9w6a6543j7n18kkhpnz13tei5e	1773126782572	1773126782572	0	cxtqjdhuqiydtmdmtdc1mesbfo	i14jg6ym6tbfmpa93dq5usgrty	qkrfhk9y7idoxbohh8dzaxqaxo		That fixed it! The security permission was the issue. Thanks Bob!		{}		[]	[]	f	0	f	
ao41rg48pirnim9q5u4ot1iaoa	1773126782668	1773126782668	0	46fd55wk57bdzq89debc4cxugr	i14jg6ym6tbfmpa93dq5usgrty	ydy7j6ux17n73y6cezo43mopay		Let me check the Jira server status... Yep, it's running at 95% memory utilization. I'm restarting the service now. Should be back to normal in 5 minutes.		{}		[]	[]	f	0	f	
mkn9sjhjdtyzmmpmtejx1ec8qy	1773126782720	1773126782720	0	93n7axewi7n9xpsis8z5d99bre	i14jg6ym6tbfmpa93dq5usgrty	ydy7j6ux17n73y6cezo43mopay		It's fast again now. Thanks for the quick fix Bob!		{}		[]	[]	f	0	f	
7kmiji6pktrwxx1z69nudfbwdy	1773126782817	1773126782817	0	hacoqz1mijy8db1u95mwsgt6pe	h4d4ekghxin7bnutsuomgd776w	jba7dsp5apbq5pm4z575nndqfa		The Employee Handbook link doesn't seem to work. Can someone share the updated URL?		{}		[]	[]	f	0	f	
go3c6ec97bbtick3ufnbstmfsy	1773126782544	1773126782544	0	46fd55wk57bdzq89debc4cxugr	i14jg6ym6tbfmpa93dq5usgrty	qkrfhk9y7idoxbohh8dzaxqaxo		Hi Mike, this is a known issue with the latest macOS update. Try this:\n1. Go to System Settings → Privacy & Security → Allow GlobalProtect\n2. Restart the GlobalProtect service\n3. Connect to gateway: `vpn.techcorp.com`\n\nIf that doesn't work, I'll remote in and take a look.		{}		[]	[]	f	0	f	
ydy7j6ux17n73y6cezo43mopay	1773126782654	1773126782720	0	93n7axewi7n9xpsis8z5d99bre	i14jg6ym6tbfmpa93dq5usgrty			Is anyone else having issues with Jira loading slowly today? It's taking 20+ seconds to load any page. Cleared cache and tried different browsers.		{}		[]	[]	f	0	f	
6gmh65mtwfnq3dbtd5so6oifgy	1773126782757	1773126782757	0	cxtqjdhuqiydtmdmtdc1mesbfo	h4d4ekghxin7bnutsuomgd776w	jba7dsp5apbq5pm4z575nndqfa		Thanks Henry! I've completed most of the checklist. Just need to finish the security training. Where do I find the development environment setup guide?		{}		[]	[]	f	0	f	
jba7dsp5apbq5pm4z575nndqfa	1773126782742	1773126782896	0	udhm7t7fqfgc9k9funqdejmeea	h4d4ekghxin7bnutsuomgd776w			:wave: **Welcome to TechCorp!**\n\nHere's your onboarding checklist:\n\n:white_check_mark: Set up your laptop and accounts (IT will help)\n:white_check_mark: Join all relevant Mattermost teams and channels\n:white_check_mark: Read the Employee Handbook (link in pinned posts)\n:white_check_mark: Meet your onboarding buddy\n:white_check_mark: Complete security training by end of Week 1\n:white_check_mark: Attend your first team standup\n:white_check_mark: Set up development environment (Engineering only)\n:white_check_mark: Schedule 1:1s with your manager and skip-level\n\nDon't hesitate to ask questions here or in #help-desk!		{}	#help-desk	[]	[]	f	0	t	\N
sjo6rkmyw7yp8qfqk4ows6h5qr	1773126782742	1773126782896	1773126782896	udhm7t7fqfgc9k9funqdejmeea	h4d4ekghxin7bnutsuomgd776w		jba7dsp5apbq5pm4z575nndqfa	:wave: **Welcome to TechCorp!**\n\nHere's your onboarding checklist:\n\n:white_check_mark: Set up your laptop and accounts (IT will help)\n:white_check_mark: Join all relevant Mattermost teams and channels\n:white_check_mark: Read the Employee Handbook (link in pinned posts)\n:white_check_mark: Meet your onboarding buddy\n:white_check_mark: Complete security training by end of Week 1\n:white_check_mark: Attend your first team standup\n:white_check_mark: Set up development environment (Engineering only)\n:white_check_mark: Schedule 1:1s with your manager and skip-level\n\nDon't hesitate to ask questions here or in #help-desk!		{}	#help-desk	[]	[]	f	0	f	
6ttrdjp8qbgj8f5598zqc158da	1773126783028	1773126783028	0	93n7axewi7n9xpsis8z5d99bre	ik8xxjatdfn75comxgxnq189iw			Definitely! I'll have the updated plan with projected ROI ready by Thursday EOD so you have time to review before presenting to leadership.		{}		[]	[]	f	0	f	
twiges6xhtn55pr8fozip9ykdy	1773126783055	1773126783055	0	g7r88gtyqjfdzgnwhr9xyumzce	ofr41qz4pjdtiyzza51qu7bxny			Bob, I noticed some unusual outbound traffic patterns from the staging environment last night. Can you check the firewall logs?		{}		[]	[]	f	0	f	
mc17yq4ur3g5dqyo3dktzotpza	1773126783070	1773126783070	0	46fd55wk57bdzq89debc4cxugr	ofr41qz4pjdtiyzza51qu7bxny			Checking now... I see it. There's a container making requests to an external IP that's not in our allowlist. Let me isolate it.		{}		[]	[]	f	0	f	
xjk419fy7trpumnwp67rajebry	1773126783081	1773126783081	0	g7r88gtyqjfdzgnwhr9xyumzce	ofr41qz4pjdtiyzza51qu7bxny			Good. Can you also check if it matches the IP range from the credential stuffing attempt we saw last week?		{}		[]	[]	f	0	f	
11c9oqax4b879fg4n7qqs8tiko	1773126783146	1773126783146	0	cxtqjdhuqiydtmdmtdc1mesbfo	5xxxy5dojj8pmbg441q5og511e			Yes! I've been reading up on progressive image loading techniques. I found a really cool approach using blurhash.		{}		[]	[]	f	0	f	
mziubnoitpfkxq6fwafpk5qeke	1773126783167	1773126783167	0	cxtqjdhuqiydtmdmtdc1mesbfo	5xxxy5dojj8pmbg441q5og511e			Makes sense to use what's already in the framework. I'll prepare some test images and a benchmark script so we can measure the improvement.		{}		[]	[]	f	0	f	
o4uum5jbqjnn3duxj3a84awyxo	1773126783206	1773126783206	0	udhm7t7fqfgc9k9funqdejmeea	e4yfhpb1rjbizxy8ygcf3u7w1r			John, just a heads up - the annual employee satisfaction survey results are in. Engineering scored 4.5/5 overall, highest in the company!		{}		[]	[]	f	0	f	
xo5uo6y5xjnqtx9mo7g9y6ezky	1773126783221	1773126783221	0	x916bcascjyyjrc5y8e5hbrgna	e4yfhpb1rjbizxy8ygcf3u7w1r			That's great to hear! Any areas where we can improve?		{}		[]	[]	f	0	f	
butyteyb6jddjfcm8c4p7m8xfw	1773126783242	1773126783242	0	x916bcascjyyjrc5y8e5hbrgna	e4yfhpb1rjbizxy8ygcf3u7w1r			Valid feedback. I'll address the on-call rotation - maybe we can reduce it from weekly to bi-weekly. And I'll set up a formal mentorship program pairing seniors with juniors.		{}		[]	[]	f	0	f	
nmfwpsn1hfbj9k1wxh7aowg9rr	1773126783253	1773126783253	0	udhm7t7fqfgc9k9funqdejmeea	e4yfhpb1rjbizxy8ygcf3u7w1r			Those sound like great initiatives. Let me know if HR can help facilitate the mentorship program. We have some templates and frameworks from other departments.		{}		[]	[]	f	0	f	
69p1xhgdu7n13e484d1d39cbka	1773126783296	1773126783296	0	ccmjk1p1abffx87a4zni7n4uoh	qk34pb8dffr4ibk69r3xkzmy9o			That's actually by design - we only allow one discount code per order. But I agree the UX is confusing. The user should see a message saying 'Only one discount code allowed'.		{}		[]	[]	f	0	f	
suecp46eyirztr76wfch3c3rmh	1773126783307	1773126783307	0	3bekgg684bb5iq6tfq1h95az3r	qk34pb8dffr4ibk69r3xkzmy9o			Ah got it. Then it's a UX bug, not a logic bug. I'll update the ticket and reassign to Alice for the frontend fix.		{}		[]	[]	f	0	f	
tcxcqomsstrqzx9qt3qkum1x3o	1773126783318	1773126783318	0	ccmjk1p1abffx87a4zni7n4uoh	qk34pb8dffr4ibk69r3xkzmy9o			Good call. I'll also add a validation check on the backend to return a proper error message instead of silently overwriting. Belt and suspenders approach.		{}		[]	[]	f	0	f	
hdx8ek1xjj8gpxa1kk7c6bhrfc	1773126783433	1773126783433	0	4zd57afzr3f4mbydt14j5mzqza	rffhn6t6jbfkiebs9cmahu7gae			Auth flow will be ready. For the dashboard, I suggest we use mock data that mirrors their actual use case. Mike's heatmap component would be a nice touch to show.		{}		[]	[]	f	0	f	
c8d4s7yczidn7d1hkerx336xae	1773126783459	1773126783459	0	x916bcascjyyjrc5y8e5hbrgna	rffhn6t6jbfkiebs9cmahu7gae			Agreed. Let's do a dry run on March 26. I'll book the conference room. Jane, can you prepare the demo environment?		{}		[]	[]	f	0	f	
36ob14ixu7defj98hticw1o8bo	1773126783542	1773126783542	0	93n7axewi7n9xpsis8z5d99bre	f3kpgwu4biddpbpyf18nbu6mpe			Marketing standup! Quick updates from everyone please.		{}		[]	[]	f	0	f	
q4nxfny673fk3rcfqierzcdq9c	1773126783576	1773126783576	0	m16j1q6rkfdpxguuksz7wmpuba	f3kpgwu4biddpbpyf18nbu6mpe			Blog post 'Streamline Your Workflow' is published and performing well - 1,200 views in the first 24 hours. Working on the Acme Corp case study, interview scheduled for Wednesday.		{}		[]	[]	f	0	f	
8pzmcmpsu3b1pqdj3w5z6hm1br	1773126783600	1773126783600	0	dp4jszrpsjnjpjw1mth4ygithy	f3kpgwu4biddpbpyf18nbu6mpe			Finished 3 of 4 blog header images. The DataFlow spotlight one is pending their logo approval. Also completed the Instagram carousel for tomorrow's post.		{}		[]	[]	f	0	f	
\.


--
-- Data for Name: postspriority; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.postspriority (postid, channelid, priority, requestedack, persistentnotifications) FROM stdin;
\.


--
-- Data for Name: preferences; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.preferences (userid, category, name, value) FROM stdin;
7kq76ce63id48nkz4hcp5rg3xh	recommended_next_steps	hide	false
7kq76ce63id48nkz4hcp5rg3xh	tutorial_step	7kq76ce63id48nkz4hcp5rg3xh	0
7kq76ce63id48nkz4hcp5rg3xh	system_notice	GMasDM	true
x916bcascjyyjrc5y8e5hbrgna	recommended_next_steps	hide	false
x916bcascjyyjrc5y8e5hbrgna	tutorial_step	x916bcascjyyjrc5y8e5hbrgna	0
x916bcascjyyjrc5y8e5hbrgna	system_notice	GMasDM	true
4zd57afzr3f4mbydt14j5mzqza	recommended_next_steps	hide	false
4zd57afzr3f4mbydt14j5mzqza	tutorial_step	4zd57afzr3f4mbydt14j5mzqza	0
4zd57afzr3f4mbydt14j5mzqza	system_notice	GMasDM	true
46fd55wk57bdzq89debc4cxugr	recommended_next_steps	hide	false
46fd55wk57bdzq89debc4cxugr	tutorial_step	46fd55wk57bdzq89debc4cxugr	0
46fd55wk57bdzq89debc4cxugr	system_notice	GMasDM	true
6a4bti99g3rtdmx11dhnihhg6r	recommended_next_steps	hide	false
6a4bti99g3rtdmx11dhnihhg6r	tutorial_step	6a4bti99g3rtdmx11dhnihhg6r	0
6a4bti99g3rtdmx11dhnihhg6r	system_notice	GMasDM	true
ccmjk1p1abffx87a4zni7n4uoh	recommended_next_steps	hide	false
ccmjk1p1abffx87a4zni7n4uoh	tutorial_step	ccmjk1p1abffx87a4zni7n4uoh	0
ccmjk1p1abffx87a4zni7n4uoh	system_notice	GMasDM	true
3bekgg684bb5iq6tfq1h95az3r	recommended_next_steps	hide	false
3bekgg684bb5iq6tfq1h95az3r	tutorial_step	3bekgg684bb5iq6tfq1h95az3r	0
3bekgg684bb5iq6tfq1h95az3r	system_notice	GMasDM	true
93n7axewi7n9xpsis8z5d99bre	recommended_next_steps	hide	false
93n7axewi7n9xpsis8z5d99bre	tutorial_step	93n7axewi7n9xpsis8z5d99bre	0
93n7axewi7n9xpsis8z5d99bre	system_notice	GMasDM	true
m16j1q6rkfdpxguuksz7wmpuba	recommended_next_steps	hide	false
m16j1q6rkfdpxguuksz7wmpuba	tutorial_step	m16j1q6rkfdpxguuksz7wmpuba	0
m16j1q6rkfdpxguuksz7wmpuba	system_notice	GMasDM	true
dp4jszrpsjnjpjw1mth4ygithy	recommended_next_steps	hide	false
dp4jszrpsjnjpjw1mth4ygithy	tutorial_step	dp4jszrpsjnjpjw1mth4ygithy	0
dp4jszrpsjnjpjw1mth4ygithy	system_notice	GMasDM	true
udhm7t7fqfgc9k9funqdejmeea	recommended_next_steps	hide	false
udhm7t7fqfgc9k9funqdejmeea	tutorial_step	udhm7t7fqfgc9k9funqdejmeea	0
udhm7t7fqfgc9k9funqdejmeea	system_notice	GMasDM	true
7e4ojpbykjntdmpu94y5ekub1c	recommended_next_steps	hide	false
7e4ojpbykjntdmpu94y5ekub1c	tutorial_step	7e4ojpbykjntdmpu94y5ekub1c	0
7e4ojpbykjntdmpu94y5ekub1c	system_notice	GMasDM	true
9mbmdxz1kidnmemmqi9ou5w1ah	recommended_next_steps	hide	false
9mbmdxz1kidnmemmqi9ou5w1ah	tutorial_step	9mbmdxz1kidnmemmqi9ou5w1ah	0
9mbmdxz1kidnmemmqi9ou5w1ah	system_notice	GMasDM	true
g7r88gtyqjfdzgnwhr9xyumzce	recommended_next_steps	hide	false
g7r88gtyqjfdzgnwhr9xyumzce	tutorial_step	g7r88gtyqjfdzgnwhr9xyumzce	0
g7r88gtyqjfdzgnwhr9xyumzce	system_notice	GMasDM	true
cxtqjdhuqiydtmdmtdc1mesbfo	recommended_next_steps	hide	false
cxtqjdhuqiydtmdmtdc1mesbfo	tutorial_step	cxtqjdhuqiydtmdmtdc1mesbfo	0
cxtqjdhuqiydtmdmtdc1mesbfo	system_notice	GMasDM	true
hacoqz1mijy8db1u95mwsgt6pe	recommended_next_steps	hide	false
hacoqz1mijy8db1u95mwsgt6pe	tutorial_step	hacoqz1mijy8db1u95mwsgt6pe	0
hacoqz1mijy8db1u95mwsgt6pe	system_notice	GMasDM	true
\.


--
-- Data for Name: productnoticeviewstate; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.productnoticeviewstate (userid, noticeid, viewed, "timestamp") FROM stdin;
7kq76ce63id48nkz4hcp5rg3xh	gfycat_deprecation_7.8	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	gif_deprecation_7.9_7.10	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	gfycat_deprecation_8.0	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	gfycat_deprecation_8.1	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	server_upgrade_v11.4	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	patch_upgrade	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	patch_upgrade2	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	crt-admin-disabled	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	crt-admin-default_off	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	crt-user-default-on	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	crt-user-always-on	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	bleve_deprecation	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	certificate_deprecation	1	1773126751
7kq76ce63id48nkz4hcp5rg3xh	unsupported-server-v5.37	1	1773126751
x916bcascjyyjrc5y8e5hbrgna	gfycat_deprecation_7.8	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	gif_deprecation_7.9_7.10	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	gfycat_deprecation_8.0	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	gfycat_deprecation_8.1	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	server_upgrade_v11.4	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	patch_upgrade	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	patch_upgrade2	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	crt-admin-disabled	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	crt-admin-default_off	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	crt-user-default-on	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	crt-user-always-on	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	bleve_deprecation	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	certificate_deprecation	1	1773126756
x916bcascjyyjrc5y8e5hbrgna	unsupported-server-v5.37	1	1773126756
4zd57afzr3f4mbydt14j5mzqza	gfycat_deprecation_7.8	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	gif_deprecation_7.9_7.10	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	gfycat_deprecation_8.0	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	gfycat_deprecation_8.1	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	server_upgrade_v11.4	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	patch_upgrade	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	patch_upgrade2	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	crt-admin-disabled	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	crt-admin-default_off	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	crt-user-default-on	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	crt-user-always-on	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	bleve_deprecation	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	certificate_deprecation	1	1773126757
4zd57afzr3f4mbydt14j5mzqza	unsupported-server-v5.37	1	1773126757
46fd55wk57bdzq89debc4cxugr	gfycat_deprecation_7.8	1	1773126757
46fd55wk57bdzq89debc4cxugr	gif_deprecation_7.9_7.10	1	1773126757
46fd55wk57bdzq89debc4cxugr	gfycat_deprecation_8.0	1	1773126757
46fd55wk57bdzq89debc4cxugr	gfycat_deprecation_8.1	1	1773126757
46fd55wk57bdzq89debc4cxugr	server_upgrade_v11.4	1	1773126757
46fd55wk57bdzq89debc4cxugr	patch_upgrade	1	1773126757
46fd55wk57bdzq89debc4cxugr	patch_upgrade2	1	1773126757
46fd55wk57bdzq89debc4cxugr	crt-admin-disabled	1	1773126757
46fd55wk57bdzq89debc4cxugr	crt-admin-default_off	1	1773126757
46fd55wk57bdzq89debc4cxugr	crt-user-default-on	1	1773126757
46fd55wk57bdzq89debc4cxugr	crt-user-always-on	1	1773126757
46fd55wk57bdzq89debc4cxugr	bleve_deprecation	1	1773126757
46fd55wk57bdzq89debc4cxugr	certificate_deprecation	1	1773126757
46fd55wk57bdzq89debc4cxugr	unsupported-server-v5.37	1	1773126757
6a4bti99g3rtdmx11dhnihhg6r	gfycat_deprecation_7.8	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	gif_deprecation_7.9_7.10	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	gfycat_deprecation_8.0	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	gfycat_deprecation_8.1	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	server_upgrade_v11.4	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	patch_upgrade	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	patch_upgrade2	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	crt-admin-disabled	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	crt-admin-default_off	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	crt-user-default-on	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	crt-user-always-on	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	bleve_deprecation	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	certificate_deprecation	1	1773126758
6a4bti99g3rtdmx11dhnihhg6r	unsupported-server-v5.37	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	gfycat_deprecation_7.8	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	gif_deprecation_7.9_7.10	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	gfycat_deprecation_8.0	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	gfycat_deprecation_8.1	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	server_upgrade_v11.4	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	patch_upgrade	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	patch_upgrade2	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	crt-admin-disabled	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	crt-admin-default_off	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	crt-user-default-on	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	crt-user-always-on	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	bleve_deprecation	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	certificate_deprecation	1	1773126758
ccmjk1p1abffx87a4zni7n4uoh	unsupported-server-v5.37	1	1773126758
3bekgg684bb5iq6tfq1h95az3r	gfycat_deprecation_7.8	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	gif_deprecation_7.9_7.10	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	gfycat_deprecation_8.0	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	gfycat_deprecation_8.1	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	server_upgrade_v11.4	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	patch_upgrade	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	patch_upgrade2	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	crt-admin-disabled	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	crt-admin-default_off	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	crt-user-default-on	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	crt-user-always-on	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	bleve_deprecation	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	certificate_deprecation	1	1773126759
3bekgg684bb5iq6tfq1h95az3r	unsupported-server-v5.37	1	1773126759
7e4ojpbykjntdmpu94y5ekub1c	gfycat_deprecation_7.8	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	gif_deprecation_7.9_7.10	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	gfycat_deprecation_8.0	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	gfycat_deprecation_8.1	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	server_upgrade_v11.4	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	patch_upgrade	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	patch_upgrade2	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	crt-admin-disabled	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	crt-admin-default_off	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	crt-user-default-on	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	crt-user-always-on	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	bleve_deprecation	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	certificate_deprecation	1	1773126761
7e4ojpbykjntdmpu94y5ekub1c	unsupported-server-v5.37	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	gfycat_deprecation_7.8	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	gif_deprecation_7.9_7.10	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	gfycat_deprecation_8.0	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	gfycat_deprecation_8.1	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	server_upgrade_v11.4	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	patch_upgrade	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	patch_upgrade2	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	crt-admin-disabled	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	crt-admin-default_off	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	crt-user-default-on	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	crt-user-always-on	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	bleve_deprecation	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	certificate_deprecation	1	1773126761
9mbmdxz1kidnmemmqi9ou5w1ah	unsupported-server-v5.37	1	1773126761
cxtqjdhuqiydtmdmtdc1mesbfo	gfycat_deprecation_7.8	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	gif_deprecation_7.9_7.10	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	gfycat_deprecation_8.0	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	gfycat_deprecation_8.1	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	server_upgrade_v11.4	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	patch_upgrade	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	patch_upgrade2	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	crt-admin-disabled	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	crt-admin-default_off	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	crt-user-default-on	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	crt-user-always-on	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	bleve_deprecation	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	certificate_deprecation	1	1773126762
cxtqjdhuqiydtmdmtdc1mesbfo	unsupported-server-v5.37	1	1773126762
hacoqz1mijy8db1u95mwsgt6pe	gfycat_deprecation_7.8	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	gif_deprecation_7.9_7.10	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	gfycat_deprecation_8.0	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	gfycat_deprecation_8.1	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	server_upgrade_v11.4	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	patch_upgrade	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	patch_upgrade2	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	crt-admin-disabled	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	crt-admin-default_off	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	crt-user-default-on	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	crt-user-always-on	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	bleve_deprecation	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	certificate_deprecation	1	1773126763
hacoqz1mijy8db1u95mwsgt6pe	unsupported-server-v5.37	1	1773126763
93n7axewi7n9xpsis8z5d99bre	gfycat_deprecation_7.8	1	1773126759
93n7axewi7n9xpsis8z5d99bre	gif_deprecation_7.9_7.10	1	1773126759
93n7axewi7n9xpsis8z5d99bre	gfycat_deprecation_8.0	1	1773126759
93n7axewi7n9xpsis8z5d99bre	gfycat_deprecation_8.1	1	1773126759
93n7axewi7n9xpsis8z5d99bre	server_upgrade_v11.4	1	1773126759
93n7axewi7n9xpsis8z5d99bre	patch_upgrade	1	1773126759
93n7axewi7n9xpsis8z5d99bre	patch_upgrade2	1	1773126759
93n7axewi7n9xpsis8z5d99bre	crt-admin-disabled	1	1773126759
93n7axewi7n9xpsis8z5d99bre	crt-admin-default_off	1	1773126759
93n7axewi7n9xpsis8z5d99bre	crt-user-default-on	1	1773126759
93n7axewi7n9xpsis8z5d99bre	crt-user-always-on	1	1773126759
93n7axewi7n9xpsis8z5d99bre	bleve_deprecation	1	1773126759
93n7axewi7n9xpsis8z5d99bre	certificate_deprecation	1	1773126759
93n7axewi7n9xpsis8z5d99bre	unsupported-server-v5.37	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	gfycat_deprecation_7.8	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	gif_deprecation_7.9_7.10	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	gfycat_deprecation_8.0	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	gfycat_deprecation_8.1	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	server_upgrade_v11.4	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	patch_upgrade	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	patch_upgrade2	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	crt-admin-disabled	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	crt-admin-default_off	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	crt-user-default-on	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	crt-user-always-on	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	bleve_deprecation	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	certificate_deprecation	1	1773126759
m16j1q6rkfdpxguuksz7wmpuba	unsupported-server-v5.37	1	1773126759
dp4jszrpsjnjpjw1mth4ygithy	gfycat_deprecation_7.8	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	gif_deprecation_7.9_7.10	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	gfycat_deprecation_8.0	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	gfycat_deprecation_8.1	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	server_upgrade_v11.4	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	patch_upgrade	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	patch_upgrade2	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	crt-admin-disabled	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	crt-admin-default_off	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	crt-user-default-on	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	crt-user-always-on	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	bleve_deprecation	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	certificate_deprecation	1	1773126760
dp4jszrpsjnjpjw1mth4ygithy	unsupported-server-v5.37	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	gfycat_deprecation_7.8	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	gif_deprecation_7.9_7.10	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	gfycat_deprecation_8.0	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	gfycat_deprecation_8.1	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	server_upgrade_v11.4	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	patch_upgrade	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	patch_upgrade2	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	crt-admin-disabled	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	crt-admin-default_off	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	crt-user-default-on	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	crt-user-always-on	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	bleve_deprecation	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	certificate_deprecation	1	1773126760
udhm7t7fqfgc9k9funqdejmeea	unsupported-server-v5.37	1	1773126760
g7r88gtyqjfdzgnwhr9xyumzce	gfycat_deprecation_7.8	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	gif_deprecation_7.9_7.10	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	gfycat_deprecation_8.0	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	gfycat_deprecation_8.1	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	server_upgrade_v11.4	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	patch_upgrade	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	patch_upgrade2	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	crt-admin-disabled	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	crt-admin-default_off	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	crt-user-default-on	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	crt-user-always-on	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	bleve_deprecation	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	certificate_deprecation	1	1773126762
g7r88gtyqjfdzgnwhr9xyumzce	unsupported-server-v5.37	1	1773126762
\.


--
-- Data for Name: propertyfields; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.propertyfields (id, groupid, name, type, attrs, targetid, targettype, createat, updateat, deleteat) FROM stdin;
cipo8y8srbgkpeb8whft33cxmw	6itaqzig4pgqdr5q5557jgxnho	reporting_time	text	{"subType": "timestamp"}			1773126729277	1773126729277	0
z7ioksckuibs5yqww8eo1os3we	6itaqzig4pgqdr5q5557jgxnho	reviewer_user_id	user	{"editable": true}			1773126729278	1773126729278	0
b1mn7c9c47gq9jxo1g85zm7day	6itaqzig4pgqdr5q5557jgxnho	actor_comment	text	null			1773126729279	1773126729279	0
sj8mp6mogpnebe8ye89t36d91w	6itaqzig4pgqdr5q5557jgxnho	content_flagging_managed	text	null			1773126729279	1773126729279	0
d8yifjyimj8qmqjas6gbeyck6c	6itaqzig4pgqdr5q5557jgxnho	flagged_post_id	text	null			1773126729280	1773126729280	0
3ama9ucafi8ofq4n1hjysprbye	6itaqzig4pgqdr5q5557jgxnho	reporting_user_id	user	null			1773126729280	1773126729280	0
6uynbcp4qidbj83363mzox9b6y	6itaqzig4pgqdr5q5557jgxnho	reporting_reason	select	null			1773126729281	1773126729281	0
he7atm8s43fp7mqo1wj5gfqyer	6itaqzig4pgqdr5q5557jgxnho	actor_user_id	user	null			1773126729281	1773126729281	0
jdqdgngqcpdwf8kqogp4hjimer	6itaqzig4pgqdr5q5557jgxnho	action_time	text	{"subType": "timestamp"}			1773126729282	1773126729282	0
8s795q1thbrtpg5fmqqfecuktc	6itaqzig4pgqdr5q5557jgxnho	status	select	{"options": [{"name": "Pending", "color": "light_grey"}, {"name": "Assigned", "color": "dark_blue"}, {"name": "Removed", "color": "dark_red"}, {"name": "Retained", "color": "light_blue"}]}			1773126729282	1773126729282	0
9mghfes6g3r17ba8daz8auckwc	6itaqzig4pgqdr5q5557jgxnho	reporting_comment	text	null			1773126729283	1773126729283	0
\.


--
-- Data for Name: propertygroups; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.propertygroups (id, name) FROM stdin;
6itaqzig4pgqdr5q5557jgxnho	content_flagging
\.


--
-- Data for Name: propertyvalues; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.propertyvalues (id, targetid, targettype, groupid, fieldid, value, createat, updateat, deleteat) FROM stdin;
\.


--
-- Data for Name: publicchannels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.publicchannels (id, deleteat, teamid, displayname, name, header, purpose) FROM stdin;
jy91zp8mu7yk5gb5hy9qhdcfeh	0	tufgabb37pdmzfspeitber78oa	Town Square	town-square		
q9g6zsqkfty78mguucajfoqcir	0	tufgabb37pdmzfspeitber78oa	Off-Topic	off-topic		
c8sz8dja63nu7ms3jjtyws3ora	0	s8e39snm5tnbxbgpeia5kpwzuo	Town Square	town-square		
oqcewxpjqtdgxn91q6ehrqgzdr	0	s8e39snm5tnbxbgpeia5kpwzuo	Off-Topic	off-topic		
ody3wrq1o7rpjpzxsx7sqtdqdo	0	dehiwb8q9bnoi8f4mxzsh8dayr	Town Square	town-square		
nih4d7rfsir4xpi8tidfcunqrr	0	dehiwb8q9bnoi8f4mxzsh8dayr	Off-Topic	off-topic		
xbdo3t9uq7gxmgnk4xopy1pkee	0	tufgabb37pdmzfspeitber78oa	Project Alpha	project-alpha	Project Alpha | Sprint 12 | Release: March 30	Discussion and updates for Project Alpha - our new customer portal
qk4rrkf1stnn5ydh15bgh16nth	0	tufgabb37pdmzfspeitber78oa	Project Beta	project-beta	Project Beta | Planning Phase | Lead: Jane Smith	Internal dashboard redesign project
j443od6puifhjf85mfwk55h8ec	0	tufgabb37pdmzfspeitber78oa	Deployments	deployments	Check #runbooks before deploying | On-call: Bob Wilson	Deployment coordination and status updates
dewd9f48ij85xgq7tfte859qfa	0	tufgabb37pdmzfspeitber78oa	Code Reviews	code-reviews	Please include PR link and brief description when requesting reviews	Request and discuss code reviews
bbekt5pgxfnc5qmpwaxux3py1a	0	tufgabb37pdmzfspeitber78oa	Bugs and Issues	bugs-and-issues	Use format: [PROJECT] Brief description | Priority: High/Med/Low	Report and track bugs across all projects
wnrktfozbffs7dpb5u86mga3uy	0	tufgabb37pdmzfspeitber78oa	Standup Notes	standup-notes	Format: Yesterday | Today | Blockers	Daily standup updates from the engineering team
rmsexzhn3jgy7f4kbgnczsa3sa	0	tufgabb37pdmzfspeitber78oa	Tech Discussions	tech-discussions	Share interesting articles, discuss tech trends, and propose RFCs	Technical discussions, architecture decisions, and knowledge sharing
et85fk3eqpgrip4z9eydcg4weo	0	tufgabb37pdmzfspeitber78oa	DevOps	devops	AWS Status: Green | K8s Cluster: Healthy	Infrastructure, CI/CD, and operations
scj33w14etykfdaydd3cqcae5w	0	s8e39snm5tnbxbgpeia5kpwzuo	Campaigns	campaigns	Q1 Campaign: 'Innovate Together' | Budget: $50K	Plan and track marketing campaigns
7ijgcabphifx7mwe9g6w9paemy	0	s8e39snm5tnbxbgpeia5kpwzuo	Social Media	social-media	Posting schedule: Mon/Wed/Fri | Tools: Hootsuite, Canva	Social media strategy and content planning
qiiq57tw6jbru8zhkytut8i64e	0	s8e39snm5tnbxbgpeia5kpwzuo	Analytics	analytics	Weekly report due every Friday by 3pm	Marketing analytics and reporting
4rt4rx5mt38b38y9ec93k89boo	0	s8e39snm5tnbxbgpeia5kpwzuo	Content Calendar	content-calendar	Next blog post due: March 15 | Author: Frank Miller	Blog posts, newsletters, and content scheduling
3zf3d5jjnfymug7cq1ucdwqrmo	0	s8e39snm5tnbxbgpeia5kpwzuo	Design Requests	design-requests	Use the pinned template for new requests | SLA: 3 business days	Submit and track design requests
5b4hke3753y73feti3hhtfbgiy	0	dehiwb8q9bnoi8f4mxzsh8dayr	Announcements	announcements	Only managers and above can post here	Company-wide announcements and news
1s9nagudoiboirmb7ckj1mukfy	0	dehiwb8q9bnoi8f4mxzsh8dayr	Random	random	Keep it friendly and respectful!	Non-work banter and fun stuff
8k1ahz7c8pgmjyco414pgi5f4y	0	dehiwb8q9bnoi8f4mxzsh8dayr	Water Cooler	watercooler	What's everyone watching this weekend?	Casual conversations and team bonding
7aqugqd4dprbzcfcnm8ouuqczc	0	dehiwb8q9bnoi8f4mxzsh8dayr	Events	events	Next event: Team Lunch - March 20 at Bella Italia	Company events, team outings, and celebrations
i14jg6ym6tbfmpa93dq5usgrty	0	dehiwb8q9bnoi8f4mxzsh8dayr	Help Desk	help-desk	For urgent issues, contact IT at ext. 5555	IT support and general help requests
h4d4ekghxin7bnutsuomgd776w	0	dehiwb8q9bnoi8f4mxzsh8dayr	New Joiners	new-joiners	Welcome to TechCorp! Check pinned posts for onboarding guide	Welcome new team members and onboarding info
\.


--
-- Data for Name: reactions; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.reactions (userid, postid, emojiname, createat, updateat, deleteat, remoteid, channelid) FROM stdin;
\.


--
-- Data for Name: readreceipts; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.readreceipts (postid, userid, expireat) FROM stdin;
\.


--
-- Data for Name: recapchannels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.recapchannels (id, recapid, channelid, channelname, highlights, actionitems, sourcepostids, createat) FROM stdin;
\.


--
-- Data for Name: recaps; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.recaps (id, userid, title, createat, updateat, deleteat, totalmessagecount, status, readat, botid) FROM stdin;
\.


--
-- Data for Name: recentsearches; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.recentsearches (userid, searchpointer, query, createat) FROM stdin;
\.


--
-- Data for Name: remoteclusters; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.remoteclusters (remoteid, remoteteamid, name, displayname, siteurl, createat, lastpingat, token, remotetoken, topics, creatorid, pluginid, options, defaultteamid, deleteat, lastglobalusersyncat) FROM stdin;
\.


--
-- Data for Name: retentionidsfordeletion; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.retentionidsfordeletion (id, tablename, ids) FROM stdin;
\.


--
-- Data for Name: retentionpolicies; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.retentionpolicies (id, displayname, postduration) FROM stdin;
\.


--
-- Data for Name: retentionpolicieschannels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.retentionpolicieschannels (policyid, channelid) FROM stdin;
\.


--
-- Data for Name: retentionpoliciesteams; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.retentionpoliciesteams (policyid, teamid) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.roles (id, name, displayname, description, createat, updateat, deleteat, permissions, schememanaged, builtin) FROM stdin;
xpkw6sc55tydxc5mtmq18xqy8y	team_post_all_public	authentication.roles.team_post_all_public.name	authentication.roles.team_post_all_public.description	1773126728621	1773126729236	0	 use_channel_mentions create_post_public use_group_mentions	f	t
mz9uf7b947n4p8zeywzmajdehy	playbook_admin	authentication.roles.playbook_admin.name	authentication.roles.playbook_admin.description	1773126728622	1773126729237	0	 playbook_public_make_private playbook_public_manage_members playbook_public_manage_roles playbook_public_manage_properties playbook_private_manage_members playbook_private_manage_roles playbook_private_manage_properties	t	t
dr7rb5puhigs3m97oshcef8ofo	system_guest	authentication.roles.global_guest.name	authentication.roles.global_guest.description	1773126728622	1773126729237	0	 create_group_channel create_direct_channel	t	t
gmy4d3e38pr4benn119awmr3me	system_user_access_token	authentication.roles.system_user_access_token.name	authentication.roles.system_user_access_token.description	1773126728623	1773126729237	0	 create_user_access_token read_user_access_token revoke_user_access_token	f	t
d6t4338emb8wfgnstgphb7r56r	system_custom_group_admin	authentication.roles.system_custom_group_admin.name	authentication.roles.system_custom_group_admin.description	1773126728625	1773126729239	0	 restore_custom_group manage_custom_group_members create_custom_group edit_custom_group delete_custom_group	f	t
wsow9ye9dt8hp81uaearzrng5e	team_user	authentication.roles.team_user.name	authentication.roles.team_user.description	1773126728625	1773126729239	0	 view_team create_private_channel playbook_public_create list_team_channels read_public_channel playbook_private_create add_user_to_team create_public_channel invite_user join_public_channels	t	t
7aotdhxb4bdepnph63ejews8yc	run_member	authentication.roles.run_member.name	authentication.roles.run_member.description	1773126728626	1773126729240	0	 run_view	t	t
tt63i3zs3frafy9htkswms13fr	system_post_all	authentication.roles.system_post_all.name	authentication.roles.system_post_all.description	1773126728626	1773126729240	0	 use_channel_mentions create_post use_group_mentions upload_file	f	t
mgfp8bozwjyhzpxi5j5ztdyecy	channel_guest	authentication.roles.channel_guest.name	authentication.roles.channel_guest.description	1773126728615	1773126729232	0	 edit_post use_channel_mentions add_reaction upload_file remove_reaction create_post read_channel read_channel_content	t	t
khmwiurpkifbxk3crqewoxtonr	team_guest	authentication.roles.team_guest.name	authentication.roles.team_guest.description	1773126728616	1773126729233	0	 view_team	t	t
118rf8s13pfftqjpuo7n743age	team_post_all	authentication.roles.team_post_all.name	authentication.roles.team_post_all.description	1773126728616	1773126729233	0	 upload_file use_group_mentions create_post use_channel_mentions	f	t
f7b473d4tjf6jruuuj6ynrypfc	run_admin	authentication.roles.run_admin.name	authentication.roles.run_admin.description	1773126728618	1773126729234	0	 run_manage_properties run_manage_members	t	t
bxpsimsb3jy6j8qno1jjegoh8r	system_post_all_public	authentication.roles.system_post_all_public.name	authentication.roles.system_post_all_public.description	1773126728619	1773126729235	0	 create_post_public use_group_mentions use_channel_mentions	f	t
o56w5mmrdbd93qg3ewi9ckoh5y	custom_group_user	authentication.roles.custom_group_user.name	authentication.roles.custom_group_user.description	1773126728620	1773126729236	0		f	f
p1sgkdbe7prmun7t99i7dis41c	channel_admin	authentication.roles.channel_admin.name	authentication.roles.channel_admin.description	1773126728621	1773126729236	0	 add_reaction edit_bookmark_public_channel manage_public_channel_banner manage_channel_access_rules edit_bookmark_private_channel create_post read_private_channel_groups remove_reaction delete_bookmark_private_channel use_channel_mentions use_group_mentions manage_public_channel_members upload_file read_public_channel_groups manage_private_channel_banner order_bookmark_public_channel delete_bookmark_public_channel add_bookmark_private_channel manage_private_channel_members manage_channel_roles add_bookmark_public_channel order_bookmark_private_channel	t	t
bgf3wzrqajfktcmqhuu7qozqay	system_user_manager	authentication.roles.system_user_manager.name	authentication.roles.system_user_manager.description	1773126728627	1773126729241	0	 manage_public_channel_properties read_ldap_sync_job read_public_channel read_public_channel_groups sysconsole_read_authentication_saml convert_public_channel_to_private manage_team list_public_teams sysconsole_read_authentication_password list_private_teams join_public_teams sysconsole_write_user_management_groups manage_team_roles manage_private_channel_properties remove_user_from_team sysconsole_read_user_management_channels sysconsole_write_user_management_teams read_channel sysconsole_read_authentication_mfa sysconsole_read_authentication_openid sysconsole_read_user_management_groups sysconsole_write_user_management_channels sysconsole_read_user_management_teams manage_public_channel_members join_private_teams manage_private_channel_members sysconsole_read_authentication_email sysconsole_read_user_management_permissions convert_private_channel_to_public delete_private_channel sysconsole_read_authentication_ldap read_private_channel_groups view_team add_user_to_team sysconsole_read_authentication_signup sysconsole_read_authentication_guest_access delete_public_channel manage_channel_roles test_ldap	f	t
wep5uhjqqtg5ix9sxe758bsghh	system_read_only_admin	authentication.roles.system_read_only_admin.name	authentication.roles.system_read_only_admin.description	1773126728620	1773126729235	0	 list_public_teams sysconsole_read_environment_logging read_data_retention_job get_logs view_team sysconsole_read_environment_performance_monitoring sysconsole_read_environment_elasticsearch sysconsole_read_plugins sysconsole_read_environment_smtp sysconsole_read_site_customization sysconsole_read_authentication_saml sysconsole_read_site_notices read_license_information test_ldap sysconsole_read_about_edition_and_license sysconsole_read_environment_database sysconsole_read_authentication_email sysconsole_read_environment_developer sysconsole_read_site_posts sysconsole_read_integrations_integration_management sysconsole_read_experimental_features sysconsole_read_environment_image_proxy sysconsole_read_environment_rate_limiting sysconsole_read_integrations_bot_accounts sysconsole_read_compliance_data_retention_policy read_private_channel_groups sysconsole_read_integrations_cors sysconsole_read_products_boards sysconsole_read_authentication_guest_access read_channel sysconsole_read_reporting_server_logs sysconsole_read_authentication_password read_audits sysconsole_read_environment_file_storage read_ldap_sync_job sysconsole_read_experimental_feature_flags read_public_channel_groups sysconsole_read_integrations_gif sysconsole_read_authentication_mfa sysconsole_read_user_management_groups sysconsole_read_compliance_compliance_export read_elasticsearch_post_indexing_job read_compliance_export_job sysconsole_read_user_management_users sysconsole_read_environment_push_notification_server list_private_teams sysconsole_read_environment_mobile_security sysconsole_read_user_management_teams sysconsole_read_compliance_compliance_monitoring sysconsole_read_authentication_ldap sysconsole_read_site_notifications sysconsole_read_site_file_sharing_and_downloads sysconsole_read_user_management_channels get_analytics download_compliance_export_result read_elasticsearch_post_aggregation_job sysconsole_read_compliance_custom_terms_of_service read_public_channel sysconsole_read_site_announcement_banner sysconsole_read_site_emoji sysconsole_read_environment_high_availability sysconsole_read_authentication_signup sysconsole_read_user_management_permissions sysconsole_read_environment_session_lengths sysconsole_read_reporting_team_statistics sysconsole_read_authentication_openid sysconsole_read_site_users_and_teams sysconsole_read_site_localization sysconsole_read_environment_web_server read_other_users_teams sysconsole_read_site_public_links sysconsole_read_reporting_site_statistics	f	t
ashmhjoyifdizg1mmxaug5bfoe	system_manager	authentication.roles.system_manager.name	authentication.roles.system_manager.description	1773126728623	1773126729238	0	 read_public_channel sysconsole_write_environment_logging manage_private_channel_properties sysconsole_read_environment_file_storage sysconsole_read_environment_image_proxy sysconsole_write_integrations_integration_management sysconsole_write_environment_push_notification_server sysconsole_read_environment_rate_limiting sysconsole_read_environment_elasticsearch get_logs sysconsole_read_environment_push_notification_server purge_elasticsearch_indexes manage_channel_roles sysconsole_write_user_management_groups sysconsole_write_integrations_cors sysconsole_write_site_notifications sysconsole_write_environment_web_server test_elasticsearch remove_user_from_team sysconsole_read_environment_session_lengths sysconsole_read_environment_logging sysconsole_read_integrations_gif test_s3 sysconsole_read_environment_database list_private_teams sysconsole_read_site_notifications read_elasticsearch_post_aggregation_job sysconsole_read_authentication_ldap invalidate_caches test_email read_public_channel_groups sysconsole_read_environment_web_server reload_config manage_public_channel_members manage_outgoing_oauth_connections view_team sysconsole_read_user_management_permissions sysconsole_write_products_boards convert_public_channel_to_private sysconsole_write_site_posts list_public_teams sysconsole_read_site_localization sysconsole_write_environment_smtp sysconsole_read_site_users_and_teams delete_public_channel read_elasticsearch_post_indexing_job sysconsole_read_site_file_sharing_and_downloads sysconsole_write_site_notices sysconsole_write_environment_session_lengths sysconsole_read_integrations_bot_accounts sysconsole_write_environment_elasticsearch sysconsole_write_environment_rate_limiting sysconsole_write_environment_file_storage sysconsole_write_integrations_gif delete_private_channel sysconsole_read_site_emoji sysconsole_read_site_public_links convert_private_channel_to_public sysconsole_write_user_management_teams manage_team read_ldap_sync_job sysconsole_read_authentication_mfa sysconsole_read_reporting_team_statistics test_site_url read_private_channel_groups manage_public_channel_properties sysconsole_write_site_public_links sysconsole_write_site_file_sharing_and_downloads add_user_to_team manage_elasticsearch_post_indexing_job sysconsole_read_about_edition_and_license sysconsole_write_integrations_bot_accounts manage_team_roles sysconsole_write_site_localization read_license_information sysconsole_read_site_posts sysconsole_write_site_users_and_teams join_public_teams sysconsole_write_environment_high_availability sysconsole_read_user_management_channels manage_private_channel_members sysconsole_write_site_emoji sysconsole_write_user_management_channels edit_brand recycle_database_connections sysconsole_read_environment_smtp sysconsole_read_environment_developer sysconsole_read_authentication_openid sysconsole_read_authentication_email sysconsole_read_authentication_saml sysconsole_read_plugins sysconsole_read_user_management_groups sysconsole_write_user_management_permissions manage_elasticsearch_post_aggregation_job test_ldap create_elasticsearch_post_aggregation_job sysconsole_write_site_announcement_banner sysconsole_read_integrations_integration_management sysconsole_read_site_announcement_banner sysconsole_read_environment_high_availability sysconsole_write_site_customization sysconsole_read_products_boards create_elasticsearch_post_indexing_job sysconsole_read_authentication_guest_access sysconsole_read_authentication_signup join_private_teams sysconsole_read_integrations_cors sysconsole_read_user_management_teams sysconsole_read_authentication_password sysconsole_write_environment_developer sysconsole_read_site_notices sysconsole_read_reporting_site_statistics sysconsole_read_environment_performance_monitoring get_analytics sysconsole_write_environment_performance_monitoring sysconsole_write_environment_database sysconsole_write_environment_image_proxy sysconsole_read_reporting_server_logs sysconsole_read_site_customization read_channel	f	t
dpnjtrj97pnfbg73oizygc6xua	channel_user	authentication.roles.channel_user.name	authentication.roles.channel_user.description	1773126728627	1773126729241	0	 manage_public_channel_properties get_public_link delete_bookmark_public_channel edit_bookmark_public_channel order_bookmark_public_channel delete_public_channel use_channel_mentions add_bookmark_private_channel add_bookmark_public_channel upload_file create_post read_channel delete_private_channel manage_private_channel_members edit_post order_bookmark_private_channel add_reaction remove_reaction use_group_mentions read_public_channel_groups manage_private_channel_properties manage_public_channel_members read_private_channel_groups delete_post read_channel_content edit_bookmark_private_channel delete_bookmark_private_channel	t	t
kajj8hodsjdfix1s3y49yu5qwc	playbook_member	authentication.roles.playbook_member.name	authentication.roles.playbook_member.description	1773126728628	1773126729242	0	 playbook_public_manage_members playbook_public_manage_properties playbook_private_view playbook_private_manage_members playbook_private_manage_properties run_create playbook_public_view	t	t
8wme8r6ktfrhtprqdqy8gtcpth	team_admin	authentication.roles.team_admin.name	authentication.roles.team_admin.description	1773126728617	1773126729234	0	 manage_own_slash_commands remove_reaction delete_post remove_user_from_team bypass_incoming_webhook_channel_lock order_bookmark_public_channel order_bookmark_private_channel manage_others_slash_commands manage_own_incoming_webhooks use_group_mentions manage_team create_post playbook_public_manage_roles manage_others_incoming_webhooks delete_bookmark_private_channel read_public_channel_groups delete_bookmark_public_channel manage_private_channel_members delete_others_posts upload_file manage_channel_roles playbook_private_manage_roles use_channel_mentions edit_bookmark_private_channel add_bookmark_private_channel manage_public_channel_members edit_bookmark_public_channel manage_private_channel_banner convert_private_channel_to_public import_team read_private_channel_groups add_reaction manage_public_channel_banner add_bookmark_public_channel manage_own_outgoing_webhooks manage_others_outgoing_webhooks convert_public_channel_to_private manage_channel_access_rules manage_team_roles	t	t
o963p1ndnire38uyouwzo8ab6c	system_user	authentication.roles.global_user.name	authentication.roles.global_user.description	1773126728618	1773126729242	0	 edit_custom_group create_direct_channel create_group_channel create_team join_public_teams restore_custom_group view_members create_custom_group delete_custom_group list_public_teams manage_custom_group_members create_emojis delete_emojis	t	t
zhd5gj8o83b7jpczix9omty36o	system_admin	authentication.roles.global_admin.name	authentication.roles.global_admin.description	1773126728629	1773126729243	0	 manage_roles sysconsole_write_site_notices bypass_incoming_webhook_channel_lock add_user_to_team order_bookmark_private_channel manage_others_outgoing_webhooks sysconsole_write_user_management_groups invalidate_email_invite playbook_private_view playbook_private_manage_members sysconsole_write_integrations_bot_accounts create_compliance_export_job sysconsole_write_environment_mobile_security join_public_channels sysconsole_write_environment_performance_monitoring sysconsole_write_site_ip_filters test_ldap recycle_database_connections edit_bookmark_private_channel sysconsole_read_compliance_data_retention_policy read_other_users_teams read_elasticsearch_post_indexing_job sysconsole_read_environment_performance_monitoring sysconsole_write_compliance_data_retention_policy list_team_channels manage_license_information manage_private_channel_members sysconsole_write_compliance_compliance_export playbook_private_manage_roles playbook_public_make_private test_s3 delete_post manage_data_retention_job playbook_public_manage_roles create_private_channel sysconsole_read_experimental_feature_flags sysconsole_read_environment_rate_limiting sysconsole_write_authentication_password sysconsole_write_user_management_system_roles delete_bookmark_public_channel sysconsole_write_compliance_compliance_monitoring convert_private_channel_to_public view_members sysconsole_write_authentication_openid sysconsole_write_environment_file_storage manage_public_channel_properties sysconsole_read_authentication_password sysconsole_write_environment_elasticsearch edit_brand sysconsole_write_products_boards sysconsole_read_user_management_users sysconsole_read_environment_image_proxy test_site_url delete_custom_group join_private_teams sysconsole_read_environment_smtp sysconsole_read_authentication_email create_bot read_deleted_posts manage_compliance_export_job sysconsole_read_site_file_sharing_and_downloads sysconsole_write_environment_rate_limiting view_team manage_elasticsearch_post_aggregation_job sysconsole_write_user_management_permissions sysconsole_read_integrations_cors sysconsole_read_environment_push_notification_server sysconsole_write_environment_smtp manage_own_slash_commands order_bookmark_public_channel remove_saml_public_cert sysconsole_read_authentication_mfa sysconsole_write_environment_push_notification_server revoke_user_access_token run_view manage_team manage_ldap_sync_job sysconsole_write_reporting_team_statistics read_private_channel_groups sysconsole_read_billing sysconsole_write_integrations_cors sysconsole_write_site_customization read_audits playbook_private_manage_properties get_saml_metadata_from_idp get_saml_cert_status get_logs sysconsole_read_site_notices create_user_access_token sysconsole_read_environment_session_lengths create_elasticsearch_post_indexing_job sysconsole_read_site_ip_filters read_public_channel demote_to_guest sysconsole_write_environment_image_proxy sysconsole_read_environment_developer sysconsole_write_site_users_and_teams sysconsole_read_site_posts read_ldap_sync_job use_group_mentions sysconsole_read_site_notifications manage_public_channel_banner sysconsole_write_site_emoji manage_own_outgoing_webhooks create_emojis read_user_access_token sysconsole_write_authentication_saml sysconsole_read_plugins sysconsole_write_reporting_server_logs manage_private_channel_properties run_manage_properties delete_private_channel sysconsole_read_environment_elasticsearch list_users_without_team sysconsole_write_reporting_site_statistics sysconsole_read_reporting_server_logs add_bookmark_public_channel upload_file create_post create_custom_group edit_custom_group sysconsole_read_site_emoji get_public_link create_data_retention_job sysconsole_write_site_notifications remove_reaction sysconsole_write_user_management_teams read_compliance_export_job sysconsole_read_authentication_signup sysconsole_write_site_posts use_channel_mentions manage_outgoing_oauth_connections read_data_retention_job use_slash_commands sysconsole_write_environment_developer manage_system_wide_oauth create_post_ephemeral playbook_public_create read_channel assign_bot remove_saml_private_cert delete_emojis sysconsole_write_billing add_saml_private_cert playbook_public_manage_members manage_public_channel_members create_post_public create_direct_channel sysconsole_write_integrations_integration_management sysconsole_write_authentication_ldap sysconsole_read_authentication_saml sysconsole_write_authentication_mfa manage_jobs sysconsole_write_environment_logging sysconsole_read_reporting_team_statistics edit_bookmark_public_channel sysconsole_write_experimental_features sysconsole_read_user_management_permissions import_team remove_user_from_team manage_others_incoming_webhooks add_bookmark_private_channel download_compliance_export_result playbook_private_make_public sysconsole_write_environment_web_server test_email sysconsole_write_site_localization sysconsole_read_environment_database create_team sysconsole_read_reporting_site_statistics test_elasticsearch restore_custom_group delete_others_emojis sysconsole_read_environment_mobile_security sysconsole_read_environment_high_availability sysconsole_write_environment_session_lengths create_public_channel assign_system_admin_role invite_user add_ldap_private_cert sysconsole_write_user_management_users sysconsole_read_user_management_channels sysconsole_read_integrations_bot_accounts manage_private_channel_banner sysconsole_read_environment_file_storage sysconsole_write_about_edition_and_license read_channel_content sysconsole_write_authentication_email sysconsole_write_environment_high_availability sysconsole_write_authentication_guest_access invalidate_caches sysconsole_read_site_public_links edit_other_users remove_saml_idp_cert create_ldap_sync_job remove_others_reactions playbook_private_create sysconsole_read_site_customization purge_elasticsearch_indexes sysconsole_write_authentication_signup read_public_channel_groups run_create sysconsole_read_user_management_groups sysconsole_write_site_public_links playbook_public_view delete_public_channel sysconsole_read_user_management_teams sysconsole_read_compliance_compliance_monitoring manage_others_bots sysconsole_read_compliance_compliance_export sysconsole_read_site_users_and_teams join_public_teams sysconsole_read_integrations_integration_management sysconsole_read_products_boards sysconsole_read_environment_web_server edit_others_posts get_analytics manage_system sysconsole_write_experimental_feature_flags sysconsole_read_user_management_system_roles run_manage_members sysconsole_write_site_file_sharing_and_downloads sysconsole_write_environment_database manage_others_slash_commands edit_post sysconsole_read_authentication_openid manage_team_roles manage_own_incoming_webhooks manage_secure_connections manage_elasticsearch_post_indexing_job manage_shared_channels create_elasticsearch_post_aggregation_job sysconsole_read_site_announcement_banner add_reaction add_saml_idp_cert manage_bots read_elasticsearch_post_aggregation_job read_license_information sysconsole_read_about_edition_and_license create_group_channel sysconsole_read_authentication_ldap read_others_bots sysconsole_read_experimental_features delete_others_posts sysconsole_write_compliance_custom_terms_of_service add_ldap_public_cert reload_config list_public_teams sysconsole_write_plugins read_jobs sysconsole_read_authentication_guest_access list_private_teams promote_guest remove_ldap_public_cert playbook_public_manage_properties sysconsole_read_integrations_gif convert_public_channel_to_private sysconsole_read_site_localization remove_ldap_private_cert add_saml_public_cert manage_custom_group_members manage_channel_access_rules invite_guest sysconsole_read_environment_logging sysconsole_write_integrations_gif sysconsole_write_site_announcement_banner delete_bookmark_private_channel read_bots manage_channel_roles sysconsole_write_user_management_channels sysconsole_read_compliance_custom_terms_of_service	t	t
\.


--
-- Data for Name: scheduledposts; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.scheduledposts (id, createat, updateat, userid, channelid, rootid, message, props, fileids, priority, scheduledat, processedat, errorcode, type) FROM stdin;
\.


--
-- Data for Name: schemes; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.schemes (id, name, displayname, description, createat, updateat, deleteat, scope, defaultteamadminrole, defaultteamuserrole, defaultchanneladminrole, defaultchanneluserrole, defaultteamguestrole, defaultchannelguestrole, defaultplaybookadminrole, defaultplaybookmemberrole, defaultrunadminrole, defaultrunmemberrole) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.sessions (id, token, createat, expiresat, lastactivityat, userid, deviceid, roles, isoauth, props, expirednotify) FROM stdin;
znn7cz35fidypxca4hk7wnnaay	ywdz3yse4fdzjr1eon1bzmnoih	1773126731119	0	1773126731119	uw9ayeotajnate67greqnm1t6w			f	{}	f
m7jzkjttu7d83qfe34bdmgietw	c9ym5czc63dzjdoborke35yeuc	1773126751815	1788678751812	1773126751815	7kq76ce63id48nkz4hcp5rg3xh		system_admin system_user	f	{"os": "", "csrf": "5h69dhaiyfddugz5as3yc8bm3r", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
hkx93uuuobfe7mxrafocn394zh	9fhgjoe3i7yt9xpekq4a1omy3y	1773126770688	1788678770686	1773126770688	x916bcascjyyjrc5y8e5hbrgna		system_user	f	{"os": "", "csrf": "jo3odedc1jnptxputs1zrzun4r", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
9ybi6pe1n3rtzmyh6m7ud45oue	zzkr5eyispr3bry4rbk9ciq3aw	1773126771070	1788678771069	1773126771070	4zd57afzr3f4mbydt14j5mzqza		system_user	f	{"os": "", "csrf": "xoyus91aeir5jnhrbwyoos83eo", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
8r8wh45ou7nddcwq1i7wybowdr	kchbipsajtbn3rm64sr7w74kdy	1773126771416	1788678771414	1773126771416	46fd55wk57bdzq89debc4cxugr		system_user	f	{"os": "", "csrf": "igsyoa5o8iyrip6arh3az9fsah", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
s5rtznf6ktguteuzh9xd99r5cw	ihcwgenf17b8pfciquf48jrnpc	1773126771755	1788678771754	1773126771755	6a4bti99g3rtdmx11dhnihhg6r		system_user	f	{"os": "", "csrf": "yf3ztno817bbfq6mhnxtwtkc1r", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
tom49sb8yty69kujdu9wbx3g7h	99et8rzmiigdijjej6fg3ompnw	1773126772231	1788678772229	1773126772231	ccmjk1p1abffx87a4zni7n4uoh		system_user	f	{"os": "", "csrf": "ow18673j7jgcifahdm3muhn6dw", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
pr894dfjbpn9pkhx9ek8u1r4ka	fcnfe4nx478bpj7mkb5zte8apy	1773126772591	1788678772590	1773126772591	3bekgg684bb5iq6tfq1h95az3r		system_user	f	{"os": "", "csrf": "qpghui3gx7gmbqbc3wbi1xszth", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
max74b3qxfnqdk4bandpipanwo	w6qjsea8yjytbxdqne5nf8zwur	1773126773068	1788678773067	1773126773068	93n7axewi7n9xpsis8z5d99bre		system_user	f	{"os": "", "csrf": "jpk651stxbrz5jo3z1gh3erbra", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
3a8dcq77dfd4d8mshdks4hx47r	7t3fe7rurpny8gihd79qe73tcc	1773126773427	1788678773425	1773126773427	m16j1q6rkfdpxguuksz7wmpuba		system_user	f	{"os": "", "csrf": "5bysx7whqjg1fq4t5dk5nsxqaa", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
4bt89yqgxbdy5xmc9ku3nnymfw	3otri4ojbbntxge1156iwo3fxw	1773126773904	1788678773902	1773126773904	dp4jszrpsjnjpjw1mth4ygithy		system_user	f	{"os": "", "csrf": "7cgydqj68idw8bcwetgs5tbaaw", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
76dj35jg7jdfdb8u8cnqheh76o	ammnuhs7jibw8e5huzx4zpbxro	1773126774380	1788678774379	1773126774380	udhm7t7fqfgc9k9funqdejmeea		system_user	f	{"os": "", "csrf": "ox5or8x1z3yauy6i4rpdn66idc", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
kf1f3jyuhbge9bwfyc8hi3xd7w	fxm375p1ubyn3f5u9jjy5ibzry	1773126774857	1788678774856	1773126774857	7e4ojpbykjntdmpu94y5ekub1c		system_user	f	{"os": "", "csrf": "9n94mtn3kinmfyaarm96jc1dzo", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
6exy4c3qq7ga5n473jj9ccoyic	nhq4ct4rniy3xgyhuzrtt3bo9e	1773126775335	1788678775333	1773126775335	9mbmdxz1kidnmemmqi9ou5w1ah		system_user	f	{"os": "", "csrf": "wce73959uincfddpm9i331xgsa", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
hsrn7w3gc7fszgc9dywmcwdmhy	xbw83aem9fnp8ge1ok4rmxj8jo	1773126775694	1788678775693	1773126775694	g7r88gtyqjfdzgnwhr9xyumzce		system_user	f	{"os": "", "csrf": "s5qc3xotpfnzpxrj4qgwtkbd1a", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
adzdgzmk4fbnzj61sz63abzw6c	81oxa7aq5jg7ic9q43mtzdqxnc	1773126776030	1788678776029	1773126776030	cxtqjdhuqiydtmdmtdc1mesbfo		system_user	f	{"os": "", "csrf": "bqcsxmtx73yf5bion5nnpir6ao", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
hufgu63bftypzdskouugwzh8qc	1skygent7bg58fyddxi3bq5ykw	1773126776508	1788678776507	1773126776508	hacoqz1mijy8db1u95mwsgt6pe		system_user	f	{"os": "", "csrf": "hee77hwqe3nbie7u7stynxhxka", "isSaml": "false", "browser": "Unknown/0.0", "isMobile": "false", "is_guest": "false", "platform": "Unknown", "isOAuthUser": "false"}	f
\.


--
-- Data for Name: sharedchannelattachments; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.sharedchannelattachments (id, fileid, remoteid, createat, lastsyncat) FROM stdin;
\.


--
-- Data for Name: sharedchannelremotes; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.sharedchannelremotes (id, channelid, creatorid, createat, updateat, isinviteaccepted, isinviteconfirmed, remoteid, lastpostupdateat, lastpostid, lastpostcreateat, lastpostcreateid, deleteat, lastmemberssyncat) FROM stdin;
\.


--
-- Data for Name: sharedchannels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.sharedchannels (channelid, teamid, home, readonly, sharename, sharedisplayname, sharepurpose, shareheader, creatorid, createat, updateat, remoteid) FROM stdin;
\.


--
-- Data for Name: sharedchannelusers; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.sharedchannelusers (id, userid, remoteid, createat, lastsyncat, channelid, lastmembershipsyncat) FROM stdin;
\.


--
-- Data for Name: sidebarcategories; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.sidebarcategories (id, userid, teamid, sortorder, sorting, type, displayname, muted, collapsed) FROM stdin;
favorites_7kq76ce63id48nkz4hcp5rg3xh_tufgabb37pdmzfspeitber78oa	7kq76ce63id48nkz4hcp5rg3xh	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_7kq76ce63id48nkz4hcp5rg3xh_tufgabb37pdmzfspeitber78oa	7kq76ce63id48nkz4hcp5rg3xh	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_7kq76ce63id48nkz4hcp5rg3xh_tufgabb37pdmzfspeitber78oa	7kq76ce63id48nkz4hcp5rg3xh	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_x916bcascjyyjrc5y8e5hbrgna_tufgabb37pdmzfspeitber78oa	x916bcascjyyjrc5y8e5hbrgna	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_x916bcascjyyjrc5y8e5hbrgna_tufgabb37pdmzfspeitber78oa	x916bcascjyyjrc5y8e5hbrgna	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_x916bcascjyyjrc5y8e5hbrgna_tufgabb37pdmzfspeitber78oa	x916bcascjyyjrc5y8e5hbrgna	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_4zd57afzr3f4mbydt14j5mzqza_tufgabb37pdmzfspeitber78oa	4zd57afzr3f4mbydt14j5mzqza	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_4zd57afzr3f4mbydt14j5mzqza_tufgabb37pdmzfspeitber78oa	4zd57afzr3f4mbydt14j5mzqza	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_4zd57afzr3f4mbydt14j5mzqza_tufgabb37pdmzfspeitber78oa	4zd57afzr3f4mbydt14j5mzqza	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_46fd55wk57bdzq89debc4cxugr_tufgabb37pdmzfspeitber78oa	46fd55wk57bdzq89debc4cxugr	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_46fd55wk57bdzq89debc4cxugr_tufgabb37pdmzfspeitber78oa	46fd55wk57bdzq89debc4cxugr	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_46fd55wk57bdzq89debc4cxugr_tufgabb37pdmzfspeitber78oa	46fd55wk57bdzq89debc4cxugr	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_6a4bti99g3rtdmx11dhnihhg6r_tufgabb37pdmzfspeitber78oa	6a4bti99g3rtdmx11dhnihhg6r	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_6a4bti99g3rtdmx11dhnihhg6r_tufgabb37pdmzfspeitber78oa	6a4bti99g3rtdmx11dhnihhg6r	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_6a4bti99g3rtdmx11dhnihhg6r_tufgabb37pdmzfspeitber78oa	6a4bti99g3rtdmx11dhnihhg6r	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_ccmjk1p1abffx87a4zni7n4uoh_tufgabb37pdmzfspeitber78oa	ccmjk1p1abffx87a4zni7n4uoh	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_ccmjk1p1abffx87a4zni7n4uoh_tufgabb37pdmzfspeitber78oa	ccmjk1p1abffx87a4zni7n4uoh	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_ccmjk1p1abffx87a4zni7n4uoh_tufgabb37pdmzfspeitber78oa	ccmjk1p1abffx87a4zni7n4uoh	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_3bekgg684bb5iq6tfq1h95az3r_tufgabb37pdmzfspeitber78oa	3bekgg684bb5iq6tfq1h95az3r	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_3bekgg684bb5iq6tfq1h95az3r_tufgabb37pdmzfspeitber78oa	3bekgg684bb5iq6tfq1h95az3r	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_3bekgg684bb5iq6tfq1h95az3r_tufgabb37pdmzfspeitber78oa	3bekgg684bb5iq6tfq1h95az3r	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_9mbmdxz1kidnmemmqi9ou5w1ah_tufgabb37pdmzfspeitber78oa	9mbmdxz1kidnmemmqi9ou5w1ah	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_9mbmdxz1kidnmemmqi9ou5w1ah_tufgabb37pdmzfspeitber78oa	9mbmdxz1kidnmemmqi9ou5w1ah	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_9mbmdxz1kidnmemmqi9ou5w1ah_tufgabb37pdmzfspeitber78oa	9mbmdxz1kidnmemmqi9ou5w1ah	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_g7r88gtyqjfdzgnwhr9xyumzce_tufgabb37pdmzfspeitber78oa	g7r88gtyqjfdzgnwhr9xyumzce	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_g7r88gtyqjfdzgnwhr9xyumzce_tufgabb37pdmzfspeitber78oa	g7r88gtyqjfdzgnwhr9xyumzce	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_g7r88gtyqjfdzgnwhr9xyumzce_tufgabb37pdmzfspeitber78oa	g7r88gtyqjfdzgnwhr9xyumzce	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_cxtqjdhuqiydtmdmtdc1mesbfo_tufgabb37pdmzfspeitber78oa	cxtqjdhuqiydtmdmtdc1mesbfo	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_cxtqjdhuqiydtmdmtdc1mesbfo_tufgabb37pdmzfspeitber78oa	cxtqjdhuqiydtmdmtdc1mesbfo	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_cxtqjdhuqiydtmdmtdc1mesbfo_tufgabb37pdmzfspeitber78oa	cxtqjdhuqiydtmdmtdc1mesbfo	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_hacoqz1mijy8db1u95mwsgt6pe_tufgabb37pdmzfspeitber78oa	hacoqz1mijy8db1u95mwsgt6pe	tufgabb37pdmzfspeitber78oa	0		favorites	Favorites	f	f
channels_hacoqz1mijy8db1u95mwsgt6pe_tufgabb37pdmzfspeitber78oa	hacoqz1mijy8db1u95mwsgt6pe	tufgabb37pdmzfspeitber78oa	10		channels	Channels	f	f
direct_messages_hacoqz1mijy8db1u95mwsgt6pe_tufgabb37pdmzfspeitber78oa	hacoqz1mijy8db1u95mwsgt6pe	tufgabb37pdmzfspeitber78oa	20	recent	direct_messages	Direct Messages	f	f
favorites_7kq76ce63id48nkz4hcp5rg3xh_s8e39snm5tnbxbgpeia5kpwzuo	7kq76ce63id48nkz4hcp5rg3xh	s8e39snm5tnbxbgpeia5kpwzuo	0		favorites	Favorites	f	f
channels_7kq76ce63id48nkz4hcp5rg3xh_s8e39snm5tnbxbgpeia5kpwzuo	7kq76ce63id48nkz4hcp5rg3xh	s8e39snm5tnbxbgpeia5kpwzuo	10		channels	Channels	f	f
direct_messages_7kq76ce63id48nkz4hcp5rg3xh_s8e39snm5tnbxbgpeia5kpwzuo	7kq76ce63id48nkz4hcp5rg3xh	s8e39snm5tnbxbgpeia5kpwzuo	20	recent	direct_messages	Direct Messages	f	f
favorites_93n7axewi7n9xpsis8z5d99bre_s8e39snm5tnbxbgpeia5kpwzuo	93n7axewi7n9xpsis8z5d99bre	s8e39snm5tnbxbgpeia5kpwzuo	0		favorites	Favorites	f	f
channels_93n7axewi7n9xpsis8z5d99bre_s8e39snm5tnbxbgpeia5kpwzuo	93n7axewi7n9xpsis8z5d99bre	s8e39snm5tnbxbgpeia5kpwzuo	10		channels	Channels	f	f
direct_messages_93n7axewi7n9xpsis8z5d99bre_s8e39snm5tnbxbgpeia5kpwzuo	93n7axewi7n9xpsis8z5d99bre	s8e39snm5tnbxbgpeia5kpwzuo	20	recent	direct_messages	Direct Messages	f	f
favorites_m16j1q6rkfdpxguuksz7wmpuba_s8e39snm5tnbxbgpeia5kpwzuo	m16j1q6rkfdpxguuksz7wmpuba	s8e39snm5tnbxbgpeia5kpwzuo	0		favorites	Favorites	f	f
channels_m16j1q6rkfdpxguuksz7wmpuba_s8e39snm5tnbxbgpeia5kpwzuo	m16j1q6rkfdpxguuksz7wmpuba	s8e39snm5tnbxbgpeia5kpwzuo	10		channels	Channels	f	f
direct_messages_m16j1q6rkfdpxguuksz7wmpuba_s8e39snm5tnbxbgpeia5kpwzuo	m16j1q6rkfdpxguuksz7wmpuba	s8e39snm5tnbxbgpeia5kpwzuo	20	recent	direct_messages	Direct Messages	f	f
favorites_dp4jszrpsjnjpjw1mth4ygithy_s8e39snm5tnbxbgpeia5kpwzuo	dp4jszrpsjnjpjw1mth4ygithy	s8e39snm5tnbxbgpeia5kpwzuo	0		favorites	Favorites	f	f
channels_dp4jszrpsjnjpjw1mth4ygithy_s8e39snm5tnbxbgpeia5kpwzuo	dp4jszrpsjnjpjw1mth4ygithy	s8e39snm5tnbxbgpeia5kpwzuo	10		channels	Channels	f	f
direct_messages_dp4jszrpsjnjpjw1mth4ygithy_s8e39snm5tnbxbgpeia5kpwzuo	dp4jszrpsjnjpjw1mth4ygithy	s8e39snm5tnbxbgpeia5kpwzuo	20	recent	direct_messages	Direct Messages	f	f
favorites_x916bcascjyyjrc5y8e5hbrgna_dehiwb8q9bnoi8f4mxzsh8dayr	x916bcascjyyjrc5y8e5hbrgna	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_x916bcascjyyjrc5y8e5hbrgna_dehiwb8q9bnoi8f4mxzsh8dayr	x916bcascjyyjrc5y8e5hbrgna	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_x916bcascjyyjrc5y8e5hbrgna_dehiwb8q9bnoi8f4mxzsh8dayr	x916bcascjyyjrc5y8e5hbrgna	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_4zd57afzr3f4mbydt14j5mzqza_dehiwb8q9bnoi8f4mxzsh8dayr	4zd57afzr3f4mbydt14j5mzqza	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_4zd57afzr3f4mbydt14j5mzqza_dehiwb8q9bnoi8f4mxzsh8dayr	4zd57afzr3f4mbydt14j5mzqza	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_4zd57afzr3f4mbydt14j5mzqza_dehiwb8q9bnoi8f4mxzsh8dayr	4zd57afzr3f4mbydt14j5mzqza	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_46fd55wk57bdzq89debc4cxugr_dehiwb8q9bnoi8f4mxzsh8dayr	46fd55wk57bdzq89debc4cxugr	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_46fd55wk57bdzq89debc4cxugr_dehiwb8q9bnoi8f4mxzsh8dayr	46fd55wk57bdzq89debc4cxugr	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_46fd55wk57bdzq89debc4cxugr_dehiwb8q9bnoi8f4mxzsh8dayr	46fd55wk57bdzq89debc4cxugr	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_6a4bti99g3rtdmx11dhnihhg6r_dehiwb8q9bnoi8f4mxzsh8dayr	6a4bti99g3rtdmx11dhnihhg6r	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_6a4bti99g3rtdmx11dhnihhg6r_dehiwb8q9bnoi8f4mxzsh8dayr	6a4bti99g3rtdmx11dhnihhg6r	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_6a4bti99g3rtdmx11dhnihhg6r_dehiwb8q9bnoi8f4mxzsh8dayr	6a4bti99g3rtdmx11dhnihhg6r	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_ccmjk1p1abffx87a4zni7n4uoh_dehiwb8q9bnoi8f4mxzsh8dayr	ccmjk1p1abffx87a4zni7n4uoh	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_ccmjk1p1abffx87a4zni7n4uoh_dehiwb8q9bnoi8f4mxzsh8dayr	ccmjk1p1abffx87a4zni7n4uoh	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_ccmjk1p1abffx87a4zni7n4uoh_dehiwb8q9bnoi8f4mxzsh8dayr	ccmjk1p1abffx87a4zni7n4uoh	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_9mbmdxz1kidnmemmqi9ou5w1ah_dehiwb8q9bnoi8f4mxzsh8dayr	9mbmdxz1kidnmemmqi9ou5w1ah	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_9mbmdxz1kidnmemmqi9ou5w1ah_dehiwb8q9bnoi8f4mxzsh8dayr	9mbmdxz1kidnmemmqi9ou5w1ah	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_9mbmdxz1kidnmemmqi9ou5w1ah_dehiwb8q9bnoi8f4mxzsh8dayr	9mbmdxz1kidnmemmqi9ou5w1ah	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_g7r88gtyqjfdzgnwhr9xyumzce_dehiwb8q9bnoi8f4mxzsh8dayr	g7r88gtyqjfdzgnwhr9xyumzce	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_g7r88gtyqjfdzgnwhr9xyumzce_dehiwb8q9bnoi8f4mxzsh8dayr	g7r88gtyqjfdzgnwhr9xyumzce	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_g7r88gtyqjfdzgnwhr9xyumzce_dehiwb8q9bnoi8f4mxzsh8dayr	g7r88gtyqjfdzgnwhr9xyumzce	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_cxtqjdhuqiydtmdmtdc1mesbfo_dehiwb8q9bnoi8f4mxzsh8dayr	cxtqjdhuqiydtmdmtdc1mesbfo	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_cxtqjdhuqiydtmdmtdc1mesbfo_dehiwb8q9bnoi8f4mxzsh8dayr	cxtqjdhuqiydtmdmtdc1mesbfo	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_cxtqjdhuqiydtmdmtdc1mesbfo_dehiwb8q9bnoi8f4mxzsh8dayr	cxtqjdhuqiydtmdmtdc1mesbfo	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_hacoqz1mijy8db1u95mwsgt6pe_dehiwb8q9bnoi8f4mxzsh8dayr	hacoqz1mijy8db1u95mwsgt6pe	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_hacoqz1mijy8db1u95mwsgt6pe_dehiwb8q9bnoi8f4mxzsh8dayr	hacoqz1mijy8db1u95mwsgt6pe	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_hacoqz1mijy8db1u95mwsgt6pe_dehiwb8q9bnoi8f4mxzsh8dayr	hacoqz1mijy8db1u95mwsgt6pe	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_7e4ojpbykjntdmpu94y5ekub1c_s8e39snm5tnbxbgpeia5kpwzuo	7e4ojpbykjntdmpu94y5ekub1c	s8e39snm5tnbxbgpeia5kpwzuo	0		favorites	Favorites	f	f
channels_7e4ojpbykjntdmpu94y5ekub1c_s8e39snm5tnbxbgpeia5kpwzuo	7e4ojpbykjntdmpu94y5ekub1c	s8e39snm5tnbxbgpeia5kpwzuo	10		channels	Channels	f	f
direct_messages_7e4ojpbykjntdmpu94y5ekub1c_s8e39snm5tnbxbgpeia5kpwzuo	7e4ojpbykjntdmpu94y5ekub1c	s8e39snm5tnbxbgpeia5kpwzuo	20	recent	direct_messages	Direct Messages	f	f
favorites_9mbmdxz1kidnmemmqi9ou5w1ah_s8e39snm5tnbxbgpeia5kpwzuo	9mbmdxz1kidnmemmqi9ou5w1ah	s8e39snm5tnbxbgpeia5kpwzuo	0		favorites	Favorites	f	f
channels_9mbmdxz1kidnmemmqi9ou5w1ah_s8e39snm5tnbxbgpeia5kpwzuo	9mbmdxz1kidnmemmqi9ou5w1ah	s8e39snm5tnbxbgpeia5kpwzuo	10		channels	Channels	f	f
direct_messages_9mbmdxz1kidnmemmqi9ou5w1ah_s8e39snm5tnbxbgpeia5kpwzuo	9mbmdxz1kidnmemmqi9ou5w1ah	s8e39snm5tnbxbgpeia5kpwzuo	20	recent	direct_messages	Direct Messages	f	f
favorites_7kq76ce63id48nkz4hcp5rg3xh_dehiwb8q9bnoi8f4mxzsh8dayr	7kq76ce63id48nkz4hcp5rg3xh	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_7kq76ce63id48nkz4hcp5rg3xh_dehiwb8q9bnoi8f4mxzsh8dayr	7kq76ce63id48nkz4hcp5rg3xh	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_7kq76ce63id48nkz4hcp5rg3xh_dehiwb8q9bnoi8f4mxzsh8dayr	7kq76ce63id48nkz4hcp5rg3xh	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_3bekgg684bb5iq6tfq1h95az3r_dehiwb8q9bnoi8f4mxzsh8dayr	3bekgg684bb5iq6tfq1h95az3r	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_3bekgg684bb5iq6tfq1h95az3r_dehiwb8q9bnoi8f4mxzsh8dayr	3bekgg684bb5iq6tfq1h95az3r	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_3bekgg684bb5iq6tfq1h95az3r_dehiwb8q9bnoi8f4mxzsh8dayr	3bekgg684bb5iq6tfq1h95az3r	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_93n7axewi7n9xpsis8z5d99bre_dehiwb8q9bnoi8f4mxzsh8dayr	93n7axewi7n9xpsis8z5d99bre	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_93n7axewi7n9xpsis8z5d99bre_dehiwb8q9bnoi8f4mxzsh8dayr	93n7axewi7n9xpsis8z5d99bre	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_93n7axewi7n9xpsis8z5d99bre_dehiwb8q9bnoi8f4mxzsh8dayr	93n7axewi7n9xpsis8z5d99bre	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_m16j1q6rkfdpxguuksz7wmpuba_dehiwb8q9bnoi8f4mxzsh8dayr	m16j1q6rkfdpxguuksz7wmpuba	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_m16j1q6rkfdpxguuksz7wmpuba_dehiwb8q9bnoi8f4mxzsh8dayr	m16j1q6rkfdpxguuksz7wmpuba	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_m16j1q6rkfdpxguuksz7wmpuba_dehiwb8q9bnoi8f4mxzsh8dayr	m16j1q6rkfdpxguuksz7wmpuba	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_dp4jszrpsjnjpjw1mth4ygithy_dehiwb8q9bnoi8f4mxzsh8dayr	dp4jszrpsjnjpjw1mth4ygithy	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_dp4jszrpsjnjpjw1mth4ygithy_dehiwb8q9bnoi8f4mxzsh8dayr	dp4jszrpsjnjpjw1mth4ygithy	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_dp4jszrpsjnjpjw1mth4ygithy_dehiwb8q9bnoi8f4mxzsh8dayr	dp4jszrpsjnjpjw1mth4ygithy	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_udhm7t7fqfgc9k9funqdejmeea_dehiwb8q9bnoi8f4mxzsh8dayr	udhm7t7fqfgc9k9funqdejmeea	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_udhm7t7fqfgc9k9funqdejmeea_dehiwb8q9bnoi8f4mxzsh8dayr	udhm7t7fqfgc9k9funqdejmeea	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_udhm7t7fqfgc9k9funqdejmeea_dehiwb8q9bnoi8f4mxzsh8dayr	udhm7t7fqfgc9k9funqdejmeea	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
favorites_7e4ojpbykjntdmpu94y5ekub1c_dehiwb8q9bnoi8f4mxzsh8dayr	7e4ojpbykjntdmpu94y5ekub1c	dehiwb8q9bnoi8f4mxzsh8dayr	0		favorites	Favorites	f	f
channels_7e4ojpbykjntdmpu94y5ekub1c_dehiwb8q9bnoi8f4mxzsh8dayr	7e4ojpbykjntdmpu94y5ekub1c	dehiwb8q9bnoi8f4mxzsh8dayr	10		channels	Channels	f	f
direct_messages_7e4ojpbykjntdmpu94y5ekub1c_dehiwb8q9bnoi8f4mxzsh8dayr	7e4ojpbykjntdmpu94y5ekub1c	dehiwb8q9bnoi8f4mxzsh8dayr	20	recent	direct_messages	Direct Messages	f	f
\.


--
-- Data for Name: sidebarchannels; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.sidebarchannels (channelid, userid, categoryid, sortorder) FROM stdin;
\.


--
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.status (userid, status, manual, lastactivityat, dndendtime, prevstatus) FROM stdin;
x916bcascjyyjrc5y8e5hbrgna	online	f	1773126776544	0	
4zd57afzr3f4mbydt14j5mzqza	online	f	1773126776584	0	
6a4bti99g3rtdmx11dhnihhg6r	online	f	1773126776626	0	
ccmjk1p1abffx87a4zni7n4uoh	online	f	1773126776696	0	
9mbmdxz1kidnmemmqi9ou5w1ah	online	f	1773126776770	0	
cxtqjdhuqiydtmdmtdc1mesbfo	online	f	1773126777373	0	
3bekgg684bb5iq6tfq1h95az3r	online	f	1773126777440	0	
46fd55wk57bdzq89debc4cxugr	online	f	1773126777629	0	
g7r88gtyqjfdzgnwhr9xyumzce	online	f	1773126777961	0	
hacoqz1mijy8db1u95mwsgt6pe	online	f	1773126779913	0	
93n7axewi7n9xpsis8z5d99bre	online	f	1773126780361	0	
m16j1q6rkfdpxguuksz7wmpuba	online	f	1773126780393	0	
dp4jszrpsjnjpjw1mth4ygithy	online	f	1773126780425	0	
7e4ojpbykjntdmpu94y5ekub1c	online	f	1773126780492	0	
udhm7t7fqfgc9k9funqdejmeea	online	f	1773126781122	0	
\.


--
-- Data for Name: systems; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.systems (name, value) FROM stdin;
CRTChannelMembershipCountsMigrationComplete	true
CRTThreadCountsAndUnreadsMigrationComplete	true
AsymmetricSigningKey	{"ecdsa_key":{"curve":"P-256","x":18831126452500576050520144583868095381343509967691825389005765715650077743525,"y":57364366989125760427962092765530774816136343491832235791756826339940644339918,"d":11317285982230421012706973099833089278259558615286588075082186461900004899742}}
DiagnosticId	j9qewrbnhjgg3mibdb5ib8um8y
LastSecurityTime	1773126728620
AdvancedPermissionsMigrationComplete	true
EmojisPermissionsMigrationComplete	true
GuestRolesCreationMigrationComplete	true
SystemConsoleRolesCreationMigrationComplete	true
CustomGroupAdminRoleCreationMigrationComplete	true
emoji_permissions_split	true
webhook_permissions_split	true
integrations_own_permissions	true
list_join_public_private_teams	true
remove_permanent_delete_user	true
add_bot_permissions	true
apply_channel_manage_delete_to_channel_user	true
remove_channel_manage_delete_from_team_user	true
view_members_new_permission	true
add_manage_guests_permissions	true
channel_moderations_permissions	true
add_use_group_mentions_permission	true
add_system_console_permissions	true
add_convert_channel_permissions	true
manage_shared_channel_permissions	true
manage_secure_connections_permissions	true
add_system_roles_permissions	true
add_billing_permissions	true
download_compliance_export_results	true
experimental_subsection_permissions	true
authentication_subsection_permissions	true
integrations_subsection_permissions	true
site_subsection_permissions	true
compliance_subsection_permissions	true
environment_subsection_permissions	true
about_subsection_permissions	true
reporting_subsection_permissions	true
test_email_ancillary_permission	true
playbooks_permissions	true
custom_groups_permissions	true
playbooks_manage_roles	true
products_boards	true
custom_groups_permission_restore	true
read_channel_content_permissions	true
add_ip_filtering_permissions	true
add_outgoing_oauth_connections_permissions	true
add_channel_bookmarks_permissions	true
add_manage_jobs_ancillary_permissions	true
add_upload_file_permission	true
restrict_access_to_channel_conversion_to_public_permissions	true
fix_read_audits_permission	true
remove_get_analytics_permission	true
add_sysconsole_mobile_security_permission	true
add_channel_banner_permissions	true
add_channel_access_rules_permission	true
ContentExtractionConfigDefaultTrueMigrationComplete	true
PlaybookRolesCreationMigrationComplete	true
RemainingSchemaMigrations	true
PostPriorityConfigDefaultTrueMigrationComplete	true
content_flagging_setup_done	v5
PostActionCookieSecret	{"key":"TrwxEXVwuYtQoV9Yh2Ri63rEYIjIAU5hx/WOQYRuyo8="}
InstallationDate	1773126731107
FirstServerRunTimestamp	1773126731926
delete_dms_preferences_migration	true
delete_orphan_drafts_migration	true
delete_empty_drafts_migration	true
\.


--
-- Data for Name: teammembers; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.teammembers (teamid, userid, roles, deleteat, schemeuser, schemeadmin, schemeguest, createat) FROM stdin;
tufgabb37pdmzfspeitber78oa	7kq76ce63id48nkz4hcp5rg3xh		0	t	t	f	1773126763200
tufgabb37pdmzfspeitber78oa	x916bcascjyyjrc5y8e5hbrgna		0	t	f	f	1773126763275
tufgabb37pdmzfspeitber78oa	4zd57afzr3f4mbydt14j5mzqza		0	t	f	f	1773126763344
tufgabb37pdmzfspeitber78oa	46fd55wk57bdzq89debc4cxugr		0	t	f	f	1773126763396
tufgabb37pdmzfspeitber78oa	6a4bti99g3rtdmx11dhnihhg6r		0	t	f	f	1773126763448
tufgabb37pdmzfspeitber78oa	ccmjk1p1abffx87a4zni7n4uoh		0	t	f	f	1773126763499
tufgabb37pdmzfspeitber78oa	3bekgg684bb5iq6tfq1h95az3r		0	t	f	f	1773126763551
tufgabb37pdmzfspeitber78oa	9mbmdxz1kidnmemmqi9ou5w1ah		0	t	f	f	1773126763601
tufgabb37pdmzfspeitber78oa	g7r88gtyqjfdzgnwhr9xyumzce		0	t	f	f	1773126763653
tufgabb37pdmzfspeitber78oa	cxtqjdhuqiydtmdmtdc1mesbfo		0	t	f	f	1773126763705
tufgabb37pdmzfspeitber78oa	hacoqz1mijy8db1u95mwsgt6pe		0	t	f	f	1773126763757
s8e39snm5tnbxbgpeia5kpwzuo	7kq76ce63id48nkz4hcp5rg3xh		0	t	t	f	1773126763817
s8e39snm5tnbxbgpeia5kpwzuo	93n7axewi7n9xpsis8z5d99bre		0	t	f	f	1773126763869
s8e39snm5tnbxbgpeia5kpwzuo	m16j1q6rkfdpxguuksz7wmpuba		0	t	f	f	1773126763919
s8e39snm5tnbxbgpeia5kpwzuo	dp4jszrpsjnjpjw1mth4ygithy		0	t	f	f	1773126763969
s8e39snm5tnbxbgpeia5kpwzuo	7e4ojpbykjntdmpu94y5ekub1c		0	t	f	f	1773126764017
s8e39snm5tnbxbgpeia5kpwzuo	9mbmdxz1kidnmemmqi9ou5w1ah		0	t	f	f	1773126764068
dehiwb8q9bnoi8f4mxzsh8dayr	7kq76ce63id48nkz4hcp5rg3xh		0	t	t	f	1773126764130
dehiwb8q9bnoi8f4mxzsh8dayr	x916bcascjyyjrc5y8e5hbrgna		0	t	f	f	1773126764193
dehiwb8q9bnoi8f4mxzsh8dayr	4zd57afzr3f4mbydt14j5mzqza		0	t	f	f	1773126764243
dehiwb8q9bnoi8f4mxzsh8dayr	46fd55wk57bdzq89debc4cxugr		0	t	f	f	1773126764293
dehiwb8q9bnoi8f4mxzsh8dayr	6a4bti99g3rtdmx11dhnihhg6r		0	t	f	f	1773126764344
dehiwb8q9bnoi8f4mxzsh8dayr	ccmjk1p1abffx87a4zni7n4uoh		0	t	f	f	1773126764394
dehiwb8q9bnoi8f4mxzsh8dayr	3bekgg684bb5iq6tfq1h95az3r		0	t	f	f	1773126764444
dehiwb8q9bnoi8f4mxzsh8dayr	93n7axewi7n9xpsis8z5d99bre		0	t	f	f	1773126764495
dehiwb8q9bnoi8f4mxzsh8dayr	m16j1q6rkfdpxguuksz7wmpuba		0	t	f	f	1773126764547
dehiwb8q9bnoi8f4mxzsh8dayr	dp4jszrpsjnjpjw1mth4ygithy		0	t	f	f	1773126764598
dehiwb8q9bnoi8f4mxzsh8dayr	udhm7t7fqfgc9k9funqdejmeea		0	t	f	f	1773126764651
dehiwb8q9bnoi8f4mxzsh8dayr	7e4ojpbykjntdmpu94y5ekub1c		0	t	f	f	1773126764703
dehiwb8q9bnoi8f4mxzsh8dayr	9mbmdxz1kidnmemmqi9ou5w1ah		0	t	f	f	1773126764757
dehiwb8q9bnoi8f4mxzsh8dayr	g7r88gtyqjfdzgnwhr9xyumzce		0	t	f	f	1773126764809
dehiwb8q9bnoi8f4mxzsh8dayr	cxtqjdhuqiydtmdmtdc1mesbfo		0	t	f	f	1773126764862
dehiwb8q9bnoi8f4mxzsh8dayr	hacoqz1mijy8db1u95mwsgt6pe		0	t	f	f	1773126764915
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.teams (id, createat, updateat, deleteat, displayname, name, description, email, type, companyname, alloweddomains, inviteid, schemeid, allowopeninvite, lastteamiconupdate, groupconstrained, cloudlimitsarchived) FROM stdin;
tufgabb37pdmzfspeitber78oa	1773126763190	1773126763190	0	Engineering	engineering	Software Engineering team at TechCorp	admin@techcorp.com	O			er8fizqdpjgw5m7ef14ztgk8do	\N	f	0	\N	f
s8e39snm5tnbxbgpeia5kpwzuo	1773126763809	1773126763809	0	Marketing	marketing	Marketing and Growth team	admin@techcorp.com	O			joahppjbapfsxpawwnoapxc15y	\N	f	0	\N	f
dehiwb8q9bnoi8f4mxzsh8dayr	1773126764122	1773126764122	0	TechCorp General	general	Company-wide communication hub	admin@techcorp.com	O			yfttnanknpyf8pf63snudux1xr	\N	f	0	\N	f
\.


--
-- Data for Name: temporaryposts; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.temporaryposts (postid, type, expireat, message, fileids) FROM stdin;
\.


--
-- Data for Name: termsofservice; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.termsofservice (id, createat, userid, text) FROM stdin;
\.


--
-- Data for Name: threadmemberships; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.threadmemberships (postid, userid, following, lastviewed, lastupdated, unreadmentions) FROM stdin;
fd51e1ms8fbfubjycuye8mairh	6a4bti99g3rtdmx11dhnihhg6r	t	1773126776624	1773126776624	0
fd51e1ms8fbfubjycuye8mairh	x916bcascjyyjrc5y8e5hbrgna	t	1773126776648	1773126776648	0
fd51e1ms8fbfubjycuye8mairh	ccmjk1p1abffx87a4zni7n4uoh	t	1773126776694	1773126776694	0
fd51e1ms8fbfubjycuye8mairh	4zd57afzr3f4mbydt14j5mzqza	t	1773126776719	1773126776719	0
fd51e1ms8fbfubjycuye8mairh	9mbmdxz1kidnmemmqi9ou5w1ah	t	1773126776769	1773126776769	0
smhfusfpcirhbgq9js6gwybwsh	4zd57afzr3f4mbydt14j5mzqza	t	1773126777327	1773126777327	0
smhfusfpcirhbgq9js6gwybwsh	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126777365	1773126777365	0
smhfusfpcirhbgq9js6gwybwsh	3bekgg684bb5iq6tfq1h95az3r	t	1773126777439	1773126777439	0
smhfusfpcirhbgq9js6gwybwsh	6a4bti99g3rtdmx11dhnihhg6r	t	1773126777471	1773126777471	0
5oezr9ccrbncuxdhtxuhjo6pho	9mbmdxz1kidnmemmqi9ou5w1ah	t	0	1773126777508	0
5oezr9ccrbncuxdhtxuhjo6pho	ccmjk1p1abffx87a4zni7n4uoh	t	1773126777512	1773126777512	0
5oezr9ccrbncuxdhtxuhjo6pho	4zd57afzr3f4mbydt14j5mzqza	t	1773126777538	1773126777538	0
5oezr9ccrbncuxdhtxuhjo6pho	x916bcascjyyjrc5y8e5hbrgna	t	1773126777586	1773126777586	0
5oezr9ccrbncuxdhtxuhjo6pho	46fd55wk57bdzq89debc4cxugr	t	1773126777623	1773126777623	0
cm7g4nhuyjbq9fr1furyz7emph	x916bcascjyyjrc5y8e5hbrgna	t	1773126777669	1773126777669	0
cm7g4nhuyjbq9fr1furyz7emph	6a4bti99g3rtdmx11dhnihhg6r	t	1773126777696	1773126777696	0
cm7g4nhuyjbq9fr1furyz7emph	ccmjk1p1abffx87a4zni7n4uoh	t	1773126777735	1773126777735	0
cm7g4nhuyjbq9fr1furyz7emph	3bekgg684bb5iq6tfq1h95az3r	t	1773126777769	1773126777769	0
oq4um7bawtd48fr4tfchj6zkce	ccmjk1p1abffx87a4zni7n4uoh	t	1773126777812	1773126777812	0
oq4um7bawtd48fr4tfchj6zkce	6a4bti99g3rtdmx11dhnihhg6r	t	1773126777846	1773126777846	0
oq4um7bawtd48fr4tfchj6zkce	4zd57afzr3f4mbydt14j5mzqza	t	1773126777878	1773126777878	0
oq4um7bawtd48fr4tfchj6zkce	x916bcascjyyjrc5y8e5hbrgna	t	1773126777902	1773126777902	0
oq4um7bawtd48fr4tfchj6zkce	g7r88gtyqjfdzgnwhr9xyumzce	t	1773126777955	1773126777955	0
u9b7ehb3kbnz5dkohhn3s6rt9y	9mbmdxz1kidnmemmqi9ou5w1ah	t	0	1773126778005	0
u9b7ehb3kbnz5dkohhn3s6rt9y	4zd57afzr3f4mbydt14j5mzqza	t	1773126778012	1773126778012	0
u9b7ehb3kbnz5dkohhn3s6rt9y	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126778043	1773126778043	0
uargsrccatrg5j17n9r7tq5ube	4zd57afzr3f4mbydt14j5mzqza	t	1773126778084	1773126778084	0
uargsrccatrg5j17n9r7tq5ube	ccmjk1p1abffx87a4zni7n4uoh	t	1773126778109	1773126778109	0
uargsrccatrg5j17n9r7tq5ube	3bekgg684bb5iq6tfq1h95az3r	t	1773126778181	1773126778181	0
uargsrccatrg5j17n9r7tq5ube	46fd55wk57bdzq89debc4cxugr	t	1773126778212	1773126778212	0
os3wyshrxtgkiqrypugky1zmyr	x916bcascjyyjrc5y8e5hbrgna	t	1773126778253	1773126778253	0
os3wyshrxtgkiqrypugky1zmyr	g7r88gtyqjfdzgnwhr9xyumzce	t	1773126778283	1773126778283	0
os3wyshrxtgkiqrypugky1zmyr	46fd55wk57bdzq89debc4cxugr	t	1773126778309	1773126778309	0
zs7apgtgpfn3bnxr9cxznwjpry	46fd55wk57bdzq89debc4cxugr	t	0	1773126778350	0
zs7apgtgpfn3bnxr9cxznwjpry	x916bcascjyyjrc5y8e5hbrgna	t	0	1773126778350	0
zs7apgtgpfn3bnxr9cxznwjpry	4zd57afzr3f4mbydt14j5mzqza	t	1773126778355	1773126778355	0
zs7apgtgpfn3bnxr9cxznwjpry	ccmjk1p1abffx87a4zni7n4uoh	t	1773126778393	1773126778393	0
zs7apgtgpfn3bnxr9cxznwjpry	3bekgg684bb5iq6tfq1h95az3r	t	1773126778442	1773126778442	0
rtdewtn5ein8uqwxqjq71jkiqh	4zd57afzr3f4mbydt14j5mzqza	t	1773126778868	1773126778868	0
rtdewtn5ein8uqwxqjq71jkiqh	g7r88gtyqjfdzgnwhr9xyumzce	t	1773126778929	1773126778929	0
rtdewtn5ein8uqwxqjq71jkiqh	ccmjk1p1abffx87a4zni7n4uoh	t	1773126778956	1773126778956	0
zj6hkh4ttpfazbhyrsz79ncedw	6a4bti99g3rtdmx11dhnihhg6r	t	1773126779403	1773126779403	0
zj6hkh4ttpfazbhyrsz79ncedw	4zd57afzr3f4mbydt14j5mzqza	t	1773126779437	1773126779437	0
zj6hkh4ttpfazbhyrsz79ncedw	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126779459	1773126779459	0
urspsr5koirhbfi6ekpezr18hh	ccmjk1p1abffx87a4zni7n4uoh	t	1773126779558	1773126779558	0
urspsr5koirhbfi6ekpezr18hh	3bekgg684bb5iq6tfq1h95az3r	t	1773126779584	1773126779584	0
s38d45f3u3yuj8t8auhrmdgtor	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126779658	1773126779658	0
s38d45f3u3yuj8t8auhrmdgtor	6a4bti99g3rtdmx11dhnihhg6r	t	1773126779681	1773126779681	0
hn887u9w6pypuqkpqj3a8u1j6y	ccmjk1p1abffx87a4zni7n4uoh	t	1773126779800	1773126779800	0
hn887u9w6pypuqkpqj3a8u1j6y	g7r88gtyqjfdzgnwhr9xyumzce	t	1773126779833	1773126779833	0
hn887u9w6pypuqkpqj3a8u1j6y	x916bcascjyyjrc5y8e5hbrgna	t	1773126779869	1773126779869	0
hn887u9w6pypuqkpqj3a8u1j6y	hacoqz1mijy8db1u95mwsgt6pe	t	1773126779912	1773126779912	0
hn887u9w6pypuqkpqj3a8u1j6y	4zd57afzr3f4mbydt14j5mzqza	t	1773126779936	1773126779936	0
zgcemj5typgct8zb5mh4a7kxue	g7r88gtyqjfdzgnwhr9xyumzce	t	0	1773126779986	0
zgcemj5typgct8zb5mh4a7kxue	x916bcascjyyjrc5y8e5hbrgna	t	1773126779996	1773126779996	0
zgcemj5typgct8zb5mh4a7kxue	46fd55wk57bdzq89debc4cxugr	t	1773126780019	1773126780019	0
zgcemj5typgct8zb5mh4a7kxue	ccmjk1p1abffx87a4zni7n4uoh	t	1773126780062	1773126780062	0
bfyx5zu8k7b45mkmhe4ex4srwc	x916bcascjyyjrc5y8e5hbrgna	t	1773126780107	1773126780107	0
bfyx5zu8k7b45mkmhe4ex4srwc	g7r88gtyqjfdzgnwhr9xyumzce	t	1773126780165	1773126780165	0
bfyx5zu8k7b45mkmhe4ex4srwc	46fd55wk57bdzq89debc4cxugr	t	1773126780193	1773126780193	0
4hnjptbpmpnmzgdqdth51qxt3y	x916bcascjyyjrc5y8e5hbrgna	t	1773126780239	1773126780239	0
4hnjptbpmpnmzgdqdth51qxt3y	46fd55wk57bdzq89debc4cxugr	t	1773126780272	1773126780272	0
4hnjptbpmpnmzgdqdth51qxt3y	4zd57afzr3f4mbydt14j5mzqza	t	1773126780304	1773126780304	0
4hnjptbpmpnmzgdqdth51qxt3y	g7r88gtyqjfdzgnwhr9xyumzce	t	1773126780335	1773126780335	0
uwc5r816rfnodbnn35erk8ejgo	m16j1q6rkfdpxguuksz7wmpuba	t	1773126780389	1773126780389	0
uwc5r816rfnodbnn35erk8ejgo	dp4jszrpsjnjpjw1mth4ygithy	t	1773126780420	1773126780420	0
uwc5r816rfnodbnn35erk8ejgo	93n7axewi7n9xpsis8z5d99bre	t	1773126780447	1773126780447	0
uwc5r816rfnodbnn35erk8ejgo	7e4ojpbykjntdmpu94y5ekub1c	t	1773126780491	1773126780491	0
duk3c7xk9bnemr57t3kda66zwh	93n7axewi7n9xpsis8z5d99bre	t	0	1773126780527	0
duk3c7xk9bnemr57t3kda66zwh	m16j1q6rkfdpxguuksz7wmpuba	t	1773126780531	1773126780531	0
duk3c7xk9bnemr57t3kda66zwh	7e4ojpbykjntdmpu94y5ekub1c	t	1773126780565	1773126780565	0
duk3c7xk9bnemr57t3kda66zwh	dp4jszrpsjnjpjw1mth4ygithy	t	1773126780590	1773126780590	0
duk3c7xk9bnemr57t3kda66zwh	9mbmdxz1kidnmemmqi9ou5w1ah	t	1773126780625	1773126780625	0
i9a9qqzfginezb1o6b8a3siuoh	93n7axewi7n9xpsis8z5d99bre	t	1773126780793	1773126780793	0
ayb41zzfr3nrzq8x9w39eabrhw	93n7axewi7n9xpsis8z5d99bre	t	1773126781066	1773126781066	0
q3ij1tnz7pfcmjkw13u57kpyie	93n7axewi7n9xpsis8z5d99bre	t	1773126781149	1773126781149	0
q3ij1tnz7pfcmjkw13u57kpyie	4zd57afzr3f4mbydt14j5mzqza	t	1773126781202	1773126781202	0
q3ij1tnz7pfcmjkw13u57kpyie	9mbmdxz1kidnmemmqi9ou5w1ah	t	1773126781285	1773126781285	0
zj5n1igz83g7bnoujg81u9c9kh	udhm7t7fqfgc9k9funqdejmeea	t	0	1773126781351	0
zj5n1igz83g7bnoujg81u9c9kh	m16j1q6rkfdpxguuksz7wmpuba	t	1773126781389	1773126781389	0
zj5n1igz83g7bnoujg81u9c9kh	hacoqz1mijy8db1u95mwsgt6pe	t	1773126781455	1773126781455	0
ituauyjmk7n35jriu16fre44eh	ccmjk1p1abffx87a4zni7n4uoh	t	1773126781560	1773126781560	0
ituauyjmk7n35jriu16fre44eh	3bekgg684bb5iq6tfq1h95az3r	t	1773126781620	1773126781620	0
sd8n1zw1obngingpzu9dnpz9xe	ccmjk1p1abffx87a4zni7n4uoh	t	1773126781708	1773126781708	0
sd8n1zw1obngingpzu9dnpz9xe	4zd57afzr3f4mbydt14j5mzqza	t	1773126781771	1773126781771	0
bq74ebs4zbyn8msgbpijcfj5rc	dp4jszrpsjnjpjw1mth4ygithy	t	1773126781848	1773126781848	0
bq74ebs4zbyn8msgbpijcfj5rc	93n7axewi7n9xpsis8z5d99bre	t	1773126781904	1773126781904	0
c3xjtk6dt7gg3puenbx5qtqz8r	ccmjk1p1abffx87a4zni7n4uoh	t	1773126782025	1773126782025	0
c3xjtk6dt7gg3puenbx5qtqz8r	4zd57afzr3f4mbydt14j5mzqza	t	1773126782084	1773126782084	0
dmpbf4epffrkmd9biy83m5qitw	ccmjk1p1abffx87a4zni7n4uoh	t	1773126782195	1773126782195	0
dmpbf4epffrkmd9biy83m5qitw	dp4jszrpsjnjpjw1mth4ygithy	t	1773126782256	1773126782256	0
8p613yhn3tr5zjiuy8ebxazfih	6a4bti99g3rtdmx11dhnihhg6r	t	1773126782308	1773126782308	0
8p613yhn3tr5zjiuy8ebxazfih	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126782370	1773126782370	0
1yfw8sxcrpym3c69odw39n155e	m16j1q6rkfdpxguuksz7wmpuba	t	0	1773126780677	0
1yfw8sxcrpym3c69odw39n155e	dp4jszrpsjnjpjw1mth4ygithy	t	1773126780682	1773126780682	0
1yfw8sxcrpym3c69odw39n155e	93n7axewi7n9xpsis8z5d99bre	t	1773126780718	1773126780718	0
1yfw8sxcrpym3c69odw39n155e	7e4ojpbykjntdmpu94y5ekub1c	t	1773126780741	1773126780741	0
i9a9qqzfginezb1o6b8a3siuoh	9mbmdxz1kidnmemmqi9ou5w1ah	t	1773126780820	1773126780820	0
i9a9qqzfginezb1o6b8a3siuoh	7e4ojpbykjntdmpu94y5ekub1c	t	1773126780859	1773126780859	0
ssjhm5cqwtgazfouy7phuxnyho	93n7axewi7n9xpsis8z5d99bre	t	1773126780910	1773126780910	0
ssjhm5cqwtgazfouy7phuxnyho	m16j1q6rkfdpxguuksz7wmpuba	t	1773126780940	1773126780940	0
ayb41zzfr3nrzq8x9w39eabrhw	m16j1q6rkfdpxguuksz7wmpuba	t	1773126781038	1773126781038	0
q3ij1tnz7pfcmjkw13u57kpyie	m16j1q6rkfdpxguuksz7wmpuba	t	1773126781249	1773126781249	0
c3xjtk6dt7gg3puenbx5qtqz8r	6a4bti99g3rtdmx11dhnihhg6r	t	1773126782058	1773126782058	0
c3xjtk6dt7gg3puenbx5qtqz8r	46fd55wk57bdzq89debc4cxugr	t	1773126782122	1773126782122	0
8p613yhn3tr5zjiuy8ebxazfih	m16j1q6rkfdpxguuksz7wmpuba	t	1773126782443	1773126782443	0
qkrfhk9y7idoxbohh8dzaxqaxo	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126782584	1773126782584	0
qkrfhk9y7idoxbohh8dzaxqaxo	hacoqz1mijy8db1u95mwsgt6pe	t	1773126782644	1773126782644	0
ydy7j6ux17n73y6cezo43mopay	46fd55wk57bdzq89debc4cxugr	t	1773126782708	1773126782708	0
jba7dsp5apbq5pm4z575nndqfa	hacoqz1mijy8db1u95mwsgt6pe	t	1773126782832	1773126782832	0
ssjhm5cqwtgazfouy7phuxnyho	dp4jszrpsjnjpjw1mth4ygithy	t	1773126780967	1773126780967	0
ayb41zzfr3nrzq8x9w39eabrhw	dp4jszrpsjnjpjw1mth4ygithy	t	1773126781103	1773126781103	0
q3ij1tnz7pfcmjkw13u57kpyie	udhm7t7fqfgc9k9funqdejmeea	t	0	1773126781142	0
q3ij1tnz7pfcmjkw13u57kpyie	x916bcascjyyjrc5y8e5hbrgna	t	1773126781178	1773126781178	0
zj5n1igz83g7bnoujg81u9c9kh	4zd57afzr3f4mbydt14j5mzqza	t	1773126781355	1773126781355	0
zj5n1igz83g7bnoujg81u9c9kh	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126781424	1773126781424	0
zj5n1igz83g7bnoujg81u9c9kh	6a4bti99g3rtdmx11dhnihhg6r	t	1773126781498	1773126781498	0
ituauyjmk7n35jriu16fre44eh	x916bcascjyyjrc5y8e5hbrgna	t	0	1773126781556	0
ituauyjmk7n35jriu16fre44eh	46fd55wk57bdzq89debc4cxugr	t	1773126781593	1773126781593	0
ituauyjmk7n35jriu16fre44eh	9mbmdxz1kidnmemmqi9ou5w1ah	t	1773126781661	1773126781661	0
sd8n1zw1obngingpzu9dnpz9xe	6a4bti99g3rtdmx11dhnihhg6r	t	0	1773126781700	0
sd8n1zw1obngingpzu9dnpz9xe	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126781737	1773126781737	0
sd8n1zw1obngingpzu9dnpz9xe	46fd55wk57bdzq89debc4cxugr	t	1773126781810	1773126781810	0
bq74ebs4zbyn8msgbpijcfj5rc	udhm7t7fqfgc9k9funqdejmeea	t	1773126781877	1773126781877	0
bq74ebs4zbyn8msgbpijcfj5rc	3bekgg684bb5iq6tfq1h95az3r	t	1773126781950	1773126781950	0
bq74ebs4zbyn8msgbpijcfj5rc	m16j1q6rkfdpxguuksz7wmpuba	t	1773126781981	1773126781981	0
dmpbf4epffrkmd9biy83m5qitw	93n7axewi7n9xpsis8z5d99bre	t	1773126782166	1773126782166	0
dmpbf4epffrkmd9biy83m5qitw	7e4ojpbykjntdmpu94y5ekub1c	t	1773126782221	1773126782221	0
8p613yhn3tr5zjiuy8ebxazfih	4zd57afzr3f4mbydt14j5mzqza	t	1773126782343	1773126782343	0
8p613yhn3tr5zjiuy8ebxazfih	udhm7t7fqfgc9k9funqdejmeea	t	1773126782498	1773126782498	0
qkrfhk9y7idoxbohh8dzaxqaxo	46fd55wk57bdzq89debc4cxugr	t	1773126782611	1773126782611	0
ydy7j6ux17n73y6cezo43mopay	93n7axewi7n9xpsis8z5d99bre	t	1773126782732	1773126782732	0
jba7dsp5apbq5pm4z575nndqfa	cxtqjdhuqiydtmdmtdc1mesbfo	t	1773126782773	1773126782773	0
jba7dsp5apbq5pm4z575nndqfa	4zd57afzr3f4mbydt14j5mzqza	t	1773126782802	1773126782802	0
jba7dsp5apbq5pm4z575nndqfa	udhm7t7fqfgc9k9funqdejmeea	t	1773126782878	1773126782878	0
\.


--
-- Data for Name: threads; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.threads (postid, replycount, lastreplyat, participants, channelid, threaddeleteat, threadteamid) FROM stdin;
fd51e1ms8fbfubjycuye8mairh	6	1773126776742	["6a4bti99g3rtdmx11dhnihhg6r", "x916bcascjyyjrc5y8e5hbrgna", "ccmjk1p1abffx87a4zni7n4uoh", "4zd57afzr3f4mbydt14j5mzqza", "9mbmdxz1kidnmemmqi9ou5w1ah"]	xbdo3t9uq7gxmgnk4xopy1pkee	\N	tufgabb37pdmzfspeitber78oa
smhfusfpcirhbgq9js6gwybwsh	5	1773126777450	["4zd57afzr3f4mbydt14j5mzqza", "cxtqjdhuqiydtmdmtdc1mesbfo", "3bekgg684bb5iq6tfq1h95az3r", "6a4bti99g3rtdmx11dhnihhg6r"]	xbdo3t9uq7gxmgnk4xopy1pkee	\N	tufgabb37pdmzfspeitber78oa
5oezr9ccrbncuxdhtxuhjo6pho	4	1773126777598	["ccmjk1p1abffx87a4zni7n4uoh", "4zd57afzr3f4mbydt14j5mzqza", "x916bcascjyyjrc5y8e5hbrgna", "46fd55wk57bdzq89debc4cxugr"]	xbdo3t9uq7gxmgnk4xopy1pkee	\N	tufgabb37pdmzfspeitber78oa
cm7g4nhuyjbq9fr1furyz7emph	4	1773126777747	["x916bcascjyyjrc5y8e5hbrgna", "6a4bti99g3rtdmx11dhnihhg6r", "ccmjk1p1abffx87a4zni7n4uoh", "3bekgg684bb5iq6tfq1h95az3r"]	xbdo3t9uq7gxmgnk4xopy1pkee	\N	tufgabb37pdmzfspeitber78oa
oq4um7bawtd48fr4tfchj6zkce	5	1773126777930	["ccmjk1p1abffx87a4zni7n4uoh", "6a4bti99g3rtdmx11dhnihhg6r", "4zd57afzr3f4mbydt14j5mzqza", "x916bcascjyyjrc5y8e5hbrgna", "g7r88gtyqjfdzgnwhr9xyumzce"]	qk4rrkf1stnn5ydh15bgh16nth	\N	tufgabb37pdmzfspeitber78oa
u9b7ehb3kbnz5dkohhn3s6rt9y	2	1773126778022	["4zd57afzr3f4mbydt14j5mzqza", "cxtqjdhuqiydtmdmtdc1mesbfo"]	qk4rrkf1stnn5ydh15bgh16nth	\N	tufgabb37pdmzfspeitber78oa
uargsrccatrg5j17n9r7tq5ube	5	1773126778191	["4zd57afzr3f4mbydt14j5mzqza", "ccmjk1p1abffx87a4zni7n4uoh", "3bekgg684bb5iq6tfq1h95az3r", "46fd55wk57bdzq89debc4cxugr"]	j443od6puifhjf85mfwk55h8ec	\N	tufgabb37pdmzfspeitber78oa
os3wyshrxtgkiqrypugky1zmyr	3	1773126778296	["x916bcascjyyjrc5y8e5hbrgna", "g7r88gtyqjfdzgnwhr9xyumzce", "46fd55wk57bdzq89debc4cxugr"]	j443od6puifhjf85mfwk55h8ec	\N	tufgabb37pdmzfspeitber78oa
zs7apgtgpfn3bnxr9cxznwjpry	3	1773126778415	["4zd57afzr3f4mbydt14j5mzqza", "ccmjk1p1abffx87a4zni7n4uoh", "3bekgg684bb5iq6tfq1h95az3r"]	j443od6puifhjf85mfwk55h8ec	\N	tufgabb37pdmzfspeitber78oa
rtdewtn5ein8uqwxqjq71jkiqh	4	1773126778939	["4zd57afzr3f4mbydt14j5mzqza", "g7r88gtyqjfdzgnwhr9xyumzce", "ccmjk1p1abffx87a4zni7n4uoh"]	dewd9f48ij85xgq7tfte859qfa	\N	tufgabb37pdmzfspeitber78oa
zj6hkh4ttpfazbhyrsz79ncedw	3	1773126779447	["6a4bti99g3rtdmx11dhnihhg6r", "4zd57afzr3f4mbydt14j5mzqza", "cxtqjdhuqiydtmdmtdc1mesbfo"]	dewd9f48ij85xgq7tfte859qfa	\N	tufgabb37pdmzfspeitber78oa
urspsr5koirhbfi6ekpezr18hh	4	1773126779570	["ccmjk1p1abffx87a4zni7n4uoh", "3bekgg684bb5iq6tfq1h95az3r"]	bbekt5pgxfnc5qmpwaxux3py1a	\N	tufgabb37pdmzfspeitber78oa
s38d45f3u3yuj8t8auhrmdgtor	3	1773126779668	["cxtqjdhuqiydtmdmtdc1mesbfo", "6a4bti99g3rtdmx11dhnihhg6r"]	bbekt5pgxfnc5qmpwaxux3py1a	\N	tufgabb37pdmzfspeitber78oa
hn887u9w6pypuqkpqj3a8u1j6y	5	1773126779923	["ccmjk1p1abffx87a4zni7n4uoh", "g7r88gtyqjfdzgnwhr9xyumzce", "x916bcascjyyjrc5y8e5hbrgna", "hacoqz1mijy8db1u95mwsgt6pe", "4zd57afzr3f4mbydt14j5mzqza"]	rmsexzhn3jgy7f4kbgnczsa3sa	\N	tufgabb37pdmzfspeitber78oa
zgcemj5typgct8zb5mh4a7kxue	3	1773126780036	["x916bcascjyyjrc5y8e5hbrgna", "46fd55wk57bdzq89debc4cxugr", "ccmjk1p1abffx87a4zni7n4uoh"]	rmsexzhn3jgy7f4kbgnczsa3sa	\N	tufgabb37pdmzfspeitber78oa
bfyx5zu8k7b45mkmhe4ex4srwc	4	1773126780175	["x916bcascjyyjrc5y8e5hbrgna", "g7r88gtyqjfdzgnwhr9xyumzce", "46fd55wk57bdzq89debc4cxugr"]	et85fk3eqpgrip4z9eydcg4weo	\N	tufgabb37pdmzfspeitber78oa
4hnjptbpmpnmzgdqdth51qxt3y	4	1773126780317	["x916bcascjyyjrc5y8e5hbrgna", "46fd55wk57bdzq89debc4cxugr", "4zd57afzr3f4mbydt14j5mzqza", "g7r88gtyqjfdzgnwhr9xyumzce"]	mjjwsjpbnt8rxyp7n5mt1f3syw	\N	tufgabb37pdmzfspeitber78oa
uwc5r816rfnodbnn35erk8ejgo	4	1773126780465	["m16j1q6rkfdpxguuksz7wmpuba", "dp4jszrpsjnjpjw1mth4ygithy", "93n7axewi7n9xpsis8z5d99bre", "7e4ojpbykjntdmpu94y5ekub1c"]	scj33w14etykfdaydd3cqcae5w	\N	s8e39snm5tnbxbgpeia5kpwzuo
duk3c7xk9bnemr57t3kda66zwh	4	1773126780611	["m16j1q6rkfdpxguuksz7wmpuba", "7e4ojpbykjntdmpu94y5ekub1c", "dp4jszrpsjnjpjw1mth4ygithy", "9mbmdxz1kidnmemmqi9ou5w1ah"]	scj33w14etykfdaydd3cqcae5w	\N	s8e39snm5tnbxbgpeia5kpwzuo
1yfw8sxcrpym3c69odw39n155e	3	1773126780727	["dp4jszrpsjnjpjw1mth4ygithy", "93n7axewi7n9xpsis8z5d99bre", "7e4ojpbykjntdmpu94y5ekub1c"]	7ijgcabphifx7mwe9g6w9paemy	\N	s8e39snm5tnbxbgpeia5kpwzuo
i9a9qqzfginezb1o6b8a3siuoh	3	1773126780837	["93n7axewi7n9xpsis8z5d99bre", "9mbmdxz1kidnmemmqi9ou5w1ah", "7e4ojpbykjntdmpu94y5ekub1c"]	qiiq57tw6jbru8zhkytut8i64e	\N	s8e39snm5tnbxbgpeia5kpwzuo
ssjhm5cqwtgazfouy7phuxnyho	3	1773126780953	["93n7axewi7n9xpsis8z5d99bre", "m16j1q6rkfdpxguuksz7wmpuba", "dp4jszrpsjnjpjw1mth4ygithy"]	4rt4rx5mt38b38y9ec93k89boo	\N	s8e39snm5tnbxbgpeia5kpwzuo
ayb41zzfr3nrzq8x9w39eabrhw	4	1773126781082	["m16j1q6rkfdpxguuksz7wmpuba", "93n7axewi7n9xpsis8z5d99bre", "dp4jszrpsjnjpjw1mth4ygithy"]	3zf3d5jjnfymug7cq1ucdwqrmo	\N	s8e39snm5tnbxbgpeia5kpwzuo
q3ij1tnz7pfcmjkw13u57kpyie	5	1773126781263	["93n7axewi7n9xpsis8z5d99bre", "x916bcascjyyjrc5y8e5hbrgna", "4zd57afzr3f4mbydt14j5mzqza", "m16j1q6rkfdpxguuksz7wmpuba", "9mbmdxz1kidnmemmqi9ou5w1ah"]	5b4hke3753y73feti3hhtfbgiy	\N	dehiwb8q9bnoi8f4mxzsh8dayr
zj5n1igz83g7bnoujg81u9c9kh	5	1773126781472	["4zd57afzr3f4mbydt14j5mzqza", "m16j1q6rkfdpxguuksz7wmpuba", "cxtqjdhuqiydtmdmtdc1mesbfo", "hacoqz1mijy8db1u95mwsgt6pe", "6a4bti99g3rtdmx11dhnihhg6r"]	5b4hke3753y73feti3hhtfbgiy	\N	dehiwb8q9bnoi8f4mxzsh8dayr
ituauyjmk7n35jriu16fre44eh	4	1773126781636	["ccmjk1p1abffx87a4zni7n4uoh", "46fd55wk57bdzq89debc4cxugr", "3bekgg684bb5iq6tfq1h95az3r", "9mbmdxz1kidnmemmqi9ou5w1ah"]	5b4hke3753y73feti3hhtfbgiy	\N	dehiwb8q9bnoi8f4mxzsh8dayr
sd8n1zw1obngingpzu9dnpz9xe	4	1773126781781	["ccmjk1p1abffx87a4zni7n4uoh", "cxtqjdhuqiydtmdmtdc1mesbfo", "4zd57afzr3f4mbydt14j5mzqza", "46fd55wk57bdzq89debc4cxugr"]	1s9nagudoiboirmb7ckj1mukfy	\N	dehiwb8q9bnoi8f4mxzsh8dayr
bq74ebs4zbyn8msgbpijcfj5rc	5	1773126781960	["dp4jszrpsjnjpjw1mth4ygithy", "udhm7t7fqfgc9k9funqdejmeea", "93n7axewi7n9xpsis8z5d99bre", "3bekgg684bb5iq6tfq1h95az3r", "m16j1q6rkfdpxguuksz7wmpuba"]	1s9nagudoiboirmb7ckj1mukfy	\N	dehiwb8q9bnoi8f4mxzsh8dayr
c3xjtk6dt7gg3puenbx5qtqz8r	4	1773126782101	["ccmjk1p1abffx87a4zni7n4uoh", "6a4bti99g3rtdmx11dhnihhg6r", "4zd57afzr3f4mbydt14j5mzqza", "46fd55wk57bdzq89debc4cxugr"]	1s9nagudoiboirmb7ckj1mukfy	\N	dehiwb8q9bnoi8f4mxzsh8dayr
dmpbf4epffrkmd9biy83m5qitw	4	1773126782243	["93n7axewi7n9xpsis8z5d99bre", "ccmjk1p1abffx87a4zni7n4uoh", "7e4ojpbykjntdmpu94y5ekub1c", "dp4jszrpsjnjpjw1mth4ygithy"]	8k1ahz7c8pgmjyco414pgi5f4y	\N	dehiwb8q9bnoi8f4mxzsh8dayr
8p613yhn3tr5zjiuy8ebxazfih	6	1773126782472	["6a4bti99g3rtdmx11dhnihhg6r", "4zd57afzr3f4mbydt14j5mzqza", "cxtqjdhuqiydtmdmtdc1mesbfo", "m16j1q6rkfdpxguuksz7wmpuba", "udhm7t7fqfgc9k9funqdejmeea"]	7aqugqd4dprbzcfcnm8ouuqczc	\N	dehiwb8q9bnoi8f4mxzsh8dayr
qkrfhk9y7idoxbohh8dzaxqaxo	4	1773126782627	["cxtqjdhuqiydtmdmtdc1mesbfo", "46fd55wk57bdzq89debc4cxugr", "hacoqz1mijy8db1u95mwsgt6pe"]	i14jg6ym6tbfmpa93dq5usgrty	\N	dehiwb8q9bnoi8f4mxzsh8dayr
jba7dsp5apbq5pm4z575nndqfa	4	1773126782852	["cxtqjdhuqiydtmdmtdc1mesbfo", "4zd57afzr3f4mbydt14j5mzqza", "hacoqz1mijy8db1u95mwsgt6pe", "udhm7t7fqfgc9k9funqdejmeea"]	h4d4ekghxin7bnutsuomgd776w	\N	dehiwb8q9bnoi8f4mxzsh8dayr
ydy7j6ux17n73y6cezo43mopay	3	1773126782720	["46fd55wk57bdzq89debc4cxugr", "93n7axewi7n9xpsis8z5d99bre"]	i14jg6ym6tbfmpa93dq5usgrty	\N	dehiwb8q9bnoi8f4mxzsh8dayr
\.


--
-- Data for Name: tokens; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.tokens (token, createat, type, extra) FROM stdin;
\.


--
-- Data for Name: translations; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.translations (objectid, dstlang, objecttype, providerid, normhash, text, confidence, meta, updateat) FROM stdin;
\.


--
-- Data for Name: uploadsessions; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.uploadsessions (id, type, createat, userid, channelid, filename, path, filesize, fileoffset, remoteid, reqfileid) FROM stdin;
\.


--
-- Data for Name: useraccesstokens; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.useraccesstokens (id, token, userid, description, isactive) FROM stdin;
\.


--
-- Data for Name: usergroups; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.usergroups (id, name, displayname, description, source, remoteid, createat, updateat, deleteat, allowreference) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.users (id, createat, updateat, deleteat, username, password, authdata, authservice, email, emailverified, nickname, firstname, lastname, roles, allowmarketing, props, notifyprops, lastpasswordupdate, lastpictureupdate, failedattempts, locale, mfaactive, mfasecret, "position", timezone, remoteid, lastlogin, mfausedtimestamps) FROM stdin;
uw9ayeotajnate67greqnm1t6w	1773126731107	1773126731174	0	calls		\N		calls@localhost	f		Calls		system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126731107	1773126731174	0	en	f			{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}	\N	0	null
x916bcascjyyjrc5y8e5hbrgna	1773126756292	1773126770689	0	john.doe	$pbkdf2$f=SHA256,w=600000,l=32$e9UPSTF/RLoF8YNZp5KALA$cWI8hjaeCAbBdNf+eDGO4udD9YMAuXPXdHVA5uo8BQU	\N		john.doe@techcorp.com	f	JD	John	Doe	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126756292	0	0	en	f		Engineering Manager	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126770688	[]
4zd57afzr3f4mbydt14j5mzqza	1773126756787	1773126771072	0	jane.smith	$pbkdf2$f=SHA256,w=600000,l=32$mSzWBWPq9Itty2TWUcgP3Q$wHK9uYgG41pgDt7CnaKMrM2uYMgxCaYOyVurpBgm3Z8	\N		jane.smith@techcorp.com	f	jsmith	Jane	Smith	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126756787	0	0	en	f		Senior Developer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126771070	[]
46fd55wk57bdzq89debc4cxugr	1773126757285	1773126771417	0	bob.wilson	$pbkdf2$f=SHA256,w=600000,l=32$oGXbyzl1AiUw/wuj1REsVA$V/2RMC2kx/iaRDBkuXMril7yTesqOvYoZPxGM7UmY8A	\N		bob.wilson@techcorp.com	f	bobw	Bob	Wilson	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126757285	0	0	en	f		DevOps Engineer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126771416	[]
ccmjk1p1abffx87a4zni7n4uoh	1773126758278	1773126772232	0	charlie.brown	$pbkdf2$f=SHA256,w=600000,l=32$J1pviwAC9WeSBARFzMbLbg$SOL06m9JAqdey93bBsvjlUEepq4aCvRz8ek6jCU3EVY	\N		charlie.brown@techcorp.com	f	charlie	Charlie	Brown	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126758278	0	0	en	f		Backend Developer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126772231	[]
3bekgg684bb5iq6tfq1h95az3r	1773126758650	1773126772593	0	diana.prince	$pbkdf2$f=SHA256,w=600000,l=32$p32VE8g6llVgcmtRVsDFTw$E2tHe855gVgnm9cv/1LCLnI7gcE+d7RtEMlddb95rX8	\N		diana.prince@techcorp.com	f	diana	Diana	Prince	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126758650	0	0	en	f		QA Engineer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126772591	[]
93n7axewi7n9xpsis8z5d99bre	1773126759017	1773126773070	0	emma.davis	$pbkdf2$f=SHA256,w=600000,l=32$2nwpjCT7yyNy3yVtnqgflQ$LtMTh7qoMUyh+TprUp2+jbUzBKFfG2VMNcS4ZM2IPII	\N		emma.davis@techcorp.com	f	emmad	Emma	Davis	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126759017	0	0	en	f		Marketing Manager	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126773068	[]
m16j1q6rkfdpxguuksz7wmpuba	1773126759513	1773126773428	0	frank.miller	$pbkdf2$f=SHA256,w=600000,l=32$gebX4CBjJiwi/HqMFMnAGQ$L/dmptH0VDcPqZbtN2V7DYAjhZCoruMRyU+nZfgpG2M	\N		frank.miller@techcorp.com	f	frankm	Frank	Miller	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126759513	0	0	en	f		Content Writer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126773427	[]
dp4jszrpsjnjpjw1mth4ygithy	1773126759989	1773126773905	0	grace.lee	$pbkdf2$f=SHA256,w=600000,l=32$KrfnUNwWUx/VsSYwe483hQ$pDG2Ouq7sDbfM1C9RDWqXhMup98paZvj0vm254FOBpg	\N		grace.lee@techcorp.com	f	gracel	Grace	Lee	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126759989	0	0	en	f		UI/UX Designer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126773904	[]
udhm7t7fqfgc9k9funqdejmeea	1773126760488	1773126774382	0	henry.taylor	$pbkdf2$f=SHA256,w=600000,l=32$wXJa/U5NO+/pSM9dXMRn6A$U4mNQL++Yj544UexwZ9Koqnp96pwIhyPsTxeyD0MoLI	\N		henry.taylor@techcorp.com	f	henryt	Henry	Taylor	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126760488	0	0	en	f		HR Manager	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126774380	[]
6a4bti99g3rtdmx11dhnihhg6r	1773126757779	1773126771756	0	alice.johnson	$pbkdf2$f=SHA256,w=600000,l=32$vU+K0mDSjjPqmpMdUEjUxw$i20fL1TnfTW7nKhxyXLqrx8ZdryUCDenk88xkO7dhrg	\N		alice.johnson@techcorp.com	f	alicej	Alice	Johnson	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126757779	0	0	en	f		Frontend Developer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126771755	[]
cxtqjdhuqiydtmdmtdc1mesbfo	1773126762355	1773126776032	0	mike.ross	$pbkdf2$f=SHA256,w=600000,l=32$EluuVE8HpxlDDCNfeSnJdw$p+ZsQ9rP/srdXP0eqaCnirmF0dqhFK6Vs3T4gDrYhVI	\N		mike.ross@techcorp.com	f	miker	Mike	Ross	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126762355	0	0	en	f		Junior Developer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126776030	[]
7e4ojpbykjntdmpu94y5ekub1c	1773126760983	1773126774859	0	ivy.chen	$pbkdf2$f=SHA256,w=600000,l=32$JaHk055UjpWncQrjGISbVw$MUiVVu2rm8gbzrkfP8rgrgRuPtsQdCatbnVzsfzQdhY	\N		ivy.chen@techcorp.com	f	ivyc	Ivy	Chen	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126760983	0	0	en	f		Data Analyst	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126774857	[]
7kq76ce63id48nkz4hcp5rg3xh	1773126750843	1773126764134	0	admin	$pbkdf2$f=SHA256,w=600000,l=32$b9DQ08xp8OXrL7MHP5FF4w$Kb88GUDN5sg4t0mts3skZLF52ztIm6bqk2EjRQ86R4g	\N		admin@techcorp.com	f		System	Admin	system_admin system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126750843	0	0	en	f		System Administrator	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126751815	[]
hacoqz1mijy8db1u95mwsgt6pe	1773126762729	1773126776510	0	natalie.kim	$pbkdf2$f=SHA256,w=600000,l=32$iB87bNG/VMXEyMFgpF1kkA$pMY8QOYQUzkGAWStkiWD2XT4wvkpU0MmBKeuYX510Lc	\N		natalie.kim@techcorp.com	f	nataliek	Natalie	Kim	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126762729	0	0	en	f		Technical Writer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126776508	[]
9mbmdxz1kidnmemmqi9ou5w1ah	1773126761480	1773126775336	0	kevin.martinez	$pbkdf2$f=SHA256,w=600000,l=32$901PtP6q7zg92iJ/gsmeug$ExJkfuIo9EYaxRX14Zl/J1v8IBoS82HRARVuKsnnsF0	\N		kevin.martinez@techcorp.com	f	kevinm	Kevin	Martinez	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126761480	0	0	en	f		Product Manager	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126775335	[]
g7r88gtyqjfdzgnwhr9xyumzce	1773126761861	1773126775696	0	lisa.wang	$pbkdf2$f=SHA256,w=600000,l=32$KAXhYuNOR6FbF7oFEyA0CA$3ElIZrm9E8ZZBQEK/3egAkQrywF+BAMN3kq3nTtfJIw	\N		lisa.wang@techcorp.com	f	lisaw	Lisa	Wang	system_user	f	{}	{"push": "mention", "email": "true", "channel": "true", "desktop": "mention", "comments": "never", "first_name": "false", "push_status": "online", "mention_keys": "", "push_threads": "all", "desktop_sound": "true", "email_threads": "all", "desktop_threads": "all"}	1773126761861	0	0	en	f		Security Engineer	{"manualTimezone": "", "automaticTimezone": "", "useAutomaticTimezone": "true"}		1773126775694	[]
\.


--
-- Data for Name: usertermsofservice; Type: TABLE DATA; Schema: public; Owner: mmuser
--

COPY public.usertermsofservice (userid, termsofserviceid, createat) FROM stdin;
\.


--
-- Name: accesscontrolpolicies accesscontrolpolicies_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.accesscontrolpolicies
    ADD CONSTRAINT accesscontrolpolicies_pkey PRIMARY KEY (id);


--
-- Name: accesscontrolpolicyhistory accesscontrolpolicyhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.accesscontrolpolicyhistory
    ADD CONSTRAINT accesscontrolpolicyhistory_pkey PRIMARY KEY (id, revision);


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: bots bots_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.bots
    ADD CONSTRAINT bots_pkey PRIMARY KEY (userid);


--
-- Name: calls_channels calls_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.calls_channels
    ADD CONSTRAINT calls_channels_pkey PRIMARY KEY (channelid);


--
-- Name: calls_jobs calls_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.calls_jobs
    ADD CONSTRAINT calls_jobs_pkey PRIMARY KEY (id);


--
-- Name: calls calls_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.calls
    ADD CONSTRAINT calls_pkey PRIMARY KEY (id);


--
-- Name: calls_sessions calls_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.calls_sessions
    ADD CONSTRAINT calls_sessions_pkey PRIMARY KEY (id);


--
-- Name: channelbookmarks channelbookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.channelbookmarks
    ADD CONSTRAINT channelbookmarks_pkey PRIMARY KEY (id);


--
-- Name: channelmemberhistory channelmemberhistory_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.channelmemberhistory
    ADD CONSTRAINT channelmemberhistory_pkey PRIMARY KEY (channelid, userid, jointime);


--
-- Name: channelmembers channelmembers_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.channelmembers
    ADD CONSTRAINT channelmembers_pkey PRIMARY KEY (channelid, userid);


--
-- Name: channels channels_name_teamid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_name_teamid_key UNIQUE (name, teamid);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: clusterdiscovery clusterdiscovery_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.clusterdiscovery
    ADD CONSTRAINT clusterdiscovery_pkey PRIMARY KEY (id);


--
-- Name: commands commands_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_pkey PRIMARY KEY (id);


--
-- Name: commandwebhooks commandwebhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.commandwebhooks
    ADD CONSTRAINT commandwebhooks_pkey PRIMARY KEY (id);


--
-- Name: compliances compliances_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.compliances
    ADD CONSTRAINT compliances_pkey PRIMARY KEY (id);


--
-- Name: contentflaggingcommonreviewers contentflaggingcommonreviewers_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.contentflaggingcommonreviewers
    ADD CONSTRAINT contentflaggingcommonreviewers_pkey PRIMARY KEY (userid);


--
-- Name: contentflaggingteamreviewers contentflaggingteamreviewers_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.contentflaggingteamreviewers
    ADD CONSTRAINT contentflaggingteamreviewers_pkey PRIMARY KEY (teamid, userid);


--
-- Name: contentflaggingteamsettings contentflaggingteamsettings_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.contentflaggingteamsettings
    ADD CONSTRAINT contentflaggingteamsettings_pkey PRIMARY KEY (teamid);


--
-- Name: db_lock db_lock_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.db_lock
    ADD CONSTRAINT db_lock_pkey PRIMARY KEY (id);


--
-- Name: db_migrations_calls db_migrations_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.db_migrations_calls
    ADD CONSTRAINT db_migrations_calls_pkey PRIMARY KEY (version);


--
-- Name: db_migrations db_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.db_migrations
    ADD CONSTRAINT db_migrations_pkey PRIMARY KEY (version);


--
-- Name: desktoptokens desktoptokens_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.desktoptokens
    ADD CONSTRAINT desktoptokens_pkey PRIMARY KEY (token);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (userid, channelid, rootid);


--
-- Name: emoji emoji_name_deleteat_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.emoji
    ADD CONSTRAINT emoji_name_deleteat_key UNIQUE (name, deleteat);


--
-- Name: emoji emoji_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.emoji
    ADD CONSTRAINT emoji_pkey PRIMARY KEY (id);


--
-- Name: fileinfo fileinfo_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.fileinfo
    ADD CONSTRAINT fileinfo_pkey PRIMARY KEY (id);


--
-- Name: groupchannels groupchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.groupchannels
    ADD CONSTRAINT groupchannels_pkey PRIMARY KEY (groupid, channelid);


--
-- Name: groupmembers groupmembers_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.groupmembers
    ADD CONSTRAINT groupmembers_pkey PRIMARY KEY (groupid, userid);


--
-- Name: groupteams groupteams_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.groupteams
    ADD CONSTRAINT groupteams_pkey PRIMARY KEY (groupid, teamid);


--
-- Name: incomingwebhooks incomingwebhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.incomingwebhooks
    ADD CONSTRAINT incomingwebhooks_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: licenses licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.licenses
    ADD CONSTRAINT licenses_pkey PRIMARY KEY (id);


--
-- Name: linkmetadata linkmetadata_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.linkmetadata
    ADD CONSTRAINT linkmetadata_pkey PRIMARY KEY (hash);


--
-- Name: llm_postmeta llm_postmeta_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.llm_postmeta
    ADD CONSTRAINT llm_postmeta_pkey PRIMARY KEY (rootpostid);


--
-- Name: notifyadmin notifyadmin_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.notifyadmin
    ADD CONSTRAINT notifyadmin_pkey PRIMARY KEY (userid, requiredfeature, requiredplan);


--
-- Name: oauthaccessdata oauthaccessdata_clientid_userid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.oauthaccessdata
    ADD CONSTRAINT oauthaccessdata_clientid_userid_key UNIQUE (clientid, userid);


--
-- Name: oauthaccessdata oauthaccessdata_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.oauthaccessdata
    ADD CONSTRAINT oauthaccessdata_pkey PRIMARY KEY (token);


--
-- Name: oauthapps oauthapps_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.oauthapps
    ADD CONSTRAINT oauthapps_pkey PRIMARY KEY (id);


--
-- Name: oauthauthdata oauthauthdata_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.oauthauthdata
    ADD CONSTRAINT oauthauthdata_pkey PRIMARY KEY (code);


--
-- Name: outgoingoauthconnections outgoingoauthconnections_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.outgoingoauthconnections
    ADD CONSTRAINT outgoingoauthconnections_pkey PRIMARY KEY (id);


--
-- Name: outgoingwebhooks outgoingwebhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.outgoingwebhooks
    ADD CONSTRAINT outgoingwebhooks_pkey PRIMARY KEY (id);


--
-- Name: persistentnotifications persistentnotifications_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.persistentnotifications
    ADD CONSTRAINT persistentnotifications_pkey PRIMARY KEY (postid);


--
-- Name: pluginkeyvaluestore pluginkeyvaluestore_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.pluginkeyvaluestore
    ADD CONSTRAINT pluginkeyvaluestore_pkey PRIMARY KEY (pluginid, pkey);


--
-- Name: postacknowledgements postacknowledgements_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.postacknowledgements
    ADD CONSTRAINT postacknowledgements_pkey PRIMARY KEY (postid, userid);


--
-- Name: postreminders postreminders_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.postreminders
    ADD CONSTRAINT postreminders_pkey PRIMARY KEY (postid, userid);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: postspriority postspriority_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.postspriority
    ADD CONSTRAINT postspriority_pkey PRIMARY KEY (postid);


--
-- Name: preferences preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT preferences_pkey PRIMARY KEY (userid, category, name);


--
-- Name: productnoticeviewstate productnoticeviewstate_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.productnoticeviewstate
    ADD CONSTRAINT productnoticeviewstate_pkey PRIMARY KEY (userid, noticeid);


--
-- Name: propertyfields propertyfields_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.propertyfields
    ADD CONSTRAINT propertyfields_pkey PRIMARY KEY (id);


--
-- Name: propertygroups propertygroups_name_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.propertygroups
    ADD CONSTRAINT propertygroups_name_key UNIQUE (name);


--
-- Name: propertygroups propertygroups_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.propertygroups
    ADD CONSTRAINT propertygroups_pkey PRIMARY KEY (id);


--
-- Name: propertyvalues propertyvalues_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.propertyvalues
    ADD CONSTRAINT propertyvalues_pkey PRIMARY KEY (id);


--
-- Name: publicchannels publicchannels_name_teamid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.publicchannels
    ADD CONSTRAINT publicchannels_name_teamid_key UNIQUE (name, teamid);


--
-- Name: publicchannels publicchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.publicchannels
    ADD CONSTRAINT publicchannels_pkey PRIMARY KEY (id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (postid, userid, emojiname);


--
-- Name: readreceipts readreceipts_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.readreceipts
    ADD CONSTRAINT readreceipts_pkey PRIMARY KEY (postid, userid);


--
-- Name: recapchannels recapchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.recapchannels
    ADD CONSTRAINT recapchannels_pkey PRIMARY KEY (id);


--
-- Name: recaps recaps_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.recaps
    ADD CONSTRAINT recaps_pkey PRIMARY KEY (id);


--
-- Name: recentsearches recentsearches_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.recentsearches
    ADD CONSTRAINT recentsearches_pkey PRIMARY KEY (userid, searchpointer);


--
-- Name: remoteclusters remoteclusters_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.remoteclusters
    ADD CONSTRAINT remoteclusters_pkey PRIMARY KEY (remoteid, name);


--
-- Name: retentionidsfordeletion retentionidsfordeletion_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.retentionidsfordeletion
    ADD CONSTRAINT retentionidsfordeletion_pkey PRIMARY KEY (id);


--
-- Name: retentionpolicies retentionpolicies_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.retentionpolicies
    ADD CONSTRAINT retentionpolicies_pkey PRIMARY KEY (id);


--
-- Name: retentionpolicieschannels retentionpolicieschannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.retentionpolicieschannels
    ADD CONSTRAINT retentionpolicieschannels_pkey PRIMARY KEY (channelid);


--
-- Name: retentionpoliciesteams retentionpoliciesteams_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.retentionpoliciesteams
    ADD CONSTRAINT retentionpoliciesteams_pkey PRIMARY KEY (teamid);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: scheduledposts scheduledposts_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.scheduledposts
    ADD CONSTRAINT scheduledposts_pkey PRIMARY KEY (id);


--
-- Name: schemes schemes_name_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.schemes
    ADD CONSTRAINT schemes_name_key UNIQUE (name);


--
-- Name: schemes schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.schemes
    ADD CONSTRAINT schemes_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sharedchannelattachments sharedchannelattachments_fileid_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannelattachments
    ADD CONSTRAINT sharedchannelattachments_fileid_remoteid_key UNIQUE (fileid, remoteid);


--
-- Name: sharedchannelattachments sharedchannelattachments_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannelattachments
    ADD CONSTRAINT sharedchannelattachments_pkey PRIMARY KEY (id);


--
-- Name: sharedchannelremotes sharedchannelremotes_channelid_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannelremotes
    ADD CONSTRAINT sharedchannelremotes_channelid_remoteid_key UNIQUE (channelid, remoteid);


--
-- Name: sharedchannelremotes sharedchannelremotes_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannelremotes
    ADD CONSTRAINT sharedchannelremotes_pkey PRIMARY KEY (id, channelid);


--
-- Name: sharedchannels sharedchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannels
    ADD CONSTRAINT sharedchannels_pkey PRIMARY KEY (channelid);


--
-- Name: sharedchannels sharedchannels_sharename_teamid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannels
    ADD CONSTRAINT sharedchannels_sharename_teamid_key UNIQUE (sharename, teamid);


--
-- Name: sharedchannelusers sharedchannelusers_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannelusers
    ADD CONSTRAINT sharedchannelusers_pkey PRIMARY KEY (id);


--
-- Name: sharedchannelusers sharedchannelusers_userid_channelid_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sharedchannelusers
    ADD CONSTRAINT sharedchannelusers_userid_channelid_remoteid_key UNIQUE (userid, channelid, remoteid);


--
-- Name: sidebarcategories sidebarcategories_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sidebarcategories
    ADD CONSTRAINT sidebarcategories_pkey PRIMARY KEY (id);


--
-- Name: sidebarchannels sidebarchannels_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.sidebarchannels
    ADD CONSTRAINT sidebarchannels_pkey PRIMARY KEY (channelid, userid, categoryid);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (userid);


--
-- Name: systems systems_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.systems
    ADD CONSTRAINT systems_pkey PRIMARY KEY (name);


--
-- Name: teammembers teammembers_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.teammembers
    ADD CONSTRAINT teammembers_pkey PRIMARY KEY (teamid, userid);


--
-- Name: teams teams_name_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_name_key UNIQUE (name);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: temporaryposts temporaryposts_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.temporaryposts
    ADD CONSTRAINT temporaryposts_pkey PRIMARY KEY (postid);


--
-- Name: termsofservice termsofservice_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.termsofservice
    ADD CONSTRAINT termsofservice_pkey PRIMARY KEY (id);


--
-- Name: threadmemberships threadmemberships_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.threadmemberships
    ADD CONSTRAINT threadmemberships_pkey PRIMARY KEY (postid, userid);


--
-- Name: threads threads_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.threads
    ADD CONSTRAINT threads_pkey PRIMARY KEY (postid);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (token);


--
-- Name: translations translations_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_pkey PRIMARY KEY (objectid, dstlang);


--
-- Name: uploadsessions uploadsessions_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.uploadsessions
    ADD CONSTRAINT uploadsessions_pkey PRIMARY KEY (id);


--
-- Name: useraccesstokens useraccesstokens_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.useraccesstokens
    ADD CONSTRAINT useraccesstokens_pkey PRIMARY KEY (id);


--
-- Name: useraccesstokens useraccesstokens_token_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.useraccesstokens
    ADD CONSTRAINT useraccesstokens_token_key UNIQUE (token);


--
-- Name: usergroups usergroups_name_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_name_key UNIQUE (name);


--
-- Name: usergroups usergroups_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_pkey PRIMARY KEY (id);


--
-- Name: usergroups usergroups_source_remoteid_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.usergroups
    ADD CONSTRAINT usergroups_source_remoteid_key UNIQUE (source, remoteid);


--
-- Name: users users_authdata_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_authdata_key UNIQUE (authdata);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: usertermsofservice usertermsofservice_pkey; Type: CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.usertermsofservice
    ADD CONSTRAINT usertermsofservice_pkey PRIMARY KEY (userid);


--
-- Name: idx_audits_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_audits_user_id ON public.audits USING btree (userid);


--
-- Name: idx_calls_channel_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_calls_channel_id ON public.calls USING btree (channelid);


--
-- Name: idx_calls_end_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_calls_end_at ON public.calls USING btree (endat);


--
-- Name: idx_calls_jobs_call_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_calls_jobs_call_id ON public.calls_jobs USING btree (callid);


--
-- Name: idx_calls_sessions_call_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_calls_sessions_call_id ON public.calls_sessions USING btree (callid);


--
-- Name: idx_channel_search_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channel_search_txt ON public.channels USING gin (to_tsvector('english'::regconfig, (((((name)::text || ' '::text) || (displayname)::text) || ' '::text) || (purpose)::text)));


--
-- Name: idx_channelbookmarks_channelid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channelbookmarks_channelid ON public.channelbookmarks USING btree (channelid);


--
-- Name: idx_channelbookmarks_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channelbookmarks_delete_at ON public.channelbookmarks USING btree (deleteat);


--
-- Name: idx_channelbookmarks_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channelbookmarks_update_at ON public.channelbookmarks USING btree (updateat);


--
-- Name: idx_channelmembers_autotranslation_enabled; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channelmembers_autotranslation_enabled ON public.channelmembers USING btree (channelid) WHERE (autotranslation = true);


--
-- Name: idx_channelmembers_channel_id_scheme_guest_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channelmembers_channel_id_scheme_guest_user_id ON public.channelmembers USING btree (channelid, schemeguest, userid);


--
-- Name: idx_channelmembers_user_id_channel_id_last_viewed_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channelmembers_user_id_channel_id_last_viewed_at ON public.channelmembers USING btree (userid, channelid, lastviewedat);


--
-- Name: idx_channels_autotranslation_enabled; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_autotranslation_enabled ON public.channels USING btree (id) WHERE (autotranslation = true);


--
-- Name: idx_channels_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_create_at ON public.channels USING btree (createat);


--
-- Name: idx_channels_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_delete_at ON public.channels USING btree (deleteat);


--
-- Name: idx_channels_displayname_lower; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_displayname_lower ON public.channels USING btree (lower((displayname)::text));


--
-- Name: idx_channels_name_lower; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_name_lower ON public.channels USING btree (lower((name)::text));


--
-- Name: idx_channels_scheme_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_scheme_id ON public.channels USING btree (schemeid);


--
-- Name: idx_channels_team_id_display_name; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_team_id_display_name ON public.channels USING btree (teamid, displayname);


--
-- Name: idx_channels_team_id_type; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_team_id_type ON public.channels USING btree (teamid, type);


--
-- Name: idx_channels_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_channels_update_at ON public.channels USING btree (updateat);


--
-- Name: idx_command_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_command_create_at ON public.commands USING btree (createat);


--
-- Name: idx_command_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_command_delete_at ON public.commands USING btree (deleteat);


--
-- Name: idx_command_team_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_command_team_id ON public.commands USING btree (teamid);


--
-- Name: idx_command_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_command_update_at ON public.commands USING btree (updateat);


--
-- Name: idx_command_webhook_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_command_webhook_create_at ON public.commandwebhooks USING btree (createat);


--
-- Name: idx_contentflaggingteamreviewers_userid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_contentflaggingteamreviewers_userid ON public.contentflaggingteamreviewers USING btree (userid);


--
-- Name: idx_desktoptokens_token_createat; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_desktoptokens_token_createat ON public.desktoptokens USING btree (token, createat);


--
-- Name: idx_emoji_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_emoji_create_at ON public.emoji USING btree (createat);


--
-- Name: idx_emoji_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_emoji_delete_at ON public.emoji USING btree (deleteat);


--
-- Name: idx_emoji_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_emoji_update_at ON public.emoji USING btree (updateat);


--
-- Name: idx_fileinfo_channel_id_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_channel_id_create_at ON public.fileinfo USING btree (channelid, createat);


--
-- Name: idx_fileinfo_content_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_content_txt ON public.fileinfo USING gin (to_tsvector('english'::regconfig, content));


--
-- Name: idx_fileinfo_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_create_at ON public.fileinfo USING btree (createat);


--
-- Name: idx_fileinfo_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_delete_at ON public.fileinfo USING btree (deleteat);


--
-- Name: idx_fileinfo_extension_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_extension_at ON public.fileinfo USING btree (extension);


--
-- Name: idx_fileinfo_name_splitted; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_name_splitted ON public.fileinfo USING gin (to_tsvector('english'::regconfig, translate((name)::text, '.,-'::text, '   '::text)));


--
-- Name: idx_fileinfo_name_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_name_txt ON public.fileinfo USING gin (to_tsvector('english'::regconfig, (name)::text));


--
-- Name: idx_fileinfo_postid_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_postid_at ON public.fileinfo USING btree (postid);


--
-- Name: idx_fileinfo_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_fileinfo_update_at ON public.fileinfo USING btree (updateat);


--
-- Name: idx_groupchannels_channelid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_groupchannels_channelid ON public.groupchannels USING btree (channelid);


--
-- Name: idx_groupchannels_schemeadmin; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_groupchannels_schemeadmin ON public.groupchannels USING btree (schemeadmin);


--
-- Name: idx_groupmembers_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_groupmembers_create_at ON public.groupmembers USING btree (createat);


--
-- Name: idx_groupteams_schemeadmin; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_groupteams_schemeadmin ON public.groupteams USING btree (schemeadmin);


--
-- Name: idx_groupteams_teamid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_groupteams_teamid ON public.groupteams USING btree (teamid);


--
-- Name: idx_incoming_webhook_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_incoming_webhook_create_at ON public.incomingwebhooks USING btree (createat);


--
-- Name: idx_incoming_webhook_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_incoming_webhook_delete_at ON public.incomingwebhooks USING btree (deleteat);


--
-- Name: idx_incoming_webhook_team_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_incoming_webhook_team_id ON public.incomingwebhooks USING btree (teamid);


--
-- Name: idx_incoming_webhook_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_incoming_webhook_update_at ON public.incomingwebhooks USING btree (updateat);


--
-- Name: idx_incoming_webhook_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_incoming_webhook_user_id ON public.incomingwebhooks USING btree (userid);


--
-- Name: idx_jobs_status_type; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_jobs_status_type ON public.jobs USING btree (status, type);


--
-- Name: idx_jobs_type; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_jobs_type ON public.jobs USING btree (type);


--
-- Name: idx_link_metadata_url_timestamp; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_link_metadata_url_timestamp ON public.linkmetadata USING btree (url, "timestamp");


--
-- Name: idx_notice_views_notice_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_notice_views_notice_id ON public.productnoticeviewstate USING btree (noticeid);


--
-- Name: idx_notice_views_timestamp; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_notice_views_timestamp ON public.productnoticeviewstate USING btree ("timestamp");


--
-- Name: idx_oauthaccessdata_refresh_token; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_oauthaccessdata_refresh_token ON public.oauthaccessdata USING btree (refreshtoken);


--
-- Name: idx_oauthaccessdata_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_oauthaccessdata_user_id ON public.oauthaccessdata USING btree (userid);


--
-- Name: idx_oauthapps_creator_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_oauthapps_creator_id ON public.oauthapps USING btree (creatorid);


--
-- Name: idx_outgoing_webhook_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_outgoing_webhook_create_at ON public.outgoingwebhooks USING btree (createat);


--
-- Name: idx_outgoing_webhook_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_outgoing_webhook_delete_at ON public.outgoingwebhooks USING btree (deleteat);


--
-- Name: idx_outgoing_webhook_team_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_outgoing_webhook_team_id ON public.outgoingwebhooks USING btree (teamid);


--
-- Name: idx_outgoing_webhook_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_outgoing_webhook_update_at ON public.outgoingwebhooks USING btree (updateat);


--
-- Name: idx_outgoingoauthconnections_name; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_outgoingoauthconnections_name ON public.outgoingoauthconnections USING btree (name);


--
-- Name: idx_postreminders_targettime; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_postreminders_targettime ON public.postreminders USING btree (targettime);


--
-- Name: idx_posts_channel_id_delete_at_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_channel_id_delete_at_create_at ON public.posts USING btree (channelid, deleteat, createat);


--
-- Name: idx_posts_channel_id_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_channel_id_update_at ON public.posts USING btree (channelid, updateat);


--
-- Name: idx_posts_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_create_at ON public.posts USING btree (createat);


--
-- Name: idx_posts_create_at_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_create_at_id ON public.posts USING btree (createat, id);


--
-- Name: idx_posts_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_delete_at ON public.posts USING btree (deleteat);


--
-- Name: idx_posts_hashtags_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_hashtags_txt ON public.posts USING gin (to_tsvector('english'::regconfig, (hashtags)::text));


--
-- Name: idx_posts_is_pinned; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_is_pinned ON public.posts USING btree (ispinned);


--
-- Name: idx_posts_message_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_message_txt ON public.posts USING gin (to_tsvector('english'::regconfig, (message)::text));


--
-- Name: idx_posts_original_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_original_id ON public.posts USING btree (originalid);


--
-- Name: idx_posts_root_id_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_root_id_delete_at ON public.posts USING btree (rootid, deleteat);


--
-- Name: idx_posts_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_update_at ON public.posts USING btree (updateat);


--
-- Name: idx_posts_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_posts_user_id ON public.posts USING btree (userid);


--
-- Name: idx_poststats_userid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_poststats_userid ON public.poststats USING btree (userid);


--
-- Name: idx_preferences_category; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_preferences_category ON public.preferences USING btree (category);


--
-- Name: idx_preferences_name; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_preferences_name ON public.preferences USING btree (name);


--
-- Name: idx_propertyfields_create_at_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_propertyfields_create_at_id ON public.propertyfields USING btree (createat, id);


--
-- Name: idx_propertyfields_unique; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE UNIQUE INDEX idx_propertyfields_unique ON public.propertyfields USING btree (groupid, targetid, name) WHERE (deleteat = 0);


--
-- Name: idx_propertyvalues_create_at_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_propertyvalues_create_at_id ON public.propertyvalues USING btree (createat, id);


--
-- Name: idx_propertyvalues_targetid_groupid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_propertyvalues_targetid_groupid ON public.propertyvalues USING btree (targetid, groupid);


--
-- Name: idx_propertyvalues_unique; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE UNIQUE INDEX idx_propertyvalues_unique ON public.propertyvalues USING btree (groupid, targetid, fieldid) WHERE (deleteat = 0);


--
-- Name: idx_publicchannels_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_publicchannels_delete_at ON public.publicchannels USING btree (deleteat);


--
-- Name: idx_publicchannels_displayname_lower; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_publicchannels_displayname_lower ON public.publicchannels USING btree (lower((displayname)::text));


--
-- Name: idx_publicchannels_name_lower; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_publicchannels_name_lower ON public.publicchannels USING btree (lower((name)::text));


--
-- Name: idx_publicchannels_search_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_publicchannels_search_txt ON public.publicchannels USING gin (to_tsvector('english'::regconfig, (((((name)::text || ' '::text) || (displayname)::text) || ' '::text) || (purpose)::text)));


--
-- Name: idx_publicchannels_team_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_publicchannels_team_id ON public.publicchannels USING btree (teamid);


--
-- Name: idx_reactions_channel_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_reactions_channel_id ON public.reactions USING btree (channelid);


--
-- Name: idx_read_receipts_post_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_read_receipts_post_id ON public.readreceipts USING btree (postid);


--
-- Name: idx_read_receipts_user_id_post_id_expire_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_read_receipts_user_id_post_id_expire_at ON public.readreceipts USING btree (userid, postid, expireat);


--
-- Name: idx_recap_channels_channel_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_recap_channels_channel_id ON public.recapchannels USING btree (channelid);


--
-- Name: idx_recap_channels_recap_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_recap_channels_recap_id ON public.recapchannels USING btree (recapid);


--
-- Name: idx_recaps_bot_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_recaps_bot_id ON public.recaps USING btree (botid);


--
-- Name: idx_recaps_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_recaps_create_at ON public.recaps USING btree (createat);


--
-- Name: idx_recaps_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_recaps_user_id ON public.recaps USING btree (userid);


--
-- Name: idx_recaps_user_id_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_recaps_user_id_delete_at ON public.recaps USING btree (userid, deleteat);


--
-- Name: idx_recaps_user_id_read_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_recaps_user_id_read_at ON public.recaps USING btree (userid, readat);


--
-- Name: idx_retentionidsfordeletion_tablename; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_retentionidsfordeletion_tablename ON public.retentionidsfordeletion USING btree (tablename);


--
-- Name: idx_retentionpolicies_displayname; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_retentionpolicies_displayname ON public.retentionpolicies USING btree (displayname);


--
-- Name: idx_retentionpolicieschannels_policyid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_retentionpolicieschannels_policyid ON public.retentionpolicieschannels USING btree (policyid);


--
-- Name: idx_retentionpoliciesteams_policyid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_retentionpoliciesteams_policyid ON public.retentionpoliciesteams USING btree (policyid);


--
-- Name: idx_scheduledposts_userid_channel_id_scheduled_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_scheduledposts_userid_channel_id_scheduled_at ON public.scheduledposts USING btree (userid, channelid, scheduledat);


--
-- Name: idx_schemes_channel_admin_role; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_schemes_channel_admin_role ON public.schemes USING btree (defaultchanneladminrole);


--
-- Name: idx_schemes_channel_guest_role; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_schemes_channel_guest_role ON public.schemes USING btree (defaultchannelguestrole);


--
-- Name: idx_schemes_channel_user_role; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_schemes_channel_user_role ON public.schemes USING btree (defaultchanneluserrole);


--
-- Name: idx_sessions_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sessions_create_at ON public.sessions USING btree (createat);


--
-- Name: idx_sessions_expires_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sessions_expires_at ON public.sessions USING btree (expiresat);


--
-- Name: idx_sessions_last_activity_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sessions_last_activity_at ON public.sessions USING btree (lastactivityat);


--
-- Name: idx_sessions_token; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sessions_token ON public.sessions USING btree (token);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (userid);


--
-- Name: idx_sharedchannelusers_remote_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sharedchannelusers_remote_id ON public.sharedchannelusers USING btree (remoteid);


--
-- Name: idx_sidebarcategories_userid_teamid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sidebarcategories_userid_teamid ON public.sidebarcategories USING btree (userid, teamid);


--
-- Name: idx_sidebarchannels_categoryid; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_sidebarchannels_categoryid ON public.sidebarchannels USING btree (categoryid);


--
-- Name: idx_status_status_dndendtime; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_status_status_dndendtime ON public.status USING btree (status, dndendtime);


--
-- Name: idx_teammembers_createat; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teammembers_createat ON public.teammembers USING btree (createat);


--
-- Name: idx_teammembers_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teammembers_delete_at ON public.teammembers USING btree (deleteat);


--
-- Name: idx_teammembers_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teammembers_user_id ON public.teammembers USING btree (userid);


--
-- Name: idx_teams_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teams_create_at ON public.teams USING btree (createat);


--
-- Name: idx_teams_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teams_delete_at ON public.teams USING btree (deleteat);


--
-- Name: idx_teams_invite_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teams_invite_id ON public.teams USING btree (inviteid);


--
-- Name: idx_teams_scheme_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teams_scheme_id ON public.teams USING btree (schemeid);


--
-- Name: idx_teams_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_teams_update_at ON public.teams USING btree (updateat);


--
-- Name: idx_temporary_posts_expire_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_temporary_posts_expire_at ON public.temporaryposts USING btree (expireat);


--
-- Name: idx_thread_memberships_last_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_thread_memberships_last_update_at ON public.threadmemberships USING btree (lastupdated);


--
-- Name: idx_thread_memberships_last_view_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_thread_memberships_last_view_at ON public.threadmemberships USING btree (lastviewed);


--
-- Name: idx_thread_memberships_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_thread_memberships_user_id ON public.threadmemberships USING btree (userid);


--
-- Name: idx_threads_channel_id_last_reply_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_threads_channel_id_last_reply_at ON public.threads USING btree (channelid, lastreplyat);


--
-- Name: idx_translations_updateat; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_translations_updateat ON public.translations USING btree (updateat DESC);


--
-- Name: idx_uploadsessions_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_uploadsessions_create_at ON public.uploadsessions USING btree (createat);


--
-- Name: idx_uploadsessions_type; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_uploadsessions_type ON public.uploadsessions USING btree (type);


--
-- Name: idx_uploadsessions_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_uploadsessions_user_id ON public.uploadsessions USING btree (userid);


--
-- Name: idx_user_access_tokens_user_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_user_access_tokens_user_id ON public.useraccesstokens USING btree (userid);


--
-- Name: idx_usergroups_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_usergroups_delete_at ON public.usergroups USING btree (deleteat);


--
-- Name: idx_usergroups_displayname; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_usergroups_displayname ON public.usergroups USING btree (displayname);


--
-- Name: idx_usergroups_remote_id; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_usergroups_remote_id ON public.usergroups USING btree (remoteid);


--
-- Name: idx_users_all_no_full_name_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_all_no_full_name_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((username)::text || ' '::text) || (nickname)::text) || ' '::text) || (email)::text)));


--
-- Name: idx_users_all_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_all_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((((((username)::text || ' '::text) || (firstname)::text) || ' '::text) || (lastname)::text) || ' '::text) || (nickname)::text) || ' '::text) || (email)::text)));


--
-- Name: idx_users_create_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_create_at ON public.users USING btree (createat);


--
-- Name: idx_users_delete_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_delete_at ON public.users USING btree (deleteat);


--
-- Name: idx_users_email_lower_textpattern; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_email_lower_textpattern ON public.users USING btree (lower((email)::text) text_pattern_ops);


--
-- Name: idx_users_firstname_lower_textpattern; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_firstname_lower_textpattern ON public.users USING btree (lower((firstname)::text) text_pattern_ops);


--
-- Name: idx_users_id_locale; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_id_locale ON public.users USING btree (id, locale);


--
-- Name: idx_users_lastname_lower_textpattern; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_lastname_lower_textpattern ON public.users USING btree (lower((lastname)::text) text_pattern_ops);


--
-- Name: idx_users_names_no_full_name_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_names_no_full_name_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((username)::text || ' '::text) || (nickname)::text)));


--
-- Name: idx_users_names_txt; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_names_txt ON public.users USING gin (to_tsvector('english'::regconfig, (((((((username)::text || ' '::text) || (firstname)::text) || ' '::text) || (lastname)::text) || ' '::text) || (nickname)::text)));


--
-- Name: idx_users_nickname_lower_textpattern; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_nickname_lower_textpattern ON public.users USING btree (lower((nickname)::text) text_pattern_ops);


--
-- Name: idx_users_update_at; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_update_at ON public.users USING btree (updateat);


--
-- Name: idx_users_username_lower_textpattern; Type: INDEX; Schema: public; Owner: mmuser
--

CREATE INDEX idx_users_username_lower_textpattern ON public.users USING btree (lower((username)::text) text_pattern_ops);


--
-- Name: retentionpolicieschannels fk_retentionpolicieschannels_retentionpolicies; Type: FK CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.retentionpolicieschannels
    ADD CONSTRAINT fk_retentionpolicieschannels_retentionpolicies FOREIGN KEY (policyid) REFERENCES public.retentionpolicies(id) ON DELETE CASCADE;


--
-- Name: retentionpoliciesteams fk_retentionpoliciesteams_retentionpolicies; Type: FK CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.retentionpoliciesteams
    ADD CONSTRAINT fk_retentionpoliciesteams_retentionpolicies FOREIGN KEY (policyid) REFERENCES public.retentionpolicies(id) ON DELETE CASCADE;


--
-- Name: llm_postmeta llm_postmeta_rootpostid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.llm_postmeta
    ADD CONSTRAINT llm_postmeta_rootpostid_fkey FOREIGN KEY (rootpostid) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: recapchannels recapchannels_recapid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mmuser
--

ALTER TABLE ONLY public.recapchannels
    ADD CONSTRAINT recapchannels_recapid_fkey FOREIGN KEY (recapid) REFERENCES public.recaps(id) ON DELETE CASCADE;


--
-- Name: attributeview; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: mmuser
--

REFRESH MATERIALIZED VIEW public.attributeview;


--
-- Name: bot_posts_by_team_day; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: mmuser
--

REFRESH MATERIALIZED VIEW public.bot_posts_by_team_day;


--
-- Name: file_stats; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: mmuser
--

REFRESH MATERIALIZED VIEW public.file_stats;


--
-- Name: posts_by_team_day; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: mmuser
--

REFRESH MATERIALIZED VIEW public.posts_by_team_day;


--
-- Name: poststats; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: mmuser
--

REFRESH MATERIALIZED VIEW public.poststats;


--
-- PostgreSQL database dump complete
--

\unrestrict EKxL6mS7eCSueQ2A2JEAIoEMagaWYhxUb5Jfncl4rW8X7Ht15BLnUy8GOxMCLSw

