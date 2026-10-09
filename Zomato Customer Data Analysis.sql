use [Zomato Analysis];

--Revenue Analysis
--What is the total revenue?
select sum(order_amount) as total_revenue
from Orders
where order_status = 'Delivered'
;

--2. What is the monthly revenue trend?
select datetrunc(month,order_timestamp) as month,sum(order_amount) as total_revenue
from Orders
where order_status = 'Delivered'
group by datetrunc(month,order_timestamp)
order by month asc
;


--3. Which city contributes the highest revenue?
select a.City, sum(order_amount) as total_revenue from Customers a
join Orders o
on a.customer_id = o.customer_id
where order_status = 'Delivered'
group by a.city
order by sum(order_amount) desc;


--4. Which payment mode generates the most revenue?
select payment_mode, sum(order_amount) as total_revenue
from Orders
where order_status = 'Delivered'
group by payment_mode
order by sum(order_amount) desc;


--5. What is the Average Order Value (AOV)?
select sum(order_amount)/count(distinct order_id) as average_order_value
from Orders
where order_status = 'Delivered'
;

--Customer Analysis
--1. Who are the top 20 customers by revenue?
--Method 1
SELECT TOP 20
    customer_id,
    SUM(order_amount - discount_amount + delivery_fee) AS revenue,
    COUNT(order_id) AS delivered_orders
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY revenue DESC;

--Method 2
with cte as (
select customer_id, sum(order_amount - discount_amount + delivery_fee) as total_revenue
from orders
where order_status = 'Delivered'
group by customer_id)

select customer_id, total_revenue from (
select customer_id, cte.total_revenue, row_number() over(order by total_revenue desc) as rnk from cte) b
where rnk<=20;

--2. What percentage of revenue comes from top customers?

--Method 1 
with cte1 as (
select customer_id, sum(order_amount - discount_amount + delivery_fee) as total_revenue
from orders
where order_status = 'Delivered'
group by customer_id),
cte2 as (
select customer_id, total_revenue from (
select customer_id, cte1.total_revenue, row_number() over(order by total_revenue desc) as rnk from cte1) b
where rnk<=20)

select sum(total_revenue)*100/(select sum(order_amount - discount_amount + delivery_fee) from Orders
where order_status = 'Delivered') from cte2

--Method 2
WITH customer_revenue AS ( 
    SELECT
        customer_id,
        SUM(order_amount - discount_amount + delivery_fee) AS revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS customer_rank
    FROM customer_revenue
)
SELECT
    SUM(CASE WHEN customer_rank <= 20 THEN revenue ELSE 0 END) AS top_20_revenue,
    SUM(revenue) AS total_revenue,
    ROUND(
        100.0 * SUM(CASE WHEN customer_rank <= 20 THEN revenue ELSE 0 END)
        / SUM(revenue),
        2
    ) AS top_20_revenue_percentage
FROM ranked_customers;

--3. Which acquisition channel brings the highest-value customers?

SELECT
    c.Acquisition_channel,
    COUNT(DISTINCT o.customer_id) AS customers,
    SUM(o.order_amount - o.discount_amount + o.delivery_fee) AS total_revenue,
    SUM(o.order_amount - o.discount_amount + o.delivery_fee)
        / COUNT(DISTINCT o.customer_id) AS revenue_per_customer
FROM orders o
JOIN Customers c
    ON o.customer_id = c.Customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.Acquisition_channel
ORDER BY revenue_per_customer DESC; 


--4. How many repeat customers do we have?
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT
        customer_id,
        COUNT(order_id) AS order_count
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) AS customer_orders;


--Restaurant Performance
--1. Which restaurants generate the highest revenue?
SELECT TOP 10
    r.restaurant_id,
    r.restaurant_name,
    SUM(o.order_amount - o.discount_amount + o.delivery_fee) AS revenue
FROM orders o
JOIN restaurants r
    ON o.restaurant_id = r.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY revenue DESC;

