# Migration Generator 🚀

เครื่องมือสร้าง migration files อัตโนมัติจาก YAML templates โดยใช้ Go

## ✨ ข้อดีของ Go Generator

- **✅ ไม่ต้องติดตั้ง dependencies**: ไม่ต้องใช้ yq, Python, PyYAML
- **⚡ เร็วกว่า**: Compiled binary ทำงานไวเกิน 1000x
- **🛠️ Type-safe**: ตรวจสอบ YAML schema ตอน compile time
- **📦 Single binary**: ไฟล์เดียว portable ได้ทั้ง Docker/K8s
- **🎉 สอดคล้องกับ codebase**: ใช้ Go เหมือน migrator

## 📋 สิ่งที่ต้องติดตั้ง

```bash
# Go 1.25+ (required)
go version

# ไม่ต้องติดตั้ง dependencies อื่นแล้ว!
# (ไม่ต้องใช้ yq, Python, หรือ PyYAML)
```

---

## 🚀 การใช้งาน

### วิธีที่ 1: ใช้ Makefile (แนะนำ)

```bash
make generate FILE=examples/postgres-simple-table.yaml
```

### วิธีที่ 2: ใช้ Go generator โดยตรง

```bash
# Build generator first
go build -o generator ./cmd/generator/main.go

# Then use it
./generator examples/postgres-simple-table.yaml
```

---

## 📂 ตัวอย่างที่มีให้

### PostgreSQL Examples

```bash
# Simple table
make generate FILE=examples/postgres-simple-table.yaml

# E-commerce product table (realistic use case)
make generate FILE=examples/ecommerce-product.yaml

# All data types demo
make generate FILE=examples/templates/postgres-all-types.yaml
```

### MongoDB Examples

```bash
# Simple collection
make generate FILE=examples/mongo-simple-collection.yaml

# User profile (realistic use case)
make generate FILE=examples/user-profile-mongo.yaml

# All BSON types demo
make generate FILE=examples/templates/mongo-all-types.yaml
```

---

## 📝 สร้าง YAML Schema

### PostgreSQL Template

```yaml
database:
  type: postgres
  name: product  # ชื่อ database (จะสร้างใน migrations/postgres-{name}/)

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
    
    - name: name
      type: VARCHAR(100)
      not_null: true
    
    - name: age
      type: INTEGER
    
    - name: is_active
      type: BOOLEAN
      default: true
    
    - name: metadata
      type: JSONB
    
    - name: tags
      type: TEXT[]
    
    - name: created_at
      type: TIMESTAMPTZ
      default: CURRENT_TIMESTAMP

  indexes:
    - name: idx_users_email
      columns: [email]
      unique: true
    
    - name: idx_users_name
      columns: [name]
    
    - name: idx_users_metadata
      columns: [metadata]
      type: GIN
```

### MongoDB Template

```yaml
database:
  type: mongo
  name: user  # ชื่อ database (จะสร้างใน migrations/mongo-{name}/)

collection:
  name: users
  validator:
    $jsonSchema:
      bsonType: object
      required: [email, name, createdAt]
      properties:
        email:
          bsonType: string
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        
        name:
          bsonType: string
          minLength: 3
          maxLength: 100
        
        age:
          bsonType: int
          minimum: 0
          maximum: 150
        
        tags:
          bsonType: array
          items:
            bsonType: string
          uniqueItems: true
        
        metadata:
          bsonType: object
        
        isActive:
          bsonType: bool
        
        createdAt:
          bsonType: date
  
  indexes:
    - keys: {email: 1}
      unique: true
    - keys: {name: "text"}
    - keys: {createdAt: -1}
```

---

## 📚 Data Types Reference

### PostgreSQL Data Types

