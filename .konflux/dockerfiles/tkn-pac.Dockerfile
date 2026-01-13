ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:6fc28bcb6776e387d7a35a2056d9d2b985dc4e26031e98a2bd35a7137cd6fd71


FROM $BUILDER AS builder

ARG WORKDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli
WORKDIR $WORKDIR

COPY sources/pac ./
ARG ARCHS="amd64 arm64 ppc64le s390x"
ARG BUILD_DIR=$WORKDIR/build

#Build TKN Binaries for All Supported Archs
RUN for arch in $ARCHS; do \
      echo "▶ Building tkn-pac for linux/$arch"; \
      GOOS=linux GOARCH=$arch CGO_ENABLED=0 \
      go build -o $BUILD_DIR/linux-$arch/tkn-pac ./cmd/tkn-pac; \
    done;

LABEL \
      com.redhat.component="openshift-pipelines-cli-tkn-pac-container" \
      name="openshift-pipelines/pipelines-cli-tkn-pac-rhel9" \
      version=$VERSION  \
      summary="Red Hat OpenShift pipelines tkn pac CLI" \
      maintainer="pipelines-extcomm@redhat.com" \
      description="CLI client 'tkn-pac' for managing openshift pipelines" \
      io.k8s.display-name="Red Hat OpenShift Pipelines tkn pac CLI" \
      io.k8s.description="Red Hat OpenShift Pipelines tkn pac CLI" \
      io.openshift.tags="pipelines,tekton,openshift" \
      vendor="Red Hat, Inc." \
      distribution-scope="public"


