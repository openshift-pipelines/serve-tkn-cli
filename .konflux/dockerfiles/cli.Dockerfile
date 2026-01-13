ARG TKN_BUILDER=quay.io/redhat-user-workloads/tekton-ecosystem-tenant/pipelines-tkn-rhel9:next
ARG OPC_BUILDER=quay.io/redhat-user-workloads/tekton-ecosystem-tenant/pipelines-opc-rhel9:next
ARG TKN_PAC_BUILDER=quay.io/redhat-user-workloads/tekton-ecosystem-tenant/pipelines-tkn-pac-rhel9:next
ARG BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25
ARG RUNTIME=registry.access.redhat.com/ubi9/httpd-24@sha256:58b583bb82da64c3c962ed2ca5e60dfff0fc93e50a9ec95e650cecb3a6cb8fda


FROM $TKN_BUILDER AS  tkn
FROM $OPC_BUILDER AS  opc
FROM $TKN_PAC_BUILDER AS  tkn-pac
FROM $BUILDER AS builder
ARG WORKDIR=/go/src/github.com/openshift-pipelines/serve-tkn-cli
WORKDIR $WORKDIR

#Package All binaries in respective archives
ARG ARCHS="amd64 arm64 ppc64le s390x"
ARG BUILD_DIR=$WORKDIR/build

COPY --from=tkn /go/src/github.com/openshift-pipelines/serve-tkn-cli/build $BUILD_DIR
COPY --from=opc /go/src/github.com/openshift-pipelines/serve-tkn-cli/build $BUILD_DIR
COPY --from=tkn-pac /go/src/github.com/openshift-pipelines/serve-tkn-cli/build $BUILD_DIR


RUN ls -rlt $BUILD_DIR/

#
RUN mkdir dist ; \
    for arch in $ARCHS; do \
      echo "▶ Packaging for linux/$arch"; \
      chmod +x $BUILD_DIR/linux-$arch/*; \
      cd $BUILD_DIR/linux-$arch;  \
      tar -czvf $WORKDIR/dist/tkn-linux-$arch.tar.gz .; \
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
