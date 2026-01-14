ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25@sha256:e8938564f866174a6d79e55dfe577c2ed184b1f53e91d782173fb69b07ce69ef
ARG RUNTIME=registry.access.redhat.com/ubi9/httpd-24:latest@sha256:58b583bb82da64c3c962ed2ca5e60dfff0fc93e50a9ec95e650cecb3a6cb8fda

ARG VERSION=5.0.5
ARG WORKDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli
ARG BUILD_DIR=$WORKDIR/build

FROM $BUILDER AS builder
ARG WORKDIR
ARG BUILD_DIR

WORKDIR $WORKDIR

COPY sources ./
ARG ARCHS="amd64 arm64 ppc64le s390x"

#Build TKN Binaries for All Supported Archs
RUN cd cli; \
    for arch in $ARCHS; do \
      echo "▶ Building tkn for linux/$arch"; \
      GOOS=linux GOARCH=$arch CGO_ENABLED=0 GOCACHE=$WORKDIR/.cache/go-build  \
      go build -mod=vendor -o $BUILD_DIR/linux-$arch/tkn ./cmd/tkn; \
    done;

#Build OPC Binaries for All Supported Archs
RUN cd opc; \
    for arch in $ARCHS; do \
      echo "▶ Building opc for linux/$arch"; \
      GOOS=linux GOARCH=$arch CGO_ENABLED=0 GOCACHE=$WORKDIR/.cache/go-build \
      go build -mod=vendor -o $BUILD_DIR/linux-$arch/opc .; \
    done;

#Build tkn-pac Binaries for All Supported Archs
RUN cd pac; \
    for arch in $ARCHS; do \
      echo "▶ Building tkn-pac for linux/$arch"; \
      GOOS=linux GOARCH=$arch CGO_ENABLED=0 \
      go build -o $BUILD_DIR/linux-$arch/tkn-pac ./cmd/tkn-pac; \
    done;

#Package All binaries in respective archives
RUN mkdir dist ; \
    for arch in $ARCHS; do \
      echo "▶ Packaging for linux/$arch"; \
      chmod +x $BUILD_DIR/linux-$arch/*; \
      cd $BUILD_DIR/linux-$arch && \
      tar -czvf $WORKDIR/dist/tkn-linux-$arch.tar.gz .; \
    done;

FROM $RUNTIME

ARG VERSION
ARG BUILD_DIR

RUN mkdir -p /var/www/html/tkn
COPY --from=builder /go/src/github.com/openshift-pipelines/serve-tkn-cli/dist/* /var/www/html/tkn/

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

CMD ["run-httpd"]

