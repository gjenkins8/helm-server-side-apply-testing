#!/bin/bash

set -euv -o pipefail

test -f ${HELM4}
test "v4.0+unreleased" == $(${HELM4} version --template='{{.Version}}')

#
# Scenario: Helm4 CSA apply succeeds for install and upgrade
#

${HELM4} delete --ignore-not-found test-client-side

# 1/ Install w/ CSA
${HELM4} install --server-side=false test-client-side test-chart/
test "Update" == $(kubectl get deploy test-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "csa" == $(${HELM4} get metadata test-client-side -o json | jq -r .applyMethod)

# 2/ Upgrade defaults to CSA
${HELM4} upgrade test-client-side test-chart/
test "Update" == $(kubectl get deploy test-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "csa" == $(${HELM4} get metadata test-client-side -o json | jq -r .applyMethod)

# 3/ Upgrade defaults to CSA (explicit auto)
${HELM4} upgrade --server-side=auto test-client-side test-chart/
test "Update" == $(kubectl get deploy test-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "csa" == $(${HELM4} get metadata test-client-side -o json | jq -r .applyMethod)

# 2/ Upgrade defaults to CSA + object update
${HELM4} upgrade test-client-side test-chart/ --set replicaCount=2
test "Update" == $(kubectl get deploy test-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "csa" == $(${HELM4} get metadata test-client-side -o json | jq -r .applyMethod)
test "2" == $(kubectl get deploy test-client-side-test-chart -o json | jq -r '.spec.replicas')

echo SUCCESS!!

