#!/bin/bash
set -euo pipefail  # exit on any error, undefined variable, or pipe failure

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # no colour

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/my_install.log"
INPUT_FILE=""

# Logging functions
function log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [LOG]   $1"
    echo -e "${GREEN}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

function info() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]  $1"
    echo -e "${BLUE}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

function warn() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]  $1"
    echo -e "${YELLOW}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

function error() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1"
    echo -e "${RED}${message}${NC}"
    echo "${message}" >> "${LOG_FILE}"
}

function section() {
    local message="$1"
    echo
    echo -e "${PURPLE}=================================================="
    echo -e "  ${message}"
    echo -e "==================================================${NC}"
    echo "==================================================" >> "${LOG_FILE}"
    echo "  ${message}" >> "${LOG_FILE}"
    echo "==================================================" >> "${LOG_FILE}"
    echo
}

# Cleanup and error handling
function handle_cleanup() {
    # ...

    log "Script execution completed"
}

function handle_interrupt() {
    echo
    warn "Caught SIGINT (CTRL+C)! Initiating graceful shutdown..."

    # ...

    exit 1
}

function handle_error() {
    local last_command="$BASH_COMMAND"
    local last_line="$LINENO"
    error "ERROR occurred on line $last_line: '$last_command' exited with status $?"

    # ...

    exit 2
}

# Check command line arguments
function check_args() {
    if [[ $# -ne 1 ]]; then
        error "Usage: $0 <input-file>"
        exit 3
    fi
    
    INPUT_FILE="$1"
    
    if [[ ! -f "$INPUT_FILE" ]]; then
        error "File not found: $INPUT_FILE"
        exit 4
    fi
}

# Check if running as root
function check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 5
    fi
}

# Detect OS
function check_os() {
    local result=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        result="MacOS $(sw_vers -productVersion) (Build: $(sw_vers -buildVersion))"
    elif [[ -f /etc/os-release ]]; then
        # linux distributions with /etc/os-release
        source /etc/os-release
        result="$ID $VERSION_ID ($PRETTY_NAME)"
    elif [[ -f /etc/redhat-release ]]; then
        # fallback for older RHEL systems without /etc/os-release
        result=$(cat /etc/redhat-release)
    else
        error "Unable to detect operating system"
        exit 6
    fi

    info "OS: ${result}"
}

# Detect primary IPv4 address
function check_primary_ip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use route and ifconfig
        local primary_interface=$(route get default | grep interface | awk '{print $2}')
        ipv4_addr=$(ifconfig "$primary_interface" | grep 'inet ' | awk '{print $2}')
    else
        # Linux - use ip command
        local primary_interface=$(ip route | grep default | awk '{print $5}' | head -1)
        ipv4_addr=$(ip -4 addr show "$primary_interface" | grep inet | awk '{print $2}' | cut -d'/' -f1 | head -1)
    fi
    
    info "Default IPv4 address: ${ipv4_addr}"
}

# Detect hostname
function check_hostname() {
    info "Hostname: $(hostname)"
}

# Detect Python version
function check_python() {
    # check if Python is installed
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is not installed or not found in PATH"
        exit 7
    fi
    
    # get Python version
    local python_version=$(python3 --version 2>&1)
    
    # extract version numbers (e.g., "3.9.2" from "Python 3.9.2")
    local version_number=$(echo "$python_version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    local major=$(echo "$version_number" | cut -d. -f1)
    local minor=$(echo "$version_number" | cut -d. -f2)
    local patch=$(echo "$version_number" | cut -d. -f3)
    
    # verify if version meets minimum requirements (Python 3.6+)
    if [[ $major -eq 3 && $minor -ge 6 ]] || [[ $major -gt 3 ]]; then
        info "Python version: $version_number"
    else
        error "Python version $version_number is incompatible (3.6+ required)"
        exit 8
    fi
}

# Detect Java version
function check_java() {
    if [[ -n "${JAVA_HOME:-}" ]]; then  # :-} returns empty string instead of error
        info "JAVA_HOME: ${JAVA_HOME}"
    else
        warn "JAVA_HOME: not detected"
    fi

    if ! command -v java &> /dev/null; then
        info "'java' command not found"
        return 1
    fi
    
    local java_version=$(java -version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [[ -n "$java_version" ]]; then
        info "Java version: $java_version"
    else
        error "Cannot detect Java version"
        exit 10
    fi
}










# business logic
function f() {
    section "Hosts file configuration"
    
    info "Current /etc/hosts content:"
    cat /etc/hosts | tail -10
    echo

    read -p "Add custom host entries? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Enter custom host entries (format: IP hostname), press Ctrl+D when done:"
        while read -r line; do
            if [[ -n "$line" ]]; then
                echo "$line" >> /etc/hosts
                log "Added: $line"
            fi
        done
    fi

    info "New /etc/hosts content:"
    cat /etc/hosts | tail -10
    echo
}










# Get user choice
function get_user_choice() {
    while true; do
        read -p "Please select an option: " choice
        case $choice in
            [1-4]) break ;;
            *) ;;
        esac
    done
    echo "$choice"
}

# Main function
function main() {
    section "My Installation Script"
    
    # initialize log file
    echo "My Installation Log - $(date). Input file = ${INPUT_FILE}" > "${LOG_FILE}"
    log "Starting My installation process"
    
    while true; do
        section "My Installation Menu"
        echo "1. Install Server"
        echo "2. Install Agent"
        echo "3. Install Both"
        echo "4. Exit"
        echo
        
        local choice=$(get_user_choice)
        
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
                log "Selected: Install Both"
                install_both
                break
                ;;
            4)
                log "Selected: Exit"
                exit 0
                ;;
        esac
    done
    
    info "Installation completed successfully! See log file: ${LOG_FILE}"
}

# Script execution starts here
check_args "$@"
check_root
check_os
check_primary_ip
check_hostname
check_python
check_java

trap handle_cleanup   EXIT
trap handle_interrupt INT
trap handle_error     ERR     # "set -e" should be set

main "$@"
