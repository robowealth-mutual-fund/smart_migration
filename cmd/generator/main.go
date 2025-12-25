package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"gopkg.in/yaml.v3"
)

type Schema struct {
	Database      Database    `yaml:"database"`
	Table         *Table      `yaml:"table,omitempty"`
	Collection    *Collection `yaml:"collection,omitempty"`
	MigrationType string      `yaml:"migration_type,omitempty"`
}

type Database struct {
	Type string `yaml:"type"`
	Name string `yaml:"name"`
}

type Table struct {
	Name        string       `yaml:"name"`
	Columns     []Column     `yaml:"columns"`
	Indexes     []Index      `yaml:"indexes,omitempty"`
	ForeignKeys []ForeignKey `yaml:"foreign_keys,omitempty"`
	Constraints []Constraint `yaml:"constraints,omitempty"`
}

type Column struct {
	Name       string      `yaml:"name"`
	Type       string      `yaml:"type"`
	PrimaryKey bool        `yaml:"primary_key,omitempty"`
	NotNull    bool        `yaml:"not_null,omitempty"`
	Unique     bool        `yaml:"unique,omitempty"`
	Default    interface{} `yaml:"default,omitempty"`
}

type Index struct {
	Name    string   `yaml:"name"`
	Columns []string `yaml:"columns"`
	Unique  bool     `yaml:"unique,omitempty"`
	Type    string   `yaml:"type,omitempty"`
}

type ForeignKey struct {
	Column     string `yaml:"column"`
	References string `yaml:"references"`
	OnDelete   string `yaml:"on_delete,omitempty"`
	OnUpdate   string `yaml:"on_update,omitempty"`
}

type Constraint struct {
	Type       string `yaml:"type"`
	Expression string `yaml:"expression"`
}

type Collection struct {
	Name      string                 `yaml:"name"`
	Validator map[string]interface{} `yaml:"validator,omitempty"`
	Indexes   []MongoIndex           `yaml:"indexes,omitempty"`
}

type MongoIndex struct {
	Keys   map[string]interface{} `yaml:"keys"`
	Unique bool                   `yaml:"unique,omitempty"`
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: generator <schema.yaml>")
		fmt.Println("")
		fmt.Println("Examples:")
		fmt.Println("  generator examples/postgres-table.yaml")
		fmt.Println("  generator examples/mongo-collection.yaml")
		os.Exit(1)
	}

	schemaFile := os.Args[1]
	if _, err := os.Stat(schemaFile); os.IsNotExist(err) {
		fmt.Printf("Error: File '%s' not found\n", schemaFile)
		os.Exit(1)
	}

	fmt.Printf("🚀 Generating migration from %s...\n\n", schemaFile)

	// Parse YAML
	data, err := os.ReadFile(schemaFile)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}

	var schema Schema
	if err := yaml.Unmarshal(data, &schema); err != nil {
		fmt.Printf("Error parsing YAML: %v\n", err)
		os.Exit(1)
	}

	// Determine migration directory and table name
	var migrationDir, tableName string
	if schema.Database.Type == "postgres" {
		migrationDir = fmt.Sprintf("migrations/postgres-%s/schema", schema.Database.Name)
		if schema.Table != nil {
			tableName = schema.Table.Name
		}
	} else {
		migrationDir = fmt.Sprintf("migrations/mongo-%s/schema", schema.Database.Name)
		if schema.Collection != nil {
			tableName = schema.Collection.Name
		}
	}

	// Create migration directory
	if err := os.MkdirAll(migrationDir, 0755); err != nil {
		fmt.Printf("Error creating directory: %v\n", err)
		os.Exit(1)
	}

	// Get next version number
	nextVersion := getNextVersion(migrationDir)
	migrationName := fmt.Sprintf("%06d_%s", nextVersion, strings.ToLower(strings.ReplaceAll(tableName, " ", "_")))

	// Generate migration files
	if schema.Database.Type == "postgres" {
		if err := generatePostgresMigration(schema, migrationDir, migrationName); err != nil {
			fmt.Printf("Error generating PostgreSQL migration: %v\n", err)
			os.Exit(1)
		}
	} else {
		if err := generateMongoMigration(schema, migrationDir, migrationName); err != nil {
			fmt.Printf("Error generating MongoDB migration: %v\n", err)
			os.Exit(1)
		}
	}

	fmt.Println("")
	fmt.Println("🎉 Migration generated successfully!")
	fmt.Println("")
	fmt.Println("Next steps:")
	fmt.Printf("  1. Review the generated files\n")
	fmt.Printf("  2. git add %s/%s*\n", migrationDir, migrationName)
	fmt.Printf("  3. make migrate-changed\n")
}

func getNextVersion(dir string) int {
	files, err := os.ReadDir(dir)
	if err != nil {
		return 1
	}

	versions := []int{}
	for _, file := range files {
		name := file.Name()
		if strings.Contains(name, "_") {
			parts := strings.Split(name, "_")
			if version, err := strconv.Atoi(parts[0]); err == nil {
				versions = append(versions, version)
			}
		}
	}

	if len(versions) == 0 {
		return 1
	}

	sort.Ints(versions)
	return versions[len(versions)-1] + 1
}

