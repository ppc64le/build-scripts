Request-Promise

Building and Running container:

$docker build -t request-promise .
$docker run -it --name=<name> request-promise 

	You can expose the ports with -p at run time as needed.

Testing the package:

When entered in the container, create a sample test.js file as follows:
_______________________________________________________________________________
var rp = require("request-promise");

var url = "https://raw.github.com/mikeal/request/master/package.json";

rp({ url:url, json:true })
  .then(function (data) {
    console.log("%s@%s: %s", data.name, data.version, data.description);
  })
  .catch(function (reason) {
    console.error("%s; %s", reason.error.message, reason.options.url);
    console.log("%j", reason.response.statusCode);
  });
_______________________________________________________________________________

Run the file:
$node test.js

OUTPUT:
request@2.87.1: Simplified HTTP request client.

