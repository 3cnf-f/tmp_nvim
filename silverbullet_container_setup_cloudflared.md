# cli command
-p to localhost
 
```
podman run -d --name silverbullet  -v "/home/podamanis/silverbullet/space:/space" -p 127.0.0.1:11010:3000 --restart unless-stopped ghcr.io/silverbulletmd/silverbullet:latest
```

