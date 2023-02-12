CREATE TABLE sales 
(
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
)

INSERT INTO sales ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INT,
  product_name VARCHAR(5),
  price INT
)

INSERT INTO menu ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12')
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
)

INSERT INTO members ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09')

--What is the total amount each customer spent at the restaurant?
WITH table1 AS (
SELECT [dbo].[sales].customer_id,[dbo].[menu].price
FROM [dbo].[sales]
JOIN [dbo].[menu]
ON [dbo].[sales].product_id=[dbo].[menu].product_id)
SELECT customer_id,SUM(price) AS total
FROM table1
GROUP BY customer_id

--How many days has each customer visited the restaurant?
SELECT customer_id,COUNT (DISTINCT(order_date)) AS visit_days
FROM [dbo].[sales]
GROUP BY customer_id

--What was the first item from the menu purchased by each customer?
WITH table2 AS (
SELECT [dbo].[sales].customer_id,[dbo].[sales].order_date,[dbo].[menu].product_name,
DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY order_date) AS ranking
FROM [dbo].[menu]
JOIN [dbo].[sales]
ON [dbo].[sales].product_id=[dbo].[menu].product_id
GROUP BY [dbo].[sales].customer_id,[dbo].[sales].order_date,[dbo].[menu].product_name)
SELECT customer_id,product_name
FROM table2
WHERE ranking=1 

--What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH table3 AS (
SELECT [dbo].[sales].order_date,[dbo].[menu].product_name
FROM [dbo].[sales]
JOIN [dbo].[menu]
ON [dbo].[sales].product_id=[dbo].[menu].product_id)
SELECT TOP 1 product_name, COUNT(product_name) AS order_count
FROM table3
GROUP BY product_name
ORDER BY COUNT(product_name) DESC

--Which item was the most popular for each customer?
WITH table4 AS (
SELECT [dbo].[sales].customer_id,[dbo].[menu].product_name,
DENSE_rank () OVER (PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) AS ranking
FROM [dbo].[sales]
JOIN [dbo].[menu]
ON [dbo].[sales].product_id=[dbo].[menu].product_id
GROUP BY [dbo].[sales].customer_id,[dbo].[menu].product_name)
SELECT customer_id,product_name
FROM table4
WHERE ranking=1
GROUP BY customer_id,product_name

--Which item was purchased first by the customer after they became a member?
WITH table4 AS (
SELECT [dbo].[sales].customer_id,[dbo].[menu].product_name,[dbo].[sales].order_date,[dbo].[members].join_date,
DENSE_rank () OVER (PARTITION BY [dbo].[sales].customer_id ORDER BY [dbo].[sales].order_date) AS ranking
FROM [dbo].[sales]
JOIN [dbo].[menu]
ON [dbo].[sales].product_id=[dbo].[menu].product_id
JOIN [dbo].[members]
ON [dbo].[members].customer_id=[dbo].[sales].customer_id
WHERE [dbo].[sales].order_date>=[dbo].[members].join_date)
SELECT customer_id,product_name
FROM table4
WHERE ranking=1 

--Which item was purchased just before the customer became a member?
WITH table4 AS (
SELECT [dbo].[sales].customer_id,[dbo].[menu].product_name,[dbo].[sales].order_date,[dbo].[members].join_date,
DENSE_rank () OVER (PARTITION BY [dbo].[sales].customer_id ORDER BY [dbo].[sales].order_date DESC) AS ranking
FROM [dbo].[sales]
JOIN [dbo].[menu]
ON [dbo].[sales].product_id=[dbo].[menu].product_id
JOIN [dbo].[members]
ON [dbo].[members].customer_id=[dbo].[sales].customer_id
WHERE [dbo].[sales].order_date<[dbo].[members].join_date)
SELECT customer_id,product_name
FROM table4
WHERE ranking=1 

--What is the total items and amount spent for each member before they became a member?
WITH table4 AS (
SELECT [dbo].[sales].customer_id,[dbo].[menu].product_name,[dbo].[menu].price,[dbo].[sales].order_date,[dbo].[members].join_date
FROM [dbo].[sales]
JOIN [dbo].[menu]
ON [dbo].[sales].product_id=[dbo].[menu].product_id
JOIN [dbo].[members]
ON [dbo].[sales].customer_id=[dbo].[members].customer_id)
SELECT customer_id, COUNT(product_name) AS quantity,SUM(price) AS total_price
FROM table4
WHERE order_date<join_date
GROUP BY customer_id

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH table4 AS (
SELECT *,
CASE WHEN  product_id=1 THEN price*20
ELSE price*10
END AS points
FROM [dbo].[menu])
SELECT customer_id,SUM(points) AS total_points 
FROM [dbo].[sales]
JOIN table4
ON table4.product_id=[dbo].[sales].product_id
GROUP BY customer_id

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH table4 AS(
SELECT *, DATEADD(DAY,7,join_date) AS dates,
		  EOMONTH('2021-01-31') AS last_day
FROM [dbo].[members])
SELECT [dbo].[sales].customer_id,SUM(
CASE WHEN [dbo].[menu].product_id=1 AND 2 AND 3 THEN [dbo].[menu].price*20
	 WHEN [dbo].[sales].order_date BETWEEN [dbo].[members].join_date AND [dbo].[members].dates THEN [dbo].[menu].price*20
ELSE [dbo].[menu].price*10
END) AS total_points
FROM [dbo].[menu]
JOIN [dbo].[sales]
ON [dbo].[menu].product_id=[dbo].[sales].product_id
JOIN table4
ON [dbo].[sales].customer_id=table4.customer_id)
WHERE order_date
GROUP BY customer_id
