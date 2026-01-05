Unit tests can be executed using the below commands:

```
docker run -d --name amqp.test -p 5672:5672 rabbitmq
```

Once the container is up and running

```
npm test
```

Sample output:

```
[root@dev-first-prachikurade-rhel ~]# docker run -d --name amqp.test -p 5672:5672 rabbitmq
Unable to find image 'rabbitmq:latest' locally
latest: Pulling from library/rabbitmq
dcb5d217f9f1: Pull complete
d8249bef981c: Pull complete
11ec9664ccb2: Pull complete
6eebefb26b17: Pull complete
3c20407ad8c6: Pull complete
ae64d1197200: Pull complete
a09d8ea9f874: Pull complete
5823dc8f13b7: Pull complete
025f2a9dbd9b: Pull complete
Digest: sha256:28056725fa3d3168f5bace5b6100d66e721562a8a9fdcbe2a9ff310dcc83e3c9
Status: Downloaded newer image for rabbitmq:latest
a53c83abef3fda2318f9f4d3313d282344a05378d21abccb395af244c2563c44


[root@dev-first-prachikurade-rhel amqplib]# npm test

> amqplib@0.10.4 test
> make test

./node_modules/.bin/mocha --check-leaks -u tdd --exit test/


  ✔ single input
  ✔ single input, resuming stream
  ✔ two sequential inputs
  ✔ two interleaved inputs
  ✔ unpipe
  ✔ roundrobin
  BitSet
    ✔ get bit
    ✔ clear bit
    ✔ next set of empty
    ✔ next set of one bit
    ✔ next set same bit
    ✔ next set following bit
    ✔ next clear of empty
    ✔ next clear of one set

  versionGreaterThan
    ✔ full spec
    ✔ partial spec
    ✔ not greater

  connect
    ✔ at all (62ms)

  updateSecret
    ✔ updateSecret (49ms)

  channel open
    ✔ at all (50ms)
    ✔ open and close (50ms)

  assert, check, delete
    ✔ assert, check, delete queue (68ms)
    ✔ assert, check, delete exchange (58ms)
    ✔ fail on check non-queue (51ms)
    ✔ fail on check non-exchange (49ms)

  bindings
    ✔ bind queue (65ms)
    ✔ bind exchange (110ms)

  sending messages
    ✔ send to queue and consume noAck (59ms)
    ✔ send to queue and consume ack (56ms)
    ✔ send to and get from queue (96ms)

  ConfirmChannel
    ✔ Receive confirmation (61ms)
    ✔ Wait for confirms (161ms)

  Error handling
    ✔ Throw error in connection open callback (46ms)
    ✔ Channel open callback throws an error (50ms)
    ✔ RPC callback throws error (48ms)
    ✔ Get callback throws error (53ms)
    ✔ Consume callback throws error (60ms)
    ✔ Get from non-queue invokes error k (51ms)
    ✔ Consume from non-queue invokes error k (48ms)

  Connection errors
    ✔ socket close during open
    ✔ bad frame during open

  Connection open
    ✔ happy
    ✔ wrong first frame
    ✔ unexpected socket close

  Connection running
    ✔ wrong frame on channel 0
    ✔ unopened channel
    ✔ unexpected socket close
    ✔ connection.blocked
    ✔ connection.unblocked

  Connection close
    ✔ happy
    ✔ interleaved close frames
    ✔ server error close
    ✔ operator-intiated close
    ✔ double close

  heartbeats
    ✔ send heartbeat after open
    ✔ detect lack of heartbeats (61ms)

  channel open and close
    ✔ open
    ✔ bad server
    ✔ open, close
    ✔ server close
    ✔ overlapping channel/server close
    ✔ double close

  channel machinery
    ✔ RPC
    ✔ Bad RPC
    ✔ RPC on closed channel
    ✔ publish all < single chunk threshold
    ✔ publish content > single chunk threshold
    ✔ publish method & headers > threshold
    ✔ publish zero-length message
    ✔ delivery
    ✔ zero byte msg
    ✔ bad delivery
    ✔ bad content send
    ✔ bad properties send
    ✔ bad consumer
    ✔ bad send in consumer
    ✔ return
    ✔ cancel
    ✔ confirm ack
    ✔ confirm nack
    ✔ out-of-order acks
    ✔ not all out-of-order acks

  connect
    ✔ at all (50ms)
    ✔ create channel (51ms)

  updateSecret
    ✔ updateSecret (48ms)

  assert, check, delete
    ✔ assert and check queue (52ms)
    ✔ assert and check exchange (59ms)
    ✔ fail on reasserting queue with different options (58ms)
    ✔ fail on checking a queue that's not there (47ms)
    ✔ fail on checking an exchange that's not there (49ms)
    ✔ fail on reasserting exchange with different type (50ms)
    ✔ channel break on publishing to non-exchange (48ms)
    ✔ delete queue (54ms)
    ✔ delete exchange (72ms)

  sendMessage
    ✔ send to queue and get from queue (122ms)
    ✔ send (and get) zero content to queue (108ms)

  binding, consuming
    ✔ route message (109ms)
    ✔ purge queue (109ms)
    ✔ unbind queue (179ms)
    ✔ consume via exchange-exchange binding (64ms)
    ✔ unbind exchange (187ms)
    ✔ cancel consumer (106ms)
    ✔ cancelled consumer (63ms)
    ✔ ack (162ms)
    ✔ nack (232ms)
    ✔ reject (159ms)
    ✔ prefetch (109ms)
    ✔ close (57ms)

  confirms
    ✔ message is confirmed (51ms)
    ✔ multiple confirms (63ms)
    ✔ wait for confirms (164ms)
    ✔ works when channel is closed (171ms)

  Implicit encodings
    ✔ byte
    ✔ byte max value
    ✔ byte min value
    ✔ < -128 promoted to signed short
    ✔ > 127 promoted to short
    ✔ < 2^15 still a short
    ✔ -2^15 still a short
    ✔ >= 2^15 promoted to int
    ✔ < -2^15 promoted to int
    ✔ < 2^31 still an int
    ✔ >= -2^31 still an int
    ✔ >= 2^31 promoted to long
    ✔ < -2^31 promoted to long
    ✔ float value
    ✔ negative float value
    ✔ string
    ✔ byte array from buffer
    ✔ true
    ✔ false
    ✔ null
    ✔ array
    ✔ object
    ✔ timestamp
    ✔ decimal
    ✔ float

  Domains
    ✔ <octet> domain
    ✔ <shortstr> domain (46ms)
    ✔ <longstr> domain
    ✔ <short-uint> domain
    ✔ <long-uint> domain
    ✔ <longlong-uint> domain
    ✔ <short-int> domain
    ✔ <long-int> domain
    ✔ <longlong-int> domain
    ✔ <bit> domain
    ✔ <double> domain
    ✔ <float> domain
    ✔ <decimal> domain
    ✔ <timestamp> domain
    ✔ <table> domain (81ms)
    ✔ <field-array> domain (228ms)

  Roundtrip values
    ✔ <octet> roundtrip
    ✔ <shortstr> roundtrip
    ✔ <longstr> roundtrip
    ✔ <short-uint> roundtrip
    ✔ <long-uint> roundtrip
    ✔ <longlong-uint> roundtrip
    ✔ <short-uint> roundtrip
    ✔ <short-int> roundtrip
    ✔ <long-int> roundtrip
    ✔ <bit> roundtrip
    ✔ <decimal> roundtrip
    ✔ <timestamp> roundtrip
    ✔ <double> roundtrip
    ✔ <float> roundtrip
    ✔ <field-array> roundtrip (73ms)
    ✔ <table> roundtrip

  Roundtrip methods
    ✔ <BasicQos> roundtrip
    ✔ <BasicQosOk> roundtrip
    ✔ <BasicConsume> roundtrip
    ✔ <BasicConsumeOk> roundtrip
    ✔ <BasicCancel> roundtrip
    ✔ <BasicCancelOk> roundtrip
    ✔ <BasicPublish> roundtrip
    ✔ <BasicReturn> roundtrip
    ✔ <BasicDeliver> roundtrip
    ✔ <BasicGet> roundtrip
    ✔ <BasicGetOk> roundtrip
    ✔ <BasicGetEmpty> roundtrip
    ✔ <BasicAck> roundtrip
    ✔ <BasicReject> roundtrip
    ✔ <BasicRecoverAsync> roundtrip
    ✔ <BasicRecover> roundtrip
    ✔ <BasicRecoverOk> roundtrip
    ✔ <BasicNack> roundtrip
    ✔ <ConnectionStart> roundtrip
    ✔ <ConnectionStartOk> roundtrip
    ✔ <ConnectionSecure> roundtrip
    ✔ <ConnectionSecureOk> roundtrip
    ✔ <ConnectionTune> roundtrip
    ✔ <ConnectionTuneOk> roundtrip
    ✔ <ConnectionOpen> roundtrip
    ✔ <ConnectionOpenOk> roundtrip
    ✔ <ConnectionClose> roundtrip
    ✔ <ConnectionCloseOk> roundtrip
    ✔ <ConnectionBlocked> roundtrip
    ✔ <ConnectionUnblocked> roundtrip
    ✔ <ConnectionUpdateSecret> roundtrip
    ✔ <ConnectionUpdateSecretOk> roundtrip
    ✔ <ChannelOpen> roundtrip
    ✔ <ChannelOpenOk> roundtrip
    ✔ <ChannelFlow> roundtrip
    ✔ <ChannelFlowOk> roundtrip
    ✔ <ChannelClose> roundtrip
    ✔ <ChannelCloseOk> roundtrip
    ✔ <AccessRequest> roundtrip
    ✔ <AccessRequestOk> roundtrip
    ✔ <ExchangeDeclare> roundtrip
    ✔ <ExchangeDeclareOk> roundtrip
    ✔ <ExchangeDelete> roundtrip
    ✔ <ExchangeDeleteOk> roundtrip
    ✔ <ExchangeBind> roundtrip
    ✔ <ExchangeBindOk> roundtrip
    ✔ <ExchangeUnbind> roundtrip
    ✔ <ExchangeUnbindOk> roundtrip
    ✔ <QueueDeclare> roundtrip
    ✔ <QueueDeclareOk> roundtrip
    ✔ <QueueBind> roundtrip
    ✔ <QueueBindOk> roundtrip
    ✔ <QueuePurge> roundtrip
    ✔ <QueuePurgeOk> roundtrip
    ✔ <QueueDelete> roundtrip
    ✔ <QueueDeleteOk> roundtrip
    ✔ <QueueUnbind> roundtrip
    ✔ <QueueUnbindOk> roundtrip
    ✔ <TxSelect> roundtrip
    ✔ <TxSelectOk> roundtrip
    ✔ <TxCommit> roundtrip
    ✔ <TxCommitOk> roundtrip
    ✔ <TxRollback> roundtrip
    ✔ <TxRollbackOk> roundtrip
    ✔ <ConfirmSelect> roundtrip
    ✔ <ConfirmSelectOk> roundtrip

  Roundtrip properties
    ✔ <BasicProperties> roundtrip (62ms)

  Credentials
    ✔ no creds
    ✔ usual user:pass
    ✔ missing user
    ✔ missing password
    ✔ escaped colons

  Connect API
    ✔ Connection refused
    ✔ bad URL
    ✔ wrongly typed open option
    ✔ serverProperties (47ms)
    ✔ using custom heartbeat option (152ms)
    ✔ wrongly typed heartbeat option
    ✔ using plain credentials (53ms)
    ✔ using amqplain credentials (59ms)
    ✔ using unsupported mechanism
    ✔ with a given connection timeout (59ms)

  Errors on connect
    ✔ closes underlying connection on authentication error

  Explicit parsing
    ✔ Parse heartbeat
    ✔ Parse partitioned
    ✔ Wrong sized frame
    ✔ Unknown method frame
    ✔ > max frame

  Parsing
    ✔ Parse trace of methods (81ms)
    ✔ Parse concat'd methods (63ms)
    ✔ Parse partitioned methods (56ms)

  Content framing
    ✔ Adhere to frame max (245ms)


  261 passing (7s)
```
