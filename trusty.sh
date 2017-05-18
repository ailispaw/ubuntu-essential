#!/bin/bash

TAG=ailispaw/ubuntu-essential
VERSION=14.04
CODENAME=trusty
REVISION=20170518

set -ve

# Build the official image from https://github.com/tianon/docker-brew-ubuntu-core
wget -q https://raw.githubusercontent.com/tianon/docker-brew-ubuntu-core/dist/${CODENAME}/Dockerfile
wget -q https://partner-images.canonical.com/core/${CODENAME}/${REVISION}/ubuntu-${CODENAME}-core-cloudimg-amd64-root.tar.gz

docker build -t ubuntu:${CODENAME}-${REVISION} .

rm -f Dockerfile ubuntu-${CODENAME}-core-cloudimg-amd64-root.tar.gz

# Based on https://github.com/textlab/glossa/blob/master/script/build_ubuntu_essential.sh
docker build -t ubuntu-essential-multilayer - <<EOF
FROM ubuntu:${CODENAME}-${REVISION}
# Make an exception for apt: it gets deselected, even though it probably shouldn't.
RUN dpkg --clear-selections && echo "apt install" | dpkg --set-selections && \
    SUDO_FORCE_REMOVE=yes DEBIAN_FRONTEND=noninteractive apt-get --purge -y dselect-upgrade && \
    dpkg-query -Wf '\${db:Status-Abbrev}\t\${binary:Package}\n' | \
      grep '^.i' | awk -F'\t' '{print \$2 " install"}' | dpkg --set-selections && \
    rm -rf /var/cache/apt /var/lib/apt/lists /var/cache/debconf/* /var/log/*
EOF

TMP_FILE="$(mktemp -t ubuntu-essential-XXXXXX).tar.gz"

docker run --rm -i ubuntu-essential-multilayer tar zpc --exclude=/etc/hostname \
  --exclude=/etc/resolv.conf --exclude=/etc/hosts --one-file-system / > "$TMP_FILE"
docker rmi ubuntu-essential-multilayer

docker import - ubuntu-essential-nocmd < "$TMP_FILE"

docker build -t ${TAG}:${VERSION} - <<EOF
FROM ubuntu-essential-nocmd
CMD ["/bin/bash"]
EOF

docker rmi ubuntu-essential-nocmd
rm -f "$TMP_FILE"

# Set tags to release
docker tag ${TAG}:${VERSION} ${TAG}:${VERSION}-${REVISION}
