### Build Command
```bash
docker build -t redis-cluster-ppc64le:8.4.1 -f Dockerfile.txt .
```

**Build Time:** Approximately 15-20 minutes (depending on system resources)

### Verify Build
```bash
docker images | grep redis-cluster-ppc64le
```

**Expected Output:**
```
REPOSITORY                    TAG       IMAGE ID       CREATED          SIZE
redis-cluster-ppc64le         8.4.1     <image-id>     X minutes ago    445 MB
```

---


#### Basic Run
```bash
docker run -d --name redis-standalone \
  -p 6379:6379 \
  -e ALLOW_EMPTY_PASSWORD=yes \
  redis-cluster-ppc64le:8.4.1 \
  redis-server --protected-mode no \
    --loadmodule /opt/bitnami/redis/modules/redisbloom.so \
    --loadmodule /opt/bitnami/redis/modules/redisearch.so \
    --loadmodule /opt/bitnami/redis/modules/rejson.so \
    --loadmodule /opt/bitnami/redis/modules/redistimeseries.so
```

#### With Password
```bash
docker run -d --name redis-standalone \
  -p 6379:6379 \
  -e REDIS_PASSWORD=mypassword \
  redis-cluster-ppc64le:8.4.1 \
  redis-server --protected-mode no --requirepass mypassword \
    --loadmodule /opt/bitnami/redis/modules/redisbloom.so \
    --loadmodule /opt/bitnami/redis/modules/redisearch.so \
    --loadmodule /opt/bitnami/redis/modules/rejson.so \
    --loadmodule /opt/bitnami/redis/modules/redistimeseries.so
```

## Interactive Shell Access

```bash
docker exec -it redis-standalone bash
```

### 3. Stop and Remove Container

```bash
docker stop redis-standalone
docker rm redis-standalone
```

---

## Verification

### 1. Check Container Status
```bash
docker ps | grep redis-standalone
```

### 2. Check Redis Binaries
```bash
docker exec -it redis-standalone ls -lh /opt/bitnami/redis/bin/
```

### 3. Verify Modules Present
```bash
docker exec -it redis-standalone ls -lh /opt/bitnami/redis/modules/
```

**Expected Output:**
```
total 26M
-rwxrwxr-x. 1 root root 646K redisbloom.so
-rwxrwxr-x. 1 root root  17M redisearch.so
-rwxrwxr-x. 1 root root 2.4M redistimeseries.so
-rwxrwxr-x. 1 root root 5.6M rejson.so
```

### 4. Test Redis Connection
```bash
docker exec -it redis-standalone redis-cli ping
```

**Expected Output:**
```
PONG
```

### 5. Check Loaded Modules
```bash
docker exec -it redis-standalone redis-cli MODULE LIST
```

**Expected Output:**
```
1) 1) "name"
   2) "bf"
   3) "ver"
   4) (integer) 80402
   ...
2) 1) "name"
   2) "search"
   3) "ver"
   4) (integer) 80405
   ...
3) 1) "name"
   2) "ReJSON"
   3) "ver"
   4) (integer) 80402
   ...
4) 1) "name"
   2) "timeseries"
   3) "ver"
   4) (integer) 80407
   ...
```

---

## Module Testing

### RedisJSON Module

#### Set JSON Data
```bash
docker exec -it redis-standalone redis-cli JSON.SET user:1 . '{"name":"John","age":30,"city":"New York"}'
```

**Expected Output:** `OK`

#### Get JSON Data
```bash
docker exec -it redis-standalone redis-cli JSON.GET user:1
```

**Expected Output:** `"{\"name\":\"John\",\"age\":30,\"city\":\"New York\"}"`

#### Query JSON Field
```bash
docker exec -it redis-standalone redis-cli JSON.GET user:1 .name
```

**Expected Output:** `"\"John\""`

---

### RedisBloom Module

#### Create Bloom Filter
```bash
docker exec -it redis-standalone redis-cli BF.ADD emails user1@example.com
```

**Expected Output:** `(integer) 1`

#### Check Item Exists
```bash
docker exec -it redis-standalone redis-cli BF.EXISTS emails user1@example.com
```

**Expected Output:** `(integer) 1`

#### Check Non-existent Item
```bash
docker exec -it redis-standalone redis-cli BF.EXISTS emails user2@example.com
```

**Expected Output:** `(integer) 0`

---

### RedisTimeSeries Module

#### Create Time Series
```bash
docker exec -it redis-standalone redis-cli TS.CREATE temperature RETENTION 86400000 LABELS sensor_id 1 location room1
```

**Expected Output:** `OK`

#### Add Data Points
```bash
docker exec -it redis-standalone redis-cli TS.ADD temperature '*' 22.5
docker exec -it redis-standalone redis-cli TS.ADD temperature '*' 23.0
docker exec -it redis-standalone redis-cli TS.ADD temperature '*' 22.8
```

**Expected Output:** `(integer) <timestamp>`

#### Query Time Series
```bash
docker exec -it redis-standalone redis-cli TS.RANGE temperature - +
```

**Expected Output:**
```
1) 1) (integer) <timestamp1>
   2) "22.5"
2) 1) (integer) <timestamp2>
   2) "23"
3) 1) (integer) <timestamp3>
   2) "22.8"
```

---

### RedisSearch Module

#### Create Index
```bash
docker exec -it redis-standalone redis-cli FT.CREATE products ON HASH PREFIX 1 product: SCHEMA name TEXT SORTABLE price NUMERIC SORTABLE category TAG
```

**Expected Output:** `OK`

#### Add Products
```bash
docker exec -it redis-standalone redis-cli HSET product:1 name "Laptop" price 999 category "Electronics"
docker exec -it redis-standalone redis-cli HSET product:2 name "Mouse" price 25 category "Electronics"
docker exec -it redis-standalone redis-cli HSET product:3 name "Desk" price 299 category "Furniture"
```

**Expected Output:** `(integer) 3`

#### Search Products
```bash
docker exec -it redis-standalone redis-cli FT.SEARCH products "Electronics" RETURN 2 name price
```

**Expected Output:**
```
1) (integer) 2
2) "product:1"
3) 1) "name"
   2) "Laptop"
   3) "price"
   4) "999"
4) "product:2"
5) 1) "name"
   2) "Mouse"
   3) "price"
   4) "25"
```

#### Search with Filter
```bash
docker exec -it redis-standalone redis-cli FT.SEARCH products "@category:{Electronics} @price:[0 100]"
```

**Expected Output:** Returns products in Electronics category with price ≤ 100

---
