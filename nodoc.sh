#!/bin/bash

set -ve

nodoc() {
  BASE_IMAGE=$1

  docker build -t ubuntu-essential-multilayer - <<EOF
FROM ${BASE_IMAGE}

# https://github.com/kubernetes/contrib/blob/master/images/ubuntu-slim/Dockerfile.build#L28-L50
RUN cd /usr/share && \
    tar zcf copyrights.tar.gz common-licenses doc/*/copyright && \
    rm -rf common-licenses doc man groff info lintian linda locale

# https://wiki.ubuntu.com/ReducingDiskFootprint
RUN echo 'path-exclude /usr/share/doc/*'            > /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-include /usr/share/doc/*/copyright' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/man/*'           >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/groff/*'         >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/info/*'          >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/lintian/*'       >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/linda/*'         >> /etc/dpkg/dpkg.cfg.d/01_nodoc
EOF

  TMP_FILE="$(mktemp -t ubuntu-essential-XXXXXX).tar.gz"

  docker run --rm -i ubuntu-essential-multilayer tar zpc --exclude=/etc/hostname \
    --exclude=/etc/resolv.conf --exclude=/etc/hosts --one-file-system / > "$TMP_FILE"
  docker rmi ubuntu-essential-multilayer

  docker import - ubuntu-essential-nocmd < "$TMP_FILE"

  docker build -t ${BASE_IMAGE}-nodoc - <<EOF
FROM ubuntu-essential-nocmd
CMD ["/bin/bash"]
EOF

  docker rmi ubuntu-essential-nocmd
  rm -f "$TMP_FILE"
}

if docker inspect ailispaw/ubuntu-essential:14.04 >/dev/null 2>&1; then
  nodoc ailispaw/ubuntu-essential:14.04
fi
if docker inspect ailispaw/ubuntu-essential:16.04 >/dev/null 2>&1; then
  nodoc ailispaw/ubuntu-essential:16.04
fi
