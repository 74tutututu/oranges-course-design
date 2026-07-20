SHELL := /bin/bash

DOCKER_IMAGE ?= oranges-course-design-dev
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)

.PHONY: help check-env docker-build docker-check docker-shell

help: ## 显示可用命令
	@printf '%s\n' \
		'OrangeS 课程设计仓库' \
		'' \
		'  make check-env     检查本机 32 位操作系统开发工具链' \
		'  make docker-build  构建统一开发环境镜像' \
		'  make docker-check  在开发容器中运行工具链自检' \
		'  make docker-shell  进入挂载当前仓库的开发容器'

check-env: ## 检查开发工具链
	@./scripts/check-env.sh

docker-build: ## 构建开发容器
	docker build --tag $(DOCKER_IMAGE) .

docker-check: ## 在容器中检查开发工具链
	docker run --rm \
		--user "$(HOST_UID):$(HOST_GID)" \
		--env HOME=/tmp \
		--volume "$(ROOT_DIR):/workspace" \
		--workdir /workspace \
		$(DOCKER_IMAGE) \
		make check-env

docker-shell: ## 进入开发容器
	docker run --rm --interactive --tty \
		--user "$(HOST_UID):$(HOST_GID)" \
		--env HOME=/tmp \
		--volume "$(ROOT_DIR):/workspace" \
		--workdir /workspace \
		$(DOCKER_IMAGE) \
		/bin/bash
