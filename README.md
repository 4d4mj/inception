# Inception 42 Project

This project sets up a small infrastructure with Docker Compose consisting of NGINX, WordPress, and MariaDB.

## Prerequisites

- Docker and Docker Compose installed
- Running in a Virtual Machine (as per subject requirements)

## Setup Instructions

### 1. Update Domain Configuration

Before running the project, you need to update the domain name in the `.env` file:

```bash
# Edit srcs/.env and replace 'your_login' with your actual 42 login
DOMAIN_NAME=your_actual_login.42.fr
```

### 2. Add Domain to Hosts File

Add the following line to your `/etc/hosts` file:
```
127.0.0.1 your_actual_login.42.fr
```

### 3. Build and Run

```bash
# Build and start the infrastructure
make

# To stop the containers
make down

# To clean everything and rebuild
make re

# To completely clean (including data directories)
make fclean
```

## Project Structure

```
inception/
├── Makefile
├── secrets/                    # Password files (gitignored)
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml     # Main compose file
    ├── .env                   # Environment variables
    └── requirements/
        ├── mariadb/           # MariaDB container
        │   ├── Dockerfile
        │   ├── conf/mariadb.conf
        │   └── tools/init_db.sh
        ├── nginx/             # NGINX container
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/setup_ssl.sh
        └── wordpress/         # WordPress container
            ├── Dockerfile
            ├── conf/php-fpm.conf
            └── tools/setup_wp.sh
```

## Services

- **NGINX**: Reverse proxy with TLS (port 443)
- **WordPress**: CMS with php-fpm (port 9000)
- **MariaDB**: Database server (port 3306)

## WordPress Users

The setup creates two WordPress users:
- **site_admin**: Administrator user
- **regular_user**: Regular user

Login credentials are defined in the `.env` file.

## Data Persistence

Data is stored in:
- Database: `/home/$USER/data/mysql`
- WordPress files: `/home/$USER/data/wordpress`

## Troubleshooting

### Check container status
```bash
docker ps
```

### View logs
```bash
docker-compose -f srcs/docker-compose.yml logs [service_name]
```

### Test website access
```bash
curl -k https://ajabado.42.fr
```

## Security Features

- TLS 1.2/1.3 only
- No passwords in Dockerfiles
- Environment variables for sensitive data
- Self-signed SSL certificates
- Restricted admin usernames (no 'admin', 'administrator')

## Compliance

This project follows all mandatory requirements from the Inception subject:
- ✅ Custom Dockerfiles only
- ✅ No pre-built images except base OS
- ✅ Proper daemon management (no tail -f, sleep infinity, etc.)
- ✅ Environment variables for configuration
- ✅ TLS-only access through NGINX
- ✅ Persistent data volumes
- ✅ Two WordPress users
- ✅ Auto-restart on crash
