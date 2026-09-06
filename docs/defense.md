# OrangeS 课程设计答辩提纲

建议控制在 8–10 分钟，演示前先执行一次 `make test` 并保留终端结果。

## 幻灯片结构

1. 选题与目标：自主实现可启动、可交互、可测试的 x86 OS 雏形。
2. 小组分工：徐千顺负责 M0–M4；赵晴负责 M5–M8，并展示对应提交。
3. 启动链：BIOS、Boot Sector、FAT12 Loader、保护模式、Kernel。
4. 中断与调度：64 字节现场、100 Hz Timer、5 tick 时间片、三个常驻任务。
5. 输入输出：扫描码、环形缓冲、TTY 行编辑、VGA 局部滚屏。
6. 系统调用与文件：`int 0x80` ABI、RAM FS、正常与失败返回。
7. 进程生命周期：fork 栈复制、EBP 重定位、exec EIP 替换、wait/exit 唤醒。
8. Shell 与扩展：help、clear、cat、stat、rm、ps 的分层与调用链。
9. 自动测试：缺失文件、碎片簇链、IRQ、调度、命令与错误路径。
10. 已知限制与总结：Ring 0、RAM FS、固定容量，以及后续页表和磁盘持久化方向。

## 推荐现场演示

```text
help
ps
cat hello.txt
stat hello.txt
rm hello.txt
stat hello.txt
clear
```

讲解要点：

- `ps` 中 TaskA 为 WAIT、`ps` 为 RUN，说明 Shell 确实在等待子进程。
- `cat/stat/rm` 只使用系统调用，不直接访问 `file_table`。
- 删除后再次 `stat` 显示不存在，用于演示错误路径。
- 上方 TaskA/B/C 计数持续变化，说明 Shell 交互没有破坏抢占调度。

## 赵晴部分讲解顺序

1. 从 Keyboard IRQ 到 TTY 的数据路径，以及为什么 IRQ 只入队。
2. `int 0x80` 寄存器 ABI 和统一 `STACK_FRAME`。
3. RAM FS 的容量、句柄所有者和错误码。
4. fork 首次失败现象、EBP 指向父栈的根因与帧链重定位。
5. Shell 如何用 fork/exec/wait 启动命令，`ps` 如何通过快照接口隔离内部表。
6. QEMU 自动按键、debugcon 标志和最终测试结果。

## 常见提问准备

### 为什么使用 RAM FS？

课程主线要求验证文件接口和系统调用控制流。RAM FS 将磁盘驱动与缓存一致性的复杂度隔离，使 `open/read/write/stat/unlink`、进程所有者和错误路径可重复验证。限制已在报告中明确，后续可替换服务实现而保持调用 ABI。

### 这是不是完整的用户态进程？

不是。程序通过真实 `int 0x80` 调用门和独立任务栈运行，但仍共享 Ring 0 平坦地址空间。项目没有声称实现页表隔离或完整 Ring 3；这是当前最重要的已知限制。

### 如何证明 fork/exec/wait 不是只改状态？

fork 会复制 8 KiB 任务栈和返回现场，子进程由 Timer 调度恢复；exec 修改 IRET 的 EIP；wait 把 TaskA 置为 BLOCKED；exit 写回状态并唤醒。debugcon 顺序和 `ps` 的 WAIT/RUN 状态提供运行证据。

### 如何保证没有只测试成功路径？

自动测试覆盖 Loader/Kernel 缺失、碎片化 Loader、删除后 stat、cat/rm 不存在文件，以及 QEMU triple fault/CPU reset 检测。

### 代码参考边界是什么？

随书源码用于理解模块划分和机制。仓库未包含参考源码或镜像；各阶段的自定义内存布局、ABI、固定现场、RAM FS、命令和测试均在 `docs/references.md` 记录。
