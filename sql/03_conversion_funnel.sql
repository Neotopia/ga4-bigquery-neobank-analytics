-- ============================================================
-- FILE 03 : Conversion Funnel Analysis
-- ============================================================
-- Dataset : bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Goal    : Reconstruct the user journey from first visit to
--           conversion and identify where users drop off.
--
-- Business context :
--   E-commerce conversion funnels measure where users drop off between
--   their first visit and a completed purchase.
--   This dataset maps the full journey:
--     session_start → view_item → add_to_cart → begin_checkout → purchase
--   Identifying the biggest drop-off step guides UX and product decisions.
--
-- 💡 How to run: copy the full query into BigQuery and click Run.
-- ============================================================


-- ============================================================
-- QUERY 1 — Overall funnel: volume and drop-off at each step
--
-- Business question: how many users complete each funnel step,
-- and where is the biggest drop-off?
-- ============================================================

SELECT
  COUNT(DISTINCT CASE WHEN event_name = 'session_start'  THEN user_pseudo_id END) AS step_1_sessions,
  COUNT(DISTINCT CASE WHEN event_name = 'view_item'       THEN user_pseudo_id END) AS step_2_view_item,
  COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart'     THEN user_pseudo_id END) AS step_3_add_to_cart,
  COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout'  THEN user_pseudo_id END) AS step_4_checkout,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase'        THEN user_pseudo_id END) AS step_5_purchase,

  -- Conversion rates step by step
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END)
     / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END), 0) * 100,
    1
  ) AS pct_to_view_item,

  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END), 0) * 100,
    1
  ) AS pct_view_to_cart,

  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart' THEN user_pseudo_id END), 0) * 100,
    1
  ) AS pct_cart_to_checkout,

  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN user_pseudo_id END), 0) * 100,
    1
  ) AS pct_checkout_to_purchase,

  -- End-to-end conversion rate: sessions → purchases
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END)
    / COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END) * 100,
    2
  ) AS overall_conversion_rate_pct

FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';

-- ============================================================
-- QUERY 2 — Funnel by acquisition channel
--
-- Business question: which channels bring users who convert best?
-- Justification for marketing budget allocation.
-- ============================================================

WITH user_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    CASE
      WHEN traffic_source.medium = 'organic'                THEN 'Organic Search'
      WHEN traffic_source.medium = 'cpc'                    THEN 'Paid Search'
      WHEN traffic_source.medium IN ('referral','affiliate') THEN 'Referral'
      WHEN traffic_source.source = '(direct)'
        OR traffic_source.medium = '(none)'                 THEN 'Direct'
      ELSE 'Other'
    END AS channel
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  channel,
  COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END)  AS sessions,
  COUNT(DISTINCT CASE WHEN event_name = 'view_item'      THEN user_pseudo_id END)  AS viewed_item,
  COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart'    THEN user_pseudo_id END)  AS added_to_cart,
  COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout' THEN user_pseudo_id END)  AS started_checkout,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase'       THEN user_pseudo_id END)  AS purchased,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase'      THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END), 0) * 100,
    2
  )                                                                                AS end_to_end_cvr_pct
FROM user_events
GROUP BY channel
ORDER BY sessions DESC;


-- ============================================================
-- QUERY 3 — Funnel by device category
--
-- Business question: do mobile users convert at a lower rate?
-- Common finding in e-commerce: mobile drives volume, desktop drives conversion.
-- ============================================================

WITH user_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    device.category AS device_category
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  device_category,
  COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END) AS sessions,
  COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart'   THEN user_pseudo_id END) AS add_to_cart,
  COUNT(DISTINCT CASE WHEN event_name = 'purchase'      THEN user_pseudo_id END) AS purchases,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_name = 'purchase'    THEN user_pseudo_id END)
    / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'session_start' THEN user_pseudo_id END), 0) * 100,
    2
  )                                                                               AS conversion_rate_pct
FROM user_events
GROUP BY device_category
ORDER BY sessions DESC;