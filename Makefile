DOCKER_REVISION ?= testing-$(USER)

.PHONY: build-image
build-image:
	docker build -t glpi:${DOCKER_REVISION} .

.PHONY: run-image
run-image:
	docker run -it --rm -p 8080:80 glpi:${DOCKER_REVISION}

.PHONY: start-dev
start-dev: build-image run-image