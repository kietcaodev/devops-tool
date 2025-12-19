# Các Tool DevOps và Công Dụng

## 🔧 Tổng quan các tool trong stack

### 1. GitLab CE 🦊
**Dùng để làm gì:**
- Quản lý source code (Git repository)
- Version control cho team
- Code review qua Merge Requests
- CI/CD tích hợp sẵn (GitLab CI)
- Issue tracking & project management
- Wiki cho documentation

**Khi nào dùng:** 
- Lưu trữ code của team
- Tự động build/test/deploy qua GitLab CI
- Thay thế GitHub/Bitbucket nhưng self-hosted

**Port:** 80, 443, 22

---

### 2. Jenkins 🤖
**Dùng để làm gì:**
- Automation server - tự động hóa mọi thứ
- CI/CD pipelines (build, test, deploy)
- Scheduled jobs & cron tasks
- Integration với GitLab, GitHub, Docker, K8s
- Plugin ecosystem khổng lồ (1000+ plugins)

**Khi nào dùng:**
- Cần pipeline phức tạp, custom nhiều
- Tích hợp với nhiều tool khác nhau
- Build & deploy tự động khi có code mới

**Port:** 8080

---

### 3. SonarQube 🔍
**Dùng để làm gì:**
- Phân tích chất lượng code (code quality)
- Tìm bugs, vulnerabilities, code smells
- Security scan - tìm lỗ hổng bảo mật
- Code coverage tracking
- Technical debt measurement

**Khi nào dùng:**
- Check code quality trước khi merge
- Ensure coding standards
- Tìm security issues sớm
- Tích hợp vào CI pipeline

**Port:** 9000

---

### 4. Nexus Repository 📦
**Dùng để làm gì:**
- Artifact repository manager
- Lưu trữ build artifacts (JAR, WAR, NPM packages, etc.)
- Private registry cho Maven, npm, Docker, PyPI
- Proxy & cache public repositories
- Version management cho libraries

**Khi nào dùng:**
- Lưu trữ packages nội bộ
- Cache dependencies để build nhanh hơn
- Share libraries giữa các projects
- Quản lý versions của artifacts

**Port:** 8081 (web), 8082 (docker hosted), 8083 (docker group)

---

### 5. Harbor 🚢
**Dùng để làm gì:**
- Private Docker Registry
- Quản lý & lưu trữ Docker images
- Vulnerability scanning cho images (Trivy)
- Access control & RBAC
- Image signing & replication
- Helm Chart repository

**Khi nào dùng:**
- Lưu trữ Docker images nội bộ
- Scan security issues trong images
- Quản lý container images cho team
- Không muốn push lên Docker Hub public

**Port:** 80/443

---

### 6. Prometheus 📊
**Dùng để làm gì:**
- Monitoring & alerting system
- Thu thập metrics từ services
- Time-series database
- Query metrics với PromQL
- Alert khi có vấn đề

**Khi nào dùng:**
- Monitor servers, containers, applications
- Theo dõi CPU, RAM, disk, network
- Alert khi service down hoặc resource cao

**Port:** 9090

---

### 7. Grafana 📈
**Dùng để làm gì:**
- Visualization & dashboards
- Hiển thị metrics từ Prometheus
- Beautiful charts & graphs
- Custom dashboards
- Alert notifications (email, Slack, etc.)

**Khi nào dùng:**
- Visualize metrics đẹp mắt
- Monitor real-time system health
- Tạo dashboard cho team/management
- Kết hợp với Prometheus

**Port:** 3000

---

## 🔄 Workflow DevOps hoàn chỉnh

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
   - SonarQube scan (check quality)
   - Build application
   - Push artifacts to Nexus
   - Build Docker image
   - Push image to Harbor
   - Deploy to server
   ↓
5. Prometheus monitor application
   ↓
6. Grafana visualize metrics
   ↓
7. Alert nếu có vấn đề
```

## 💼 Use Cases thực tế

### Scenario 1: Web Application
- **GitLab**: Lưu code React + Node.js
- **Jenkins**: Auto build & test khi commit
- **SonarQube**: Check code quality
- **Harbor**: Lưu Docker image
- **Prometheus + Grafana**: Monitor uptime, response time

### Scenario 2: Microservices
- **GitLab**: Quản lý nhiều repos (services)
- **Jenkins**: Build & deploy từng service
- **Nexus**: Share common libraries
- **Harbor**: Registry cho tất cả service images
- **Monitoring**: Track metrics của tất cả services

### Scenario 3: Team Development
- **GitLab**: Code review qua MR
- **SonarQube**: Quality gate (không pass = không merge)
- **Jenkins**: Auto deploy to staging khi merge
- **Nexus**: Share packages trong team
- **Grafana**: Dashboard cho cả team xem

## 🎯 Kết luận

| Tool | Category | Vai trò chính |
|------|----------|---------------|
| **GitLab** | Source Control | Nơi lưu code & CI/CD |
| **Jenkins** | CI/CD | Automation engine |
| **SonarQube** | Code Quality | Quality gate |
| **Nexus** | Artifacts | Package manager |
| **Harbor** | Registry | Docker image storage |
| **Prometheus** | Monitoring | Metrics collection |
| **Grafana** | Visualization | Dashboard & alerts |

---

**Lưu ý:** Không nhất thiết phải dùng tất cả! Chọn tools phù hợp với nhu cầu:
- **Nhỏ**: GitLab + Jenkins + Monitoring
- **Trung bình**: Thêm SonarQube + Nexus
- **Lớn**: Full stack như trên