func generatePostgresMigration(schema Schema, dir, name string) error {
	if schema.Table == nil {
		return fmt.Errorf("table definition is required for PostgreSQL")
	}

	table := schema.Table
	upSQL := generatePostgresUp(table)
	downSQL := generatePostgresDown(table)

	// Write UP migration
	upFile := filepath.Join(dir, name+".up.sql")
	if err := os.WriteFile(upFile, []byte(upSQL), 0644); err != nil {
		return err
	}

	// Write DOWN migration
	downFile := filepath.Join(dir, name+".down.sql")
	if err := os.WriteFile(downFile, []byte(downSQL), 0644); err != nil {
		return err
	}

	fmt.Printf("✅ Generated PostgreSQL migrations:\n")
	fmt.Printf("  - %s\n", upFile)
	fmt.Printf("  - %s\n", downFile)

	return nil
}

func generatePostgresUp(table *Table) string {
	var lines []string

	// CREATE TABLE
	lines = append(lines, fmt.Sprintf("-- Create %s table", table.Name))
	lines = append(lines, fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s (", table.Name))

	// Columns
	colDefs := []string{}
	for _, col := range table.Columns {
		colDef := fmt.Sprintf("    %s %s", col.Name, col.Type)
		if col.PrimaryKey {
			colDef += " PRIMARY KEY"
		}
		if col.NotNull {
			colDef += " NOT NULL"
		}
		if col.Unique {
			colDef += " UNIQUE"
		}
		if col.Default != nil {
			colDef += fmt.Sprintf(" DEFAULT %v", col.Default)
		}
		colDefs = append(colDefs, colDef)
	}

	lines = append(lines, strings.Join(colDefs, ",\n"))
	lines = append(lines, ");")
	lines = append(lines, "")

	// Indexes
	for _, idx := range table.Indexes {
		unique := ""
		if idx.Unique {
			unique = "UNIQUE "
		}
		idxType := ""
		if idx.Type != "" {
			idxType = " USING " + idx.Type
		}
		cols := strings.Join(idx.Columns, ", ")
		lines = append(lines, fmt.Sprintf("CREATE %sINDEX IF NOT EXISTS %s ON %s%s (%s);", unique, idx.Name, table.Name, idxType, cols))
	}

	// Foreign Keys
	for _, fk := range table.ForeignKeys {
		line := fmt.Sprintf("ALTER TABLE %s ADD CONSTRAINT fk_%s_%s FOREIGN KEY (%s) REFERENCES %s",
			table.Name, table.Name, fk.Column, fk.Column, fk.References)
		if fk.OnDelete != "" {
			line += " ON DELETE " + fk.OnDelete
		}
		if fk.OnUpdate != "" {
			line += " ON UPDATE " + fk.OnUpdate
		}
		line += ";"
		lines = append(lines, line)
	}

	// Constraints
	for _, constraint := range table.Constraints {
		lines = append(lines, fmt.Sprintf("ALTER TABLE %s ADD CONSTRAINT chk_%s CHECK (%s);",
			table.Name, strings.ToLower(strings.ReplaceAll(constraint.Expression, " ", "_"))[:20], constraint.Expression))
	}

	return strings.Join(lines, "\n")
}

func generatePostgresDown(table *Table) string {
	var lines []string

	lines = append(lines, fmt.Sprintf("-- Drop %s table", table.Name))

	// Drop indexes in reverse order
	for i := len(table.Indexes) - 1; i >= 0; i-- {
		lines = append(lines, fmt.Sprintf("DROP INDEX IF EXISTS %s;", table.Indexes[i].Name))
	}

	lines = append(lines, fmt.Sprintf("DROP TABLE IF EXISTS %s;", table.Name))

	return strings.Join(lines, "\n")
}

func generateMongoMigration(schema Schema, dir, name string) error {
	if schema.Collection == nil {
		return fmt.Errorf("collection definition is required for MongoDB")
	}

	collection := schema.Collection

	// Generate UP migration
	upData, err := yaml.Marshal([]map[string]interface{}{
		{
			"create":    collection.Name,
			"validator": collection.Validator,
		},
	})
	if err != nil {
		return err
	}

	upFile := filepath.Join(dir, name+".up.js")
	if err := os.WriteFile(upFile, upData, 0644); err != nil {
		return err
	}

	// Generate DOWN migration
	downData, err := yaml.Marshal([]map[string]interface{}{
		{
			"drop": collection.Name,
		},
	})
	if err != nil {
		return err
	}

	downFile := filepath.Join(dir, name+".down.js")
	if err := os.WriteFile(downFile, downData, 0644); err != nil {
		return err
	}

	fmt.Printf("✅ Generated MongoDB migrations:\n")
	fmt.Printf("  - %s\n", upFile)
	fmt.Printf("  - %s\n", downFile)

	return nil
}
