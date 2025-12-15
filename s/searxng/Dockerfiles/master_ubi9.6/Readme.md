* To Build SearXNG Image: 
```bash
docker buildx build . --load -t searxng:latest
```

To create and run the container from the image built: 

* Run the SearXNG image:
```bash
 # to use with random secret 
 docker run -p 8888:8888 searxng:latest
 #OR to use your custom searxng secret
 docker run -p 8888:8888-e SEARXNG_SECRET="my_secure_custom_key" searxng:latest
```