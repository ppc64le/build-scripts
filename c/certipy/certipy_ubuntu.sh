#!/bin/bash

# Exit on error
set -e

# Create directory and clone repository
git clone https://github.com/LLNL/certipy.git
cd certipy/

# Upgrade pip to the latest version
pip install --upgrade pip

# Install dependencies build tools
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
pip install wheel
pip install setuptools wheel pypandoc requests flask
pip install .

#Give required permission needed
sudo chown -R ubuntu:ubuntu /tmp/
sudo chmod -R g+rwx /tmp

#Install pytest and run tests
pip install pytest
pytest -v

# Build and install the package
python setup.py build
sudo python setup.py install

#cd dist/
ls -ltrh dist | grep "certipy-0.1.3"

echo "Setup and testing completed successfully!"