--2. Which restaurants receive the most orders?
SELECT TOP 10
    r.restaurant_id,
    r.restaurant_name,
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN restaurants r
    ON o.restaurant_id = r.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY total_orders DESC;


--3. Which cuisines are most popular?
SELECT
    r.cuisine,
    COUNT(o.order_id) AS total_orders,
    SUM(o.order_amount - o.discount_amount + o.delivery_fee) AS revenue
FROM orders o
JOIN restaurants r
    ON o.restaurant_id = r.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.cuisine
ORDER BY total_orders DESC;

--4. Do highly-rated restaurants generate more revenue?
SELECT
    r.avg_rating,
    COUNT(DISTINCT r.restaurant_id) AS restaurants,
    AVG(CAST(x.revenue AS DECIMAL(18,2))) AS avg_revenue
FROM restaurants r
JOIN (
    SELECT
        restaurant_id,
        SUM(order_amount - discount_amount + delivery_fee) AS revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY restaurant_id
) x
    ON r.restaurant_id = x.restaurant_id
GROUP BY r.avg_rating
ORDER BY r.avg_rating desc;


--5. Last 5 restaurants
--based on Average ratings
SELECT TOP 5
    restaurant_id,
    restaurant_name,
    avg_rating
FROM restaurants
ORDER BY avg_rating ASC;

--based on revenue
SELECT TOP 5
    r.restaurant_id,
    r.restaurant_name,
	SUM(o.order_amount - o.discount_amount + o.delivery_fee) AS revenue,
    r.avg_rating
FROM restaurants r
join orders o
on r.restaurant_id = o.restaurant_id
group by r.restaurant_id, r.restaurant_name, r.avg_rating
ORDER BY r.avg_rating asc;


--Coupon Analysis
--1. What percentage of orders use coupons?
SELECT
    COUNT(*) AS total_delivered_orders,
    SUM(CASE WHEN discount_amount > 0 THEN 1 ELSE 0 END) AS coupon_orders,
    ROUND(
        100.0 * SUM(CASE WHEN discount_amount > 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS coupon_usage_percentage
FROM orders
WHERE order_status = 'Delivered';

--2. Do coupon users spend more than non-coupon users?
SELECT
    CASE
        WHEN discount_amount > 0 THEN 'Coupon User'
        ELSE 'Non-Coupon User'
    END AS customer_type,
    COUNT(*) AS orders,
    ROUND(AVG(order_amount), 2) AS avg_order_value,
    ROUND(
        AVG(order_amount - discount_amount + delivery_fee),
        2
    ) AS avg_realized_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY
    CASE
        WHEN discount_amount > 0 THEN 'Coupon User'
        ELSE 'Non-Coupon User'
    END;

--3. Which city uses the most coupons?
SELECT
    c.City,
    SUM(CASE WHEN o.discount_amount > 0 THEN 1 ELSE 0 END) AS coupon_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.Customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.City
ORDER BY coupon_orders DESC;

--4. Are coupons helping customer retention?
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(CASE WHEN discount_amount > 0 THEN 1 ELSE 0 END) AS coupon_orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
customer_segments AS (
    SELECT
        customer_id,
        total_orders,
        CASE
            WHEN coupon_orders > 0 THEN 'Coupon User'
            ELSE 'Non-Coupon User'
        END AS customer_type,
        CASE
            WHEN total_orders > 1 THEN 1
            ELSE 0
        END AS is_repeat
    FROM customer_orders
)
SELECT
    customer_type,
    COUNT(*) AS customers,
    SUM(is_repeat) AS repeat_customers,
    ROUND(
        100.0 * SUM(is_repeat) / COUNT(*),
        2
    ) AS repeat_rate
FROM customer_segments
GROUP BY customer_type;


--Cancellation & Refund Analysis
--1. What is the cancellation rate?
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS cancellation_rate
FROM orders;


--2. What is the refund rate?
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'Refunded' THEN 1 ELSE 0 END) AS refunded_orders,
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'Refunded' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS refund_rate
FROM orders;


--3. How much revenue is lost due to cancellations?
SELECT
    SUM(
        order_amount
        - discount_amount
        + delivery_fee
    ) AS lost_revenue
FROM orders
WHERE order_status = 'Cancelled';


--4. Which restaurants have the highest cancellation rate?
SELECT TOP 10
    r.restaurant_id,
    r.restaurant_name,
    COUNT(o.order_id) AS total_orders,
    SUM(
        CASE
            WHEN o.order_status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN o.order_status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) / COUNT(o.order_id),
        2
    ) AS cancellation_rate
