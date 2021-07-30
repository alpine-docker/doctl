# DigitalOcean tools 

DigitalOcean tool images with necessary tools, it can be used as normal kubectl tool as well.

Image tag is kubectl version, not doctl version

There is no `latest` tag for this image

### Installed tools

- [kubectl](https://github.com/kubernetes/kubectl) (latest release), use as image tag
- [helm](https://github.com/helm/helm) (latest release)
- [doctl](https://github.com/digitalocean/doctl) (latest release)
- General tools, such as bash, curl

### Github Repo

https://github.com/alpine-docker/doctl

### build logs

https://app.circleci.com/pipelines/github/alpine-docker/doctl

### Docker image tags

https://hub.docker.com/r/alpine/doctl/tags/

# Why we need it

Mostly it is used during CI/CD (continuous integration and continuous delivery) or as part of an automated build/deployment

# Involve with developing and testing

If you want to build these images by yourself, please follow below commands.

```
export REBUILD=true
bash ./build.sh
```

### Weekly build

Build job runs weekly
