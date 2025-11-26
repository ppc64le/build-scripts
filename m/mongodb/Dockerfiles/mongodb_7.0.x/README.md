# MongoDB (ppc64le)
Dockerfile for building **MongoDB 7.0.x** on **IBM Power (ppc64le)** architecture.

---

## Build the Docker Image

```bash
docker build -t mongo-ppc64le:7.0.25 .

## Run a MongoDB Container
docker run -d -p 27017:27017 --name mongodb mongo:7.0.25

## Basic Validation Steps 

1. Access the running container
docker exec -it mongodb bash

2. Check Mongo Shell version
mongosh --version

3. Start mongo shell
mongosh

## CRUD Operation Example
### Inside the mongosh shell, run the following commands:

show dbs
use department

db.employee.insertOne({"Ename": "Tom", "Eid": 33597, "Ecompany": "psl"})
db.employee.insertOne({"Ename": "Jerry", "Eid": 33599, "Ecompany": "persistent"})

db.employee.find({}).pretty()

db.employee.updateOne({"Eid": 33597}, { $set: {"Ename": "Tom", "Ecompany": "persistent"} })

db.employee.deleteOne({"Eid": 33599})

db.employee.find({}).pretty()

