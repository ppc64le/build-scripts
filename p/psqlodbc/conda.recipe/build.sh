#!/bin/bash
./bootstrap
./configure --build=ppc64le-linux --prefix=$PREFIX
make
make check
