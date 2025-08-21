#!/bin/bash

set -euv -o pipefail

helm delete --ignore-not-found test1-ssa

helm install --server-side=true test1-ssa test-chart/
test "Apply" == $(kubectl get deploy test1-ssa -o json --show-managed-fields | jq '.metadata.managedFields[] | select(.manager == "helm") | .operation')


helm upgrade --server-side=true  test1-ssa test-chart/ --set replicas=2
test "Apply" == $(kubectl get deploy test1-ssa -o json --show-managed-fields | jq '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "2" == $(kubectl get deploy test1-ssa -o json | jq '.spec.replicas')


helm upgrade --server-side=true  test1-ssa test-chart/ --set replicas=null
test "Apply" == $(kubectl get deploy test1-ssa -o json --show-managed-fields | jq '.metadata.managedFields[] | select(.manager == "helm") | .operation')
test "null" == $(helm get values test1-ssa -o json | jq .replicas)
test "2" == $(kubectl get deploy test1-ssa -o json | jq '.spec.replicas')

