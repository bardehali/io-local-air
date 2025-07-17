# Capistrano Deployment Guide for io-local-air Project

## Overview
This Rails application uses Capistrano 3.11.0 for deployment across multiple production servers and staging. The deployment is configured for Ruby 2.7.8 with Rails 6.0.3.

## Server Architecture
The application runs on a distributed architecture with these servers:

### Production Servers:
- **web3**: 83.229.82.155 (Primary Rails server)
- **web4**: 103.45.247.104 (Rails server)
- **web5**: 95.179.183.89 (Rails server)
- **backend_server**: 45.32.187.246 (Background jobs)
- **production**: 209.250.245.176 (Database/MySQL + Elasticsearch)

### Staging Server:
- **staging**: 140.82.56.18 (Full staging environment)

### Cache Server:
- **cache_server**: 45.32.187.192 (Redis)

## Prerequisites

1. **SSH Access**: You need the SSH private key `~/.ssh/tbdmarket` or `~/.ssh/id_rsa`
2. **Ruby Environment**: Uses RVM with Ruby 2.7.8
3. **Dependencies**: All Capistrano gems are already in the Gemfile

## Quick Start Deployment

### 1. Setup SSH Configuration
Add this to your `~/.ssh/config` file for easy server access:

```bash
Host shoppn_web3
  Hostname 83.229.82.155
  User deploy
  IdentityFile ~/.ssh/tbdmarket
  UseKeychain yes

Host shoppn_web4
  Hostname 103.45.247.104
  User deploy
  IdentityFile ~/.ssh/tbdmarket
  UseKeychain yes

Host shoppn_web5
  Hostname 95.179.183.89
  User deploy
  IdentityFile ~/.ssh/tbdmarket
  UseKeychain yes

Host shoppn_backend
  Hostname 45.32.187.246
  User deploy
  IdentityFile ~/.ssh/tbdmarket
  UseKeychain yes

Host shoppn_prod
  Hostname 209.250.245.176
  User deploy
  IdentityFile ~/.ssh/tbdmarket
  UseKeychain yes

Host shoppn_staging
  Hostname 140.82.56.18
  User deploy
  IdentityFile ~/.ssh/tbdmarket
  UseKeychain yes
```

### 2. Basic Deployment Commands

#### Pre-Deployment Database Backup (ALWAYS DO THIS FIRST!)
```bash
# Create timestamped database backup before any deployment
ssh shoppn_production_root "mysqldump -u root shoppn_spree_production | gzip" > /Volumes/LocalIO/ioffer_production_db_$(date +%m_%d_%y).sql.gz

# Verify backup was created
ls -la /Volumes/LocalIO/ioffer_production_db_*.sql.gz
echo "✅ Database backup created successfully"
```

#### Deploy to Staging First (MANDATORY)
```bash
cap staging deploy
cap staging puma:restart

# Test staging thoroughly before proceeding
echo "🔍 Test your changes at http://140.82.56.18:3000"
echo "⚠️  DO NOT proceed to production until staging is verified"
```

#### Deploy to All Production Servers (With Health Checks)
```bash
# Deploy to web servers with health verification
echo "Deploying to web3..."
cap web3 deploy && cap web3 puma:restart
curl -f http://83.229.82.155:8000/ || echo "⚠️ WARNING: web3 health check failed"

echo "Deploying to web4..."
cap web4 deploy && cap web4 puma:restart
curl -f http://103.45.247.104:8000/ || echo "⚠️ WARNING: web4 health check failed"

echo "Deploying to web5..."
cap web5 deploy && cap web5 puma:restart
curl -f http://95.179.183.89:8000/ || echo "⚠️ WARNING: web5 health check failed"

# Deploy to backend server
echo "Deploying to backend server..."
cap backend_server deploy
```

#### Deploy Specific Branch
```bash
# Deploy a specific branch to any server
BRANCH=feature-branch-name cap web3 deploy
BRANCH=hotfix-123 cap production deploy
```

### 3. Deployment Process Details

#### Pre-deployment Checklist
- [ ] Ensure you have SSH access to all servers
- [ ] Verify your SSH key is properly configured
- [ ] Check that you have the latest code pulled locally
- [ ] Ensure database migrations are ready if needed
- [ ] Test the branch locally before deploying

#### What Happens During Deployment
1. **Code Checkout**: Latest code is pulled from GitHub
2. **Bundle Install**: Gems are installed on the server
3. **Asset Compilation**: Rails assets are precompiled
4. **Database Migrations**: Any pending migrations are run
5. **Symlink Creation**: Shared files and directories are linked
6. **Puma Restart**: The Rails server is restarted
7. **Cleanup**: Old releases are cleaned up

### 4. Server-Specific Operations

#### Web Servers (web3, web4, web5)
These servers run the Rails application with Puma:
- **Port**: 8000 (production)
- **Path**: `/var/www/shoppn_spree`
- **Process**: Puma web server

#### Backend Server
Runs background jobs:
- **Delayed Jobs**: `bin/delayed_job start`
- **Multiple Workers**: `bin/delayed_job -n 2 start`
- **Specific Queues**: `bin/delayed_job -queues=follow_up_email,stats start`

