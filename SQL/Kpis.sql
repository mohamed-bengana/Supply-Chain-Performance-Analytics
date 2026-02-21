                                    ----SUPPLY CHAIN KPIs----

---Average Lead Time---
SELECT 
    AVG(lead_time_days) as avg_lead_time_days,
    MIN(lead_time_days) as min_lead_time,
    MAX(lead_time_days) as max_lead_time,
    STDEV(lead_time_days) as std_dev_lead_time
FROM fact_supply_chain_orders
WHERE lead_time_days IS NOT NULL;

-- By product category
SELECT 
    p.product_category,
    AVG(f.lead_time_days) as avg_lead_time
FROM fact_supply_chain_orders f
JOIN dim_products p ON f.product_id = p.product_id
WHERE f.lead_time_days IS NOT NULL
GROUP BY p.product_category
ORDER BY avg_lead_time DESC;

---On-Time Delivery %---
SELECT 
    COUNT(*) as total_orders,
    SUM(CASE WHEN actual_delivery_date <= expected_delivery_date THEN 1 ELSE 0 END) as on_time_deliveries,
    CAST(SUM(CASE WHEN actual_delivery_date <= expected_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as on_time_delivery_pct
FROM fact_supply_chain_orders
WHERE actual_delivery_date IS NOT NULL 
  AND expected_delivery_date IS NOT NULL;

-- Monthly trend
SELECT 
    c.year,
    c.month,
    COUNT(*) as total_orders,
    CAST(SUM(CASE WHEN f.actual_delivery_date <= f.expected_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as on_time_pct
FROM fact_supply_chain_orders f
JOIN dim_calendar c ON f.date_id = c.date_id
WHERE f.actual_delivery_date IS NOT NULL
GROUP BY c.year, c.month
ORDER BY c.year, c.month;

---Service Level %---
SELECT 
    COUNT(*) as total_orders,
    SUM(CASE WHEN service_level_flag = 'On-Time' THEN 1 ELSE 0 END) as service_level_met,
    CAST(SUM(CASE WHEN service_level_flag = 'On-Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as service_level_pct
FROM fact_supply_chain_orders;

-- By plant
SELECT 
    pl.plant_name,
    pl.region,
    CAST(SUM(CASE WHEN f.service_level_flag = 'On-Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as service_level_pct
FROM fact_supply_chain_orders f
JOIN dim_plants pl ON f.plant_id = pl.plant_id
GROUP BY pl.plant_name, pl.region
ORDER BY service_level_pct DESC;

---Order Fulfillment Rate---
SELECT 
    COUNT(*) as total_orders,
    SUM(CASE WHEN received_quantity >= order_quantity THEN 1 ELSE 0 END) as fully_fulfilled,
    CAST(SUM(CASE WHEN received_quantity >= order_quantity THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as fulfillment_rate_pct,
    AVG(CAST(received_quantity AS FLOAT) / NULLIF(order_quantity, 0) * 100) as avg_fill_rate_pct
FROM fact_supply_chain_orders
WHERE order_quantity > 0;
---Inventory Turnover ---
-- Note: This requires assumptions about inventory periods
SELECT 
    p.product_category,
    SUM(f.received_quantity) as total_units_received,
    AVG(f.order_quantity) as avg_inventory_level,
    CAST(SUM(f.received_quantity) / NULLIF(AVG(f.order_quantity), 0) AS DECIMAL(10,2)) as inventory_turnover_ratio
FROM fact_supply_chain_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_category;

---Inventory Holding Cost---
SELECT 
    SUM(inventory_holding_cost) as total_holding_cost,
    AVG(inventory_holding_cost) as avg_holding_cost_per_order,
    p.product_category,
    SUM(f.inventory_holding_cost) as category_holding_cost
FROM fact_supply_chain_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_category
ORDER BY category_holding_cost DESC;

-- By year
SELECT 
    c.year,
    SUM(f.inventory_holding_cost) as annual_holding_cost
FROM fact_supply_chain_orders f
JOIN dim_calendar c ON f.date_id = c.date_id
GROUP BY c.year
ORDER BY c.year;

---Supplier Delay Rate---
SELECT 
    COUNT(*) as total_deliveries,
    SUM(CASE WHEN actual_delivery_date > expected_delivery_date THEN 1 ELSE 0 END) as delayed_deliveries,
    CAST(SUM(CASE WHEN actual_delivery_date > expected_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as delay_rate_pct,
    AVG(CASE WHEN actual_delivery_date > expected_delivery_date 
        THEN DATEDIFF(day, expected_delivery_date, actual_delivery_date) 
        ELSE 0 END) as avg_delay_days
FROM fact_supply_chain_orders
WHERE actual_delivery_date IS NOT NULL 
  AND expected_delivery_date IS NOT NULL;


                                         ----SUPPLIER KPIs----
---Supplier Reliability %---
SELECT 
    s.supplier_id,
    s.supplier_name,
    s.supplier_rating,
    s.country,
    COUNT(*) as total_orders,
    SUM(CASE WHEN f.actual_delivery_date <= f.expected_delivery_date THEN 1 ELSE 0 END) as on_time_orders,
    CAST(SUM(CASE WHEN f.actual_delivery_date <= f.expected_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as reliability_pct
FROM fact_supply_chain_orders f
JOIN dim_suppliers s ON f.supplier_id = s.supplier_id
WHERE f.actual_delivery_date IS NOT NULL
GROUP BY s.supplier_id, s.supplier_name, s.supplier_rating, s.country
ORDER BY reliability_pct DESC;

---Average Delay per Supplier ---
SELECT 
    s.supplier_id,
    s.supplier_name,
    s.supplier_type,
    COUNT(*) as total_orders,
    SUM(CASE WHEN f.actual_delivery_date > f.expected_delivery_date THEN 1 ELSE 0 END) as delayed_orders,
    AVG(CASE WHEN f.actual_delivery_date > f.expected_delivery_date 
        THEN DATEDIFF(day, f.expected_delivery_date, f.actual_delivery_date) 
        ELSE 0 END) as avg_delay_days,
    MAX(CASE WHEN f.actual_delivery_date > f.expected_delivery_date 
        THEN DATEDIFF(day, f.expected_delivery_date, f.actual_delivery_date) 
        ELSE 0 END) as max_delay_days
FROM fact_supply_chain_orders f
JOIN dim_suppliers s ON f.supplier_id = s.supplier_id
WHERE f.actual_delivery_date IS NOT NULL
GROUP BY s.supplier_id, s.supplier_name, s.supplier_type
ORDER BY avg_delay_days DESC;

---Cost per Supplier---
SELECT 
    s.supplier_id,
    s.supplier_name,
    s.contract_type,
    COUNT(*) as total_orders,
    SUM(f.order_cost) as total_order_cost,
    SUM(f.inventory_holding_cost) as total_holding_cost,
    SUM(f.order_cost + f.inventory_holding_cost) as total_cost,
    AVG(f.order_cost) as avg_order_cost
FROM fact_supply_chain_orders f
JOIN dim_suppliers s ON f.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.supplier_name, s.contract_type
ORDER BY total_cost DESC;

                            ----PLANT KPIs----
---Stock Availability % ---
SELECT 
    pl.plant_id,
    pl.plant_name,
    pl.region,
    COUNT(*) as total_orders,
    SUM(CASE WHEN f.received_quantity >= f.order_quantity THEN 1 ELSE 0 END) as fulfilled_orders,
    CAST(SUM(CASE WHEN f.received_quantity >= f.order_quantity THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as stock_availability_pct
FROM fact_supply_chain_orders f
JOIN dim_plants pl ON f.plant_id = pl.plant_id
GROUP BY pl.plant_id, pl.plant_name, pl.region
ORDER BY stock_availability_pct DESC;

---Delay Impact on Production---
SELECT 
    pl.plant_id,
    pl.plant_name,
    pl.plant_type,
    COUNT(*) as total_orders,
    SUM(CASE WHEN f.actual_delivery_date > f.expected_delivery_date THEN 1 ELSE 0 END) as delayed_orders,
    AVG(CASE WHEN f.actual_delivery_date > f.expected_delivery_date 
        THEN DATEDIFF(day, f.expected_delivery_date, f.actual_delivery_date) 
        ELSE 0 END) as avg_delay_days,
    SUM(CASE WHEN f.actual_delivery_date > f.expected_delivery_date 
        THEN DATEDIFF(day, f.expected_delivery_date, f.actual_delivery_date) 
        ELSE 0 END) as total_delay_days
FROM fact_supply_chain_orders f
JOIN dim_plants pl ON f.plant_id = pl.plant_id
WHERE f.actual_delivery_date IS NOT NULL
GROUP BY pl.plant_id, pl.plant_name, pl.plant_type
ORDER BY total_delay_days DESC;

---Cost of Delays ---
SELECT 
    pl.plant_id,
    pl.plant_name,
    COUNT(*) as total_orders,
    SUM(CASE WHEN f.actual_delivery_date > f.expected_delivery_date 
        THEN f.order_cost + f.inventory_holding_cost 
        ELSE 0 END) as cost_of_delayed_orders,
    AVG(CASE WHEN f.actual_delivery_date > f.expected_delivery_date 
        THEN f.order_cost + f.inventory_holding_cost 
        ELSE 0 END) as avg_cost_per_delay
FROM fact_supply_chain_orders f
JOIN dim_plants pl ON f.plant_id = pl.plant_id
WHERE f.actual_delivery_date IS NOT NULL
GROUP BY pl.plant_id, pl.plant_name
ORDER BY cost_of_delayed_orders DESC;
