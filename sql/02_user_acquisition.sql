-- ============================================================
-- FILE 02 : User Acquisition Analysis
-- ============================================================
-- Dataset : bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Goal    : Analyse traffic sources and channel performance —
--           understanding which channels drive volume, engagement,
--           and revenue for an e-commerce store.
--
-- Business context :
--   E-commerce teams track channel efficiency to allocate marketing spend.
--   This file answers: which channels bring the most users,
--   the most engaged sessions, and the most conversions (purchases)?
--   Key metrics: sessions, conversion rate, revenue, average order value.
--
-- 💡 How to run: copy the full query into BigQuery and click Run.
-- ============================================================


-- ============================================================
-- QUERY 1 — Channel performance overview
--
-- Business question: which acquisition channels drive volume,
-- engagement, and conversions?
-- ============================================================

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    PARSE_DATE('%Y%m%d', event_date)     AS session_date,

    -- Channel classification (mirrors GA4 default channel grouping)
    CASE
      WHEN traffic_source.medium = 'organic'               THEN 'Organic Search'
      WHEN traffic_source.medium = 'cpc'                   THEN 'Paid Search'
      WHEN traffic_source.medium IN ('referral','affiliate') THEN 'Referral'
      WHEN traffic_source.medium = 'email'                 THEN 'Email'
      WHEN traffic_source.medium = 'social'                THEN 'Social'
      WHEN traffic_source.source = '(direct)'
        OR traffic_source.medium = '(none)'                THEN 'Direct'
      ELSE 'Other'
    END                                  AS channel,

    traffic_source.source                AS source,
    COUNT(*) AS events_in_session,
    COUNTIF(event_name = 'purchase') > 0 AS converted,
    ROUND(SUM(ecommerce.purchase_revenue), 2) AS session_revenue,

    -- Engagement: session with >1 event and >10s is considered engaged
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'session_engaged') AS is_engaged

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY
    user_pseudo_id, session_id, session_date,
    channel, source, traffic_source.medium, is_engaged
  HAVING session_id IS NOT NULL
)

SELECT
  channel,
  COUNT(*)                                              AS total_sessions,
  COUNT(DISTINCT user_pseudo_id)                        AS unique_users,
  COUNTIF(converted)                                    AS conversions,
  ROUND(COUNTIF(converted) / COUNT(*) * 100, 2)         AS conversion_rate_pct,
  ROUND(SUM(session_revenue), 2)                        AS total_revenue,
  ROUND(SAFE_DIVIDE(SUM(session_revenue), COUNTIF(converted)), 2) AS avg_order_value,
  ROUND(COUNTIF(is_engaged = 1) / COUNT(*) * 100, 1)   AS engagement_rate_pct
FROM sessions
GROUP BY channel
ORDER BY total_sessions DESC;


-- ============================================================
-- QUERY 2 — Top traffic sources ranked by conversion rate
--
-- Business question: beyond channels, which specific sources
-- convert best? Used to identify partnership or SEO opportunities.
-- ============================================================

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    traffic_source.source                AS source,
    traffic_source.medium                AS medium,
    COUNTIF(event_name = 'purchase') > 0 AS converted,
    ROUND(SUM(ecommerce.purchase_revenue), 2) AS session_revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY user_pseudo_id, session_id, source, medium
  HAVING session_id IS NOT NULL
)

SELECT
  source,
  medium,
  COUNT(*)                                              AS sessions,
  COUNT(DISTINCT user_pseudo_id)                        AS unique_users,
  COUNTIF(converted)                                    AS conversions,
  ROUND(SAFE_DIVIDE(COUNTIF(converted), COUNT(*)) * 100, 2) AS conversion_rate_pct,
  ROUND(SUM(session_revenue), 2)                        AS revenue
FROM sessions
GROUP BY source, medium
HAVING COUNT(*) >= 50    -- filter out low-volume sources for reliability
ORDER BY conversion_rate_pct DESC
LIMIT 20;


-- ============================================================
-- QUERY 3 — New vs returning users by channel
--
-- Business context : in e-commerce analytics, new user acquisition
--   is tracked separately from returning user engagement.
--   High returning-user rate = strong brand loyalty and repeat purchase behaviour.
-- ============================================================

SELECT
  CASE
    WHEN traffic_source.medium = 'organic'                THEN 'Organic Search'
    WHEN traffic_source.medium = 'cpc'                    THEN 'Paid Search'
    WHEN traffic_source.medium IN ('referral','affiliate') THEN 'Referral'
    WHEN traffic_source.source = '(direct)'
      OR traffic_source.medium = '(none)'                 THEN 'Direct'
    ELSE 'Other'
  END                                                     AS channel,

  -- GA4 distinguishes new vs returning at user level
  COUNTIF(
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium')
    IS NOT NULL
    AND event_name = 'first_visit'
  )                                                       AS new_user_events,

  COUNT(DISTINCT user_pseudo_id)                          AS total_users,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase'
    THEN user_pseudo_id END)                              AS converting_users,

  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END)
    / COUNT(DISTINCT user_pseudo_id) * 100,
    2
  )                                                       AS user_conversion_rate_pct

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY channel
ORDER BY total_users DESC;