| Type | Example | Description |
|------|---------|-------------|
| `SERIAL` | `SERIAL` | Auto-incrementing integer (1 to 2B) |
| `BIGSERIAL` | `BIGSERIAL` | Auto-incrementing bigint (1 to 9E18) |
| `SMALLINT` | `SMALLINT` | Small integer (-32768 to 32767) |
| `INTEGER` | `INTEGER` | Standard integer (-2B to 2B) |
| `BIGINT` | `BIGINT` | Large integer (-9E18 to 9E18) |
| `DECIMAL` | `DECIMAL(10,2)` | Exact decimal (10 digits, 2 decimals) |
| `NUMERIC` | `NUMERIC(15,5)` | Exact numeric (15 digits, 5 decimals) |
| `REAL` | `REAL` | Floating point (6 decimal precision) |
| `DOUBLE PRECISION` | `DOUBLE PRECISION` | Double float (15 decimal precision) |
| `VARCHAR` | `VARCHAR(255)` | Variable-length string (max 255) |
| `CHAR` | `CHAR(10)` | Fixed-length string (10 chars) |
| `TEXT` | `TEXT` | Unlimited length string |
| `BOOLEAN` | `BOOLEAN` | True/false value |
| `DATE` | `DATE` | Date only (YYYY-MM-DD) |
| `TIME` | `TIME` | Time only (HH:MM:SS) |
| `TIMESTAMP` | `TIMESTAMP` | Date + time (no timezone) |
| `TIMESTAMPTZ` | `TIMESTAMPTZ` | Date + time (with timezone) |
| `INTERVAL` | `INTERVAL` | Time interval |
| `JSON` | `JSON` | JSON data (text format) |
| `JSONB` | `JSONB` | JSON data (binary, indexable) |
| `ARRAY` | `TEXT[]`, `INTEGER[]` | Array of values |
| `UUID` | `UUID` | Universally unique identifier |
| `BYTEA` | `BYTEA` | Binary data |
| `INET` | `INET` | IPv4 or IPv6 address |
| `MACADDR` | `MACADDR` | MAC address |
| `CIDR` | `CIDR` | Network address |
| `POINT` | `POINT` | Geometric point |
| `MONEY` | `MONEY` | Currency amount |
| `XML` | `XML` | XML document |

### MongoDB BSON Types

| Type | Example | Description |
|------|---------|-------------|
| `string` | `bsonType: string` | UTF-8 string |
| `int` | `bsonType: int` | 32-bit integer |
| `long` | `bsonType: long` | 64-bit integer |
| `double` | `bsonType: double` | 64-bit floating point |
| `decimal` | `bsonType: decimal` | 128-bit decimal |
| `bool` | `bsonType: bool` | Boolean |
| `date` | `bsonType: date` | UTC datetime |
| `objectId` | `bsonType: objectId` | 12-byte ObjectId |
| `array` | `bsonType: array` | Array of values |
| `object` | `bsonType: object` | Embedded document |
| `binData` | `bsonType: binData` | Binary data |
| `null` | `bsonType: ["string", "null"]` | Nullable field |

---

## 💡 คุณสมบัติพิเศษ

### PostgreSQL

#### Auto-increment Version Numbers
```bash
# Version numbers are auto-generated
# 000001_users.up.sql, 000001_users.down.sql
# 000002_products.up.sql, 000002_products.down.sql
```

#### Constraints
```yaml
columns:
  - name: status
    type: VARCHAR(20)
    not_null: true
    default: "'pending'"  # String values need quotes

constraints:
  - type: CHECK
    expression: "status IN ('pending', 'completed')"
```

#### Foreign Keys
```yaml
foreign_keys:
  - column: user_id
    references: users(id)
    on_delete: CASCADE
    on_update: CASCADE
```

#### Indexes
```yaml
indexes:
  # Simple index
  - name: idx_users_email
    columns: [email]
    unique: true
  
  # Compound index
  - name: idx_users_name_email
    columns: [name, email]
  
  # GIN index for JSONB
  - name: idx_users_metadata
    columns: [metadata]
    type: GIN
```

### MongoDB

#### Schema Validation
```yaml
validator:
  $jsonSchema:
    bsonType: object
    required: [email, name]  # Required fields
    properties:
      email:
        bsonType: string
        pattern: "^.+@.+$"  # Regex validation
      
      age:
        bsonType: int
        minimum: 0
        maximum: 150
```

#### Array Validation
```yaml
tags:
  bsonType: array
  items:
    bsonType: string
  minItems: 0
  maxItems: 10
  uniqueItems: true  # No duplicates
```

#### Nested Objects
```yaml
address:
  bsonType: object
  required: [city, country]
  properties:
    street:
      bsonType: string
    city:
      bsonType: string
    postalCode:
      bsonType: string
      pattern: "^[0-9]{5}$"
```

