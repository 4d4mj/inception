# VM Setup Instructions for Inception Project

## Before Moving to VM - Checklist ✅

Your project is now properly configured with:
- ✅ Docker secrets implemented (passwords removed from .env)
- ✅ Proper file permissions set
- ✅ .dockerignore files added
- ✅ .gitignore created to protect secrets
- ✅ Domain name configured for ajabado.42.fr

## Quick Setup (Automated)

### Option 1: Use the Automated Script
1. Copy `vm_setup.sh` to your fresh VM
2. Edit the GitHub URL in the script (line with `REPO_URL=`)
3. Run the script:
```bash
chmod +x vm_setup.sh
./vm_setup.sh
```

### Option 2: Manual Setup Steps

### 1. Prerequisites on VM
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl git ca-certificates gnupg lsb-release

# Install Docker (official method)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker ajabado
```

### 2. Create Required Directories
```bash
# Create data directories
sudo mkdir -p /home/ajabado/data/mariadb
sudo mkdir -p /home/ajabado/data/wordpress
sudo chown -R ajabado:ajabado /home/ajabado/data/
```

### 3. Configure Domain Resolution
```bash
# Add domain to /etc/hosts
echo "127.0.0.1 ajabado.42.fr" | sudo tee -a /etc/hosts
```

### 4. Clone Project from GitHub
```bash
cd /home/ajabado/
git clone YOUR_GITHUB_URL inception
cd inception
find . -name "*.sh" -exec chmod +x {} \;
```

### 5. Deploy
```bash
# Log out and log back in first (for docker group)
cd /home/ajabado/inception
make up
```

## Common Issues & Solutions

### Volume Mount Errors
If you get "no such file or directory" errors:
```bash
# Ensure data directories exist and have correct ownership
sudo mkdir -p /home/ajabado/data/{mariadb,wordpress}
sudo chown -R ajabado:ajabado /home/ajabado/data/
```

### Permission Denied on Scripts
```bash
# Fix script permissions
chmod +x srcs/requirements/*/tools/*.sh
```

### Domain Not Resolving
```bash
# Verify /etc/hosts entry
cat /etc/hosts | grep ajabado.42.fr
# Should show: 127.0.0.1 ajabado.42.fr
```

### Docker Socket Permission
```bash
# If docker commands fail
sudo usermod -aG docker $USER
# Then logout and login again
```

## Security Notes
- Secrets are stored in `secrets/` directory (not in git)
- Passwords are read from Docker secrets at runtime
- No sensitive data in environment variables
- SSL certificates use TLSv1.2/TLSv1.3 only

## Testing
After deployment, test:
```bash
# Check containers are running
docker ps

# Test HTTPS access
curl -k https://ajabado.42.fr

# Check logs if issues
docker logs mariadb
docker logs wordpress
docker logs nginx
```