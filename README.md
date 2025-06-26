# DigitalOcean tools 

DigitalOcean tool images with necessary tools, it can be used as normal kubectl or doctl command line as well.

**Image tag is kubectl version, not doctl version**

### Installed tools

- [doctl](https://github.com/digitalocean/doctl) (latest release, when run the build)
- [kubectl](https://github.com/kubernetes/kubectl) (latest release, when run the build)
- [helm](https://github.com/helm/helm) (latest release, when run the build)
- [pv-migrate](https://github.com/utkuozdemir/pv-migrate) (latest release, when run the build)
- General tools, such as bash, curl
- Recommend any other tools by raise PR.

### Github Repo

https://github.com/alpine-docker/doctl

### build logs

https://app.circleci.com/pipelines/github/alpine-docker/doctl

### Docker image tags

https://hub.docker.com/r/alpine/doctl/tags/

# Why we need it

Mostly it is used during CI/CD (continuous integration and continuous delivery) or as part of an automated build/deployment

# A sample for you to use it in CICD

Make sure you have set a secret variable `DIGITALOCEAN_TOKEN` in its pipeline, with below pipeline, you can 

```

    steps:
      - checkout
      - run:
          name: helm_chart_deployment
          command: |
            # doctl authenticating
            doctl auth init -t ${DIGITALOCEAN_TOKEN}
            # run other doctl command if required
            apk add jq
            # save Kube config
            id=$(doctl kubernetes cluster list -o  json |jq -r  .[].id)
            doctl kubernetes cluster kubeconfig save ${id}
            # deploy a helm chart
            cd charts/application_name
            helm upgrade --install my-release .
```

# Involve with developing and testing

If you want to build these images by yourself, please follow below commands.

```
export REBUILD=true
bash ./build.sh
```

### schedule builds

Build job runs daily by [CircleCI](https://circleci.com/dashboard)
