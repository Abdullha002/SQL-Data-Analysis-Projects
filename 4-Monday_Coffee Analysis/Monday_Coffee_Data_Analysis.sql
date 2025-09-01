-- Monday Coffee SCHEMAS

-- Import Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales

DROP TABLE IF EXISTS city;
CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

DROP TABLE IF EXISTS customers;
CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

DROP TABLE IF EXISTS products;
CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales;

-- 10 Business Problems

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, 
-- given that 25% of the population does?

SELECT
	city_name,
	ROUND((population * 0.25) / 1000000, 2) as coffee_consumer_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the 
-- last quarter of 2023?

SELECT
	ci.city_name,
	SUM(total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT
	p.product_name,
	COUNT(s.sale_id) as toal_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city and total sale
-- no of customers in each these city

SELECT
	ci.city_name,
	SUM(total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customer,
	ROUND(SUM(total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_percustomer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table
AS
(
	SELECT
		city_name,
		ROUND(SUM(population * 0.25) / 1000000, 2) as coffee_consumers
	FROM city
	GROUP BY 1
	ORDER BY 2 DESC
),
customer_table
AS
(
	SELECT
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cust
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
)
SELECT
	customer_table.city_name,
	city_table.coffee_consumers as coffee_consumers_in_millions,
	customer_table.unique_cust
FROM city_table
JOIN
customer_table
ON city_table.city_name = customer_table.city_name;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
(
	SELECT
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_sales,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
) as t1
WHERE
	rank <= 3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cust
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT
	ci.city_name,
	COUNT(DISTINCT s.customer_id) as total_customer,
	ci.estimated_rent,
	ROUND(SUM(total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_percustomer,
	ROUND(ci.estimated_rent::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_rent_percustomer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 3
ORDER BY 4 DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over 
-- different time periods (monthly) by each city

WITH monthly_sales
AS
(
	SELECT
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as year,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),

growth
AS
(
	SELECT
		city_name,
		month,
		year,
		total_sale as cr_month_sale,
		LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
	FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND((cr_month_sale - last_month_sale)::numeric / last_month_sale::numeric * 100, 2) 
	as growth_ratio
FROM growth
WHERE
	last_month_sale IS NOT NULL;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, 
-- total rent, total customers, estimated coffee consumer

SELECT
	ci.city_name,
	SUM(total) as total_sale,
	COUNT(DISTINCT s.customer_id) as total_customer,
	ci.estimated_rent as total_rent,
	ROUND(ci.population * 0.25 / 1000000, 2) as coffee_consumers_in_millions,
	ROUND(SUM(total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_percustomer,
	ROUND(ci.estimated_rent::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_rent_percustomer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 4, 5
ORDER BY 2 DESC
LIMIT 3;


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.

	