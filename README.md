# Simple Server for Apple App Site Assocation and Assetlinks.json

<img src="https://coveralls.io/repos/github/xshadowlegendx/aasa-assetlinks-server/badge.svg?branch=main"/> <img src="https://github.com/xshadowlegendx/aasa-assetlinks-server/actions/workflows/build.yml/badge.svg"/>

## Installation

### Kubernetes

```bash
# with kustomize
# ensure .secrets/S3_ACCESS_KEY_ID and .secrets/S3_SECRET_ACCESS_KEY
# exists before running below commands
cat <<EOF > kustomization.yml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- https://raw.githubusercontent.com/xshadowlegendx/aasa-assetlinks-server/refs/heads/main/k8s/install.yml

secretGenerator:
- name: aasa-assetlinks-server
  behavior: merge
  literals:
  - S3_PORT='443'
  - S3_REGION=garage
  - S3_HOST=s3.example.com
  - S3_URL_SCHEME=https
  - S3_BUCKET_NAME=aasa-assetlinks
  files:
  - S3_ACCESS_KEY_ID=./.secrets/S3_ACCESS_KEY_ID
  - S3_SECRET_ACCESS_KEY=./.secrets/S3_SECRET_ACCESS_KEY
EOF

kubectl apply -k .
```

### Docker

```bash
# if no s3 credential and bucket configured
# data will not be persist
docker container run --rm -it -p 4000:4000 shadowlegend/aasa-assetlinks-server:latest
```
