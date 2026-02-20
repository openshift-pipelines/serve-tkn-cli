ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:9.7-1771271449@sha256:4c0a6ea209ccc5028c45d3fd886dd0f51e52a8917bceea15c759a2bd2598836f
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:c7d44146f826037f6873d99da479299b889473492d3c1ab8af86f08af04ec8a0

FROM $GO_BUILDER AS builder

ARG REMOTE_SOURCE=/go/src/github.com/tektoncd/cli

WORKDIR $REMOTE_SOURCE

COPY sources/cli .

ENV GODEBUG="http2server=0"
ENV GOEXPERIMENT=strictfipsruntime
RUN TKN_VERSION=$(cat VERSION);\
    echo "Build TKN ($TKN_VERSION)" ;\
    go build -mod=vendor -tags disable_gcp,strictfipsruntime -v \
       -ldflags "-X github.com/tektoncd/cli/pkg/cmd/version.clientVersion=${TKN_VERSION}" \
       -o /tmp/tkn ./cmd/tkn

# Build tkn-pac from sources
COPY sources/pac $REMOTE_SOURCE/pac
RUN cd $REMOTE_SOURCE/pac && \
    go build -tags strictfipsruntime -mod=vendor -o /tmp/tkn-pac ./cmd/tkn-pac

FROM $RUNTIME

COPY --from=builder /tmp/tkn /usr/bin
COPY --from=builder /tmp/tkn-pac /usr/bin
LABEL \
      com.redhat.component="openshift-pipelines-cli-tkn-rhel9-container" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines serve-tkn-cli tkn" \
      io.k8s.description="Red Hat OpenShift Pipelines serve-tkn-cli tkn" \
      io.k8s.display-name="Red Hat OpenShift Pipelines serve-tkn-cli tkn" \
      io.openshift.tags="tekton,openshift,serve-tkn-cli,tkn" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/pipelines-cli-tkn-rhel9" \
      summary="Red Hat OpenShift Pipelines serve-tkn-cli tkn" \
      version="v1.22.0"

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532
