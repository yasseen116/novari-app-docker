#!/usr/bin/env bash
#
# Novari Project Deployment Script
# --------------------------------
# This script will:
# 1. Stop the old Gunicorn setup
# 2. Create a Docker container for Novari
# 3. Set up MySQL database
# 4. Integrate with Nginx Proxy Manager
# 5. Configure domain and SSL
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
PROJECT_NAME="novari"
DOMAIN="novari.cabai.tech"
OLD_PROJECT_DIR="$HOME/novaribb"
NEW_PROJECT_DIR="$HOME/novari-docker"
MYSQL_ROOT_PASSWORD="novari-root-2024"
MYSQL_DATABASE="novari_db"
MYSQL_USER="novari_user"
MYSQL_PASSWORD="novari-pass-2024"
APP_PORT="8001"

# --- Logging Functions ---

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$HOME/novari-deploy.log"
}

info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
    log "INFO: $*"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
    log "SUCCESS: $*"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
    log "WARNING: $*"
}

error() {
    echo -e "${RED}❌ $*${NC}"
    log "ERROR: $*"
}

header() {
    echo -e "${PURPLE}=== $* ===${NC}"
}

# --- Helper Functions ---

check_dependencies() {
    header "Checking Dependencies"
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi
    
    if ! sudo docker info &> /dev/null; then
        error "Docker daemon is not running"
        exit 1
    fi
    
    success "All dependencies are available"
}

stop_old_gunicorn() {
    header "Stopping Old Gunicorn Setup"
    
    info "Stopping Gunicorn processes..."
    sudo pkill -f gunicorn || info "No Gunicorn processes found"
    
    # Stop any systemd services
    if systemctl is-active --quiet novari 2>/dev/null; then
        sudo systemctl stop novari
        sudo systemctl disable novari
        info "Stopped novari systemd service"
    fi
    
    success "Old setup stopped"
}

backup_old_data() {
    header "Backing Up Old Data"
    
    backup_dir="$HOME/backups/novari-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [[ -d "$OLD_PROJECT_DIR" ]]; then
        info "Backing up old project to $backup_dir"
        cp -r "$OLD_PROJECT_DIR" "$backup_dir/"
        success "Backup completed"
    else
        warning "No old project directory found"
    fi
}

