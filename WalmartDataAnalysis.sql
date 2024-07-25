-- Create database
CREATE DATABASE IF NOT EXISTS walmartSales;

-- Create table
CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    `date` DATETIME NOT NULL,
    `time` TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);

SELECT * FROM sales;

-- Feature Engineering:------------------------------------------------------------------------------
-- Add a new column named time_of_day----------------------------------------------------------------
WITH CATEGORY AS(
SELECT `TIME`, CASE 
WHEN `TIME` BETWEEN "6:00:00" AND "11:59:00" THEN "Morning"
WHEN `TIME` BETWEEN  "12:00:00" AND "17:59:00" THEN "Afternoon"
WHEN `TIME` BETWEEN  "18:00:00" AND "22:59:00" THEN "Evening"
WHEN `TIME` BETWEEN  "23:00:00" AND "5:59:00" THEN "Night"
END AS time_of_day 
FROM SALES)
SELECT COUNT(`TIME`), COUNT(time_of_day) FROM CATEGORY
;

ALTER TABLE sales
ADD time_of_day varchar(50);


SET SQL_SAFE_UPDATES = 0;

UPDATE SALES
SET time_of_day=(
CASE 
WHEN `TIME` BETWEEN "6:00:00" AND "11:59:00" THEN "Morning"
WHEN `TIME` BETWEEN  "12:00:00" AND "17:59:00" THEN "Afternoon"
WHEN `TIME` BETWEEN  "18:00:00" AND "22:59:00" THEN "Evening"
WHEN `TIME` BETWEEN  "23:00:00" AND "5:59:00" THEN "Night"
END);
SELECT * FROM sales;


-- Add a new column named day_name----------------------------------------------------------------
SELECT `DATE` ,dayofweek(`DATE`),
CASE
WHEN dayofweek(`DATE`)=1 THEN "Sunday"
WHEN dayofweek(`DATE`)=2 THEN "Monday"
WHEN dayofweek(`DATE`)=3 THEN "Tuesday"
WHEN dayofweek(`DATE`)=4 THEN "Wednesday"
WHEN dayofweek(`DATE`)=5 THEN "Thursday"
WHEN dayofweek(`DATE`)=6 THEN "Friday"
WHEN dayofweek(`DATE`)=7 THEN "Saturday"
END as `Day`
FROM SALES;

ALTER TABLE SALES
ADD day_name VARCHAR(50);

UPDATE SALES
SET day_name=(
CASE
WHEN dayofweek(`DATE`)=1 THEN "Sunday"
WHEN dayofweek(`DATE`)=2 THEN "Monday"
WHEN dayofweek(`DATE`)=3 THEN "Tuesday"
WHEN dayofweek(`DATE`)=4 THEN "Wednesday"
WHEN dayofweek(`DATE`)=5 THEN "Thursday"
WHEN dayofweek(`DATE`)=6 THEN "Friday"
WHEN dayofweek(`DATE`)=7 THEN "Saturday"
END);

SELECT * FROM SALES;

-- Add a new column named month_name---------------------------------------------------------------

SELECT `DATE`, MONTHNAME(`DATE`) FROM SALES;

ALTER TABLE SALES
ADD month_name VARCHAR(50);

UPDATE sales
SET month_name=(
monthname(`DATE`)
);
SELECT * FROM SALES;

-- Generic Question-----------------------------------------------------------------------------
-- 1. How many unique cities does the data have?------------------------------------------------

SELECT DISTINCT CITY FROM SALES;

-- 2.In which city is each branch?--------------------------------------------------------------

SELECT DISTINCT BRANCH, CITY FROM SALES
ORDER BY BRANCH;

-- Product--------------------------------------------------------------------------------------
-- 1.How many unique product lines does the data have?------------------------------------------

SELECT COUNT(DISTINCT PRODUCT_LINE) FROM SALES;

-- 2.What is the most common payment method?----------------------------------------------------

