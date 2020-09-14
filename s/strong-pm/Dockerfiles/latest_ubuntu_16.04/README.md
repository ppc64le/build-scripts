strong-pm

$ docker build -t strong-pm .
$ docker run -it -p 8701:8701 -p 3000:3000 -p 3001:3001 -p 3002:3002 -p 3003:3003  strong-pm

Testing:

Now you can access the service through browser at:

http://ipaddress:8701/explorer 
