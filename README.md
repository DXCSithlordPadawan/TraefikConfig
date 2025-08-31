# TraefikConfig
Set up Traefik as a reverse proxy for Jenkins, Heimdall, Prometheus, Grafana, Helpdesk, Vaultwarden, IES4 Analyst, MD Threat Dashboard with SSL certificates. 

Here's a comprehensive configuration:Now let me create the setup scripts and additional configuration:

Here's your complete Traefik reverse proxy setup:

## Quick Setup Steps:

1. **On Traefik server (192.168.0.124):**
   - Create the directory structure and files from the configuration
   - Run the setup script to create Docker network and set permissions
   - Update domain names in the configuration files

2. **DNS Configuration (192.168.0.110):**
   - Point your service domains (jenkins.yourdomain.com, heimdall.yourdomain.com, traefik.yourdomain.com) to 192.168.0.124

3. **Certificate Management (192.168.0.122):**
   - Either configure automatic certificate retrieval or manually sync certificates using the provided script

4. **Service Configuration:**
   - Ensure Jenkins and Heimdall are accessible on their respective IPs
   - For Jenkins: Add reverse proxy headers if needed
   - For Heimdall: No special configuration typically required

## Key Features:

- **Automatic HTTPS redirect** from port 80 to 443
- **Health checks** for backend services
- **Support for both Let's Encrypt and custom certificates**
- **Traefik dashboard** accessible at traefik.yourdomain.com
- **Flexible certificate management** from your cert-server

## Important Notes:

1. **Replace `yourdomain.com`** with your actual domain
2. **Update email addresses** in the configuration
3. **Choose certificate method**: Either Let's Encrypt (automated) or custom certificates from your cert-server
4. **Security**: Disable Traefik dashboard in production or protect it with authentication
5. **Jenkins may need additional headers** for proper reverse proxy operation

Updated the configuration to include all the additional services.
Updated both configuration files to include all additional services. 
Here's a summary of what was added:

## New Services Added:

1. **Prometheus** (192.168.0.90:9090) - LXC Container
2. **Grafana** (192.168.0.90:3000) - LXC Container  
3. **Helpdesk** (192.168.0.195:80) - LXC Container
4. **Vaultwarden** (192.168.0.210:80) - LXC Container (with bitwarden.aip.dxc.com alias)
5. **Analyst** (192.168.0.200:80) - Docker Container
6. **MDWatch** (192.168.0.201:80) - Docker Container

## Key Updates:

### DNS Configuration:
- Added all new subdomains to point to your Traefik server (192.168.0.124)
- Includes `bitwarden.aip.dxc.com` as an alias for Vaultwarden

### Health Checks:
- **Prometheus**: Uses `/-/healthy` endpoint
- **Grafana**: Uses `/api/health` endpoint  
- **Vaultwarden**: Uses `/alive` endpoint
- **Others**: Use standard `/` root path checks

### Service-Specific Notes:

**For LXC Containers** (Prometheus, Grafana, Helpdesk, Vaultwarden):
- Ensure each service binds to `0.0.0.0` rather than `127.0.0.1`
- Configure firewall to allow access from Traefik server
- Grafana needs specific domain configuration in `grafana.ini`
- Vaultwarden needs `DOMAIN` environment variable set

**For Docker Containers** (Analyst, MDWatch):
- Should be connected to the `traefik` Docker network
- Or accessible via their host IPs as configured

## Next Steps:

1. **Update DNS**: Add all the new A records on your DNS server (192.168.0.110)
2. **Get Certificates**: Request certificates for all new domains from your cert-server (192.168.0.122)
3. **Configure Services**: Update each service's configuration as noted in the comments
4. **Test**: Use the health check script to verify all services are accessible

The configuration provides both automatic Let's Encrypt certificates and manual certificate management from your cert-server. Choose the approach that works best with your infrastructure!
