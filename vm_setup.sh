#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"
}

print_warning() {
    printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"
}

print_error() {
    printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1" >&2
}

trap 'print_error "Setup failed. Review the messages above for details."; exit 1' ERR
trap 'print_warning "Setup interrupted by user."; exit 130' INT

usage() {
    cat <<'EOF'
Usage: ./vm_setup.sh [options]

Options:
  --login USERNAME         System user that owns the project (defaults to current user)
  --domain DOMAIN          Fully qualified domain (defaults to <login>.42.fr)
  --repo URL               Git repository to clone (defaults to project remote)
  --project-dir NAME       Directory name for the project clone (defaults to inception)
  --data-root PATH         Host directory for Docker volumes (defaults to /home/<login>/data)
  --auto-up                Run 'make up' automatically when Docker access is available
  -h, --help               Show this help message and exit

Environment overrides:
  INCEPTION_LOGIN, INCEPTION_DOMAIN, INCEPTION_REPO_URL,
  INCEPTION_PROJECT_NAME, INCEPTION_DATA_ROOT

Secrets can be provided via:
  INCEPTION_DB_ROOT_PASSWORD, INCEPTION_DB_PASSWORD,
  INCEPTION_WP_ADMIN_PASSWORD, INCEPTION_WP_USER_PASSWORD
EOF
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_not_root() {
    if [[ $(id -u) -eq 0 ]]; then
        print_error "Run this script as a non-root user with sudo privileges."
        exit 1
    fi
}

require_sudo() {
    if ! command_exists sudo; then
        print_error "sudo is required to run this script."
        exit 1
    fi

    print_status "Verifying sudo access..."
    if ! sudo -n true >/dev/null 2>&1; then
        sudo -v
    fi
    sudo -v
}

DEFAULT_REPO_URL="https://github.com/Hicham1S/inception.git"
DEFAULT_PROJECT_NAME="inception"
DEFAULT_LOGIN="${INCEPTION_LOGIN:-${SUDO_USER:-$(id -un)}}"

LOGIN="$DEFAULT_LOGIN"
DOMAIN="${INCEPTION_DOMAIN:-}"
PROJECT_NAME="${INCEPTION_PROJECT_NAME:-$DEFAULT_PROJECT_NAME}"
REPO_URL="${INCEPTION_REPO_URL:-$DEFAULT_REPO_URL}"
DATA_ROOT="${INCEPTION_DATA_ROOT:-}"
AUTO_UP=false
ADDED_TO_DOCKER_GROUP=false
ADDED_HOSTS_ENTRY=false

LOGIN_HOME=""
PROJECT_PATH=""
ENV_FILE=""
DOCKER_COMPOSE_FILE=""
SECRETS_DIR=""

declare -A GENERATED_SECRETS=()

APT_PACKAGES=(ca-certificates curl git gnupg lsb-release make openssl)
DOCKER_PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
SECRET_SPECS=(
    "db_root_password.txt:INCEPTION_DB_ROOT_PASSWORD:32"
    "db_password.txt:INCEPTION_DB_PASSWORD:28"
    "wp_admin_password.txt:INCEPTION_WP_ADMIN_PASSWORD:24"
    "wp_user_password.txt:INCEPTION_WP_USER_PASSWORD:24"
)

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --login)
                if [[ $# -lt 2 ]]; then
                    print_error "Missing value for --login"
                    usage
                    exit 1
                fi
                LOGIN="$2"
                shift 2
                ;;
            --domain)
                if [[ $# -lt 2 ]]; then
                    print_error "Missing value for --domain"
                    usage
                    exit 1
                fi
                DOMAIN="$2"
                shift 2
                ;;
            --repo)
                if [[ $# -lt 2 ]]; then
                    print_error "Missing value for --repo"
                    usage
                    exit 1
                fi
                REPO_URL="$2"
                shift 2
                ;;
            --project-dir)
                if [[ $# -lt 2 ]]; then
                    print_error "Missing value for --project-dir"
                    usage
                    exit 1
                fi
                PROJECT_NAME="$2"
                shift 2
                ;;
            --data-root)
                if [[ $# -lt 2 ]]; then
                    print_error "Missing value for --data-root"
                    usage
                    exit 1
                fi
                DATA_ROOT="$2"
                shift 2
                ;;
            --auto-up)
                AUTO_UP=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

finalize_paths() {
    LOGIN_HOME="$(eval echo "~${LOGIN}")"
    if [[ -z "$LOGIN_HOME" || ! -d "$LOGIN_HOME" ]]; then
        print_error "Cannot determine home directory for user '${LOGIN}'."
        exit 1
    fi

    if [[ -z "$DOMAIN" ]]; then
        DOMAIN="${LOGIN}.42.fr"
    fi

    if [[ -z "$DATA_ROOT" ]]; then
        DATA_ROOT="${LOGIN_HOME}/data"
    fi

    PROJECT_PATH="${LOGIN_HOME}/${PROJECT_NAME}"
    ENV_FILE="${PROJECT_PATH}/srcs/.env"
    DOCKER_COMPOSE_FILE="${PROJECT_PATH}/srcs/docker-compose.yml"
    SECRETS_DIR="${PROJECT_PATH}/secrets"

    if [[ -z "$REPO_URL" ]]; then
        print_error "A repository URL must be provided via --repo or INCEPTION_REPO_URL."
        exit 1
    fi
}

install_base_packages() {
    print_status "Updating apt cache and installing base packages..."
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}"
}

install_docker() {
    if command_exists docker; then
        print_status "Docker already installed."
    else
        print_status "Installing Docker Engine and dependencies..."
        sudo install -m 0755 -d /etc/apt/keyrings
        if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        fi
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        if [[ ! -f /etc/apt/sources.list.d/docker.list ]] || ! grep -q "download.docker.com/linux/debian" /etc/apt/sources.list.d/docker.list; then
            . /etc/os-release
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        fi

        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${DOCKER_PACKAGES[@]}"
    fi

    print_status "Ensuring Docker service is enabled and running..."
    if command_exists systemctl; then
        sudo systemctl enable --now docker
    else
        sudo service docker start
    fi
}

ensure_docker_group_membership() {
    if ! getent group docker >/dev/null 2>&1; then
        sudo groupadd docker
    fi

    if id -nG "$LOGIN" | tr ' ' '\n' | grep -qx docker; then
        print_status "User ${LOGIN} already in docker group."
    else
        print_status "Adding ${LOGIN} to docker group..."
        sudo usermod -aG docker "$LOGIN"
        ADDED_TO_DOCKER_GROUP=true
    fi
}

create_data_directories() {
    print_status "Preparing data directories under ${DATA_ROOT}..."
    mkdir -p "${DATA_ROOT}/mariadb" "${DATA_ROOT}/wordpress"
    sudo chown -R "${LOGIN}:${LOGIN}" "$DATA_ROOT"
    chmod 755 "$DATA_ROOT"
}

ensure_hosts_entry() {
    if grep -qE "^[^#]*\s${DOMAIN}(\s|$)" /etc/hosts; then
        print_status "Domain ${DOMAIN} already mapped in /etc/hosts."
    else
        print_status "Adding ${DOMAIN} to /etc/hosts..."
        echo "127.0.0.1 ${DOMAIN}" | sudo tee -a /etc/hosts >/dev/null
        ADDED_HOSTS_ENTRY=true
    fi
}

clone_or_update_project() {
    if [[ -d "${PROJECT_PATH}/.git" ]]; then
        print_status "Updating existing project at ${PROJECT_PATH}..."
        git -C "$PROJECT_PATH" fetch --prune
        git -C "$PROJECT_PATH" pull --ff-only
    elif [[ -d "$PROJECT_PATH" ]]; then
        print_error "${PROJECT_PATH} exists but is not a git repository. Remove it or choose a different --project-dir."
        exit 1
    else
        print_status "Cloning project from ${REPO_URL}..."
        git clone "$REPO_URL" "$PROJECT_PATH"
    fi
}

update_env_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    local escaped_value
    escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')

    if [[ -f "$file" ]] && grep -qE "^${key}=" "$file"; then
        sed -i "s#^${key}=.*#${key}=${escaped_value}#" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
}

configure_project_files() {
    if [[ ! -f "$ENV_FILE" ]]; then
        print_warning "Environment file missing at ${ENV_FILE}; creating a new one."
        mkdir -p "${PROJECT_PATH}/srcs"
        touch "$ENV_FILE"
    fi

    update_env_value "$ENV_FILE" "DOMAIN_NAME" "$DOMAIN"
    update_env_value "$ENV_FILE" "HOST_DATA_ROOT" "$DATA_ROOT"
}

generate_secret() {
    local length="${1:-32}"
    if command_exists openssl; then
        openssl rand -base64 $((length * 2)) | tr -dc 'A-Za-z0-9' | head -c "$length"
    else
        tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
    fi
}

ensure_secret_file() {
    local filename="$1"
    local env_var="$2"
    local length="$3"
    local target="${SECRETS_DIR}/${filename}"
    local value=""

    if [[ -n "$env_var" ]]; then
        value="${!env_var:-}"
    fi

    if [[ -n "$value" ]]; then
        printf '%s\n' "$value" > "$target"
        print_status "Applied secret from environment for ${filename}."
    elif [[ ! -s "$target" ]]; then
        value=$(generate_secret "$length")
        printf '%s\n' "$value" > "$target"
        GENERATED_SECRETS["$filename"]="$value"
        print_status "Generated secret for ${filename}."
    else
        print_status "Reusing existing secret for ${filename}."
    fi

    chmod 600 "$target"
}

ensure_secrets() {
    mkdir -p "$SECRETS_DIR"
    for spec in "${SECRET_SPECS[@]}"; do
        IFS=':' read -r filename env_var length <<< "$spec"
        ensure_secret_file "$filename" "$env_var" "$length"
    done
}

set_script_permissions() {
    if [[ -d "$PROJECT_PATH" ]]; then
        find "$PROJECT_PATH" -type f -name "*.sh" -exec chmod +x {} +
    fi
}

verify_installation() {
    if docker --version >/dev/null 2>&1; then
        print_status "Docker CLI available."
    else
        print_error "Docker CLI unavailable after installation."
    fi

    if docker compose version >/dev/null 2>&1; then
        print_status "Docker Compose plugin available."
    else
        print_error "Docker Compose plugin unavailable."
    fi

    if [[ -d "${DATA_ROOT}/mariadb" && -d "${DATA_ROOT}/wordpress" ]]; then
        print_status "Data directories ready at ${DATA_ROOT}."
    else
        print_error "Expected data directories not found under ${DATA_ROOT}."
    fi

    if grep -qE "^[^#]*\s${DOMAIN}(\s|$)" /etc/hosts; then
        print_status "Host mapping present for ${DOMAIN}."
    else
        print_warning "Host mapping for ${DOMAIN} missing from /etc/hosts."
    fi

    if [[ -f "$ENV_FILE" ]]; then
        print_status "Environment file ready at ${ENV_FILE}."
    else
        print_error "Environment file missing at ${ENV_FILE}."
    fi
}

maybe_start_stack() {
    if [[ "$AUTO_UP" != "true" ]]; then
        return
    fi

    if docker info >/dev/null 2>&1; then
        print_status "Bringing the stack up with 'make up'..."
        make -C "$PROJECT_PATH" up
    else
        print_warning "Docker socket not accessible in current session. Log out/in or run 'newgrp docker', then execute 'make up'."
    fi
}

print_summary() {
    echo
    print_status "Setup tasks completed."
    print_status "Project directory: ${PROJECT_PATH}"
    print_status "Data directory: ${DATA_ROOT}"
    print_status "Domain configured: ${DOMAIN}"

    if [[ "$AUTO_UP" != "true" ]]; then
        print_status "Next step: run 'make up' inside ${PROJECT_PATH}."
    fi

    if [[ "$ADDED_TO_DOCKER_GROUP" == "true" ]]; then
        print_warning "Log out and back in (or run 'newgrp docker') to refresh docker group membership."
    fi

    if [[ "$ADDED_HOSTS_ENTRY" == "true" ]]; then
        print_status "Added /etc/hosts entry for ${DOMAIN}."
    fi

    if (( ${#GENERATED_SECRETS[@]} > 0 )); then
        print_warning "Generated secrets (store these securely):"
        for filename in "${!GENERATED_SECRETS[@]}"; do
            printf "  %s: %s\n" "$filename" "${GENERATED_SECRETS[$filename]}"
        done
    fi
}

main() {
    parse_args "$@"
    check_not_root
    finalize_paths
    require_sudo
    install_base_packages
    install_docker
    ensure_docker_group_membership
    create_data_directories
    ensure_hosts_entry
    clone_or_update_project
    configure_project_files
    ensure_secrets
    set_script_permissions
    verify_installation
    maybe_start_stack
    print_summary
}

main "$@"
