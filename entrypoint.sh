#!/bin/bash

#Setup environment

# Retrieve the instances in the Kafka cluster
mkdir /tmp/zookeeper && mkdir /tmp/kafka-logs

cd $KAFKA_HOME && \
cd ./config 
touch hosts

nslookup $HOSTNAME >> zk.cluster

# Configure Zookeeper
NO=$(($(wc -l < zk.cluster) - 2))

while read line; do
	ip=$(echo $line | grep -oE "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b")
	echo "$ip" >> zk.cluster.tmp
done < 'zk.cluster'
rm zk.cluster

sort -n zk.cluster.tmp > zk.cluster.tmp.sort
mv zk.cluster.tmp.sort zk.cluster.tmp

no_instances=1
while read line; do
        if [ "$line" != "" ]; then
		#eval var=\$"HOST"$no_instances
		echo "server.$no_instances=$line:2888:3888" >> $KAFKA_HOME/config/zookeeper.properties
		echo "$(cat hosts) $ip:2181" >  hosts
		no_instances=$(($no_instances + 1))
	fi
done < 'zk.cluster.tmp'

index = 0

echo "$index" >> /tmp/zookeeper/myid
sed "s/broker.id=0/broker.id=$index/" $KAFKA_HOME/config/server.properties >> $KAFKA_HOME/config/server.properties.tmp
mv $KAFKA_HOME/config/server.properties.tmp $KAFKA_HOME/config/server.properties
 
echo "initLimit=5" >> $KAFKA_HOME/config/zookeeper.properties
echo "syncLimit=2" >> $KAFKA_HOME/config/zookeeper.properties

# configure all the hosts in the cluster in the server.properties file
sed -i 's/^ *//' hosts 
sed -e 's/\s/,/g' hosts > hosts.txt

content=$(cat $KAFKA_HOME/config/hosts.txt)

sed "s/zookeeper.connect=localhost:2181/zookeeper.connect=$content/" $KAFKA_HOME/config/server.properties >> $KAFKA_HOME/config/server.properties.tmp && \
mv  $KAFKA_HOME/config/server.properties.tmp  $KAFKA_HOME/config/server.properties

# Start Zookeeper service
nohup $KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties &

# Start Kafka service
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
