Build/Test 3scale_toolbox
-------------------------

3scale toolbox is a set of tools to help manage 3scale product.

Step 1) Build 3scale_toolbox builder image (once per release)
	$ docker build -t 3scale_toolbox_builder .

Step 2) Build and Test 3scale_toolbox
	$ docker run --rm -v `pwd`:/ws 3scale_toolbox_builder bash -l -c "cd /ws; ./build.sh | tee output.log"
