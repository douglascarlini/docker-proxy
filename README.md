# Docker Reverse Proxy

Reverse Proxy with NGINX with Docker.

### How to Use

- Run your app container on network `proxy_network`;
- Give execution permission to script with `chmod +x deploy.sh`;
- Add site to proxy with `./deploy.sh --site app.example.com --port 8080`;