# Docker Reverse Proxy

Reverse Proxy with NGINX for Docker web applications.

### Information

- You can edit `default.conf` and `docker-compose.yml` as you need
- Maybe you will need to add site entry to `/etc/hosts` (if running as normal user)
- The auto-signed SSL certified files will be generated automatically on folder `ssl/{site}`
- If you already have a valid SSL certified, put the `server.crt` and `server.key` files on `ssl/{site}` folder

### Example

For site `site1.com`:

- Your app container must be named `site1.com`
- Your app container must be running on network `site1.com`
- Your app container must have ports `80` and `443` exposed

### Create Reverse Proxy and add Site

```bash
bash deploy.sh site1.com site2.com site3.com
```
### SSL Certified

You can update SSL certified for your site with command:

```bash
docker cp /path/to/files proxy:/etc/ssl/certs/nginx/{site}
```
