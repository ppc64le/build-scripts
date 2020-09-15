#!/bin/bash
modprobe ip_vs
keepalived -P -C -d -D -S 7 -f /etc/keepalived/keepalived.conf --dont-fork --log-console
