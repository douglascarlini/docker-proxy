# Docker Reverse Proxy

Reverse Proxy with NGINX with Docker.

### Information

- Maybe you will need to add site entry to `/etc/hosts` (if running as normal user)
- The auto-signed SSL certified files will be generated automatically on folder `ssl/{site}`
- If you already have a valid SSL certified, put the `server.crt` and `server.key` files on `ssl/{site}` folder

### Example

Create an `apps.txt` file with sites configuration as example:

```
dba.myapp.com;myapp;dba;1
api.myapp.com;myapp;api;3
web.myapp.com;myapp;app;3
```

> Format: `[domain];[project/folder];[service];[replicas]`

The example will create 3 configuration files:

- `dba.myapp.com.conf` proxed to `upstream myapp-dba` with server `myapp-dba-1`;
- `api.myapp.com.conf` proxed to `upstream myapp-api` with servers `myapp-api-1`, `myapp-api-2` and  `myapp-api-3`;
- `web.myapp.com.conf` proxed to `upstream myapp-web` with servers `myapp-web-1`, `myapp-web-2` and  `myapp-web-3`;

Now, you can deploy with `./deploy.sh` (check execution permission).