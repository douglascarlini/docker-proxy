:warning: PROJECT UNDER DEVELOPMENT!

# Docker Reverse Proxy

Reverse Proxy with NGINX, Docker and valid SSL with Let's Encrypt.

### How to Use

Create an file `sites.txt` with yours sites and ports:

```
app1.example.com;8081
app2.example.com;8082
app3.example.com;8083
```

Run `bash linux.sh`

### Let's Encrypt

- To generate valid SSL, run `bash ssl.sh admin@admin.admin`
- To renew certificates, run `bash ssl.sh admin@admin.admin renew`