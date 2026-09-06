#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
boot_binary="${1:-${root_dir}/build/boot.bin}"
loader_binary="${2:-${root_dir}/build/loader.bin}"
kernel_binary="${3:-${root_dir}/build/kernel.bin}"
disk_image="${4:-${root_dir}/build/os.img}"
build_dir="${root_dir}/build"
kernel_elf="${build_dir}/kernel.elf"

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

run_observed_qemu()
{
    local image_path="$1"
    local log_path="$2"
    local stderr_log="${build_dir}/qemu-success.stderr"
    local qemu_status

    rm -f "${log_path}"
    rm -f "${stderr_log}"
    set +e
    (
        sleep 1
        printf 'sendkey a\n'
        printf 'sendkey b\n'
        printf 'sendkey backspace\n'
        printf 'sendkey c\n'
        printf 'sendkey ret\n'
        sleep 5
    ) | timeout --signal=TERM 6s \
        qemu-system-i386 \
        -machine accel=tcg \
        -drive "file=${image_path},format=raw,if=floppy" \
        -boot a \
        -display none \
        -monitor stdio \
        -serial none \
        -debugcon "file:${log_path}" \
        -no-reboot \
        -no-shutdown > /dev/null 2>"${stderr_log}"
    qemu_status=${PIPESTATUS[1]}
    set -e

    [[ "${qemu_status}" == 124 ]] || fail "完整启动 QEMU 应运行到测试超时，实际状态码为 ${qemu_status}"
    assert_file "${log_path}"
    assert_file "${stderr_log}"
    if grep --text --quiet --ignore-case --extended-regexp 'triple fault|cpu reset' "${stderr_log}"; then
        fail 'QEMU 检测到 triple fault 或 CPU reset'
    fi
}