FROM orders o
JOIN restaurants r
    ON o.restaurant_id = r.restaurant_id
GROUP BY
    r.restaurant_id,
    r.restaurant_name
ORDER BY cancellation_rate DESC;


--Customer Churn Analysis
--1. How many customers have churned?
WITH last_order AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS churned_customers
FROM customers c
LEFT JOIN last_order l
    ON c.Customer_id = l.customer_id
WHERE l.last_order_date < DATEADD(DAY, -90, '2026-04-30')
   OR l.last_order_date IS NULL;


--2. What is the churn rate?
WITH last_order AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(
        CASE
            WHEN l.last_order_date < DATEADD(DAY, -90, '2026-04-30')
              OR l.last_order_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS churned_customers,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN l.last_order_date < DATEADD(DAY, -90, '2026-04-30')
                  OR l.last_order_date IS NULL
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate
FROM customers c
LEFT JOIN last_order l
    ON c.Customer_id = l.customer_id;


--3. Which city has the highest churn?
WITH last_order AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
customer_churn AS (
    SELECT
        c.Customer_id,
        c.City,
        CASE
            WHEN l.last_order_date < DATEADD(DAY, -90, '2026-04-30')
              OR l.last_order_date IS NULL
            THEN 1 ELSE 0
        END AS churned
    FROM customers c
    LEFT JOIN last_order l
        ON c.Customer_id = l.customer_id
)
SELECT
    City,
    COUNT(*) AS total_customers,
    SUM(churned) AS churned_customers,
    ROUND(100.0 * SUM(churned) / COUNT(*), 2) AS churn_rate
FROM customer_churn
GROUP BY City
ORDER BY churn_rate DESC;


--4. How much revenue is lost due to churn?
WITH last_order AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
churned_customers AS (
    SELECT
        c.Customer_id
    FROM customers c
    LEFT JOIN last_order l
        ON c.Customer_id = l.customer_id
    WHERE l.last_order_date < DATEADD(DAY, -90, '2026-04-30')
       OR l.last_order_date IS NULL
)
SELECT
    SUM(
        o.order_amount
        - o.discount_amount
        + o.delivery_fee
    ) AS revenue_from_churned_customers
FROM orders o
JOIN churned_customers c
    ON o.customer_id = c.Customer_id
WHERE o.order_status = 'Delivered';


--5. Who are the high-value churned customers?
WITH last_order AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
churned_customers AS (
    SELECT
        c.Customer_id,
        c.Customer_name,
        c.City,
        l.last_order_date
    FROM customers c
    LEFT JOIN last_order l
        ON c.Customer_id = l.customer_id
    WHERE l.last_order_date < DATEADD(DAY, -90, '2026-04-30')
       OR l.last_order_date IS NULL
),
customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(
            o.order_amount
            - o.discount_amount
            + o.delivery_fee
        ) AS historical_revenue,
        COUNT(o.order_id) AS delivered_orders
    FROM orders o
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
)
SELECT TOP 10
    c.Customer_id,
    c.Customer_name,
    c.City,
    r.historical_revenue,
    r.delivered_orders,
    c.last_order_date
FROM churned_customers c
JOIN customer_revenue r
    ON c.Customer_id = r.customer_id
ORDER BY r.historical_revenue DESC;

