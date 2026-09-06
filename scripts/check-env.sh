#!/usr/bin/env bash

set -euo pipefail

required_commands=(
    nasm
    gcc
    ld
    objdump
    readelf
    ar
    objcopy
    nm
    make
    mcopy
    mdel
    mformat
    mdir
    mshowfat
    pandoc
    qemu-system-i386
)

missing_commands=()
for command_name in "${required_commands[@]}"; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        missing_commands+=("${command_name}")
    fi
done

if ((${#missing_commands[@]} > 0)); then
    printf '[error] 缺少命令: %s\n' "${missing_commands[*]}" >&2
    printf '[hint] 请参考 docs/development.md 安装依赖，或运行 make docker-build && make docker-check。\n' >&2
    exit 1
fi

printf '[info] NASM: %s\n' "$(nasm -v)"
printf '[info] GCC: %s\n' "$(gcc --version | sed -n '1p')"
printf '[info] LD: %s\n' "$(ld --version | sed -n '1p')"
printf '[info] Make: %s\n' "$(make --version | sed -n '1p')"
printf '[info] mtools: %s\n' "$(mcopy -V 2>&1 | sed -n '1p')"
printf '[info] QEMU: %s\n' "$(qemu-system-i386 --version | sed -n '1p')"
printf '[info] Pandoc: %s\n' "$(pandoc --version | sed -n '1p')"

probe_dir="$(mktemp -d)"
trap 'rm -rf "${probe_dir}"' EXIT

printf '%s\n' \
    'void _start(void)' \
    '{' \
    '    for (;;) {' \
    '    }' \
    '}' >"${probe_dir}/probe.c"

gcc \
    -m32 \
    -ffreestanding \
    -fno-pie \
    -fno-stack-protector \
    -c "${probe_dir}/probe.c" \
    -o "${probe_dir}/probe.o"

ld \
    -m elf_i386 \
    -Ttext 0x1000 \
    -e _start \
    -o "${probe_dir}/probe.elf" \
    "${probe_dir}/probe.o"

if ! readelf -h "${probe_dir}/probe.elf" | grep -Eq 'Class:[[:space:]]+ELF32'; then
    printf '[error] 32 位链接探针没有生成 ELF32 文件。\n' >&2
    exit 1
fi

if ! objdump -f "${probe_dir}/probe.elf" | grep -q 'architecture: i386'; then
    printf '[error] 32 位链接探针的目标架构不是 i386。\n' >&2
    exit 1
fi

printf '[ok] 32 位 freestanding 编译和链接探针通过。\n'
printf '[ok] OrangeS 开发环境已就绪。\n'
