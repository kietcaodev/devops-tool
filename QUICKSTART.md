# Quick Start Guide

## Cài đặt nhanh một tool

```bash
cd devops-tool/install

# Cài GitLab
sudo ./gitlab.sh

# Cài Jenkins
sudo ./jenkins.sh

# Cài SonarQube
sudo ./sonarqube.sh

# Cài Nexus
sudo ./nexus.sh

# Cài Harbor
sudo ./harbor.sh

# Cài Monitoring
sudo ./monitoring.sh
```

## Cài đặt toàn bộ stack

```bash
cd devops-tool/install
sudo ./all.sh
```

## Yêu cầu hệ thống tối thiểu

### Cài riêng lẻ từng tool:
- **GitLab**: 4GB RAM, 10GB disk
- **Jenkins**: 2GB RAM, 5GB disk
- **SonarQube**: 2GB RAM, 5GB disk
- **Nexus**: 2GB RAM, 5GB disk
- **Harbor**: 2GB RAM, 5GB disk
- **Monitoring**: 2GB RAM, 5GB disk

### Cài toàn bộ stack:
- **RAM**: 16GB+
- **Disk**: 50GB+
- **CPU**: 4+ cores
- **OS**: Debian 12

## Sau khi cài đặt

### 1. Kiểm tra containers đang chạy
```bash
docker ps
```

### 2. Xem logs
```bash
docker logs -f <container-name>
```

### 3. Restart services
```bash
cd /srv/<service-name>
docker compose restart
```

## Default Credentials

### GitLab
- URL: http://localhost
- Username: `root`
- Password: Xem output script

### Jenkins
- URL: http://localhost:8080
- Username: `admin`
- Password: Xem output script

### SonarQube
- URL: http://localhost:9000
- Username: `admin`
- Password: `admin` (đổi ngay)

### Nexus
- URL: http://localhost:8081
- Username: `admin`
- Password: Trong file `/srv/nexus/data/admin.password`

### Harbor
- URL: http://harbor.local
- Username: `admin`
- Password: Xem output script

### Grafana
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin` (đổi ngay)

## Backup

Mỗi tool có script backup riêng:

```bash
# GitLab
/srv/gitlab/backup.sh

# Jenkins
/srv/jenkins/backup.sh

# SonarQube
/srv/sonarqube/backup.sh

# Nexus
/srv/nexus/backup.sh

# Harbor
/srv/harbor/backup.sh
```

## Troubleshooting

### Container không start
```bash
docker logs <container-name>
```

### Port bị chiếm
```bash
sudo netstat -tulpn | grep <port>
```

### Hết RAM
```bash
# Tạo swap file
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Architecture

```
┌─────────────────────────────────────────────┐
│          Developer Workstation              │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│              GitLab (Port 80)               │
│         Source Control & Git Repo           │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│            Jenkins (Port 8080)              │
│         CI/CD Pipeline Automation           │
└───┬─────────────────────────────────────┬───┘
    │                                     │
    ▼                                     ▼
┌──────────────────┐          ┌──────────────────┐
│   SonarQube      │          │   Nexus/Harbor   │
│   (Port 9000)    │          │  (Ports 8081)    │
│  Code Quality    │          │   Artifacts      │
└──────────────────┘          └──────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│      Prometheus + Grafana (Port 3000)       │
│           Monitoring & Alerts               │
└─────────────────────────────────────────────┘
```

## Workflow Example

1. Developer push code → **GitLab**
2. GitLab webhook trigger → **Jenkins**
3. Jenkins run pipeline:
   - Checkout code
   - Run tests
   - **SonarQube** scan
   - Build artifacts
   - Push to **Nexus**
   - Build Docker image
   - Push to **Harbor**
   - Deploy
4. **Prometheus + Grafana** monitor everything

## Support

Nếu gặp vấn đề, check:
1. Docker logs: `docker logs <container>`
2. System resources: `docker stats`
3. Disk space: `df -h`
4. Memory: `free -h`
