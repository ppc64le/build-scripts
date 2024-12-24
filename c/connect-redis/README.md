Unit tests can be executed using the below commands:

1. Setup redis server

```
sudo yum install redis
sudo systemctl enable redis
sudo systemctl start redis
```

Once the server is up and running

```
npm test
```

Sample output:

````
[root@dev-first-prachikurade-rhel connect-redis]# npm test

> connect-redis@7.1.1 test
> nyc ts-node node_modules/blue-tape/bin/blue-tape "**/*_test.ts"

(node:389644) [DEP0128] DeprecationWarning: Invalid 'main' field in '/root/code/open-source/connect-redis/package.json' of './dist/esm/index.js'. Please either fix that or report it to the module author
(Use `node --trace-deprecation ...` to show where the warning was created)
TAP version 13
# setup
389667:C 05 Sep 2024 04:50:46.471 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
389667:C 05 Sep 2024 04:50:46.471 # Redis version=6.2.7, bits=64, commit=00000000, modified=0, pid=389667, just started
389667:C 05 Sep 2024 04:50:46.472 # Configuration loaded
389667:M 05 Sep 2024 04:50:46.472 * monotonic clock: POSIX clock_gettime
389667:M 05 Sep 2024 04:50:46.472 # A key '__redis__compare_helper' was added to Lua globals which is not on the globals allow list nor listed on the deny list.
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 6.2.7 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 18543
 |    `-._   `._    /     _.-'    |     PID: 389667
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           https://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

389667:M 05 Sep 2024 04:50:46.472 # Server initialized
389667:M 05 Sep 2024 04:50:46.472 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
389667:M 05 Sep 2024 04:50:46.473 * Ready to accept connections
# defaults
ok 1 stores client
ok 2 defaults to sess:
ok 3 defaults to one day
ok 4 defaults SCAN count to 100
ok 5 defaults to JSON serialization
ok 6 defaults to having `touch` enabled
ok 7 defaults to having `ttl` enabled
# redis
ok 8 store.get
ok 9 check one day ttl
ok 10 check expires ttl
ok 11 check expires ttl touch
ok 12 stored two keys length
ok 13 stored two keys ids
ok 14 stored two keys data
ok 15 one key remains
ok 16 no keys remain
ok 17 bulk count
ok 18 bulk clear
ok 19 one key exists (session 789)
ok 20 no key remains and that includes session 789
# ioredis
ok 21 store.get
ok 22 check one day ttl
ok 23 check expires ttl
ok 24 check expires ttl touch
ok 25 stored two keys length
ok 26 stored two keys ids
ok 27 stored two keys data
ok 28 one key remains
ok 29 no keys remain
ok 30 bulk count
ok 31 bulk clear
ok 32 one key exists (session 789)
ok 33 no key remains and that includes session 789
# teardown

1..33
# tests 33
# pass  33

# ok

------------------------|---------|----------|---------|---------|---------------------------------------
File                    | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
------------------------|---------|----------|---------|---------|---------------------------------------
All files               |   92.07 |    69.81 |   97.05 |   94.21 |
 connect-redis          |   92.14 |    69.81 |     100 |   94.41 |
  index.ts              |   85.57 |    70.58 |     100 |   89.47 | 60,88,105,116,126,137,146,159,179,185
  index_test.ts         |     100 |       50 |     100 |     100 | 83
 connect-redis/testdata |    90.9 |      100 |      75 |    90.9 |
  server.ts             |    90.9 |      100 |      75 |    90.9 | 13
------------------------|---------|----------|---------|---------|---------------------------------------
````
