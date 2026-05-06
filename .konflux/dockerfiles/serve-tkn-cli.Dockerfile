ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25.8-1776962329
ARG RUNTIME=registry.redhat.io/ubi8/httpd-24@sha256:8f43534a4bd986e328e0884d6dff00329213ca071f576dcf7b5ef4524759fdf9

FROM $BUILDER AS builder
USER root
WORKDIR /go/src/github.com/openshift-pipelines/serve-tkn-cli

# Copy source code
COPY sources sources
# Move caches away from the small /tmp partition
ENV GOCACHE=/go/src/github.com/openshift-pipelines/serve-tkn-cli/.cache/go-build
ENV GOTMPDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli/.cache/tmp

# Build logic using a single loop and BuildKit cache
RUN set -ex; \
    mkdir -p $GOCACHE $GOTMPDIR ;\
    TKN_VER=$(cat sources/cli/VERSION);\
    PAC_VER=$(cat sources/pac/pkg/params/version/version.txt);  \
    echo "Define build matrix: GOOS/GOARCH/FILENAME_OS/EXTENSION";\
    PLATFORMS="linux/amd64/linux/ \
               linux/arm64/linux/ \
               linux/ppc64le/linux/ \
               linux/s390x/linux/ \
               darwin/amd64/macos/ \
               darwin/arm64/macos/ \
               windows/amd64/windows/.exe \
               windows/arm64/windows/.exe"; \
    \
    for p in $PLATFORMS; do \
      df -h ; \
      OS=$(echo $p | cut -d/ -f1); \
      ARCH=$(echo $p | cut -d/ -f2); \
      OS_LABEL=$(echo $p | cut -d/ -f3); \
      EXT=$(echo $p | cut -d/ -f4); \
      \
      BUILD_DIR="$PWD/dist/$OS-$ARCH"; \
      echo "$BUILD_DIR";\
      mkdir -p "$BUILD_DIR"; \
      \
      echo "▶ Building for $OS/$ARCH..."; \
      \
      echo "Build TKN ($TKN_VER)" ;\
      (cd sources/cli && GOOS=$OS GOARCH=$ARCH go build -tags strictfipsruntime -mod=vendor \
        -ldflags "-X github.com/tektoncd/cli/pkg/cmd/version.clientVersion=${TKN_VER} -s -w" \
        -o "$BUILD_DIR/tkn$EXT" ./cmd/tkn); \
      \
      echo "Build TKN-PAC ($PAC_VER)";\
      (cd sources/pac && GOOS=$OS GOARCH=$ARCH go build -tags strictfipsruntime -mod=vendor \
        -ldflags "-X github.com/openshift-pipelines/pipelines-as-code/pkg/params/version.Version=${PAC_VER} -s -w" \
        -o "$BUILD_DIR/tkn-pac$EXT" ./cmd/tkn-pac); \
      \
      echo "Build OPC (opc module)";\
      (cd sources/opc && GOOS=$OS GOARCH=$ARCH go build -tags strictfipsruntime -mod=vendor \
        -ldflags "-s -w" -o "$BUILD_DIR/opc$EXT" .); \
      \
      echo "Package and purge binaries to save space in the builder layer";\
      go clean -cache -modcache; \
      tar -C "$BUILD_DIR" -czvf "dist/tkn-$OS_LABEL-$ARCH.tar.gz" .; \
      rm -rf "$BUILD_DIR"; \
    done

FROM $RUNTIME

# Copy only the final tarballs
COPY --from=builder /go/src/github.com/openshift-pipelines/serve-tkn-cli/dist/*.tar.gz /var/www/html/tkn/

LABEL \
    com.redhat.component="openshift-pipelines-serve-tkn-cli-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.15::el9" \
    description="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
    distribution-scope="public" \
    io.k8s.description="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
    io.k8s.display-name="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
    io.openshift.tags="tekton,openshift,serve-tkn-cli,serve-tkn-cli" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-serve-tkn-cli-rhel9" \
    summary="Red Hat OpenShift Pipelines serve-tkn-cli serve-tkn-cli" \
    vendor="Red Hat, Inc." \
    version="v1.15.5"

CMD ["run-httpd"]