--- Digital Analysis



---How many users are there?

SELECT COUNT(DISTINCT user_id)
FROM clique_bait.users


--How many cookies does each user have on average?
WITH cookie_count AS (
SELECT 
    user_id, 
    COUNT(cookie_id) AS cookie_id_count
  FROM clique_bait.users
  GROUP BY user_id
)

SELECT
ROUND(AVG(cookie_id_count), 2)
from cookie_count

--What is the unique number of visits by all users per month?

SELECT COUNT(DISTINCT visit_id), EXTRACT(month from event_time)
FROM clique_bait.events
GROUP by EXTRACT(month from event_time)

--What is the number of events for each event type?
SELECT COUNT(*), event_type
FROM clique_bait.events
GROUP by event_type


--What is the percentage of visits which have a purchase event?
SELECT 
  100 * COUNT(DISTINCT e.visit_id)/
    (SELECT COUNT(DISTINCT visit_id) FROM clique_bait.events) AS percentage_purchase
FROM clique_bait.events AS e
JOIN clique_bait.event_identifier AS ei
  ON e.event_type = ei.event_type
WHERE ei.event_name = 'Purchase';


--What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH checkout_purchase AS (
SELECT 
  visit_id,
  MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS checkout,
  MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
FROM clique_bait.events
GROUP BY visit_id)

SELECT 
  ROUND(100 * (1-(SUM(purchase)::numeric/SUM(checkout))),2) AS percent_checkout_view_no_purchase
FROM checkout_purchase


--What are the top 3 pages by number of views?
SELECT page_name, COUNT(visit_id) AS view_count
FROM clique_bait.events e
LEFT JOIN  clique_bait.page_hierarchy ph ON e.page_id=ph.page_id
WHERE event_type = 1 --Page View
GROUP BY page_name
ORDER BY view_count DESC
LIMIT 3;


--What is the number of views and cart adds for each product category?
SELECT ph.product_category,
  SUM(CASE WHEN e.event_type=1 THEN 1 ELSE 0 END) AS page_view_counts,
  SUM(CASE WHEN e.event_type=2 THEN 1 ELSE 0 END) AS add_to_cart_counts
FROM clique_bait.events e
LEFT JOIN  clique_bait.page_hierarchy ph ON e.page_id=ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY page_view_counts DESC;


