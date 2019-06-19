Prerequisites:
	1. Navigate to the mikefarah-yq folder
	2. Refer to the README.md and build the mikefarah-yq docker image.
	3. Navigate to the registry-centos and s2i-base-container folders
	4. Refer to the README.md and build the respective images.

Build command:

	docker build -t eclipse/che-plugin-registry .

Run command:

	docker run -it  --rm  -p 8080:8080 eclipse/che-plugin-registry
