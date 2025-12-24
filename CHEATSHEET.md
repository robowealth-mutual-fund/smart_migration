# Migration Generator - Quick Reference 📋

## ตัวอย่างการใช้งานด่วน

### สร้าง Migration จาก YAML

```bash
# PostgreSQL
make generate FILE=examples/postgres-simple-table.yaml

# MongoDB
make generate FILE=examples/mongo-simple-collection.yaml

# หรือใช้ script โดยตรง
./generate-migration.sh my-schema.yaml
```

---

## PostgreSQL Quick Reference

### Basic Table

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
    - name: name
      type: VARCHAR(100)
      not_null: true
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

### Common Data Types

```yaml
# Numeric
- name: id
  type: SERIAL              # Auto-increment
- name: price
  type: DECIMAL(10,2)       # Money
- name: count
  type: INTEGER             # Number

# String
- name: name
  type: VARCHAR(255)        # Short text
- name: description
  type: TEXT                # Long text

# Boolean
- name: is_active
  type: BOOLEAN
  default: true

# Date/Time
- name: created_at
  type: TIMESTAMPTZ
  default: CURRENT_TIMESTAMP

# JSON
- name: metadata
  type: JSONB               # Binary JSON (recommended)

# Array
- name: tags
  type: TEXT[]              # Array of strings
```

### Indexes

```yaml
indexes:
  # Simple unique index
  - name: idx_users_email
    columns: [email]
    unique: true
  
  # Compound index
  - name: idx_users_name_email
    columns: [name, email]
  
  # JSONB index
  - name: idx_users_metadata
    columns: [metadata]
    type: GIN
```

### Constraints

```yaml
columns:
  - name: status
    type: VARCHAR(20)
    default: "'pending'"     # String needs quotes!
    
constraints:
  - type: CHECK
    expression: "price >= 0"
  - type: CHECK
    expression: "status IN ('pending', 'active', 'completed')"
```

### Foreign Keys

```yaml
columns:
  - name: user_id
    type: INTEGER
    not_null: true

foreign_keys:
  - column: user_id
    references: users(id)
    on_delete: CASCADE
    on_update: CASCADE
```

---

## MongoDB Quick Reference

### Basic Collection

```yaml
database:
  type: mongo
  name: user

collection:
  name: users
  validator:
    $jsonSchema:
      bsonType: object
      required: [email, name]
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
        isActive:
          bsonType: bool
        createdAt:
          bsonType: date
  
  indexes:
    - keys: {email: 1}
      unique: true
    - keys: {name: "text"}
```

### Common BSON Types

```yaml
properties:
  # String
  name:
    bsonType: string
    minLength: 3
    maxLength: 100
  
  # Numbers
  count:
    bsonType: int           # 32-bit integer
  bigCount:
    bsonType: long          # 64-bit integer
  price:
    bsonType: double        # Floating point
  precisePrice:
    bsonType: decimal       # High precision
  
  # Boolean
  isActive:
    bsonType: bool
  
  # Date
  createdAt:
    bsonType: date
  
  # ObjectId
  userId:
    bsonType: objectId
  
  # Array
  tags:
    bsonType: array
    items:
      bsonType: string
    uniqueItems: true
  
  # Object (nested)
  address:
    bsonType: object
    properties:
      city:
        bsonType: string
      country:
        bsonType: string
```

### Enum Validation

```yaml
status:
  bsonType: string
  enum: [pending, active, completed, cancelled]
```

### Email/Pattern Validation

```yaml
email:
  bsonType: string
  pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

phone:
  bsonType: string
  pattern: "^[0-9]{10}$"

postalCode:
  bsonType: string
  pattern: "^[0-9]{5}$"
```

### Indexes

```yaml
indexes:
  # Unique index
  - keys: {email: 1}
    unique: true
  
  # Text search index
  - keys: {name: "text"}
  
  # Compound index
  - keys: {category: 1, price: -1}
  
  # Nested field index
  - keys: {"address.city": 1}
```

---

## Migration Commands

### Run Migrations

```bash
# Smart migration (only changed files)
make migrate-changed

# All databases
make migrate-all-dbs

# Specific database
POSTGRES_DSN="postgres://user:pass@host:5432/product?sslmode=disable" \
  ./migrator -db=postgres-product -type=schema -action=up

# Rollback
./migrator -db=postgres-product -type=schema -action=down -steps=1
```

