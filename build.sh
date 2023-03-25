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

# Get the list of all releases tags, excludes alpha, beta, rc tags
releases=$(curl -s https://api.github.com/repos/kubernetes/kubernetes/releases | jq -r '.[].tag_name | select(test("alpha|beta|rc") | not)')

# Loop through the releases and extract the minor version number
for release in $releases; do
  minor_version=$(echo $release | awk -F'.' '{print $1"."$2}')

  # Check if the minor version is already in the array of minor versions
  if [[ ! " ${minor_versions[@]} " =~ " ${minor_version} " ]]; then
    minor_versions+=($minor_version)
  fi
done

# Sort the unique minor versions in reverse order
sorted_minor_versions=($(echo "${minor_versions[@]}" | tr ' ' '\n' | sort -rV))

# Loop through the first 4 unique minor versions and get the latest version for each
for i in $(seq 0 3); do
  minor_version="${sorted_minor_versions[$i]}"
  latest_version=$(echo "$releases" | grep "^$minor_version\." | sort -rV | head -1 | sed 's/v//')
  latest_versions+=($latest_version)
done

echo "Found k8s latest versions: ${latest_versions[*]}"

for tag in "${latest_versions[@]}"; do
  echo ${tag}
  status=$(curl -sL https://hub.docker.com/v2/repositories/${image}/tags/${tag})
  echo $status
  if [[ ( "${status}" =~ "not found" ) ||( ${REBUILD} == "true" ) ]]; then
     echo "build image for ${tag}"
     build
  fi
done

# update latest image

docker tag ${image}:${latest_versions[0]} ${image}:latest
docker push ${image}:latest
