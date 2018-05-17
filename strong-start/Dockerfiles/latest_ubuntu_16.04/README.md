Strong-Start 

$ docker build -t strong-start .
$ docker run -it -p 8701:8701 -p 3000:3000 -p 3001:3001 -p 3002:3002 -p 3003:3003 strong-start bash

Testing the Strong-start

Clone an example app in root directory:

git clone https://github.com/strongloop/express-example-app.git
cd express-example-app
npm install
sl-start.js


Now sl-start command has started the application using strong-start.
you can visit the app from browser at http://vm_ip:3002
