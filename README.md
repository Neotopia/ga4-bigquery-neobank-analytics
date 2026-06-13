# GA4 → BigQuery — Digital Analytics

SQL analysis of real GA4 event data exported to BigQuery.  
Built to demonstrate the intersection of **Digital Analytics** and **Data Analytics Engineering** skills.

**Stack:** Google BigQuery · Standard SQL · GA4 BigQuery Export · Window Functions · Cohort Analysis

> Dataset: `bigquery-public-data.ga4_obfuscated_sample_ecommerce` — official Google sample, no setup required.

---

## Why this project

BigQuery pipelines to understand user acquisition, product funnel performance, and retention. This project demonstrates the full analytics stack a digital analyst would own in that context.

---

## Repository Structure

```
ga4-bigquery-neobank-analytics/
└── sql/
    ├── 01_explore_ga4_schema.sql       → GA4 schema discovery, UNNEST event_params
    ├── 02_user_acquisition.sql         → Traffic sources, channel performance, CAC proxy
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


---

## Author

**Lisa Momas** — Digital Analytics & Data  
[LinkedIn](https://www.linkedin.com/in/lisa-momas)
