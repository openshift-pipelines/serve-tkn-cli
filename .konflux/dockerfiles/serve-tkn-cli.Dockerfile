ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:9.7-1770654497@sha256:82b82ecf4aedf67c4369849047c2680dba755fe57547bbb05eca211b22038e29
ARG RUNTIME=registry.redhat.io/rhel9/httpd-24@sha256:4b23e987ebb3a021d53c637805c5e10428e39e2ed252b7fad4fa51195604fb80
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
      echo "  Cleaning up binaries and temp files..."; \
      rm -rf $BUILD_DIR/linux-$arch; \
      rm -rf /tmp/go-build* || true; \
    done;

# Clean up temp build artifacts before starting Darwin builds
RUN rm -rf /tmp/go-build* $WORKDIR/.cache || true

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
      echo "  Cleaning up binaries and temp files..."; \
      rm -rf $BUILD_DIR/darwin-$arch; \
      rm -rf /tmp/go-build* || true; \
    done;

# Clean up temp build artifacts before starting Windows builds
RUN rm -rf /tmp/go-build* $WORKDIR/.cache || true

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
      echo "  Packaging tkn-windows-$arch.tar.gz..."; \
      tar -C $BUILD_DIR/windows-$arch -czvf $WORKDIR/dist/tkn-windows-$arch.tar.gz .; \
      \
      echo "  Cleaning up binaries and temp files..."; \
      rm -rf $BUILD_DIR/windows-$arch; \
      rm -rf /tmp/go-build* || true; \
    done;

FROM $RUNTIME
ARG VERSION
ARG BUILD_DIR

RUN mkdir -p /var/www/html/tkn

COPY --from=builder /go/src/github.com/openshift-pipelines/serve-tkn-cli/dist/* /var/www/html/tkn/

LABEL \
      com.redhat.component="openshift-pipelines-serve-tkn-cli-rhel9-container" \
      cpe="cpe:/a:redhat:openshift_pipelines:next::el9" \
      description="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      distribution-scope="public" \
      io.k8s.description="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      io.k8s.display-name="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      io.openshift.tags="tekton,openshift,serve-tkn-cli,serve-tkn-cli" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/pipelines-serve-tkn-cli-rhel9" \
      summary="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
      vendor="Red Hat, Inc." \
      version="next"

CMD ["run-httpd"]
