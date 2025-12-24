# Smart Migration - รันเฉพาะไฟล์ที่เปลี่ยนแปลง

ระบบใหม่นี้จะ**อัตโนมัติตรวจจับและรัน migration เฉพาะไฟล์ที่เพิ่ม/แก้ไขใหม่**

## 🎯 ความแตกต่างจากเดิม

### ⛔ แบบเดิม (ไม่แนะนำแล้ว)
```bash
# ต้องรันแยก job สำหรับแต่ละ database
make k8s-apply-schema  # Job 1: schema
make k8s-apply-seed    # Job 2: seed

# รัน migration ทุกไฟล์ทุกครั้ง
```

### ✅ แบบใหม่ (Smart Migration)
```bash
# Job เดียว auto-detect ไฟล์ที่เปลี่ยนแปลง
make k8s-apply

# รันเฉพาะ database ที่มีไฟล์เปลี่ยน
```

---

## 🚀 การใช้งาน

### 1. Local Development

#### เพิ่ม Migration ใหม่
```bash
# 1. สร้างไฟล์ migration
cat > migrations/postgres-product/schema/000003_add_discount_field.up.sql << 'EOF'
ALTER TABLE products ADD COLUMN discount DECIMAL(5,2) DEFAULT 0.00;
EOF

cat > migrations/postgres-product/schema/000003_add_discount_field.down.sql << 'EOF'
ALTER TABLE products DROP COLUMN discount;
EOF

# 2. Stage ไฟล์ใน Git
git add migrations/postgres-product/

# 3. รัน Smart Migration (ตรวจจับและรันเฉพาะ product database)
make migrate-changed
```

#### Output ที่จะเห็น:
```
🔍 Detecting changed migration files...

Found changed migration files:
  📄 migrations/postgres-product/schema/000003_add_discount_field.up.sql
  📄 migrations/postgres-product/schema/000003_add_discount_field.down.sql

=== Running Migrations ===

🐘 Migrating PostgreSQL: product
✅ PostgreSQL product migrated

🎉 All changed migrations applied successfully!
```

### 2. Kubernetes Deployment

#### Setup (ครั้งเดียว)

```bash
# 1. สร้าง secret
kubectl create secret generic database-credentials \
  --from-literal=POSTGRES_USER=user \
  --from-literal=POSTGRES_PASSWORD=password

# 2. แก้ไข image ใน k8s/job-migration.yaml
# เปลี่ยน: your-registry/fundii-database-migration:latest
# เป็น:   your-actual-registry.com/fundii-database-migration:v1.0.0
```

#### Deploy Migration

```bash
# 1. Commit migrations
git add migrations/
git commit -m "Add discount field to products"
git push

# 2. Build และ push Docker image
make docker-build docker-push REGISTRY=your-registry.com IMAGE_TAG=v1.0.0

# 3. Deploy Job (จะรันเฉพาะ databases ที่มีไฟล์เปลี่ยน)
make k8s-apply

# 4. ดู logs
make k8s-logs

# 5. ตรวจสอบสถานะ
make k8s-status
```

---

## 📋 ตัวอย่างการใช้งาน

### Scenario 1: แก้ไขเฉพาะ User Database

```bash
# แก้ไข user migration
vim migrations/postgres-user/schema/000003_add_avatar_field.up.sql

# Stage และรัน
git add migrations/postgres-user/
make migrate-changed
```

**ผลลัพธ์:** รันเฉพาะ `user` database เท่านั้น

---

### Scenario 2: แก้ไขหลาย Databases พร้อมกัน

```bash
# เพิ่ม migrations ใน 2 databases
vim migrations/postgres-product/schema/000004_add_rating.up.sql
vim migrations/mongo-analytics/schema/000002_add_events.up.js

# Stage และรัน
git add migrations/
make migrate-changed
```

**ผลลัพธ์:** 
- รัน `product` database (PostgreSQL)
- รัน `analytics` database (MongoDB)
- ข้าม databases อื่นๆ ที่ไม่มีการเปลี่ยนแปลง

---

### Scenario 3: แก้ไข Seed Data

```bash
# แก้ seed migration
vim migrations/postgres-order/schema/000003_add_more_orders.up.sql

# ระบบจะรัน migration ตามปกติ (ไม่แยก schema/seed)
git add migrations/postgres-order/
make migrate-changed
```

---

## 🔧 Configuration

### Environment Variables

```bash
# PostgreSQL
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_USER=user
export POSTGRES_PASSWORD=password

# MongoDB
export MONGO_HOST=localhost
export MONGO_PORT=27017
```

### Git Detection

Script จะตรวจจับไฟล์จาก:
1. **Staged files**: `git add` แล้ว
2. **Unstaged changes**: แก้ไขแต่ยัง `git add`
3. **Last commit**: commit ล่าสุด

---

## 🎨 Architecture

### การทำงาน

