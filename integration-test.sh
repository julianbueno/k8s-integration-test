#!/usr/bin/env ash
# shellcheck shell=dash
# Run integration test for configured components
# Usage: `integration-test.sh`

set -o errexit
set -o nounset
set -o pipefail

echo "[INFO] Configuring kubernetes credentials"
echo "${KUBECONFIG_INTEGRATION_TEST}" | base64 -d > /tmp/KUBECONFIG
export KUBECONFIG=/tmp/KUBECONFIG
echo "[DEBUG] KUBECONFIG"
kubectl config view

# insert mocked variables on values.yaml 
envsubst < kuard.tpl > kuard.yaml

# test components
go test -v -count=1 -timeout 60m ./integration_test.go