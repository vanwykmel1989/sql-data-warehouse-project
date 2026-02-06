/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

CREATE OR ALTER VIEW gold.dim_customers
AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.[cst_id] AS customer_id,
	ci.[cst_key] AS customer_number,
	ci.[cst_firstname] AS first_name,
	ci.[cst_lastname] AS last_name,
	loc.[cntry] AS country,
	ci.[cst_marital_status] AS marital_status,
	CASE 
		WHEN ci.[cst_gndr] = 'n/a' THEN ISNULL(az12.gen, 'n/a')
		ELSE ci.[cst_gndr]
	END	AS gender,
	az12.[bdate] AS birth_date,
	ci.[cst_create_date] AS create_date
FROM 
	[silver].[crm_cust_info] AS ci LEFT JOIN
	[silver].[erp_cust_az12] AS az12 ON ci.cst_key = az12.cid LEFT JOIN
	[silver].[erp_loc_a101] AS loc ON loc.cid = ci.cst_key;
GO

CREATE OR ALTER VIEW gold.dim_products
AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY pdi.[prd_start_dt], prd_id) AS product_key,
	pdi.[prd_id] AS product_id,
	pdi.[prd_key] AS product_number,
	pdi.[prd_nm] AS product_name,
	pdi.[cat_id] AS category_id,
	pc.cat AS category,
	pc.subcat AS sub_category,
	pc.maintenance AS maintenance,
	pdi.[prd_cost] AS cost,
	pdi.[prd_line] AS product_line,
	pdi.[prd_start_dt] AS start_date,
	pdi.[dwh_create_date] AS create_date
FROM 
	[silver].[crm_prd_info] AS pdi LEFT JOIN
	[silver].[erp_px_cat_g1v2] AS pc ON pdi.cat_id = pc.id 
WHERE
	prd_end_dt IS NULL

GO

CREATE OR ALTER VIEW gold.fact_sales 
AS
SELECT 
	[sls_ord_num] AS order_number,
	p.product_key AS product_key,
	c.customer_key AS customer_key,
	[sls_order_dt] AS order_date,
	[sls_ship_dt] AS shipping_date,
	[sls_due_dt] AS due_date,
	[sls_sales] AS sales_amount,
	[sls_quantity] AS quantity,
	[sls_price] AS price,
	[dwh_create_date] AS create_date
FROM 
	[silver].[crm_sales_details] AS s LEFT JOIN
	gold.dim_customers AS c ON c.customer_id = s.sls_cust_id LEFT JOIN
	gold.dim_products AS p ON p.product_number = s.sls_prd_key;


