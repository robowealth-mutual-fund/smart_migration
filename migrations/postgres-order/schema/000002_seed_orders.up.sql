-- Insert sample orders
INSERT INTO orders (user_id, order_number, status, total_amount, payment_method, payment_status, shipping_address) VALUES
    (1, 'ORD-2024-001', 'completed', 1329.98, 'credit_card', 'paid', '123 Main St, San Francisco, CA 94102'),
    (2, 'ORD-2024-002', 'pending', 29.99, 'paypal', 'pending', '456 Oak Ave, New York, NY 10001'),
    (2, 'ORD-2024-003', 'shipped', 49.99, 'credit_card', 'paid', '456 Oak Ave, New York, NY 10001')
ON CONFLICT (order_number) DO NOTHING;

-- Insert order items
INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price)
SELECT o.id, 1, 'Laptop Pro 15', 1, 1299.99, 1299.99
FROM orders o WHERE o.order_number = 'ORD-2024-001';

INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price)
SELECT o.id, 2, 'Wireless Mouse', 1, 29.99, 29.99
FROM orders o WHERE o.order_number = 'ORD-2024-001';

INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price)
SELECT o.id, 2, 'Wireless Mouse', 1, 29.99, 29.99
FROM orders o WHERE o.order_number = 'ORD-2024-002';

INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price)
SELECT o.id, 4, 'Programming Book', 1, 49.99, 49.99
FROM orders o WHERE o.order_number = 'ORD-2024-003';
