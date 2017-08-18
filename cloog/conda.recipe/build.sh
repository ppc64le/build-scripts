#!/bin/bash
./get_submodules.sh
./autogen.sh
./configure
make
make check
