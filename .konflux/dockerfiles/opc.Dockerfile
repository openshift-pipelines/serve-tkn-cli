ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:9.7-1772454089@sha256:b3b98e0b21ddbb979d968ca319b8eebdca121e30d58994072cbf99ce86e5d24e
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:c7d44146f826037f6873d99da479299b889473492d3c1ab8af86f08af04ec8a0

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/opc
COPY sources/opc .

ENV GOEXPERIMENT="strictfipsruntime"
RUN go build -buildvcs=false -mod=vendor -tags disable_gcp,strictfipsruntime  -o /tmp/opc main.go

FROM $RUNTIME
ARG VERSION=opc-main
COPY --from=builder /tmp/opc /usr/bin

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

LABEL \
      com.redhat.component="openshift-pipelines-opc-rhel9-container" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines serve-tkn-cli opc" \
      io.k8s.description="Red Hat OpenShift Pipelines serve-tkn-cli opc" \
      io.k8s.display-name="Red Hat OpenShift Pipelines serve-tkn-cli opc" \
      io.openshift.tags="tekton,openshift,serve-tkn-cli,opc" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/pipelines-opc-rhel9" \
      summary="Red Hat OpenShift Pipelines serve-tkn-cli opc" \
      version="v1.22.0"