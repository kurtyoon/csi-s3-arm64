# yandex-cloud/k8s-csi-s3 for linux/arm64. The upstream Dockerfile builds the
# driver for the build host but downloads geesefs-linux-amd64, and the
# published images are amd64 only (upstream issue #51). The driver copies
# geesefs to the host and runs it under the host's systemd, so the binary must
# match the node: this image takes the arm64 release instead.
ARG CSI_S3_VERSION=v0.43.7
ARG GEESEFS_VERSION=v0.43.9

FROM golang:1.25.9-alpine AS gobuild
ARG CSI_S3_VERSION
RUN apk add --no-cache git
RUN git clone --depth 1 --branch ${CSI_S3_VERSION} https://github.com/yandex-cloud/k8s-csi-s3 /build
WORKDIR /build
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

FROM alpine:3.22
ARG GEESEFS_VERSION
RUN apk add --no-cache fuse mailcap
ADD --chmod=755 https://github.com/yandex-cloud/geesefs/releases/download/${GEESEFS_VERSION}/geesefs-linux-arm64 /usr/bin/geesefs
COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]