```
┌─────────────────────────────────────────┐
│  Git Repository                         │
│  migrations/                            │
│  ├── postgres-product/                 │
│  ├── postgres-user/      ← เปลี่ยนแปลง │
│  └── mongo-analytics/                   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  migrate-changed-only.sh                │
│  🔍 Detect: git diff                    │
│  📊 Parse: postgres-user                │
│  🎯 Target: user database only          │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  ./migrator                             │
│  🐘 Connect: postgres://host/user       │
│  ✅ Run: schema migrations              │
└─────────────────────────────────────────┘
```

### Kubernetes Workflow

```
┌──────────────────┐
│  Push to Git     │
└────────┬─────────┘
         ↓
┌──────────────────┐
│  CI/CD Build     │
│  Docker Image    │
└────────┬─────────┘
         ↓
┌──────────────────┐
│  kubectl apply   │
│  job-migration   │
└────────┬─────────┘
         ↓
┌──────────────────┐
│  Job Container   │
│  - Git clone     │
│  - Detect changes│
│  - Run migrations│
└──────────────────┘
```

---

## 📊 การตรวจสอบ

### ตรวจสอบว่าไฟล์ใดจะถูกรัน

```bash
# Dry run: ดูว่าจะรัน database ไหนบ้าง
git add migrations/
./migrate-changed-only.sh 2>&1 | grep "Migrating"
```

### ตรวจสอบ Migration Version

```bash
# PostgreSQL
psql -h localhost -U user -d product \
  -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;"

# MongoDB
mongosh mongodb://localhost:27017/analytics \
  --eval "db.schema_migrations.find().sort({version: -1}).limit(5)"
```

---

## 🚨 Troubleshooting

### Issue 1: "No changed migration files detected"

**สาเหตุ:** ไฟล์ยังไม่ได้ `git add` หรือ commit

**แก้ไข:**
```bash
git add migrations/
make migrate-changed
```

---

### Issue 2: รัน migration ของ database ที่ไม่ต้องการ

**สาเหตุ:** มีไฟล์เปลี่ยนแปลงค้างใน Git

**แก้ไข:**
```bash
# ดูว่าไฟล์ไหนเปลี่ยน
git status migrations/

# Commit หรือ revert ไฟล์ที่ไม่ต้องการ
git checkout migrations/postgres-product/schema/000003*
```

---

### Issue 3: Database connection failed

**สาเหตุ:** Environment variables ไม่ถูกต้อง

**แก้ไข:**
```bash
# ตรวจสอบ env vars
echo $POSTGRES_HOST
echo $POSTGRES_USER

# หรือระบุตอนรัน
POSTGRES_HOST=myhost.com make migrate-changed
```

---

## 💡 Best Practices

### 1. Commit Migration Files ทันที
```bash
# ✅ Good: commit ทันทีหลังสร้าง
git add migrations/postgres-product/schema/000003*
git commit -m "Add discount field to products"

# ❌ Bad: สะสมหลาย migrations
```

### 2. ใช้ Descriptive Commit Messages
```bash
# ✅ Good
git commit -m "feat(product): add discount field for promotions"

# ❌ Bad
git commit -m "update"
```

### 3. Test Locally ก่อน Push
```bash
# 1. รันใน local
make migrate-changed

# 2. ตรวจสอบผล
psql -U user -d product -c "\d products"

# 3. Test rollback
./migrator -db=postgres -action=down -steps=1

# 4. Push
git push
```

### 4. ใช้ Feature Branches
```bash
# สร้าง branch สำหรับ migration ใหม่
git checkout -b feat/add-discount-field

# เพิ่ม migrations
vim migrations/postgres-product/schema/000003*

# Test และ merge
make migrate-changed
git push origin feat/add-discount-field
```

---

## 📚 Commands Summary

### Local Development
```bash
make migrate-changed          # Smart migration (changed files only)
make migrate-all-dbs          # Migrate all databases (force)
make migrate-product-db       # Migrate specific database
```

### Kubernetes
```bash
make k8s-apply                # Deploy migration job
make k8s-logs                 # View logs
make k8s-status               # Check status
make k8s-delete               # Delete jobs
```

### Manual
```bash
./migrate-changed-only.sh     # Run smart migration script
./migrate-all-databases.sh    # Run all migrations
```

---

## 🔄 Migration vs Old Approach

| Feature | Old Approach | Smart Migration |
|---------|-------------|-----------------|
| Jobs | แยก schema/seed | Job เดียว |
| Detection | Manual | Auto (Git) |
| Scope | รันทั้งหมด | รันเฉพาะที่เปลี่ยน |
| Speed | ช้า | เร็ว |
| Resource | มาก | น้อย |
| Setup | ซับซ้อน | ง่าย |

---

## 🎓 สรุป

**Smart Migration = อัจฉริยะกว่า, เร็วกว่า, ประหยัด Resource**

- ✅ ตรวจจับไฟล์อัตโนมัติจาก Git
- ✅ รันเฉพาะ databases ที่มีการเปลี่ยนแปลง
- ✅ Job เดียวจัดการทุกอย่าง
- ✅ ประหยัด CPU/Memory
- ✅ Deploy เร็วขึ้น

เริ่มใช้งานได้เลยด้วย:
```bash
make migrate-changed
```
