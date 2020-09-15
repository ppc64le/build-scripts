# Docker Image for Tensorflow1.3.1 on Ubuntu 16.04 (With GPU support)
# How to Use 

NOTE - We are providing some patches in patches.zip file, please keep these patches and the Dockerfile under the same directory
e.g.   cd <$wdir>
         |
         |_ Dockerfile (This is a TF Dockerfile)
         |
         +-patches (All the patches should be in "patches" directory)

1) First create a docker image using following command :
      
	$ sudo nvidia-docker build -t tensorflow1.3.1:gpu .


2) Run tensorflow-gpu image , it will automatically start the Jupyter Notebook Server on port 8888 :

	$ sudo nvidia-docker run -it -p 8888:8888 tensorflow1.3.1:gpu
	
3) Go to your browser on  http://localhost:8888/  and you can see Jupyter Notebook Server running.
   You can perform some operations on Jupiter Server to test if everything is alright.
   
   
4)  Also we can access TensorBoard on port 6006.

	Visualisation with TensorBoard :
    TensorBoard is a suite of web applications for inspecting and understanding your TensorFlow runs and graphs.TensorBoard currently supports five visualizations: scalars, images, audio, histograms, and graphs.The computations you will use in TensorFlow for things such as training a massive deep neural network,can be fairly complex and confusing, TensorBoard will make this a lot easier to understand, debug, and optimize your TensorFlow programs.

    For more details refer - https://github.com/tensorflow/tensorboard , https://learningtensorflow.com/Visualisation/ , https://www.tensorflow.org/get_started/summaries_and_tensorboard  and https://www.tensorflow.org/get_started/graph_viz etc.
	
	Usage -

	a) Before running TensorBoard, make sure you have generated summary data in a log directory by creating a summary writer:
       sess.graph contains the graph definition; that enables the Graph Visualizer.
           $ file_writer = tf.summary.FileWriter('/path/to/logs', sess.graph)
   
	b) For more details, see the TensorBoard tutorial (https://www.tensorflow.org/get_started/summaries_and_tensorboard). Once you have event files, run TensorBoard and provide the log directory. If you're using a precompiled TensorFlow package (e.g. you installed via pip), run:
        $ tensorboard --logdir path/to/logs

	c)This should print that TensorBoard has started. Next, connect to http://localhost:6006.
      TensorBoard requires a logdir to read logs from. For info on configuring TensorBoard, run tensorboard --help.
      TensorBoard can be used in Google Chrome or Firefox. Other browsers might work, but there may be bugs or performance issues.

	  
5) Run below command to check tensorflow1.3.1 installed location and other information
   
        $ pip show tensorflow


6) Try your first TensorFlow program

	$ python
	>>> import tensorflow as tf
	>>> hello = tf.constant('Hello, TensorFlow!')
	>>> sess = tf.Session()
	>>> sess.run(hello)
	'Hello, TensorFlow!'
	>>> a = tf.constant(10)
	>>> b = tf.constant(32)
	>>> sess.run(a + b)
	42
	>>> sess.close()
