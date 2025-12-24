-- Remove order items
DELETE FROM order_items WHERE order_id IN (
    SELECT id FROM orders WHERE order_number IN ('ORD-2024-001', 'ORD-2024-002', 'ORD-2024-003')
);

-- Remove orders
DELETE FROM orders WHERE order_number IN ('ORD-2024-001', 'ORD-2024-002', 'ORD-2024-003');
