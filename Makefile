.PHONY: help build run test clean docker-build docker-push k8s-apply k8s-delete

# Variables
IMAGE_NAME ?= fundii-database-migration
IMAGE_TAG ?= latest
REGISTRY ?= your-registry
FULL_IMAGE = $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

# Database Connection Settings
POSTGRES_HOST ?= localhost
POSTGRES_PORT ?= 5432
POSTGRES_USER ?= user
POSTGRES_PASSWORD ?= password

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Go binary
	@echo "Building binary..."
	go build -o migrator ./cmd/main.go

run: ## Run migrations locally (requires env vars)
	@echo "Running migrations..."
	go run ./cmd/main.go -verbose=true

run-postgres-schema: ## Run PostgreSQL schema migrations only
	go run ./cmd/main.go -db=postgres -type=schema -action=up -verbose=true

run-postgres-seed: ## Run PostgreSQL seed migrations only
	go run ./cmd/main.go -db=postgres -type=seed -action=up -verbose=true

run-mongo-schema: ## Run MongoDB schema migrations only
	go run ./cmd/main.go -db=mongo -type=schema -action=up -verbose=true

run-mongo-seed: ## Run MongoDB seed migrations only
	go run ./cmd/main.go -db=mongo -type=seed -action=up -verbose=true

test: ## Run tests
	go test -v ./...

clean: ## Clean build artifacts
	@echo "Cleaning..."
	rm -f migrator generator
	go clean

docker-build: ## Build Docker image
	@echo "Building Docker image: $(FULL_IMAGE)"
	docker build -t $(FULL_IMAGE) --no-cache .

docker-push: docker-build ## Push Docker image to registry
	@echo "Pushing Docker image: $(FULL_IMAGE)"
	docker push $(FULL_IMAGE)

docker-run: ## Run Docker container locally
	docker run --rm \
		-e POSTGRES_DSN="$(POSTGRES_DSN)" \
		-e MONGO_URI="$(MONGO_URI)" \
		$(FULL_IMAGE) \
		-verbose=true

k8s-create-secret: ## Create Kubernetes secret (requires POSTGRES_DSN and MONGO_URI env vars)
	@echo "Creating Kubernetes secret..."
	kubectl create secret generic database-credentials \
		--from-literal=POSTGRES_DSN="$(POSTGRES_DSN)" \
		--from-literal=MONGO_URI="$(MONGO_URI)" \
		--dry-run=client -o yaml | kubectl apply -f -

k8s-apply: ## Apply migration job to Kubernetes (auto-detects changes)
	@echo "Applying migration job..."
	kubectl apply -f k8s/job-migration.yaml

k8s-apply-schema: ## Apply schema migration job to Kubernetes (deprecated - use k8s-apply)
	@echo "Applying schema migration job..."
	kubectl apply -f k8s/job-schema.yaml

k8s-apply-seed: ## Apply seed migration job to Kubernetes (deprecated - use k8s-apply)
	@echo "Applying seed migration job..."
	kubectl apply -f k8s/job-seed.yaml

k8s-apply-cronjob: ## Apply CronJob to Kubernetes
	@echo "Applying CronJob..."
	kubectl apply -f k8s/cronjob.yaml

k8s-logs: ## Get logs from migration job
	kubectl logs -l app=db-migration --tail=100 -f

k8s-logs-schema: ## Get logs from schema migration job (deprecated - use k8s-logs)
	kubectl logs -l app=db-migration,type=schema --tail=100 -f

k8s-logs-seed: ## Get logs from seed migration job (deprecated - use k8s-logs)
	kubectl logs -l app=db-migration,type=seed --tail=100 -f

k8s-delete: ## Delete all migration jobs
	@echo "Deleting migration jobs..."
	kubectl delete job -l app=db-migration --ignore-not-found=true
	kubectl delete cronjob -l app=db-migration --ignore-not-found=true

k8s-status: ## Check status of migration job
	@echo "Migration job:"
	@kubectl get job db-migration 2>/dev/null || echo "Not found"
	@echo "\nCronJob:"
	@kubectl get cronjob db-migration-scheduled 2>/dev/null || echo "Not found"
	@echo "\nAll migration jobs:"
	@kubectl get jobs -l app=db-migration 2>/dev/null || echo "None found"

# Multiple Database Migrations (same host, different databases)
migrate-all-dbs: ## Migrate all databases (product, user, order)
	@echo "🚀 Migrating all databases..."
	@./migrate-all-databases.sh

migrate-changed: ## Migrate only changed migration files (smart mode)
	@echo "🧠 Smart migration: detecting changes..."
	@./migrate-changed-only.sh

migrate-product-db: ## Migrate product database only
	@echo "📦 Migrating Product Database..."
	@POSTGRES_DSN="postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/product?sslmode=disable" \
		go run ./cmd/main.go -db=postgres -type=schema -verbose=true

migrate-user-db: ## Migrate user database only
	@echo "👤 Migrating User Database..."
	@POSTGRES_DSN="postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/user?sslmode=disable" \
		go run ./cmd/main.go -db=postgres -type=schema -verbose=true

migrate-order-db: ## Migrate order database only
	@echo "📋 Migrating Order Database..."
	@POSTGRES_DSN="postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/order?sslmode=disable" \
	go run ./cmd/main.go -db=postgres -type=schema -verbose=true

# Migration Generator
build-generator: ## Build the migration generator binary
	@echo "Building generator..."
	go build -o generator ./cmd/generator/main.go

generate: build-generator ## Generate migration from YAML template (usage: make generate FILE=examples/postgres-simple-table.yaml)
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: FILE parameter required"; \
		echo "Usage: make generate FILE=examples/postgres-simple-table.yaml"; \
		exit 1; \
	fi
	@./generator $(FILE)
