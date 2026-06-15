# GA4 → BigQuery — Digital Analytics

SQL analysis of real GA4 event data exported to BigQuery.  
Built to demonstrate the intersection of **Digital Analytics** and **Data Analytics Engineering** skills.

**Stack:** Google BigQuery · Standard SQL · GA4 BigQuery Export · Window Functions · Cohort Analysis

> Dataset: `bigquery-public-data.ga4_obfuscated_sample_ecommerce` — official Google sample, no setup required.

---

## Why this project

End-to-end SQL analysis of GA4 e-commerce event data in BigQuery — covering acquisition, funnel performance, and cohort retention. Built to demonstrate the kind of analytical work a digital analyst owns: from raw event data to business-ready KPIs.

---

## Repository Structure

```
ga4-bigquery-neobank-analytics/
└── sql/
    ├── 01_explore_ga4_schema.sql       → GA4 schema discovery, UNNEST event_params
    ├── 02_user_acquisition.sql         → Traffic sources, channel performance, CAC proxy
    ├── 03_conversion_funnel.sql        → Event funnel: landing → engagement → conversion
    ├── 04_retention_cohorts.sql        → Weekly cohort retention (visits & purchases)
    └── 05_business_playbook.sql        → Combined KPIs: ROAS proxy, LTV estimate, churn signal
```

---

## How to Run

1. Open [BigQuery Sandbox](https://console.cloud.google.com/bigquery) — free, no credit card needed
2. Copy any file entirely and paste it into the BigQuery editor
3. Click **Run** — the dataset is public, no import needed

> The GA4 public dataset is queried directly via `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`.  
> All queries are self-contained and reference this table directly.

---

## Concepts Covered

| File | SQL & Analytics Concepts |
|---|---|
| `01_explore_ga4_schema.sql` | `UNNEST`, `ARRAY<STRUCT>`, nested fields, event taxonomy |
| `02_user_acquisition.sql` | `traffic_source`, channel grouping, `COUNT DISTINCT`, session reconstruction |
| `03_conversion_funnel.sql` | Conditional aggregation, funnel steps, conversion rate, `CASE WHEN` |
| `04_retention_cohorts.sql` | Cohort definition, `DATE_DIFF`, `COUNTIF`, retention rate |
| `05_business_playbook.sql` | Multi-CTE pipelines, LTV proxy, churn signal, executive KPI summary |

---

## Business Playbook — Queries at a Glance

| # | Business Question | Use Case |
|---|---|---|
| Q1 | Which acquisition channels drive the most engaged users? | Marketing budget allocation |
| Q2 | Where do users drop off in the conversion funnel? | Product & UX optimisation |
| Q3 | What does weekly retention look like by acquisition cohort? | Growth & repeat purchase KPIs |
| Q4 | Which user segments have the highest revenue potential? | LTV-based targeting |
| Q5 | Which users showed purchase intent but never converted? | Re-engagement prioritisation |

---

## Author

**Lisa Momas** — Digital Analytics & Data  
[LinkedIn](https://www.linkedin.com/in/lisa-momas)
