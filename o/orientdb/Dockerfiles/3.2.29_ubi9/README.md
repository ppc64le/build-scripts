### Command to build OrientDB:
```bash
docker build -t orientdb:3.2.29 .
```

### Command to run OrientDB:
```bash
docker run -d --name orientdb -p 2424:2424 -p 2480:2480 -e ORIENTDB_ROOT_PASSWORD=rootpwd orientdb:3.2.29
