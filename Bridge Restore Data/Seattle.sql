--
-- PostgreSQL database cluster dump
--

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Drop databases (except postgres and template1)
--

DROP DATABASE vapor_database;




--
-- Drop roles
--

DROP ROLE vapor_username;


--
-- Roles
--

CREATE ROLE vapor_username;
ALTER ROLE vapor_username WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:69UWWkYGsG45gPxjQLfk5g==$Uxck1J4kVEbmljIXxy1vnQ1rQ5fGI/MuObDdtBWDAYY=:amzubgZiHQQ2wJqbRalCCw+tFxatIXg0ZZUJsUquI/g=';






--
-- Databases
--

--
-- Database "template1" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

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

UPDATE pg_catalog.pg_database SET datistemplate = false WHERE datname = 'template1';
DROP DATABASE template1;
--
-- Name: template1; Type: DATABASE; Schema: -; Owner: vapor_username
--

CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE template1 OWNER TO vapor_username;

\connect template1

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
-- Name: DATABASE template1; Type: COMMENT; Schema: -; Owner: vapor_username
--

COMMENT ON DATABASE template1 IS 'default template for new databases';


--
-- Name: template1; Type: DATABASE PROPERTIES; Schema: -; Owner: vapor_username
--

ALTER DATABASE template1 IS_TEMPLATE = true;


\connect template1

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
-- Name: DATABASE template1; Type: ACL; Schema: -; Owner: vapor_username
--

REVOKE CONNECT,TEMPORARY ON DATABASE template1 FROM PUBLIC;
GRANT CONNECT ON DATABASE template1 TO PUBLIC;


--
-- PostgreSQL database dump complete
--

--
-- Database "postgres" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

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

DROP DATABASE postgres;
--
-- Name: postgres; Type: DATABASE; Schema: -; Owner: vapor_username
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE postgres OWNER TO vapor_username;

\connect postgres

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
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: vapor_username
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- PostgreSQL database dump complete
--

--
-- Database "vapor_database" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

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
-- Name: vapor_database; Type: DATABASE; Schema: -; Owner: vapor_username
--

CREATE DATABASE vapor_database WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE vapor_database OWNER TO vapor_username;

\connect vapor_database

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _fluent_migrations; Type: TABLE; Schema: public; Owner: vapor_username
--

