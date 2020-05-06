#!/bin/bash
# Build a salt container image with gitfs
# This work is based on code from https://github.com/saltstack/saltdocker

BASEIMAGE='python:3.7-alpine'
SALT_VERSION='3000.2'

ctr=$(buildah from "$BASEIMAGE")

buildah run "$ctr" -- apk add --no-cache gcc g++ autoconf make libffi-dev openssl-dev dumb-init git libgit2 libgit2-dev

buildah run "$ctr" -- addgroup -g 450 -S salt
buildah run "$ctr" -- adduser -s /bin/sh -SD -G salt salt
buildah run "$ctr" -- mkdir -p /etc/pki /etc/salt/pki /etc/salt/minion.d/ /etc/salt/master.d /etc/salt/proxy.d /var/cache/salt /var/log/salt /var/run/salt

dirs='/etc/pki /etc/salt /var/cache/salt /var/log/salt /var/run/salt'
buildah run "$ctr" -- chmod -R 2775 $dirs
buildah run "$ctr" -- chgrp -R salt $dirs

buildah run "$ctr" -- pip3 install --no-cache-dir "salt==$SALT_VERSION" pycryptodomex CherryPy pyOpenSSL 'pygit2<1.1'

buildah run "$ctr" --  su - salt -c 'salt-run salt.cmd tls.create_self_signed_cert'
buildah add "$ctr" saltinit.py /usr/local/bin/saltinit

buildah config --volume /etc/salt/pki \
 --port 4505 --port 4506 --port 8000 \
 --entrypoint '["/usr/bin/dumb-init"]' \
 --cmd '/usr/local/bin/saltinit' \
 "$ctr"

buildah commit "$ctr" "salt:$SALT_VERSION"
