# Migration Files

โฟลเดอร์นี้เก็บ migration files สำหรับ PostgreSQL และ MongoDB

## โครงสร้าง

```
migrations/
├── postgres/
│   ├── schema/      # Schema migrations (CREATE TABLE, ALTER TABLE, etc.)
│   └── seed/        # Seed data migrations (INSERT data)
└── mongo/
    ├── schema/      # Schema migrations (collections, indexes, validators)
    └── seed/        # Seed data migrations (initial documents)
```

## Naming Convention

### Format

```
NNNNNN_description_of_change.{up|down}.{sql|js}
```

- `NNNNNN`: เลขลำดับ 6 หลัก (000001, 000002, ...)
- `description`: คำอธิบายสั้นๆ ใช้ underscore คั่น
- `.up`: สำหรับ apply migration
- `.down`: สำหรับ rollback migration
- `.sql`: สำหรับ PostgreSQL
- `.js`: สำหรับ MongoDB

### ตัวอย่าง

PostgreSQL:
```
000001_create_users_table.up.sql
000001_create_users_table.down.sql
000002_add_email_index.up.sql
000002_add_email_index.down.sql
```

MongoDB:
```
000001_create_products_collection.up.js
000001_create_products_collection.down.js
000002_add_category_index.up.js
000002_add_category_index.down.js
```

## การเขียน Migration

### PostgreSQL Schema Migration

**Up Migration** (`000001_create_users_table.up.sql`):
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
```

**Down Migration** (`000001_create_users_table.down.sql`):
```sql
DROP INDEX IF EXISTS idx_users_username;
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;
```

### PostgreSQL Seed Migration

**Up Migration** (`000001_seed_users.up.sql`):
```sql
INSERT INTO users (username, email, full_name) 
VALUES 
    ('admin', 'admin@example.com', 'Admin User'),
    ('test_user', 'test@example.com', 'Test User')
ON CONFLICT (username) DO NOTHING;
```

**Down Migration** (`000001_seed_users.down.sql`):
```sql
DELETE FROM users WHERE username IN ('admin', 'test_user');
```

### MongoDB Schema Migration

**Up Migration** (`000001_create_products_collection.up.js`):
```javascript
// Create collection with schema validation
db.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "price", "createdAt"],
      properties: {
        name: {
          bsonType: "string",
          description: "Product name is required"
        },
        price: {
          bsonType: "number",
          minimum: 0,
          description: "Price must be positive"
        },
        category: {
          bsonType: "string"
        },
        inStock: {
          bsonType: "bool"
        },
        createdAt: {
          bsonType: "date"
        }
      }
    }
  }
});

// Create indexes
db.products.createIndex({ name: 1 }, { unique: true });
db.products.createIndex({ category: 1 });
db.products.createIndex({ price: 1 });
```

**Down Migration** (`000001_create_products_collection.down.js`):
```javascript
db.products.drop();
```

### MongoDB Seed Migration

**Up Migration** (`000001_seed_products.up.js`):
```javascript
db.products.insertMany([
  {
    name: "Product 1",
    price: 99.99,
    category: "Electronics",
    inStock: true,
    createdAt: new Date()
  },
  {
    name: "Product 2",
    price: 149.99,
    category: "Books",
    inStock: true,
    createdAt: new Date()
  }
]);
```

**Down Migration** (`000001_seed_products.down.js`):
```javascript
db.products.deleteMany({
  name: { $in: ["Product 1", "Product 2"] }
});
```

## Best Practices

### 1. แยก Schema และ Seed
- **Schema**: โครงสร้างฐานข้อมูล (tables, collections, indexes)
- **Seed**: ข้อมูลเริ่มต้น (sample data, initial configuration)

### 2. Idempotent Migrations
Migration ควรรันได้หลายครั้งโดยไม่เกิดข้อผิดพลาด:

```sql
-- Good
CREATE TABLE IF NOT EXISTS users (...);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Bad
CREATE TABLE users (...);  -- จะ error ถ้าตารางมีอยู่แล้ว
```

### 3. ใช้ Transactions (PostgreSQL)
```sql
BEGIN;

-- Your migration code here
CREATE TABLE ...;
ALTER TABLE ...;

COMMIT;
```

### 4. Reversible Migrations
เสมอต้องมี `.down` migration สำหรับ rollback:

```sql
-- Up: Add column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Down: Remove column
ALTER TABLE users DROP COLUMN phone;
```

### 5. ตรวจสอบก่อน Apply
```bash
# ดู migration files
ls -la migrations/postgres/schema/

# Test locally ก่อน
make run-postgres-schema

# ทดสอบ rollback
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=1
```

### 6. ใช้ Comments
```sql
-- Create users table for authentication
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    -- Username for login
    username VARCHAR(255) NOT NULL UNIQUE,
    -- Email for notifications
    email VARCHAR(255) NOT NULL UNIQUE
);
```

### 7. Version Control
- Commit migration files พร้อมกับ code changes
- ห้ามแก้ไข migration ที่ apply ไปแล้ว
- สร้าง migration ใหม่แทนการแก้ไขของเก่า

## การ Test Migration

### Local Testing

```bash
# 1. Set environment variables
export POSTGRES_DSN="postgres://user:password@localhost:5432/testdb"
export MONGO_URI="mongodb://localhost:27017/testdb"

# 2. รัน schema migration
make run-postgres-schema
make run-mongo-schema

# 3. ตรวจสอบ database
psql "$POSTGRES_DSN" -c "\dt"  # List tables
mongosh "$MONGO_URI" --eval "db.getCollectionNames()"

# 4. รัน seed migration
make run-postgres-seed
make run-mongo-seed

# 5. ทดสอบ rollback
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=1
```

### Docker Testing

```bash
# Build image
make docker-build

# Run migration
docker run --rm \
  -e POSTGRES_DSN="postgres://..." \
  -e MONGO_URI="mongodb://..." \
  your-registry/fundii-database-migration:latest \
  -db=all -type=schema -verbose=true
```

## Common Patterns

### Adding a New Table

```sql
-- 000003_create_orders_table.up.sql
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

```sql
-- 000003_create_orders_table.down.sql
DROP TABLE IF EXISTS orders;
```

### Modifying Existing Table

```sql
-- 000004_add_phone_to_users.up.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
```

```sql
-- 000004_add_phone_to_users.down.sql
DROP INDEX IF EXISTS idx_users_phone;
ALTER TABLE users DROP COLUMN IF EXISTS phone;
```

### MongoDB Collection Modification

```javascript
// 000003_update_products_schema.up.js
db.runCommand({
  collMod: "products",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "price", "sku", "createdAt"],
      properties: {
        name: { bsonType: "string" },
        price: { bsonType: "number", minimum: 0 },
        sku: { bsonType: "string" },  // New required field
        category: { bsonType: "string" },
        inStock: { bsonType: "bool" },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

db.products.createIndex({ sku: 1 }, { unique: true });
```

## Troubleshooting

### Migration ล้มเหลว

1. ดู error logs:
```bash
kubectl logs -l app=db-migration --tail=100
```

2. ตรวจสอบ database connection:
```bash
psql "$POSTGRES_DSN" -c "SELECT 1;"
```

3. ตรวจสอบว่า migration file มีอยู่:
```bash
ls -la migrations/postgres/schema/
```

### Rollback Migration

```bash
# Rollback 1 step
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=1

# Rollback all
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=0
```

### ตรวจสอบ Migration Version

```bash
go run ./cmd/main.go -db=postgres -action=version
```

## References

- [golang-migrate Documentation](https://github.com/golang-migrate/migrate)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
