-- Check missing critical fields in fact table
SELECT 
    COUNT(*) as total_records,
    COUNT(order_id) as orders_with_id,
    COUNT(product_id) as orders_with_product,
    COUNT(supplier_id) as orders_with_supplier,
    COUNT(plant_id) as orders_with_plant,
    COUNT(order_date) as orders_with_date,
    COUNT(actual_delivery_date) as orders_with_delivery
FROM fact_supply_chain_orders;

-- Identify records with NULL delivery dates
SELECT order_id, order_date, expected_delivery_date, actual_delivery_date
FROM fact_supply_chain_orders
WHERE actual_delivery_date IS NULL;

-- Find duplicate orders
SELECT order_id, COUNT(*) as duplicate_count
FROM fact_supply_chain_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check for negative or zero quantities
SELECT order_id, order_quantity, received_quantity
FROM fact_supply_chain_orders
WHERE order_quantity <= 0 OR received_quantity < 0;

-- Check for illogical dates (delivery before order)
SELECT order_id, order_date, actual_delivery_date
FROM fact_supply_chain_orders
WHERE actual_delivery_date < order_date;

-- Verify foreign key relationships
SELECT COUNT(*) as orphan_products
FROM fact_supply_chain_orders f
LEFT JOIN dim_products p ON f.product_id = p.product_id
WHERE p.product_id IS NULL;