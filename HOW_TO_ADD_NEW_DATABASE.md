# วิธีการเพิ่ม Database ใหม่

คู่มือนี้อธิบายทีละขั้นตอนว่าจะเพิ่ม database ใหม่อย่างไร พร้อมตัวอย่างทั้ง PostgreSQL และ MongoDB

## 📋 ภาพรวม

ปัจจุบันระบบรองรับ:

### PostgreSQL Databases
- `product` - สินค้าและหมวดหมู่
- `user` - ผู้ใช้และโปรไฟล์
- `order` - คำสั่งซื้อและรายการสินค้า

### MongoDB Databases
- `product` - Product catalog พร้อม inventory
- `analytics` - Analytics และ page views

---

## 🆕 เพิ่ม PostgreSQL Database ใหม่

สมมติเราต้องการเพิ่ม database **`inventory`** สำหรับจัดการสต็อก

### ขั้นตอนที่ 1: สร้างโครงสร้าง Directory

```bash
mkdir -p migrations/postgres-inventory/schema
```

### ขั้นตอนที่ 2: สร้าง Migration Files

#### 2.1 สร้าง Schema Migration (up)

`migrations/postgres-inventory/schema/000001_create_inventory_tables.up.sql`
```sql
-- Create warehouses table
CREATE TABLE IF NOT EXISTS warehouses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    location VARCHAR(500),
    capacity INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create inventory table
CREATE TABLE IF NOT EXISTS inventory (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(warehouse_id, product_id)
);

-- Create indexes
CREATE INDEX idx_inventory_warehouse_id ON inventory(warehouse_id);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);
```

#### 2.2 สร้าง Schema Migration (down)

`migrations/postgres-inventory/schema/000001_create_inventory_tables.down.sql`
```sql
-- Drop indexes
DROP INDEX IF EXISTS idx_inventory_product_id;
DROP INDEX IF EXISTS idx_inventory_warehouse_id;

-- Drop tables
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS warehouses;
```

#### 2.3 สร้าง Seed Migration (up)

`migrations/postgres-inventory/schema/000002_seed_inventory.up.sql`
```sql
-- Insert warehouses
INSERT INTO warehouses (name, location, capacity) VALUES
    ('Main Warehouse', 'Bangkok, Thailand', 10000),
    ('North Warehouse', 'Chiang Mai, Thailand', 5000),
    ('South Warehouse', 'Phuket, Thailand', 3000)
ON CONFLICT (name) DO NOTHING;

-- Insert inventory
INSERT INTO inventory (warehouse_id, product_id, quantity, reserved_quantity)
SELECT w.id, 1, 100, 10 FROM warehouses w WHERE w.name = 'Main Warehouse'
ON CONFLICT (warehouse_id, product_id) DO NOTHING;
```

#### 2.4 สร้าง Seed Migration (down)

`migrations/postgres-inventory/schema/000002_seed_inventory.down.sql`
```sql
-- Remove inventory
DELETE FROM inventory WHERE warehouse_id IN (
    SELECT id FROM warehouses WHERE name IN ('Main Warehouse', 'North Warehouse', 'South Warehouse')
);

-- Remove warehouses
DELETE FROM warehouses WHERE name IN ('Main Warehouse', 'North Warehouse', 'South Warehouse');
```

### ขั้นตอนที่ 3: สร้าง Database

```bash
# เชื่อมต่อ PostgreSQL และสร้าง database
psql -h localhost -U user postgres -c "CREATE DATABASE inventory;"

# หรือใช้ Docker
docker exec postgres-container psql -U user postgres -c "CREATE DATABASE inventory;"
```

### ขั้นตอนที่ 4: เพิ่มใน Script

แก้ไขไฟล์ `migrate-all-databases.sh`:

```bash
# เพิ่มก่อน echo "🎉 All databases migrated successfully!"

# Migrate PostgreSQL Inventory Database
echo -e "${BLUE}📦 Migrating PostgreSQL Inventory Database...${NC}"
POSTGRES_DSN="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/inventory?sslmode=disable" \
  ./migrator -db=postgres -type=schema -verbose=true
echo -e "${GREEN}✅ PostgreSQL Inventory Database migrated${NC}"
echo ""
```

