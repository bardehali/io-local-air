#!/bin/bash

# io-local-air Production Deployment Script with Safety Features
# Usage: ./deploy_all.sh [staging|production] [branch-name]

set -e

ENVIRONMENT=${1:-production}
BRANCH=${2:-master}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create database backup
create_backup() {
    echo -e "${YELLOW}📦 Creating database backup...${NC}"
    BACKUP_FILE="/Volumes/LocalIO/ioffer_production_db_$(date +%m_%d_%y_%H%M).sql.gz"
    ssh shoppn_production_root "mysqldump -u root shoppn_spree_production | gzip" > "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        echo -e "${GREEN}✅ Database backup created: $BACKUP_FILE${NC}"
        ls -la "$BACKUP_FILE"
    else
        echo -e "${RED}❌ Database backup failed!${NC}"
        exit 1
    fi
}

# Function to check server health
check_health() {
    local server_name=$1
    local server_url=$2
    
    echo "🔍 Checking $server_name health..."
    if curl -f "$server_url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $server_name is healthy${NC}"
        return 0
    else
        echo -e "${RED}⚠️  WARNING: $server_name health check failed${NC}"
        return 1
    fi
}

# Function to rollback all servers
rollback_all() {
    echo -e "${RED}🚨 INITIATING EMERGENCY ROLLBACK${NC}"
    
    cap web3 deploy:rollback &
    cap web4 deploy:rollback &
    cap web5 deploy:rollback &
    cap backend_server deploy:rollback &
    wait
    
    cap web3 puma:restart &
    cap web4 puma:restart &
    cap web5 puma:restart &
    wait
    
    echo -e "${YELLOW}🔍 Checking health after rollback...${NC}"
    check_health "web3" "http://83.229.82.155:8000/"
    check_health "web4" "http://103.45.247.104:8000/"
    check_health "web5" "http://95.179.183.89:8000/"
}

echo "============================================"
echo "🚀 Starting deployment to $ENVIRONMENT"
echo "📝 Branch: $BRANCH"
echo "⏰ Time: $(date)"
echo "============================================"

# Pre-deployment safety checks
echo -e "${YELLOW}🔍 Running pre-deployment safety checks...${NC}"

# Check for sensitive files
if git diff --cached --name-only | grep -E "(.env|config/database.yml|config/master.key)" > /dev/null 2>&1; then
    echo -e "${RED}❌ WARNING: Sensitive files detected in staged changes!${NC}"
    git diff --cached --name-only | grep -E "(.env|config/database.yml|config/master.key)"
    echo "Please unstage these files before deploying."
    exit 1
fi

if [ "$ENVIRONMENT" = "staging" ]; then
    echo -e "${YELLOW}🧪 Deploying to staging...${NC}"
    BRANCH=$BRANCH cap staging deploy
    BRANCH=$BRANCH cap staging puma:restart
    
    echo -e "${GREEN}✅ Staging deployment complete!${NC}"
    echo -e "${YELLOW}🔍 Please test your changes at: http://140.82.56.18:3000${NC}"
    
elif [ "$ENVIRONMENT" = "production" ]; then
    # Create database backup before production deployment
    create_backup
    
    echo -e "${YELLOW}🏭 Deploying to production servers...${NC}"
    
    # Deploy to web servers with health checks
    echo -e "${YELLOW}📡 Deploying to web3...${NC}"
    BRANCH=$BRANCH cap web3 deploy
    BRANCH=$BRANCH cap web3 puma:restart
    if ! check_health "web3" "http://83.229.82.155:8000/"; then
        echo -e "${RED}❌ web3 deployment failed! Consider rollback.${NC}"
    fi
    
    echo -e "${YELLOW}📡 Deploying to web4...${NC}"
    BRANCH=$BRANCH cap web4 deploy
    BRANCH=$BRANCH cap web4 puma:restart
    if ! check_health "web4" "http://103.45.247.104:8000/"; then
        echo -e "${RED}❌ web4 deployment failed! Consider rollback.${NC}"
    fi
    
    echo -e "${YELLOW}📡 Deploying to web5...${NC}"
    BRANCH=$BRANCH cap web5 deploy
    BRANCH=$BRANCH cap web5 puma:restart
    if ! check_health "web5" "http://95.179.183.89:8000/"; then
        echo -e "${RED}❌ web5 deployment failed! Consider rollback.${NC}"
    fi
    
    echo -e "${YELLOW}⚙️  Deploying to backend server...${NC}"
    BRANCH=$BRANCH cap backend_server deploy
    
    echo -e "${GREEN}✅ Production deployment complete!${NC}"
    
    # Final health check summary
    echo -e "${YELLOW}🏥 Final Health Check Summary:${NC}"
    check_health "web3" "http://83.229.82.155:8000/"
    check_health "web4" "http://103.45.247.104:8000/"
    check_health "web5" "http://95.179.183.89:8000/"
    
else
    echo -e "${RED}❌ Invalid environment specified${NC}"
    echo "Usage: $0 [staging|production] [branch-name]"
    echo "Example: $0 production master"
    echo "Example: $0 staging feature-branch"
    echo ""
    echo "Available commands:"
    echo "  $0 staging           - Deploy to staging"
    echo "  $0 production        - Deploy to production with backup"
    echo "  $0 rollback          - Emergency rollback all servers"
    exit 1
fi

# Special rollback command
if [ "$ENVIRONMENT" = "rollback" ]; then
    rollback_all
    exit 0
fi

echo "============================================"
echo -e "${GREEN}🎉 Deployment to $ENVIRONMENT completed successfully!${NC}"
echo "⏰ Completed at: $(date)"
echo "============================================"
