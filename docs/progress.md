# 工作量与进度记录

课程评分中个人工作量占 30%。每项工作合并后更新本表，并保留可以复核的提交、测试输出或截图。

| 日期 | 成员 | 工作内容 | 提交或文件 | 验证证据 |
| --- | --- | --- | --- | --- |
| 2026-07-20 | 徐千顺 | 初始化仓库骨架、开发容器和课程文档 | `chore: initialize OrangeS course design repository` | `make docker-check` |
| 2026-07-27 | 徐千顺 | 实现 512 字节 Boot Sector、软盘镜像构建和 QEMU 启动测试 | `boot/boot.asm`、`tests/test-boot.sh` | `make docker-test` |
| 2026-08-18 | 徐千顺 | 实现 FAT12 Loader、保护模式切换和最小 32 位 Kernel | `boot/loader.asm`、`kernel/kernel.asm` | `make docker-test`、`assets/screenshots/m2-protected-mode.png` |
| 2026-08-19 | 徐千顺 | 实现 C 内核入口、IDT、8259A PIC、PIT Timer IRQ 和 Keyboard IRQ | `kernel/*.c`、`kernel/kernel.asm`、`kernel/linker.ld` | `make docker-test`、`assets/screenshots/m3-interrupts.png` |
| 2026-09-05 | 徐千顺 | 实现三个内核级任务、独立任务栈、Timer 抢占式轮转和上下文恢复 | `include/proc.h`、`kernel/proc.c`、`kernel/kernel.asm` | `make docker-test`、`assets/screenshots/m4-processes.png` |
| 2026-09-06 | 赵晴 | 实现扫描码翻译、Shift/Caps Lock 状态和 IRQ 到任务的键盘环形缓冲 | `5e55e2c` | `make test`、日志 `KEY a` |
| 2026-09-06 | 赵晴 | 实现 VGA 文本控制台、TTY 回显、退格、行提交与滚屏 | `0ad08bf` | `make test`、`assets/screenshots/m5-tty.png` |
| 2026-09-06 | 赵晴 | 实现 `int 0x80` 调用门、用户封装和 RAM 文件系统基础操作 | `3dfaf33` | `make test`、日志 `FS SYSCALLS OK` |
| 2026-09-06 | 赵晴 | 实现动态进程槽位、fork 栈复制、exec 入口替换、wait 阻塞与退出唤醒 | `52338a8` | `make test`、`assets/screenshots/m6-syscalls.png` |
| 2026-09-06 | 赵晴 | 实现 Shell 行解析、`help`、`clear` 与未知命令提示 | `01acdeb` | `make test`、日志 `SHELL HELP/CLEAR/UNKNOWN OK` |
| 2026-09-06 | 赵晴 | 实现经 fork/exec/wait 启动的 `cat`、`stat`、`rm` 命令 | `0a1cc1f` | `make test`、`assets/screenshots/m7-shell.png` |
| 2026-09-06 | 赵晴 | 清理动态进程名显示残影并稳定 QEMU 键盘注入时序 | `182349f` | `make test`、`assets/screenshots/m7-shell.png` |

## 问题与解决记录

- M6 首次实现 `fork` 时只复制了栈内容和中断返回现场，子进程恢复后的 EBP 仍指向父栈，表现为子进程被反复调度但无法进入 `exec`。最终在复制栈后沿保存的调用帧链重定位 EBP，QEMU 日志恢复为 `forked -> EXEC CHILD OK -> TaskA -> FORK EXEC WAIT OK`。

## 记录要求

- 一行只记录一个可以独立说明的成果，不使用“参与开发”等模糊描述。
- 提交字段使用提交哈希、PR 链接或明确文件路径。
- 验证证据使用测试命令、日志路径、截图路径或演示步骤。
- 双人共同完成的任务分别说明设计、实现、测试或文档责任。
- 遇到的问题和解决过程同步整理到项目报告，不只保留最终结果。

## 新记录模板

```text
| YYYY-MM-DD | 姓名 | 具体实现或文档成果 | commit/PR/path | command/log/screenshot |
```