### 5. Troubleshooting

#### Common Issues and Solutions

**SSH Key Issues**
```bash
# Test SSH connection
ssh shoppn_web3
ssh shoppn_staging

# If key issues, check permissions
chmod 600 ~/.ssh/tbdmarket
```

**Deployment Fails**
```bash
# Check what's happening
cap web3 deploy --trace

# Check server logs
ssh shoppn_web3
cd /var/www/shoppn_spree/current
tail -f log/production.log
```

**Puma Won't Restart**
```bash
# Manual restart process
ssh shoppn_web3
cd /var/www/shoppn_spree/current
bundle exec pumactl -P shared/pids/pumaproduction.pid restart

# If that fails, kill and restart
ps ax | grep puma
kill -s QUIT [PID]
bundle exec puma -C config/puma.rb --daemon
```

**Database Connection Issues**
```bash
# Check database connectivity
ssh shoppn_prod
mysql -u [username] -p
```

### 6. Rollback Procedures

#### Quick Rollback (Most Common)
```bash
# Rollback all servers to previous release
cap web3 deploy:rollback
cap web4 deploy:rollback
cap web5 deploy:rollback
cap backend_server deploy:rollback

# Restart services after rollback
cap web3 puma:restart
cap web4 puma:restart
cap web5 puma:restart

# Verify rollback worked with health checks
curl -f http://83.229.82.155:8000/ || echo "⚠️ web3 still failing after rollback"
curl -f http://103.45.247.104:8000/ || echo "⚠️ web4 still failing after rollback"
curl -f http://95.179.183.89:8000/ || echo "⚠️ web5 still failing after rollback"
```

#### Database Restore (If Database Changes Need Rollback)
```bash
# List available backups
ls -la /Volumes/LocalIO/ioffer_production_db_*.sql.gz

# Restore from most recent backup (replace MM_DD_YY with actual date)
gunzip -c /Volumes/LocalIO/ioffer_production_db_MM_DD_YY.sql.gz | ssh shoppn_production_root "mysql -u root shoppn_spree_production"

# Verify database restore
ssh shoppn_production_root "mysql -u root -e 'SELECT COUNT(*) FROM shoppn_spree_production.spree_products;'"
```

#### Deploy Specific Commit (Advanced Rollback)
```bash
# Get commit SHA from history
git log --oneline -10

# Create temporary rollback branch
git checkout -b rollback-[commit-sha] [commit-sha]
git push origin rollback-[commit-sha]

# Deploy the specific commit
BRANCH=rollback-[commit-sha] cap web3 deploy
BRANCH=rollback-[commit-sha] cap web4 deploy
BRANCH=rollback-[commit-sha] cap web5 deploy

# Clean up temporary branch after successful rollback
git branch -d rollback-[commit-sha]
git push origin --delete rollback-[commit-sha]
```

#### Emergency Complete Rollback Script
```bash
#!/bin/bash
# Emergency rollback script - save as emergency_rollback.sh

echo "🚨 EMERGENCY ROLLBACK INITIATED"
echo "Rolling back all servers..."

# Rollback code
cap web3 deploy:rollback &
cap web4 deploy:rollback &
cap web5 deploy:rollback &
cap backend_server deploy:rollback &
wait

# Restart services
cap web3 puma:restart &
cap web4 puma:restart &
cap web5 puma:restart &
wait

# Health checks
echo "Checking server health..."
curl -f http://83.229.82.155:8000/ && echo "✅ web3 OK" || echo "❌ web3 FAILED"
curl -f http://103.45.247.104:8000/ && echo "✅ web4 OK" || echo "❌ web4 FAILED"
curl -f http://95.179.183.89:8000/ && echo "✅ web5 OK" || echo "❌ web5 FAILED"

echo "🚨 EMERGENCY ROLLBACK COMPLETE"
```

### 7. Environment Variables and Secrets

#### Required Files on Servers
These files must exist in `/var/www/shoppn_spree/shared/config/`:
- `master.key`
- `credentials.yml.enc`
- `storage.yml`
- `elasticsearch.yml`

#### Setting Up Secrets
```bash
# On each server
ssh shoppn_web3
cd /var/www/shoppn_spree/shared/config
# Copy your master.key and credentials.yml.enc here
```

### 8. Monitoring and Health Checks

#### Check Application Status
```bash
# Check if Puma is running
ssh shoppn_web3
ps aux | grep puma

# Check application health
curl http://localhost:8000/health
```

#### Log Locations
- **Application logs**: `/var/www/shoppn_spree/shared/log/`
- **Puma logs**: `/var/www/shoppn_spree/shared/log/puma.*.log`
- **Nginx logs**: `/var/log/nginx/`

### 9. Database Operations

#### Run Migrations Manually
```bash
ssh shoppn_web3
cd /var/www/shoppn_spree/current
RAILS_ENV=production bundle exec rails db:migrate
```

