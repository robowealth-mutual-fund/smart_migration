-- Drop products table
DROP INDEX IF EXISTS idx_products_created_at;
DROP INDEX IF EXISTS idx_products_metadata;
DROP INDEX IF EXISTS idx_products_is_active;
DROP INDEX IF EXISTS idx_products_brand;
DROP INDEX IF EXISTS idx_products_category;
DROP INDEX IF EXISTS idx_products_name;
DROP INDEX IF EXISTS idx_products_sku;
DROP TABLE IF EXISTS products;