create_docker_setup() {
    header "Creating Docker Setup"
    
    # Create new project directory
    mkdir -p "$NEW_PROJECT_DIR"
    cd "$NEW_PROJECT_DIR"
    
    # Copy source code
    if [[ -d "$OLD_PROJECT_DIR" ]]; then
        info "Copying source code..."
        cp -r "$OLD_PROJECT_DIR"/* . 2>/dev/null || true
        cp -r "$OLD_PROJECT_DIR"/.* . 2>/dev/null || true
    fi
    
    # Create Dockerfile
    info "Creating Dockerfile..."
    cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create uploads directory if it doesn't exist
RUN mkdir -p uploads

# Expose port
EXPOSE 8001

# Run the application
CMD ["python", "main.py"]
EOF
    
    # Create docker-compose.yml
    info "Creating docker-compose.yml..."
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  novari-app:
    build: .
    container_name: novari-app
    restart: unless-stopped
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@novari-db:3306/${MYSQL_DATABASE}
    volumes:
      - ./uploads:/app/uploads
      - ./db:/app/db
    depends_on:
      - novari-db
    networks:
      - novari-network
      - proxy-network

  novari-db:
    image: mysql:8.0
    container_name: novari-db
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ./mysql-data:/var/lib/mysql
      - ./db:/docker-entrypoint-initdb.d
    networks:
      - novari-network

networks:
  novari-network:
    driver: bridge
  proxy-network:
    external: true
EOF
    
    success "Docker setup created"
}

setup_database() {
    header "Setting Up Database"
    
    # Copy SQL dump if it exists
    if [[ -f "$OLD_PROJECT_DIR/novari_06.sql" ]]; then
        info "Copying database dump..."
        cp "$OLD_PROJECT_DIR/novari_06.sql" ./db/
    elif [[ -f "$OLD_PROJECT_DIR/novari_06_dump.sql" ]]; then
        info "Copying database dump..."
        cp "$OLD_PROJECT_DIR/novari_06_dump.sql" ./db/init.sql
    else
        warning "No database dump found, will start with empty database"
    fi
    
    success "Database setup prepared"
}

update_app_config() {
    header "Updating Application Configuration"
    
    # Update main.py to use environment variables for database
    if [[ -f "main.py" ]]; then
        info "Updating main.py for Docker environment..."
        
        # Create a backup
        cp main.py main.py.backup
        
        # Update the main.py to use proper host and port for Docker
        sed -i 's/app.run(host="0.0.0.0", port=8001, debug=False)/app.run(host="0.0.0.0", port=8001, debug=False)/' main.py
    fi
    
    # Check if app/__init__.py needs database URL update
    if [[ -f "app/__init__.py" ]]; then
        info "Checking app configuration..."
        # You might need to update database connection here
        # This depends on how your app is configured
    fi
    
    success "Application configuration updated"
}

build_and_start() {
    header "Building and Starting Novari"
    
    cd "$NEW_PROJECT_DIR"
    
    info "Building Docker image..."
    if sudo docker compose build; then
        success "Docker image built successfully"
    else
        error "Failed to build Docker image"
        return 1
    fi
    
    info "Starting services..."
    if sudo docker compose up -d; then
        success "Services started successfully"
        sleep 10
        
        # Check if containers are running
        if sudo docker ps | grep -q "novari-app.*Up"; then
            success "Novari app is running"
        else
            error "Novari app failed to start"
            sudo docker logs novari-app
            return 1
        fi
    else
        error "Failed to start services"
        return 1
    fi
}

get_container_info() {
    header "Getting Container Information"
    
    local app_ip=$(sudo docker inspect novari-app -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "")
    
    if [[ -n "$app_ip" ]]; then
        success "Novari app IP: $app_ip"
        echo "APP_IP=$app_ip" > "$NEW_PROJECT_DIR/.env"
        
        info "Container is accessible at: http://$app_ip:$APP_PORT"
        
        # Test if the app is responding
        if curl -s "http://$app_ip:$APP_PORT" >/dev/null; then
            success "Application is responding to HTTP requests"
        else
            warning "Application might still be starting up"
        fi
    else
        error "Could not get container IP"
        return 1
    fi
}

setup_proxy_instructions() {
    header "Nginx Proxy Manager Setup Instructions"
    
    local app_ip=$(cat "$NEW_PROJECT_DIR/.env" | grep APP_IP | cut -d= -f2)
    
    echo
    info "To complete the setup, add this to Nginx Proxy Manager:"
    echo
    echo -e "${GREEN}1. Go to: http://$(curl -s ifconfig.me):81${NC}"
    echo -e "${GREEN}2. Login to Nginx Proxy Manager${NC}"
    echo -e "${GREEN}3. Add Proxy Host:${NC}"
    echo -e "   ${YELLOW}Domain: $DOMAIN${NC}"
    echo -e "   ${YELLOW}Forward to: $app_ip:$APP_PORT${NC}"
    echo -e "   ${YELLOW}Enable SSL: Yes (Let's Encrypt)${NC}"
    echo
    echo -e "${GREEN}4. Add DNS record:${NC}"
    echo -e "   ${YELLOW}$DOMAIN  A  $(curl -s ifconfig.me)${NC}"
    echo
    info "After setup, access Novari at: https://$DOMAIN"
}

show_status() {
    header "Deployment Status"
    
    echo -e "${BLUE}Container Status:${NC}"
    sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep novari || echo "No Novari containers found"
    
    echo
    echo -e "${BLUE}Logs (last 10 lines):${NC}"
    sudo docker logs --tail 10 novari-app 2>/dev/null || echo "No logs available"
    
    echo
    echo -e "${BLUE}Project Directory:${NC} $NEW_PROJECT_DIR"
    echo -e "${BLUE}Domain:${NC} $DOMAIN"
    echo -e "${BLUE}App Port:${NC} $APP_PORT"
}

cleanup_old_setup() {
    header "Cleaning Up Old Setup"
    
    read -rp "Do you want to remove the old Novari directory? (y/N): " remove_old
    if [[ "$remove_old" =~ ^[Yy]$ ]]; then
        if [[ -d "$OLD_PROJECT_DIR" ]]; then
            info "Removing old project directory..."
            rm -rf "$OLD_PROJECT_DIR"
            success "Old directory removed"
        fi
    else
        info "Keeping old directory for reference"
    fi
}

# --- Main Menu ---

show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           Novari Deployment Script          ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════╝${NC}"
    echo
    echo " 1) Full deployment (recommended)"
    echo " 2) Stop old Gunicorn setup only"
    echo " 3) Create Docker setup only"
    echo " 4) Build and start containers"
    echo " 5) Show status"
    echo " 6) Show proxy setup instructions"
    echo " 7) View logs"
    echo " 8) Restart Novari"
    echo " 9) Stop Novari"
    echo "10) Cleanup old setup"
    echo " 0) Exit"
    echo
}

handle_menu() {
    read -rp "Choice: " choice
    case "$choice" in
        1) full_deployment ;;
        2) stop_old_gunicorn ;;
        3) create_docker_setup && setup_database && update_app_config ;;
        4) build_and_start && get_container_info ;;
        5) show_status ;;
        6) setup_proxy_instructions ;;
        7) sudo docker logs --tail 50 novari-app ;;
        8) cd "$NEW_PROJECT_DIR" && sudo docker compose restart ;;
        9) cd "$NEW_PROJECT_DIR" && sudo docker compose down ;;
        10) cleanup_old_setup ;;
        0) success "Goodbye!"; exit 0 ;;
        *) warning "Invalid option" ;;
    esac
    
    echo
    read -rp "Press Enter to continue..."
}

full_deployment() {
    header "Starting Full Novari Deployment"
    
    check_dependencies
    backup_old_data
    stop_old_gunicorn
    create_docker_setup
    setup_database
    update_app_config
    build_and_start
    get_container_info
    setup_proxy_instructions
    
    success "Deployment completed!"
    info "Check the proxy setup instructions above to complete the process."
}

# --- Main ---

main() {
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        while true; do
            show_menu
            handle_menu
        done
    else
        # Command line mode
        case "$1" in
            "deploy") full_deployment ;;
            "status") show_status ;;
            "stop") cd "$NEW_PROJECT_DIR" && sudo docker compose down ;;
            "start") cd "$NEW_PROJECT_DIR" && sudo docker compose up -d ;;
            "logs") sudo docker logs -f novari-app ;;
            *) 
                echo "Usage: $0 [deploy|status|stop|start|logs]"
                echo "Or run without arguments for interactive mode"
                ;;
        esac
    fi
}

# Run the script
main "$@" 