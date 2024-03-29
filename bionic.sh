#!/bin/bash

TAG=ailispaw/ubuntu-essential
VERSION=18.04
CODENAME=bionic
REVISION=20220531

set -ve

# Build the official image from https://github.com/tianon/docker-brew-ubuntu-core
wget -q https://raw.githubusercontent.com/tianon/docker-brew-ubuntu-core/dist-amd64/${CODENAME}/Dockerfile
wget -q https://partner-images.canonical.com/oci/${CODENAME}/${REVISION}/ubuntu-${CODENAME}-oci-amd64-root.tar.gz

docker build -t ubuntu:${CODENAME}-${REVISION} .

rm -f Dockerfile ubuntu-${CODENAME}-oci-amd64-root.tar.gz

# Based on https://github.com/textlab/glossa/blob/master/script/build_ubuntu_essential.sh
docker build -t ubuntu-essential-multilayer - <<EOF
FROM ubuntu:${CODENAME}-${REVISION}
# Make an exception for apt: it gets deselected, even though it probably shouldn't.
RUN export DEBIAN_FRONTEND=noninteractive && \
    dpkg --clear-selections && \
    echo "apt install" | dpkg --set-selections && \
    echo "mount install" | dpkg --set-selections && \
    apt-get --purge -y dselect-upgrade && \
    dpkg-query -Wf '\${db:Status-Abbrev}\t\${binary:Package}\n' | \
      grep '^.i' | awk -F'\t' '{print \$2 " install"}' | dpkg --set-selections && \
    rm -rf /var/cache/apt /var/lib/apt/lists /var/cache/debconf/* /var/log/*
EOF

docker run --rm -i ubuntu-essential-multilayer \
  tar zpc --exclude=/etc/hostname --exclude=/etc/resolv.conf --exclude=/etc/hosts \
    --one-file-system / | \
  docker import -c 'CMD ["/bin/bash"]' -m "${TAG}:${VERSION}-${REVISION}" - ${TAG}:${VERSION}

docker rmi ubuntu-essential-multilayer

# Set tags to release
docker tag ${TAG}:${VERSION} ${TAG}:${VERSION}-${REVISION}
docker tag ${TAG}:${VERSION} ${TAG}:latest
