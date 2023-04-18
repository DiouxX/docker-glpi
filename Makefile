DOCKER_TAG = docker-glpi
DOCKER_REVISION ?= testing-$(USER)

.PHONY: build-image
build-image:
	docker build -t ${DOCKER_TAG}:${DOCKER_REVISION} .

.PHONY: run-image
run-image:
	docker run -it --rm -p 8080:80 ${DOCKER_TAG}:${DOCKER_REVISION}

.PHONY: start-dev
start-dev: build-image run-image