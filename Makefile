ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

ifndef CHANNEL
$(error CHANNEL is not set. Must set CHANNEL=value in the build command.)
endif
ifndef VERSION
$(error VERSION is not set. Must set VERSION=value in the build command.)
endif

.PHONY: build
build: builder
	docker pull archlinux:base-devel
	docker run --rm -v $(ROOT_DIR)/output:/output --privileged=true image-builder:latest $(CHANNEL) $(VERSION) 

.PHONY: builder
builder:
	docker build -t image-builder:latest .


