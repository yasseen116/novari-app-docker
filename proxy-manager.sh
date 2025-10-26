#!/usr/bin/env bash
#
# Centralized Proxy Manager
# -------------------------
# Manage all your web services through Nginx Proxy Manager
# 
# Features:
# - Add/remove proxy hosts
# - Manage SSL certificates
# - Monitor services
# - Quick service deployment
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Directories
PROXY_DIR="$HOME/nginx-proxy-manager"
WEBMAIL_DIR="$HOME/webmail"
MAILSERVER_DIR="$HOME/docker-mailserver"
LOG_FILE="$HOME/proxy-manager.log"

# --- Logging Functions ---

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
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

check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi
    
    if ! sudo docker info &> /dev/null; then
        error "Docker daemon is not running or permission denied"
        exit 1
    fi
}

get_container_ip() {
    local container_name="$1"
    sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null || echo ""
}

check_service_status() {
    local service_name="$1"
    local container_name="$2"
    
    if sudo docker ps | grep -q "$container_name.*Up"; then
        success "$service_name is running"
        return 0
    else
        error "$service_name is not running"
        return 1
    fi
}

# --- Service Management ---

start_proxy_manager() {
    header "Starting Nginx Proxy Manager"
    
    cd "$PROXY_DIR"
    if sudo docker compose up -d; then
        success "Nginx Proxy Manager started"
        sleep 5
        info "Admin interface: http://$(curl -s ifconfig.me):81"
        info "Default login: admin@example.com / changeme"
    else
        error "Failed to start Nginx Proxy Manager"
    fi
}

start_webmail() {
    header "Starting Webmail (Roundcube)"
    
    cd "$WEBMAIL_DIR"
    if sudo docker compose up -d; then
        success "Webmail started"
        local webmail_ip=$(get_container_ip "roundcube-webmail")
        info "Webmail internal IP: $webmail_ip"
        info "Add this to Nginx Proxy Manager: webmail.cabai.tech -> $webmail_ip:80"
    else
        error "Failed to start webmail"
    fi
}

stop_all_services() {
    header "Stopping All Services"
    
    info "Stopping webmail..."
    cd "$WEBMAIL_DIR" && sudo docker compose down
    
    info "Stopping proxy manager..."
    cd "$PROXY_DIR" && sudo docker compose down
    
    success "All services stopped"
}

restart_all_services() {
    header "Restarting All Services"
    stop_all_services
    sleep 3
    start_proxy_manager
    sleep 5
    start_webmail
}

# --- Status and Monitoring ---

show_status() {
    header "Service Status"
    
    echo -e "${BLUE}Nginx Proxy Manager:${NC}"
    check_service_status "Nginx Proxy Manager" "nginx-proxy-manager"
    
    echo -e "${BLUE}Webmail (Roundcube):${NC}"
    check_service_status "Webmail" "roundcube-webmail"
    
    echo -e "${BLUE}Mail Server:${NC}"
    check_service_status "Mail Server" "mailserver"
    
    echo
    header "Container IPs"
    info "Webmail IP: $(get_container_ip 'roundcube-webmail')"
    info "Mail Server IP: $(get_container_ip 'mailserver')"
    
    echo
    header "Port Status"
    for port in 80 443 81; do
        if ss -tlnp | grep -q ":$port "; then
            success "Port $port is in use"
        else
            warning "Port $port is not in use"
        fi
    done
}

show_logs() {
    header "View Logs"
    echo "1) Nginx Proxy Manager logs"
    echo "2) Webmail logs"
    echo "3) Proxy Manager script logs"
    echo "4) Follow Nginx Proxy Manager logs"
    read -rp "Choice: " choice
    
    case "$choice" in
        1) sudo docker logs --tail 50 nginx-proxy-manager ;;
        2) sudo docker logs --tail 50 roundcube-webmail ;;
        3) tail -30 "$LOG_FILE" 2>/dev/null || info "No logs found" ;;
        4) info "Following logs... Press Ctrl+C to stop"
           sudo docker logs -f nginx-proxy-manager ;;
        *) warning "Invalid choice" ;;
    esac
}

# --- Quick Setup Functions ---

setup_webmail_proxy() {
    header "Webmail Proxy Setup Instructions"
    
    local webmail_ip=$(get_container_ip "roundcube-webmail")
    
    if [[ -z "$webmail_ip" ]]; then
        error "Webmail container not running. Start it first."
        return 1
    fi
    
    info "To set up webmail proxy in Nginx Proxy Manager:"
    echo
    echo -e "${GREEN}1. Go to: http://$(curl -s ifconfig.me):81${NC}"
    echo -e "${GREEN}2. Login with: admin@example.com / changeme${NC}"
    echo -e "${GREEN}3. Add Proxy Host:${NC}"
    echo -e "   ${YELLOW}Domain: webmail.cabai.tech${NC}"
    echo -e "   ${YELLOW}Forward to: $webmail_ip:80${NC}"
    echo -e "   ${YELLOW}Enable SSL: Yes (Let's Encrypt)${NC}"
    echo
    info "After setup, access webmail at: https://webmail.cabai.tech"
}

