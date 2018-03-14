BRANCH := $(shell git branch | sed -n -e 's/^\* \(.*\)/\1/p' | sed -e 's/\//_/g')
TAG := ${BRANCH}-$(shell git rev-parse --short HEAD)

# ignore hidden dirs and current dir
DIRS := $(shell find . -maxdepth 1 -type d -not -path "./\.*" -not -path "." -not -path "./golang-tools")
PUSHS := $(addsuffix _push,$(DIRS))

GO_VERSIONS=1.8.7 1.9.4
GOLANG_TOOLS=$(addprefix golang-tools_,$(GO_VERSIONS))
GOLANG_TOOLS_PUSHS=$(addsuffix _push,$(GOLANG_TOOLS))

all: docker push

docker: $(DIRS) $(GOLANG_TOOLS)
push: $(PUSHS) $(GOLANG_TOOLS_PUSHS)

.PHONY: $(DIRS)
$(DIRS):
	docker build -f $@/Dockerfile -t gridx/$@:$(TAG) $@

.PHONY:
$(PUSHS):
	docker push gridx/$(subst _push,,$@):$(TAG)

.PHONY: $(GOLANG_TOOLS)
$(GOLANG_TOOLS):
	docker build -f golang-tools/Dockerfile -t gridx/golang-tools:$(subst golang-tools_,,$@) --build-arg GO_VERSION=$(subst golang-tools_,,$@) golang-tools

$(GOLANG_TOOLS_PUSHS):
	docker push gridx/golang-tools:$(subst _push,,$(subst golang-tools_,,$@))
