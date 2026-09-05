# 工作量与进度记录

课程评分中个人工作量占 30%。每项工作合并后更新本表，并保留可以复核的提交、测试输出或截图。

| 日期 | 成员 | 工作内容 | 提交或文件 | 验证证据 |
| --- | --- | --- | --- | --- |
| 2026-07-20 | 徐千顺 | 初始化仓库骨架、开发容器和课程文档 | `chore: initialize OrangeS course design repository` | `make docker-check` |
| 2026-07-27 | 徐千顺 | 实现 512 字节 Boot Sector、软盘镜像构建和 QEMU 启动测试 | `boot/boot.asm`、`tests/test-boot.sh` | `make docker-test` |
| 2026-08-18 | 徐千顺 | 实现 FAT12 Loader、保护模式切换和最小 32 位 Kernel | `boot/loader.asm`、`kernel/kernel.asm` | `make docker-test`、`assets/screenshots/m2-protected-mode.png` |
| 2026-08-19 | 徐千顺 | 实现 C 内核入口、IDT、8259A PIC、PIT Timer IRQ 和 Keyboard IRQ | `kernel/*.c`、`kernel/kernel.asm`、`kernel/linker.ld` | `make docker-test`、`assets/screenshots/m3-interrupts.png` |
| 2026-09-05 | 徐千顺 | 实现三个内核级任务、独立任务栈、Timer 抢占式轮转和上下文恢复 | `include/proc.h`、`kernel/proc.c`、`kernel/kernel.asm` | `make docker-test`、`assets/screenshots/m4-processes.png` |

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
