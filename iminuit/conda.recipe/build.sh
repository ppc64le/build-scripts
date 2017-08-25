#!/bin/bash
$PYTHON setup.py build_ext -i
$PYTHON setup.py install --single-version-externally-managed --record=record.txt
