#!/bin/bash

# Emergency Rollback Script for io-local-air
# Usage: ./emergency_rollback.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}🚨 EMERGENCY ROLLBACK INITIATED${NC}"
echo "⏰ Started at: $(date)"
echo "============================================"

# Function to check server health
check_health() {
    local server_name=$1
    local server_url=$2
    
    echo "🔍 Checking $server_name health..."
    if curl -f "$server_url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $server_name is healthy${NC}"
        return 0
    else
        echo -e "${RED}❌ $server_name health check failed${NC}"
        return 1
    fi
}

echo -e "${YELLOW}📦 Rolling back all servers to previous release...${NC}"

# Rollback all servers in parallel
echo "Rolling back web3..." &
cap web3 deploy:rollback &
PID1=$!

echo "Rolling back web4..." &
cap web4 deploy:rollback &
PID2=$!

echo "Rolling back web5..." &
cap web5 deploy:rollback &
PID3=$!

echo "Rolling back backend server..." &
cap backend_server deploy:rollback &
PID4=$!

# Wait for all rollbacks to complete
wait $PID1 $PID2 $PID3 $PID4

echo -e "${YELLOW}🔄 Restarting services...${NC}"

# Restart services in parallel
cap web3 puma:restart &
cap web4 puma:restart &
cap web5 puma:restart &
wait

echo -e "${YELLOW}🏥 Checking server health after rollback...${NC}"

# Health checks
HEALTH_FAILED=0

if ! check_health "web3" "http://83.229.82.155:8000/"; then
    HEALTH_FAILED=1
fi

if ! check_health "web4" "http://103.45.247.104:8000/"; then
    HEALTH_FAILED=1
fi

if ! check_health "web5" "http://95.179.183.89:8000/"; then
    HEALTH_FAILED=1
fi

echo "============================================"

if [ $HEALTH_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ EMERGENCY ROLLBACK COMPLETED SUCCESSFULLY${NC}"
    echo -e "${GREEN}All servers are healthy after rollback${NC}"
else
    echo -e "${RED}⚠️  ROLLBACK COMPLETED BUT SOME SERVERS STILL FAILING${NC}"
    echo -e "${YELLOW}Manual intervention may be required${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Check server logs: ssh shoppn_web3 'tail -f /var/www/shoppn_spree/shared/log/production.log'"
    echo "2. Check Puma processes: ssh shoppn_web3 'ps aux | grep puma'"
    echo "3. Manual Puma restart: ssh shoppn_web3 'cd /var/www/shoppn_spree/current && bundle exec puma -C config/puma.rb --daemon'"
    echo "4. Consider database restore if needed"
fi

echo "⏰ Completed at: $(date)"
echo "============================================"

# Show available database backups
echo -e "${YELLOW}📦 Available database backups:${NC}"
ls -la /Volumes/LocalIO/ioffer_production_db_*.sql.gz 2>/dev/null || echo "No database backups found"

echo ""
echo -e "${YELLOW}💡 If database restore is needed:${NC}"
echo "gunzip -c /Volumes/LocalIO/ioffer_production_db_MM_DD_YY_HHMM.sql.gz | ssh shoppn_production_root 'mysql -u root shoppn_spree_production'"
