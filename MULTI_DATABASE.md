# การจัดการหลาย Databases บน Host เดียวกัน

คู่มือนี้อธิบายวิธีการ migrate หลาย databases (product, user, order) ที่อยู่บน PostgreSQL host เดียวกัน

## 📁 โครงสร้าง

```
migrations/
├── product/
│   └── schema/
│       ├── 000001_create_products_table.up.sql
│       └── 000002_seed_products.up.sql
├── user/
│   └── schema/
│       ├── 000001_create_users_table.up.sql
│       └── 000002_seed_users.up.sql
└── order/
    └── schema/
        ├── 000001_create_orders_table.up.sql
        └── 000002_seed_orders.up.sql
```

## 🚀 วิธีใช้งาน

### 1. ใช้ Makefile (ง่ายที่สุด)

```bash
# Migrate ทั้งหมด
make migrate-all-dbs

# หรือ migrate ทีละ database
make migrate-product-db
make migrate-user-db
make migrate-order-db
```

### 2. ใช้ Script

```bash
# แก้ไข configuration ใน migrate-all-databases.sh
vim migrate-all-databases.sh

# รัน script
./migrate-all-databases.sh
```

### 3. ใช้ Docker Compose

```bash
# รัน migration สำหรับทุก database พร้อมกัน
docker-compose -f docker-compose.multi-db.yml up --build

# รัน migration เฉพาะ database เดียว
docker-compose -f docker-compose.multi-db.yml up migrate-product
docker-compose -f docker-compose.multi-db.yml up migrate-user
docker-compose -f docker-compose.multi-db.yml up migrate-order
```

### 4. รัน Manual

```bash
# Product Database
POSTGRES_DSN="postgres://user:password@localhost:5432/product?sslmode=disable" \
  ./migrator -db=postgres -type=schema -verbose=true

# User Database
POSTGRES_DSN="postgres://user:password@localhost:5432/user?sslmode=disable" \
  ./migrator -db=postgres -type=schema -verbose=true

# Order Database
POSTGRES_DSN="postgres://user:password@localhost:5432/order?sslmode=disable" \
  ./migrator -db=postgres -type=schema -verbose=true
```

## ⚙️ Configuration

### Environment Variables

```bash
# สำหรับ Makefile
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_USER=user
export POSTGRES_PASSWORD=password

# หรือส่งตอนรันคำสั่ง
make migrate-product-db POSTGRES_HOST=prod-db.example.com POSTGRES_USER=admin
```

### Docker Compose

แก้ไขไฟล์ `docker-compose.multi-db.yml`:
```yaml
environment:
  POSTGRES_DSN: "postgres://user:password@postgres:5432/product?sslmode=disable"
```

## 🎯 สำหรับ Production

### Kubernetes - แยก Job สำหรับแต่ละ Database

สร้างไฟล์ `k8s/job-migrate-product.yaml`:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-product-db
spec:
  template:
    spec:
      containers:
      - name: migrator
        image: your-registry/migrator:latest
        env:
        - name: POSTGRES_DSN
          valueFrom:
            secretKeyRef:
              name: product-db-credentials
              key: POSTGRES_DSN
        command: ["-db=postgres", "-type=schema", "-verbose=true"]
      restartPolicy: Never
```

Deploy:
```bash
# สร้าง secrets สำหรับแต่ละ database
kubectl create secret generic product-db-credentials \
  --from-literal=POSTGRES_DSN="postgres://user:pass@host:5432/product"

kubectl create secret generic user-db-credentials \
  --from-literal=POSTGRES_DSN="postgres://user:pass@host:5432/user"

kubectl create secret generic order-db-credentials \
  --from-literal=POSTGRES_DSN="postgres://user:pass@host:5432/order"

# Deploy jobs
kubectl apply -f k8s/job-migrate-product.yaml
kubectl apply -f k8s/job-migrate-user.yaml
kubectl apply -f k8s/job-migrate-order.yaml

