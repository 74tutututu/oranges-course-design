SHELL := /bin/bash

DOCKER_IMAGE ?= oranges-course-design-dev
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)
BUILD_DIR := build
BOOT_SOURCE := boot/boot.asm
BOOT_BINARY := $(BUILD_DIR)/boot.bin
LOADER_SOURCE := boot/loader.asm
LOADER_BINARY := $(BUILD_DIR)/loader.bin
KERNEL_SOURCE := kernel/kernel.asm
KERNEL_SOURCES := kernel/main.c kernel/pic.c kernel/clock.c kernel/keyboard.c kernel/interrupt.c kernel/proc.c \
	kernel/console.c kernel/tty.c kernel/syscall.c kernel/selftest.c
FS_SOURCES := fs/fs.c
LIB_SOURCES := lib/string.c lib/syscall.c
MM_SOURCES := mm/process.c
COMMAND_SOURCES := command/shell.c command/commands.c
SYSTEM_SOURCES := $(KERNEL_SOURCES) $(FS_SOURCES) $(LIB_SOURCES) $(MM_SOURCES) \
	$(COMMAND_SOURCES)
KERNEL_OBJECTS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(SYSTEM_SOURCES))
KERNEL_ENTRY_OBJECT := $(BUILD_DIR)/kernel/kernel.o
KERNEL_IO_OBJECT := $(BUILD_DIR)/kernel/io.o
KERNEL_ELF := $(BUILD_DIR)/kernel.elf
KERNEL_BINARY := $(BUILD_DIR)/kernel.bin
KERNEL_LINKER := kernel/linker.ld
DISK_IMAGE := $(BUILD_DIR)/os.img
SCREENSHOT := assets/screenshots/m6-syscalls.png
NASM ?= nasm
GCC ?= gcc
LD ?= ld
OBJCOPY ?= objcopy
QEMU ?= qemu-system-i386
RUN_TIMEOUT ?= 10s

.PHONY: help build image run test screenshot clean check-env docker-build docker-check docker-test docker-screenshot docker-shell

help: ## 显示可用命令
	@printf '%s\n' \
		'OrangeS 课程设计仓库' \
		'' \
		'  make build         构建 Boot Sector、Loader 和 Kernel' \
		'  make image         生成 FAT12 启动软盘镜像' \
		'  make run           在 QEMU 终端界面启动系统' \
		'  make test          验证 FAT12 和完整启动链' \
		'  make screenshot    生成 M6 系统调用截图' \
		'  make clean         删除构建产物' \
		'' \
		'  make check-env     检查本机 32 位操作系统开发工具链' \
		'  make docker-build  构建统一开发环境镜像' \
		'  make docker-check  在开发容器中运行工具链自检' \
		'  make docker-test   在开发容器中运行启动测试' \
		'  make docker-screenshot  在开发容器中生成启动截图' \
		'  make docker-shell  进入挂载当前仓库的开发容器'

build: $(BOOT_BINARY) $(LOADER_BINARY) $(KERNEL_BINARY) ## 构建启动链

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
	@./tests/test-boot.sh \
		"$(BOOT_BINARY)" \
		"$(LOADER_BINARY)" \
		"$(KERNEL_BINARY)" \
		"$(DISK_IMAGE)"

screenshot: image ## 生成 M6 系统调用截图
	@mkdir -p "$(dir $(SCREENSHOT))"
	@rm -f "$(SCREENSHOT)" "$(BUILD_DIR)/screenshot-debug.log"
	@(sleep 1; ./scripts/qemu-send-text.sh help "cat hello.txt"; \
		sleep 2; printf 'screendump %s -f png\nquit\n' "$(SCREENSHOT)") | \
		$(QEMU) \
			-machine accel=tcg \
			-drive "file=$(DISK_IMAGE),format=raw,if=floppy" \
			-boot a \
			-display none \
			-monitor stdio \
			-serial none \
			-debugcon "file:$(BUILD_DIR)/screenshot-debug.log" \
			-no-reboot \
			-no-shutdown
	@test -s "$(SCREENSHOT)"
	@printf '已生成 %s\n' "$(SCREENSHOT)"

clean: ## 删除构建产物
	rm -rf "$(BUILD_DIR)"

$(BOOT_BINARY): $(BOOT_SOURCE)
	@mkdir -p "$(BUILD_DIR)"
	$(NASM) -f bin -o "$@" "$<"

$(LOADER_BINARY): $(LOADER_SOURCE)
	@mkdir -p "$(BUILD_DIR)"
	$(NASM) -f bin -o "$@" "$<"

$(KERNEL_ENTRY_OBJECT): $(KERNEL_SOURCE)
	@mkdir -p "$(dir $@)"
	$(NASM) -f elf32 -o "$@" "$<"

$(KERNEL_IO_OBJECT): kernel/io.asm
	@mkdir -p "$(dir $@)"
	$(NASM) -f elf32 -o "$@" "$<"

$(BUILD_DIR)/%.o: %.c include/type.h include/const.h include/protect.h include/global.h include/proto.h \
	include/fs.h include/syscall.h
	@mkdir -p "$(dir $@)"
	$(GCC) -m32 -ffreestanding -fno-pie -fno-stack-protector -fno-builtin -fno-asynchronous-unwind-tables -fno-unwind-tables -nostdinc -Wall -Wextra -Iinclude -c -o "$@" "$<"

$(KERNEL_ELF): $(KERNEL_ENTRY_OBJECT) $(KERNEL_IO_OBJECT) $(KERNEL_OBJECTS) $(KERNEL_LINKER)
	@mkdir -p "$(BUILD_DIR)"
	$(LD) -m elf_i386 -T "$(KERNEL_LINKER)" -o "$@" $(KERNEL_ENTRY_OBJECT) $(KERNEL_IO_OBJECT) $(KERNEL_OBJECTS)

$(KERNEL_BINARY): $(KERNEL_ELF)
	$(OBJCOPY) -O binary "$<" "$@"

$(DISK_IMAGE): $(BOOT_BINARY) $(LOADER_BINARY) $(KERNEL_BINARY)
	@mkdir -p "$(BUILD_DIR)"
	rm -f "$@"
	mformat -C -f 1440 -i "$@" -v ORANGES ::
	dd if="$<" of="$@" bs=512 count=1 conv=notrunc status=none
	mcopy -i "$@" "$(LOADER_BINARY)" ::LOADER.BIN
	mcopy -i "$@" "$(KERNEL_BINARY)" ::KERNEL.BIN

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

docker-screenshot: ## 在容器中生成启动截图
	docker run --rm \
		--user "$(HOST_UID):$(HOST_GID)" \
		--env HOME=/tmp \
		--volume "$(ROOT_DIR):/workspace" \
		--workdir /workspace \
		$(DOCKER_IMAGE) \
		make screenshot

docker-shell: ## 进入开发容器
	docker run --rm --interactive --tty \
		--user "$(HOST_UID):$(HOST_GID)" \
		--env HOME=/tmp \
		--volume "$(ROOT_DIR):/workspace" \
		--workdir /workspace \
		$(DOCKER_IMAGE) \
		/bin/bash
