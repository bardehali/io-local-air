# Deployment Safety Checklist for io-local-air

## 🛡️ Pre-Deployment Safety Checklist

### Environment Isolation Verification
- [ ] **Local repository is separate from production repository**
  - Local: `https://github.com/bardehali/io-local-air.git`
  - Production: `https://github.com/ioffer-dev/ioffer.git`
  - ✅ This prevents local settings from affecting production

- [ ] **Check for sensitive files before commit**
  ```bash
  git diff --cached --name-only | grep -E "(.env|config/database.yml|config/master.key)" || echo "✅ No sensitive files detected"
  ```

- [ ] **Verify .gitignore is protecting sensitive files**
  ```bash
  git check-ignore .env
  git check-ignore config/master.key
  git check-ignore config/database.yml
  ```

### Code Safety Checks
- [ ] **Pull latest code from master**
  ```bash
  git checkout master
  git pull origin master
  ```

- [ ] **Test changes locally first**
  ```bash
  rails server
  # Test at http://localhost:3000
  ```

- [ ] **Clean working directory**
  ```bash
  git status  # Should show clean working tree
  ```

### Database Backup (MANDATORY)
- [ ] **Create database backup before ANY deployment**
  ```bash
  ssh shoppn_production_root "mysqldump -u root shoppn_spree_production | gzip" > /Volumes/LocalIO/ioffer_production_db_$(date +%m_%d_%y_%H%M).sql.gz
  ```

- [ ] **Verify backup was created**
  ```bash
  ls -la /Volumes/LocalIO/ioffer_production_db_*.sql.gz
  ```

## 🧪 Staging Deployment (MANDATORY FIRST STEP)

### Deploy to Staging
- [ ] **Deploy to staging environment**
  ```bash
  cap staging deploy
  cap staging puma:restart
  ```

- [ ] **Test thoroughly on staging**
  - Visit: http://140.82.56.18:3000
  - Test all changed functionality
  - Verify no errors in logs

- [ ] **Do NOT proceed to production until staging is verified**

## 🏭 Production Deployment

### Safe Production Deployment Process
- [ ] **Use the enhanced deploy script**
  ```bash
  ./deploy_all.sh production master
  ```

- [ ] **Monitor health checks during deployment**
  - Script automatically checks each server after deployment
  - Watch for any health check failures

- [ ] **Verify all servers are healthy**
  - web3: http://83.229.82.155:8000/
  - web4: http://103.45.247.104:8000/
  - web5: http://95.179.183.89:8000/

## 🚨 Emergency Procedures

### If Deployment Fails
- [ ] **Immediate rollback using emergency script**
  ```bash
  ./emergency_rollback.sh
  ```

- [ ] **Or manual rollback**
  ```bash
  cap web3 deploy:rollback
  cap web4 deploy:rollback
  cap web5 deploy:rollback
  cap backend_server deploy:rollback
  ```

### If Database Issues Occur
- [ ] **Restore from backup**
  ```bash
  # List available backups
  ls -la /Volumes/LocalIO/ioffer_production_db_*.sql.gz
  
  # Restore (replace with actual backup filename)
  gunzip -c /Volumes/LocalIO/ioffer_production_db_MM_DD_YY_HHMM.sql.gz | ssh shoppn_production_root "mysql -u root shoppn_spree_production"
  ```

## 📋 Environment Safety Guarantees

### How Local Settings Are Prevented from Affecting Production

1. **Repository Separation**
   - Your local work is in `bardehali/io-local-air`
   - Production deploys from `ioffer-dev/ioffer`
   - No direct connection between local and production repos

2. **Environment-Specific Configuration**
   - Development uses `.env.development` (local only)
   - Production uses server-specific configs in `/var/www/shoppn_spree/shared/config/`
   - Different database names and hosts

3. **Capistrano Deployment Process**
   - Pulls code directly from GitHub repository
   - Uses shared configuration files on servers
   - Symlinks production-specific settings during deployment

4. **Git Ignore Protection**
   - Sensitive files are excluded from version control
   - Pre-deployment checks prevent accidental commits

## 🔧 Available Scripts and Tools

### Deployment Scripts
- **`./deploy_all.sh production`** - Full production deployment with safety checks
- **`./deploy_all.sh staging`** - Deploy to staging environment
- **`./emergency_rollback.sh`** - Emergency rollback all servers

### Manual Commands
- **`cap staging deploy`** - Deploy to staging
- **`cap web3 deploy`** - Deploy to specific server
- **`cap web3 deploy:rollback`** - Rollback specific server

## 📊 Health Check URLs

### Production Servers
- **web3**: http://83.229.82.155:8000/
- **web4**: http://103.45.247.104:8000/
- **web5**: http://95.179.183.89:8000/

### Staging Server
- **staging**: http://140.82.56.18:3000/

## 🆘 Emergency Contacts and Procedures

### If Everything Fails
1. **Check server logs**
   ```bash
   ssh shoppn_web3 'tail -f /var/www/shoppn_spree/shared/log/production.log'
   ```

2. **Check running processes**
   ```bash
   ssh shoppn_web3 'ps aux | grep puma'
   ```

3. **Manual Puma restart**
   ```bash
   ssh shoppn_web3 'cd /var/www/shoppn_spree/current && bundle exec puma -C config/puma.rb --daemon'
   ```

4. **Check disk space and memory**
   ```bash
   ssh shoppn_web3 'df -h && free -m'
   ```

## ✅ Post-Deployment Verification

### After Successful Deployment
- [ ] **All health checks pass**
- [ ] **Website loads correctly**
- [ ] **No errors in application logs**
- [ ] **Database is functioning**
- [ ] **Background jobs are running (if applicable)**

### Documentation
- [ ] **Update deployment log with changes made**
- [ ] **Note any issues encountered and solutions**
- [ ] **Keep database backup files organized**

---

## 🎯 Quick Reference Commands

```bash
# Complete safe deployment workflow
cd /Volumes/LocalIO/io-local-air
git checkout master && git pull origin master
./deploy_all.sh staging          # Test first
./deploy_all.sh production       # Deploy with backup

# Emergency rollback
./emergency_rollback.sh

# Manual health checks
curl -f http://83.229.82.155:8000/ && echo "web3 OK"
curl -f http://103.45.247.104:8000/ && echo "web4 OK"
curl -f http://95.179.183.89:8000/ && echo "web5 OK"
```

**Remember: Your local environment settings CANNOT affect production due to the repository separation and deployment process architecture. This is your primary safety guarantee.**
