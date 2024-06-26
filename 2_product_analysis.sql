--Product Funnel Analysis


/*
Using a single SQL query - create a new output table which has the following details:

    How many times was each product viewed?
    How many times was each product added to cart?
    How many times was each product added to a cart but not purchased (abandoned)?
    How many times was each product purchased?
*/

WITH view_cart_events AS (
SELECT 
    ph.product_category,
    ph.page_name,
    e.visit_id,
    ph.product_id,
    COUNT(CASE WHEN e.event_type=1 THEN 1 ELSE NULL END) AS view_count,
    COUNT(CASE WHEN e.event_type=2 THEN 1 ELSE NULL END) AS add_to_cart_count
FROM  clique_bait.events e
JOIN  clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY  ph.product_category, ph.page_name, e.visit_id, ph.product_id
),
purchase_events AS ( 
  SELECT 
    DISTINCT visit_id
  FROM clique_bait.events
  WHERE event_type = 3 
),
combined_table AS (
  SELECT 
    vce.visit_id, 
    vce.product_id, 
    vce.page_name, 
    vce.product_category, 
    vce.view_count, 
    vce.add_to_cart_count,
    CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
  FROM view_cart_events AS vce
  LEFT JOIN purchase_events AS pe
    ON vce.visit_id = pe.visit_id
)

 SELECT 
    page_name, 
    product_category, 
    product_id,
    SUM(view_count) AS views,
    SUM(add_to_cart_count) AS cart_adds, 
    SUM(CASE WHEN add_to_cart_count = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN add_to_cart_count = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_table
  GROUP BY product_id, page_name, product_category
  ORDER BY product_id;


/*
CAMPAIGN ANALYSIS
Generate a table that has 1 single row for every unique visit_id record and has the following columns:

user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
*/

SELECT 
  u.user_id, e.visit_id, 
  MIN(e.event_time) AS visit_start_time,
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
  SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchase,
  c.campaign_name,
  SUM(CASE WHEN e.event_type = 4 THEN 1 ELSE 0 END) AS impression, 
  SUM(CASE WHEN e.event_type = 5 THEN 1 ELSE 0 END) AS click, 
  STRING_AGG(CASE WHEN p.product_id IS NOT NULL AND e.event_type = 2 THEN p.page_name ELSE NULL END, 
    ', ' ORDER BY e.sequence_number) AS cart_products
FROM clique_bait.users AS u
INNER JOIN clique_bait.events AS e
  ON u.cookie_id = e.cookie_id
LEFT JOIN clique_bait.campaign_identifier AS c
  ON e.event_time BETWEEN c.start_date AND c.end_date
LEFT JOIN clique_bait.page_hierarchy AS p
  ON e.page_id = p.page_id
GROUP BY u.user_id, e.visit_id, c.campaign_name;