deploy_new_service() {
    header "Deploy New Service"
    
    read -rp "Service name: " service_name
    read -rp "Domain (e.g., app.cabai.tech): " domain
    read -rp "Internal port: " port
    read -rp "Docker image: " image
    
    service_dir="$HOME/$service_name"
    mkdir -p "$service_dir"
    
    cat > "$service_dir/docker-compose.yml" << EOF
services:
  $service_name:
    image: $image
    container_name: $service_name
    restart: unless-stopped
    networks:
      - proxy-network

networks:
  proxy-network:
    external: true
EOF
    
    info "Service configuration created in $service_dir"
    
    read -rp "Start the service now? (y/N): " start_now
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        cd "$service_dir"
        if sudo docker compose up -d; then
            success "Service $service_name started"
            local service_ip=$(get_container_ip "$service_name")
            info "Add to Nginx Proxy Manager: $domain -> $service_ip:$port"
        else
            error "Failed to start service"
        fi
    fi
}

# --- Backup and Maintenance ---

backup_configs() {
    header "Backup Configurations"
    
    backup_dir="$HOME/backups/proxy-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    info "Creating backup in $backup_dir"
    
    # Backup Nginx Proxy Manager data
    if [[ -d "$PROXY_DIR/data" ]]; then
        cp -r "$PROXY_DIR/data" "$backup_dir/npm-data"
        success "Nginx Proxy Manager data backed up"
    fi
    
    # Backup webmail data
    if [[ -d "$WEBMAIL_DIR" ]]; then
        cp -r "$WEBMAIL_DIR" "$backup_dir/webmail"
        success "Webmail configuration backed up"
    fi
    
    # Backup mail server
    if [[ -d "$MAILSERVER_DIR" ]]; then
        cp -r "$MAILSERVER_DIR" "$backup_dir/mailserver"
        success "Mail server configuration backed up"
    fi
    
    success "Backup completed: $backup_dir"
}

# --- Main Menu ---

show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         Centralized Proxy Manager           ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════╝${NC}"
    echo
    
    # Quick status
    if sudo docker ps | grep -q "nginx-proxy-manager.*Up"; then
        echo -e "${GREEN}Proxy Manager: ✅ Running${NC}"
    else
        echo -e "${RED}Proxy Manager: ❌ Stopped${NC}"
    fi
    
    if sudo docker ps | grep -q "roundcube-webmail.*Up"; then
        echo -e "${GREEN}Webmail: ✅ Running${NC}"
    else
        echo -e "${RED}Webmail: ❌ Stopped${NC}"
    fi
    
    echo
    echo " 1) Start Nginx Proxy Manager    8) Show service status"
    echo " 2) Start Webmail                9) View logs"
    echo " 3) Restart all services        10) Setup webmail proxy"
    echo " 4) Stop all services           11) Deploy new service"
    echo " 5) Show status                 12) Backup configurations"
    echo " 6) Open Proxy Manager          13) Show container IPs"
    echo " 7) Open Webmail                14) Quick troubleshoot"
    echo " 0) Exit"
    echo
    echo -e "${YELLOW}Proxy Manager: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_IP'):81${NC}"
    echo
}

handle_menu() {
    read -rp "Choice: " choice
    case "$choice" in
        1) start_proxy_manager ;;
        2) start_webmail ;;
        3) restart_all_services ;;
        4) stop_all_services ;;
        5) show_status ;;
        6) info "Opening: http://$(curl -s ifconfig.me):81" ;;
        7) info "Webmail should be at: https://webmail.cabai.tech (after proxy setup)" ;;
        8) show_status ;;
        9) show_logs ;;
        10) setup_webmail_proxy ;;
        11) deploy_new_service ;;
        12) backup_configs ;;
        13) 
            info "Container IPs:"
            echo "Webmail: $(get_container_ip 'roundcube-webmail')"
            echo "Mail Server: $(get_container_ip 'mailserver')"
            echo "Proxy Manager: $(get_container_ip 'nginx-proxy-manager')"
            ;;
        14)
            info "Quick troubleshoot:"
            sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            ;;
        0) success "Goodbye!"; exit 0 ;;
        *) warning "Invalid option" ;;
    esac
    
    echo
    read -rp "Press Enter to continue..."
}

# --- Main ---

main() {
    touch "$LOG_FILE"
    check_docker
    
    while true; do
        show_menu
        handle_menu
    done
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 