

OSES   := linux
ARCHES := amd64 arm64 ppc64le s390x
# Output dirs

BUILD_DIR := build
DIST_DIR  := dist

.PHONY: all
all: build package

.PHONY: build
build:
	@mkdir -p $(BUILD_DIR)
	@for os in $(OSES); do \
	  for arch in $(ARCHES); do \
	    outdir=$(abspath $(BUILD_DIR))/$$os-$$arch; \
	    ls -l .	\
	    mkdir -p $$outdir; \
	  	echo "▶ Building cli for $$os/$$arch $(shell pwd)"; \
	  	(cd cli && GOOS=$$os GOARCH=$$arch CGO_ENABLED=0 go build -o $$outdir/tkn ./cmd/tkn;) \
	  done; \
	done

.PHONY: package
package:
	@mkdir -p $(DIST_DIR)
	@for dir in $(BUILD_DIR)/*; do \
	  arch=$$(basename $$dir); \
	  echo "📦 Packaging $$arch"; \
	  tar -C $(BUILD_DIR) -czf $(DIST_DIR)/$$arch.tar.gz $$arch; \
	done
