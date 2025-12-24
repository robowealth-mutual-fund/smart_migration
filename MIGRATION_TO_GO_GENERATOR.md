# Migration from Bash Script to Go Generator

## การใช้งาน


### (Go Generator)
```bash
# ไม่ต้องติดตั้งอะไรเพิ่ม (มี Go อยู่แล้ว)

# ใช้งานผ่าน Makefile (แนะนำ)
make generate FILE=examples/postgres-simple-table.yaml

# หรือใช้โดยตรง
go build -o generator ./cmd/generator/main.go
./generator examples/postgres-simple-table.yaml
```

## Breaking Changes

**ไม่มี!** การใช้งานยังเหมือนเดิม:
- YAML format เหมือนเดิม 100%
- Output files เหมือนเดิม
- Makefile command เหมือนเดิม (`make generate FILE=...`)

## ไฟล์ที่เพิ่ม

```
cmd/
└── generator/
    ├── main.go        # Go generator implementation
    └── README.md      # Generator documentation
```

## ไฟล์ที่เปลี่ยน

- `Makefile` - เพิ่ม `build-generator` target, เปลี่ยน `generate` ให้ใช้ Go
- `GENERATOR.md` - อัพเดทเอกสารให้สะท้อน Go implementation
- `README.md` - อัพเดท Migration Generator section
- `CHANGELOG.md` - บันทึกการเปลี่ยนแปลง
- `.gitignore` - เพิ่ม `generator` binary และ `*.bak`

## ไฟล์ที่ลบ/ย้าย

- `generate-migration.sh` → `generate-migration.sh.bak` (backup)

## ทดสอบ

```bash
# Clean old binaries
make clean

# Test PostgreSQL
make generate FILE=examples/postgres-simple-table.yaml

# Test MongoDB  
make generate FILE=examples/mongo-simple-collection.yaml

# Test complex example
make generate FILE=examples/ecommerce-product.yaml

# ✅ ทั้งหมดควรทำงานได้ตามปกติ!
```

## Rollback (ถ้าต้องการ)

```bash
# Restore bash script
mv generate-migration.sh.bak generate-migration.sh

# Revert Makefile changes
git checkout Makefile

# ติดตั้ง dependencies
brew install yq
pip3 install pyyaml
```

แต่ไม่น่าจะต้อง rollback เพราะ Go generator ดีกว่าทุกด้าน! 🎉

## Support

หากพบปัญหา:
1. ตรวจสอบว่ามี Go 1.25+ (`go version`)
2. ลอง `make clean && make generate FILE=...`
3. ดู error message จาก generator
4. อ่าน [GENERATOR.md](GENERATOR.md) สำหรับรายละเอียด

## Next Steps

Generator ที่เป็น Go นี้สามารถขยายความสามารถได้ง่าย:
- ✅ Support constraints (CHECK, UNIQUE, etc.)
- ✅ Support foreign keys
- 🔄 Validate YAML schema
- 🔄 Generate test data
- 🔄 Auto-generate API models from schema
- 🔄 Database diff tool
