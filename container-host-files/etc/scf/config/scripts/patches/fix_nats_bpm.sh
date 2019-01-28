#! /usr/bin/env bash

# This is a temporary patch needed to make kube-dns work for BPM-managed jobs.
# This will go away with the transition to the cf-operator, which will not require BPM anymore.

set -e

PATCH_DIR=/var/vcap/jobs-src/nats/templates
SENTINEL="${PATCH_DIR}/${0##*/}.sentinel"

if [ -f "${SENTINEL}" ]; then
  exit 0
fi

patch -d "$PATCH_DIR" --force -p0 <<'PATCH'
--- bpm.erb.yml	2019-01-30 14:43:03.998357476 -0800
+++ bpm.erb.yml	2019-01-30 14:43:51.086385477 -0800
@@ -7,3 +7,10 @@
   args:
   - -c
   - "/var/vcap/jobs/nats/config/nats.conf"
+  unsafe:
+    unrestricted_volumes:
+    - path: /etc/hostname
+    - path: /etc/hosts
+    - path: /etc/resolv.conf
+    - path: /etc/ssl
+    - path: /var/lib/ca-certificates
PATCH

# Notes on "unsafe.unrestricted_volumes":
#
# - The first three mounts are required to make DNS work in the nested
#   container created by BPM for the job to run in.
#
# - The remainder are required to give the job access to the system
#   root certificates so that it actually can verify the certs given
#   to it by its partners (like the router-registrar).

touch "${SENTINEL}"

exit 0
