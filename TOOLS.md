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

## 🔄 Workflow DevOps thiết yếu

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
   - Build application (nếu pass quality gate)
   - Build Docker image
   - Deploy to server
   ↓
5. Application running in production
```

## 💼 Use Cases thực tế

### Scenario 1: Web Application
- **GitLab**: Lưu code React + Node.js, CI/CD pipelines
- **Jenkins**: Auto build & test khi commit
- **SonarQube**: Check code quality, block bad code
- **Deploy**: Docker containers to production

### Scenario 2: Team Development
- **GitLab**: Code review qua Merge Requests
- **SonarQube**: Quality gate (không pass = không merge)
- **Jenkins**: Auto build & deploy khi merge
- **Result**: Code quality cao, deploy tự động

### Scenario 3: Continuous Deployment
- **GitLab**: Source control + issue tracking
- **Jenkins**: Complex pipelines với nhiều stages
- **SonarQube**: Security & quality checks
- **Outcome**: Deploy an toàn từ dev → production

## 🎯 Kết luận

| Tool | Category | Vai trò chính | RAM |
|------|----------|---------------|-----|
| **GitLab** | Source Control | Nơi lưu code & CI/CD | ~4GB |
| **Jenkins** | CI/CD | Automation engine | ~2GB |
| **SonarQube** | Code Quality | Quality gate | ~2GB |

**Tổng RAM cần thiết: ~8GB** (+ 8GB swap khuyến nghị)

---

## 🎯 Tại sao chỉ 3 tools này?

### ✅ Đủ để làm DevOps chuyên nghiệp:
- **GitLab**: Git + CI/CD + Issues → Thay thế GitHub + GitLab CI
- **Jenkins**: Automation mạnh mẽ → Build/Deploy phức tạp
- **SonarQube**: Code quality → Đảm bảo code sạch, an toàn

### 💰 Tiết kiệm tài nguyên:
- Nexus, Harbor, Prometheus, Grafana → **Optional**, chỉ cần khi scale lớn
- 8GB RAM là đủ (thay vì 16GB)
- Server nhỏ vẫn chạy mượt

### 🚀 Alternatives cho tools không cài:
- **Nexus** → Dùng Docker Hub, npmjs.com, Maven Central
- **Harbor** → Dùng Docker Hub hoặc GitLab Container Registry
- **Prometheus/Grafana** → Dùng GitLab built-in monitoring hoặc cloud monitoring

---

**Khuyến nghị:**
- **Startup/Team nhỏ**: 3 tools này là **VỪA ĐỦ**
- **Team lớn/Enterprise**: Cài thêm Nexus, Harbor, Monitoring sau khi có nhiều RAM hơn
