ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:9.7-1769430014@sha256:359dd4c6c4255b3f7bce4dc15ffa5a9aa65a401f819048466fa91baa8244a793
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest@sha256:759f5f42d9d6ce2a705e290b7fc549e2d2cd39312c4fa345f93c02e4abb8da95

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/pipelines-as-code
COPY sources/pac .

ENV GODEBUG="http2server=0"
ENV GOEXPERIMENT="strictfipsruntime"
RUN TKN_PAC_VERSION=$(cat sources/pac/pkg/params/version/version.txt);  \
    echo "Build TKN-TKN ($TKN_PAC_VERSION)" ;\
    go build -mod=vendor -tags disable_gcp,strictfipsruntime -v  \
    -ldflags "-X github.com/openshift-pipelines/pipelines-as-code/pkg/params/version.Version=${TKN_PAC_VERSION}" \
    -o /tmp/tkn-pac ./cmd/tkn-pac

FROM $RUNTIME
ARG VERSION=pipelines-as-code-cli-next

COPY --from=builder /tmp/tkn-pac /usr/bin

LABEL \
      com.redhat.component="openshift-pipelines-pipelines-as-code-cli-rhel9-container" \
      cpe="cpe:/a:redhat:openshift_pipelines:1.22::el9" \
      description="Red Hat OpenShift Pipelines serve-tkn-cli tkn-pac" \
      io.k8s.description="Red Hat OpenShift Pipelines serve-tkn-cli tkn-pac" \
      io.k8s.display-name="Red Hat OpenShift Pipelines serve-tkn-cli tkn-pac" \
      io.openshift.tags="tekton,openshift,serve-tkn-cli,tkn-pac" \
      maintainer="pipelines-extcomm@redhat.com" \
      name="openshift-pipelines/pipelines-pipelines-as-code-cli-rhel9" \
      summary="Red Hat OpenShift Pipelines serve-tkn-cli tkn-pac" \
      version="v1.22.0"

RUN groupadd -r -g 65532 nonroot && \
    useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532
