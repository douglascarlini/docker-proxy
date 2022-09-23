# Docker Reverse Proxy

Reverse Proxy with NGINX for Docker web applications.

### Information

- You can edit `default.conf` and `docker-compose.yml` as you need
- Maybe you will need to add site entry to `/etc/hosts` (if running as normal user)
- The auto-signed SSL certified files will be generated automatically on folder `ssl/{site}`
- If you already have a valid SSL certified, put the `server.crt` and `server.key` files on `ssl/{site}` folder

### Example

`bash deploy.sh <your-site> <site-container> <container-network>`

For site `site1.com` on container `site1_app` on network `site1_default`:

`bash deploy.sh site1.com site1_app site1_default`
