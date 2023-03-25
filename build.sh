#!/usr/bin/env bash

# Prerequisite
# Make sure you set secret enviroment variables in CI
# DOCKER_USERNAME
# DOCKER_PASSWORD

# set -ex

set -e

function get_latest_kubectl_minor_releases() {
  local releases
  local minor_versions
  local minor_version
  local latest_versions

  releases=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases | jq -r '.[].tag_name | select(test("alpha|beta|rc") | not)')

  for release in $releases; do
    minor_version=$(echo $release | awk -F'.' '{print $1"."$2}')

    if [[ ! " ${minor_versions[@]} " =~ " ${minor_version} " ]]; then
      minor_versions+=($minor_version)
    fi
  done

  sorted_minor_versions=($(echo "${minor_versions[@]}" | tr ' ' '\n' | sort -rV))

  for i in $(seq 0 3); do
    minor_version="${sorted_minor_versions[$i]}"
    latest_version=$(echo "$releases" | grep "^$minor_version\." | sort -rV | head -1 | sed 's/v//')
    latest_versions+=($latest_version)
  done

  echo "${latest_versions[@]}"
}

function get_latest_helm_version() {
  local helm=$(curl -s https://github.com/helm/helm/releases)
  helm=$(echo $helm\" |grep -oP '(?<=tag\/v)[0-9][^"]*'|grep -v \-|sort -Vr|head -1)
  echo "helm version is $helm"
  echo $helm
}

function get_latest_doctl_version() {
  local doctl=$(curl -s https://github.com/digitalocean/doctl/releases)
  doctl=$(echo $doctl\" |grep -oP '(?<=tag\/v)[0-9][^"<]*'|grep -v \-|sort -Vr|head -1)
  echo "doctl version is $doctl"
  echo $doctl
}

build() {

  docker build --no-cache \
    --build-arg KUBECTL_VERSION=${tag} \
    --build-arg HELM_VERSION=${latest_helm_version} \
    --build-arg DOCTL_VERSION=${latest_doctl_version} \
    -t ${image}:${tag} .

  # run test
  echo "Detected Helm3+"
  version=$(docker run --rm ${image}:${tag} helm version)
  # version.BuildInfo{Version:"v3.6.3", GitCommit:"d506314abfb5d21419df8c7e7e68012379db2354", GitTreeState:"clean", GoVersion:"go1.16.5"}

  version=$(echo ${version}| awk -F \" '{print $2}')
  if [ "${version}" == "v${latest_helm_version}" ]; then
    echo "matched"
  else
    echo "unmatched"
    exit
  fi

  if [[ "$CIRCLE_BRANCH" == "main" ]]; then
    docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
    #docker push ${image}:${tag}
  fi
}

main() {
  image="alpine/doctl"

  latest_kubectl_versions=($(get_latest_kubectl_minor_releases))
  echo "latest kubectl versions of each minor version are ${latest_versions[@]}"

  latest_helm_version=$(get_latest_helm_version)
  echo "latest helm version is ${latest_helm_version}"

  latest_doctl_version=$(get_latest_doctl_version)
  echo "latest doctl version is ${latest_doctl_version}"
  
  for tag in "${latest_kubectl_versions[@]}"; do
    echo ${tag}
    status=$(curl -sL https://hub.docker.com/v2/repositories/${image}/tags/${tag})
    echo $status
    if [[ ( "${status}" =~ "not found" ) ||( ${REBUILD} == "true" ) ]]; then
       echo "build image for ${tag}"
       build
    fi
  done
  
  # update latest image
  docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
  docker pull ${image}:${latest_kubectl_versions[0]}
  docker tag ${image}:${latest_kubectl_versions[0]} ${image}:latest
  #docker push ${image}:latest

}

main "$@"
