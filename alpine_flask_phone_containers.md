Run container
```
podman run -itd --name phn_jmp_bok -v ./py_containers/phone_jump:/phone_jump -v ./py_containers/phone_final:/phone_final -p 127.0.0.1:11035:11035 -p 127.0.0.1:11051:11051 docker.io/alpine:latest /bin/sh
```

```
apk add --no-cache py3-flask
```
