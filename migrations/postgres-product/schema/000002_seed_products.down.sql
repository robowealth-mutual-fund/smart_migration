-- Remove seeded products
DELETE FROM products WHERE sku IN ('LAP-001', 'MOU-001', 'TSH-001', 'BOK-001', 'GRD-001');

-- Remove seeded categories
DELETE FROM categories WHERE name IN ('Electronics', 'Clothing', 'Books', 'Home & Garden');
