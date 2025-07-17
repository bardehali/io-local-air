# Basic Deployment Guide - Change Terms of Use Page

This guide walks you through making a simple change to the Terms of Use page and deploying it to the live site.

## The File You'll Change
**File location:** `/Volumes/LocalIO/io-local-air/app/views/home/_terms_of_use.html.erb`

## Terminal Location Guide

**Important:** All commands must be run from your project folder:
```
/Volumes/LocalIO/io-local-air
```

## Step 1: Get to the Right Location

Open Terminal and navigate to your project:

```bash
cd /Volumes/LocalIO/io-local-air
pwd  # This should show: /Volumes/LocalIO/io-local-air
```

## Step 2: Get the Latest Live Code

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# Make sure you're on the master branch
git checkout master

# Get the latest live code from GitHub
git pull origin master
```

## Step 3: Look at the Current Terms of Use

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# See what's currently in the file
cat app/views/home/_terms_of_use.html.erb
```

## Step 4: Make Your Change

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# Open the file to edit
nano app/views/home/_terms_of_use.html.erb
```

Find any text you want to change, edit it, then save:
- Press `Ctrl+X` to exit
- Press `Y` to save changes
- Press `Enter` to confirm

## Step 5: Test Your Change Locally

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# Start the local server
rails server

# Open browser to http://localhost:3000
# Navigate to the terms page to see your change
# Press Ctrl+C to stop the server when done
```

## Step 6: Save Your Change to Git

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# See what you changed
git diff app/views/home/_terms_of_use.html.erb

# Add your change
git add app/views/home/_terms_of_use.html.erb

# Commit with a simple message
git commit -m "Updated terms of use wording"

# Push to GitHub
git push origin master
```

## Step 7: Create Database Backup (Safety First!)

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# Create timestamped database backup before deployment
ssh shoppn_production_root "mysqldump -u root shoppn_spree_production | gzip" > /Volumes/LocalIO/ioffer_production_db_$(date +%m_%d_%y).sql.gz

# Verify backup was created
ls -la /Volumes/LocalIO/ioffer_production_db_*.sql.gz
```

## Step 8: Deploy to Staging First

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# Deploy to staging server (safe testing)
cap staging deploy

# This takes about 2-3 minutes
# Check staging at: http://140.82.56.18:3000

# Test your changes on staging before proceeding
echo "✅ Test your changes at http://140.82.56.18:3000 before continuing"
```

## Step 9: Deploy to Live Site with Health Checks

**Run this from:** `/Volumes/LocalIO/io-local-air`

```bash
# Deploy to all live servers (one at a time with health checks)
echo "Deploying to web3..."
cap web3 deploy && cap web3 puma:restart
curl -f http://83.229.82.155:8000/ || echo "⚠️ WARNING: web3 health check failed"

echo "Deploying to web4..."
cap web4 deploy && cap web4 puma:restart
curl -f http://103.45.247.104:8000/ || echo "⚠️ WARNING: web4 health check failed"

echo "Deploying to web5..."
cap web5 deploy && cap web5 puma:restart
curl -f http://95.179.183.89:8000/ || echo "⚠️ WARNING: web5 health check failed"
```

## Complete Example - All Commands in Order

**All commands run from:** `/Volumes/LocalIO/io-local-air`

```bash
# 1. Get to the right place
cd /Volumes/LocalIO/io-local-air

# 2. Get latest code
git checkout master
git pull origin master

# 3. Edit the file
nano app/views/home/_terms_of_use.html.erb
# [make your change and save]

# 4. Test locally
rails server
# [check localhost:3000, then Ctrl+C]

# 5. Save to Git
git add app/views/home/_terms_of_use.html.erb
git commit -m "Changed terms text"
git push origin master

# 6. Create database backup
ssh shoppn_production_root "mysqldump -u root shoppn_spree_production | gzip" > /Volumes/LocalIO/ioffer_production_db_$(date +%m_%d_%y).sql.gz

# 7. Deploy to staging
cap staging deploy
# [test at http://140.82.56.18:3000]

# 8. Deploy to live with health checks
cap web3 deploy && cap web3 puma:restart
curl -f http://83.229.82.155:8000/ || echo "⚠️ web3 health check failed"

cap web4 deploy && cap web4 puma:restart
curl -f http://103.45.247.104:8000/ || echo "⚠️ web4 health check failed"

cap web5 deploy && cap web5 puma:restart
curl -f http://95.179.183.89:8000/ || echo "⚠️ web5 health check failed"
```

## Quick Reference Card

**Always start here:**
```bash
cd /Volumes/LocalIO/io-local-air
```

**Then run any command from this location:**
- `git pull origin master` - Get latest
- `nano app/views/home/_terms_of_use.html.erb` - Edit file
- `git push origin master` - Push to GitHub
- `cap staging deploy` - Deploy to staging
- `cap web3 deploy` - Deploy to live web3

## Visual Terminal Location Check

Before running any command, always check you're in the right place:

```bash
$ pwd
/Volumes/LocalIO/io-local-air

$ ls
app/  config/  Gemfile  README.md  [other files...]
```


## Environment Safety Check

**Before making any commits, ensure you don't accidentally include local environment settings:**

```bash
# Quick safety check - run this before git add/commit
git status

# Look for these files - they should NOT be staged:
# ❌ .env
# ❌ config/database.yml
# ❌ config/master.key
# ❌ config/credentials/*.key

# If you see any of these staged, unstage them:
git reset HEAD .env
git reset HEAD config/database.yml
git reset HEAD config/master.key

# Safe files to commit:
# ✅ app/views/home/_terms_of_use.html.erb
# ✅ app/controllers/*.rb
# ✅ Any code changes
```

**Quick command to check for sensitive files:**
```bash
git diff --cached --name-only | grep -E "(.env|config/database.yml|config/master.key)" || echo "✅ No sensitive files detected"
```

## Emergency Rollback Procedures

**If something goes wrong after deployment:**

```bash
# Rollback all servers to previous version
cap web3 deploy:rollback
cap web4 deploy:rollback
cap web5 deploy:rollback

# Restart services after rollback
cap web3 puma:restart
cap web4 puma:restart
cap web5 puma:restart

# Check health after rollback
curl -f http://83.229.82.155:8000/ || echo "⚠️ web3 still failing"
curl -f http://103.45.247.104:8000/ || echo "⚠️ web4 still failing"
curl -f http://95.179.183.89:8000/ || echo "⚠️ web5 still failing"
```

**If rollback doesn't work, restore from database backup:**
```bash
# List available backups
ls -la /Volumes/LocalIO/ioffer_production_db_*.sql.gz

# Restore from backup (replace with actual backup filename)
gunzip -c /Volumes/LocalIO/ioffer_production_db_MM_DD_YY.sql.gz | ssh shoppn_production_root "mysql -u root shoppn_spree_production"
```

If you see these files, you're in the right place to run all deployment commands!
