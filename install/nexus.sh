#!/bin/bash

###############################################################################
# Nexus Repository Installation Script for Debian 12
# Cài đặt Nexus Repository Manager OSS
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NEXUS_HOME="/srv/nexus"
NEXUS_PORT="${NEXUS_PORT:-8081}"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Nexus Repository Installation${NC}"
echo -e "${GREEN}=====================================${NC}"

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root or with sudo${NC}"
        exit 1
    fi
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
    
    mkdir -p $NEXUS_HOME/data
    mkdir -p $NEXUS_HOME/backups
    
    # Nexus runs as UID 200
    chown -R 200:200 $NEXUS_HOME/data
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Create docker-compose file
create_compose_file() {
    echo -e "\n${YELLOW}Creating docker-compose configuration...${NC}"
    
    cat > $NEXUS_HOME/docker-compose.yml <<EOF
version: '3.8'

services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    restart: always
    ports:
      - '${NEXUS_PORT}:8081'
      - '8082:8082'  # Docker hosted repository
      - '8083:8083'  # Docker group repository
    volumes:
      - '$NEXUS_HOME/data:/nexus-data'
    environment:
      - INSTALL4J_ADD_VM_PARAMS=-Xms1g -Xmx2g -XX:MaxDirectMemorySize=2g
    networks:
      - nexus-network

networks:
  nexus-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}✓ Docker compose file created${NC}"
}

# Start Nexus
start_nexus() {
    echo -e "\n${YELLOW}Starting Nexus Repository...${NC}"
    echo -e "${YELLOW}This may take 2-3 minutes...${NC}"
    
    cd $NEXUS_HOME
    docker compose up -d
    
    echo -e "${GREEN}✓ Nexus container started${NC}"
}

# Wait for Nexus to be ready
wait_for_nexus() {
    echo -e "\n${YELLOW}Waiting for Nexus to be ready...${NC}"
    
    COUNTER=0
    MAX_TRIES=60
    
    while [ $COUNTER -lt $MAX_TRIES ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:${NEXUS_PORT} | grep -q "200\|403"; then
            echo -e "\n${GREEN}✓ Nexus is ready!${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 5
        COUNTER=$((COUNTER + 1))
    done
    
    echo -e "\n${YELLOW}⚠️  Nexus is still starting up${NC}"
}

# Get initial admin password
get_admin_password() {
    echo -e "\n${YELLOW}Retrieving initial admin password...${NC}"
    
    sleep 10
    
    if [ -f "$NEXUS_HOME/data/admin.password" ]; then
        ADMIN_PASSWORD=$(cat $NEXUS_HOME/data/admin.password)
        echo -e "${GREEN}✓ Initial admin password retrieved${NC}"
    else
        echo -e "${YELLOW}⚠️  Password file not yet created${NC}"
        ADMIN_PASSWORD="Check /srv/nexus/data/admin.password"
    fi
}

# Create backup script
create_backup_script() {
    echo -e "\n${YELLOW}Creating backup script...${NC}"
    
    cat > $NEXUS_HOME/backup.sh <<'EOF'
#!/bin/bash

# Backup Nexus
BACKUP_DIR="/srv/nexus/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Starting Nexus backup..."

# Create backup
tar -czf $BACKUP_DIR/nexus-backup-$TIMESTAMP.tar.gz -C /srv/nexus/data .

echo "Backup completed: $BACKUP_DIR/nexus-backup-$TIMESTAMP.tar.gz"

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t nexus-backup-*.tar.gz | tail -n +8 | xargs -r rm

echo "Old backups cleaned up"
EOF
    
    chmod +x $NEXUS_HOME/backup.sh
    
    # Create cron job
    (crontab -l 2>/dev/null; echo "0 5 * * * $NEXUS_HOME/backup.sh >> $NEXUS_HOME/backup.log 2>&1") | crontab -
    
    echo -e "${GREEN}✓ Backup script created (scheduled daily at 5 AM)${NC}"
}

# Display info
display_info() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}Nexus Installation Completed!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${BLUE}Access Information:${NC}"
    echo -e "  URL: ${YELLOW}http://localhost:${NEXUS_PORT}${NC}"
    echo -e "  Username: ${YELLOW}admin${NC}"
    echo -e "  Initial Password: ${YELLOW}${ADMIN_PASSWORD}${NC}"
    
    echo -e "\n${BLUE}Repository Ports:${NC}"
    echo -e "  Web UI:          ${NEXUS_PORT}"
    echo -e "  Docker hosted:   8082"
    echo -e "  Docker group:    8083"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  View logs:       ${YELLOW}docker logs -f nexus${NC}"
    echo -e "  Restart:         ${YELLOW}docker restart nexus${NC}"
    echo -e "  Backup:          ${YELLOW}$NEXUS_HOME/backup.sh${NC}"
    echo -e "  Nexus Shell:     ${YELLOW}docker exec -it nexus bash${NC}"
    
    echo -e "\n${BLUE}Configuration:${NC}"
    echo -e "  Data:            ${NEXUS_HOME}/data"
    echo -e "  Backups:         ${NEXUS_HOME}/backups"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Open ${YELLOW}http://localhost:${NEXUS_PORT}${NC}"
    echo -e "  2. Click 'Sign in' (top right)"
    echo -e "  3. Login with admin and the initial password"
    echo -e "  4. Change the password when prompted"
    echo -e "  5. Configure repositories as needed"
    
    echo -e "\n${BLUE}Common Repository Types:${NC}"
    echo -e "  - Maven (Java artifacts)"
    echo -e "  - npm (Node.js packages)"
    echo -e "  - Docker (Container images)"
    echo -e "  - PyPI (Python packages)"
    echo -e "  - Raw (Generic files)"
}

# Main execution
main() {
    check_root
    install_docker
    create_directories
    create_compose_file
    start_nexus
    wait_for_nexus
    get_admin_password
    create_backup_script
    display_info
}

main
