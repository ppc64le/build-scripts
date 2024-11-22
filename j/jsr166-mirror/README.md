
       Test cases failure details for version master
  -----
 ```[javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/DoubleAdder.java:171: warning: no @return
    [javac]     public int intValue() {
    [javac]                ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/DoubleAdder.java:179: warning: no @return
    [javac]     public float floatValue() {
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/LongAccumulator.java:174: warning: no @return
    [javac]     public int intValue() {
    [javac]                ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/LongAccumulator.java:182: warning: no @return
    [javac]     public float floatValue() {
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/LongAccumulator.java:190: warning: no @return
    [javac]     public double doubleValue() {
    [javac]                   ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/LongAdder.java:164: warning: no @return
    [javac]     public int intValue() {
    [javac]                ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/LongAdder.java:172: warning: no @return
    [javac]     public float floatValue() {
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/LongAdder.java:180: warning: no @return
    [javac]     public double doubleValue() {
    [javac]                   ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/Striped64.java:353: error: Striped64 is not public in java.util.concurrent.atomic; cannot be accessed from outside package
    [javac]                 (Striped64.class.getDeclaredField("base"));
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/atomic/Striped64.java:355: error: Striped64 is not public in java.util.concurrent.atomic; cannot be accessed from outside package
    [javac]                 (Striped64.class.getDeclaredField("cellsBusy"));
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1726: error: reference not found
    [javac]          * Implements {@link AbstractQueuedLongSynchronizer#hasWaiters(ConditionObject)}.
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1745: error: reference not found
    [javac]          * Implements {@link AbstractQueuedLongSynchronizer#getWaitQueueLength(ConditionObject)}.
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1765: error: reference not found
    [javac]          * Implements {@link AbstractQueuedLongSynchronizer#getWaitingThreads(ConditionObject)}.
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:121: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node oldTail = tail;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:141: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node node = new Node(mode);
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:141: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node node = new Node(mode);
    [javac]                         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:145: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node oldTail = tail;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:192: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node s = node.next;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:195: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             for (Node p = tail; p != node && p != null; p = p.prev)
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:221: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node h = head;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:224: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 if (ws == Node.SIGNAL) {
    [javac]                           ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:225: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                     if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
    [javac]                                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:230: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                          !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
    [javac]                                                         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:247: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node h = head; // Record old head for check below
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:267: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node s = node.next;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:288: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node pred = node.prev;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:295: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node predNext = pred.next;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:300: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         node.waitStatus = Node.CANCELLED;
    [javac]                           ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:310: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 ((ws = pred.waitStatus) == Node.SIGNAL ||
    [javac]                                            ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:311: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                  (ws <= 0 && compareAndSetWaitStatus(pred, ws, Node.SIGNAL))) &&
    [javac]                                                                ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:313: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 Node next = node.next;
    [javac]                 ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:335: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         if (ws == Node.SIGNAL)
    [javac]                   ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:356: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
    [javac]                                               ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:399: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 final Node p = node.predecessor();
    [javac]                       ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:421: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.EXCLUSIVE);
    [javac]               ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:421: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.EXCLUSIVE);
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:424: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 final Node p = node.predecessor();
    [javac]                       ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:452: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.EXCLUSIVE);
    [javac]               ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:452: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.EXCLUSIVE);
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:455: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 final Node p = node.predecessor();
    [javac]                       ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:483: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.SHARED);
    [javac]               ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:483: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.SHARED);
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:487: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 final Node p = node.predecessor();
    [javac]                       ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:514: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.SHARED);
    [javac]               ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:514: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.SHARED);
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:517: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 final Node p = node.predecessor();
    [javac]                       ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:548: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.SHARED);
    [javac]               ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:548: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         final Node node = addWaiter(Node.SHARED);
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:551: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 final Node p = node.predecessor();
    [javac]                       ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:729: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:792: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node h = head;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:936: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node h, s;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:952: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node t = tail;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:976: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         for (Node p = tail; p != null; p = p.prev)
    [javac]              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:992: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node h, s;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1046: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node t = tail; // Read fields in reverse initialization order
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1047: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node h = head;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1048: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node s;
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1067: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         for (Node p = tail; p != null; p = p.prev) {
    [javac]              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1087: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         for (Node p = tail; p != null; p = p.prev) {
    [javac]              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1105: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         for (Node p = tail; p != null; p = p.prev) {
    [javac]              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1125: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         for (Node p = tail; p != null; p = p.prev) {
    [javac]              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1161: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         if (node.waitStatus == Node.CONDITION || node.prev == null)
    [javac]                                ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1185: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         for (Node p = tail;;) {
    [javac]              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1205: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         if (!compareAndSetWaitStatus(node, Node.CONDITION, 0))
    [javac]                                            ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1214: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         Node p = enq(node);
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1216: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         if (ws > 0 || !compareAndSetWaitStatus(p, ws, Node.SIGNAL))
    [javac]                                                       ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1229: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         if (compareAndSetWaitStatus(node, Node.CONDITION, 0)) {
    [javac]                                           ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1257: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             node.waitStatus = Node.CANCELLED;
    [javac]                               ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1273: error: incompatible types: java.util.concurrent.locks.AbstractQueuedLongSynchronizer cannot be converted to java.util.concurrent.locks.AbstractQueuedLongSynchronizer
    [javac]         return condition.isOwnedBy(this);
    [javac]                                    ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1378: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node t = lastWaiter;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1380: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             if (t != null && t.waitStatus != Node.CONDITION) {
    [javac]                                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1385: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node node = new Node();
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1385: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node node = new Node();
    [javac]                             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1386: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             U.putInt(node, WAITSTATUS, Node.CONDITION);
    [javac]                                        ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1419: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 Node next = first.nextWaiter;
    [javac]                 ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1441: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node t = firstWaiter;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1442: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node trail = null;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1444: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 Node next = t.nextWaiter;
    [javac]                 ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1445: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 if (t.waitStatus != Node.CONDITION) {
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1473: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node first = firstWaiter;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1488: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node first = firstWaiter;
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1505: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node node = addConditionWaiter();
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1568: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node node = addConditionWaiter();
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1603: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node node = addConditionWaiter();
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1646: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node node = addConditionWaiter();
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1688: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             Node node = addConditionWaiter();
    [javac]             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1721: error: not an enclosing class: AbstractQueuedLongSynchronizer
    [javac]             return sync == AbstractQueuedLongSynchronizer.this;
    [javac]                                                          ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1735: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             for (Node w = firstWaiter; w != null; w = w.nextWaiter) {
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1736: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 if (w.waitStatus == Node.CONDITION)
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1755: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             for (Node w = firstWaiter; w != null; w = w.nextWaiter) {
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1756: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 if (w.waitStatus == Node.CONDITION)
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1775: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]             for (Node w = firstWaiter; w != null; w = w.nextWaiter) {
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1776: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 if (w.waitStatus == Node.CONDITION) {
    [javac]                                     ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1814: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 (Node.class.getDeclaredField("waitStatus"));
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1816: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 (Node.class.getDeclaredField("prev"));
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1818: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 (Node.class.getDeclaredField("next"));
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1820: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]                 (Node.class.getDeclaredField("thread"));
    [javac]                  ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedLongSynchronizer.java:1834: error: Node is not public in AbstractQueuedSynchronizer; cannot be accessed from outside package
    [javac]         if (U.compareAndSwapObject(this, HEAD, null, new Node()))
    [javac]                                                          ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedSynchronizer.java:2152: error: reference not found
    [javac]          * Implements {@link AbstractQueuedSynchronizer#hasWaiters(ConditionObject)}.
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedSynchronizer.java:2171: error: reference not found
    [javac]          * Implements {@link AbstractQueuedSynchronizer#getWaitQueueLength(ConditionObject)}.
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedSynchronizer.java:2191: error: reference not found
    [javac]          * Implements {@link AbstractQueuedSynchronizer#getWaitingThreads(ConditionObject)}.
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedSynchronizer.java:1701: error: incompatible types: java.util.concurrent.locks.AbstractQueuedSynchronizer cannot be converted to java.util.concurrent.locks.AbstractQueuedSynchronizer
    [javac]         return condition.isOwnedBy(this);
    [javac]                                    ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/AbstractQueuedSynchronizer.java:2147: error: not an enclosing class: AbstractQueuedSynchronizer
    [javac]             return sync == AbstractQueuedSynchronizer.this;
    [javac]                                                      ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/ReentrantReadWriteLock.java:213: error: incompatible types: java.util.concurrent.locks.ReentrantReadWriteLock cannot be converted to java.util.concurrent.locks.ReentrantReadWriteLock
    [javac]         readerLock = new ReadLock(this);
    [javac]                                   ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/ReentrantReadWriteLock.java:214: error: incompatible types: java.util.concurrent.locks.ReentrantReadWriteLock cannot be converted to java.util.concurrent.locks.ReentrantReadWriteLock
    [javac]         writerLock = new WriteLock(this);
    [javac]                                    ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/ReentrantReadWriteLock.java:654: error: cannot find symbol
    [javac]             return apparentlyFirstQueuedIsExclusive();
    [javac]                    ^
    [javac]   symbol:   method apparentlyFirstQueuedIsExclusive()
    [javac]   location: class NonfairSync
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/ReentrantReadWriteLock.java:685: error: sync is not public in ReentrantReadWriteLock; cannot be accessed from outside package
    [javac]             sync = lock.sync;
    [javac]                        ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/ReentrantReadWriteLock.java:899: error: sync is not public in ReentrantReadWriteLock; cannot be accessed from outside package
    [javac]             sync = lock.sync;
    [javac]                        ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/StampedLock.java:941: error: nextSecondarySeed() is not public in LockSupport; cannot be accessed from outside package
    [javac]         else if ((LockSupport.nextSecondarySeed() &
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/StampedLock.java:968: error: nextSecondarySeed() is not public in LockSupport; cannot be accessed from outside package
    [javac]         else if ((LockSupport.nextSecondarySeed() &
    [javac]                              ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/StampedLock.java:1015: error: nextSecondarySeed() is not public in LockSupport; cannot be accessed from outside package
    [javac]                 if (LockSupport.nextSecondarySeed() >= 0)
    [javac]                                ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/StampedLock.java:1053: error: nextSecondarySeed() is not public in LockSupport; cannot be accessed from outside package
    [javac]                     else if (LockSupport.nextSecondarySeed() >= 0 &&
    [javac]                                         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/StampedLock.java:1128: error: nextSecondarySeed() is not public in LockSupport; cannot be accessed from outside package
    [javac]                             if (LockSupport.nextSecondarySeed() >= 0)
    [javac]                                            ^
    [javac] /opt/jsr166-mirror/src/main/java/util/concurrent/locks/StampedLock.java:1238: error: nextSecondarySeed() is not public in LockSupport; cannot be accessed from outside package
    [javac]                              LockSupport.nextSecondarySeed() >= 0 && --k <= 0)
    [javac]                                         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/AbstractQueue.java:88: error: cannot find symbol
    [javac]             throw new NoSuchElementException();
    [javac]                       ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class AbstractQueue<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class AbstractQueue
    [javac] /opt/jsr166-mirror/src/main/java/util/AbstractQueue.java:107: error: cannot find symbol
    [javac]             throw new NoSuchElementException();
    [javac]                       ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class AbstractQueue<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class AbstractQueue
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:58: error: ArrayDeque is not abstract and does not override abstract method addAll(Collection<? extends E>) in Deque
    [javac] public class ArrayDeque<E> extends AbstractCollection<E>
    [javac]        ^
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:235: error: cannot find symbol
    [javac]             throw new NoSuchElementException();
    [javac]                       ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:245: error: cannot find symbol
    [javac]             throw new NoSuchElementException();
    [javac]                       ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:281: error: cannot find symbol
    [javac]             throw new NoSuchElementException();
    [javac]                       ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:292: error: cannot find symbol
    [javac]             throw new NoSuchElementException();
    [javac]                       ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:502: error: cannot find symbol
    [javac]             throw new ConcurrentModificationException();
    [javac]                       ^
    [javac]   symbol:   class ConcurrentModificationException
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:590: error: cannot find symbol
    [javac]                 throw new NoSuchElementException();
    [javac]                           ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class ArrayDeque<E>.DeqIterator
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:596: error: cannot find symbol
    [javac]                 throw new ConcurrentModificationException();
    [javac]                           ^
    [javac]   symbol:   class ConcurrentModificationException
    [javac]   location: class ArrayDeque<E>.DeqIterator
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:629: error: cannot find symbol
    [javac]                 throw new NoSuchElementException();
    [javac]                           ^
    [javac]   symbol:   class NoSuchElementException
    [javac]   location: class ArrayDeque<E>.DescendingIterator
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:634: error: cannot find symbol
    [javac]                 throw new ConcurrentModificationException();
    [javac]                           ^
    [javac]   symbol:   class ConcurrentModificationException
    [javac]   location: class ArrayDeque<E>.DescendingIterator
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:723: error: cannot find symbol
    [javac]         Object[] a = Arrays.copyOfRange(elements, head, end);
    [javac]                      ^
    [javac]   symbol:   variable Arrays
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:774: error: cannot find symbol
    [javac]             a = (T[]) Arrays.copyOfRange(elements, head, head + size,
    [javac]                       ^
    [javac]   symbol:   variable Arrays
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:774: warning: [cast] redundant cast to T[]
    [javac]             a = (T[]) Arrays.copyOfRange(elements, head, head + size,
    [javac]                 ^
    [javac]   where T is a type-variable:
    [javac]     T extends Object declared in method <T>toArray(T[])
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:796: error: cannot find symbol
    [javac]             ArrayDeque<E> result = (ArrayDeque<E>) super.clone();
    [javac]                                                    ^
    [javac]   symbol:   variable super
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:796: warning: [cast] redundant cast to java.util.ArrayDeque<E>
    [javac]             ArrayDeque<E> result = (ArrayDeque<E>) super.clone();
    [javac]                                    ^
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class java.util.ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:797: error: elements is not public in ArrayDeque; cannot be accessed from outside package
    [javac]             result.elements = Arrays.copyOf(elements, elements.length);
    [javac]                   ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:797: error: cannot find symbol
    [javac]             result.elements = Arrays.copyOf(elements, elements.length);
    [javac]                               ^
    [javac]   symbol:   variable Arrays
    [javac]   location: class ArrayDeque<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:851: error: incompatible types: java.util.ArrayDeque<E> cannot be converted to java.util.ArrayDeque<E>
    [javac]         return new DeqSpliterator<E>(this, -1, -1);
    [javac]                                      ^
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class java.util.ArrayDeque
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:869: error: tail is not public in ArrayDeque; cannot be accessed from outside package
    [javac]                 t = fence = deq.tail;
    [javac]                                ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:870: error: head is not public in ArrayDeque; cannot be accessed from outside package
    [javac]                 index = deq.head;
    [javac]                            ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:876: error: elements is not public in ArrayDeque; cannot be accessed from outside package
    [javac]             int t = getFence(), h = index, n = deq.elements.length;
    [javac]                                                   ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:889: error: elements is not public in ArrayDeque; cannot be accessed from outside package
    [javac]             Object[] a = deq.elements;
    [javac]                             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:896: error: cannot find symbol
    [javac]                     throw new ConcurrentModificationException();
    [javac]                               ^
    [javac]   symbol:   class ConcurrentModificationException
    [javac]   location: class DeqSpliterator<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class DeqSpliterator
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:904: error: elements is not public in ArrayDeque; cannot be accessed from outside package
    [javac]             Object[] a = deq.elements;
    [javac]                             ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:910: error: cannot find symbol
    [javac]                     throw new ConcurrentModificationException();
    [javac]                               ^
    [javac]   symbol:   class ConcurrentModificationException
    [javac]   location: class DeqSpliterator<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class DeqSpliterator
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:920: error: elements is not public in ArrayDeque; cannot be accessed from outside package
    [javac]                 n += deq.elements.length;
    [javac]                         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:924: error: method does not override or implement a method from a supertype
    [javac]         @Override
    [javac]         ^
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:926: error: cannot find symbol
    [javac]             return Spliterator.ORDERED | Spliterator.SIZED |
    [javac]                    ^
    [javac]   symbol:   variable Spliterator
    [javac]   location: class DeqSpliterator<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class DeqSpliterator
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:926: error: cannot find symbol
    [javac]             return Spliterator.ORDERED | Spliterator.SIZED |
    [javac]                                          ^
    [javac]   symbol:   variable Spliterator
    [javac]   location: class DeqSpliterator<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class DeqSpliterator
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:927: error: cannot find symbol
    [javac]                 Spliterator.NONNULL | Spliterator.SUBSIZED;
    [javac]                 ^
    [javac]   symbol:   variable Spliterator
    [javac]   location: class DeqSpliterator<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class DeqSpliterator
    [javac] /opt/jsr166-mirror/src/main/java/util/ArrayDeque.java:927: error: cannot find symbol
    [javac]                 Spliterator.NONNULL | Spliterator.SUBSIZED;
    [javac]                                       ^
    [javac]   symbol:   variable Spliterator
    [javac]   location: class DeqSpliterator<E>
    [javac]   where E is a type-variable:
    [javac]     E extends Object declared in class DeqSpliterator
    [javac] Note: Some messages have been simplified; recompile with -Xdiags:verbose to get full output
    [javac] 932 errors
   [javac] 17 warnings```
