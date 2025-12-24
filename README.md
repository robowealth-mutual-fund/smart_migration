# Fundii Database Migration Tool

เครื่องมือสำหรับจัดการ database migration สำหรับ PostgreSQL และ MongoDB พร้อมรองรับการใช้งานบน Kubernetes

## คุณสมบัติ

- ✅ รองรับ PostgreSQL และ MongoDB
- ✅ แยก Schema และ Seed migrations
- ✅ รองรับการรัน migration แบบ up, down และ version
- ✅ ใช้งานง่ายด้วย command-line flags
- ✅ Docker image ขนาดเล็ก (multi-stage build)
- ✅ พร้อมใช้งานบน Kubernetes (Job และ CronJob)
- ✅ Verbose logging สำหรับ debugging

## โครงสร้างโปรเจค

```
fundii-database-migration/
├── cmd/
│   └── main.go                    # Entry point
├── internal/
│   └── config/
│       └── config_loader.go       # Configuration loader
├── migrations/
│   ├── postgres/
│   │   ├── schema/               # PostgreSQL schema migrations
│   │   └── seed/                 # PostgreSQL seed data
│   └── mongo/
│       ├── schema/               # MongoDB schema migrations
│       └── seed/                 # MongoDB seed data
├── k8s/
│   ├── configmap.yaml            # Kubernetes ConfigMap
│   ├── secret.yaml.example       # Kubernetes Secret template
│   ├── job-schema.yaml           # Schema migration Job
│   ├── job-seed.yaml             # Seed migration Job
│   └── cronjob.yaml              # Scheduled migration CronJob
├── Dockerfile                     # Multi-stage Docker build
├── Makefile                       # ทำให้การใช้งานง่ายขึ้น
├── go.mod
└── README.md
```

## การติดตั้ง

### ข้อกำหนดเบื้องต้น

- Go 1.25 หรือสูงกว่า
- Docker (สำหรับ build image)
- kubectl (สำหรับ deploy ไปยัง Kubernetes)
- Access ไปยัง PostgreSQL และ/หรือ MongoDB

### Clone Repository

```bash
git clone <repository-url>
cd fundii-database-migration
```

## การใช้งาน

### 1. การรันในเครื่อง (Local)

#### ตั้งค่า Environment Variables

```bash
export POSTGRES_DSN="postgres://user:password@localhost:5432/mydb?sslmode=disable"
export MONGO_URI="mongodb://localhost:27017/mydb"
```

#### รัน Migration แบบต่างๆ

```bash
# รัน schema migrations สำหรับทั้ง PostgreSQL และ MongoDB
make run-postgres-schema
make run-mongo-schema

# รัน seed migrations
make run-postgres-seed
make run-mongo-seed

# รันทั้งหมดพร้อมกัน
make run
```

#### ใช้ Command-line Flags

```bash
# รัน PostgreSQL schema migration
go run ./cmd/main.go -db=postgres -type=schema -action=up -verbose=true

# รัน MongoDB seed migration
go run ./cmd/main.go -db=mongo -type=seed -action=up -verbose=true

# รันทั้งหมด
go run ./cmd/main.go -db=all -type=all -action=up -verbose=true

# Rollback migration 2 steps
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=2

# ตรวจสอบ version
go run ./cmd/main.go -db=postgres -type=schema -action=version
```

### 2. การใช้งานกับ Docker

#### Build Docker Image

```bash
# Build ด้วย default settings
make docker-build

# Build พร้อมกำหนด registry และ tag
make docker-build REGISTRY=your-registry.com IMAGE_TAG=v1.0.0
```

#### Run Docker Container

```bash
make docker-run POSTGRES_DSN="postgres://..." MONGO_URI="mongodb://..."

# หรือใช้ docker run โดยตรง
docker run --rm \
  -e POSTGRES_DSN="postgres://user:password@host:5432/mydb" \
  -e MONGO_URI="mongodb://host:27017/mydb" \
  your-registry/fundii-database-migration:latest \
  -db=all -type=schema -action=up -verbose=true
```

#### Push Image ไปยัง Registry

```bash
# Push image
make docker-push REGISTRY=your-registry.com IMAGE_TAG=v1.0.0
```

### 3. การใช้งานบน Kubernetes

