#!/bin/bash

# Complete Ambari Ambari 3.0.0 Installation Script - Server and Agent Setup (CentOS Stream 9, Rocky Linux 9)
# by: Artem Mitrakov (mitrakov-artem@yandex.ru) + claude.ai + chatgpt

set -eo pipefail  # Exit on any error, or pipe failure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Global variables
INPUT_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/ambari_install.log"

# Logging functions
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

warn() {
    local message="[WARNING] $1"
    echo -e "${YELLOW}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

error() {
    local message="[ERROR] $1"
    echo -e "${RED}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
    exit 1
}

info() {
    local message="[INFO] $1"
    echo -e "${BLUE}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

section() {
    local message="$1"
    echo -e "${PURPLE}=================================="
    echo -e "  ${message}"
    echo -e "==================================${NC}"
    echo "==================================" >> "${LOG_FILE}"
    echo "  ${message}" >> "${LOG_FILE}"
    echo "==================================" >> "${LOG_FILE}"
}

# Check command line arguments
check_args() {
  if [[ $# -ne 1 ]]; then
    error "Usage: $0 <input-file>"
    echo "File should contain lines like: <IP> <hostname>"
    exit 1
  fi
  
  INPUT_FILE="$1"
  
  if [[ ! -f "$INPUT_FILE" ]]; then
    error "File not found: $INPUT_FILE"
    exit 2
  fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        log "Detected OS: $OS_NAME $OS_VERSION"
    else
        error "Cannot detect OS version"
    fi
}



# Show menu
show_menu() {
    echo
    section "Ambari Installation Menu"
    echo "1. Install Ambari-Server"
    echo "2. Install Ambari-Agent"
    echo "3. Install Repository"
    echo "4. Bugfix for agents: 'The package hadoop-hdfs-dfsrouter is not supported'"
    echo "5. Exit"
    echo
}

# Get user choice
get_user_choice() {
    while true; do
        read -p "Please select an option (1-5): " choice
        case $choice in
            [1-5]) break ;;
            *) echo "Invalid option. Please select 1-5." ;;
        esac
    done
    echo "$choice"
}



# Update SSH (optional for CentOS 9)
update_ssh() {
    section "Updating SSH Components"

    openssl version
    
    read -p "Update SSH components? (recommended for CentOS 9) (Y/n): " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log "Updating SSH components..."
        if command -v dnf &> /dev/null; then
            dnf install -y openssl openssh-server openssh-clients
            openssl version
            log "SSH components updated successfully"
        else
            warn "DNF not found, skipping SSH update"
        fi
    fi
}

# Setup hostname
setup_hostname() {
    section "Hostname Configuration"
    
    info "Current hostname: $(hostname)"
    read -p "Enter new hostname for this server (e.g., centos1.host) or press Enter to skip: " HOSTNAME
    
    if [[ -n "$HOSTNAME" ]]; then
        hostnamectl set-hostname "$HOSTNAME"
        log "Hostname set to: $(hostname)"
        export HOSTNAME_CHANGED=1
    else
        info "Hostname unchanged"
    fi
}

# Setup hosts file with predefined entries
setup_hosts() {
    section "Hosts File Configuration"
    
    info "Current /etc/hosts content:"
    cat /etc/hosts | tail -20
    echo
    
    # Processing input file
    while IFS= read -r line; do
      # Skip blank lines and comments
      [[ -z "$line" || "$line" =~ ^# ]] && continue

      IP=$(echo "$line" | awk '{print $1}')
      HOSTNAME=$(echo "$line" | awk '{print $2}')

      if grep -qE "\\b$IP\\b.*\\b$HOSTNAME\\b" /etc/hosts; then
        info "Entry for $IP $HOSTNAME already exists. Skipping."
      else
        echo "$IP $HOSTNAME" >> /etc/hosts
        info "Added: $IP $HOSTNAME"
      fi
    done < "$INPUT_FILE"

    info "Now /etc/hosts content:"
    cat /etc/hosts | tail -20
    echo
}

# Disable firewall
disable_firewall() {
    section "Firewall Configuration"
    
    read -p "Disable firewall? (recommended for quick-start) (Y/n): " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log "Disabling firewall..."
        if systemctl is-active --quiet firewalld; then
            systemctl stop firewalld && systemctl disable firewalld
            log "Firewall disabled successfully"
        else
            info "Firewall is already inactive"
        fi
    fi
}

# Install prerequisites
install_prerequisites() {
    section "Installing Prerequisites"
    
    log "Installing basic prerequisites..."
    if command -v dnf &> /dev/null; then
        dnf install -y zip unzip tar curl wget
    else
        yum install -y zip unzip tar curl wget
    fi
    log "Prerequisites installed successfully"
}

# Install Java using SDKMAN
install_java() {
    section "Java Installation"
    
    log "Installing Java using SDKMAN..."
    
    # Install SDKMAN
    if [[ ! -d "/root/.sdkman" ]]; then
        curl -s "https://get.sdkman.io" | bash
        log "SDKMAN installed"
    else
        info "SDKMAN already installed"
    fi
    
    # Source SDKMAN
    source "/root/.sdkman/bin/sdkman-init.sh"
    
    # Install Java versions
    log "Installing Java 17 and Java 8..."
    sdk install java 17.0.16-amzn || warn "Java 17 may already be installed"
    sdk install java 8.0.462-amzn || warn "Java 8 may already be installed"
    
    # Set Java 8 as default
    sdk default java 8.0.462-amzn
    
    log "Java installations completed"
}

# Copy Java installations
copy_java() {
    log "Copying Java installations to /usr/jdk64..."
    
    mkdir -p /usr/jdk64
    
    # Copy Java 17 (NOT symlinks!)
    if [[ -d "/root/.sdkman/candidates/java/17.0.16-amzn" ]]; then
        cp -r /root/.sdkman/candidates/java/17.0.16-amzn /usr/jdk64/jdk17
        log "Java 17 copied to /usr/jdk64/jdk17"
    else
        error "Java 17 installation not found"
    fi
    
    # Copy Java 8 (NOT symlinks!)
    if [[ -d "/root/.sdkman/candidates/java/8.0.462-amzn" ]]; then
        cp -r /root/.sdkman/candidates/java/8.0.462-amzn /usr/jdk64/jdk8
        log "Java 8 copied to /usr/jdk64/jdk8"
    else
        error "Java 8 installation not found"
    fi
}

# Verify Java installations
verify_java() {
    log "Verifying Java installations..."
    
    if [[ -x "/usr/jdk64/jdk8/bin/java" ]] && [[ -x "/usr/jdk64/jdk17/bin/java" ]]; then
        echo "Java 8 version:"
        /usr/jdk64/jdk8/bin/java -version
        echo
        echo "Java 17 version:"
        /usr/jdk64/jdk17/bin/java --version
        log "Java verification completed successfully"
    else
        error "Java installations not found or not executable"
    fi
}

# Common setup for all installations
common_setup() {
    section "Common Setup for All Hosts"
    
    update_ssh
    setup_hostname
    setup_hosts
    disable_firewall
    install_prerequisites
    install_java
    copy_java
    verify_java
    
    log "Common setup completed successfully"
}

# Setup Ambari repository
setup_ambari_repo() {
    section "Ambari Repository Setup"
    
    read -p "Enter the repository hostname (e.g., 192.168.1.99): " REPO_HOST
    if [[ -z "$REPO_HOST" ]]; then
        error "Repository hostname is required"
    fi
    
    log "Setting up Ambari repository..."
    
    cat > /etc/yum.repos.d/ambari.repo << EOF
[ambari]
name=Ambari Repository
baseurl=http://${REPO_HOST}/ambari-repo
gpgcheck=0
enabled=1
EOF
    
    log "Ambari repository configured for $REPO_HOST"
}

# Install Ambari Server
install_ambari_server() {
    section "Ambari Server Installation"
    
    log "Installing Ambari Server..."
    
    if command -v dnf &> /dev/null; then
        dnf install -y ambari-server
    else
        yum install -y ambari-server
    fi
    
    log "Ambari Server package installed"
}

# Setup Ambari Server
setup_ambari_server() {
    log "Setting up Ambari Server with Java configurations..."
    
    ambari-server setup \
        --java-home /usr/jdk64/jdk8 \
        --ambari-java-home /usr/jdk64/jdk17 \
        --stack-java-home /usr/jdk64/jdk8 \
        --silent
    
    log "Ambari Server setup completed"
}

# Setup MySQL connector (optional)
setup_mysql_connector() {
    read -p "Setup MySQL connector for Hive? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Downloading and setting up MySQL connector..."
        
        MYSQL_CONNECTOR_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/9.3.0/mysql-connector-j-9.3.0.jar"
        MYSQL_CONNECTOR_FILE="mysql-connector-j-9.3.0.jar"
        
        wget -O "$MYSQL_CONNECTOR_FILE" "$MYSQL_CONNECTOR_URL"
        
        if [[ -f "$MYSQL_CONNECTOR_FILE" ]]; then
            ambari-server setup --jdbc-db=mysql --jdbc-driver="$MYSQL_CONNECTOR_FILE"
            log "MySQL connector setup completed"
        else
            error "Failed to download MySQL connector"
        fi
    fi
}

# Start Ambari Server
start_ambari_server() {
    log "Starting Ambari Server..."
    
    ambari-server start

    info "Access Ambari Web UI at: http://$(hostname):8080"
    info "Default credentials: admin/admin"
}

# Apply agent-specific fixes
apply_agent_fixes() {
    section "Installing Ambari Agent missing packages"
    
    # Fix 1: Install python3-distro for ModuleNotFoundError
    log "Fix 1: Installing python3-distro..."
    if command -v dnf &> /dev/null; then
        dnf install -y python3-distro
    else
        yum install -y python3-distro
    fi
    log "python3-distro installed successfully"
    
    # Fix 2: Enable CRB repository for libtirpc-devel
    log "Fix 2: Enabling CRB repository..."
    if command -v dnf &> /dev/null; then
        dnf config-manager --set-enabled crb || warn "CRB repository may already be enabled or not available"
    fi
    log "CRB repository configuration completed"
    
    # Fix 3: Install LSB packages for Hadoop
    log "Fix 3: Installing LSB packages for Hadoop..."
    install_lsb_packages
    
    log "All extra agent packages have been installed successfully"
    echo
}

# Install LSB packages
install_lsb_packages() {
    log "Creating and running LSB installation script..."
    
    # Create the installation script
    cat > "${SCRIPT_DIR}/install-lsb.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

LSB_DIR="/tmp/lsb_packages"
mkdir -p "$LSB_DIR"
cd "$LSB_DIR"

echo "Downloading LSB packages..."
wget -q https://mirror.ghettoforge.net/distributions/gf/el/9/gf/x86_64/spax-1.6-7.gf.el9.x86_64.rpm
wget -q https://mirror.ghettoforge.net/distributions/gf/el/9/gf/x86_64/redhat-lsb-submod-security-4.1-59.1.gf.el9.x86_64.rpm
wget -q https://mirror.ghettoforge.net/distributions/gf/el/9/gf/x86_64/redhat-lsb-core-4.1-59.1.gf.el9.x86_64.rpm

echo "Installing LSB packages..."
dnf install -y spax-1.6-7.gf.el9.x86_64.rpm
dnf install -y redhat-lsb-submod-security-4.1-59.1.gf.el9.x86_64.rpm
dnf install -y redhat-lsb-core-4.1-59.1.gf.el9.x86_64.rpm

echo "Cleaning up..."
cd /
rm -rf "$LSB_DIR"

echo "LSB packages installed successfully"
EOF
    
    chmod +x "${SCRIPT_DIR}/install-lsb.sh"
    
    if "${SCRIPT_DIR}/install-lsb.sh"; then
        log "LSB packages installed successfully"
        rm -f "${SCRIPT_DIR}/install-lsb.sh"
    else
        error "Failed to install LSB packages"
    fi
}

# This addresses the "HDFS-Router: The package hadoop-hdfs-dfsrouter is not supported" error.
patch_distro_select_for_dfsrouter() {
    local DISTRO_SELECT_FILE="/usr/lib/bigtop-select/distro-select"
    local NEW_ENTRY='           "hadoop-hdfs-dfsrouter": "hadoop-hdfs",'
    local INSERT_AFTER_PATTERN='           "hadoop-hdfs-zkfc": "hadoop-hdfs",' # Insert after this line

    echo "Attempting to patch ${DISTRO_SELECT_FILE}..."

    # Check if the distro-select.py file exists
    if [ ! -f "${DISTRO_SELECT_FILE}" ]; then
        echo "Error: ${DISTRO_SELECT_FILE} not found. Cannot apply patch."
        return 1
    fi

    # Check if the entry already exists to prevent duplicate additions
    if grep -qF "${NEW_ENTRY}" "${DISTRO_SELECT_FILE}"; then
        echo "Entry '${NEW_ENTRY}' already exists in ${DISTRO_SELECT_FILE}. Skipping patch."
        return 0
    fi

    # Use sed to insert the new entry after the specified pattern
    # The 'a\' command in sed appends text after the matched line.
    sed -i "/${INSERT_AFTER_PATTERN}/a\\${NEW_ENTRY}" "${DISTRO_SELECT_FILE}"

    if [ $? -eq 0 ]; then
        echo "Successfully added '${NEW_ENTRY}' to ${DISTRO_SELECT_FILE}."
        echo "Verification (showing lines around the change):"
        # Show a few lines before and after the inserted entry for verification
        grep -B 2 -A 2 -F "${NEW_ENTRY}" "${DISTRO_SELECT_FILE}"
    else
        echo "Error: Failed to patch ${DISTRO_SELECT_FILE}. Manual intervention may be required."
        return 1
    fi
}

# Install server
install_server() {
    common_setup
    setup_ambari_repo
    install_ambari_server
    setup_ambari_server
    setup_mysql_connector
    start_ambari_server
    
    section "Server Installation Completed"
    info "Access Ambari Web UI at: http://$(hostname):8080"
    info "Default credentials: admin/admin"
}

# Install agent
install_agent() {
    common_setup
    apply_agent_fixes
    
    section "Agent Installation Completed"
    warn "If you see the error: 'The package hadoop-hdfs-dfsrouter is not supported by this version of the stack-select tool'"
    warn "Run this script again with option '4'"
    echo
    info "Make sure to configure passwordless SSH key on each agent"
}

# Install repository
install_repo() {
  section "Installing repository"

  setup_hosts

  read -p "Enter the repository hostname (from your '$INPUT_FILE' file): " REPO_HOST
  if [[ -z "$REPO_HOST" ]]; then
    error "Repository hostname is required"
  fi

  dnf install -y createrepo nginx
  mkdir -p /var/www/html/ambari-repo
  cd /var/www/html/ambari-repo

  wget -r -np -nH --cut-dirs=4 --reject 'index.html*' https://www.apache-ambari.com/dist/ambari/3.0.0/rocky9/
  wget -r -np -nH --cut-dirs=4 --reject 'index.html*' https://www.apache-ambari.com/dist/bigtop/3.3.0/rocky9/

  cd /var/www/html && createrepo .

  tee /etc/nginx/conf.d/ambari-repo.conf > /dev/null << EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    autoindex on;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

  systemctl start nginx && systemctl enable nginx
  firewall-cmd --permanent --add-port=80/tcp
  firewall-cmd --reload

  curl -s "$REPO_HOST" > /dev/null && info "Nginx serving Ambari repo."
}

# Show final summary
show_summary() {
    section "Installation Summary"
    
    info "Installation completed successfully!"
    info "Log file: ${LOG_FILE}"
    
    if [[ -n "${HOSTNAME_CHANGED:-}" ]]; then
        echo
        warn "Hostname was changed during installation"
        read -p "Re-login is recommended. Logout now? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Good bye..."
            logout
        fi
    fi
    
    echo
    info "For troubleshooting, check the log file: ${LOG_FILE}"
}

# Main function
main() {
    check_args "$@"
    check_root
    detect_os

    section "Ambari Installation Script (by Artem Mitrakov, 2025)"
    
    # Initialize log file
    echo "Ambari Installation Log - $(date)" > "${LOG_FILE}"
    info "Ambari v3.0.0, BigTop v3.3.0, Python v3.9"
    info "Please prepare at least 5 nodes and note their IP-to-Hostname pairs"
    info "1. Repository (if you already have a public repo, just take its URL)"
    info "2. Ambari server"
    info "3. Ambari agent master1"
    info "4. Ambari agent master2"
    info "5... Ambari agent data nodes"
    
    while true; do
        show_menu
        choice=$(get_user_choice)
        
        case $choice in
            1)
                log "Selected: Install Server"
                install_server
                break
                ;;
            2)
                log "Selected: Install Agent"
                install_agent
                break
                ;;
            3)
                log "Selected: Install Repository"
                install_repo
                break
                ;;
            4)
                log "Selected: Bugfix for agents (hadoop-hdfs-dfsrouter)"
                patch_distro_select_for_dfsrouter
                break
                ;;
            5)
                log "Exiting installation"
                exit 0
                ;;
        esac
    done
    
    show_summary
}

# Trap to ensure cleanup on script exit
trap 'log "Script execution finished"' EXIT

# Script execution starts here
main "$@"
