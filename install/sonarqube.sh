#!/bin/bash

###############################################################################
# SonarQube Installation Script for Debian 12
# Cài đặt SonarQube Community Edition với PostgreSQL
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SONAR_HOME="/srv/sonarqube"
SONAR_PORT="${SONAR_PORT:-9000}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-sonar123}"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}SonarQube Installation${NC}"
echo -e "${GREEN}=====================================${NC}"

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root or with sudo${NC}"
        exit 1
    fi
}

# Configure system for SonarQube
configure_system() {
    echo -e "\n${YELLOW}Configuring system parameters for SonarQube...${NC}"
    
    # Increase vm.max_map_count
    sysctl -w vm.max_map_count=524288
    sysctl -w fs.file-max=131072
    
    # Make changes permanent
    cat >> /etc/sysctl.conf <<EOF

# SonarQube requirements
vm.max_map_count=524288
fs.file-max=131072
EOF
    
    # Increase ulimit
    cat >> /etc/security/limits.conf <<EOF

# SonarQube requirements
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF
    
    echo -e "${GREEN}✓ System parameters configured${NC}"
}

# Install Docker if not present
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
        
        echo -e "${GREEN}✓ Docker installed successfully${NC}"
    fi
}

# Create directory structure
create_directories() {
    echo -e "\n${YELLOW}Creating directory structure...${NC}"
    
    mkdir -p $SONAR_HOME/data
    mkdir -p $SONAR_HOME/logs
    mkdir -p $SONAR_HOME/extensions
    mkdir -p $SONAR_HOME/postgres
    mkdir -p $SONAR_HOME/backups
    
    # Set proper permissions (SonarQube runs as UID 1000)
    chown -R 1000:1000 $SONAR_HOME/data
    chown -R 1000:1000 $SONAR_HOME/logs
    chown -R 1000:1000 $SONAR_HOME/extensions
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Create docker-compose file
create_compose_file() {
    echo -e "\n${YELLOW}Creating docker-compose configuration...${NC}"
    
    cat > $SONAR_HOME/docker-compose.yml <<EOF
version: '3.8'

services:
  postgres:
    image: postgres:15-bookworm
    container_name: sonarqube-postgres
    restart: always
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: sonarqube
    volumes:
      - '$SONAR_HOME/postgres:/var/lib/postgresql/data'
    networks:
      - sonar-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sonar"]
      interval: 10s
      timeout: 5s
      retries: 5

  sonarqube:
    image: sonarqube:lts-community
    container_name: sonarqube
    restart: always
    depends_on:
      - postgres
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: ${POSTGRES_PASSWORD}
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: true
    ports:
      - '${SONAR_PORT}:9000'
    volumes:
      - '$SONAR_HOME/data:/opt/sonarqube/data'
      - '$SONAR_HOME/logs:/opt/sonarqube/logs'
      - '$SONAR_HOME/extensions:/opt/sonarqube/extensions'
    networks:
      - sonar-network
    ulimits:
      nofile:
        soft: 131072
        hard: 131072
      nproc:
        soft: 8192
        hard: 8192

networks:
  sonar-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}✓ Docker compose file created${NC}"
}

# Start SonarQube
start_sonarqube() {
    echo -e "\n${YELLOW}Starting SonarQube...${NC}"
    echo -e "${YELLOW}This may take 2-3 minutes...${NC}"
    
    cd $SONAR_HOME
    docker compose up -d
    
    echo -e "${GREEN}✓ SonarQube containers started${NC}"
}

