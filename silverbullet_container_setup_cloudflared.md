# cli command
-p to localhost
in cloudflared hostname do NOT set the jwt for the main site
create bypass app for service_worker.js as well as .client
 
```
podman run -d --name silverbullet  -v "/home/podamanis/silverbullet/space:/space" -p 127.0.0.1:11010:3000 --restart unless-stopped ghcr.io/silverbulletmd/silverbullet:latest
```

