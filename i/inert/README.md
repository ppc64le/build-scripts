Testing
Chrome is a dependency to execute the tests for this package. Chrome binaries are not readily available for ppc64le at the moment, so you'll need to build it on ppc64le to be able to run the tests.

Assuming that the chrome binary is built on Power or is available via other sources, the following command can be used to mount this path inside a UBI container:
mount -t nfs 129.40.81.15:/nfsrepos /nfsrepos
sh docker run -it -v <directory_containing_chrome_binary>:/chromium/ registry.access.redhat.com/ubi8/ubi /bin/bash
or
sometimes mount code doesn't exit where exactly we want to mount in that case follow below steps
copy binary zip folder in root directory
export the path
cd /root
unzip chromium_84_0_4118_0.zip
export CHROME_BIN=/root/chromium_84_0_4118_0/chrome
chmod 777 $CHROME_BIN

Once you have successfully created the container, you can uncomment the test code in the build script , set the Chrome bin environment variable and test your package

Testing Log:
[root@8dcf93bc0240 inert]# npm test

> wicg-inert@3.1.1 test /inert
> npm run build && karma start


> wicg-inert@3.1.1 build /inert
> rollup -c


src/inert.js → dist/inert.esm.js...
created dist/inert.esm.js in 1.5s

src/inert.js → dist/inert.js...
created dist/inert.js in 850ms

src/inert.js → dist/inert.min.js...
created dist/inert.min.js in 1.4s
19 05 2022 10:58:18.016:INFO [karma-server]: Karma v6.3.20 server started at http://localhost:9876/
19 05 2022 10:58:18.026:INFO [launcher]: Launching browsers ChromeHeadless with concurrency unlimited
19 05 2022 10:58:18.035:INFO [launcher]: Starting browser ChromeHeadless
19 05 2022 10:58:18.702:INFO [Chrome Headless 84.0.4118.0 (Linux ppc64le)]: Connected on socket g_NQlO2GH-CrenP8AAAB with id 37731462

  Basic
    ✓ should have no effect on elements outside inert region
    ✓ should make implicitly focusable child not focusable
    ✓ should make explicitly focusable child not focusable
    ✓ should remove attribute and un-inert content if set to false
    ✓ should be able to be reapplied multiple times
    ✓ should apply to dynamically added content
    ✓ should be detected on dynamically added content

  Element.prototype
    ✓ should patch the Element prototype

  Interactives
    ✓ should make button child not focusable
    ✓ should make tabindexed child not focusable
    ✓ should make a[href] child not focusable
    ✓ should make input child not focusable
    ✓ should make select child not focusable
    ✓ should make textarea child not focusable
    ✓ should make details child not focusable
    ✓ should make details with summary child not focusable
    ✓ should make contenteditable child not focusable

  Nested inert regions
    ✓ should apply regardless of how many deep the nesting is
    ✓ should still apply if inner inert is removed
    ✓ should still apply to inner content if outer inert is removed
    ✓ should be detected on dynamically added content within an inert root

  Reapply existing aria-hidden
    ✓ should reinstate pre-existing aria-hidden on setting inert=false

  Reapply existing tabindex
    ✓ should reinstate pre-existing tabindex on setting inert=false
    ✓ should set tabindex correctly for elements added later in the inert root

  ShadowDOM v1
    ✓ should apply inside shadow trees
    ✓ should apply inert styles inside shadow trees
    ✓ should apply inert styles inside shadow trees that aren't focused
    ✓ should apply inside shadow trees distributed content

Chrome Headless 84.0.4118.0 (Linux ppc64le): Executed 28 of 28 SUCCESS (0.367 secs / 0.078 secs)
TOTAL: 28 SUCCESS