#!/bin/bash

###############################################################################
# GitLab CE Installation Script for Debian 12
# Cài đặt GitLab Community Edition với Docker
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITLAB_HOME="/srv/gitlab"
GITLAB_VERSION="latest"
GITLAB_EXTERNAL_URL="${GITLAB_EXTERNAL_URL:-http://gitlab.local}"
GITLAB_ROOT_PASSWORD="${GITLAB_ROOT_PASSWORD:-ChangeMe123!}"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}GitLab CE Installation${NC}"
echo -e "${GREEN}=====================================${NC}"

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root or with sudo${NC}"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    echo -e "\n${YELLOW}Checking system requirements...${NC}"
    
    # Check RAM (GitLab needs at least 4GB)
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    if [ $TOTAL_RAM -lt 4 ]; then
        echo -e "${RED}⚠️  Warning: GitLab requires at least 4GB RAM${NC}"
        echo -e "${RED}   Current RAM: ${TOTAL_RAM}GB${NC}"
        read -p "Continue anyway? (yes/no): " CONTINUE
        if [ "$CONTINUE" != "yes" ]; then
            exit 1
        fi
    fi
    
    # Check disk space (at least 10GB free)
    FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $FREE_SPACE -lt 10 ]; then
        echo -e "${RED}⚠️  Warning: At least 10GB free disk space recommended${NC}"
        echo -e "${RED}   Current free space: ${FREE_SPACE}GB${NC}"
    fi
    
    echo -e "${GREEN}✓ System requirements check completed${NC}"
}

# Install Docker if not present
install_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker already installed${NC}"
    else
        echo -e "\n${YELLOW}Installing Docker...${NC}"
        
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release
        
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
    
    mkdir -p $GITLAB_HOME/config
    mkdir -p $GITLAB_HOME/logs
    mkdir -p $GITLAB_HOME/data
    mkdir -p $GITLAB_HOME/backups
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Create docker-compose file
create_compose_file() {
    echo -e "\n${YELLOW}Creating docker-compose configuration...${NC}"
    
    cat > $GITLAB_HOME/docker-compose.yml <<EOF
version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:${GITLAB_VERSION}
    container_name: gitlab
    restart: always
    hostname: gitlab.local
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${GITLAB_EXTERNAL_URL}'
        gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'
        
        # GitLab Rails
        gitlab_rails['time_zone'] = 'Asia/Ho_Chi_Minh'
        gitlab_rails['gitlab_email_enabled'] = true
        gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
        gitlab_rails['gitlab_email_display_name'] = 'GitLab'
        
        # Backup settings
        gitlab_rails['backup_keep_time'] = 604800
        gitlab_rails['backup_path'] = '/var/opt/gitlab/backups'
        
        # Performance tuning
        postgresql['shared_buffers'] = "256MB"
        postgresql['max_connections'] = 200
        
        # Disable unused services to save resources
        prometheus_monitoring['enable'] = false
        
        # Registry (optional)
        registry_external_url 'https://registry.example.com'
        gitlab_rails['registry_enabled'] = true
        
        # Let's Encrypt (disable if using external SSL)
        letsencrypt['enable'] = false
        
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'  # Changed from 22 to 2222 to avoid SSH conflict
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
      - '$GITLAB_HOME/backups:/var/opt/gitlab/backups'
    shm_size: '256m'
    networks:
      - gitlab-network

networks:
  gitlab-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}✓ Docker compose file created${NC}"
}

# Start GitLab
start_gitlab() {
    echo -e "\n${YELLOW}Starting GitLab...${NC}"
    echo -e "${YELLOW}This may take several minutes on first run...${NC}"
    
    cd $GITLAB_HOME
    docker compose up -d
    
    echo -e "${GREEN}✓ GitLab container started${NC}"
}

# Wait for GitLab to be ready
wait_for_gitlab() {
    echo -e "\n${YELLOW}Waiting for GitLab to be ready...${NC}"
    echo -e "${YELLOW}This usually takes 3-5 minutes...${NC}"
    
    COUNTER=0
    MAX_TRIES=60
    
    while [ $COUNTER -lt $MAX_TRIES ]; do
        if docker exec gitlab gitlab-rake gitlab:check SANITIZE=true &> /dev/null; then
            echo -e "${GREEN}✓ GitLab is ready!${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 10
        COUNTER=$((COUNTER + 1))
    done
    
    echo -e "\n${YELLOW}⚠️  GitLab is still starting up. This is normal.${NC}"
    echo -e "${YELLOW}   You can check status with: docker logs -f gitlab${NC}"
}

# Create backup script
create_backup_script() {
    echo -e "\n${YELLOW}Creating backup script...${NC}"
    
    cat > $GITLAB_HOME/backup.sh <<'EOF'
#!/bin/bash

# Backup GitLab
echo "Starting GitLab backup..."

# Create backup
docker exec -t gitlab gitlab-backup create

# Backup configuration
cd /srv/gitlab
tar -czf config-backup-$(date +%Y%m%d_%H%M%S).tar.gz config/

echo "Backup completed!"
echo "Backups are stored in: /srv/gitlab/backups/"
EOF
    
    chmod +x $GITLAB_HOME/backup.sh
    
    # Create cron job for daily backups
    (crontab -l 2>/dev/null; echo "0 2 * * * $GITLAB_HOME/backup.sh >> $GITLAB_HOME/logs/backup.log 2>&1") | crontab -
    
    echo -e "${GREEN}✓ Backup script created (scheduled daily at 2 AM)${NC}"
}

# Display info
display_info() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}GitLab Installation Completed!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${BLUE}Access Information:${NC}"
    echo -e "  URL: ${GITLAB_EXTERNAL_URL}"
    echo -e "  Username: ${YELLOW}root${NC}"
    echo -e "  Password: ${YELLOW}${GITLAB_ROOT_PASSWORD}${NC}"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  Check status:    ${YELLOW}docker ps${NC}"
    echo -e "  View logs:       ${YELLOW}docker logs -f gitlab${NC}"
    echo -e "  Restart:         ${YELLOW}docker restart gitlab${NC}"
    echo -e "  Backup:          ${YELLOW}$GITLAB_HOME/backup.sh${NC}"
    echo -e "  GitLab Console:  ${YELLOW}docker exec -it gitlab gitlab-rails console${NC}"
    
    echo -e "\n${BLUE}Configuration:${NC}"
    echo -e "  Config:          ${GITLAB_HOME}/config/gitlab.rb"
    echo -e "  Data:            ${GITLAB_HOME}/data"
    echo -e "  Logs:            ${GITLAB_HOME}/logs"
    echo -e "  Backups:         ${GITLAB_HOME}/backups"
    
    echo -e "\n${YELLOW}Note: GitLab may take 3-5 minutes to fully start${NC}"
    echo -e "${YELLOW}Check readiness: docker exec gitlab gitlab-ctl status${NC}"
}

# Main execution
main() {
    check_root
    check_requirements
    install_docker
    create_directories
    create_compose_file
    start_gitlab
    wait_for_gitlab
    create_backup_script
    display_info
}

main
