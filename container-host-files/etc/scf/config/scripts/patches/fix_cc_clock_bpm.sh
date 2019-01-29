#! /usr/bin/env bash

# This is a temporary patch needed to make kube-dns work for BPM-managed jobs.
# This will go away with the transition to the cf-operator, which will not require BPM anymore.

set -e

PATCH_DIR=/var/vcap/jobs-src/cloud_controller_clock/templates
SENTINEL="${PATCH_DIR}/${0##*/}.sentinel"

if [ -f "${SENTINEL}" ]; then
  exit 0
fi

patch -d "$PATCH_DIR" --force -p0 <<'PATCH'
--- bpm.yml.erb	2018-11-30 11:20:42.871780634 -0800
+++ bpm.yml.erb	2019-01-30 11:39:00.876578045 -0800
@@ -2,8 +2,6 @@
 processes:
 - name: cloud_controller_clock
   executable: /var/vcap/jobs/cloud_controller_clock/bin/cloud_controller_clock
-  limits:
-    memory: <%= p("cc.thresholds.api.restart_if_above_mb") %>M
   env:
     BUNDLE_GEMFILE: /var/vcap/packages/cloud_controller_ng/cloud_controller_ng/Gemfile
     CLOUD_CONTROLLER_NG_CONFIG: /var/vcap/jobs/cloud_controller_clock/config/cloud_controller_ng.yml
@@ -11,3 +9,10 @@
     LANG: en_US.UTF-8
     LIBRARY_PATH: /var/vcap/packages/libpq/lib
     NEWRELIC_ENABLE: false
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
