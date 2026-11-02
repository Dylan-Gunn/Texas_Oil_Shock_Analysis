DROP TABLE IF EXISTS areas_swap;

CREATE TABLE areas_swap AS
SELECT * FROM areas;

-- Deleting counties Upton and Reeves
DELETE FROM areas_swap
WHERE area_fips IN ('48461', '48389');

-- Adding two replacement counties
INSERT INTO areas_swap (area_fips, area_name, area_group, group_rule, inclusion_basis)
VALUES
  ('48235', 'Irion', 'oil_heavy', 'swap test: next-highest oil share', 'swap_test'),
  ('48475', 'Ward', 'oil_heavy', 'swap test: next-highest oil share', 'swap_test');

  
  
WITH cm AS (
    SELECT a.area_group, s.report_month,
           SUM(s.net_payment) AS pay, SUM(s.comparable_prior_year) AS prior
    FROM sales_tax s
    JOIN areas_swap a ON UPPER(s.county) = UPPER(a.area_name)
    GROUP BY a.area_group, s.report_month
),
y AS (
    SELECT area_group,
           100.0 * (pay / prior - 1) AS yoy,
           CASE WHEN date(report_month, '-1 month') <  '2026-03-01' THEN 'pre'
                WHEN date(report_month, '-1 month') <= '2026-08-01' THEN 'post' END AS period
    FROM cm
)
SELECT ROUND(
    (AVG(CASE WHEN area_group='oil_heavy'  AND period='post' THEN yoy END)
   - AVG(CASE WHEN area_group='oil_heavy'  AND period='pre'  THEN yoy END))
  - (AVG(CASE WHEN area_group='comparison' AND period='post' THEN yoy END)
   - AVG(CASE WHEN area_group='comparison' AND period='pre'  THEN yoy END)), 2) AS did_swapped
FROM y;



WITH cm AS (
    SELECT a.area_name, a.area_group, s.report_month,
           SUM(s.net_payment) AS net_payment,
           SUM(s.comparable_prior_year) AS comparable_prior_year
    FROM sales_tax s
    JOIN areas_swap a ON UPPER(s.county) = UPPER(a.area_name)
    GROUP BY a.area_name, a.area_group, s.report_month
),
c AS (
    SELECT area_name, area_group,
           100.0 * (net_payment / comparable_prior_year - 1) AS yoy,
           CASE WHEN date(report_month, '-1 month') <  '2026-03-01' THEN 'pre'
                WHEN date(report_month, '-1 month') <= '2026-08-01' THEN 'post' END AS period
    FROM cm
)
SELECT area_group, area_name,
       ROUND(AVG(CASE WHEN period='pre'  THEN yoy END), 2) AS pre_yoy,
       ROUND(AVG(CASE WHEN period='post' THEN yoy END), 2) AS post_yoy,
       ROUND(AVG(CASE WHEN period='post' THEN yoy END)
           - AVG(CASE WHEN period='pre'  THEN yoy END), 2) AS change
FROM c
WHERE period IS NOT NULL
GROUP BY area_group, area_name
ORDER BY area_group, change;