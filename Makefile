SHELL := /bin/bash

DOCKER_IMAGE ?= oranges-course-design-dev
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)
BUILD_DIR := build
BOOT_SOURCE := boot/boot.asm
BOOT_BINARY := $(BUILD_DIR)/boot.bin
DISK_IMAGE := $(BUILD_DIR)/os.img
NASM ?= nasm
QEMU ?= qemu-system-i386
RUN_TIMEOUT ?= 10s

.PHONY: help build image run test clean check-env docker-build docker-check docker-test docker-shell

help: ## 显示可用命令
	@printf '%s\n' \
		'OrangeS 课程设计仓库' \
		'' \
		'  make build         汇编 512 字节 Boot Sector' \
		'  make image         生成 1.44 MB 启动软盘镜像' \
		'  make run           在 QEMU 终端界面启动系统' \
		'  make test          检查镜像并运行 QEMU 启动测试' \
		'  make clean         删除构建产物' \
		'' \
		'  make check-env     检查本机 32 位操作系统开发工具链' \
		'  make docker-build  构建统一开发环境镜像' \
		'  make docker-check  在开发容器中运行工具链自检' \
		'  make docker-test   在开发容器中运行启动测试' \
		'  make docker-shell  进入挂载当前仓库的开发容器'

build: $(BOOT_BINARY) ## 汇编 Boot Sector

image: $(DISK_IMAGE) ## 生成启动镜像

run: image ## 启动 QEMU
	@set +e; \
	timeout --foreground --signal=TERM "$(RUN_TIMEOUT)" \
		$(QEMU) \
			-drive "file=$(DISK_IMAGE),format=raw,if=floppy" \
			-boot a \
			-display curses \
			-monitor none \
			-serial none; \
	qemu_status=$$?; \
	set -e; \
	if [[ $$qemu_status -ne 124 ]]; then exit $$qemu_status; fi; \
	printf 'QEMU 演示已在 %s 后自动结束。\n' "$(RUN_TIMEOUT)"

test: image ## 执行启动测试
	@./tests/test-boot.sh "$(BOOT_BINARY)" "$(DISK_IMAGE)"

clean: ## 删除构建产物
	rm -rf "$(BUILD_DIR)"

$(BOOT_BINARY): $(BOOT_SOURCE)
	@mkdir -p "$(BUILD_DIR)"
	$(NASM) -f bin -o "$@" "$<"

$(DISK_IMAGE): $(BOOT_BINARY)
	@mkdir -p "$(BUILD_DIR)"
	dd if=/dev/zero of="$@" bs=512 count=2880 status=none
	dd if="$<" of="$@" bs=512 count=1 conv=notrunc status=none

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

docker-test: ## 在容器中执行启动测试
	docker run --rm \
		--user "$(HOST_UID):$(HOST_GID)" \
		--env HOME=/tmp \
		--volume "$(ROOT_DIR):/workspace" \
		--workdir /workspace \
		$(DOCKER_IMAGE) \
		make test

docker-shell: ## 进入开发容器
	docker run --rm --interactive --tty \
		--user "$(HOST_UID):$(HOST_GID)" \
		--env HOME=/tmp \
		--volume "$(ROOT_DIR):/workspace" \
		--workdir /workspace \
		$(DOCKER_IMAGE) \
		/bin/bash
