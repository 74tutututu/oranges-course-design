# 开发指南

## Docker 环境

仓库以 Ubuntu 24.04 为基础镜像，包含 NASM、32 位 GCC 工具链、binutils、Make、mtools 和 QEMU x86。

```bash
make docker-build
make docker-check
make docker-test
make docker-shell
```

容器以当前用户的 UID/GID 运行并挂载仓库到 `/workspace`，避免后续生成 root 所有的构建文件。

## Ubuntu 24.04 本机环境

```bash
sudo apt update
sudo apt install build-essential gcc-multilib binutils make mtools nasm qemu-system-x86
make check-env
```

`make check-env` 会检查工具版本，并临时编译、链接一个 32 位 freestanding ELF 探针。只有命令存在但 `gcc -m32` 或 `ld -m elf_i386` 不可用时，自检仍会失败。

## M4 构建和运行

在开发容器或安装好依赖的宿主机中运行：

```bash
make build
make image
make test
make run
make screenshot
```

- `build/boot.bin` 是严格 512 字节的 Boot Sector。
- `build/loader.bin` 负责 FAT12 内核装载和保护模式切换。
- `build/kernel.elf` 是入口为 `0x10000` 的 ELF32 C Kernel，`build/kernel.bin` 是供 Loader 装载的平坦二进制。
- `build/os.img` 是包含 Loader 和 Kernel 的 1.44 MB FAT12 软盘镜像。
- `make test` 使用 QEMU debugcon 进行无图形启动、Timer/Keyboard IRQ 和进程轮转验证，适用于 CI。
- `make run` 使用 QEMU curses 文本界面显示 BIOS 输出，默认 10 秒后自动结束；可用 `RUN_TIMEOUT=30s` 调整展示时间。
- `make screenshot` 使用 QEMU monitor 注入一次 `a` 键并生成 `assets/screenshots/m4-processes.png`；截图包含三个任务计数和上下文切换次数。

## 模拟器约定

QEMU 是默认模拟器。形成磁盘镜像后，运行入口应由根 Makefile 统一封装，并优先提供可用于 CI 的无图形串口或调试退出路径。

Bochs 只作为可选调试环境：

```bash
sudo apt install bochs bochs-x
```

添加 Bochs 支持时，应将仓库内相对路径写入配置，不能依赖个人目录或未记录的 BIOS 路径。

## 构建约定

- 所有生成内容写入 `build/`。
- 不通过 `sudo mount` 修改镜像，优先使用 mtools。
- C 代码按 32 位 freestanding 方式编译，禁止 PIE 和栈保护等宿主默认特性。
- 链接脚本、内存布局和入口地址必须进入版本控制并在架构文档中说明。
- 增加 `image`、`run` 或 `debug` 目标时，目标必须能够真实工作并提供对应测试；当前骨架不提供占位目标。