### Local Development

```bash
# Run PostgreSQL schema
make run-postgres-schema

# Run MongoDB schema
make run-mongo-schema

# Run all
make run
```

### Docker

```bash
# Build
make docker-build

# Run
make docker-run POSTGRES_DSN="..." MONGO_URI="..."
```

### Kubernetes

```bash
# Create secret
make k8s-create-secret

# Apply migration job
make k8s-apply

# View logs
make k8s-logs

# Check status
make k8s-status

# Delete jobs
make k8s-delete
```

---

## Common Patterns

### E-commerce Product

```yaml
database:
  type: postgres
  name: product

table:
  name: products
  columns:
    - name: id
      type: SERIAL
      primary_key: true
    - name: sku
      type: VARCHAR(100)
      not_null: true
      unique: true
    - name: name
      type: VARCHAR(255)
      not_null: true
    - name: price
      type: DECIMAL(10,2)
      not_null: true
    - name: stock
      type: INTEGER
      default: 0
    - name: metadata
      type: JSONB
    - name: tags
      type: TEXT[]
    - name: created_at
      type: TIMESTAMPTZ
      default: CURRENT_TIMESTAMP
```

### User Profile (MongoDB)

```yaml
database:
  type: mongo
  name: user

collection:
  name: profiles
  validator:
    $jsonSchema:
      bsonType: object
      required: [userId, email]
      properties:
        userId:
          bsonType: objectId
        email:
          bsonType: string
          pattern: "^.+@.+\\..+$"
        name:
          bsonType: object
          properties:
            first:
              bsonType: string
            last:
              bsonType: string
        tags:
          bsonType: array
          items:
            bsonType: string
        createdAt:
          bsonType: date
```

---

## Tips

### 1. String Default Values Need Quotes

```yaml
# ❌ Wrong
default: pending

# ✅ Correct
default: "'pending'"
```

### 2. Naming Conventions

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

### 3. Always Create Indexes for

```yaml
# Unique fields
- email
- username
- sku

# Foreign keys
- user_id
- product_id

# Frequently queried fields
- status
- created_at
- category
```

### 4. JSONB vs JSON (PostgreSQL)

```yaml
# Use JSONB (binary) - supports indexing, faster queries
- name: metadata
  type: JSONB

# Use JSON (text) - only if you need exact formatting
- name: raw_data
  type: JSON
```

---

## Data Type Sizes

### PostgreSQL

| Type | Size | Range |
|------|------|-------|
| SMALLINT | 2 bytes | -32K to 32K |
| INTEGER | 4 bytes | -2B to 2B |
| BIGINT | 8 bytes | -9E18 to 9E18 |
| DECIMAL(10,2) | variable | Exact numeric |
| VARCHAR(255) | variable | Up to 255 chars |
| TEXT | variable | Unlimited |
| BOOLEAN | 1 byte | true/false |
| TIMESTAMPTZ | 8 bytes | Date + time + timezone |
| JSONB | variable | Binary JSON |
| UUID | 16 bytes | Unique ID |

### MongoDB

| Type | Description |
|------|-------------|
| string | UTF-8 string |
| int | 32-bit integer |
| long | 64-bit integer |
| double | 64-bit float |
| decimal | 128-bit decimal |
| bool | Boolean |
| date | UTC datetime |
| objectId | 12-byte ID |
| array | Array of values |
| object | Embedded doc |

---

## Troubleshooting

### Generator not found

```bash
# Check if script exists
ls -la generate-migration.sh

# Make executable
chmod +x generate-migration.sh
```

### yq not found

```bash
# macOS
brew install yq

# Linux
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq
```

### PyYAML not found

```bash
pip3 install pyyaml
```

### Migration file syntax error

Check:
- YAML indentation (use spaces, not tabs)
- String values with special chars need quotes
- Array syntax: `[item1, item2]`
- Default string values: `"'value'"`

---

## Quick Links

- [Full Documentation](README.md)
- [Generator Guide](GENERATOR.md)
- [Examples & All Data Types](examples/README.md)
- [Smart Migration](SMART_MIGRATION.md)
- [Add New Database](HOW_TO_ADD_NEW_DATABASE.md)