#### Indexes
```yaml
indexes:
  # Unique index
  - keys: {email: 1}
    unique: true
  
  # Text index (full-text search)
  - keys: {name: "text"}
  
  # Compound index
  - keys: {category: 1, price: -1}
  
  # Nested field index
  - keys: {"address.city": 1}
```

---

## 🔧 ขั้นตอนการใช้งานจริง

### 1. สร้าง YAML Schema

สร้างไฟล์ `my-schema.yaml`:

```yaml
database:
  type: postgres
  name: product

table:
  name: categories
  columns:
    - name: id
      type: SERIAL
      primary_key: true
    - name: name
      type: VARCHAR(100)
      not_null: true
    - name: slug
      type: VARCHAR(100)
      not_null: true
      unique: true
    - name: created_at
      type: TIMESTAMPTZ
      default: CURRENT_TIMESTAMP
  
  indexes:
    - name: idx_categories_slug
      columns: [slug]
      unique: true
```

### 2. Generate Migration

```bash
make generate FILE=my-schema.yaml
```

Output:
```
✅ Generated migration files:
  - migrations/postgres-product/schema/000003_categories.up.sql
  - migrations/postgres-product/schema/000003_categories.down.sql
```

### 3. ตรวจสอบไฟล์ที่สร้าง

```sql
-- 000003_categories.up.sql
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_slug ON categories (slug);
```

```sql
-- 000003_categories.down.sql
DROP TABLE IF EXISTS categories CASCADE;
```

### 4. Run Migration

```bash
# ใช้ smart migration (แนะนำ)
make migrate-changed

# หรือ migrate เฉพาะ database
POSTGRES_DSN="postgres://user:pass@host:5432/product?sslmode=disable" \
  ./migrator -db=postgres-product -type=schema -action=up
```

---

## 📖 เอกสารเพิ่มเติม

- [README.md](README.md) - ภาพรวมโปรเจค
- [examples/README.md](examples/README.md) - ตัวอย่างและ data types ทั้งหมด
- [SMART_MIGRATION.md](SMART_MIGRATION.md) - Smart migration system
- [HOW_TO_ADD_NEW_DATABASE.md](HOW_TO_ADD_NEW_DATABASE.md) - เพิ่ม database ใหม่

---

## 🎯 Tips & Best Practices

### 1. ใช้ naming conventions ที่เหมาะสม

```yaml
# PostgreSQL - snake_case
table:
  name: user_profiles
  columns:
    - name: user_id
    - name: created_at

# MongoDB - camelCase
collection:
  name: userProfiles
  properties:
    userId: ...
    createdAt: ...
```

### 2. ระบุ default values

```yaml
columns:
  - name: status
    type: VARCHAR(20)
    default: "'active'"  # String ต้องมี quotes
  
  - name: count
    type: INTEGER
    default: 0  # Number ไม่ต้องมี quotes
  
  - name: created_at
    type: TIMESTAMP
    default: CURRENT_TIMESTAMP  # Functions ไม่ต้องมี quotes
```

### 3. สร้าง indexes ที่เหมาะสม

```yaml
indexes:
  # Unique fields
  - name: idx_users_email
    columns: [email]
    unique: true
  
  # Frequently queried fields
  - name: idx_users_status
    columns: [status]
  
  # JSONB search
  - name: idx_users_metadata
    columns: [metadata]
    type: GIN
```

### 4. ใช้ constraints เพื่อ data integrity

```yaml
constraints:
  - type: CHECK
    expression: "price >= 0"
  
  - type: CHECK
    expression: "stock >= 0"
  
  - type: CHECK
    expression: "status IN ('pending', 'active', 'completed')"
```

---

## ❏ Troubleshooting

### Migration ถูกสร้างแล้ว แต่มีข้อผิดพลาด

ตรวจสอบ syntax ใน YAML:
- Indentation ถูกต้อง (ใช้ spaces ไม่ใช้ tabs)
- String values ที่มี special characters ต้อง quote
- Array syntax: `[item1, item2]`
- Object syntax: `{key: value}`

---

## 📞 Support

หากมีปัญหาหรือข้อสงสัย กรุณาดูที่:
- [examples/README.md](examples/README.md) - ตัวอย่างครบถ้วน
- [README.md](README.md) - คู่มือหลัก