# Wait for SonarQube to be ready
wait_for_sonarqube() {
    echo -e "\n${YELLOW}Waiting for SonarQube to be ready...${NC}"
    
    COUNTER=0
    MAX_TRIES=60
    
    while [ $COUNTER -lt $MAX_TRIES ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:${SONAR_PORT}/api/system/status | grep -q "200"; then
            STATUS=$(curl -s http://localhost:${SONAR_PORT}/api/system/status | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            if [ "$STATUS" == "UP" ]; then
                echo -e "\n${GREEN}✓ SonarQube is ready!${NC}"
                return 0
            fi
        fi
        
        echo -n "."
        sleep 5
        COUNTER=$((COUNTER + 1))
    done
    
    echo -e "\n${YELLOW}⚠️  SonarQube is still starting up${NC}"
    echo -e "${YELLOW}   Check logs: docker logs -f sonarqube${NC}"
}

# Create backup script
create_backup_script() {
    echo -e "\n${YELLOW}Creating backup script...${NC}"
    
    cat > $SONAR_HOME/backup.sh <<'EOF'
#!/bin/bash

# Backup SonarQube
BACKUP_DIR="/srv/sonarqube/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Starting SonarQube backup..."

# Backup database
docker exec sonarqube-postgres pg_dump -U sonar sonarqube > $BACKUP_DIR/sonarqube-db-$TIMESTAMP.sql

# Backup data directory
tar -czf $BACKUP_DIR/sonarqube-data-$TIMESTAMP.tar.gz -C /srv/sonarqube data extensions

echo "Backup completed!"
echo "Database: $BACKUP_DIR/sonarqube-db-$TIMESTAMP.sql"
echo "Data: $BACKUP_DIR/sonarqube-data-$TIMESTAMP.tar.gz"

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t sonarqube-db-*.sql | tail -n +8 | xargs -r rm
ls -t sonarqube-data-*.tar.gz | tail -n +8 | xargs -r rm

echo "Old backups cleaned up"
EOF
    
    chmod +x $SONAR_HOME/backup.sh
    
    # Create cron job
    (crontab -l 2>/dev/null; echo "0 4 * * * $SONAR_HOME/backup.sh >> $SONAR_HOME/backup.log 2>&1") | crontab -
    
    echo -e "${GREEN}✓ Backup script created (scheduled daily at 4 AM)${NC}"
}

# Create scanner configuration example
create_scanner_config() {
    echo -e "\n${YELLOW}Creating scanner configuration example...${NC}"
    
    cat > $SONAR_HOME/sonar-project.properties.example <<EOF
# SonarQube Scanner Configuration Example
# Copy this file to your project root and customize

# Project identification
sonar.projectKey=my-project
sonar.projectName=My Project
sonar.projectVersion=1.0

# Source code location
sonar.sources=.
sonar.sourceEncoding=UTF-8

# Exclusions
sonar.exclusions=**/node_modules/**,**/vendor/**,**/*.test.js,**/*.spec.js

# SonarQube server
sonar.host.url=http://localhost:${SONAR_PORT}
sonar.login=YOUR_TOKEN_HERE

# Language-specific settings
# For JavaScript/TypeScript
#sonar.javascript.lcov.reportPaths=coverage/lcov.info

# For Java
#sonar.java.binaries=target/classes
#sonar.java.source=11

# For Python
#sonar.python.coverage.reportPaths=coverage.xml
EOF
    
    echo -e "${GREEN}✓ Scanner configuration example created${NC}"
}

# Display info
display_info() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}SonarQube Installation Completed!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${BLUE}Access Information:${NC}"
    echo -e "  URL: ${YELLOW}http://localhost:${SONAR_PORT}${NC}"
    echo -e "  Default Username: ${YELLOW}admin${NC}"
    echo -e "  Default Password: ${YELLOW}admin${NC}"
    echo -e "  ${RED}(You will be prompted to change the password on first login)${NC}"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  View logs:       ${YELLOW}docker logs -f sonarqube${NC}"
    echo -e "  Restart:         ${YELLOW}docker restart sonarqube${NC}"
    echo -e "  Backup:          ${YELLOW}$SONAR_HOME/backup.sh${NC}"
    echo -e "  SonarQube Shell: ${YELLOW}docker exec -it sonarqube bash${NC}"
    
    echo -e "\n${BLUE}Configuration:${NC}"
    echo -e "  Data:            ${SONAR_HOME}/data"
    echo -e "  Logs:            ${SONAR_HOME}/logs"
    echo -e "  Extensions:      ${SONAR_HOME}/extensions"
    echo -e "  Backups:         ${SONAR_HOME}/backups"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Open ${YELLOW}http://localhost:${SONAR_PORT}${NC}"
    echo -e "  2. Login with admin/admin"
    echo -e "  3. Change the default password"
    echo -e "  4. Generate a token: My Account > Security > Generate Tokens"
    echo -e "  5. Install SonarScanner: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/"
    echo -e "  6. Use example config: ${SONAR_HOME}/sonar-project.properties.example"
}

# Main execution
main() {
    check_root
    configure_system
    install_docker
    create_directories
    create_compose_file
    start_sonarqube
    wait_for_sonarqube
    create_backup_script
    create_scanner_config
    display_info
}

main
