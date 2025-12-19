# Troubleshooting Guide

## Port Conflicts đã fix

### GitLab SSH Port
- **Lỗi**: Port 22 conflict với SSH hệ thống
- **Fix**: Đổi sang port 2222
- **Git clone sẽ dùng**: `git clone ssh://git@localhost:2222/username/repo.git`

### cAdvisor Port  
- **Lỗi**: Port 8080 conflict với Jenkins
- **Fix**: Đổi sang port 8888
- **Access**: http://localhost:8888

### Harbor
- **Lỗi**: Cần prepare trước khi install
- **Fix**: Đã thêm `./prepare --with-trivy` trước install

## Cách xử lý sau khi fix

### 1. Stop tất cả containers hiện tại

```bash
# Stop GitLab (nếu đang chạy)
cd /srv/gitlab && docker compose down

# Stop Monitoring stack
cd /srv/monitoring && docker compose down
```

### 2. Chạy lại từng tool bị lỗi

```bash
cd devops-tool/install

# Cài lại GitLab với port mới
sudo ./gitlab.sh

# Cài lại Harbor
sudo ./harbor.sh

# Cài lại Monitoring
sudo ./monitoring.sh
```

## Kiểm tra ports đang dùng

```bash
# Check port usage
sudo netstat -tulpn | grep LISTEN

# Hoặc
sudo ss -tulpn | grep LISTEN
```

## Ports sau khi fix

| Service | Old Port | New Port | Reason |
|---------|----------|----------|--------|
| GitLab SSH | 22 | **2222** | SSH system conflict |
| GitLab HTTP | 80 | 80 | ✓ OK |
| Jenkins | 8080 | 8080 | ✓ OK |
| SonarQube | 9000 | 9000 | ✓ OK |
| Nexus | 8081 | 8081 | ✓ OK |
| cAdvisor | 8080 | **8888** | Jenkins conflict |
| Prometheus | 9090 | 9090 | ✓ OK |
| Grafana | 3000 | 3000 | ✓ OK |

## Update Git remote URL (nếu dùng GitLab SSH)

```bash
# Thay vì port 22, dùng port 2222
git remote set-url origin ssh://git@your-server:2222/username/repo.git
```

## Services đã cài thành công

✅ Jenkins - http://localhost:8080
✅ SonarQube - http://localhost:9000  
✅ Nexus - http://localhost:8081

Password Nexus: `c4b9b3cd-2c98-483c-a369-7d5a39794bc6`
