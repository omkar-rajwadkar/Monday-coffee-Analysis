SELECT * From city;
SELECT * From customers;
SELECT * From products;
SELECT * From sales;

                                 -- Reports and data analysis--

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
	city_name,
    round((population * 0.25)/1000000, 2) as population_in_millions,
    city_rank
FROM city
ORDER BY 2 DESC;


-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
	ci.city_name,
	sum(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE quarter(s.sale_date) = 4 AND year(s.sale_date) = 2023
GROUP BY 1
ORDER BY 2 DESC;


-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT 
	product_name,
    count(sale_id) as total_orders
FROM products as p
LEFT JOIN sales as s
ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?
SELECT 
	ci.city_name,
	sum(s.total) as total_revenue,
    count(distinct c.customer_id) as total_cx,
    round(sum(s.total)/count(distinct c.customer_id),2) as avg_sales_per_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci 
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- City Population and Coffee Consumers
-- Q.5 Provide a list of cities along with their populations and estimated coffee consumers. (Esitmated coffee consumers 25%)
WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
	customers_table ON city_table.city_name = customers_table.city_name;


-- Top Selling Products by City
-- Q.6 What are the top 3 selling products in each city based on sales volume?
SELECT * 
FROM
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as R_A_N_K
	FROM sales as s
	JOIN 
		products as p ON p.product_id = s.product_id
	JOIN 
		customers as c ON c.customer_id = s.customer_id
	JOIN
		city as ci ON ci.city_id = c.city_id
	GROUP BY 1, 2
) as t1
WHERE R_A_N_K <= 3;


-- Customer Segmentation by City
-- Q.7 How many unique customers are there in each city who have purchased coffee products?
SELECT	
	ci.city_name,
    COUNT(DISTINCT 	c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE
	s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;


-- Average Sale vs Rent
-- Q.8 Find each city and their average sale per customer and avg rent per customer
WITH city_table
AS
(
	SELECT 	
		ci.city_name,
		sum(s.total) as total_revenue,
		count(distinct s.customer_id) as total_cx,
		round(sum(s.total)/count(distinct s.customer_id), 2) as avg_sale_per_cx
	FROM sales as s
		JOIN customers as c
		ON s.customer_id = c.customer_id
		JOIN city as ci
		ON ci.city_id = c.city_id
		GROUP BY 1
		ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name,
        estimated_rent
	FROM city
)
SELECT
	cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_per_cx,
    round(cr.estimated_rent/ct.total_cx,2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;


-- Monthly Sales Growth
-- Q9 Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly). PER CITY
WITH monthly_sales
AS
(
	SELECT
		city_name,
		EXTRACT(month from s.sale_date) as month,
		EXTRACT(year from s.sale_date) as year,
		sum(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
),
growth_ratio
AS
(
	SELECT
		city_name,
		month,
        year,
        total_sale as cr_month_Sale,
        LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
	FROM monthly_sales
)
SELECT
	city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
		(cr_month_sale-last_month_sale)/last_month_sale* 100
		, 2
		) as growth_ratio
FROM growth_ratio;
-- WHERE last_month_sale IS NOT NULL	


-- Market Potential Analysis
-- Q.10 Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)/
					COUNT(DISTINCT s.customer_id)
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/
									ct.total_cx
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

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
	

    
