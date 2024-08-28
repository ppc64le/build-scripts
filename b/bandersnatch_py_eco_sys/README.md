If you want to run "test_storage_plugin_s3.py" test, follow below steps along with script to set up minio server.
Here are the steps to set up minio server

--------------------------------------------------------------------------------------------------------------

docker run -d -p 9000:9000 --name minio -e "MINIO_ACCESS_KEY=minioadmin" -e "MINIO_SECRET_KEY=minioadmin" -v '/tmp/data:/data' -v '/tmp/config:/root/.minio' minio/minio server /data
export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin
export AWS_EC2_METADATA_DISABLED=true

--------------------------------------------------------------------------------------------------------------

Use below test command to run all tests : 
python3 test_runner.py

