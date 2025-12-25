# Migration Generator

Go-based migration file generator from YAML templates.

## Build

```bash
go build -o generator ./cmd/generator/main.go
```

Or use the Makefile:

```bash
make build-generator
```

## Usage

```bash
./generator <schema.yaml>
```

### Examples

```bash
# PostgreSQL
./generator examples/postgres-simple-table.yaml

# MongoDB
./generator examples/mongo-simple-collection.yaml
```

Or use Makefile:

```bash
make generate FILE=examples/postgres-simple-table.yaml
```

## Features

- ✅ No external dependencies (yq, Python, PyYAML not needed)
- ⚡ Fast compiled binary
- 🛠️ Type-safe YAML parsing
- 📦 Single portable binary
- 🎉 Written in Go like the migrator

## Documentation

See [GENERATOR.md](../../GENERATOR.md) for complete documentation and examples.
