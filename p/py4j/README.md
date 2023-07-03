Disabling java_tls_test.py as it hangs indefinitely. Refer to line number 85 of the following link:
https://github.com/py4j/py4j/blob/master/.github/workflows/test.yml 


Disabling java_gateway_test.py as it needs IPv6 enabled inside the docker container.

It works fine locally when IPv6 is enabled in the following way:
docker run -t -d --network host --privileged --shm-size=3gb --name package_name registry.access.redhat.com/ubi8/ubi:8.5 /usr/sbin/init


 pytest -k "not java_tls_test."
==================================================================== test session starts ====================================================================
platform linux -- Python 3.8.13, pytest-7.2.2, pluggy-1.0.0
rootdir: /py4j
collected 189 items / 2 deselected / 187 selected

py4j-python/src/py4j/tests/byte_string_test.py .                                                                                                      [  0%]
py4j-python/src/py4j/tests/client_server_test.py .................                                                                                    [  9%]
py4j-python/src/py4j/tests/finalizer_test.py .......                                                                                                  [ 13%]
py4j-python/src/py4j/tests/java_array_test.py .......                                                                                                 [ 17%]
py4j-python/src/py4j/tests/java_callback_test.py .......................                                                                              [ 29%]
py4j-python/src/py4j/tests/java_dir_test.py .........                                                                                                 [ 34%]
py4j-python/src/py4j/tests/java_gateway_test.py ...........................................................................                           [ 74%]
py4j-python/src/py4j/tests/java_help_test.py .........                                                                                                [ 79%]
py4j-python/src/py4j/tests/java_list_test.py ............                                                                                             [ 85%]
py4j-python/src/py4j/tests/java_map_test.py ..                                                                                                        [ 86%]
py4j-python/src/py4j/tests/java_set_test.py ...                                                                                                       [ 88%]
py4j-python/src/py4j/tests/memory_leak_test.py ..............                                                                                         [ 95%]
py4j-python/src/py4j/tests/py4j_signals_test.py ...                                                                                                   [ 97%]
py4j-python/src/py4j/tests/signals_test.py .....                                                                                                      [100%]
===================================================================== warnings summary ======================================================================
py4j-python/src/py4j/tests/java_gateway_test.py:192
  /py4j/py4j-python/src/py4j/tests/java_gateway_test.py:192: PytestCollectionWarning: cannot collect test class 'TestConnection' because it has a __init__ constructor (from: py4j-python/src/py4j/tests/java_gateway_test.py)
    class TestConnection(object):

py4j-python/src/py4j/tests/client_server_test.py::GarbageCollectionTest::testSendObjects
  /py4j/py4j-python/src/py4j/tests/client_server_test.py:148: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(1000, hello.calls)

py4j-python/src/py4j/tests/client_server_test.py::IntegrationTest::testMultiClientServer
  /py4j/py4j-python/src/py4j/tests/client_server_test.py:612: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(thisThreadId,

py4j-python/src/py4j/tests/client_server_test.py::IntegrationTest::testMultiClientServer
  /py4j/py4j-python/src/py4j/tests/client_server_test.py:614: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(thisThreadId,

py4j-python/src/py4j/tests/client_server_test.py::IntegrationTest::testMultiClientServerWithSharedJavaThread
  /py4j/py4j-python/src/py4j/tests/client_server_test.py:569: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(sharedPythonThreadId0,

py4j-python/src/py4j/tests/client_server_test.py::IntegrationTest::testMultiClientServerWithSharedJavaThread
  /py4j/py4j-python/src/py4j/tests/client_server_test.py:571: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(sharedPythonThreadId1,

py4j-python/src/py4j/tests/java_gateway_test.py::MethodTest::testNoneArg
  /py4j/py4j-python/src/py4j/tests/java_gateway_test.py:367: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(ex2.getField1(), 3)

py4j-python/src/py4j/tests/java_gateway_test.py::MethodTest::testNoneArg
  /py4j/py4j-python/src/py4j/tests/java_gateway_test.py:368: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(2, ex.method7(None))

py4j-python/src/py4j/tests/java_gateway_test.py::FieldTest::testSetField
  /py4j/py4j-python/src/py4j/tests/java_gateway_test.py:442: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(get_field(ex, "field10"), 2334)

py4j-python/src/py4j/tests/java_gateway_test.py::FieldTest::testSetField
  /py4j/py4j-python/src/py4j/tests/java_gateway_test.py:446: DeprecationWarning: Please use assertEqual instead.
    self.assertEquals(get_field(ex, "field21").toString(), "Hello World!")


-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
================================================ 187 passed, 2 deselected, 10 warnings in 142.63s (0:02:22) =================================================



