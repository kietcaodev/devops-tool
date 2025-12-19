# Troubleshooting Guide

## 🔧 Common Issues & Solutions

### Port Conflicts

#### GitLab SSH Port 22 Conflict
**Error:** `failed to bind host port 0.0.0.0:22/tcp: address already in use`

**Solution:**
- Port đã được đổi sang 2222
- Git clone command: `git clone ssh://git@server:2222/user/repo.git`

#### Harbor Port 80 Conflict  
**Error:** `Bind for 0.0.0.0:80 failed: port is already allocated`

**Solution:**
- Port đã được đổi sang 8090
- Access: `http://harbor.local:8090`
- Docker login: `docker login server:8090`

#### cAdvisor Port 8080 Conflict
**Error:** `Bind for 0.0.0.0:8080 failed: port is already allocated`

**Solution:**
- Port đã được đổi sang 8888
- Access: `http://localhost:8888`

### Services Not Starting

#### Check Docker Status
```bash
sudo systemctl status docker
sudo systemctl start docker
```

#### Check Container Logs
```bash
docker logs <container-name>
docker logs -f <container-name>  # Follow logs
```

#### Check Container Status
```bash
docker ps -a  # All containers
docker compose ps  # In service directory
```

### Memory Issues

#### Out of Memory
```bash
# Check memory
free -h

# Add swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

#### Container Memory Limits
```bash
# Edit docker-compose.yml
services:
  app:
    mem_limit: 2g
    mem_reservation: 1g
```

### Disk Space Issues

#### Check Disk Space
```bash
df -h
du -sh /srv/*
```

#### Clean Docker Resources
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused containers
docker container prune

# Clean everything
docker system prune -a --volumes
```

### Database Issues

#### PostgreSQL Not Ready
```bash
# Check logs
docker logs sonarqube-postgres
docker logs harbor-db

# Restart database
docker restart sonarqube-postgres
```

#### Connection Refused
- Wait 30-60 seconds after starting
- Check database container is running
- Verify network connections

### GitLab Specific

#### GitLab Taking Too Long
- GitLab needs 3-5 minutes to start
- Check: `docker exec gitlab gitlab-ctl status`
- View logs: `docker logs -f gitlab`

#### Cannot Access GitLab
```bash
# Check if running
docker ps | grep gitlab

# Check port
sudo netstat -tulpn | grep :80

# Restart
docker restart gitlab
```

### Jenkins Specific

#### Cannot Get Admin Password
```bash
# Wait 2-3 minutes after installation
docker logs jenkins | grep -A 5 "password"

# Or check file
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

#### Plugin Installation Failed
```bash
# Restart Jenkins
docker restart jenkins

# Clear plugin cache
docker exec jenkins rm -rf /var/jenkins_home/plugins/*
docker restart jenkins
```

### SonarQube Specific

#### ElasticSearch Bootstrap Checks Failed
```bash
# Already configured in script, but verify:
sysctl vm.max_map_count
# Should be 524288

# If not:
sudo sysctl -w vm.max_map_count=524288
```

#### SonarQube Won't Start
```bash
# Check logs
docker logs sonarqube

# Check database
docker logs sonarqube-postgres

# Verify system limits
ulimit -n  # Should be > 65536
```

### Harbor Specific

#### Harbor Installation Fails
```bash
# Clean up
cd /srv/harbor/harbor
docker compose down
cd /srv
rm -rf harbor

# Reinstall
cd ~/devops-tool/install
sudo ./harbor.sh
```

#### Cannot Push to Harbor
```bash
# Add to Docker daemon config
sudo nano /etc/docker/daemon.json
{
  "insecure-registries": ["your-server:8090"]
}

# Restart Docker
sudo systemctl restart docker

# Login
docker login your-server:8090
```

### Network Issues

#### Containers Can't Communicate
```bash
# Check networks
docker network ls

# Inspect network
docker network inspect <network-name>

# Restart all
cd /srv/<service>
docker compose restart
```

#### DNS Resolution Failed
```bash
# Add to docker-compose.yml
services:
  app:
    dns:
      - 8.8.8.8
      - 8.8.4.4
```

### Permission Issues

#### Permission Denied Errors
```bash
# Fix ownership (example for Jenkins)
sudo chown -R 1000:1000 /srv/jenkins/data

# For Nexus
sudo chown -R 200:200 /srv/nexus/data

# For Prometheus
sudo chown -R 65534:65534 /srv/monitoring/prometheus/data
```

### Backup & Restore Issues

#### Backup Script Fails
```bash
# Check script permissions
chmod +x /srv/<service>/backup.sh

# Run manually
sudo /srv/<service>/backup.sh

# Check crontab
crontab -l
```

#### Restore Fails
```bash
# Stop service first
cd /srv/<service>
docker compose down

# Restore data
tar -xzf backup.tar.gz -C /srv/<service>/data

# Start service
docker compose up -d
```

### SSL/TLS Issues

#### Certificate Errors
```bash
# For Harbor with self-signed cert
# Add cert to Docker
sudo mkdir -p /etc/docker/certs.d/your-server:8090
sudo cp ca.crt /etc/docker/certs.d/your-server:8090/

# Restart Docker
sudo systemctl restart docker
```

### Performance Issues

#### High CPU Usage
```bash
# Check resource usage
docker stats

# Limit CPU
services:
  app:
    cpus: '2.0'
```

#### Slow Response
```bash
# Check logs for errors
docker compose logs

# Increase memory limits
# Edit docker-compose.yml
```

## 🔍 Diagnostic Commands

### System Information
```bash
# OS info
cat /etc/os-release

# System resources
free -h
df -h
nproc

# Docker version
docker --version
docker compose version
```

### Container Diagnostics
```bash
# All containers
docker ps -a

# Resource usage
docker stats

# Inspect container
docker inspect <container-name>

# Enter container
docker exec -it <container-name> bash
```

### Network Diagnostics
```bash
# List networks
docker network ls

# Inspect network
docker network inspect <network-name>

# Test connectivity
docker exec <container> ping <other-container>
```

### Log Analysis
```bash
# View logs
docker logs <container-name>

# Follow logs
docker logs -f <container-name>

# Last N lines
docker logs --tail 100 <container-name>

# Since timestamp
docker logs --since 2024-01-01 <container-name>
```

## 🆘 Emergency Recovery

### Complete Reset
```bash
# Stop all services
cd /srv/gitlab && docker compose down
cd /srv/jenkins && docker compose down
cd /srv/sonarqube && docker compose down
cd /srv/nexus && docker compose down
cd /srv/harbor/harbor && docker compose down
cd /srv/monitoring && docker compose down

# Clean Docker
docker system prune -a --volumes

# Reinstall
cd ~/devops-tool/install
sudo ./all.sh
```

### Single Service Reset
```bash
# Example: Jenkins
cd /srv/jenkins
docker compose down
rm -rf data/*
docker compose up -d
```

## 📞 Getting Help

### Check Logs First
```bash
# Service logs
docker logs <service-name>

# System logs
journalctl -xe
```

### Gather Information
```bash
# System info
uname -a
docker version
docker compose version

# Container status
docker ps -a

# Resource usage
free -h
df -h
docker stats --no-stream
```

### Useful Links
- GitLab: https://docs.gitlab.com/
- Jenkins: https://www.jenkins.io/doc/
- SonarQube: https://docs.sonarqube.org/
- Harbor: https://goharbor.io/docs/
- Nexus: https://help.sonatype.com/
