#!/usr/bin/env bash

# Prerequisite
# Make sure you set secret enviroment variables in CI
# DOCKER_USERNAME
# DOCKER_PASSWORD

# set -ex

set -e

build() {

  # helm latest
  helm=$(curl -s https://github.com/helm/helm/releases)
  helm=$(echo $helm\" |grep -oP '(?<=tag\/v)[0-9][^"]*'|grep -v \-|sort -Vr|head -1)
  echo "helm version is $helm"

  # doctl latest
  doctl=$(curl -s https://github.com/digitalocean/doctl/releases)
  doctl=$(echo $doctl\" |grep -oP '(?<=tag\/v)[0-9][^"<]*'|grep -v \-|sort -Vr|head -1)
  echo "doctl version is $doctl"

  docker build --no-cache \
    --build-arg KUBECTL_VERSION=${tag} \
    --build-arg HELM_VERSION=${helm} \
    --build-arg DOCTL_VERSION=${doctl} \
    -t ${image}:${tag} .

  # run test
  echo "Detected Helm3+"
  version=$(docker run --rm ${image}:${tag} helm version)
  # version.BuildInfo{Version:"v3.6.3", GitCommit:"d506314abfb5d21419df8c7e7e68012379db2354", GitTreeState:"clean", GoVersion:"go1.16.5"}

  version=$(echo ${version}| awk -F \" '{print $2}')
  if [ "${version}" == "v${helm}" ]; then
    echo "matched"
  else
    echo "unmatched"
    exit
  fi

  if [[ "$CIRCLE_BRANCH" == "main" ]]; then
    docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
    docker push ${image}:${tag}
  fi
}

image="alpine/doctl"

# kubectl latest
kubectl=$(curl -s https://github.com/kubernetes/kubectl/releases)
kubectl=$(echo $kubectl\" |grep -oP '(?<=tag\/v)[0-9][^"<]*'|grep -v \-|sort -Vr|head -1)
echo "kubectl version is $kubectl"

# set kubectl version as image's tag
tag=${kubectl}

status=$(curl -sL https://hub.docker.com/v2/repositories/${image}/tags/${tag})
echo $status
if [[ ( "${status}" =~ "not found" ) || ( ${REBUILD} == "true" ) ]]; then
   build
fi