SELECT DISTINCT PAYMENT ,COUNT(PAYMENT) OVER(PARTITION BY PAYMENT) COMMON FROM SALES
ORDER BY COMMON DESC
LIMIT 1;

-- 3.What is the most selling product line?------------------------------------------------------

SELECT DISTINCT PRODUCT_LINE,COUNT(PRODUCT_LINE) OVER(PARTITION BY PRODUCT_LINE) AS MOST_SELLING FROM SALES
ORDER BY MOST_SELLING DESC
LIMIT 1;

-- 4.What is the total revenue by month?------------------------------------------------------------
SELECT MONTH_NAME,SUM(TOTAL) FROM SALES
GROUP BY MONTH_NAME
LIMIT 1; 

-- 5.What month had the largest COGS?-----------------------------------------------------------------------

SELECT month_name, SUM(COGS) FROM SALES
GROUP BY MONTH_NAME
ORDER BY SUM(COGS) DESC
LIMIT 1;

-- 6.What product line had the largest revenue?---------------------------------------------------------

SELECT PRODUCT_LINE, SUM(TOTAL) FROM SALES
GROUP BY PRODUCT_LINE
ORDER BY SUM(TOTAL)
LIMIT 1;

-- 7.What is the city with the largest revenue?---------------------------------------------------------------

SELECT CITY, AVG(TOTAL) FROM SALES
GROUP BY CITY
ORDER BY SUM(TOTAL)
LIMIT 1;
	
-- 8.What product line had the largest VAT?-----------------------------------------------------------------------

SELECT PRODUCT_LINE, AVG(COGS*0.05) AS VAT FROM SALES
GROUP BY PRODUCT_LINE
ORDER BY VAT
LIMIT 1;

-- 9. Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
WITH PRODUCT AS (
SELECT PRODUCT_LINE, SUM(QUANTITY) AS AVGPRODUCT FROM SALES
GROUP BY PRODUCT_LINE
)
SELECT PRODUCT_LINE, 
CASE 
WHEN AVGPRODUCT>(SELECT AVG(QUANTITY) FROM SALES) THEN "GOOD"
ELSE "BAD"
END AS Remarks
FROM PRODUCT;

-- 10. Which branch sold more products than average product sold?-------------------------------------------
WITH PRODUCT AS (
SELECT BRANCH, SUM(QUANTITY) AS AVGPRODUCT FROM SALES
GROUP BY BRANCH
)
SELECT BRANCH, AVGPRODUCT FROM PRODUCT
WHERE AVGPRODUCT>(SELECT AVG(QUANTITY) FROM SALES);

-- 11. What is the most common product line by gender?----------------------------------------------------------
SELECT "MALE" AS GENDER,PRODUCT_LINE AS COMMON_PRODUCT_LINE,COUNT(PRODUCT_LINE) AS PRODUCTCOUNT FROM SALES
WHERE GENDER="MALE"
GROUP BY PRODUCT_LINE
ORDER BY PRODUCTCOUNT DESC
LIMIT 1;
SELECT "FEMALE" AS GENDER, PRODUCT_LINE AS COMMON_PRODUCT_LINE,COUNT(PRODUCT_LINE) AS PRODUCTCOUNT FROM SALES
WHERE GENDER="FEMALE"
GROUP BY PRODUCT_LINE
ORDER BY PRODUCTCOUNT DESC
LIMIT 1;

-- 12. What is the average rating of each product line?-------------------------------------------------------------
SELECT PRODUCT_LINE, ROUND(AVG(RATING),2) FROM SALES
GROUP BY PRODUCT_LINE;

-- Sales--------------------------------------------------------------------------------------------------------------
-- 1. Number of sales made in each time of the day per weekday-----------------------------------------------------------
SELECT DAY_NAME, SUM(QUANTITY) AS SALES_PER_DAY FROM SALES
GROUP BY DAY_NAME
ORDER BY SALES_PER_DAY;