#### เตรียม Kubernetes Resources

##### 1. สร้าง Secret สำหรับ Database Credentials

```bash
# วิธีที่ 1: ใช้ Makefile
export POSTGRES_DSN="postgres://user:password@postgres-service:5432/mydb?sslmode=disable"
export MONGO_URI="mongodb://mongo-service:27017/mydb"
make k8s-create-secret

# วิธีที่ 2: ใช้ kubectl โดยตรง
kubectl create secret generic database-credentials \
  --from-literal=POSTGRES_DSN="postgres://..." \
  --from-literal=MONGO_URI="mongodb://..."

# วิธีที่ 3: แก้ไข k8s/secret.yaml.example แล้ว apply
cp k8s/secret.yaml.example k8s/secret.yaml
# แก้ไขค่าใน secret.yaml
kubectl apply -f k8s/secret.yaml
```

##### 2. แก้ไข Image ใน Job Manifests

แก้ไขไฟล์ `k8s/job-schema.yaml`, `k8s/job-seed.yaml`, และ `k8s/cronjob.yaml`:

```yaml
# เปลี่ยนจาก
image: your-registry/fundii-database-migration:latest

# เป็น
image: your-actual-registry.com/fundii-database-migration:v1.0.0
```

#### รัน Migration Jobs

```bash
# รัน schema migration
make k8s-apply-schema

# รัน seed migration
make k8s-apply-seed

# ดู logs
make k8s-logs-schema
make k8s-logs-seed

# ตรวจสอบสถานะ
make k8s-status

# ลบ jobs
make k8s-delete
```

#### Setup CronJob สำหรับ Scheduled Migrations

```bash
# Apply CronJob
make k8s-apply-cronjob

# ตรวจสอบ CronJob
kubectl get cronjob db-migration-scheduled

# ดู history
kubectl get jobs -l app=db-migration

# ลบ CronJob
kubectl delete cronjob db-migration-scheduled
```

## 🚀 Migration Generator (Go-based!)

เครื่องมือสร้้าง migration files อัตโนมัติจาก YAML templates โดยใช้ Go (**ไม่ต้อง yq, Python, PyYAML!**)

```bash
# สร้าง PostgreSQL table migration
make generate FILE=examples/postgres-simple-table.yaml

# สร้าง MongoDB collection migration
make generate FILE=examples/mongo-simple-collection.yaml
```

### ตัวอย่าง YAML Template

**PostgreSQL:**
```yaml
database:
  type: postgres
  name: product

table:
  name: users
  columns:
    - name: id
      type: SERIAL
      primary_key: true
    - name: email
      type: VARCHAR(255)
      not_null: true
      unique: true
    - name: created_at
      type: TIMESTAMPTZ
      default: CURRENT_TIMESTAMP
  
  indexes:
    - name: idx_users_email
      columns: [email]
      unique: true
```

**MongoDB:**
```yaml
database:
  type: mongo
  name: user

collection:
  name: users
  validator:
    $jsonSchema:
      bsonType: object
      required: [email]
      properties:
        email:
          bsonType: string
          pattern: "^.+@.+$"
  
  indexes:
    - keys: {email: 1}
      unique: true
```

📚 **อ่านเพิ่มเติม:** [GENERATOR.md](GENERATOR.md) | [examples/README.md](examples/README.md)

---

## การเขียน Migration Files ด้วยตัวเอง

### PostgreSQL Migrations

#### Schema Migration

สร้างไฟล์ใน `migrations/postgres/schema/`:

```sql
-- 000001_create_users_table.up.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

```sql
-- 000001_create_users_table.down.sql
DROP TABLE IF EXISTS users;
```

#### Seed Migration

สร้างไฟล์ใน `migrations/postgres/seed/`:

```sql
-- 000001_seed_users.up.sql
INSERT INTO users (username, email) 
VALUES ('admin', 'admin@example.com')
ON CONFLICT (username) DO NOTHING;
```

### MongoDB Migrations

#### Schema Migration

สร้างไฟล์ใน `migrations/mongo/schema/`:

```javascript
// 000001_create_products_collection.up.js
db.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "price"],
      properties: {
        name: { bsonType: "string" },
        price: { bsonType: "number", minimum: 0 }
      }
    }
  }
});

