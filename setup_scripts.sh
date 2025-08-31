#!/bin/bash
# setup-traefik.sh - Setup script for Traefik

echo "Setting up Traefik reverse proxy..."

# Create necessary directories
mkdir -p traefik/{certs,logs}
cd traefik

# Create Docker network for Traefik
docker network create traefik 2>/dev/null || echo "Network 'traefik' already exists"

# Set proper permissions for certificate directory
chmod 700 certs
touch certs/acme.json
chmod 600 certs/acme.json

# Create environment file
cat > .env << EOF
DOMAIN=yourdomain.com
EMAIL=your-email@yourdomain.com
TRAEFIK_VERSION=v3.0
EOF

echo "Traefik setup complete!"
echo "Next steps:"
echo "1. Update domain names in dynamic.yml"
echo "2. Configure your DNS (192.168.0.110) to point domains to 192.168.0.124"
echo "3. Set up certificate retrieval from cert-server (192.168.0.122)"
echo "4. Start Traefik: docker-compose up -d"

---
# cert-sync.sh - Script to sync certificates from cert-server
#!/bin/bash

CERT_SERVER="192.168.0.122"
CERT_DIR="/path/to/traefik/certs"
DOMAINS=("jenkins.yourdomain.com" "heimdall.yourdomain.com" "traefik.yourdomain.com")

echo "Syncing certificates from cert-server..."

for domain in "${DOMAINS[@]}"; do
    echo "Retrieving certificate for $domain..."
    
    # Method 1: Using SCP (if SSH access is available)
    scp user@$CERT_SERVER:/path/to/certs/$domain.crt $CERT_DIR/
    scp user@$CERT_SERVER:/path/to/certs/$domain.key $CERT_DIR/
    
    # Method 2: Using curl/wget (if cert-server has HTTP API)
    # curl -o $CERT_DIR/$domain.crt http://$CERT_SERVER/api/certs/$domain.crt
    # curl -o $CERT_DIR/$domain.key http://$CERT_SERVER/api/certs/$domain.key
    
    # Method 3: Using rsync
    # rsync -av user@$CERT_SERVER:/path/to/certs/$domain.* $CERT_DIR/
done

# Set proper permissions
chmod 600 $CERT_DIR/*.key
chmod 644 $CERT_DIR/*.crt

# Restart Traefik to reload certificates
docker-compose restart traefik

echo "Certificate sync complete!"

---
# Jenkins Configuration
# Add these environment variables to your Jenkins container

# If Jenkins is running in Docker, update its docker-compose.yml:
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
    networks:
      - traefik
    environment:
      - JENKINS_OPTS="--httpPort=8080 --prefix=/jenkins"
      # For reverse proxy configuration
      - JAVA_OPTS="-Dhudson.model.DirectoryBrowserSupport.CSP="

networks:
  traefik:
    external: true

volumes:
  jenkins_home:

---
# Heimdall Configuration
# If Heimdall is running in Docker:

version: '3.8'
services:
  heimdall:
    image: lscr.io/linuxserver/heimdall:latest
    container_name: heimdall
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - heimdall_config:/config
    networks:
      - traefik
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London

networks:
  traefik:
    external: true

volumes:
  heimdall_config:

---
# Prometheus Configuration (LXC Container)
# Ensure Prometheus is configured to accept external connections
# In prometheus.yml, set:
# web.listen-address: 0.0.0.0:9090
# web.external-url: https://prometheus.aip.dxc.com

---
# Grafana Configuration (LXC Container) 
# Update /etc/grafana/grafana.ini:
[server]
domain = grafana.aip.dxc.com
root_url = https://grafana.aip.dxc.com/
serve_from_sub_path = false

[security]
cookie_secure = true

---
# Vaultwarden Configuration (LXC Container)
# Update vaultwarden configuration:
# DOMAIN=https://vaultwarden.aip.dxc.com
# ROCKET_PORT=80
# WEBSOCKET_ENABLED=true

---
# Analyst Configuration (Docker Container)
# If Analyst is running in Docker, ensure it's on the traefik network:
version: '3.8'
services:
  analyst:
    image: your-analyst-image:latest
    container_name: analyst
    restart: unless-stopped
    ports:
      - "80:80"
    networks:
      - traefik
    environment:
      - TZ=Europe/London

networks:
  traefik:
    external: true

---
# MDWatch Configuration (Docker Container)
# If MDWatch is running in Docker, ensure it's on the traefik network:
version: '3.8'
services:
  mdwatch:
    image: your-mdwatch-image:latest
    container_name: mdwatch
    restart: unless-stopped
    ports:
      - "80:80"
    networks:
      - traefik
    environment:
      - TZ=Europe/London

networks:
  traefik:
    external: true

---
# Service-specific notes:
# LXC Containers (Jenkins, Heimdall, Prometheus, Grafana, Helpdesk, Vaultwarden):
# - These run directly on their host IPs
# - Ensure firewall allows access from Traefik (192.168.0.124)
# - Configure each service to bind to 0.0.0.0 or allow external access
#
# Docker Containers (Analyst, MDWatch):  
# - These should be connected to the 'traefik' Docker network
# - Or ensure they're accessible on their host IPs as configured above

---
# DNS Configuration Script
#!/bin/bash
# dns-config.sh - Configure DNS entries (run on DNS server 192.168.0.110)

DNS_SERVER="192.168.0.110"
TRAEFIK_IP="192.168.0.124"

echo "Configuring DNS entries for Traefik..."

# Example for BIND DNS server
# Add these entries to your zone file:

cat >> /etc/bind/zones/aip.dxc.com << EOF
; Traefik and services
traefik         IN      A       $TRAEFIK_IP
jenkins         IN      A       $TRAEFIK_IP
heimdall        IN      A       $TRAEFIK_IP
dashboard       IN      A       $TRAEFIK_IP
prometheus      IN      A       $TRAEFIK_IP
grafana         IN      A       $TRAEFIK_IP
helpdesk        IN      A       $TRAEFIK_IP
vaultwarden     IN      A       $TRAEFIK_IP
bitwarden       IN      A       $TRAEFIK_IP
analyst         IN      A       $TRAEFIK_IP
mdwatch         IN      A       $TRAEFIK_IP
EOF

# Reload DNS
systemctl reload bind9

# For other DNS servers, adjust accordingly:
# - Pi-hole: Add custom DNS entries in admin panel
# - dnsmasq: Add entries to /etc/hosts or dnsmasq configuration
# - Windows DNS: Use DNS Manager MMC

echo "DNS configuration complete!"
echo "Test with: nslookup jenkins.aip.dxc.com"

---
# Health check script
#!/bin/bash
# health-check.sh - Check if all services are accessible

SERVICES=("traefik" "jenkins" "heimdall" "prometheus" "grafana" "helpdesk" "vaultwarden" "analyst" "mdwatch")
DOMAIN="aip.dxc.com"

for service in "${SERVICES[@]}"; do
    echo "Checking $service.$DOMAIN..."
    
    # Check HTTP redirect to HTTPS
    http_status=$(curl -s -o /dev/null -w "%{http_code}" "http://$service.$DOMAIN")
    echo "HTTP status: $http_status"
    
    # Check HTTPS
    https_status=$(curl -s -o /dev/null -w "%{http_code}" "https://$service.$DOMAIN")
    echo "HTTPS status: $https_status"
    
    # Check certificate
    echo "Certificate info:"
    openssl s_client -connect "$service.$DOMAIN:443" -servername "$service.$DOMAIN" </dev/null 2>/dev/null | openssl x509 -noout -dates
    
    echo "---"
done