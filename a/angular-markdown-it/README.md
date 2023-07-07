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
29 08 2022 10:50:07.860:INFO [launcher]: Starting browser Firefox
29 08 2022 10:51:07.861:WARN [launcher]: Firefox have not captured in 60000 ms, killing.
29 08 2022 10:51:09.863:WARN [launcher]: Firefox was not killed in 2000 ms, sending SIGKILL.
29 08 2022 10:51:11.863:WARN [launcher]: Firefox was not killed by SIGKILL in 2000 ms, continuing.
------------------angular-markdown-it:install_&_test_both_success-------------------------
https://github.com/macedigital/angular-markdown-it angular-markdown-it
angular-markdown-it  |  https://github.com/macedigital/angular-markdown-it | v0.6.1 | "Red Hat Enterprise Linux 8.5 (Ootpa)" | GitHub  | Pass |  Both_Install_and_Test_Success
