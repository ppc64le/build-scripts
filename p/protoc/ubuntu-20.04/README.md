# Build protoc-3.5.1-1-linux-ppcle_64.exe
### Required by Apache HBase/Zeppline/Camel-examples

## What is Protocol Buffers?
Protocol Buffers (a.k.a., protobuf) are Google's language-neutral, platform-neutral, extensible mechanism for serializing structured data. 

## GitHub URL
https://github.com/protocolbuffers/protobuf

## Usage

### Step 1) Build Protocol Buffers builder docker image (once)
`$ docker build . -t protoc_builder `

### Step 2) Build protoc-3.5.1-1-linux-ppcle_64.exe. 

	
``` $ docker run --rm -v `pwd`:/ws protoc_builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | te output.log" ```

Note: To build from the **master branch** do not specify a <rel_tag>.

## Examples:
		
**build from master branch**

``` $ docker run --rm -v `pwd`:/ws protoc_builder bash -l -c "cd /ws; ./build.sh" ```

**build from branch v3.5.1.1**

``` $ docker run --rm -v `pwd`:/ws protoc_builder bash -l -c "cd /ws; ./build.sh v3.5.1.1" ```
