#!/bin/bash

###############################################################################
# Master Installation Script - Essential DevOps Tools
# Cài đặt stack thiết yếu: GitLab, Jenkins, SonarQube
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  Essential DevOps Stack Setup         ║${NC}"
echo -e "${MAGENTA}║  GitLab + Jenkins + SonarQube          ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Display menu
show_menu() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}What do you want to install?${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${YELLOW}1)${NC} GitLab CE (Source Control & CI/CD) - 4GB RAM"
    echo -e "  ${YELLOW}2)${NC} Jenkins (Automation Server) - 2GB RAM"
    echo -e "  ${YELLOW}3)${NC} SonarQube (Code Quality) - 2GB RAM"
    echo ""
    echo -e "  ${GREEN}4)${NC} Install ALL (Essential Stack) - 8GB RAM"
    echo ""
    echo -e "  ${RED}0)${NC} Exit"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -n "Enter your choice: "
}

# System requirements check
check_system_requirements() {
    echo -e "\n${YELLOW}Checking system requirements...${NC}"
    
    # Check OS
    if [ -f /etc/debian_version ]; then
        DEBIAN_VERSION=$(cat /etc/debian_version | cut -d'.' -f1)
        if [ "$DEBIAN_VERSION" -ge 12 ]; then
            echo -e "${GREEN}✓ Debian 12 detected${NC}"
        else
            echo -e "${RED}⚠️  Warning: This script is designed for Debian 12${NC}"
        fi
    else
        echo -e "${RED}⚠️  Warning: This script is designed for Debian 12${NC}"
    fi
    
    # Check RAM
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    echo -e "${BLUE}RAM: ${TOTAL_RAM}GB${NC}"
    if [ $TOTAL_RAM -lt 8 ]; then
        echo -e "${RED}⚠️  Warning: At least 8GB RAM recommended for full stack${NC}"
    fi
    
    # Check disk space
    FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    echo -e "${BLUE}Free disk space: ${FREE_SPACE}GB${NC}"
    if [ $FREE_SPACE -lt 50 ]; then
        echo -e "${RED}⚠️  Warning: At least 50GB free space recommended${NC}"
    fi
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    echo -e "${BLUE}CPU cores: ${CPU_CORES}${NC}"
    if [ $CPU_CORES -lt 4 ]; then
        echo -e "${RED}⚠️  Warning: At least 4 CPU cores recommended${NC}"
    fi
}

# Install GitLab
install_gitlab() {
    echo -e "\n${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${MAGENTA}Installing GitLab CE...${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    
    if [ -f "$SCRIPT_DIR/gitlab.sh" ]; then
        bash "$SCRIPT_DIR/gitlab.sh"
    else
        echo -e "${RED}Error: gitlab.sh not found${NC}"
        return 1
    fi
}

# Install Jenkins
install_jenkins() {
    echo -e "\n${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${MAGENTA}Installing Jenkins...${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    
    if [ -f "$SCRIPT_DIR/jenkins.sh" ]; then
        bash "$SCRIPT_DIR/jenkins.sh"
    else
        echo -e "${RED}Error: jenkins.sh not found${NC}"
        return 1
    fi
}

# Install SonarQube
install_sonarqube() {
    echo -e "\n${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${MAGENTA}Installing SonarQube...${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    
    if [ -f "$SCRIPT_DIR/sonarqube.sh" ]; then
        bash "$SCRIPT_DIR/sonarqube.sh"
    else
        echo -e "${RED}Error: sonarqube.sh not found${NC}"
        return 1
    fi
}

# Install all
install_all() {
    echo -e "\n${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  Installing Essential DevOps Stack    ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}This will install:${NC}"
    echo -e "  • GitLab CE (4GB RAM)"
    echo -e "  • Jenkins (2GB RAM)"
    echo -e "  • SonarQube (2GB RAM)"
    echo -e "\n${BLUE}Total RAM needed: ~8GB${NC}"
    echo ""
    echo -e "${RED}This may take 20-30 minutes depending on your system${NC}"
    echo ""
    read -p "Continue? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        return 0
    fi
    
    START_TIME=$(date +%s)
    
    install_gitlab || echo -e "${YELLOW}GitLab installation had issues${NC}"
    echo -e "\n${BLUE}Waiting 30s for GitLab to stabilize...${NC}"
    sleep 30
    
    install_jenkins || echo -e "${YELLOW}Jenkins installation had issues${NC}"
    echo -e "\n${BLUE}Waiting 30s for Jenkins to stabilize...${NC}"
    sleep 30
    
    install_sonarqube || echo -e "${YELLOW}SonarQube installation had issues${NC}"
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Installation Complete!                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo -e "\n${BLUE}Total time: ${DURATION} seconds${NC}"
    
    display_final_summary
}

# Display final summary
display_final_summary() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Essential DevOps Stack Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}Access URLs:${NC}"
    echo -e "  GitLab:       http://localhost (SSH: port 2222)"
    echo -e "  Jenkins:      http://localhost:8080"
    echo -e "  SonarQube:    http://localhost:9000"
    
    echo -e "\n${YELLOW}Default Credentials:${NC}"
    echo -e "  GitLab:     root / (set on first login)"
    echo -e "  Jenkins:    admin / (check: docker logs jenkins)"
    echo -e "  SonarQube:  admin / admin"
    
    echo -e "\n${YELLOW}Status Check:${NC}"
    echo -e "  ${BLUE}docker ps${NC} - View running containers"
    echo -e "  ${BLUE}docker stats${NC} - Check resource usage"
    
    echo -e "\n${YELLOW}Data Locations:${NC}"
    echo -e "  /srv/gitlab"
    echo -e "  /srv/jenkins"
    echo -e "  /srv/sonarqube"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Wait 2-3 minutes for all services to start"
    echo -e "  2. Access GitLab and set root password"
    echo -e "  3. Get Jenkins initial admin password"
    echo -e "  4. Login to SonarQube and change password"
    
    echo -e "\n${YELLOW}Documentation:${NC}"
    echo -e "  Check README.md and QUICKSTART.md"
    
    echo -e "\n${GREEN}Happy DevOps! 🚀${NC}"
}

# Main loop
main() {
    check_system_requirements
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                install_gitlab
                read -p "Press Enter to continue..."
                ;;
            2)
                install_jenkins
                read -p "Press Enter to continue..."
                ;;
            3)
                install_sonarqube
                read -p "Press Enter to continue..."
                ;;
            4)
                install_all
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "\n${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

main