### ขั้นตอนที่ 5: เพิ่มใน Makefile

แก้ไขไฟล์ `Makefile`:

```makefile
migrate-inventory-db: ## Migrate inventory database only
	@echo "📦 Migrating Inventory Database..."
	@POSTGRES_DSN="postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/inventory?sslmode=disable" \
		go run ./cmd/main.go -db=postgres -type=schema -verbose=true
```

### ขั้นตอนที่ 6: เพิ่มใน Docker Compose

แก้ไขไฟล์ `docker-compose.multi-db.yml`:

```yaml
# เพิ่ม service ใหม่
migrate-inventory:
  build: .
  depends_on:
    postgres:
      condition: service_healthy
    migrate-order:  # รันหลังจาก order database
      condition: service_completed_successfully
  environment:
    POSTGRES_DSN: "postgres://user:password@postgres:5432/inventory?sslmode=disable"
  command: ["-db=postgres", "-type=schema", "-action=up", "-verbose=true"]
```

และเพิ่มใน `init-databases.sql`:

```sql
CREATE DATABASE inventory;
```

### ขั้นตอนที่ 7: เพิ่มใน Kubernetes

สร้างไฟล์ `k8s/job-migrate-inventory.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-inventory-db
  namespace: default
spec:
  ttlSecondsAfterFinished: 3600
  backoffLimit: 3
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrator
        image: your-registry/fundii-database-migration:latest
        env:
        - name: POSTGRES_DSN
          valueFrom:
            secretKeyRef:
              name: inventory-db-credentials
              key: POSTGRES_DSN
        command: ["-db=postgres", "-type=schema", "-action=up", "-verbose=true"]
```

### ขั้นตอนที่ 8: ทดสอบ

```bash
# 1. Build binary
make build

# 2. รัน migration
POSTGRES_DSN="postgres://user:password@localhost:5432/inventory?sslmode=disable" \
  ./migrator -db=postgres -type=schema -verbose=true

# 3. ตรวจสอบ
psql -h localhost -U user -d inventory -c "\dt"
psql -h localhost -U user -d inventory -c "SELECT * FROM warehouses;"
```

---

## 🆕 เพิ่ม MongoDB Database ใหม่

สมมติเราต้องการเพิ่ม database **`logs`** สำหรับเก็บ application logs

### ขั้นตอนที่ 1: สร้างโครงสร้าง Directory

```bash
mkdir -p migrations/mongo-logs/schema
```

### ขั้นตอนที่ 2: สร้าง Migration Files

#### 2.1 สร้าง Schema Migration (up)

`migrations/mongo-logs/schema/000001_create_logs_collection.up.js`
```json
[
  {
    "create": "application_logs",
    "validator": {
      "$jsonSchema": {
        "bsonType": "object",
        "required": ["level", "message", "timestamp"],
        "properties": {
          "level": {
            "bsonType": "string",
            "enum": ["error", "warn", "info", "debug"]
          },
          "message": {
            "bsonType": "string"
          },
          "timestamp": {
            "bsonType": "date"
          },
          "source": {
            "bsonType": "string"
          },
          "userId": {
            "bsonType": "string"
          },
          "metadata": {
            "bsonType": "object"
          }
        }
      }
    }
  }
]
```

#### 2.2 สร้าง Schema Migration (down)

`migrations/mongo-logs/schema/000001_create_logs_collection.down.js`
```json
[
  {
    "drop": "application_logs"
  }
]
```

#### 2.3 สร้าง Seed Migration (up) - optional

`migrations/mongo-logs/schema/000002_seed_logs.up.js`
```json
[
  {
    "insert": "application_logs",
    "documents": [
      {
        "level": "info",
        "message": "Application started",
        "timestamp": { "$date": "2024-12-24T00:00:00Z" },
        "source": "app",
        "metadata": {
          "version": "1.0.0"
        }
      }
    ]
  }
]
```

