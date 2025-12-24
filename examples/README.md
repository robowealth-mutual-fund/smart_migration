# Migration Generator - Examples & Templates

ตัวอย่างและ Templates สำหรับสร้าง migrations อัตโนมัติจาก YAML

## 🚀 การใช้งาน

```bash
# Generate migration from YAML
./generate-migration.sh examples/postgres-simple-table.yaml

# จะสร้างไฟล์:
# - migrations/postgres-product/schema/000003_customers.up.sql
# - migrations/postgres-product/schema/000003_customers.down.sql
```

---

## 📋 PostgreSQL Data Types

### Numeric Types

```yaml
columns:
  # Auto-increment
  - name: id
    type: SERIAL  # 1 to 2,147,483,647
    
  - name: big_id
    type: BIGSERIAL  # 1 to 9,223,372,036,854,775,807
    
  # Integers
  - name: small_num
    type: SMALLINT  # -32768 to 32767
    
  - name: int_num
    type: INTEGER  # -2147483648 to 2147483647
    
  - name: big_num
    type: BIGINT  # -9223372036854775808 to 9223372036854775807
    
  # Decimals
  - name: price
    type: DECIMAL(10,2)  # 10 digits total, 2 after decimal
    
  - name: precise_num
    type: NUMERIC(15,5)
    
  # Floating point
  - name: float_num
    type: REAL  # 6 decimal digits precision
    
  - name: double_num
    type: DOUBLE PRECISION  # 15 decimal digits precision
```

### String Types

```yaml
columns:
  - name: short_text
    type: VARCHAR(255)  # Variable length, max 255
    
  - name: fixed_text
    type: CHAR(10)  # Fixed length, padded with spaces
    
  - name: long_text
    type: TEXT  # Unlimited length
    
  - name: tiny_text
    type: VARCHAR(50)
```

### Boolean

```yaml
columns:
  - name: is_active
    type: BOOLEAN
    default: true
    
  - name: is_verified
    type: BOOLEAN
    default: false
```

### Date/Time Types

```yaml
columns:
  - name: birth_date
    type: DATE  # Date only (YYYY-MM-DD)
    
  - name: start_time
    type: TIME  # Time only (HH:MM:SS)
    
  - name: created_at
    type: TIMESTAMP  # Date + Time (no timezone)
    default: CURRENT_TIMESTAMP
    
  - name: updated_at
    type: TIMESTAMPTZ  # Date + Time (with timezone)
    default: CURRENT_TIMESTAMP
    
  - name: duration
    type: INTERVAL  # Time interval
```

### JSON Types

```yaml
columns:
  # Standard JSON
  - name: metadata
    type: JSON
    
  # Binary JSON (faster, supports indexing)
  - name: settings
    type: JSONB
    
# Index for JSONB
indexes:
  - name: idx_settings
    columns: [settings]
    type: GIN
```

### Array Types

```yaml
columns:
  - name: tags
    type: TEXT[]
    
  - name: scores
    type: INTEGER[]
    
  - name: prices
    type: DECIMAL(10,2)[]
```

### UUID

```yaml
columns:
  - name: uuid_id
    type: UUID
    default: gen_random_uuid()
```

### Binary Data

```yaml
columns:
  - name: file_data
    type: BYTEA  # Binary data
```

### Network Types

```yaml
columns:
  - name: ip_addr
    type: INET  # IPv4 or IPv6
    
  - name: mac_addr
    type: MACADDR  # MAC address
    
  - name: cidr_addr
    type: CIDR  # Network address
```

### Other Types

```yaml
columns:
  - name: location
    type: POINT  # Geometric point
    
  - name: price_money
    type: MONEY  # Currency amount
    
  - name: xml_doc
    type: XML  # XML data
```

---

## 📋 MongoDB Data Types (BSON)

### String

```yaml
properties:
  name:
    bsonType: string
    description: "User name"
    minLength: 3
    maxLength: 100
```

### Numbers

```yaml
properties:
  # Integer (32-bit)
  count:
    bsonType: int
    minimum: 0
    maximum: 1000
    
  # Long (64-bit)
  big_count:
    bsonType: long
    
  # Double (floating point)
  price:
    bsonType: double
    minimum: 0
    
  # Decimal128 (high precision)
  precise_price:
    bsonType: decimal
```

### Boolean

```yaml
properties:
  isActive:
    bsonType: bool
```

### Date

```yaml
properties:
  createdAt:
    bsonType: date
    description: "Creation timestamp"
```

### ObjectId

```yaml
properties:
  _id:
    bsonType: objectId
  userId:
    bsonType: objectId
```

### Array

```yaml
properties:
  tags:
    bsonType: array
    items:
      bsonType: string
    minItems: 0
    maxItems: 10
    uniqueItems: true
```

### Object (Nested Document)

```yaml
properties:
  address:
    bsonType: object
    required: [city, country]
    properties:
      street:
        bsonType: string
      city:
        bsonType: string
      country:
        bsonType: string
      postalCode:
        bsonType: string
```

### Binary Data

```yaml
properties:
  fileData:
    bsonType: binData
```

### Null

