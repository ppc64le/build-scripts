   Test cases failure details for version  v5.4.0
  -----
 ` ` `not ok 5 test exited without ending: test/heroku_rediscloud.test.js -> Confirm RedisCloud is accessible GET/SET
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: test/heroku_rediscloud.test.js ->  Confirm RedisCloud is accessible GET/SET
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 6 test exited without ending: test/kill_connection_manually.test.js -> Kill a Redis Connection
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: test/kill_connection_manually.test.js -> Kill a Redis Connection
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 7 test exited without ending: test/kill_connection_manually.test.js -> Connect to LOCAL Redis instance Which was CLOSED in Previous Test
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: test/kill_connection_manually.test.js ->  Connect to LOCAL Redis instance Which was CLOSED in Previous Test
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 8 test exited without ending: test/local_redis.test.js -> Connect to LOCAL Redis instance as Subscriber
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: test/local_redis.test.js ->  Connect to LOCAL Redis instance as Subscriber
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 9 test exited without ending: test/local_redis.test.js -> Connect to LOCAL Redis instance and GET/SET
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: test/local_redis.test.js ->  Connect to LOCAL Redis instance and GET/SET
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 10 test exited without ending: Require an existing Redis connection
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: Require an existing Redis connection
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 11 test exited without ending: Require an existing Redis SUBSCRIBER connectiong
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: Require an existing Redis SUBSCRIBER connectiong
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 12 test exited without ending: Close Conection & Reset for Heroku Compatibility tests
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: Close Conection & Reset for Heroku Compatibility tests
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 13 test exited without ending: test/local_redis_reuse.test.js -> Connect to LOCAL Redis instance CLOSED in Previous Test
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: test/local_redis_reuse.test.js ->  Connect to LOCAL Redis instance CLOSED in Previous Test
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...
not ok 14 test exited without ending: test/local_redis_reuse.test.js -> Connect to LOCAL Redis instance Which was CLOSED in Previous Test
  ---
    operator: fail
    at: process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
    stack: |-
      Error: test exited without ending: test/local_redis_reuse.test.js ->  Connect to LOCAL Redis instance Which was CLOSED in Previous Test
          at Test.assert [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:275:54)
          at Test.bound [as _assert] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test.fail (/root/redis-connection/node_modules/tape/lib/test.js:368:10)
          at Test.bound [as fail] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at Test._exit (/root/redis-connection/node_modules/tape/lib/test.js:238:14)
          at Test.bound [as _exit] (/root/redis-connection/node_modules/tape/lib/test.js:89:32)
          at process.<anonymous> (/root/redis-connection/node_modules/tape/index.js:86:23)
          at process.emit (events.js:326:22)
  ...

1..14
# tests 14
# pass  4
# fail  10

npm ERR! Test failed.  See above for more details.```