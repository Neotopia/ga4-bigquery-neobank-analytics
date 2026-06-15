-- ============================================================
-- FILE 04 : Retention Cohort Analysis
-- ============================================================
-- Dataset : bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Goal    : Measure how many users return after their first visit,
--           grouped by the week they first appeared (acquisition cohort).
--
-- Business context :
--   Retention is one of the most important growth metrics in e-commerce.
--   A user who visits once and never returns generates no long-term value.
--   This analysis answers: of the users acquired in week W,
--   how many came back in W+1, W+2, W+3?
--   For purchasing cohorts: first purchase → repeat purchase behaviour.
--
-- Technique : CTE to define cohorts, then LEFT JOIN to match
--             return activity, DATE_DIFF to compute weeks since first visit.
--
-- 💡 How to run: copy each query separately into BigQuery and click Run.
-- ============================================================


-- ============================================================
-- QUERY 1 — Weekly retention cohort table
--
-- Rows = acquisition cohort (week of first visit)
-- Columns = weeks since first visit (W+0, W+1, W+2, ...)
-- Values = % (pct) of cohort still active that week
-- ============================================================

WITH

-- Step 1: find each user's first active week
first_visit AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'session_start'
  GROUP BY user_pseudo_id
),

-- Step 2: get all active weeks per user
-- Intentionally includes all event types (not just session_start)
-- so that any on-site interaction counts as a return visit.
user_activity AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS activity_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

-- Step 3: join cohort to activity and compute weeks since first visit
cohort_activity AS (
  SELECT
    f.cohort_week,
    DATE_DIFF(a.activity_week, f.cohort_week, WEEK) AS weeks_since_first_visit,
    COUNT(DISTINCT f.user_pseudo_id)                 AS cohort_size,
    COUNT(DISTINCT a.user_pseudo_id)                 AS retained_users
  FROM first_visit f
  LEFT JOIN user_activity a
    ON f.user_pseudo_id = a.user_pseudo_id
   AND a.activity_week >= f.cohort_week
  GROUP BY f.cohort_week, weeks_since_first_visit
)

SELECT *
FROM (
  SELECT
    cohort_week,
    MAX(CASE WHEN weeks_since_first_visit = 0 THEN cohort_size END)  AS cohort_size,

    ROUND(MAX(CASE WHEN weeks_since_first_visit = 0 THEN retained_users END)
      / NULLIF(MAX(CASE WHEN weeks_since_first_visit = 0 THEN cohort_size END), 0) * 100, 1) AS w0_pct,

    ROUND(MAX(CASE WHEN weeks_since_first_visit = 1 THEN retained_users END)
      / NULLIF(MAX(CASE WHEN weeks_since_first_visit = 0 THEN cohort_size END), 0) * 100, 1) AS w1_pct,

    ROUND(MAX(CASE WHEN weeks_since_first_visit = 2 THEN retained_users END)
      / NULLIF(MAX(CASE WHEN weeks_since_first_visit = 0 THEN cohort_size END), 0) * 100, 1) AS w2_pct,

    ROUND(MAX(CASE WHEN weeks_since_first_visit = 3 THEN retained_users END)
      / NULLIF(MAX(CASE WHEN weeks_since_first_visit = 0 THEN cohort_size END), 0) * 100, 1) AS w3_pct,

    ROUND(MAX(CASE WHEN weeks_since_first_visit = 4 THEN retained_users END)
      / NULLIF(MAX(CASE WHEN weeks_since_first_visit = 0 THEN cohort_size END), 0) * 100, 1) AS w4_pct

  FROM cohort_activity
  GROUP BY cohort_week
)
WHERE cohort_size >= 20
ORDER BY cohort_week;


-- ============================================================
-- QUERY 2 — Purchasing cohort retention
--
-- Business question: of users who made a first purchase in week W,
-- how many came back to purchase again?
-- Equivalent to: measuring repeat purchase loyalty after a first order.
-- ============================================================

WITH

first_purchase AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS first_purchase_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
  GROUP BY user_pseudo_id
),

-- All purchase events; week-0 rows are excluded via the JOIN condition below.
all_purchases AS (
  SELECT DISTINCT
    user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS purchase_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
)

SELECT
  f.first_purchase_week,
  COUNT(DISTINCT f.user_pseudo_id) AS cohort_size,

  COUNT(DISTINCT CASE WHEN DATE_DIFF(p.purchase_week, f.first_purchase_week, WEEK) = 1
    THEN p.user_pseudo_id END) AS retained_w1,
  ROUND(
    COUNT(DISTINCT CASE WHEN DATE_DIFF(p.purchase_week, f.first_purchase_week, WEEK) = 1
      THEN p.user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT f.user_pseudo_id), 0) * 100, 1
  ) AS w1_pct,

  COUNT(DISTINCT CASE WHEN DATE_DIFF(p.purchase_week, f.first_purchase_week, WEEK) = 2
    THEN p.user_pseudo_id END) AS retained_w2,
  ROUND(
    COUNT(DISTINCT CASE WHEN DATE_DIFF(p.purchase_week, f.first_purchase_week, WEEK) = 2
      THEN p.user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT f.user_pseudo_id), 0) * 100, 1
  ) AS w2_pct,

  COUNT(DISTINCT CASE WHEN DATE_DIFF(p.purchase_week, f.first_purchase_week, WEEK) BETWEEN 1 AND 4
    THEN p.user_pseudo_id END) AS retained_month1,
  ROUND(
    COUNT(DISTINCT CASE WHEN DATE_DIFF(p.purchase_week, f.first_purchase_week, WEEK) BETWEEN 1 AND 4
      THEN p.user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT f.user_pseudo_id), 0) * 100, 1
  ) AS month1_retention_pct

FROM first_purchase f
LEFT JOIN all_purchases p
  ON f.user_pseudo_id = p.user_pseudo_id
 AND p.purchase_week > f.first_purchase_week
GROUP BY f.first_purchase_week
HAVING COUNT(DISTINCT f.user_pseudo_id) >= 10
ORDER BY f.first_purchase_week;