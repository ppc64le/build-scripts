#!/bin/bash
$PYTHON setup.py build_ext -D HAVE_FREETDS -U WANT_BULKCOPY
$PYTHON setup.py install --single-version-externally-managed --record=record.txt
