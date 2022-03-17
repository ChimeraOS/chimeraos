.PHONY: build
build: builder
	docker run --rm -v $(PWD)/output:/output --privileged=true image-builder:latest

.PHONY: builder
builder:
	docker build -t image-builder:latest .


