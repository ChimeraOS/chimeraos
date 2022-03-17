ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: build
build: builder
	docker pull archlinux:base-devel
	docker run --rm -v $(ROOT_DIR)/output:/output --privileged=true image-builder:latest

.PHONY: builder
builder:
	docker build -t image-builder:latest .


