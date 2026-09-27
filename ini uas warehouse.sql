SELECT *
FROM stg_disaster
LIMIT 10;

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'stg_disaster';

--DIMENTION TABLE--
--dim_time
CREATE TABLE dim_time AS
SELECT DISTINCT
    "declarationDate",
    year,
    month,
    quarter
FROM stg_disaster;

ALTER TABLE dim_time
ADD COLUMN time_id SERIAL PRIMARY KEY;

--dim_state
CREATE TABLE dim_state AS
SELECT DISTINCT
	state,
	region
FROM stg_disaster;

ALTER TABLE dim_state
ADD COLUMN state_id SERIAL PRIMARY KEY;

--dim_incident
CREATE TABLE dim_incident AS
SELECT DISTINCT
    "incidentType"
FROM stg_disaster;

ALTER TABLE dim_incident
ADD COLUMN incident_id SERIAL PRIMARY KEY;

--dim_program
CREATE TABLE dim_program AS
SELECT DISTINCT
    "IA",
    "PA",
    "HM"
FROM stg_disaster;

ALTER TABLE dim_program
ADD COLUMN program_id SERIAL PRIMARY KEY;

--dim_declaration
CREATE TABLE dim_declaration AS
SELECT DISTINCT
    "declarationType"
FROM stg_disaster;

ALTER TABLE dim_declaration
ADD COLUMN declaration_id SERIAL PRIMARY KEY;

--FACT TABLE--
CREATE TABLE fact_disaster AS
SELECT
    s."disasterNumber",

    t.time_id,
    st.state_id,
    i.incident_id,
    p.program_id,
    d.declaration_id,

    1 AS disaster_count

FROM stg_disaster s

JOIN dim_time t
ON s."declarationDate" = t."declarationDate"

JOIN dim_state st
ON s.state = st.state
AND s.region = st.region

JOIN dim_incident i
ON s."incidentType" = i."incidentType"

JOIN dim_program p
ON s."IA" = p."IA"
AND s."PA" = p."PA"
AND s."HM" = p."HM"

JOIN dim_declaration d
ON s."declarationType" = d."declarationType";


--INDEX--
CREATE INDEX idx_fact_time
ON fact_disaster(time_id);

CREATE INDEX idx_fact_state
ON fact_disaster(state_id);

CREATE INDEX idx_fact_incident
ON fact_disaster(incident_id);


--MATERIALIZED VIEW--
CREATE MATERIALIZED VIEW mv_disaster_year AS
SELECT
    t.year,
    COUNT(*) AS total_disaster
FROM fact_disaster f
JOIN dim_time t
ON f.time_id = t.time_id
GROUP BY t.year
ORDER BY t.year;

--VERIFIKASI--
SELECT * FROM fact_disaster LIMIT 10;
SELECT * FROM mv_disaster_year;


--REPLACE--
CREATE OR REPLACE VIEW vw_disaster_analysis AS
SELECT
    f."disasterNumber",
    f.disaster_count,

    t.year,
    t.month,
    t.quarter,

    s.state,
    s.region,

    i."incidentType",

    p."IA",
    p."PA",
    p."HM",

    d."declarationType"

FROM fact_disaster f

JOIN dim_time t
ON f.time_id = t.time_id

JOIN dim_state s
ON f.state_id = s.state_id

JOIN dim_incident i
ON f.incident_id = i.incident_id

JOIN dim_program p
ON f.program_id = p.program_id

JOIN dim_declaration d
ON f.declaration_id = d.declaration_id;

SELECT *
FROM vw_disaster_analysis
LIMIT 5;

--EXPLAIN ANALYZE--
EXPLAIN ANALYZE
SELECT
    year,
    COUNT(*) AS total_disaster
FROM vw_disaster_analysis
GROUP BY year;


--Bersihin index--
DROP INDEX IF EXISTS idx_fact_time;
DROP INDEX IF EXISTS idx_dim_time_year;

EXPLAIN ANALYZE
SELECT
    year,
    COUNT(*) AS total_disaster
FROM vw_disaster_analysis
GROUP BY year
ORDER BY year;


CREATE INDEX idx_fact_time
ON fact_disaster(time_id);

CREATE INDEX idx_dim_time_year
ON dim_time(year);

EXPLAIN ANALYZE
SELECT
    year,
    COUNT(*) AS total_disaster
FROM vw_disaster_analysis
GROUP BY year
ORDER BY year;


DROP MATERIALIZED VIEW IF EXISTS mv_disaster_year;

CREATE MATERIALIZED VIEW mv_disaster_year AS
SELECT
    year,
    COUNT(*) AS total_disaster
FROM vw_disaster_analysis
GROUP BY year
ORDER BY year;

REFRESH MATERIALIZED VIEW mv_disaster_year;

EXPLAIN ANALYZE
SELECT *
FROM mv_disaster_year;

SELECT *
FROM vw_disaster_analysis
LIMIT 5;

select * from dim_time;