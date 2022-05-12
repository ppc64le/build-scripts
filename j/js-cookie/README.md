## Testing



Chrome is a dependency to execute the tests for this package. Chrome binaries are not readily available for ppc64le at the moment, so you'll need to build it on ppc64le to be able to run the tests.



Assuming that the chrome binary is built on Power or is available via other sources, the following command can be used to mount this path inside a UBI container:



```
sh docker run -it -v <directory_containing_chrome_binary>:/chromium/ registry.access.redhat.com/ubi8/ubi /bin/bash
```


Once you have successfully created the container, you can uncomment the test code in the build script , set the Chrome bin environment variable and test your package