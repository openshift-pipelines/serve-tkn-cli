ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:6fc28bcb6776e387d7a35a2056d9d2b985dc4e26031e98a2bd35a7137cd6fd71


FROM $BUILDER AS builder

ARG WORKDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli
WORKDIR $WORKDIR

COPY sources ./
ARG ARCHS="amd64 arm64 ppc64le s390x"
ARG BUILD_DIR=$WORKDIR/build

#Build Binaries for All Supported Archs
RUN cd cli; \
    for arch in $ARCHS; do \
      echo "▶ Building for linux/$arch"; \
      GOOS=linux GOARCH=$arch CGO_ENABLED=0 \
      go build -o $BUILD_DIR/linux-$arch/tkn ./cmd/tkn; \
    done;

#Package All binaries in respective archives
RUN mkdir dist ; cd dist ; \
    for arch in $ARCHS; do \
      echo "▶ Packaging for linux/$arch"; \
      chmod +x $BUILD_DIR/linux-$arch/*; \
      tar -czvf tkn-linux-$arch.tar.gz $BUILD_DIR/linux-$arch; \
    done;

FROM $RUNTIME

RUN mkdir -p /var/www/html/tkn
COPY --from=builder /go/src/github.com/openshift-pipelines/serve-tkn-cli/dist/* /var/www/html/tkn/

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

CMD ["run-httpd"]
