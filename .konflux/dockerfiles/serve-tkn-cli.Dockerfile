ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25.3-1768393489@sha256:e8938564f866174a6d79e55dfe577c2ed184b1f53e91d782173fb69b07ce69ef
ARG RUNTIME=registry.redhat.io/rhel9/httpd-24@sha256:47a0b3f12211320d1828524a324ab3ec9deac97c17b9d3f056c87d3384d9eb79
ARG VERSION=5.0.5
ARG WORKDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli
ARG BUILD_DIR=$WORKDIR/build

FROM $BUILDER AS builder
ARG WORKDIR
ARG BUILD_DIR

WORKDIR $WORKDIR
COPY sources ./

# Define all architectures and platforms we need to build for
ARG LINUX_ARCHS="amd64 arm64 ppc64le s390x"
ARG DARWIN_ARCHS="amd64 arm64"
ARG WINDOWS_ARCHS="amd64 arm64"

# Build TKN binaries for all platforms
RUN cd cli; \
    for arch in $LINUX_ARCHS; do \
      echo "▶ Building tkn for linux/$arch"; \
      GOOS=linux GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/linux-$arch/tkn ./cmd/tkn; \
    done; \
    for arch in $DARWIN_ARCHS; do \
      echo "▶ Building tkn for darwin/$arch"; \
      GOOS=darwin GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/darwin-$arch/tkn ./cmd/tkn; \
    done; \
    for arch in $WINDOWS_ARCHS; do \
      echo "▶ Building tkn for windows/$arch"; \
      GOOS=windows GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/windows-$arch/tkn.exe ./cmd/tkn; \
    done;

# Build OPC binaries for all platforms
RUN cd opc; \
    for arch in $LINUX_ARCHS; do \
      echo "▶ Building opc for linux/$arch"; \
      GOOS=linux GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/linux-$arch/opc .; \
    done; \
    for arch in $DARWIN_ARCHS; do \
      echo "▶ Building opc for darwin/$arch"; \
      GOOS=darwin GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/darwin-$arch/opc .; \
    done; \
    for arch in $WINDOWS_ARCHS; do \
      echo "▶ Building opc for windows/$arch"; \
      GOOS=windows GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/windows-$arch/opc.exe .; \
    done;

# Build tkn-pac binaries for all platforms
RUN cd pac; \
    for arch in $LINUX_ARCHS; do \
      echo "▶ Building tkn-pac for linux/$arch"; \
      GOOS=linux GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/linux-$arch/tkn-pac ./cmd/tkn-pac; \
    done; \
    for arch in $DARWIN_ARCHS; do \
      echo "▶ Building tkn-pac for darwin/$arch"; \
      GOOS=darwin GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/darwin-$arch/tkn-pac ./cmd/tkn-pac; \
    done; \
    for arch in $WINDOWS_ARCHS; do \
      echo "▶ Building tkn-pac for windows/$arch"; \
      GOOS=windows GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/windows-$arch/tkn-pac.exe ./cmd/tkn-pac; \
    done;

# Package all binaries in respective archives
# Linux: tar.gz, macOS: tar.gz, Windows: zip
RUN mkdir -p dist ; \
    for arch in $LINUX_ARCHS; do \
      echo "▶ Packaging tkn-linux-$arch.tar.gz"; \
      chmod +x $BUILD_DIR/linux-$arch/*; \
      tar -C $BUILD_DIR/linux-$arch -czvf $WORKDIR/dist/tkn-linux-$arch.tar.gz .; \
    done; \
    for arch in $DARWIN_ARCHS; do \
      echo "▶ Packaging tkn-macos-$arch.tar.gz"; \
      chmod +x $BUILD_DIR/darwin-$arch/*; \
      tar -C $BUILD_DIR/darwin-$arch -czvf $WORKDIR/dist/tkn-macos-$arch.tar.gz .; \
    done; \
    for arch in $WINDOWS_ARCHS; do \
      echo "▶ Packaging tkn-windows-$arch.zip"; \
      cd $BUILD_DIR/windows-$arch && \
      zip -r $WORKDIR/dist/tkn-windows-$arch.zip .; \
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
