# DevOps Infrastructure Automation

Bộ script tự động cài đặt và cấu hình các tool DevOps chuẩn trên Debian 12.

## 🎯 Các Tool Được Hỗ Trợ

- **GitLab CE** - Source control & CI/CD platform
- **Jenkins** - Automation server với Blue Ocean
- **SonarQube** - Code quality & security analysis
- **Nexus Repository** - Artifact repository manager
- **Harbor** - Docker/Container registry
- **Prometheus + Grafana** - Monitoring & visualization
- **GitLab Runner** - CI/CD executor
- **PostgreSQL** - Database cho các services

## 🚀 Tính năng

- ✅ Cài đặt tự động từng tool hoặc toàn bộ stack
- ✅ Cấu hình SSL/TLS với Let's Encrypt
- ✅ Backup và restore tự động
- ✅ High availability setup
- ✅ Security hardening
- ✅ Resource optimization cho Debian 12
- ✅ Docker-based deployment
- ✅ Monitoring và alerting tích hợp

## 📁 Cấu trúc Project

```
devops-tool/
├── install/              # Installation scripts
│   ├── gitlab.sh        # Cài đặt GitLab CE
│   ├── jenkins.sh       # Cài đặt Jenkins
│   ├── sonarqube.sh     # Cài đặt SonarQube
│   ├── nexus.sh         # Cài đặt Nexus Repository
│   ├── harbor.sh        # Cài đặt Harbor Registry
│   ├── monitoring.sh    # Cài đặt Prometheus + Grafana
│   └── all.sh           # Cài đặt toàn bộ stack
├── configs/             # Configuration templates
│   ├── gitlab/         # GitLab configs
│   ├── jenkins/        # Jenkins configs
│   ├── sonarqube/      # SonarQube configs
│   ├── nexus/          # Nexus configs
│   ├── harbor/         # Harbor configs
│   └── monitoring/     # Monitoring configs
├── docker/              # Docker compose files
│   ├── gitlab/
│   ├── jenkins/
│   ├── sonarqube/
│   ├── nexus/
│   ├── harbor/
│   └── monitoring/
├── backup/              # Backup scripts
│   ├── backup-gitlab.sh
│   ├── backup-jenkins.sh
│   ├── backup-sonar.sh
│   └── restore.sh
└── utils/               # Utility scripts
    ├── ssl-setup.sh    # Setup SSL certificates
    ├── health-check.sh # Health monitoring
    └── cleanup.sh      # Cleanup unused resources
```

## 🔧 Yêu cầu hệ thống

- **OS**: Debian 12 (Bookworm)
- **RAM**: 
  - GitLab: 4GB minimum, 8GB recommended
  - Jenkins: 2GB minimum, 4GB recommended
  - SonarQube: 2GB minimum, 4GB recommended
  - Full Stack: 16GB+ recommended
- **Disk**: 50GB+ free space
- **CPU**: 4+ cores recommended
- **Internet**: Để download Docker images

## 📦 Cài đặt nhanh

### Cài đặt từng tool riêng lẻ

```bash
# GitLab
sudo chmod +x install/gitlab.sh
sudo ./install/gitlab.sh

# Jenkins
sudo chmod +x install/jenkins.sh
sudo ./install/jenkins.sh

# SonarQube
sudo chmod +x install/sonarqube.sh
sudo ./install/sonarqube.sh

# Nexus
sudo chmod +x install/nexus.sh
sudo ./install/nexus.sh

# Harbor
sudo chmod +x install/harbor.sh
sudo ./install/harbor.sh

# Monitoring Stack (Prometheus + Grafana)
sudo chmod +x install/monitoring.sh
sudo ./install/monitoring.sh
```

### Cài đặt toàn bộ stack

```bash
sudo chmod +x install/all.sh
sudo ./install/all.sh
```

## 🎯 Cấu hình sau khi cài đặt

### GitLab
- URL: http://localhost (hoặc domain của bạn)
- Username: `root`
- Password: Xem trong output của script

### Jenkins
- URL: http://localhost:8080
- Username: `admin`
- Initial Password: Xem trong output của script

### SonarQube
- URL: http://localhost:9000
- Username: `admin`
- Password: `admin` (thay đổi ngay sau lần đăng nhập đầu tiên)

### Nexus
- URL: http://localhost:8081
- Username: `admin`
- Password: Xem trong `/srv/nexus/data/admin.password`

### Harbor
- URL: http://harbor.local:8090
- Username: `admin`
- Password: Xem trong output của script

### Grafana
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin`

## 🔐 Security

### SSL/TLS Setup

```bash
sudo ./utils/ssl-setup.sh yourdomain.com
```

### Firewall Configuration

```bash
# GitLab
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2222/tcp  # GitLab SSH

# Jenkins
sudo ufw allow 8080/tcp

# SonarQube
sudo ufw allow 9000/tcp

# Nexus
sudo ufw allow 8081/tcp

# Harbor
sudo ufw allow 8090/tcp

# Monitoring
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
```

## 💾 Backup & Restore

### Backup tất cả services

```bash
sudo ./backup/backup-all.sh
```

### Backup riêng từng service

```bash
sudo ./backup/backup-gitlab.sh
sudo ./backup/backup-jenkins.sh
sudo ./backup/backup-sonar.sh
```

### Restore

```bash
sudo ./backup/restore.sh [service-name] [backup-file]
```

## 📊 Monitoring

### Health Check tất cả services

```bash
./utils/health-check.sh
```

### Xem logs

```bash
# GitLab
docker logs -f gitlab

# Jenkins
docker logs -f jenkins

# SonarQube
docker logs -f sonarqube
```

## 🛠️ Troubleshooting

### Service không start

```bash
# Check Docker
sudo systemctl status docker

# Check logs
docker logs [container-name]

# Check resources
docker stats
```

### Out of memory

```bash
# Tăng swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Port conflicts

```bash
# Check port usage
sudo netstat -tulpn | grep [port]

# Change port in docker-compose.yml
cd /srv/[service]
nano docker-compose.yml
docker compose restart
```

## 📖 Documentation

Chi tiết hơn về từng tool:
- [GitLab Documentation](https://docs.gitlab.com/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Nexus Documentation](https://help.sonatype.com/repomanager3)
- [Harbor Documentation](https://goharbor.io/docs/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

MIT License

## 🎯 Use Cases

### Complete DevOps Pipeline

1. **Source Control**: GitLab
2. **CI/CD**: Jenkins với GitLab integration
3. **Code Quality**: SonarQube analysis
4. **Artifact Storage**: Nexus repository
5. **Container Registry**: Harbor
6. **Monitoring**: Prometheus + Grafana

### Example Workflow

```
Developer Push Code
    ↓
GitLab (Git repository)
    ↓
Jenkins (CI/CD pipeline)
    ↓
SonarQube (Code quality check)
    ↓
Build & Test
    ↓
Nexus (Store artifacts)
    ↓
Build Docker Image
    ↓
Harbor (Push Docker image)
    ↓
Deploy to Production
    ↓
Prometheus + Grafana (Monitor)
```

---
Made with ❤️ for Vibe Coding on Debian 12

