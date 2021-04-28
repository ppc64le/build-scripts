Building and saving 3scale-istio-adapter

Step 1) Build the 3scale-istio-adapter container image (once per release) 
	`$ docker build -t 3scale-istio-adapter:ibm`

Step 2) Build, Test and package 3scale-istio-adapter binary 
	`docker run --rm -v `pwd`:/ws 3scale-istio-adapter:ibm bash -l -c "cd /ws; ./build.sh | tee output.log"`
