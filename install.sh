#!/bin/bash

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

VERSION="master"
if [[ $1 != "" ]]; then VERSION=$1; fi

echo "The Things Network Gateway installer"
echo "Version $VERSION"

# Update the gateway installer to the correct branch (defaults to master)
echo "Updating installer files..."
git checkout -q $VERSION
OLD_HEAD=$(git rev-parse HEAD)
git pull
NEW_HEAD=$(git rev-parse HEAD)

if [[ $OLD_HEAD != $NEW_HEAD ]]; then
    echo "New installer found. Restarting process..."
    exec "./install.sh" "$VERSION"
fi

# Change hostname if needed
CURRENT_HOSTNAME=$(hostname)
NEW_HOSTNAME="ttn-gateway"

if [[ $NEW_HOSTNAME != $CURRENT_HOSTNAME ]]; then
    echo "Updating hostname to '$NEW_HOSTNAME'..."
    hostname $NEW_HOSTNAME
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/" /etc/hosts
fi

# Check dependencies
echo "Installing dependencies..."
apt-get install swig libftdi-dev python-dev

# Install LoRaWAN packet forwarder repositories
INSTALL_DIR="/opt/ttn-gateway"
if [ ! -d "$INSTALL_DIR" ]; then mkdir $INSTALL_DIR; fi
pushd $INSTALL_DIR

if [ ! -d "$INSTALL_DIR/libmpsse" ]; then
    git clone https://github.com/devttys0/libmpsse.git
fi

popd

echo "Installation completed."
