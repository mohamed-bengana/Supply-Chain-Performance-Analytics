                              ----COMPREHENSIVE DASHBOARD QUERY----

-- Combined KPI summary for executive dashboard
SELECT 
    'Overall Metrics' as metric_category,
    COUNT(*) as total_orders,
    CAST(AVG(f.lead_time_days) AS DECIMAL(10,2)) as avg_lead_time,
    CAST(SUM(CASE WHEN f.actual_delivery_date <= f.expected_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as on_time_delivery_pct,
    CAST(SUM(CASE WHEN f.service_level_flag = 'On-Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as service_level_pct,
    CAST(SUM(CASE WHEN f.received_quantity >= f.order_quantity THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as fulfillment_rate_pct,
    SUM(f.order_cost) as total_order_cost,
    SUM(f.inventory_holding_cost) as total_holding_cost
FROM fact_supply_chain_orders f
WHERE f.actual_delivery_date IS NOT NULL;