assert_symbol()
{
    local symbol="$1"

    nm -g "${kernel_elf}" | awk '{print $3}' | grep --quiet --fixed-strings "${symbol}" || \
        fail "Kernel ELF 缺少符号: ${symbol}"
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
assert_file "${kernel_elf}"

boot_size="$(stat --format='%s' "${boot_binary}")"
loader_size="$(stat --format='%s' "${loader_binary}")"
kernel_size="$(stat --format='%s' "${kernel_binary}")"
image_size="$(stat --format='%s' "${disk_image}")"
boot_signature="$(od --address-radix=n --format=x1 --skip-bytes=510 --read-bytes=2 "${boot_binary}" | tr -d '[:space:]')"

[[ "${boot_size}" == 512 ]] || fail "引导扇区应为 512 字节，实际为 ${boot_size}"
[[ "${boot_signature}" == 55aa ]] || fail "引导签名应为 55aa，实际为 ${boot_signature}"
((loader_size > 0 && loader_size <= 65024)) || fail "Loader 大小超出 0x9000:0x0100 加载区域"
((kernel_size > 0 && kernel_size <= 65536)) || fail "Kernel 大小超出 0x1000:0x0000 加载区域"
readelf -h "${kernel_elf}" | grep --quiet --extended-regexp 'Class:[[:space:]]+ELF32' || fail 'Kernel ELF 不是 ELF32'
objdump -f "${kernel_elf}" | grep --quiet 'architecture: i386' || fail 'Kernel ELF 目标架构不是 i386'
[[ "${image_size}" == 1474560 ]] || fail "软盘镜像应为 1474560 字节，实际为 ${image_size}"
cmp --silent --bytes=512 "${boot_binary}" "${disk_image}" || fail '镜像首扇区与 boot.bin 不一致'

directory_listing="$(mdir -b -i "${disk_image}" ::)"
grep --quiet --extended-regexp '(^|/)LOADER\.BIN$' <<<"${directory_listing}" || fail 'FAT12 根目录缺少 LOADER.BIN'
grep --quiet --extended-regexp '(^|/)KERNEL\.BIN$' <<<"${directory_listing}" || fail 'FAT12 根目录缺少 KERNEL.BIN'

success_log="${build_dir}/qemu-success.log"
run_observed_qemu "${disk_image}" "${success_log}"

boot_line="$(line_number 'Boot OK' "${success_log}")"
loader_line="$(line_number 'Loader OK' "${success_log}")"
protected_line="$(line_number 'Protected Mode OK' "${success_log}")"
kernel_line="$(line_number 'Kernel OK' "${success_log}")"
[[ -n "${boot_line}" && -n "${loader_line}" && -n "${protected_line}" && -n "${kernel_line}" ]] || \
    fail '完整启动日志缺少预期信息'
((boot_line < loader_line && loader_line < protected_line && protected_line < kernel_line)) || \
    fail '启动信息顺序不正确'
grep --text --quiet --fixed-strings 'Kernel C OK' "${success_log}" || fail 'C 内核入口没有执行'
grep --text --quiet --fixed-strings 'IDT OK' "${success_log}" || fail 'IDT 初始化没有完成'
grep --text --quiet --fixed-strings 'PIC OK' "${success_log}" || fail 'PIC 初始化没有完成'
grep --text --quiet --fixed-strings 'TIMER IRQ OK' "${success_log}" || fail 'Timer IRQ 没有触发'
grep --text --quiet --fixed-strings 'KEYBOARD IRQ OK' "${success_log}" || fail 'Keyboard IRQ 没有触发'
grep --text --quiet --fixed-strings 'KEY a' "${success_log}" || fail '键盘扫描码没有转换为字符'
grep --text --quiet --fixed-strings 'TTY READY' "${success_log}" || fail 'TTY 没有完成初始化'
grep --text --quiet --fixed-strings 'TTY LINE ac' "${success_log}" || fail 'TTY 行编辑或回车提交失败'
grep --text --quiet --fixed-strings 'TTY OK' "${success_log}" || fail 'TTY 行输入没有完成'
grep --text --quiet --fixed-strings 'SCHEDULER OK' "${success_log}" || fail '调度器没有完成三任务轮转'
grep --text --quiet --fixed-strings 'TASK A OK' "${success_log}" || fail 'TaskA 没有运行'
grep --text --quiet --fixed-strings 'TASK B OK' "${success_log}" || fail 'TaskB 没有运行'
grep --text --quiet --fixed-strings 'TASK C OK' "${success_log}" || fail 'TaskC 没有运行'
grep --text --quiet --fixed-strings 'SCHEDULE TaskA' "${success_log}" || fail '调度器没有轮转回 TaskA'
grep --text --quiet --fixed-strings 'SCHEDULE TaskB' "${success_log}" || fail '调度器没有切换到 TaskB'
grep --text --quiet --fixed-strings 'SCHEDULE TaskC' "${success_log}" || fail '调度器没有切换到 TaskC'

task_a_line="$(line_number 'TASK A OK' "${success_log}")"
task_b_line="$(line_number 'TASK B OK' "${success_log}")"
task_c_line="$(line_number 'TASK C OK' "${success_log}")"
((task_a_line < task_b_line && task_b_line < task_c_line)) || fail '任务首次运行顺序不是 A -> B -> C'

for symbol in kernel_entry start_first_process task_a task_b task_c schedule proc_table p_proc_ready; do
    assert_symbol "${symbol}"
done

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
run_observed_qemu "${fragmented_image}" "${fragmented_log}"
grep --text --quiet --fixed-strings 'Kernel OK' "${fragmented_log}" || fail '碎片化 Loader 未能完成启动'

printf '[ok] Boot Sector: 512 字节，签名 55aa。\n'
printf '[ok] FAT12 镜像包含 LOADER.BIN 和 KERNEL.BIN。\n'
printf '[ok] 完整启动链已进入保护模式并执行 Kernel。\n'
printf '[ok] Loader/Kernel 缺失路径均输出明确错误。\n'
printf '[ok] 碎片化 Loader 已通过 FAT12 簇链正确装载。\n'
printf '[ok] C 内核、IDT、PIC、Timer IRQ 和 Keyboard IRQ 均已验证。\n'
printf '[ok] 键盘扫描码已转换并写入字符缓冲区。\n'
printf '[ok] TTY 已完成字符回显、行输入和回车提交。\n'
printf '[ok] 三个独立任务已完成 A -> B -> C 的抢占式轮转。\n'
