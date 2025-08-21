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
# Scenario: Helm4 SSA upgrade of Helm3 CSA installed chart succeeds, then Helm4 object update succeeds
#

${HELM4} delete --ignore-not-found test-helm4-upgrade1

# 1/ Install (Helm3)
${HELM3} install test-helm4-upgrade1 test-chart/
test "null" == $(${HELM3} get metadata test-helm4-upgrade1 -o json | jq -r .applyMethod)
test "null" == $(${HELM4} get metadata test-helm4-upgrade1 -o json | jq -r .applyMethod)
test "Update" == $(kubectl get deploy test-helm4-upgrade1-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "1" == $(kubectl get deploy test-helm4-upgrade1-test-chart -o json | jq -r '.spec.replicas')

# 2/ Upgrade with Helm4, forcing SSA
${HELM4} upgrade --server-side=true test-helm4-upgrade1 test-chart/
test "null" == $(${HELM3} get metadata test-helm4-upgrade1 -o json | jq -r .applyMethod)
test "ssa" == $(${HELM4} get metadata test-helm4-upgrade1 -o json | jq -r .applyMethod)
test "Apply" == $(kubectl get deploy test-helm4-upgrade1-test-chart -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "1" == $(kubectl get deploy test-helm4-upgrade1-test-chart -o json | jq -r '.spec.replicas')

# 3/ Upgrade with Helm4 + object update
HELM_DEBUG=1 ${HELM4} upgrade test-helm4-upgrade1 test-chart/ --set replicaCount=2
test "null" == $(${HELM3} get metadata test-helm4-upgrade1 -o json | jq -r .applyMethod)
test "ssa" == $(${HELM4} get metadata test-helm4-upgrade1 -o json | jq -r .applyMethod)
test '"Apply"' == $(kubectl get deploy test-helm4-upgrade1-test-chart -o json --show-managed-fields | jq '.metadata.managedFields[] | select(.manager == "helm") | .operation' | tr -d '\n')
test "2" == $(kubectl get deploy test-helm4-upgrade1-test-chart -o json | jq -r '.spec.replicas')

echo SUCCESS!!

