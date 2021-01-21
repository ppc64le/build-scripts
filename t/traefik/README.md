# Deploy traefik on power
1.Execute following commands:
```bash
./build.sh
```
2. configure traefik.toml [API and dashboard configuration section]
```bash
cd traefik-library-image
vi traefik.toml
insecure = true
dashboard = true
```
3. Start Traefik
```bash
docker run -d -p 8080:8080 -p 80:80 \
-v $PWD/traefik.toml:/etc/traefik/traefik.toml \
-v /var/run/docker.sock:/var/run/docker.sock \
traefik-library-image:latest
```

