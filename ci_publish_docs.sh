#!/bin/bash

# should be invoked from drone ci

set -e
set -u
set -o pipefail

test -d _docs_dist/ # ensure site exists

echo "Creating new deployment..."
WEBPLOY_DEPLOYMENT_ID=$(curl -m 30 --fail -X POST -u "${WEBPLOY_USER}:${WEBPLOY_PASSWORD}" "${WEBPLOY_URL}/sites/${WEBPLOY_SITE}/deployments" -d '{"meta":"'"${DRONE_BUILD_NUMBER}"'"}' | jq -r .id)
echo "Deployment created! Deployment id: ${WEBPLOY_DEPLOYMENT_ID}"

echo "Uploading contents..."
tar -c -C _docs_dist . | curl --fail -X POST -u "${WEBPLOY_USER}:${WEBPLOY_PASSWORD}" --data-binary @- "${WEBPLOY_URL}/sites/${WEBPLOY_SITE}/deployments/${WEBPLOY_DEPLOYMENT_ID}/uploadTar"

echo "Upload completed, finishing deployment..."
curl -m 30 --fail -X POST -u "${WEBPLOY_USER}:${WEBPLOY_PASSWORD}" "${WEBPLOY_URL}/sites/${WEBPLOY_SITE}/deployments/${WEBPLOY_DEPLOYMENT_ID}/finish" | jq .
