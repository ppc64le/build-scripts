# Build cruise-control
### Required by Redhat AMQStreams

## What is linkedin cruise-control?
Cruise Control is a product that helps run Apache Kafka clusters on a large scale. Due to the popularity of Apache Kafka, many companies have bigger and bigger Kafka clusters. At LinkedIn, we have ~7K+ Kafka brokers, which means broker deaths are an almost daily occurrence, and balancing the workload of Kafka also becomes a big overhead.

## Usage

### Step 1) Build linkedin cruise-control builder docker image (once)
`$ docker build . -t cruise-control_builder `

### Step 2) Build linkedin cruise-control. 

	
``` $ docker run --rm -v `pwd`:/ws cruise-control_builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log" ```

Note: To build from **master branch** do not specify a <rel_tag>.

## Examples:
		
**build from master branch**

``` $ docker run --rm -v `pwd`:/ws cruise-control_builder bash -l -c "cd /ws; ./build.sh" ```

**build from release branch**

``` $ docker run --rm -v `pwd`:/ws cruise-control_builder bash -l -c "cd /ws; ./build.sh kafka_0_11_and_1_0" ```
