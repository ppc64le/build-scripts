Apple Swift language compiler
-----------------------------

1. Command to build Docker container:
   docker build --tag=swift41 .

2. Command to create a container:
   docker run -it --name test_swift swift41

3. Once inside the container, swift compiler can be used as:
   cd /root/swift-source/Ninja-ReleaseAssert+stdlib-Release/swiftpm-linux-powerpc64le/release
   ./swiftc
