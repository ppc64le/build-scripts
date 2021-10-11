# Build/Test Apache strimzi-kafka-oauth
### Required by Redhat AMQStreams

## What is strimzi-kafka-oauth?
Strimzi Kafka OAuth modules provide support for OAuth2 as an authentication mechanism when establishing a session with Kafka broker.

## Usage

### Step 1) Build strimzi-kafka-oauth builder docker image (once)
`$ docker build . -t strimzi-kafka-oauth_builder `

### Step 2) Build and Test strimzi-kafka-oauth. 

	
``` $ docker run --rm -v `pwd`:/ws strimzi-kafka-oauth_builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log" ```

Note: To build from the **master branch** do not specify a <rel_tag>.

## Examples:
		
**build/test from master branch**

``` $ docker run --rm -v `pwd`:/ws strimzi-kafka-oauth_builder bash -l -c "cd /ws; ./build.sh" ```

**build/test from branch release-0.6.x**

``` $ docker run --rm -v `pwd`:/ws strimzi-kafka-oauth_builder bash -l -c "cd /ws; ./build.sh release-0.6.x" ```
