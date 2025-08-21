#!/bin/bash

set -euv -o pipefail

test -f ${HELM4}
if [[ $(${HELM4} version --template='{{.Version}}') =~ ^"v4\." ]]; then
    exit 1
fi

test -f ${HELM3}
if [[ $(${HELM3} version --template='{{.Version}}') =~ ^"v3\." ]]; then
    exit 1
fi

#
# Scenario: Helm3 upgrade of Helm4 SSA installed chart succeeds, and then able to (immediately) upgrade with Helm4 SSA
#

${HELM4} delete --ignore-not-found test-helm3-downgrade2

# 1/ Install w/ SSA
${HELM4} install --server-side=true test-helm3-downgrade2 test-chart/
test "null" == $(${HELM3} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "ssa" == $(${HELM4} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm3-downgrade2-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')

# 2/ Upgrade with Helm3 (will update with CSA; but object remains unchanged/untouched)
${HELM3} upgrade test-helm3-downgrade2 test-chart/
test "null" == $(${HELM3} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "null" == $(${HELM4} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm3-downgrade2-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')

# 3/ Upgrade with Helm4 with explicit SSA
${HELM4} upgrade --server-side=true test-helm3-downgrade2 test-chart/ --set replicaCount=2
test "null" == $(${HELM3} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "ssa" == $(${HELM4} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm3-downgrade2-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "2" == $(kubectl get deploy test-helm3-downgrade2-test-chart -o json | jq -r '.spec.replicas')

# 4/ Upgrade with Helm4 (will retain SSA)
${HELM4} upgrade test-helm3-downgrade2 test-chart/ --set replicaCount=3
test "null" == $(${HELM3} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "ssa" == $(${HELM4} get metadata test-helm3-downgrade2 -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm3-downgrade2-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "3" == $(kubectl get deploy test-helm3-downgrade2-test-chart -o json | jq -r '.spec.replicas')

echo SUCCESS!!

