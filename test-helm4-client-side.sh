#!/bin/bash

set -euv -o pipefail

test -f ${HELM4}
if [[ $(${HELM4} version --template='{{.Version}}') =~ ^"v4\." ]]; then
    exit 1
fi

#
# Scenario: Helm4 CSA apply succeeds for install and upgrade
#

${HELM4} delete --ignore-not-found test-helm4-client-side

# 1/ Install w/ CSA
${HELM4} install --server-side=false test-helm4-client-side test-chart/
test "csa" == $(${HELM4} get metadata test-helm4-client-side -o json | jq -r .applyMethod)
test "Update" == $(kubectl get deploy test-helm4-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "1" == $(kubectl get deploy test-helm4-client-side-test-chart -o json | jq -r '.spec.replicas')

# 2/ Upgrade defaults to CSA
${HELM4} upgrade test-helm4-client-side test-chart/
test "csa" == $(${HELM4} get metadata test-helm4-client-side -o json | jq -r .applyMethod)
test "Update" == $(kubectl get deploy test-helm4-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "1" == $(kubectl get deploy test-helm4-client-side-test-chart -o json | jq -r '.spec.replicas')

# 3/ Upgrade defaults to CSA (explicit auto)
${HELM4} upgrade --server-side=auto test-helm4-client-side test-chart/
test "csa" == $(${HELM4} get metadata test-helm4-client-side -o json | jq -r .applyMethod)
test "Update" == $(kubectl get deploy test-helm4-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "1" == $(kubectl get deploy test-helm4-client-side-test-chart -o json | jq -r '.spec.replicas')

# 2/ Upgrade defaults to CSA + object update
${HELM4} upgrade test-helm4-client-side test-chart/ --set replicaCount=2
test "csa" == $(${HELM4} get metadata test-helm4-client-side -o json | jq -r .applyMethod)
test "Update" == $(kubectl get deploy test-helm4-client-side-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "2" == $(kubectl get deploy test-helm4-client-side-test-chart -o json | jq -r '.spec.replicas')

echo SUCCESS!!

