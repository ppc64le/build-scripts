git clone https://github.com/apache/activemq 
cd activemq 
mvn clean install -DskipTests=true
cp assembly/target/apache-activemq-*-bin.zip ../
cd ..
rm -rf activemq

