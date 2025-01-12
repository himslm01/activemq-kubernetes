#!/bin/bash

set -e

# When using "Shared File System Master Slave" (their words)
# https://activemq.apache.org/components/classic/documentation/shared-file-system-master-slave
# ActiveMQ manages which node is active and which is passively waiting.
# Only the active node opens its network connections.
# This script waits for this ActiveMQ node open its network connections before labeling this pod
# as the leader, causing the Service to swing all network connections to this ActiveMQ node.

# Wait until the ActiveMQ admin API server is available in this pod
until curl -sS http://localhost:8161; do echo "sleeping"; sleep 1; done

# https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/#without-using-a-proxy

# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc

# Path to ServiceAccount token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# Reference the internal certificate authority (CA)
CACERT=${SERVICEACCOUNT}/ca.crt

# Replace the 'leader' label
curl \
 --silent \
 --show-error \
 --header "Authorization: Bearer ${TOKEN}" \
 --header "Content-Type: application/json-patch+json" \
 --cacert ${CACERT} \
 --request PATCH \
 --data '[{"op": "replace", "path": "/metadata/labels/leader", "value": "yes"}]' \
 ${APISERVER}/api/v1/namespaces/${NAMESPACE}/pods/${HOSTNAME}

echo "this pods leader label has been set to 'yes'"

# sleep for ever
while true; do sleep 10000; done