#### 2.4 สร้าง Seed Migration (down)

`migrations/mongo-logs/schema/000002_seed_logs.down.js`
```json
[
  {
    "delete": "application_logs",
    "deletes": [
      {
        "q": { "message": "Application started" },
        "limit": 0
      }
    ]
  }
]
```

### ขั้นตอนที่ 3: เพิ่มใน Script

แก้ไขไฟล์ `migrate-all-databases.sh`:

```bash
# เพิ่มก่อน echo "🎉 All databases migrated successfully!"

# Migrate MongoDB Logs Database
echo -e "${BLUE}📋 Migrating MongoDB Logs Database...${NC}"
MONGO_URI="mongodb://${MONGO_HOST}:${MONGO_PORT}/logs" \
  ./migrator -db=mongo -type=schema -verbose=true
echo -e "${GREEN}✅ MongoDB Logs Database migrated${NC}"
echo ""
```

### ขั้นตอนที่ 4: เพิ่มใน Makefile

```makefile
migrate-logs-db: ## Migrate MongoDB logs database only
	@echo "📋 Migrating Logs Database..."
	@MONGO_URI="mongodb://$(MONGO_HOST):$(MONGO_PORT)/logs" \
		go run ./cmd/main.go -db=mongo -type=schema -verbose=true
```

### ขั้นตอนที่ 5: ทดสอบ

```bash
# รัน migration
MONGO_URI="mongodb://localhost:27017/logs" \
  ./migrator -db=mongo -type=schema -verbose=true

# ตรวจสอบ
mongosh mongodb://localhost:27017/logs --eval "db.getCollectionNames()"
mongosh mongodb://localhost:27017/logs --eval "db.application_logs.find().pretty()"
```

---

## ✅ Checklist สำหรับเพิ่ม Database ใหม่

### PostgreSQL
- [ ] สร้าง directory `migrations/postgres-{name}/schema`
- [ ] สร้าง `000001_create_tables.up.sql`
- [ ] สร้าง `000001_create_tables.down.sql`
- [ ] สร้าง `000002_seed_data.up.sql` (ถ้าต้องการ)
- [ ] สร้าง `000002_seed_data.down.sql` (ถ้าต้องการ)
- [ ] สร้าง database: `CREATE DATABASE {name};`
- [ ] เพิ่มใน `migrate-all-databases.sh`
- [ ] เพิ่มใน `Makefile`
- [ ] เพิ่มใน `docker-compose.multi-db.yml`
- [ ] เพิ่มใน `init-databases.sql`
- [ ] สร้าง Kubernetes Job (ถ้าใช้ K8s)
- [ ] ทดสอบ migration
- [ ] ทดสอบ rollback
- [ ] Commit ทุกไฟล์

### MongoDB
- [ ] สร้าง directory `migrations/mongo-{name}/schema`
- [ ] สร้าง `000001_create_collection.up.js`
- [ ] สร้าง `000001_create_collection.down.js`
- [ ] สร้าง `000002_seed_data.up.js` (ถ้าต้องการ)
- [ ] สร้าง `000002_seed_data.down.js` (ถ้าต้องการ)
- [ ] เพิ่มใน `migrate-all-databases.sh`
- [ ] เพิ่มใน `Makefile`
- [ ] เพิ่มใน `docker-compose.multi-db.yml` (ถ้าใช้)
- [ ] สร้าง Kubernetes Job (ถ้าใช้ K8s)
- [ ] ทดสอบ migration
- [ ] ทดสอบ rollback
- [ ] Commit ทุกไฟล์

---

## 📝 Naming Conventions

### Directory Names
- PostgreSQL: `postgres-{database_name}`
- MongoDB: `mongo-{database_name}`

ตัวอย่าง:
```
migrations/postgres-product/
migrations/postgres-user/
migrations/mongo-analytics/
migrations/mongo-logs/
```

### Migration File Names
```
NNNNNN_description.{up|down}.{sql|js}
```

