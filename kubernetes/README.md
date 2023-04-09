# Docspell Kubernetes Setup

This folder contains the necessary Kubernetes manifests, as well as a [Kustomization](https://kustomize.io/), to deploy docspell to a Kubernetes cluster.

## Using Kustomize

To deploy a basic installation using Kustomize, you can use the following command:

``` shell
kubectl apply -k https://raw.githubusercontent.com/eikek/docspell/master/kubernetes
```

For a more advanced and production ready setup, create your own kustomization.yaml, changing the secret value and replica counts as necessary:

``` yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- github.com/eikek/docspell.git//kubernetes?timeout=90s&ref=master
patches:
- target:
    kind: Deployment
    name: restserver
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 2
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: docspell/restserver:v0.40.0
- target:
    kind: Deployment
    name: joex
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: docspell/joex:v0.40.0
- target:
    kind: Secret
    name: restserver-secrets
  patch: |-
    - op: replace
      path: /data/DOCSPELL_SERVER_BACKEND_JDBC_PASSWORD
      value: ZGJwYXNzMg== # dbpass2
    - op: replace
      path: /data/DOCSPELL_JOEX_JDBC_PASSWORD
      value: ZGJwYXNzMg== # dbpass2
```

And apply your kustomization:

``` shell
kubectl apply -k .
```

## Using Kubernetes manifests

To deploy a basic installation using the Kubernetes manifests, you can use the following command:

``` shell
kubectl apply -f https://raw.githubusercontent.com/eikek/docspell/master/kubernetes
```