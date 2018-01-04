BRANCH := $(shell git branch | sed -n -e 's/^\* \(.*\)/\1/p' | sed -e 's/\//_/g')
TAG := ${BRANCH}-$(shell git rev-parse --short HEAD)

# ignore hidden dirs and current dir
DIRS := $(shell find . -type d -not -path "./\.*" -not -path ".")
PUSHS := $(addsuffix _push,$(DIRS))

all: docker

docker: $(DIRS)
push: $(PUSHS)

.PHONY: $(DIRS)
$(DIRS):
	docker build -f $@/Dockerfile -t gridx/$@:$(TAG) $@

.PHONY:
$(PUSHS):
	docker push gridx/$(subst _push,,$@):$(TAG)
