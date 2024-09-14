FROM alpine

# Ignore to update versions here
# docker build --no-cache --build-arg KUBECTL_VERSION=${kubectl} --build-arg HELM_VERSION=${helm} --build-arg DOCTL_VERION=${doctl} -t ${image}:${tag} .
ARG HELM_VERSION=3.2.1
ARG KUBECTL_VERSION=1.21.3
ARG DOCTL_VERSION=1.62.0

# Install helm (latest release)
# ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
RUN apk add --update --no-cache curl ca-certificates bash git && \
    curl -sL ${BASE_URL}/${TAR_FILE} | tar -xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64

# Install kubectl (latest release)
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# Install doctl (latest release)
RUN apk add --update --no-cache tar && \
  curl -sL https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz |tar xvz -C /usr/bin && \
  chmod +x /usr/bin/doctl && \
  apk del tar

WORKDIR /apps