-- 2. Which of the customer types brings the most revenue?-------------------------------------------------------------
SELECT CUSTOMER_TYPE, SUM(TOTAL) AS TOTALREVENUE FROM SALES
GROUP BY CUSTOMER_TYPE
ORDER BY TOTALREVENUE DESC;

-- 3. Which city has the largest tax percent/ VAT?----------------------------------------------------------------------

SELECT CITY, ROUND(MAX(TAX_PCT),2) AS MAX_VAT FROM SALES
GROUP BY CITY
ORDER BY MAX_VAT DESC;

-- 4. Which customer type pays the most in VAT?--------------------------------------------------------------------------

SELECT CUSTOMER_TYPE, ROUND(SUM(TAX_PCT),2) AS TAX_PAID FROM SALES
GROUP BY CUSTOMER_TYPE
ORDER BY TAX_PAID DESC;

-- Customer-------------------------------------------------------------------------------------------------------------------
-- 1. How many unique customer types does the data have?----------------------------------------------------------------------

SELECT DISTINCT CUSTOMER_TYPE FROM SALES;

-- 2. How many unique payment methods does the data have?---------------------------------------------------------------------

SELECT DISTINCT PAYMENT FROM SALES;

-- 3. What is the most common customer type?-----------------------------------------------------------------------------------

WITH CUSTOMERCOUNT AS(
SELECT DISTINCT CUSTOMER_TYPE,  COUNT(CUSTOMER_TYPE) AS COUNTOFCUS FROM SALES
GROUP BY CUSTOMER_TYPE
)
SELECT * FROM CUSTOMERCOUNT
ORDER BY COUNTOFCUS DESC
LIMIT 1;

-- 4. Which customer type buys the most?-----------------------------------------------------------------------------------------

SELECT CUSTOMER_TYPE,SUM(QUANTITY) AS PRODUCTBUY FROM SALES
GROUP BY CUSTOMER_TYPE
ORDER BY PRODUCTBUY DESC
LIMIT 1;
 
-- 5. What is the gender of most of the customers?--------------------------------------------------------------------------------

SELECT GENDER, COUNT(GENDER) COUNTCUSTOMER FROM SALES
GROUP BY GENDER
ORDER BY COUNTCUSTOMER DESC
LIMIT 1;

-- 6. What is the gender distribution per branch?---------------------------------------------------------------------------------
SELECT BRANCH, GENDER,COUNT(GENDER) FROM SALES
GROUP BY BRANCH, GENDER
ORDER BY BRANCH;

-- 7. Which time of the day do customers give most ratings?-------------------------------------------------------------------------

SELECT TIME_OF_DAY, ROUND(AVG(RATING),2) AS AVERGAE_RATING FROM SALES
GROUP BY TIME_OF_DAY
ORDER BY AVERGAE_RATING DESC
LIMIT 1;

-- 8. Which time of the day do customers give most ratings per branch?---------------------------------------

SELECT BRANCH,TIME_OF_DAY, ROUND(AVG(RATING),2) AS AVERGAE_RATING FROM SALES
GROUP BY BRANCH,TIME_OF_DAY
ORDER BY BRANCH;

-- Which day fo the week has the best avg ratings?---------------------------------------------------------

SELECT DAY_NAME, ROUND(AVG(RATING),2) AS AVERGAE_RATING FROM SALES
GROUP BY DAY_NAME
ORDER BY AVERGAE_RATING DESC;

-- 10. Which day of the week has the best average ratings per branch?-------------------------------------------------

SELECT BRANCH,DAY_NAME, ROUND(AVG(RATING),2) AS AVERGAE_RATING FROM SALES
GROUP BY BRANCH,DAY_NAME
ORDER BY BRANCH;

SHOW VARIABLES LIKE "secure_file_priv";
SELECT * FROM SALES INTO OUTFILE "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\filename.csv";






		