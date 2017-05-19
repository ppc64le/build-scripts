1.	Create a folder where you would store all your .js files to be run against V8.
	$mkdir  /root/js_sample

2.	Create a sample .js file in this dir, say .hello.js.,  with following content:
	print("Welcome to V8 shell")

3.	Now run the container with -v option, where you would mount a folder containing your javascript files and then you could load/test them. 
	$sudo docker run --rm -it -v dir_path_to_be_mounted:/home/nonroot/dir  v8 bash

	Eg:- 
	$ sudo docker run --rm -it .v /root/js_sample:/home/nonroot/js_sample  v8 bash

4.	you can run the command-line version of V8 by typing the "d8" command (e.g., "d8 -f ~/files/file.js"). To use the pre-defined JavaScript object definitions, supply a command like "d8 -f ~/objects.js ~/files/file.js"
$d8

5.	Now you will be inside the d8 shell and you can test it with following sample commands:
D8$ version()


