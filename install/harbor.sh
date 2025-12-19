#!/bin/bash

###############################################################################
# Harbor Registry Installation Script for Debian 12
# Cài đặt Harbor - Enterprise-class container registry
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
HARBOR_HOME="/srv/harbor"
HARBOR_VERSION="v2.10.0"
HARBOR_HOSTNAME="${HARBOR_HOSTNAME:-harbor.local}"
HARBOR_ADMIN_PASSWORD="${HARBOR_ADMIN_PASSWORD:-Harbor12345}"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Harbor Registry Installation${NC}"
echo -e "${GREEN}=====================================${NC}"

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root or with sudo${NC}"
        exit 1
    fi
}

# Install Docker and Docker Compose
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

# Download Harbor
download_harbor() {
    echo -e "\n${YELLOW}Downloading Harbor ${HARBOR_VERSION}...${NC}"
    
    mkdir -p $HARBOR_HOME
    cd $HARBOR_HOME
    
    DOWNLOAD_URL="https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-online-installer-${HARBOR_VERSION}.tgz"
    
    curl -L $DOWNLOAD_URL -o harbor-installer.tgz
    tar xzvf harbor-installer.tgz
    rm harbor-installer.tgz
    
    echo -e "${GREEN}✓ Harbor downloaded${NC}"
}

# Configure Harbor
configure_harbor() {
    echo -e "\n${YELLOW}Configuring Harbor...${NC}"
    
    cd $HARBOR_HOME/harbor
    
    cp harbor.yml.tmpl harbor.yml
    
    # Update configuration
    sed -i "s/hostname: .*/hostname: ${HARBOR_HOSTNAME}/" harbor.yml
    sed -i "s/harbor_admin_password: .*/harbor_admin_password: ${HARBOR_ADMIN_PASSWORD}/" harbor.yml
    
    # Disable HTTPS for initial setup (can be enabled later with SSL)
    sed -i '/^https:/,/^$/s/^/#/' harbor.yml
    
    echo -e "${GREEN}✓ Harbor configured${NC}"
}

# Install Harbor
install_harbor() {
    echo -e "\n${YELLOW}Installing Harbor...${NC}"
    echo -e "${YELLOW}This may take 5-10 minutes...${NC}"
    
    cd $HARBOR_HOME/harbor
    
    # Install with Trivy scanner and Chartmuseum
    ./install.sh --with-trivy --with-chartmuseum
    
    echo -e "${GREEN}✓ Harbor installed${NC}"
}

# Create management scripts
create_management_scripts() {
    echo -e "\n${YELLOW}Creating management scripts...${NC}"
    
    # Start script
    cat > $HARBOR_HOME/start.sh <<EOF
#!/bin/bash
cd $HARBOR_HOME/harbor
docker compose up -d
echo "Harbor started"
EOF
    
    # Stop script
    cat > $HARBOR_HOME/stop.sh <<EOF
#!/bin/bash
cd $HARBOR_HOME/harbor
docker compose down
echo "Harbor stopped"
EOF
    
    # Backup script
    cat > $HARBOR_HOME/backup.sh <<'EOF'
#!/bin/bash

BACKUP_DIR="/srv/harbor/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Starting Harbor backup..."

# Stop Harbor
cd /srv/harbor/harbor
docker compose down

# Backup data
tar -czf $BACKUP_DIR/harbor-backup-$TIMESTAMP.tar.gz -C /srv/harbor/harbor .

# Restart Harbor
docker compose up -d

echo "Backup completed: $BACKUP_DIR/harbor-backup-$TIMESTAMP.tar.gz"

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t harbor-backup-*.tar.gz | tail -n +8 | xargs -r rm
EOF
    
    chmod +x $HARBOR_HOME/*.sh
    
    # Create backup cron job
    (crontab -l 2>/dev/null; echo "0 1 * * 0 $HARBOR_HOME/backup.sh >> $HARBOR_HOME/backup.log 2>&1") | crontab -
    
    echo -e "${GREEN}✓ Management scripts created${NC}"
}

# Configure Docker to use Harbor
configure_docker_client() {
    echo -e "\n${YELLOW}Configuring Docker client...${NC}"
    
    # Add insecure registry (for HTTP)
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["${HARBOR_HOSTNAME}"]
}
EOF
    
    systemctl restart docker
    
    echo -e "${GREEN}✓ Docker client configured${NC}"
}

# Display info
display_info() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}Harbor Installation Completed!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${BLUE}Access Information:${NC}"
    echo -e "  URL: ${YELLOW}http://${HARBOR_HOSTNAME}${NC}"
    echo -e "  Username: ${YELLOW}admin${NC}"
    echo -e "  Password: ${YELLOW}${HARBOR_ADMIN_PASSWORD}${NC}"
    
    echo -e "\n${BLUE}Management Scripts:${NC}"
    echo -e "  Start Harbor:    ${YELLOW}$HARBOR_HOME/start.sh${NC}"
    echo -e "  Stop Harbor:     ${YELLOW}$HARBOR_HOME/stop.sh${NC}"
    echo -e "  Backup Harbor:   ${YELLOW}$HARBOR_HOME/backup.sh${NC}"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  View logs:       ${YELLOW}cd $HARBOR_HOME/harbor && docker compose logs -f${NC}"
    echo -e "  Check status:    ${YELLOW}cd $HARBOR_HOME/harbor && docker compose ps${NC}"
    
    echo -e "\n${BLUE}Docker Login:${NC}"
    echo -e "  ${YELLOW}docker login ${HARBOR_HOSTNAME}${NC}"
    echo -e "  Username: admin"
    echo -e "  Password: ${HARBOR_ADMIN_PASSWORD}"
    
    echo -e "\n${BLUE}Push Image Example:${NC}"
    echo -e "  ${YELLOW}docker tag myimage:latest ${HARBOR_HOSTNAME}/library/myimage:latest${NC}"
    echo -e "  ${YELLOW}docker push ${HARBOR_HOSTNAME}/library/myimage:latest${NC}"
    
    echo -e "\n${YELLOW}Note: If you want to use HTTPS:${NC}"
    echo -e "  1. Get SSL certificates (Let's Encrypt)"
    echo -e "  2. Edit $HARBOR_HOME/harbor/harbor.yml"
    echo -e "  3. Enable HTTPS section with your certificates"
    echo -e "  4. Run: cd $HARBOR_HOME/harbor && ./prepare"
    echo -e "  5. Restart Harbor"
}

# Main execution
main() {
    check_root
    install_docker
    download_harbor
    configure_harbor
    install_harbor
    create_management_scripts
    configure_docker_client
    display_info
}

main
