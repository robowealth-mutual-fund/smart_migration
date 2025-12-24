#!/bin/bash
set -e

# Configuration
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_USER="user"
POSTGRES_PASSWORD="password"

MONGO_HOST="localhost"
MONGO_PORT="27017"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Starting migration for all databases..."
echo ""

echo -e "${YELLOW}=== PostgreSQL Databases ===${NC}"
echo ""

# Migrate PostgreSQL Product Database
echo -e "${BLUE}📦 Migrating PostgreSQL Product Database...${NC}"
POSTGRES_DSN="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/product?sslmode=disable" \
  ./migrator -db=postgres -type=schema -verbose=true
echo -e "${GREEN}✅ PostgreSQL Product Database migrated${NC}"
echo ""

# Migrate PostgreSQL User Database
echo -e "${BLUE}👤 Migrating PostgreSQL User Database...${NC}"
export POSTGRES_DSN="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/user?sslmode=disable"
export MIGRATION_PATH="migrations/postgres-user/schema"
./migrator -db=postgres -type=schema -verbose=true
echo -e "${GREEN}✅ PostgreSQL User Database migrated${NC}"
echo ""

# Migrate PostgreSQL Order Database
echo -e "${BLUE}📋 Migrating PostgreSQL Order Database...${NC}"
export POSTGRES_DSN="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/order?sslmode=disable"
export MIGRATION_PATH="migrations/postgres-order/schema"
./migrator -db=postgres -type=schema -verbose=true
echo -e "${GREEN}✅ PostgreSQL Order Database migrated${NC}"
echo ""

echo -e "${YELLOW}=== MongoDB Databases ===${NC}"
echo ""

# Migrate MongoDB Product Database
echo -e "${BLUE}📦 Migrating MongoDB Product Database...${NC}"
export MONGO_URI="mongodb://${MONGO_HOST}:${MONGO_PORT}/product"
export MIGRATION_PATH="migrations/mongo-product/schema"
./migrator -db=mongo -type=schema -verbose=true
echo -e "${GREEN}✅ MongoDB Product Database migrated${NC}"
echo ""

# Migrate MongoDB Analytics Database
echo -e "${BLUE}📊 Migrating MongoDB Analytics Database...${NC}"
export MONGO_URI="mongodb://${MONGO_HOST}:${MONGO_PORT}/analytics"
export MIGRATION_PATH="migrations/mongo-analytics/schema"
./migrator -db=mongo -type=schema -verbose=true
echo -e "${GREEN}✅ MongoDB Analytics Database migrated${NC}"
echo ""

echo -e "${GREEN}🎉 All databases migrated successfully!${NC}"
