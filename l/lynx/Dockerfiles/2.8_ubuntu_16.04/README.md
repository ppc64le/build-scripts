Using and Testing Lynx Container:

Start the container with following command:
	$docker run -it --rm lynx
Now you will be on official page of lynx.
From here you can go to any url you want as follows:
	Press .g.
	Enter the URL you want to visit.
	Press y or n depending upon whether you want to allow cookies.
	You can even start the container with specific url as follows:
       		$ docker run -it --rm lynx lynx <website_url>
        Eg: $ docker run -it --rm lynx lynx www.google.com
	Once the site is loaded you can use the arrow keys to brows the contents.
	After this instruction for how to use lynx are shown at the bottom of the lynx window

