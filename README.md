# Chicago 311 Service Request Response Times

**Where and which services does Chicago respond slowest to its residents?**

An end-to-end analysis of Chicago's 311 service requests from raw city data to an interactive dashboard, examining how service resolution times vary by request type, by ward, and across the year.

**[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/carissa.mason/viz/Chicago311ServiceRequestResponseTimes/Dashboard1)**

---

## Summary

Chicago resolves a typical 311 request in approximately **9 days**, but that citywide median hides large, uneven gaps, as some services take about 5x longer than others. Response time depends heavily on *what* a resident reports and *where* they live.

## The data

- **Source:** [Chicago Data Portal — 311 Service Requests](https://data.cityofchicago.org/Service-Requests/311-Service-Requests/v6vf-nfxy) (dataset `v6vf-nfxy`)
- **Scope:** A 12-month window (July 2025 – June 2026), filtered to six common, closeable request types: Abandoned Vehicle, Alley Pothole, Alley Light Out, Alley Sewer Inspection, Bee/Wasp Removal, and Bicycle Request.
- **Size:** ~70,500 requests, of which ~64,800 had been resolved (closed) and could be used to measure resolution time.

## Methodology

**1. Cleaning (Python/pandas)**
- Parsed the raw timestamps, which arrived as `MM/DD/YYYY HH:MM:SS AM/PM` text, into proper datetime values.
- Calculated `RESOLUTION_DAYS` as the difference between the created and closed timestamps.
- Split the data into two tables: a full set (all requests, used for volume-over-time) and a resolved-only set (closed requests, used for timing analysis).

**2. Analysis (SQL — SQLite via DB Browser)**
- Aggregated resolution time by request type and by ward.
- Reported the **median** rather than the mean, because the data is strongly right-skewed (mean ≈ 17.5 days vs. median ≈ 9.3 days — a small number of very slow requests inflate the average).
- Computed medians using window functions (`ROW_NUMBER()` and `COUNT() OVER`), since SQLite has no built-in median function.
- See [`analysis.sql`](analysis.sql) for all queries, commented with the reasoning behind each.

**3. Visualization (Tableau Public)**
- A four-panel dashboard: resolution by type, top-slowest wards, monthly request volume, and a type-by-month heat map.

## Key findings

1. **Service type drives speed.** Alley sewer inspections (median ~17 days) and alley potholes (~15 days) are the slowest to resolve. Bicycle, bee/wasp, and alley-light requests close in 3–4 days.
2. **Geography matters.** The slowest wards take roughly **5x longer** (median ~16 days) than the fastest (~3 days), pointing to real differences in service delivery across the city.
3. **Demand is seasonal.** Request volume peaks in spring (~7,000/month, March–May) and dips in late fall (~4,500/month in November), consistent with the weather-driven nature of the request types studied.

## Recommendations

- **Investigate the two slowest services.** Alley sewer inspections and alley potholes are consistent outliers; a workflow or resourcing review for these categories would target the biggest delays.
- **Audit the slowest wards.** A handful of wards lag the rest by a wide margin. Comparing their crew allocation and routing against faster wards could reveal causes of these slowdowns.
- **Pre-staff for spring.** The spring surge in alley and pavement-related requests is predictable; scaling crews ahead of it would reduce backlog growth.
- **Track medians, not averages.** Because resolution times are right-skewed, reporting medians (or percentiles) gives a more honest picture of the typical resident's experience than the mean.

## Limitations

- **Resolution time covers closed requests only.** Currently, open requests have no resolution time and are excluded from timing analysis.
- **June 2026 is a partial month.** (data pulled mid-month) and is excluded from the volume trend to avoid a misleading drop.
- **Uneven sample sizes.** Abandoned Vehicle complaints make up the majority of requests; smaller categories have fewer observations.
- **No income/equity layer.** An earlier plan to correlate response time with neighborhood income was dropped: the most accessible income dataset predates the request data by over a decade, and a time-matched source could not be reliably obtained. This is noted as a deliberate scoping decision rather than an oversight.

## Repository contents

| File | Description |
|------|-------------|
| `README.md` | This file |
| `analysis.sql` | All SQL queries, commented |
| `311_clean.ipynb` | Python/pandas cleaning notebook |
| `chicago_311_resolved.csv` | Cleaned data — resolved requests (timing analysis) |
| `chicago_311_all.csv` | Cleaned data — all requests (volume analysis) |

## Tools

Python (pandas) · SQL (SQLite) · Tableau Public

---

*Built by [CARISSA MASON](https://www.linkedin.com/in/carissa-datascience/) as a data analytics portfolio project.*