db.products.createIndex({ name: 1 }, { unique: true });
```

```javascript
// 000001_create_products_collection.down.js
db.products.drop();
```

## Command-line Flags

| Flag | Default | Description |
|------|---------|-------------|
| `-db` | `all` | Database type: `postgres`, `mongo`, หรือ `all` |
| `-type` | `schema` | Migration type: `schema`, `seed`, หรือ `all` |
| `-action` | `up` | Action: `up`, `down`, หรือ `version` |
| `-steps` | `0` | จำนวน steps สำหรับ down action (0 = ทั้งหมด) |
| `-verbose` | `false` | เปิด verbose logging |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `POSTGRES_DSN` | No* | PostgreSQL connection string |
| `MONGO_URI` | No* | MongoDB connection URI |

*จำเป็นถ้าต้องการ migrate database นั้นๆ

## Kubernetes Configuration

### Job Resources

- **Requests**: 64Mi memory, 100m CPU
- **Limits**: 128Mi memory, 200m CPU
- **TTL**: Jobs จะถูกลบอัตโนมัติหลังจาก 1 ชั่วโมง
- **Backoff Limit**: จะ retry สูงสุด 3 ครั้ง

### CronJob Schedule

Default: รันทุกวันเวลา 2:00 AM
แก้ไขใน `k8s/cronjob.yaml`:

```yaml
spec:
  schedule: "0 2 * * *"  # Cron format
```

## Tips & Best Practices

### 1. Migration Naming Convention

ใช้รูปแบบ: `NNNNNN_description.up.sql` และ `NNNNNN_description.down.sql`
- `NNNNNN`: เลข 6 หลัก เช่น 000001, 000002
- `description`: คำอธิบายสั้นๆ ใช้ underscore
- เสมอต้องมีทั้ง `.up` และ `.down` ไฟล์

### 2. Testing Migrations

```bash
# Test locally ก่อน
make run-postgres-schema

# Test rollback
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=1

# Test ใน Docker ก่อน push
make docker-build
make docker-run POSTGRES_DSN="..." MONGO_URI="..."
```

### 3. Production Deployment

```bash
# 1. Build และ push image
make docker-push REGISTRY=your-registry.com IMAGE_TAG=v1.0.0

# 2. สร้าง secret
make k8s-create-secret

# 3. รัน schema migration ก่อน
make k8s-apply-schema
make k8s-logs-schema

# 4. ถ้าสำเร็จ รัน seed migration
make k8s-apply-seed
make k8s-logs-seed
```

### 4. Monitoring

```bash
# ดู logs แบบ real-time
kubectl logs -f job/db-migration-schema

# ตรวจสอบ job status
kubectl get jobs -l app=db-migration

# ดู events
kubectl get events --sort-by='.lastTimestamp' | grep migration
```

## Troubleshooting

### Migration ไม่รัน

1. ตรวจสอบ logs:
```bash
kubectl logs -l app=db-migration --tail=100
```

2. ตรวจสอบ secret:
```bash
kubectl get secret database-credentials -o yaml
```

3. ตรวจสอบ connectivity:
```bash
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- \
  psql "postgres://user:password@postgres-service:5432/mydb"
```

### Job ติด Pending

```bash
# ตรวจสอบ pod status
kubectl describe pod -l app=db-migration

# ตรวจสอบ resources
kubectl top nodes
```

### Migration Failed

```bash
# ดู error logs
kubectl logs -l app=db-migration,type=schema

# Check migration version
go run ./cmd/main.go -db=postgres -action=version

# Rollback ถ้าจำเป็น
go run ./cmd/main.go -db=postgres -type=schema -action=down -steps=1
```

## การพัฒนาต่อ

### เพิ่ม Migration ใหม่

1. สร้างไฟล์ migration ด้วยเลขถัดไป
2. Test locally
3. Commit และ push
4. Build image ใหม่
5. Deploy

### Makefile Targets ทั้งหมด

```bash
make help  # ดูคำสั่งทั้งหมด
```

## License

[Your License Here]

## Authors

- Fundii Development Team

## Support

สำหรับคำถามหรือปัญหา กรุณาติดต่อ:
- Email: support@fundii.com
- Slack: #database-migrations
