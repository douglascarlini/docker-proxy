# Docker Reverse Proxy

Reverse Proxy with NGINX with Docker.

### How to Use

Create an file `sites.txt` with yours sites and ports:

```
app1.example.com;8081
app2.example.com;8082
app3.example.com;8083
```

Run `bash deploy.sh`