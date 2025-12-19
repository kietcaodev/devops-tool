# Port Reference - DevOps Stack

## 📊 Tất cả các ports được sử dụng

| Service | Port | Protocol | Purpose | Notes |
|---------|------|----------|---------|-------|
| **GitLab HTTP** | 80 | HTTP | Web UI | Main access |
| **GitLab HTTPS** | 443 | HTTPS | Secure Web | If SSL enabled |
| **GitLab SSH** | 2222 | SSH | Git operations | Changed from 22 to avoid conflict |
| **Jenkins** | 8080 | HTTP | Web UI & API | Automation server |
| **SonarQube** | 9000 | HTTP | Web UI | Code analysis |
| **Nexus Web** | 8081 | HTTP | Web UI | Main interface |
| **Nexus Docker** | 8082 | HTTP | Docker hosted repo | Push/pull images |
| **Nexus Docker Group** | 8083 | HTTP | Docker group repo | Aggregated registry |
| **Harbor** | 8090 | HTTP | Web UI & Registry | Changed from 80 to avoid GitLab conflict |
| **Prometheus** | 9090 | HTTP | Metrics & Web UI | Monitoring |
| **Grafana** | 3000 | HTTP | Dashboards | Visualization |
| **AlertManager** | 9093 | HTTP | Alert management | Prometheus alerts |
| **Node Exporter** | 9100 | HTTP | Host metrics | System metrics |
| **cAdvisor** | 8888 | HTTP | Container metrics | Changed from 8080 to avoid Jenkins conflict |

## 🔥 Firewall Rules (UFW)

```bash
# GitLab
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS  
sudo ufw allow 2222/tcp    # Git SSH

# Jenkins
sudo ufw allow 8080/tcp

# SonarQube
sudo ufw allow 9000/tcp

# Nexus
sudo ufw allow 8081/tcp    # Web UI
sudo ufw allow 8082/tcp    # Docker hosted (optional)
sudo ufw allow 8083/tcp    # Docker group (optional)

# Harbor
sudo ufw allow 8090/tcp

# Monitoring
sudo ufw allow 3000/tcp    # Grafana
sudo ufw allow 9090/tcp    # Prometheus
sudo ufw allow 9093/tcp    # AlertManager (optional)

# Enable firewall
sudo ufw enable
```

## 🔍 Port Conflicts đã fix

| Original Port | New Port | Service | Reason |
|---------------|----------|---------|--------|
| 22 | **2222** | GitLab SSH | Conflict với SSH system |
| 80 | **8090** | Harbor | Conflict với GitLab HTTP |
| 8080 | **8888** | cAdvisor | Conflict với Jenkins |

## 🌐 Access URLs

```bash
# Production URLs (thay localhost bằng domain/IP của bạn)
GitLab:       http://your-server/
              ssh://git@your-server:2222/user/repo.git

Jenkins:      http://your-server:8080

SonarQube:    http://your-server:9000

Nexus:        http://your-server:8081
              http://your-server:8082  # Docker hosted
              http://your-server:8083  # Docker group

Harbor:       http://your-server:8090
              docker login your-server:8090

Prometheus:   http://your-server:9090

Grafana:      http://your-server:3000

AlertManager: http://your-server:9093

cAdvisor:     http://your-server:8888
```

## 🔒 Internal Network Ports

Các services này chỉ giao tiếp nội bộ qua Docker network, không cần expose:

| Service | Internal Port | Purpose |
|---------|---------------|---------|
| PostgreSQL (GitLab) | 5432 | Database |
| Redis (GitLab) | 6379 | Cache |
| PostgreSQL (SonarQube) | 5432 | Database |
| PostgreSQL (Harbor) | 5432 | Database |

## 📝 Git Clone với SSH port khác

```bash
# Standard SSH (port 22)
git clone git@server:username/repo.git

# Custom SSH port (2222) - GitLab
git clone ssh://git@server:2222/username/repo.git

# Hoặc config trong ~/.ssh/config
Host gitlab
    HostName your-server
    User git
    Port 2222

# Sau đó clone đơn giản:
git clone gitlab:username/repo.git
```

## 🐳 Docker Registry Usage

### Nexus Docker Registry

```bash
# Login
docker login your-server:8082

# Tag & Push
docker tag myapp:latest your-server:8082/myapp:latest
docker push your-server:8082/myapp:latest

# Pull
docker pull your-server:8082/myapp:latest
```

### Harbor Registry

```bash
# Login
docker login your-server:8090

# Tag & Push
docker tag myapp:latest your-server:8090/library/myapp:latest
docker push your-server:8090/library/myapp:latest

# Pull
docker pull your-server:8090/library/myapp:latest
```

## ⚙️ Check Port Usage

```bash
# Check if port is in use
sudo netstat -tulpn | grep :8080
sudo ss -tulpn | grep :8080

# List all listening ports
sudo netstat -tulpn | grep LISTEN

# Check Docker container ports
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

## 🚨 Port Troubleshooting

### Port already in use

```bash
# Find process using port
sudo lsof -i :8080

# Kill process
sudo kill -9 <PID>

# Or stop container
docker stop <container-name>
```

### Change port for a service

```bash
# Edit docker-compose.yml
cd /srv/<service>
nano docker-compose.yml

# Change ports section, e.g.:
ports:
  - '8090:8080'  # host:container

# Restart
docker compose down
docker compose up -d
```

## 📋 Port Requirements Summary

**Minimum ports cần mở để access từ bên ngoài:**
- GitLab: 80, 2222
- Jenkins: 8080  
- SonarQube: 9000
- Nexus: 8081
- Harbor: 8090
- Grafana: 3000

**Optional ports:**
- Prometheus: 9090 (có thể chỉ access qua Grafana)
- AlertManager: 9093 (có thể chỉ dùng internal)
- cAdvisor: 8888 (có thể chỉ dùng internal)
- Nexus Docker: 8082, 8083 (nếu dùng Docker registry)
