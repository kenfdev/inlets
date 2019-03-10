Version := $(shell git describe --tags --dirty)
GitCommit := $(shell git rev-parse HEAD)
LDFLAGS := "-s -w -X main.Version=$(Version) -X main.GitCommit=$(GitCommit)"
CCARMV7=arm-linux-gnueabihf-gcc
CCARM64=aarch64-linux-gnu-gcc

.PHONY: all
all: docker

.PHONY: dist
dist:
	CGO_ENABLED=0 GOOS=linux go build -ldflags $(LDFLAGS) -a -installsuffix cgo -o bin/inlets
	CGO_ENABLED=0 GOOS=darwin go build -ldflags $(LDFLAGS) -a -installsuffix cgo -o bin/inlets-darwin
	CGO_ENABLED=0 GOOS=linux CC=${CCARMV7} GOARCH=arm GOARM=6 go build -ldflags $(LDFLAGS) -a -installsuffix cgo -o bin/inlets-armhf
	CGO_ENABLED=0 GOOS=linux CC=${CCARM64} GOARCH=arm64 go build -ldflags $(LDFLAGS) -a -installsuffix cgo -o bin/inlets-arm64

.PHONY: docker
docker:
	docker build --build-arg BASE_IMAGE=alpine:3.9 --build-arg INLETS_BINARY=bin/inlets --build-arg Version=$(Version) --build-arg GIT_COMMIT=$(GitCommit) --tag kenfdev/inlets:${Version} --no-cache=true .
	docker build --build-arg BASE_IMAGE=arm32v6/alpine:3.9 --build-arg INLETS_BINARY=bin/inlets-armhf --build-arg Version=$(Version) --build-arg GIT_COMMIT=$(GitCommit) --tag kenfdev/inlets:${Version}-armhf --no-cache=true .
	docker build --build-arg BASE_IMAGE=arm64v8/alpine:3.9 --build-arg INLETS_BINARY=bin/inlets-arm64 --build-arg Version=$(Version) --build-arg GIT_COMMIT=$(GitCommit) --tag kenfdev/inlets:${Version}-arm64 --no-cache=true .

.PHONY: docker-login
docker-login:
	echo -n "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

.PHONY: push
push:
	docker push kenfdev/inlets:$(Version)
	docker push kenfdev/inlets:$(Version)-armhf
	docker push kenfdev/inlets:$(Version)-arm64
	docker manifest create "kenfdev/inlets:${Version}" "kenfdev/inlets:${Version}" "kenfdev/inlets:${Version}-armhf" "kenfdev/inlets:${Version}-arm64"
	docker manifest push "kenfdev/inlets:${Version}"