- `NNNNNN`: เลข 6 หลัก (000001, 000002, ...)
- `description`: คำอธิบายสั้นๆ ใช้ underscore
- `.up`: apply migration
- `.down`: rollback migration
- `.sql`: PostgreSQL
- `.js`: MongoDB (JSON format)

---

## 🔍 การทดสอบ

### ทดสอบ Migration ใหม่

```bash
# 1. ทดสอบ up migration
POSTGRES_DSN="postgres://user:pass@localhost:5432/newdb?sslmode=disable" \
  ./migrator -db=postgres -type=schema -action=up -verbose=true

# 2. ตรวจสอบโครงสร้าง
psql -h localhost -U user -d newdb -c "\dt"
psql -h localhost -U user -d newdb -c "\d table_name"

# 3. ตรวจสอบ version
psql -h localhost -U user -d newdb -c "SELECT * FROM schema_migrations;"

# 4. ทดสอบ down migration
POSTGRES_DSN="postgres://user:pass@localhost:5432/newdb?sslmode=disable" \
  ./migrator -db=postgres -type=schema -action=down -steps=1 -verbose=true

# 5. ตรวจสอบว่า tables ถูกลบแล้ว
psql -h localhost -U user -d newdb -c "\dt"
```

---

## 💡 Tips & Best Practices

### 1. ใช้ Transactions (PostgreSQL)
```sql
BEGIN;
-- Your migration code
CREATE TABLE ...;
ALTER TABLE ...;
COMMIT;
```

### 2. ใช้ IF EXISTS/IF NOT EXISTS
```sql
CREATE TABLE IF NOT EXISTS ...;
DROP TABLE IF EXISTS ...;
CREATE INDEX IF NOT EXISTS ...;
```

### 3. Foreign Keys ต้องระวัง
```sql
-- ถ้า reference table อื่น ต้องแน่ใจว่า table นั้นมีอยู่แล้ว
-- หรือสร้าง migration แยก
```

### 4. MongoDB JSON Format
- ต้องเป็น valid JSON
- ใช้ double quotes (`"`) ไม่ใช่ single quotes (`'`)
- MongoDB commands ต้องอยู่ใน array `[...]`

### 5. Version Control
- Commit migration files ก่อนรัน
- ห้ามแก้ไข migration ที่รันไปแล้ว
- สร้าง migration ใหม่แทน

### 6. Documentation
- เขียน comments ในไฟล์ migration
- อัพเดท README เมื่อเพิ่ม database ใหม่
- เก็บ schema diagram (ถ้ามี)

---

## 🚨 Common Issues

### Issue 1: "database does not exist"
**Solution:** สร้าง database ก่อน
```bash
psql -U user postgres -c "CREATE DATABASE newdb;"
```

### Issue 2: "migration version conflict"
**Solution:** Reset migration version
```bash
psql -U user -d newdb -c "DROP TABLE schema_migrations;"
```

### Issue 3: "invalid JSON" (MongoDB)
**Solution:** ตรวจสอบ JSON syntax
```bash
# ใช้ tool validate
cat migration.js | jq .
```

### Issue 4: "permission denied"
**Solution:** ตรวจสอบ user permissions
```bash
psql -U user postgres -c "GRANT ALL PRIVILEGES ON DATABASE newdb TO user;"
```

---

## 📚 ตัวอย่างเพิ่มเติม

ดู migrations ที่มีอยู่แล้ว:
- `migrations/postgres-product/` - PostgreSQL product database
- `migrations/postgres-user/` - PostgreSQL user database
- `migrations/postgres-order/` - PostgreSQL order database
- `migrations/mongo-product/` - MongoDB product catalog
- `migrations/mongo-analytics/` - MongoDB analytics

---

## 📞 การขอความช่วยเหลือ

ถ้าติดปัญหา:
1. ดู logs: `./migrator -verbose=true`
2. ตรวจสอบ connection string
3. ทดสอบ migration ใน local ก่อน
4. ดู examples ใน `migrations/` directory
5. อ่าน [README.md](./README.md) หลัก
