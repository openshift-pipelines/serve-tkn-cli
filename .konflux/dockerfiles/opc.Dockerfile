ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25@sha256:38d909b4f0b5244bc6dffab499fa3324e2ce878dcc79e3ee85a200655cbba736
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-micro@sha256:e9765516d74cafded50d8ef593331eeca2ef6eababdda118e5297898d99b7433

ARG WORKDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli
ARG BUILD_DIR=$WORKDIR/build

FROM $BUILDER AS builder
ARG WORKDIR
ARG BUILD_DIR

WORKDIR $WORKDIR

COPY sources/opc ./
ARG ARCHS="amd64 arm64 ppc64le s390x"

#Build TKN Binaries for All Supported Archs
RUN for arch in $ARCHS; do \
      echo "▶ Building tkn for linux/$arch"; \
      GOOS=linux GOARCH=$arch CGO_ENABLED=0 \
      go build -o $BUILD_DIR/linux-$arch/opc .; \
    done;
LABEL \
      com.redhat.component="openshift-pipelines-opc-container" \
      name="openshift-pipelines/pipelines-opc-rhel9" \
      version="5.0.5-482" \
      summary="Red Hat OpenShift pipelines serves tkn CLI binaries" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Serves tkn CLI binaries from server" \
      io.k8s.display-name="Red Hat OpenShift Pipelines tkn CLI serve" \
      io.k8s.description="Red Hat OpenShift Pipelines tkn CLI serve" \
      io.openshift.tags="pipelines,tekton,openshift" \
      vendor="Red Hat, Inc." \
      distribution-scope="public"

FROM $RUNTIME
ARG BUILD_DIR

COPY --from=builder $BUILD_DIR $BUILD_DIR

LABEL \
      com.redhat.component="openshift-pipelines-serve-tkn-cli-container" \
      name="openshift-pipelines/pipelines-serve-tkn-cli-rhel9" \
      version="$VERSION" \
      summary="Red Hat OpenShift pipelines serves tkn CLI binaries" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="Serves tkn CLI binaries from server" \
      io.k8s.display-name="Red Hat OpenShift Pipelines tkn CLI serve" \
      io.k8s.description="Red Hat OpenShift Pipelines tkn CLI serve" \
      io.openshift.tags="pipelines,tekton,openshift" \
      vendor="Red Hat, Inc." \
      distribution-scope="public"