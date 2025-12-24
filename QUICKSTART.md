# Quick Start Guide - เริ่มใช้งานด่วน

คู่มือเริ่มต้นใช้งานฉบับย่อ สำหรับผู้ที่ต้องการเริ่มต้นใช้งานอย่างรวดเร็ว

## 🚀 เริ่มใช้งานในเครื่อง (5 นาที)

### 1. เตรียมพร้อม

```bash
# Clone repository
git clone <repository-url>
cd fundii-database-migration

# ตรวจสอบว่ามี Go 1.25+
go version
```

### 2. ตั้งค่า Environment Variables

```bash
# สำหรับ PostgreSQL
export POSTGRES_DSN="postgres://user:password@localhost:5432/mydb?sslmode=disable"

# สำหรับ MongoDB
export MONGO_URI="mongodb://localhost:27017/mydb"
```

### 3. รัน Migration

```bash
# รันทั้งหมด
make run

# หรือแยกรัน
make run-postgres-schema  # Schema สำหรับ PostgreSQL
make run-mongo-schema     # Schema สำหรับ MongoDB
make run-postgres-seed    # Seed data สำหรับ PostgreSQL
make run-mongo-seed       # Seed data สำหรับ MongoDB
```

## 🐳 เริ่มใช้งานกับ Docker (10 นาที)

### 1. Build Docker Image

```bash
# แก้ไข REGISTRY ใน Makefile หรือระบุตอน run
make docker-build REGISTRY=your-registry.com IMAGE_TAG=v1.0.0
```

### 2. Push ไป Registry

```bash
make docker-push REGISTRY=your-registry.com IMAGE_TAG=v1.0.0
```

### 3. ทดสอบรัน Local

```bash
docker run --rm \
  -e POSTGRES_DSN="postgres://user:password@host:5432/mydb" \
  -e MONGO_URI="mongodb://host:27017/mydb" \
  your-registry.com/fundii-database-migration:v1.0.0 \
  -verbose=true
```

## ☸️ เริ่มใช้งานบน Kubernetes (15 นาที)

### 1. สร้าง Secret

```bash
export POSTGRES_DSN="postgres://user:password@postgres-service:5432/mydb?sslmode=disable"
export MONGO_URI="mongodb://mongo-service:27017/mydb"
make k8s-create-secret
```

### 2. แก้ไข Image Path

แก้ไขไฟล์ `k8s/job-schema.yaml`, `k8s/job-seed.yaml`:

```yaml
# เปลี่ยนบรรทัดนี้
image: your-registry/fundii-database-migration:latest

# เป็น
image: your-registry.com/fundii-database-migration:v1.0.0
```

### 3. รัน Migration Job

```bash
# รัน schema migration
make k8s-apply-schema

# ตรวจสอบสถานะ
kubectl get job db-migration-schema
kubectl get pods -l app=db-migration

# ดู logs
make k8s-logs-schema
```

### 4. รัน Seed Migration (Optional)

```bash
make k8s-apply-seed
make k8s-logs-seed
```

## 📝 สร้าง Migration ใหม่

### PostgreSQL

```bash
# Schema migration
cat > migrations/postgres/schema/000002_create_orders_table.up.sql << 'EOF'
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

cat > migrations/postgres/schema/000002_create_orders_table.down.sql << 'EOF'
DROP TABLE IF EXISTS orders;
EOF
```

### MongoDB

```bash
# Schema migration
cat > migrations/mongo/schema/000002_create_orders_collection.up.js << 'EOF'
db.createCollection("orders", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "total", "createdAt"],
      properties: {
        userId: { bsonType: "string" },
        total: { bsonType: "number", minimum: 0 },
        createdAt: { bsonType: "date" }
      }
    }
  }
});
db.orders.createIndex({ userId: 1 });
EOF

cat > migrations/mongo/schema/000002_create_orders_collection.down.js << 'EOF'
db.orders.drop();
EOF
```

## 🔧 คำสั่งที่ใช้บ่อย

```bash
# ดูคำสั่งทั้งหมด
make help

# รัน migration แบบระบุ flag
go run ./cmd/main.go -db=postgres -type=schema -action=up -verbose=true

# Rollback migration
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=1

# ตรวจสอบ version ปัจจุบัน
go run ./cmd/main.go -db=postgres -action=version

# ดู logs บน K8s
kubectl logs -f job/db-migration-schema

# ลบ jobs
make k8s-delete
```

## 🆘 แก้ปัญหาเบื้องต้น

### Connection Error

```bash
# ตรวจสอบ connection string
echo $POSTGRES_DSN
echo $MONGO_URI

# ทดสอบ connection
# PostgreSQL
psql "$POSTGRES_DSN" -c "SELECT 1;"

# MongoDB
mongosh "$MONGO_URI" --eval "db.runCommand({ ping: 1 })"
```

### Migration ไม่รัน

```bash
# ดู logs
kubectl logs -l app=db-migration --tail=100

# ตรวจสอบว่า migration files อยู่ใน path ที่ถูกต้อง
ls -la migrations/postgres/schema/
ls -la migrations/mongo/schema/
```

### Pod ไม่ Start

```bash
# ดู pod details
kubectl describe pod -l app=db-migration

# ตรวจสอบ secret
kubectl get secret database-credentials -o yaml
```

## 📚 ข้อมูลเพิ่มเติม

อ่านเพิ่มเติมใน [README.md](./README.md) สำหรับ:
- การใช้งานขั้นสูง
- Best practices
- Troubleshooting แบบละเอียด
- Configuration options

## 🎯 Next Steps

1. ✅ ทดสอบ migration ในเครื่องก่อน
2. ✅ ทดสอบ rollback ด้วย `-action=down`
3. ✅ Build Docker image
4. ✅ Deploy ไป Kubernetes
5. ✅ Setup CronJob สำหรับ scheduled migrations

Happy migrating! 🚀
