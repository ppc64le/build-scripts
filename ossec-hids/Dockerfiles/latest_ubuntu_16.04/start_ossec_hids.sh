# Script for adding default user and starting ossec-hids
# This will run when the docker container starts up

#PATH for manage_agent and ossec-contrl executables
export PATH=$PATH:/srv/ossec/bin

# This is required for manage_agents to run with -f option
# To mount /dev, the docker container need to be started in
# privlidged mode, otherwise these commands will fail
cd /srv/ossec
mkdir dev
mount -o bind /dev dev/

# Add default_agent before starting ossec-hids.
# ossec-remoted exits if no agent is configured.
./bin/manage_agents -f default_local_agent

# Start the ossec services
ossec-control start

# Run in a loop, keep the container running
while true
do
	sleep 1
done
