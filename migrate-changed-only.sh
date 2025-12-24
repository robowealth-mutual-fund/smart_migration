#!/bin/bash
set -e

# Configuration
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-user}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-password}"

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🔍 Detecting changed migration files..."
echo ""

# Get changed files from git (staged + unstaged + last commit)
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || echo "")
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
ALL_CHANGED="$CHANGED_FILES"$'\n'"$STAGED_FILES"

# Filter only migration files
CHANGED_MIGRATIONS=$(echo "$ALL_CHANGED" | grep -E "^migrations/.*\.(sql|js)$" | sort -u || echo "")

if [ -z "$CHANGED_MIGRATIONS" ]; then
    echo -e "${YELLOW}⚠️  No changed migration files detected${NC}"
    echo ""
    echo "To detect changes, either:"
    echo "  1. Stage files: git add migrations/"
    echo "  2. Or commit: git commit -m 'Add migrations'"
    echo ""
    exit 0
fi

echo -e "${GREEN}Found changed migration files:${NC}"
echo "$CHANGED_MIGRATIONS" | while read -r file; do
    echo "  📄 $file"
done
echo ""

# Group migrations by database
declare -A DB_PATHS

while IFS= read -r file; do
    if [ -z "$file" ]; then
        continue
    fi
    
    # Extract database name from path
    # Format: migrations/{db-name}/schema/...
    if [[ $file =~ migrations/([^/]+)/ ]]; then
        db_name="${BASH_REMATCH[1]}"
        
        # Determine database type and connection
        if [[ $db_name == postgres-* ]]; then
            db_short="${db_name#postgres-}"
            db_type="postgres"
            connection="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${db_short}?sslmode=disable"
        elif [[ $db_name == mongo-* ]]; then
            db_short="${db_name#mongo-}"
            db_type="mongo"
            connection="mongodb://${MONGO_HOST}:${MONGO_PORT}/${db_short}"
        else
            echo -e "${RED}⚠️  Unknown database format: $db_name${NC}"
            continue
        fi
        
        # Store unique database
        key="${db_type}|${db_short}|${connection}"
        DB_PATHS[$key]="1"
    fi
done <<< "$CHANGED_MIGRATIONS"

# Run migrations for each affected database
echo -e "${YELLOW}=== Running Migrations ===${NC}"
echo ""

for key in "${!DB_PATHS[@]}"; do
    IFS='|' read -r db_type db_name connection <<< "$key"
    
    if [ "$db_type" == "postgres" ]; then
        echo -e "${BLUE}🐘 Migrating PostgreSQL: ${db_name}${NC}"
        POSTGRES_DSN="$connection" ./migrator -db=postgres -type=schema -verbose=true
        echo -e "${GREEN}✅ PostgreSQL ${db_name} migrated${NC}"
    elif [ "$db_type" == "mongo" ]; then
        echo -e "${BLUE}🍃 Migrating MongoDB: ${db_name}${NC}"
        MONGO_URI="$connection" ./migrator -db=mongo -type=schema -verbose=true
        echo -e "${GREEN}✅ MongoDB ${db_name} migrated${NC}"
    fi
    echo ""
done

echo -e "${GREEN}🎉 All changed migrations applied successfully!${NC}"
