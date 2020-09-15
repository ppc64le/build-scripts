Run the Irssi container as follows:
$docker run -it --rm --name some-name irrsi

Run another instance of the container:
$docker run .it --rm --name some-other-name irrsi

Now you have two containers running.

In each container, type
/connect Freenode

(Freenode is widely used irssi server, for chatting, you can go for other server also)

Now both the containers will be connect to the server.

Now in both the containers, type,
/join #testchannel

This will connect both the containers to testchannel.

Now any message you type on any of the container, will be seen from other, and it will also be visible to any irssi console connected testchannel. 

Type /eixt to exit the window, and same for exiting the container as well.

