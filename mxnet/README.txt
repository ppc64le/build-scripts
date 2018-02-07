--------------------------------------------------------------------------------
Validate MXNet Installation
Start the python terminal.

$ python

...........................For GPU ........................

Run a short MXNet python program to create a 2x3 matrix of ones a on a GPU,
multiply each element in the matrix by 2 followed by adding 1. 
We expect the output to be a 2x3 matrix with all elements being 3. We use
mx.gpu(), to set MXNet context to be GPUs.

>>> import mxnet as mx
>>> a = mx.nd.ones((2, 3), mx.gpu())
>>> b = a * 2 + 1
>>> b.asnumpy()
array([[ 3.,  3.,  3.],
       [ 3.,  3.,  3.]], dtype=float32)

Exit the Python terminal.

>>> exit()
$

..........................For CPU .........................

Run a short MXNet python program to create a 2x3 matrix of ones, multiply
each element in the matrix by 2 followed by adding 1. 
We expect the output to be a 2x3 matrix with all elements being 3.

>>> import mxnet as mx
>>> a = mx.nd.ones((2, 3))
>>> b = a * 2 + 1
>>> b.asnumpy()
array([[ 3.,  3.,  3.],
       [ 3.,  3.,  3.]], dtype=float32)
Exit the Python terminal.

>>> exit()
$
