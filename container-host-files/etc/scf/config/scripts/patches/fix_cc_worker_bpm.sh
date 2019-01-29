#! /usr/bin/env bash

# This is a temporary patch needed to make kube-dns work for BPM-managed jobs.
# This will go away with the transition to the cf-operator, which will not require BPM anymore.

set -e

PATCH_DIR=/var/vcap/jobs-src/cloud_controller_worker/templates
SENTINEL="${PATCH_DIR}/${0##*/}.sentinel"

if [ -f "${SENTINEL}" ]; then
  exit 0
fi

patch -d "$PATCH_DIR" --force -p0 <<'PATCH'
--- bpm.yml.erb	2019-01-30 11:11:35.434797840 -0800
+++ bpm.yml.erb	2019-01-30 11:41:33.924756933 -0800
@@ -18,6 +17,15 @@
       "NRCONFIG" => "/var/vcap/jobs/cloud_controller_worker/config/newrelic.yml",
       "INDEX" => index
     }
+    "unsafe" => {
+      "unrestricted_volumes" => [
+        { "path" => "/etc/hostname" },
+        { "path" => "/etc/hosts" },
+        { "path" => "/etc/resolv.conf" },
+        { "path" => "/etc/ssl" },
+        { "path" => "/var/lib/ca-certificates" }
+      ]
+    }
   }
 
   if_p('nfs_server.address') do
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
