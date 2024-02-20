# Remotely-debuggable OTEL Collector Docker Image
This repository builds an opentelemetry-collector-contrib docker image that a remote debugger can attach to. This can be helpful for troubleshooting environment-specific issues.

You can show your interest in the OTEL team publishing "official" debuggable docker images in [this github issue](https://github.com/open-telemetry/opentelemetry-collector-releases/issues/481). That would be more robust and future-proof than this repo, but it works for now.

# Getting a debuggable docker image

I'll be publishing images whenever there's new versions of the contrib collector:
* [swar8080/otelcontribcol-debuggable-amd64](https://hub.docker.com/r/swar8080/otelcontribcol-debuggable-amd64/tags) (linux amd64)
* [swar8080/otelcontribcol-debuggable-amd64](https://hub.docker.com/r/swar8080/otelcontribcol-debuggable-arm64/tags) (linux arm64)

Alternatively you can [build your own image from scratch](#building-debuggable-docker-images-from-scratch) with the script in this repo.

# Using the docker image

1. Identify which version of the collector you want to debug. Checkout that version in the opentelemetry-collector-contrib repo (ex: `git checkout v0.94.0`)
2. Ensure the collector configuration yaml file is mounted at `/etc/otel/config.yaml`
3. Allow attaching a remote debugger by exposing port `2345` of the container
4. Optionally, set the container environment variable `DELVE_CONTINUE=false` to pause start-up of the collector until the remote debugger is attached. This can be helpful for debugging collector start-up code. By default, this value is `true`, meaning the collector starts automatically and a debugger can be attached at anytime.
5. Start the container and you're all set to remotely debug. Most IDEs have built in tools for remote debugging. You can also can test the above steps by starting a debugger through CLI with `go install github.com/go-delve/delve/cmd/dlv@latest && dlv connect localhost:2345 --log`

### Example: mounting the collector config file

If using helm/kubernetes, you could use the following to create the debuggable collector pod with access to the config file:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otelcol-debuggable-config-map
data:
  config.yaml: {{ tpl (.Files.Get "config.yaml") . | quote }}
---
apiVersion: v1
kind: Pod
metadata:
  name: otelcol-debuggable
spec:
  containers:
    - name: otelcol
      image: swar8080/otelcontribcol-debuggable-amd64:0.94.0
      ports:
        - containerPort: 2345
      volumeMounts:
        - name: otelcol-debuggable-config-volume
          mountPath: /etc/otel
  volumes:
    - name: otelcol-debuggable-config-volume
      configMap:
        name: otelcol-debuggable-config-map
```

# Building debuggable docker images from scratch

### Pre-requisites
- Docker with access to QEMU emulation if building an image for a different os/architecture than your host machine. This should be available by default with docker desktop
- The [yq](https://mikefarah.gitbook.io/yq/v/v3.x/) CLI tool
- The `curl` CLI tool

### Executing the build script
The `build.sh` script will create build a image for your local OS/architecture, linux_arm64, and for linux_amd64. Optionally it'll push the images to a container repository:

```shell
RELEASE_VERSION=0.94.0 HOST_OS_ARCH=darwin_arm64 PUBLISH_DOCKER=true IMAGE_NAME_PREFIX=swar8080 ./build.sh
```

Where:
* `RELEASE_VERSION` - The version of the OTEL Collector Contrib to use as source code
* `HOST_OS_ARCH` - This is the OS and chip architecture of your host machine, in lowercase. The `uname` and `arch` CLI commands can usually be used to check these values.
* `PUBLISH_DOCKER` - `true` to push images to the docker repository you're authenticated with
* `IMAGE_NAME_PREFIX` - A unique prefix for the built docker image name, which results in a name like `swar8080/otelcontribcol-debuggable-amd64`
