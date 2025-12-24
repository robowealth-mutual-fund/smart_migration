-- Insert categories
INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Electronic devices and gadgets'),
    ('Clothing', 'Apparel and fashion items'),
    ('Books', 'Books and publications'),
    ('Home & Garden', 'Home improvement and garden supplies')
ON CONFLICT (name) DO NOTHING;

-- Insert products
INSERT INTO products (name, description, price, stock_quantity, sku, category) VALUES
    ('Laptop Pro 15', 'High-performance laptop with 16GB RAM', 1299.99, 50, 'LAP-001', 'Electronics'),
    ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 200, 'MOU-001', 'Electronics'),
    ('T-Shirt Blue', 'Cotton t-shirt in blue', 19.99, 100, 'TSH-001', 'Clothing'),
    ('Programming Book', 'Learn Go programming', 49.99, 75, 'BOK-001', 'Books'),
    ('Garden Tools Set', 'Complete garden tools set', 89.99, 30, 'GRD-001', 'Home & Garden')
ON CONFLICT (sku) DO NOTHING;
