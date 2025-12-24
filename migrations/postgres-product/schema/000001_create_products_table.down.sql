-- Drop constraints
ALTER TABLE products DROP CONSTRAINT IF EXISTS fk_products_category;

-- Drop indexes
DROP INDEX IF EXISTS idx_products_is_active;
DROP INDEX IF EXISTS idx_products_category;
DROP INDEX IF EXISTS idx_products_sku;
DROP INDEX IF EXISTS idx_products_name;

-- Drop tables
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
