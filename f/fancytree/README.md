# Testing
This package has Chrome dependency. Chrome binaries are not readily available for ppc64le, so to successfully run tests chrome binary need 
to be build on ppc64le.

After making chrome binaries available on Power the fllowing command can be used to mount this path inside a UBI container:


### ES6 Quickstart

```js
sh docker run -it -v <directory_containing_chrome_binary>:/chromium/ registry.access.redhat.com/ubi8/ubi /bin/bash

```

Once The container is successfully created, uncomment the test code in the build script and set the Chrome bin environment variable to test the package.