#### Elasticsearch Operations
```bash
# Reindex products
bundle exec rake es:reindex_products

# Rebuild entire index
bundle exec rake es:rebuild_products_index

# Sync recent changes
START_TIME_IN_RUBY="25.hours.ago" bundle exec rake es:sync_indices
```

### 10. Emergency Procedures

#### Complete Server Restart
```bash
# Stop all services
cap web3 puma:stop
cap web4 puma:stop
cap web5 puma:stop

# Start all services
cap web3 puma:start
cap web4 puma:start
cap web5 puma:start
```

#### Database Backup Before Deploy
```bash
ssh shoppn_prod
mysqldump -u [user] -p [database_name] > backup_$(date +%Y%m%d_%H%M%S).sql
```

## Support and Contacts

For deployment issues:
1. Check server logs first
2. Verify SSH connectivity
3. Check disk space: `df -h`
4. Check memory: `free -m`
5. Check running processes: `ps aux`

## Quick Reference Card

```bash
# Most common commands
cap staging deploy                    # Deploy to staging
cap web3 deploy && cap web3 puma:restart  # Deploy to web3
cap production deploy --trace         # Deploy with debug output
cap web3 deploy:rollback             # Rollback web3

## 11. Environment Isolation & Configuration Management

### Preventing Local Environment Settings from Affecting Staging/Production

#### Git Configuration Files to Exclude
The following files should **never** be committed to Git as they contain environment-specific settings:

**Files to add to .gitignore:**
```bash
# Environment files
.env
.env.local
.env.development
.env.test
.env.production

# IDE and editor files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Local configuration
config/database.yml.local
config/master.key
config/credentials/production.key
config/credentials/staging.key
```

#### Environment-Specific Configuration Strategy

**1. Use Environment Variables**
```bash
# Instead of hardcoding values in config files, use ENV variables
# config/database.yml
production:
  adapter: mysql2
  database: <%= ENV['DATABASE_NAME'] %>
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV['DATABASE_HOST'] %>
```

**2. Rails Credentials System**
```bash
# Edit credentials for each environment
EDITOR="code --wait" bin/rails credentials:edit --environment production
EDITOR="code --wait" bin/rails credentials:edit --environment staging

# These files are encrypted and safe to commit:
# config/credentials/production.yml.enc
# config/credentials/staging.yml.enc
```

**3. Capistrano Shared Files**
During deployment, sensitive files are symlinked from shared directories:

```bash
# On each server, these files exist in /var/www/shoppn_spree/shared/config/
# and are NOT overwritten by deployments:
- master.key
- credentials.yml.enc
- database.yml
- storage.yml
- elasticsearch.yml
```

#### Pre-Deployment Checklist for Environment Safety

**Before committing any changes:**
```bash
# 1. Check what files are staged
git status

# 2. Review staged changes
git diff --cached

# 3. Ensure no sensitive files are staged
git diff --cached --name-only | grep -E "(.env|config/database.yml|config/master.key)" && echo "WARNING: Sensitive files detected!"

# 4. Use .gitignore to prevent accidents
echo ".env*" >> .gitignore
echo "config/master.key" >> .gitignore
echo "config/database.yml.local" >> .gitignore
```

#### Local Development Best Practices

**1. Use .env files for local development:**
```bash
# Create .env file for local development (never commit this)
cp .env.example .env
# Edit .env with your local settings
```

**2. Use different database names:**
```yaml
# config/database.yml
development:
  database: io_local_air_development

test:
  database: io_local_air_test

production:
  database: <%= ENV['DATABASE_NAME'] %>  # Different from local
```

**3. Separate Redis configurations:**
```yaml
# config/redis.yml
development:
  url: redis://localhost:6379/0

staging:
  url: <%= ENV['REDIS_URL'] %>

production:
  url: <%= ENV['REDIS_URL'] %>
```

#### Deployment Safety Checks

**Verify before deploying:**
```bash
# Check current branch and status
git branch
git status

# Ensure clean working directory
git diff --exit-code

# Test locally first
RAILS_ENV=production bundle exec rails console
# Test database connection
RAILS_ENV=production bundle exec rails db:migrate:status
```

#### Emergency Rollback for Environment Issues

If environment settings are accidentally deployed:
```bash
# Immediate rollback
cap web3 deploy:rollback
cap web4 deploy:rollback
cap web5 deploy:rollback

# Check what was deployed
ssh shoppn_web3
cd /var/www/shoppn_spree/current
git log --oneline -5
```

#### Environment Variable Reference

**Required on staging/production servers:**
```bash
# Database
DATABASE_NAME
DATABASE_USER
DATABASE_PASSWORD
DATABASE_HOST

# Redis
REDIS_URL

# Rails
RAILS_MASTER_KEY
SECRET_KEY_BASE

# External services
ELASTICSEARCH_URL
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

#### Quick Environment Safety Commands

```bash
# Check if .env files are ignored
git check-ignore .env

# List all ignored files
git ls-files --others --ignored --exclude-standard

# Verify no sensitive files in commit
git diff --cached --name-only | xargs grep -l "password\|secret\|key" 2>/dev/null || echo "No sensitive data detected"
```
BRANCH=hotfix cap web4 deploy        # Deploy specific branch
