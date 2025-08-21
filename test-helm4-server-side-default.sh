#!/bin/bash

set -euv -o pipefail

test -f ${HELM4}
if [[ $(${HELM4} version --template='{{.Version}}') =~ ^"v4\." ]]; then
    exit 1
fi

#
# Scenario: Helm defaults to SSA apply
#

${HELM4} delete --ignore-not-found test-helm4-server-side-default

# 1/ Install w/ SSA (as default)
${HELM4} install test-helm4-server-side-default test-chart/
test "ssa" == $(${HELM4} get metadata test-helm4-server-side-default -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm4-server-side-default-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "1" == $(kubectl get deploy test-helm4-server-side-default-test-chart -o json | jq -r '.spec.replicas')

# 2/ Upgrade defaults to SSA
${HELM4} upgrade test-helm4-server-side-default test-chart/
test "ssa" == $(${HELM4} get metadata test-helm4-server-side-default -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm4-server-side-default-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "1" == $(kubectl get deploy test-helm4-server-side-default-test-chart -o json | jq -r '.spec.replicas')

# 3/ Upgrade defaults to SSA + object update
${HELM4} upgrade test-helm4-server-side-default test-chart/ --set replicaCount=2
test "ssa" == $(${HELM4} get metadata test-helm4-server-side-default -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm4-server-side-default-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "2" == $(kubectl get deploy test-helm4-server-side-default-test-chart -o json | jq -r '.spec.replicas')

echo SUCCESS!!

