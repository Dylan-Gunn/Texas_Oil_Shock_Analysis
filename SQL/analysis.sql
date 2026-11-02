-- Monthly average prices
DROP VIEW IF EXISTS monthly_prices;

CREATE VIEW monthly_prices AS
SELECT series,
       substr(price_date, 1, 7) || '-01' AS price_month,
       ROUND(AVG(value), 3)              AS avg_value,
       COUNT(value)                      AS n_obs
FROM prices
GROUP BY series, substr(price_date, 1, 7);

-- Checking average price before and after shock
SELECT * FROM monthly_prices
WHERE series = 'brent' AND price_month BETWEEN '2026-01-01' AND '2026-08-01'
ORDER BY price_month;


DROP VIEW IF EXISTS county_monthly;

CREATE VIEW county_monthly AS
SELECT
    a.area_fips,
    a.area_name,
    a.area_group,
    s.report_month,
    SUM(s.net_payment)           AS net_payment,
    SUM(s.comparable_prior_year) AS comparable_prior_year,
    COUNT(*)                     AS n_city_rows
FROM sales_tax s
JOIN areas a ON UPPER(s.county) = UPPER(a.area_name)
GROUP BY a.area_fips, a.area_name, a.area_group, s.report_month;

DROP VIEW IF EXISTS group_sales_yoy;


-- Year over year sales
CREATE VIEW group_sales_yoy AS
SELECT area_group,
       report_month,
       SUM(net_payment)           AS payment,
       SUM(comparable_prior_year) AS prior_year_payment,
       ROUND(100.0 * (SUM(net_payment) / SUM(comparable_prior_year) - 1), 2) AS yoy_pct
FROM county_monthly
GROUP BY area_group, report_month;

-- Cross checking data
SELECT g.area_group, g.report_month,
       g.yoy_pct AS file_yoy,
       ROUND(100.0 * (g.payment / p.payment - 1), 2) AS own_yoy
FROM group_sales_yoy g
JOIN group_sales_yoy p
  ON p.area_group = g.area_group
 AND p.report_month = date(g.report_month, '-12 months')
ORDER BY g.area_group, g.report_month;

-- Lining up sales with prices
DROP VIEW IF EXISTS analysis_monthly;

CREATE VIEW analysis_monthly AS
SELECT g.area_group,
       g.report_month,
       date(g.report_month, '-1 month') AS sales_month,
       g.yoy_pct                        AS sales_yoy_pct,
       CASE WHEN date(g.report_month, '-1 month') <  '2026-03-01' THEN 'pre'
            WHEN date(g.report_month, '-1 month') <= '2026-08-01' THEN 'post'
            ELSE 'after_window' END     AS period,
       b.avg_value   AS brent_avg,
       gas.avg_value AS gasoline_avg
FROM group_sales_yoy g
LEFT JOIN monthly_prices b
       ON b.series = 'brent'
      AND b.price_month = date(g.report_month, '-1 month')
LEFT JOIN monthly_prices gas
       ON gas.series = 'gasoline_regular'
      AND gas.price_month = date(g.report_month, '-1 month');

	  
-- Comparison 
SELECT period,
       ROUND(oil, 2)         AS oil_heavy_yoy,
       ROUND(comp, 2)        AS comparison_yoy,
       ROUND(oil - comp, 2)  AS gap
FROM (
    SELECT period,
           AVG(CASE WHEN area_group = 'oil_heavy'  THEN sales_yoy_pct END) AS oil,
           AVG(CASE WHEN area_group = 'comparison' THEN sales_yoy_pct END) AS comp
    FROM analysis_monthly
    WHERE period IN ('pre', 'post')
    GROUP BY period
);

-- Checking trend pre-shock
SELECT sales_month,
       ROUND(AVG(CASE WHEN area_group = 'oil_heavy'  THEN sales_yoy_pct END), 2) AS oil,
       ROUND(AVG(CASE WHEN area_group = 'comparison' THEN sales_yoy_pct END), 2) AS comp,
       ROUND(AVG(CASE WHEN area_group = 'oil_heavy'  THEN sales_yoy_pct END)
           - AVG(CASE WHEN area_group = 'comparison' THEN sales_yoy_pct END), 2) AS gap
FROM analysis_monthly
GROUP BY sales_month
ORDER BY sales_month;

-- Change in specific counties
WITH c AS (
    SELECT area_name, area_group, report_month,
           100.0 * (net_payment / comparable_prior_year - 1) AS yoy,
           CASE WHEN date(report_month, '-1 month') <  '2026-03-01' THEN 'pre'
                WHEN date(report_month, '-1 month') <= '2026-08-01' THEN 'post' END AS period
    FROM county_monthly
)
SELECT area_group, area_name,
       ROUND(AVG(CASE WHEN period = 'pre'  THEN yoy END), 2) AS pre_yoy,
       ROUND(AVG(CASE WHEN period = 'post' THEN yoy END), 2) AS post_yoy,
       ROUND(AVG(CASE WHEN period = 'post' THEN yoy END)
           - AVG(CASE WHEN period = 'pre'  THEN yoy END), 2) AS change
FROM c
WHERE period IS NOT NULL
GROUP BY area_group, area_name
ORDER BY area_group, change;