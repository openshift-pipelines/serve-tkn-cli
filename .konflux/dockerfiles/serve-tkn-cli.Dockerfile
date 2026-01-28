ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25.5-1769430014@sha256:359dd4c6c4255b3f7bce4dc15ffa5a9aa65a401f819048466fa91baa8244a793
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

# Build and package per architecture to save disk space
# Loop through each architecture, build all tools, package, then clean up binaries
RUN mkdir -p dist

# Process Linux architectures
RUN for arch in $LINUX_ARCHS; do \
      echo "▶ Building and packaging for linux/$arch"; \
      \
      echo "  Building tkn..."; \
      cd $WORKDIR/cli && \
      GOOS=linux GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/linux-$arch/tkn ./cmd/tkn; \
      go clean -cache -modcache; \
      \
      echo "  Building opc..."; \
      cd $WORKDIR/opc && \
      GOOS=linux GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/linux-$arch/opc .; \
      go clean -cache -modcache; \
      \
      echo "  Building tkn-pac..."; \
      cd $WORKDIR/pac && \
      GOOS=linux GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/linux-$arch/tkn-pac ./cmd/tkn-pac; \
      go clean -cache -modcache; \
      \
      echo "  Packaging tkn-linux-$arch.tar.gz..."; \
      chmod +x $BUILD_DIR/linux-$arch/*; \
      tar -C $BUILD_DIR/linux-$arch -czvf $WORKDIR/dist/tkn-linux-$arch.tar.gz .; \
      \
      echo "  Cleaning up binaries..."; \
      rm -rf $BUILD_DIR/linux-$arch; \
    done;

# Process Darwin/macOS architectures
RUN for arch in $DARWIN_ARCHS; do \
      echo "▶ Building and packaging for darwin/$arch"; \
      \
      echo "  Building tkn..."; \
      cd $WORKDIR/cli && \
      GOOS=darwin GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/darwin-$arch/tkn ./cmd/tkn; \
      go clean -cache -modcache; \
      \
      echo "  Building opc..."; \
      cd $WORKDIR/opc && \
      GOOS=darwin GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/darwin-$arch/opc .; \
      go clean -cache -modcache; \
      \
      echo "  Building tkn-pac..."; \
      cd $WORKDIR/pac && \
      GOOS=darwin GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/darwin-$arch/tkn-pac ./cmd/tkn-pac; \
      go clean -cache -modcache; \
      \
      echo "  Packaging tkn-macos-$arch.tar.gz..."; \
      chmod +x $BUILD_DIR/darwin-$arch/*; \
      tar -C $BUILD_DIR/darwin-$arch -czvf $WORKDIR/dist/tkn-macos-$arch.tar.gz .; \
      \
      echo "  Cleaning up binaries..."; \
      rm -rf $BUILD_DIR/darwin-$arch; \
    done;

# Process Windows architectures
RUN for arch in $WINDOWS_ARCHS; do \
      echo "▶ Building and packaging for windows/$arch"; \
      \
      echo "  Building tkn..."; \
      cd $WORKDIR/cli && \
      GOOS=windows GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/windows-$arch/tkn.exe ./cmd/tkn; \
      go clean -cache -modcache; \
      \
      echo "  Building opc..."; \
      cd $WORKDIR/opc && \
      GOOS=windows GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/windows-$arch/opc.exe .; \
      go clean -cache -modcache; \
      \
      echo "  Building tkn-pac..."; \
      cd $WORKDIR/pac && \
      GOOS=windows GOARCH=$arch GOCACHE=$WORKDIR/.cache/go-build \
      go build -tags strictfipsruntime -mod=vendor -o $BUILD_DIR/windows-$arch/tkn-pac.exe ./cmd/tkn-pac; \
      go clean -cache -modcache; \
      \
      echo "  Packaging tkn-windows-$arch.zip..."; \
      cd $BUILD_DIR/windows-$arch && \
      zip -r $WORKDIR/dist/tkn-windows-$arch.zip .; \
      \
      echo "  Cleaning up binaries..."; \
      rm -rf $BUILD_DIR/windows-$arch; \
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
