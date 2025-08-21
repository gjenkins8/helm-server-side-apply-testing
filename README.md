# helm-server-side-apply-testing

These "scripts" before basic end-to-end testing of Helm 4's server-side apply functionality

## Usage

1. Ensure a Kubernetes cluster is available (locally or remote)
2. Configure locations to helm3 and helm4 binaries:

```shell
export HELM3=/path/to/helm3 binary
export HELM4=/path/to/helm4 binary
```

3. Run tests:

```shell
(set -euv -o pipefail; for test in $(ls -1 test-*.sh); do echo $test; ./$test; done) # or run individual scripts as wanted
```