CREATE TABLE public._fluent_migrations (
    id uuid NOT NULL,
    name text NOT NULL,
    batch bigint NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public._fluent_migrations OWNER TO vapor_username;

--
-- Name: bridges; Type: TABLE; Schema: public; Owner: vapor_username
--

CREATE TABLE public.bridges (
    id uuid NOT NULL,
    name text NOT NULL,
    status text NOT NULL,
    image_url text NOT NULL,
    maps_url text NOT NULL,
    address text NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    bridge_location text NOT NULL
);


ALTER TABLE public.bridges OWNER TO vapor_username;

--
-- Data for Name: _fluent_migrations; Type: TABLE DATA; Schema: public; Owner: vapor_username
--

COPY public._fluent_migrations (id, name, batch, created_at, updated_at) FROM stdin;
101b5d63-00aa-48c8-893f-12f5ecc35f44	App.UpdateStatus	1	2022-08-31 21:06:05.644478+00	2022-08-31 21:06:05.644478+00
\.


--
-- Data for Name: bridges; Type: TABLE DATA; Schema: public; Owner: vapor_username
--

COPY public.bridges (id, name, status, image_url, maps_url, address, latitude, longitude, bridge_location) FROM stdin;
52ca4452-2bbd-4c48-b456-c6fcb33fc0b1	Spokane St Swing Bridge	down	https://s3-media0.fl.yelpcdn.com/bphoto/65OT7DMVBuYaKCypaLl7Bw/o.jpg	https://maps.apple.com/?address=W%20Marginal%20Way%20SW,%20Seattle,%20WA%20%2098106,%20United%20States&auid=1398119420499563697&ll=47.572371,-122.359972&lsp=9902&q=Spokane%20St%20Swing%20Bridge&_ext=CjMKBQgEEOIBCgQIBRADCgUIBhCyAgoECAoQAAoECFIQBAoECFUQAAoECFkQBgoFCKQBEAESJilOd4r/q8hHQDHK8r5Ed5dewDnMTLBb0slHQEEG70AdnZZewFAE	Seattle, WA, United States	47.57237	-122.35997	Seattle, Wa
d6e22016-407f-494b-b11b-63458ad1210f	Fremont Bridge	down	https://s3-media0.fl.yelpcdn.com/bphoto/D6GWjywwsRtcnUrmAKUbjg/o.jpg	https://maps.apple.com/?address=N%2034th%20St%20%26%20Fremont%20Ave%20N,%20Seattle,%20WA%20%2098103,%20United%20States&auid=4071119378163287291&ll=47.649574,-122.349736&lsp=9902&q=Fremont%20Bridge&_ext=CjMKBQgEEOIBCgQIBRADCgUIBhCyAgoECAoQAAoECFIQAwoECFUQDwoECFkQAgoFCKQBEAESJikQPu8SktJHQDGYyOlOz5ZewDmOExVvuNNHQEGYFsfU9JVewFAE	Seattle, Wa, United States	47.64957	-122.34974	Seattle, Wa
85c3d66a-b103-49ab-aa8b-26d153600d19	Ballard Bridge	down	https://s3-media0.fl.yelpcdn.com/bphoto/rq2iSswXqRp5Nmp7MIEVJg/o.jpg	https://maps.apple.com/?address=Ballard%20Bridge,%20Seattle,%20WA%20%2098199,%20United%20States&ll=47.657044,-122.376245&q=Ballard%20Bridge&_ext=EiYpoLms1YbTR0AxFkGkn4GYXsA5Ho/SMa3UR0BBNmKBHaeXXsBQBA%3D%3D	Seattle, WA 98199, United States	47.65704	-122.37624	Seattle, Wa
8e12ea9b-7f86-4940-becf-2ad8c09787f6	Montlake Bridge	down	https://s3-media0.fl.yelpcdn.com/bphoto/x23fdXYi_FhJ2FselX7f-w/o.jpg	https://maps.apple.com/?address=2908%20Montlake%20Blvd%20E,%20Seattle,%20WA%20%2098112,%20United%20States&auid=13921575388625385978&ll=47.647222,-122.304473&lsp=9902&q=Montlake%20Bridge&_ext=CjMKBQgEEOIBCgQIBRADCgUIBhCyAgoECAoQAAoECFIQAwoECFUQDwoECFkQAgoFCKQBEAESJCldUZhNUsdHQDECxyjtB5xewDl3hmP2WN5HQEHq+nsL8YpewA%3D%3D	Seattle, Wa, United States	47.64722	-122.30447	Seattle, Wa
e4d0e7f3-db3e-42c7-9009-d42af978c4e3	University Bridge	down	https://s3-media0.fl.yelpcdn.com/bphoto/s9o-RJkNPkAGoYbFL9Nh_w/o.jpg	https://maps.apple.com/?address=University%20Bridge,%20Seattle,%20WA%20%2098102,%20United%20States&ll=47.651722,-122.321160&q=University%20Bridge&_ext=EiYp/Jxoc9jSR0AxKwWjJfuUXsA5enKOz/7TR0BBwX0zqSCUXsBQBA%3D%3D	Seattle, WA  98102, United States	47.65172	-122.32116	Seattle, Wa
65c163b6-8b32-477a-b292-69ab0bcefc15	South Park Bridge	down	https://s3-media0.fl.yelpcdn.com/bphoto/tqKgN-n8lthpfOr1Dwer6A/o.jpg	https://maps.apple.com/?address=14th%20Ave%20S,%20Tukwila,%20WA%20%2098108,%20United%20States&auid=13112458643910587530&ll=47.529300,-122.314000&lsp=9902&q=South%20Park%20Bridge&_ext=CjMKBQgEEOIBCgQIBRADCgUIBhCyAgoECAoQAAoECFIQBAoECFUQAAoECFkQAgoFCKQBEAESJCnFgJmqosNHQDGIm6FfLpRewDkRRdSJ3cNHQEFM3UfHApRewA%3D%3D	Seattle, WA, United States	47.5293	-122.314	Seattle, Wa
cc1a77e6-2b93-4781-849a-a9c794a2c1ec	1st Ave S Bridge	down	https://cdn.westseattleblog.com/blog/wp-content/uploads/2020/07/P1110807-scaled-e1594843642213.jpg	https://maps.apple.com/?address=1st%20Avenue%20S%20Bridge,%20Seattle,%20WA%20%2098108,%20United%20States&auid=4426036263298196194&ll=47.542222,-122.334234&lsp=9902&q=1st%20Avenue%20Bridge&_ext=CjMKBQgEEOIBCgQIBRADCgUIBhCyAgoECAoQAAoECFIQBAoECFUQAAoECFkQAwoFCKQBEAESJilHiR1b1MRHQDG4ji4Z0ZVewDnFXkO3+sVHQEGqAa0R95RewFAE	Seattle, WA, United States	47.54222	-122.33423	Seattle, Wa
\.


--
-- Name: _fluent_migrations _fluent_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public._fluent_migrations
    ADD CONSTRAINT _fluent_migrations_pkey PRIMARY KEY (id);


--
-- Name: bridges bridges_pkey; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public.bridges
    ADD CONSTRAINT bridges_pkey PRIMARY KEY (id);


--
-- Name: _fluent_migrations uq:_fluent_migrations.name; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public._fluent_migrations
    ADD CONSTRAINT "uq:_fluent_migrations.name" UNIQUE (name);


--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database cluster dump complete
--

