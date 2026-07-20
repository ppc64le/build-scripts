# Docker build
docker build -t langflow-ppc64le:v1.7.3 .

# Docker run 
docker run -d -p 0.0.0.0:7860:7860 --name langflow langflow-ppc64le:v1.7.3 langflow run --host 0.0.0.0 --port 7860

# Import Test 
docker run --rm langflow-ppc64le:v1.7.3 python3.12 -c "import langflow; print('PASS: Langflow import successful')"

# Check Logs
docker logs -f langflow