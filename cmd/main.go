package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"fundii-database-migration/internal/config"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/mongodb"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	// Parse command line flags
	dbType := flag.String("db", "all", "Database type: postgres, mongo, or all")
	migrationType := flag.String("type", "schema", "Migration type: schema, seed, or all")
	action := flag.String("action", "up", "Migration action: up, down, or version")
	steps := flag.Int("steps", 0, "Number of migration steps (for down action, 0 means all)")
	verbose := flag.Bool("verbose", false, "Enable verbose logging")
	flag.Parse()

	// Load config
	cfg := config.LoadConfig()

	if *verbose {
		log.Printf("Configuration loaded: DB=%s, Type=%s, Action=%s", *dbType, *migrationType, *action)
	}

	// Run migrations based on flags
	if *dbType == "postgres" || *dbType == "all" {
		if err := runPostgresMigration(cfg, *migrationType, *action, *steps, *verbose); err != nil {
			log.Fatalf("Postgres migration failed: %v", err)
		}
	}

	if *dbType == "mongo" || *dbType == "all" {
		if err := runMongoMigration(cfg, *migrationType, *action, *steps, *verbose); err != nil {
			log.Fatalf("MongoDB migration failed: %v", err)
		}
	}

	log.Println("✓ Migration completed successfully")
}

func runPostgresMigration(cfg *config.Config, migrationType, action string, steps int, verbose bool) error {
	if cfg.PostgresDSN == "" {
		log.Println("⚠ POSTGRES_DSN not set, skipping Postgres migration")
		return nil
	}

	if verbose {
		log.Println("→ Starting Postgres migration...")
	}

	// Connect to PostgreSQL
	db, err := sql.Open("postgres", cfg.PostgresDSN)
	if err != nil {
		return fmt.Errorf("failed to open postgres connection: %w", err)
	}
	defer db.Close()

	// Test connection
	if err := db.Ping(); err != nil {
		return fmt.Errorf("failed to ping postgres: %w", err)
	}

	if verbose {
		log.Println("✓ Connected to PostgreSQL")
	}

	paths := getMigrationPaths("postgres", migrationType)
	for _, path := range paths {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			if verbose {
				log.Printf("⚠ Path %s does not exist, skipping", path)
			}
			continue
		}

		if verbose {
			log.Printf("→ Running migration from: %s", path)
		}

		driver, err := postgres.WithInstance(db, &postgres.Config{})
		if err != nil {
			return fmt.Errorf("failed to create postgres driver: %w", err)
		}

		m, err := migrate.NewWithDatabaseInstance(
			fmt.Sprintf("file://%s", path),
			"postgres", driver,
		)
		if err != nil {
			return fmt.Errorf("failed to create migrate instance: %w", err)
		}
		defer m.Close()

		if err := executeMigration(m, action, steps, verbose); err != nil {
			return fmt.Errorf("migration execution failed: %w", err)
		}
	}

	if verbose {
		log.Println("✓ Postgres migration completed")
	}
	return nil
}

func runMongoMigration(cfg *config.Config, migrationType, action string, steps int, verbose bool) error {
	if cfg.MongoURI == "" {
		log.Println("⚠ MONGO_URI not set, skipping MongoDB migration")
		return nil
	}

	if verbose {
		log.Println("→ Starting MongoDB migration...")
	}

	// Connect to MongoDB
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(cfg.MongoURI))
	if err != nil {
		return fmt.Errorf("failed to connect to mongodb: %w", err)
	}
	defer func() {
		if err := client.Disconnect(context.Background()); err != nil {
			log.Printf("⚠ Error disconnecting from MongoDB: %v", err)
		}
	}()

	// Test connection
	if err := client.Ping(ctx, nil); err != nil {
		return fmt.Errorf("failed to ping mongodb: %w", err)
	}

	if verbose {
		log.Println("✓ Connected to MongoDB")
	}

	paths := getMigrationPaths("mongo", migrationType)
	for _, path := range paths {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			if verbose {
				log.Printf("⚠ Path %s does not exist, skipping", path)
			}
			continue
		}

		if verbose {
			log.Printf("→ Running migration from: %s", path)
		}

		driver, err := mongodb.WithInstance(client, &mongodb.Config{
			DatabaseName: extractDBNameFromURI(cfg.MongoURI),
		})
		if err != nil {
			return fmt.Errorf("failed to create mongodb driver: %w", err)
		}

		m, err := migrate.NewWithDatabaseInstance(
			fmt.Sprintf("file://%s", path),
			"mongodb", driver,
		)
		if err != nil {
			return fmt.Errorf("failed to create migrate instance: %w", err)
		}
		defer m.Close()

		if err := executeMigration(m, action, steps, verbose); err != nil {
			return fmt.Errorf("migration execution failed: %w", err)
		}
	}

	if verbose {
		log.Println("✓ MongoDB migration completed")
	}
	return nil
}

func getMigrationPaths(dbType, migrationType string) []string {
	basePath := fmt.Sprintf("migrations/%s", dbType)

	switch migrationType {
	case "schema":
		return []string{fmt.Sprintf("%s/schema", basePath)}
	case "seed":
		return []string{fmt.Sprintf("%s/seed", basePath)}
	case "all":
		return []string{
			fmt.Sprintf("%s/schema", basePath),
			fmt.Sprintf("%s/seed", basePath),
		}
	default:
		return []string{basePath}
	}
}

func extractDBNameFromURI(uri string) string {
	// Simple extraction of database name from MongoDB URI
	// Format: mongodb://host:port/dbname or mongodb://user:pass@host:port/dbname
	if len(uri) == 0 {
		return "test"
	}

	// Find the last slash and extract database name
	parts := strings.Split(uri, "/")
	if len(parts) >= 4 {
		// Remove query parameters if any
		dbName := strings.Split(parts[3], "?")[0]
		if dbName != "" {
			return dbName
		}
	}
	return "test"
}

func executeMigration(m *migrate.Migrate, action string, steps int, verbose bool) error {
	switch action {
	case "up":
		err := m.Up()
		if err != nil && err != migrate.ErrNoChange {
			return err
		}
		if err == migrate.ErrNoChange && verbose {
			log.Println("⚠ No changes to apply")
		}
	case "down":
		if steps > 0 {
			err := m.Steps(-steps)
			if err != nil && err != migrate.ErrNoChange {
				return err
			}
		} else {
			err := m.Down()
			if err != nil && err != migrate.ErrNoChange {
				return err
			}
		}
	case "version":
		version, dirty, err := m.Version()
		if err != nil {
			return err
		}
		log.Printf("Current version: %d (dirty: %v)", version, dirty)
	default:
		return fmt.Errorf("unknown action: %s", action)
	}
	return nil
}
