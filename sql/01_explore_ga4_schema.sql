-- ============================================================
-- FILE 01 : GA4 Schema Exploration
-- ============================================================
-- Dataset : bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Details : Only ecommerce data from 2020 available
-- Goal    : Understand the GA4 BigQuery export schema before
--           writing analytical queries.
--
-- ⚠️ Key difference vs classic SQL tables:
--   GA4 data is stored as EVENTS, not sessions or users.
--   Each row = one event. Dimensions like page URL or item name
--   are stored inside nested ARRAY<STRUCT> columns (event_params,
--   items, user_properties) — you must UNNEST them to access values.
--
-- 💡 How to run: copy the full query into BigQuery and click Run.
--    Dataset is public — no setup needed.
-- ============================================================


-- ============================================================
-- QUERY 1 — Raw event structure
-- What does a single GA4 event look like?
-- ============================================================

SELECT
  event_date,
  event_timestamp,
  event_name,

  -- User identifier (pseudonymous, no PII)
  user_pseudo_id,

  -- Traffic source of the session that triggered this event
  traffic_source.source        AS traffic_source,
  traffic_source.medium        AS traffic_medium,
  traffic_source.name          AS traffic_campaign,

  -- Geographic context
  geo.country                  AS country,
  geo.city                     AS city,

  -- Device context
  device.category              AS device_category,
  device.operating_system      AS os,

  -- event_params is an ARRAY of key-value pairs
  -- → you cannot SELECT a value directly, you must UNNEST first (see Query 2)
  event_params

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX = '20201101'   -- single day to keep the preview fast
LIMIT 10;


-- ============================================================
-- QUERY 2 — UNNEST event_params
--
-- event_params stores all event-level dimensions as an array:
--   [{ key: "page_location", value: { string_value: "https://..." } },
--    { key: "session_id",    value: { int_value: 1234567 } }, ...]
--
-- To extract a specific parameter, UNNEST the array and filter by key.
-- ============================================================

SELECT
  event_date,
  event_name,
  user_pseudo_id,

  -- Extract page URL from event_params
  (SELECT value.string_value
   FROM UNNEST(event_params)
   WHERE key = 'page_location')        AS page_location,

  -- Extract session ID (stored as int_value)
  (SELECT value.int_value
   FROM UNNEST(event_params)
   WHERE key = 'ga_session_id')        AS session_id,

  -- Extract engagement time in milliseconds
  (SELECT value.int_value
   FROM UNNEST(event_params)
   WHERE key = 'engagement_time_msec') AS engagement_time_msec

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX = '20201101'
  AND event_name = 'page_view'
LIMIT 20;


-- ============================================================
-- QUERY 3 — Event inventory
-- Event Volume: Top events by count, unique users, and date range. E-commerce data available (purchase event).
-- ============================================================

SELECT
  event_name,
  COUNT(*)                             AS event_count,
  COUNT(DISTINCT user_pseudo_id)       AS unique_users,
  MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_seen,
  MAX(PARSE_DATE('%Y%m%d', event_date)) AS last_seen
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
ORDER BY event_count DESC;


-- ============================================================
-- QUERY 4 — Evolution of actif users and purchases over time
-- ============================================================

SELECT
  PARSE_DATE('%Y%m%d', event_date)     AS date,
  COUNT(*)                             AS total_events,
  COUNT(DISTINCT user_pseudo_id)       AS daily_active_users,
  COUNTIF(event_name = 'session_start') AS sessions,
  COUNTIF(event_name = 'purchase')     AS purchases
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY date
ORDER BY date;


-- ============================================================
-- QUERY 5 — Session conversion and revenue
-- ============================================================

SELECT
  user_pseudo_id,

  -- ga_session_id is stored inside event_params
  (SELECT value.int_value
   FROM UNNEST(event_params)
   WHERE key = 'ga_session_id')                       AS session_id,

  PARSE_DATE('%Y%m%d', event_date)                    AS session_date,
  traffic_source.source                               AS source,
  traffic_source.medium                               AS medium,
  device.category                                     AS device,
  geo.country                                         AS country,

  COUNT(*) AS events_in_session,

  -- Session contained a purchase?
  COUNTIF(event_name = 'purchase') > 0                AS converted,

  -- Total revenue in session (items array, not event_params)
  ROUND(SUM(ecommerce.purchase_revenue), 2)           AS session_revenue

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY
  user_pseudo_id,
  session_id,
  session_date,
  source,
  medium,
  device,
  country
HAVING session_id IS NOT NULL
ORDER BY session_date, session_revenue DESC
LIMIT 100;