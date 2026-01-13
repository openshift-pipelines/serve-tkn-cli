ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-micro@sha256:e9765516d74cafded50d8ef593331eeca2ef6eababdda118e5297898d99b7433

ARG WORKDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli
ARG BUILD_DIR=$WORKDIR/build

FROM $BUILDER AS builder
ARG WORKDIR
ARG BUILD_DIR

WORKDIR $WORKDIR

COPY sources/cli ./
ARG ARCHS="amd64 arm64 ppc64le s390x"
ARG BUILD_DIR=$WORKDIR/build

#Build TKN Binaries for All Supported Archs
RUN set -euo pipefail; \
    for arch in $ARCHS; do \
        echo "▶ Building tkn for linux/$arch"; \
        mkdir -p "$BUILD_DIR/linux-$arch"; \
        GOOS=linux GOARCH=$arch CGO_ENABLED=0 \
        go build -o "$BUILD_DIR/linux-$arch/tkn" ./cmd/tkn; \
    done;

FROM $RUNTIME
ARG BUILD_DIR

COPY --from=builder $BUILD_DIR $BUILD_DIR

LABEL \
      com.redhat.component="openshift-pipelines-serve-tkn-cli-container" \
      name="openshift-pipelines/pipelines-serve-tkn-cli-rhel9" \
      version="5.0.5-482" \
      summary="Red Hat OpenShift pipelines serves tkn CLI binaries" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Serves tkn CLI binaries from server" \
      io.k8s.display-name="Red Hat OpenShift Pipelines tkn CLI serve" \
      io.k8s.description="Red Hat OpenShift Pipelines tkn CLI serve" \
      io.openshift.tags="pipelines,tekton,openshift" \
      vendor="Red Hat, Inc." \
      distribution-scope="public"