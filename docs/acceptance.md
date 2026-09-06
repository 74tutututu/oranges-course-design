# 最终验收清单

验收日期：2026-09-06。

## 构建与格式

- [x] `make check-env` 检查 32 位 freestanding 工具链、mtools、QEMU 和 Pandoc。
- [x] `make clean && make test` 从空构建目录生成完整镜像。
- [x] Boot Sector 为 512 字节且签名为 `55aa`。
- [x] Kernel 为 ELF32/i386，`kernel.bin` 为 14,048 字节，小于 64 KiB 装载上限。
- [x] 所有生成文件写入 `build/`，提交的截图和报告除外。

## 功能

- [x] FAT12 Boot Sector、碎片簇链 Loader、保护模式与 C Kernel。
- [x] IDT、8259A、100 Hz Timer、键盘 IRQ 和异常停机路径。
- [x] TaskA/TaskB/TaskC 抢占轮转及动态子进程。
- [x] 扫描码翻译、键盘环形缓冲、TTY 回显/退格/回车/滚屏。
- [x] `int 0x80` 与 `open/read/write/close/stat/unlink`。
- [x] fork/exec/wait/exit 的栈复制、阻塞、唤醒和回收。
- [x] help、clear、未知命令、cat、stat、rm、ps。
- [x] 删除后 stat、cat/rm 不存在文件等错误路径。

## 交付物

- [x] README 阅读导航与快速开始。
- [x] `docs/report.md` 和生成的 Word 报告。
- [x] `docs/defense.md` 答辩结构、演示步骤和常见问题。
- [x] `docs/progress.md` 个人工作量与提交证据。
- [x] M2–M8 关键截图，最终图为 `assets/screenshots/m8-final.png`。
- [x] GitHub Actions 在 Ubuntu 24.04 容器中执行工具链与完整启动测试。

## 已知限制

- RAM FS 不持久化，文件数量和大小固定。
- 命令程序共享 Ring 0 地址空间，没有页表和用户态隔离。
- Shell 只解析命令名和一个文件参数，不支持管道、重定向和后台任务。
