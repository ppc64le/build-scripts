Docker build command:
docker build -t tidb .

Docker run command:
docker run --name tidb-server -d -p 4000:4000

Then you can use official mysql client to connect to TiDB.
mysql -h 127.0.0.1 -P 4000 -u root -D test --prompt="tidb> "  

Now type .status;. in tidb shell to check whether you are actually connected to tidb.
And you could see tidb related info at .Server version:. section

