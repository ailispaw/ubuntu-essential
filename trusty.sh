#!/bin/bash

# based on https://github.com/textlab/glossa/blob/master/script/build_ubuntu_essential.sh

TAG=ailispaw/ubuntu-essential
VERSION=14.04
CODENAME=trusty
REVISION=20160819

set -ve

wget -q https://raw.githubusercontent.com/tianon/docker-brew-ubuntu-core/dist/${CODENAME}/Dockerfile
wget -q https://partner-images.canonical.com/core/${CODENAME}/${REVISION}/ubuntu-${CODENAME}-core-cloudimg-amd64-root.tar.gz

docker build -t ubuntu:${CODENAME}-${REVISION} .

rm -f Dockerfile ubuntu-${CODENAME}-core-cloudimg-amd64-root.tar.gz

docker build -t ubuntu-essential-multilayer - <<EOF
FROM ubuntu:${CODENAME}-${REVISION}
# Make an exception for apt: it gets deselected, even though it probably shouldn't.
RUN dpkg --clear-selections && echo "apt install" | dpkg --set-selections && \
    SUDO_FORCE_REMOVE=yes DEBIAN_FRONTEND=noninteractive apt-get --purge -y dselect-upgrade && \
    dpkg-query -Wf '\${db:Status-Abbrev}\t\${binary:Package}\n' | \
      grep '^.i' | awk -F'\t' '{print \$2 " install"}' | dpkg --set-selections && \
    rm -r /var/cache/apt /var/lib/apt/lists
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

docker tag -f ${TAG}:${VERSION} ${TAG}:${VERSION}-${REVISION}