```yaml
properties:
  optionalField:
    bsonType: ["string", "null"]
```

### Multiple Types

```yaml
properties:
  mixedField:
    bsonType: ["string", "int", "double"]
```

### Enum

```yaml
properties:
  status:
    bsonType: string
    enum: [pending, active, completed, cancelled]
```

---

## 🎯 ตัวอย่างการใช้งาน

### Example 1: E-commerce Product Table

`examples/ecommerce-product.yaml`
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
    - name: description
      type: TEXT
    - name: price
      type: DECIMAL(10,2)
      not_null: true
    - name: stock
      type: INTEGER
      default: 0
    - name: is_active
      type: BOOLEAN
      default: true
    - name: metadata
      type: JSONB
    - name: images
      type: TEXT[]
    - name: created_at
      type: TIMESTAMPTZ
      default: CURRENT_TIMESTAMP

  indexes:
    - name: idx_products_sku
      columns: [sku]
      unique: true
    - name: idx_products_name
      columns: [name]
    - name: idx_products_metadata
      columns: [metadata]
      type: GIN
```

### Example 2: User Profile (MongoDB)

`examples/user-profile-mongo.yaml`
```yaml
database:
  type: mongo
  name: user

collection:
  name: profiles
  validator:
    $jsonSchema:
      bsonType: object
      required: [userId, email, createdAt]
      properties:
        userId:
          bsonType: objectId
        email:
          bsonType: string
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        name:
          bsonType: object
          properties:
            first:
              bsonType: string
            last:
              bsonType: string
        age:
          bsonType: int
          minimum: 0
          maximum: 150
        tags:
          bsonType: array
          items:
            bsonType: string
        address:
          bsonType: object
          properties:
            street:
              bsonType: string
            city:
              bsonType: string
            country:
              bsonType: string
        settings:
          bsonType: object
        createdAt:
          bsonType: date
```

---

## 🛠️ Advanced Features

### PostgreSQL Constraints

```yaml
table:
  name: orders
  columns:
    - name: id
      type: SERIAL
      primary_key: true
    - name: user_id
      type: INTEGER
      not_null: true
    - name: total
      type: DECIMAL(10,2)
      not_null: true
    - name: status
      type: VARCHAR(20)
      not_null: true
      default: "'pending'"
      
  # Check constraints
  constraints:
    - type: CHECK
      expression: "total >= 0"
    - type: CHECK
      expression: "status IN ('pending', 'completed', 'cancelled')"
      
  # Foreign keys
  foreign_keys:
    - column: user_id
      references: users(id)
      on_delete: CASCADE
      on_update: CASCADE
```

### MongoDB Indexes

```yaml
collection:
  name: products
  validator:
    # ... validator schema ...
    
  indexes:
    - keys: {sku: 1}
      unique: true
    - keys: {name: "text"}  # Text index for full-text search
    - keys: {createdAt: -1}  # Descending
    - keys: {category: 1, price: -1}  # Compound index
```

---

## 💡 Tips

### 1. Naming Conventions

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

### 2. Default Values

```yaml
# PostgreSQL
- name: created_at
  type: TIMESTAMP
  default: CURRENT_TIMESTAMP

- name: status
  type: VARCHAR(20)
  default: "'active'"  # Note: string values need quotes

- name: count
  type: INTEGER
  default: 0
```

### 3. Indexes

```yaml
# Single column
indexes:
  - name: idx_email
    columns: [email]
    unique: true

# Multiple columns
indexes:
  - name: idx_user_created
    columns: [user_id, created_at]

# JSONB index (PostgreSQL)
indexes:
  - name: idx_metadata
    columns: [metadata]
    type: GIN
```

---

## 📚 สรุป Data Types

### PostgreSQL

| Type | Size | Range/Description |
|------|------|-------------------|
| SMALLINT | 2 bytes | -32768 to 32767 |
| INTEGER | 4 bytes | -2B to 2B |
| BIGINT | 8 bytes | -9E18 to 9E18 |
| DECIMAL(p,s) | variable | Exact numeric |
| REAL | 4 bytes | 6 decimal digits |
| DOUBLE PRECISION | 8 bytes | 15 decimal digits |
| VARCHAR(n) | variable | Variable length string |
| TEXT | variable | Unlimited length |
| BOOLEAN | 1 byte | true/false |
| DATE | 4 bytes | Date only |
| TIMESTAMP | 8 bytes | Date + time |
| JSON/JSONB | variable | JSON data |
| UUID | 16 bytes | Universally unique ID |

### MongoDB BSON

| Type | Description |
|------|-------------|
| string | UTF-8 string |
| int | 32-bit integer |
| long | 64-bit integer |
| double | 64-bit floating point |
| decimal | 128-bit decimal |
| bool | Boolean |
| date | UTC datetime |
| objectId | 12-byte ObjectId |
| array | Array of values |
| object | Embedded document |
| binData | Binary data |

---

## 🔗 เอกสารเพิ่มเติม

- [PostgreSQL Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [MongoDB BSON Types](https://docs.mongodb.com/manual/reference/bson-types/)
- [How to Add New Database](../HOW_TO_ADD_NEW_DATABASE.md)
