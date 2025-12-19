# DevOps Essential Stack

Bộ script tự động cài đặt 3 tool DevOps thiết yếu trên Debian 12: **GitLab + Jenkins + SonarQube**

## 🎯 Các Tool

| Tool | Mục đích | RAM | Port |
|------|----------|-----|------|
| **GitLab CE** | Source control & CI/CD | ~4GB | 80, 2222 |
| **Jenkins** | Automation server | ~2GB | 8080 |
| **SonarQube** | Code quality & security | ~2GB | 9000 |

**Tổng RAM cần thiết**: ~8GB

## ⚠️ Yêu cầu hệ thống

### Tối thiểu:
- **RAM**: 8GB
- **CPU**: 4 cores
- **Disk**: 40GB free space
- **OS**: Debian 12 (Bookworm)

### Khuyến nghị:
- **RAM**: 12GB+ (8GB services + 4GB hệ thống)
- **CPU**: 4+ cores
- **Disk**: 50GB+ free space

### ⚡ Nếu RAM < 12GB:
Tạo swap 4-8GB để tránh OOM:
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 🚀 Tính năng

- ✅ Cài đặt tự động từng tool hoặc cả 3
- ✅ Docker-based deployment
- ✅ Tự động backup hàng ngày
- ✅ Cấu hình tối ưu cho Debian 12
- ✅ Script đơn giản, dễ customize

## 📁 Cấu trúc Project

```
devops-tool/
├── README.md           # Tài liệu này
├── QUICKSTART.md       # Hướng dẫn nhanh
├── TOOLS.md            # Chi tiết về từng tool
└── install/            # Installation scripts
    ├── all.sh          # Menu cài đặt (khuyến nghị)
    ├── gitlab.sh       # Cài riêng GitLab
    ├── jenkins.sh      # Cài riêng Jenkins
    └── sonarqube.sh    # Cài riêng SonarQube
```

## � Cài đặt

### Bước 1: Kiểm tra tài nguyên hệ thống

**LUÔN CHẠY LỆNH NÀY TRƯỚC TIÊN!**

```bash
cd devops-tool
chmod +x utils/check-resources.sh
sudo ./utils/check-resources.sh
```

Script này sẽ:
- Kiểm tra RAM, CPU, Disk
- Đưa ra khuyến nghị cài đặt
- Cảnh báo nếu thiếu tài nguyên

### Bước 2: Tạo Swap (nếu RAM < 16GB)

```bash
chmod +x utils/create-swap.sh
sudo ./utils/create-swap.sh
# Chọn option 2 (8GB swap)
```

### Bước 3: Chọn phương thức cài đặt

#### A. Server có 16GB+ RAM → Cài đầy đủ

```bash
chmod +x install/staggered.sh
sudo ./install/staggered.sh
```

Cài tất cả services với delays giữa mỗi service để tránh overload.

#### B. Server có 8-16GB RAM → Cài nhẹ

```bash
chmod +x install/lightweight.sh
sudo ./install/lightweight.sh
```

Chỉ cài services thiết yếu: GitLab + Jenkins + SonarQube

#### C. Server có < 8GB RAM → Cài từng service

```bash
# Chỉ cài service quan trọng nhất trước
chmod +x install/gitlab.sh
sudo ./install/gitlab.sh

# Đợi GitLab ổn định rồi mới cài tiếp
chmod +x install/jenkins.sh
sudo ./install/jenkins.sh
```

### ⚠️ KHÔNG nên dùng (trừ khi có 16GB+ RAM):

```bash
# ❌ CẢNH BÁO: Sẽ crash server nếu RAM thấp!
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
- U🔐 Access & Credentials

### GitLab
- **URL**: http://localhost hoặc http://YOUR_SERVER_IP
- **SSH Port**: 2222 (thay vì 22)
- **Username**: `root`
- **Password**: Đặt khi lần đầu truy cập

**Clone repo với SSH:**
```basFirewall Configuration

```bash
# GitLab
sudo ufw allow 80/tcp
sudo ufw allow 2222/tcp  # GitLab SSH

# Jenkins
sudo ufw allow 8080/tcp

# SonarQube
sudo ufw allow 9000/tcp

# Enable firewall
sudo ufw enable
```

## 💾 Backup

Tất cả services đã được cấu hình backup tự động:

### GitLab
- **Backup location**: `/srv/gitlab/backups`
- **Schedule**: Hàng ngày lúc 2:00 AM
- **Manual backup**:
```bash
docker exec -t gitlab gitlab-backup create
```

### Jenkins
- **Backup location**: `/srv/jenkins/backups`
- **Schedule**: Hàng ngày lúc 3:00 AM
- **Manual backup**:
```bash
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /srv/jenkins/data
```

### SonarQube
- **Backup location**: `/srv/sonarqube/backups`
- **Schedule**: Hàng ngày lúc 4:00 AM
- **Manual backup**:
```bash
docker exec sonarqube-db pg_dump -U sonar sonar > sonar-backup-$(date +%Y%m%d).sql
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

# ChangQuản lý Services

### Kiểm tra trạng thái

```bash
docker ps
docker stats --no-stream
```

### Restart service

```bash
cd /srv/gitlab && docker compose restart
cd /srv/jenkins && docker compose restart
cd /srv/sonarqube && docker compose restart
```

### Stop service

```bash
cd /srv/gitlab && docker compose down
cd /srv/jenkins && docker compose down
cd /srv/sonarqube && docker compose down
```

### Xem logs

```bash
docker logs -f gitlab
docker logs -f jenkins
docker logs -f sonarqube
```

## 🛠️ Troubleshooting

### Service không start

```bash
# Check Docker
sudo systemctl status docker

# Check logs
docker logs [container-name]

# Check RAM
free -h
docker stats
```

### Port đã được sử dụng

```bash
# Check port
sudo netstat -tulpn | grep [port]

# Hoặc dùng ss
sudo ss -tulpn | grep [port]
```

### GitLab SSH port 2222

Khi clone repo:
```bash
# Sai
git clone git@server:user/repo.git

# Đúng
git clone ssh://git@server:2222/user/repo.git
```

## 🎯 DevOps Workflow

```
1. Developer viết code
   ↓
2. Push lên GitLab
   ↓
3. GitLab trigger Jenkins pipeline
   ↓
4. Jenkins:
   - Checkout code
   - Run tests
   - SonarQube scan (quality gate)
   - Build application
   - Deploy (nếu pass all checks)
   ↓
5. Production running
```

## 📖 Tài liệu thêm

- [QUICKSTART.md](QUICKSTART.md) - Hướng dẫn nhanh
- [TOOLS.md](TOOLS.md) - Chi tiết về từng tool
- [GitLab Docs](https://docs.gitlab.com/)
- [Jenkins Docs](https://www.jenkins.io/doc/)
- [SonarQube Docs](https://docs.sonarqube.org/)

## 📝 License

MIT License

---

**Repository**: https://github.com/kietcaodev/devops-tool

**Made for**: