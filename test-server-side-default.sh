#!/bin/bash

set -euv -o pipefail

test -f ${HELM4}
test "v4.0+unreleased" == $(${HELM4} version --template='{{.Version}}')

#
# Scenario: Helm defaults to SSA apply
#

${HELM4} delete --ignore-not-found test1-ssa-default

# 1/ Install w/ SSA (as default)
${HELM4} install test1-ssa-default test-chart/
test "Apply" == $(kubectl get deploy test1-ssa-default -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "ssa" == $(${HELM4} get metadata test1-ssa-default -o json | jq -r .applyMethod)
test "1" == $(kubectl get deploy test1-ssa-default -o json | jq -r '.spec.replicas')

# 2/ Upgrade defaults to SSA
${HELM4} upgrade test1-ssa-default test-chart/
test "Apply" == $(kubectl get deploy test1-ssa-default -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "ssa" == $(${HELM4} get metadata test1-ssa-default -o json | jq -r .applyMethod)
test "1" == $(kubectl get deploy test1-ssa-default -o json | jq -r '.spec.replicas')

# 3/ Upgrade defaults to SSA + object update
${HELM4} upgrade test1-ssa-default test-chart/ --set replicaCount=2
test "Apply" == $(kubectl get deploy test1-ssa-default -o json --show-managed-fields | jq -r '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "ssa" == $(${HELM4} get metadata test1-ssa-default -o json | jq -r .applyMethod)
test "2" == $(kubectl get deploy test1-ssa-default -o json | jq -r '.spec.replicas')

echo SUCCESS!!

