BRANCH := $(shell git branch | sed -n -e 's/^\* \(.*\)/\1/p' | sed -e 's/\//_/g')
TAG := ${BRANCH}-$(shell git rev-parse --short HEAD)

# ignore hidden dirs and current dir
DIRS := $(shell find . -maxdepth 1 -type d -not -path "./\.*" -not -path "." -not -path "./golang-tools" -not -path "./modbus-tools")
PUSHS := $(addsuffix _push,$(DIRS))

GO_VERSIONS=1.8.7 1.9.4
GOLANG_TOOLS=$(addprefix golang-tools_,$(GO_VERSIONS))
GOLANG_TOOLS_PUSHS=$(addsuffix _push,$(GOLANG_TOOLS))
MODBUS_TOOLS=$(addprefix modbus-tools_,$(GO_VERSIONS))
MODBUS_TOOLS_PUSHS=$(addsuffix _push,$(MODBUS_TOOLS))

all: docker push

docker: $(GOLANG_TOOLS) $(DIRS) $(MODBUS_TOOLS)
push: $(GOLANG_TOOLS_PUSHS) $(PUSHS)  $(MODBUS_TOOLS_PUSHS)

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

.PHONY: $(MODBUS_TOOLS)
$(MODBUS_TOOLS): $(GOLANG_TOOLS)
	docker build -f modbus-tools/Dockerfile -t gridx/modbus-tools:$(subst modbus-tools_,,$@) --build-arg GO_VERSION=$(subst modbus-tools_,,$@) modbus-tools

$(MODBUS_TOOLS_PUSHS):
	docker push gridx/modbus-tools:$(subst _push,,$(subst modbus-tools_,,$@))
