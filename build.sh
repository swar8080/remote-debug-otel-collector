set -e

releaseVersion=${RELEASE_VERSION}
hostOSArch=${HOST_OS_ARCH}
isPublishingDocker=${PUBLISH_DOCKER-false}
imageNamePrefix=${IMAGE_NAME_PREFIX}

if [[ -z $releaseVersion ]]; then
    echo "RELEASE_VERSION environment variable is required, and most be set to a valid OpenTelemetry Collector release number (without the 'v' prefix)"
    exit 1
fi

if [[ -z $hostOSArch ]]; then
    echo "HOST_OS_ARCH environment variable is required. It is in the format <operating system>_<chip architecture>, all in lowercase. The uname and arch unix commands can usually be used to find these values. Example values are darwin_arm64, linux_amd64, etc."
    exit 1
fi

if [[ -z $imageNamePrefix && $isPublishingDocker = true ]]; then
    echo "IMAGE_NAME_PREFIX environment variable must be set when PUBLISH_DOCKER=true"
    exit 1
fi

set -x

mkdir -p build
mkdir -p build/otelcontribcol

curl -o build/manifest.yaml "https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector-releases/v${releaseVersion}/distributions/otelcol-contrib/manifest.yaml"
yq -i '.dist.debug_compilation = true' build/manifest.yaml
yq -i '.dist.output_path = "./build/otelcontribcol"' build/manifest.yaml

curl -L -o build/ocb.bin "https://github.com/open-telemetry/opentelemetry-collector/releases/download/cmd%2Fbuilder%2Fv${releaseVersion}/ocb_${releaseVersion}_${hostOSArch}"
chmod +x build/ocb.bin

echo "Building for local use/architecture"
build/ocb.bin --config build/manifest.yaml
docker build -t otelcontribcol-debuggable .

echo "Building for linux/amd64"
export GOOS=linux
export GOARCH=amd64
build/ocb.bin --config build/manifest.yaml
docker build -t ${imageNamePrefix}/otelcontribcol-debuggable-amd64:${releaseVersion} --platform=linux/amd64 .

if [[ $isPublishingDocker = true ]]; then
  docker push ${imageNamePrefix}/otelcontribcol-debuggable-amd64:${releaseVersion}
fi

echo "Building for linux/arm64"
export GOOS=linux
export GOARCH=arm64
build/ocb.bin --config build/manifest.yaml
docker build -t ${imageNamePrefix}/otelcontribcol-debuggable-arm64:${releaseVersion} --platform=linux/arm64 .

if [[ $isPublishingDocker = true ]]; then
  docker push ${imageNamePrefix}/otelcontribcol-debuggable-arm64:${releaseVersion}
fi