#!/bin/bash

###############################################################################
# Jenkins Installation Script for Debian 12
# Cài đặt Jenkins với Blue Ocean và Docker support
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
JENKINS_HOME="/srv/jenkins"
JENKINS_PORT="${JENKINS_PORT:-8080}"
JENKINS_AGENT_PORT="50000"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Jenkins Installation${NC}"
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
    
    mkdir -p $JENKINS_HOME/data
    mkdir -p $JENKINS_HOME/backups
    
    # Set proper permissions
    chown -R 1000:1000 $JENKINS_HOME/data
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Create custom Jenkins Dockerfile
create_dockerfile() {
    echo -e "\n${YELLOW}Creating Jenkins Dockerfile...${NC}"
    
    cat > $JENKINS_HOME/Dockerfile <<'EOF'
FROM jenkins/jenkins:lts-jdk17

USER root

# Install Docker CLI
RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install useful tools
RUN apt-get update && \
    apt-get install -y \
        git \
        vim \
        wget \
        unzip && \
    apt-get clean

# Install plugins
RUN jenkins-plugin-cli --plugins \
    blueocean \
    docker-workflow \
    docker-plugin \
    git \
    github \
    gitlab-plugin \
    pipeline-stage-view \
    workflow-aggregator \
    credentials-binding \
    ssh-agent \
    sonar \
    nodejs

USER jenkins
EOF
    
    echo -e "${GREEN}✓ Dockerfile created${NC}"
}

# Create docker-compose file
create_compose_file() {
    echo -e "\n${YELLOW}Creating docker-compose configuration...${NC}"
    
    cat > $JENKINS_HOME/docker-compose.yml <<EOF
version: '3.8'

services:
  jenkins:
    build: .
    container_name: jenkins
    restart: always
    privileged: true
    user: root
    ports:
      - '${JENKINS_PORT}:8080'
      - '${JENKINS_AGENT_PORT}:50000'
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xmx2g -Xms512m
      - DOCKER_HOST=unix:///var/run/docker.sock
    volumes:
      - '$JENKINS_HOME/data:/var/jenkins_home'
      - '/var/run/docker.sock:/var/run/docker.sock'
      - '$JENKINS_HOME/backups:/backups'
    networks:
      - jenkins-network

networks:
  jenkins-network:
    driver: bridge
EOF
    
    echo -e "${GREEN}✓ Docker compose file created${NC}"
}

# Build and start Jenkins
start_jenkins() {
    echo -e "\n${YELLOW}Building and starting Jenkins...${NC}"
    echo -e "${YELLOW}This may take a few minutes...${NC}"
    
    cd $JENKINS_HOME
    docker compose build
    docker compose up -d
    
    echo -e "${GREEN}✓ Jenkins container started${NC}"
}

# Wait for Jenkins to be ready
wait_for_jenkins() {
    echo -e "\n${YELLOW}Waiting for Jenkins to be ready...${NC}"
    
    COUNTER=0
    MAX_TRIES=30
    
    while [ $COUNTER -lt $MAX_TRIES ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:${JENKINS_PORT} | grep -q "200\|403"; then
            echo -e "${GREEN}✓ Jenkins is ready!${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 5
        COUNTER=$((COUNTER + 1))
    done
    
    echo -e "\n${YELLOW}⚠️  Jenkins is still starting up${NC}"
}

# Get initial admin password
get_admin_password() {
    echo -e "\n${YELLOW}Retrieving initial admin password...${NC}"
    
    sleep 5
    
    if [ -f "$JENKINS_HOME/data/secrets/initialAdminPassword" ]; then
        ADMIN_PASSWORD=$(cat $JENKINS_HOME/data/secrets/initialAdminPassword)
        echo -e "${GREEN}✓ Initial admin password retrieved${NC}"
    else
        echo -e "${YELLOW}⚠️  Password file not yet created. Check: docker logs jenkins${NC}"
        ADMIN_PASSWORD="Check docker logs"
    fi
}

# Create backup script
create_backup_script() {
    echo -e "\n${YELLOW}Creating backup script...${NC}"
    
    cat > $JENKINS_HOME/backup.sh <<'EOF'
#!/bin/bash

# Backup Jenkins
BACKUP_DIR="/srv/jenkins/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Starting Jenkins backup..."

# Stop Jenkins temporarily
docker exec jenkins java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ safe-restart

# Wait a bit
sleep 10

# Create backup
tar -czf $BACKUP_DIR/jenkins-backup-$TIMESTAMP.tar.gz -C /srv/jenkins/data .

echo "Backup completed: $BACKUP_DIR/jenkins-backup-$TIMESTAMP.tar.gz"

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t jenkins-backup-*.tar.gz | tail -n +8 | xargs -r rm

echo "Old backups cleaned up"
EOF
    
    chmod +x $JENKINS_HOME/backup.sh
    
    # Create cron job
    (crontab -l 2>/dev/null; echo "0 3 * * * $JENKINS_HOME/backup.sh >> $JENKINS_HOME/backup.log 2>&1") | crontab -
    
    echo -e "${GREEN}✓ Backup script created (scheduled daily at 3 AM)${NC}"
}

# Display info
display_info() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}Jenkins Installation Completed!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${BLUE}Access Information:${NC}"
    echo -e "  URL: ${YELLOW}http://localhost:${JENKINS_PORT}${NC}"
    echo -e "  Username: ${YELLOW}admin${NC}"
    echo -e "  Initial Password: ${YELLOW}${ADMIN_PASSWORD}${NC}"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  View logs:       ${YELLOW}docker logs -f jenkins${NC}"
    echo -e "  Restart:         ${YELLOW}docker restart jenkins${NC}"
    echo -e "  Backup:          ${YELLOW}$JENKINS_HOME/backup.sh${NC}"
    echo -e "  Jenkins CLI:     ${YELLOW}docker exec -it jenkins bash${NC}"
    
    echo -e "\n${BLUE}Configuration:${NC}"
    echo -e "  Data:            ${JENKINS_HOME}/data"
    echo -e "  Backups:         ${JENKINS_HOME}/backups"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Open ${YELLOW}http://localhost:${JENKINS_PORT}${NC}"
    echo -e "  2. Login with the initial password above"
    echo -e "  3. Install recommended plugins"
    echo -e "  4. Create your first admin user"
    echo -e "  5. Start creating pipelines!"
}

# Main execution
main() {
    check_root
    install_docker
    create_directories
    create_dockerfile
    create_compose_file
    start_jenkins
    wait_for_jenkins
    get_admin_password
    create_backup_script
    display_info
}

main
