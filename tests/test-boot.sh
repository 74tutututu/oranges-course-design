#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
boot_binary="${1:-${root_dir}/build/boot.bin}"
loader_binary="${2:-${root_dir}/build/loader.bin}"
kernel_binary="${3:-${root_dir}/build/kernel.bin}"
disk_image="${4:-${root_dir}/build/os.img}"
build_dir="${root_dir}/build"

fail()
{
    printf '[error] %s\n' "$1" >&2
    exit 1
}

assert_file()
{
    [[ -f "$1" ]] || fail "找不到文件: $1"
}

create_fat_image()
{
    local image_path="$1"

    rm -f "${image_path}"
    mformat -C -f 1440 -i "${image_path}" -v ORANGES ::
    dd if="${boot_binary}" of="${image_path}" bs=512 count=1 conv=notrunc status=none
}

run_qemu()
{
    local image_path="$1"
    local log_path="$2"
    local expected_status="$3"
    local qemu_status

    rm -f "${log_path}"
    set +e
    timeout --signal=TERM 5s \
        qemu-system-i386 \
        -machine accel=tcg \
        -drive "file=${image_path},format=raw,if=floppy" \
        -boot a \
        -display none \
        -monitor none \
        -serial none \
        -debugcon "file:${log_path}" \
        -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
        -no-reboot \
        -no-shutdown
    qemu_status=$?
    set -e

    [[ "${qemu_status}" == "${expected_status}" ]] || \
        fail "QEMU 状态码应为 ${expected_status}，实际为 ${qemu_status}"
    assert_file "${log_path}"
}

line_number()
{
    local pattern="$1"
    local log_path="$2"

    grep --text --line-number --max-count=1 --fixed-strings "${pattern}" "${log_path}" | cut -d: -f1
}

assert_file "${boot_binary}"
assert_file "${loader_binary}"
assert_file "${kernel_binary}"
assert_file "${disk_image}"

boot_size="$(stat --format='%s' "${boot_binary}")"
loader_size="$(stat --format='%s' "${loader_binary}")"
kernel_size="$(stat --format='%s' "${kernel_binary}")"
image_size="$(stat --format='%s' "${disk_image}")"
boot_signature="$(od --address-radix=n --format=x1 --skip-bytes=510 --read-bytes=2 "${boot_binary}" | tr -d '[:space:]')"

[[ "${boot_size}" == 512 ]] || fail "引导扇区应为 512 字节，实际为 ${boot_size}"
[[ "${boot_signature}" == 55aa ]] || fail "引导签名应为 55aa，实际为 ${boot_signature}"
((loader_size > 0 && loader_size <= 65024)) || fail "Loader 大小超出 0x9000:0x0100 加载区域"
((kernel_size > 0 && kernel_size <= 65536)) || fail "Kernel 大小超出 0x1000:0x0000 加载区域"
[[ "${image_size}" == 1474560 ]] || fail "软盘镜像应为 1474560 字节，实际为 ${image_size}"
cmp --silent --bytes=512 "${boot_binary}" "${disk_image}" || fail '镜像首扇区与 boot.bin 不一致'

directory_listing="$(mdir -b -i "${disk_image}" ::)"
grep --quiet --extended-regexp '(^|/)LOADER\.BIN$' <<<"${directory_listing}" || fail 'FAT12 根目录缺少 LOADER.BIN'
grep --quiet --extended-regexp '(^|/)KERNEL\.BIN$' <<<"${directory_listing}" || fail 'FAT12 根目录缺少 KERNEL.BIN'

success_log="${build_dir}/qemu-success.log"
run_qemu "${disk_image}" "${success_log}" 33

boot_line="$(line_number 'Boot OK' "${success_log}")"
loader_line="$(line_number 'Loader OK' "${success_log}")"
protected_line="$(line_number 'Protected Mode OK' "${success_log}")"
kernel_line="$(line_number 'Kernel OK' "${success_log}")"
[[ -n "${boot_line}" && -n "${loader_line}" && -n "${protected_line}" && -n "${kernel_line}" ]] || \
    fail '完整启动日志缺少预期信息'
((boot_line < loader_line && loader_line < protected_line && protected_line < kernel_line)) || \
    fail '启动信息顺序不正确'

missing_loader_image="${build_dir}/missing-loader.img"
missing_loader_log="${build_dir}/qemu-missing-loader.log"
create_fat_image "${missing_loader_image}"
mcopy -i "${missing_loader_image}" "${kernel_binary}" ::KERNEL.BIN
run_qemu "${missing_loader_image}" "${missing_loader_log}" 35
grep --text --quiet --fixed-strings 'Loader Missing' "${missing_loader_log}" || fail '缺少 Loader 时没有明确报错'

missing_kernel_image="${build_dir}/missing-kernel.img"
missing_kernel_log="${build_dir}/qemu-missing-kernel.log"
create_fat_image "${missing_kernel_image}"
mcopy -i "${missing_kernel_image}" "${loader_binary}" ::LOADER.BIN
run_qemu "${missing_kernel_image}" "${missing_kernel_log}" 37
grep --text --quiet --fixed-strings 'Kernel Missing' "${missing_kernel_log}" || fail '缺少 Kernel 时没有明确报错'

fragmented_image="${build_dir}/fragmented-loader.img"
fragmented_log="${build_dir}/qemu-fragmented-loader.log"
filler_file="${build_dir}/filler.bin"
dd if=/dev/zero of="${filler_file}" bs=512 count=1 status=none
create_fat_image "${fragmented_image}"
mcopy -i "${fragmented_image}" "${filler_file}" ::HOLD1.BIN
mcopy -i "${fragmented_image}" "${filler_file}" ::HOLD2.BIN
mdel -i "${fragmented_image}" ::HOLD1.BIN
mcopy -i "${fragmented_image}" "${loader_binary}" ::LOADER.BIN
mcopy -i "${fragmented_image}" "${kernel_binary}" ::KERNEL.BIN
fragmented_chain="$(mshowfat -i "${fragmented_image}" ::LOADER.BIN)"
grep --quiet --fixed-strings '> <' <<<"${fragmented_chain}" || fail '测试镜像中的 Loader 未形成碎片化簇链'
run_qemu "${fragmented_image}" "${fragmented_log}" 33
grep --text --quiet --fixed-strings 'Kernel OK' "${fragmented_log}" || fail '碎片化 Loader 未能完成启动'

printf '[ok] Boot Sector: 512 字节，签名 55aa。\n'
printf '[ok] FAT12 镜像包含 LOADER.BIN 和 KERNEL.BIN。\n'
printf '[ok] 完整启动链已进入保护模式并执行 Kernel。\n'
printf '[ok] Loader/Kernel 缺失路径均输出明确错误。\n'
printf '[ok] 碎片化 Loader 已通过 FAT12 簇链正确装载。\n'