# ดู logs
kubectl logs -f job/migrate-product-db
kubectl logs -f job/migrate-user-db
kubectl logs -f job/migrate-order-db
```

## 📝 การสร้าง Migration ใหม่

### สำหรับ Product Database

```bash
# สร้างไฟล์ใน migrations/product/schema/
cat > migrations/product/schema/000003_add_category_column.up.sql << 'EOF'
ALTER TABLE products ADD COLUMN category VARCHAR(100);
CREATE INDEX idx_products_category ON products(category);
EOF

cat > migrations/product/schema/000003_add_category_column.down.sql << 'EOF'
DROP INDEX IF EXISTS idx_products_category;
ALTER TABLE products DROP COLUMN category;
EOF
```

### สำหรับ User Database

```bash
cat > migrations/user/schema/000003_add_profile_table.up.sql << 'EOF'
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    bio TEXT,
    avatar_url VARCHAR(255)
);
EOF

cat > migrations/user/schema/000003_add_profile_table.down.sql << 'EOF'
DROP TABLE IF EXISTS user_profiles;
EOF
```

## 🔍 ตรวจสอบสถานะ

```bash
# ตรวจสอบว่า databases ถูกสร้างแล้ว
psql -h localhost -U user -c "\l"

# ตรวจสอบ migration version ของแต่ละ database
psql -h localhost -U user -d product -c "SELECT * FROM schema_migrations;"
psql -h localhost -U user -d user -c "SELECT * FROM schema_migrations;"
psql -h localhost -U user -d order -c "SELECT * FROM schema_migrations;"
```

## 💡 Tips

### 1. ลำดับการ Migrate
ถ้า databases มี dependencies กัน ใช้ Docker Compose dependency:
```yaml
migrate-order:
  depends_on:
    migrate-user:
      condition: service_completed_successfully
```

### 2. Parallel Migrations
ถ้า databases ไม่มี dependency รันพร้อมกันได้:
```bash
# รัน 3 terminals พร้อมกัน
make migrate-product-db &
make migrate-user-db &
make migrate-order-db &
wait
```

### 3. CI/CD Pipeline
```yaml
# GitHub Actions
- name: Migrate Product DB
  run: |
    POSTGRES_DSN="${{ secrets.PRODUCT_DB_DSN }}" \
      ./migrator -db=postgres -type=schema

- name: Migrate User DB
  run: |
    POSTGRES_DSN="${{ secrets.USER_DB_DSN }}" \
      ./migrator -db=postgres -type=schema

- name: Migrate Order DB
  run: |
    POSTGRES_DSN="${{ secrets.ORDER_DB_DSN }}" \
      ./migrator -db=postgres -type=schema
```

## 🆘 Troubleshooting

### Database ไม่มี
```bash
# สร้าง databases
psql -h localhost -U user postgres << EOF
CREATE DATABASE product;
CREATE DATABASE "user";
CREATE DATABASE "order";
EOF
```

### Migration version conflict
```bash
# Reset migration version ของแต่ละ database
psql -h localhost -U user -d product -c "DROP TABLE IF EXISTS schema_migrations;"
psql -h localhost -U user -d user -c "DROP TABLE IF EXISTS schema_migrations;"
psql -h localhost -U user -d order -c "DROP TABLE IF EXISTS schema_migrations;"
```

## 📚 สรุป

**วิธีที่แนะนำ:**
1. ✅ Development: ใช้ `make migrate-all-dbs` 
2. ✅ Testing: ใช้ `docker-compose -f docker-compose.multi-db.yml up`
3. ✅ Production: ใช้ Kubernetes Jobs แยกกัน

**ข้อดี:**
- ง่าย ไม่ต้องแก้โค้ด
- แยก migration แต่ละ database ชัดเจน
- รัน parallel ได้ (ถ้าไม่มี dependency)
- Rollback แต่ละ database ได้อิสระ
