#!/bin/bash

###############################################################################
# Monitoring Stack Installation Script for Debian 12
# Cài đặt Prometheus + Grafana + Node Exporter + AlertManager
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MONITORING_HOME="/srv/monitoring"
PROMETHEUS_PORT="9090"
GRAFANA_PORT="3000"
ALERTMANAGER_PORT="9093"
NODE_EXPORTER_PORT="9100"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Monitoring Stack Installation${NC}"
echo -e "${GREEN}=====================================${NC}"

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root or with sudo${NC}"
        exit 1
    fi
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker already installed${NC}"
    else
        echo -e "\n${YELLOW}Installing Docker...${NC}"
        
        apt-get update
        apt-get install -y ca-certificates curl gnupg
        
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        systemctl enable docker
        systemctl start docker
        
        echo -e "${GREEN}✓ Docker installed${NC}"
    fi
}

# Create directory structure
create_directories() {
    echo -e "\n${YELLOW}Creating directory structure...${NC}"
    
    mkdir -p $MONITORING_HOME/prometheus/data
    mkdir -p $MONITORING_HOME/prometheus/config
    mkdir -p $MONITORING_HOME/grafana/data
    mkdir -p $MONITORING_HOME/grafana/provisioning/datasources
    mkdir -p $MONITORING_HOME/grafana/provisioning/dashboards
    mkdir -p $MONITORING_HOME/alertmanager/data
    mkdir -p $MONITORING_HOME/alertmanager/config
    
    # Set permissions
    chown -R 65534:65534 $MONITORING_HOME/prometheus/data
    chown -R 472:472 $MONITORING_HOME/grafana/data
    chown -R 65534:65534 $MONITORING_HOME/alertmanager/data
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Create Prometheus configuration
create_prometheus_config() {
    echo -e "\n${YELLOW}Creating Prometheus configuration...${NC}"
    
    cat > $MONITORING_HOME/prometheus/config/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'devops-cluster'
    environment: 'production'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load rules once and periodically evaluate them
rule_files:
  - '/etc/prometheus/alerts/*.yml'

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # Docker containers (cAdvisor)
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  # Add your application metrics here
  # - job_name: 'myapp'
  #   static_configs:
  #     - targets: ['myapp:8080']
EOF
    
    # Create alerts directory and sample alert rules
    mkdir -p $MONITORING_HOME/prometheus/config/alerts
    
    cat > $MONITORING_HOME/prometheus/config/alerts/node-alerts.yml <<'EOF'
groups:
  - name: node_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% (current value: {{ $value }}%)"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 80% (current value: {{ $value }}%)"

      - alert: DiskSpaceLow
        expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space"
          description: "Disk usage is above 80% (current value: {{ $value }}%)"

      - alert: ServiceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Service is down"
          description: "{{ $labels.job }} on {{ $labels.instance }} is down"
EOF
    
    echo -e "${GREEN}✓ Prometheus configuration created${NC}"
}

# Create AlertManager configuration
create_alertmanager_config() {
    echo -e "\n${YELLOW}Creating AlertManager configuration...${NC}"
    
    cat > $MONITORING_HOME/alertmanager/config/alertmanager.yml <<'EOF'
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical'
    - match:
        severity: warning
      receiver: 'warning'

receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true

  - name: 'critical'
    # Email configuration (uncomment and configure)
    # email_configs:
    #   - to: 'admin@example.com'
    #     from: 'alertmanager@example.com'
    #     smarthost: 'smtp.gmail.com:587'
    #     auth_username: 'your-email@gmail.com'
    #     auth_password: 'your-app-password'
    
    # Slack configuration (uncomment and configure)
    # slack_configs:
    #   - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    #     channel: '#alerts'
    #     title: 'CRITICAL: {{ .GroupLabels.alertname }}'
    
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true

  - name: 'warning'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'
        send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
EOF
    
    echo -e "${GREEN}✓ AlertManager configuration created${NC}"
}

# Create Grafana datasource
create_grafana_datasource() {
    echo -e "\n${YELLOW}Creating Grafana datasource...${NC}"
    
    cat > $MONITORING_HOME/grafana/provisioning/datasources/prometheus.yml <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF
    
    echo -e "${GREEN}✓ Grafana datasource created${NC}"
}

# Create docker-compose file
create_compose_file() {
    echo -e "\n${YELLOW}Creating docker-compose configuration...${NC}"
    
    cat > $MONITORING_HOME/docker-compose.yml <<EOF
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: always
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    ports:
      - '${PROMETHEUS_PORT}:9090'
    volumes:
      - '$MONITORING_HOME/prometheus/config:/etc/prometheus'
      - '$MONITORING_HOME/prometheus/data:/prometheus'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: always
    ports:
      - '${GRAFANA_PORT}:3000'
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_ROOT_URL=http://localhost:3000
    volumes:
      - '$MONITORING_HOME/grafana/data:/var/lib/grafana'
      - '$MONITORING_HOME/grafana/provisioning:/etc/grafana/provisioning'
    networks:
      - monitoring
    depends_on:
      - prometheus

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: always
    ports:
      - '${ALERTMANAGER_PORT}:9093'
    volumes:
      - '$MONITORING_HOME/alertmanager/config:/etc/alertmanager'
      - '$MONITORING_HOME/alertmanager/data:/alertmanager'
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: always
    ports:
      - '${NODE_EXPORTER_PORT}:9100'
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - '/proc:/host/proc:ro'
      - '/sys:/host/sys:ro'
      - '/:/rootfs:ro'
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: always
    ports:
      - '8888:8080'  # Changed from 8080 to 8888 to avoid Jenkins conflict
    volumes:
      - '/:/rootfs:ro'
      - '/var/run:/var/run:ro'
      - '/sys:/sys:ro'
      - '/var/lib/docker:/var/lib/docker:ro'
      - '/dev/disk/:/dev/disk:ro'
    privileged: true
    devices:
      - '/dev/kmsg'
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
EOF
    
    echo -e "${GREEN}✓ Docker compose file created${NC}"
}

# Start monitoring stack
start_monitoring() {
    echo -e "\n${YELLOW}Starting monitoring stack...${NC}"
    
    cd $MONITORING_HOME
    docker compose up -d
    
    echo -e "${GREEN}✓ Monitoring stack started${NC}"
}

# Display info
display_info() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}Monitoring Stack Installation Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${BLUE}Access Information:${NC}"
    echo -e "  Prometheus:      ${YELLOW}http://localhost:${PROMETHEUS_PORT}${NC}"
    echo -e "  Grafana:         ${YELLOW}http://localhost:${GRAFANA_PORT}${NC}"
    echo -e "  AlertManager:    ${YELLOW}http://localhost:${ALERTMANAGER_PORT}${NC}"
    echo -e "  Node Exporter:   ${YELLOW}http://localhost:${NODE_EXPORTER_PORT}${NC}"
    echo -e "  cAdvisor:        ${YELLOW}http://localhost:8888${NC}"
    
    echo -e "\n${BLUE}Grafana Login:${NC}"
    echo -e "  Username: ${YELLOW}admin${NC}"
    echo -e "  Password: ${YELLOW}admin${NC}"
    echo -e "  (You'll be prompted to change on first login)"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  View logs:       ${YELLOW}cd $MONITORING_HOME && docker compose logs -f${NC}"
    echo -e "  Restart:         ${YELLOW}cd $MONITORING_HOME && docker compose restart${NC}"
    echo -e "  Stop:            ${YELLOW}cd $MONITORING_HOME && docker compose down${NC}"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Open Grafana: ${YELLOW}http://localhost:${GRAFANA_PORT}${NC}"
    echo -e "  2. Login and change password"
    echo -e "  3. Import dashboards:"
    echo -e "     - Node Exporter Full (ID: 1860)"
    echo -e "     - Docker Container & Host Metrics (ID: 179)"
    echo -e "  4. Configure AlertManager notifications in:"
    echo -e "     ${MONITORING_HOME}/alertmanager/config/alertmanager.yml"
    echo -e "  5. Add custom metrics endpoints in:"
    echo -e "     ${MONITORING_HOME}/prometheus/config/prometheus.yml"
}

# Main execution
main() {
    check_root
    install_docker
    create_directories
    create_prometheus_config
    create_alertmanager_config
    create_grafana_datasource
    create_compose_file
    start_monitoring
    display_info
}

main
