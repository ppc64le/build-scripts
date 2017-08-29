#!/bin/bash
$PYTHON setup.py build
$PYTHON setup.py install --single-version-externally-managed --record=record.txt
