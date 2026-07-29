#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
boot_binary="${1:-${root_dir}/build/boot.bin}"
disk_image="${2:-${root_dir}/build/os.img}"
debug_log="${root_dir}/build/qemu-debug.log"

fail()
{
    printf '[error] %s\n' "$1" >&2
    exit 1
}

[[ -f "${boot_binary}" ]] || fail "找不到引导扇区: ${boot_binary}"
[[ -f "${disk_image}" ]] || fail "找不到磁盘镜像: ${disk_image}"

boot_size="$(stat --format='%s' "${boot_binary}")"
[[ "${boot_size}" == 512 ]] || fail "引导扇区应为 512 字节，实际为 ${boot_size}"

boot_signature="$(od --address-radix=n --format=x1 --skip-bytes=510 --read-bytes=2 "${boot_binary}" | tr -d '[:space:]')"
[[ "${boot_signature}" == 55aa ]] || fail "引导签名应为 55aa，实际为 ${boot_signature}"

image_size="$(stat --format='%s' "${disk_image}")"
[[ "${image_size}" == 1474560 ]] || fail "软盘镜像应为 1474560 字节，实际为 ${image_size}"

rm -f "${debug_log}"

set +e
timeout --signal=TERM 5s \
    qemu-system-i386 \
    -machine accel=tcg \
    -drive "file=${disk_image},format=raw,if=floppy" \
    -boot a \
    -display none \
    -monitor none \
    -serial none \
    -debugcon "file:${debug_log}" \
    -no-reboot \
    -no-shutdown
qemu_status=$?
set -e

[[ "${qemu_status}" == 124 ]] || fail "QEMU 在等待超时前异常退出，状态码为 ${qemu_status}"
grep --fixed-strings --quiet 'OrangeS Course Design' "${debug_log}" || fail '未捕获课程设计启动信息'
grep --fixed-strings --quiet 'Boot OK' "${debug_log}" || fail '未捕获 Boot OK'

printf '[ok] boot.bin: 512 字节，签名 55aa。\n'
printf '[ok] os.img: 1474560 字节。\n'
printf '[ok] QEMU 已执行引导扇区并输出预期信息。\n'
