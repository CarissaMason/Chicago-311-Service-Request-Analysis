/* ------------------------------------------------------------
   Q1: Which request types take longest to resolve?
   First I checked using averages, plus fastest/slowest to view the spread.
   ------------------------------------------------------------ */
SELECT
    SR_TYPE,
    COUNT(*) AS num_requests,
    ROUND(AVG(CAST(RESOLUTION_DAYS AS REAL)), 1) AS avg_days,
    ROUND(MIN(CAST(RESOLUTION_DAYS AS REAL)), 1) AS fastest,
    ROUND(MAX(CAST(RESOLUTION_DAYS AS REAL)), 1) AS slowest
FROM resolved
GROUP BY SR_TYPE
ORDER BY avg_days DESC;
-- Takeaway: the gap between fastest and slowest is huge (e.g. potholes max ~349 days),
-- This is a sign the data is right-skewed and that AVG alone will be misleading.

/* ------------------------------------------------------------
   Q2: Same question, but using the MEDIAN instead of the average.
   Median is more honest here because a slow tail inflates the mean
   (confirmed by Q1's max values). SQLite has no MEDIAN() function,
   so I computed it manually with window functions.
   ------------------------------------------------------------ */
WITH ranked AS (
    SELECT
        SR_TYPE,
        CAST(RESOLUTION_DAYS AS REAL) AS days,
        ROW_NUMBER() OVER (
            PARTITION BY SR_TYPE                      -- restart numbering per type
            ORDER BY CAST(RESOLUTION_DAYS AS REAL)    -- sort so the middle = median
        ) AS rn,
        COUNT(*) OVER (PARTITION BY SR_TYPE) AS cnt   -- group size, kept on every row
    FROM resolved
)
SELECT
    SR_TYPE,
    COUNT(*) AS num_requests,
    ROUND(AVG(days), 1) AS avg_days,
    -- Pick the middle row(s): one if the count is odd, two adjacent if even,
    -- then average them. That value is the median.
    ROUND(AVG(CASE WHEN rn IN ((cnt + 1) / 2, (cnt + 2) / 2) THEN days END), 1) AS median_days
FROM ranked
GROUP BY SR_TYPE
ORDER BY median_days DESC;
-- Takeaway: median sits well below avg for every type (e.g. Bicycle avg 20.4 vs median 3.0),
-- proving the skew.

-- Resolution time by ward median
WITH ranked AS (
    SELECT
        WARD,
        CAST(RESOLUTION_DAYS AS REAL) AS days,
        ROW_NUMBER() OVER (PARTITION BY WARD ORDER BY CAST(RESOLUTION_DAYS AS REAL)) AS rn,
        COUNT(*) OVER (PARTITION BY WARD) AS cnt
    FROM resolved
    WHERE WARD IS NOT NULL AND WARD != ''
)
SELECT
    WARD,
    COUNT(*) AS num_requests,
    ROUND(AVG(CASE WHEN rn IN ((cnt + 1) / 2, (cnt + 2) / 2) THEN days END), 1) AS median_days
FROM ranked
GROUP BY WARD
ORDER BY median_days DESC;
-- Takeaway: Slowest wards sit around 15.8 median days vs 3.3 for the quickest.

-- Q: How does request volume change month to month?
-- Uses all_requests (the FULL set, open + closed) because volume is about
-- how many come in, not how many have closed. Using the resolved-only table
-- here would undercount recent months (newer requests haven't closed yet).
SELECT
    strftime('%Y-%m', CREATED_DATE) AS month,
    COUNT(*) AS num_requests
FROM all_requests
GROUP BY month
ORDER BY month;
-- Note: June 2026 is a partial month (data pulled mid-month)
-- Mild seasonality visible: winter low (~4.5k), spring high (~7k), consistent with weather-driven request types.