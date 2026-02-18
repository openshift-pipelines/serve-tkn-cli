ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:9.7-1771271449@sha256:4c0a6ea209ccc5028c45d3fd886dd0f51e52a8917bceea15c759a2bd2598836f
ARG RUNTIME=registry.redhat.io/rhel9/httpd-24@sha256:dbba6830bf41d3f85c83a46f288d3124b77295c54c62893739b457705c275bc8

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
      com.redhat.component="openshift-serve-tkn-cli/pipelines-serve-tkn-cli-rhel9-container" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      distribution-scope="public" \
      io.k8s.description="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      io.k8s.display-name="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      io.openshift.tags="tekton,openshift,serve-tkn-cli,serve-tkn-cli" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/serve-tkn-cli/pipelines-serve-tkn-cli-rhel9" \
      summary="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      vendor="Red Hat, Inc." \
      version="v1.22.0"

CMD ["run-httpd"]

