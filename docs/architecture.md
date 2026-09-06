# 系统架构

本文件描述最终结构、启动链和模块责任。M8 已完成进程快照、最终回归与交付材料。

## 启动与运行链路

```text
BIOS
  -> Boot Sector（FAT12 查找 LOADER.BIN）
  -> Loader（加载 KERNEL.BIN、A20、GDT、保护模式）
  -> 32 位 Kernel 入口
  -> C 内核、IDT、PIC、PIT 和键盘 IRQ
  -> Timer 抢占式进程调度
  -> TTY / 控制台
  -> MM 与 FS 服务
  -> 系统调用与用户态库
  -> Shell 和命令程序
```

## 内存布局

| 物理地址 | 用途 |
| --- | --- |
| `0x07c00` | BIOS 加载的 512 字节 Boot Sector |
| `0x10000` | Loader 装载的平坦 32 位 Kernel |
| `0x70000` | Loader 的 FAT12 根目录和 FAT 临时缓冲区 |
| `0x80000` | Boot Sector 的 FAT 临时缓冲区 |
| `0x90100` | Boot Sector 装载的 `LOADER.BIN` |
| `0x9f000` | 保护模式临时栈顶 |
| `0xb8000` | VGA 文本显存 |

任务栈由 Kernel `.bss` 中的 `task_stacks[3][0x2000]` 提供；每个任务初始化为一个包含段寄存器、`pushad` 寄存器组、IRQ 占位和 `iretd` 返回现场的 64 字节 `STACK_FRAME`。

## 启动交接契约

- Boot Sector 通过 `DL` 向 Loader 传递 BIOS 启动驱动器号，Loader 入口为 `0x9000:0x0100`。
- Loader 使用 `0x08` 平坦代码段和 `0x10` 平坦数据段，开启 A20 后设置 `CR0.PE`。
- Kernel 入口为线性地址 `0x10000`；进入时 CPU 已处于 32 位保护模式，`ESP=0x9f000`，中断关闭。
- M3 的 Kernel 在安装 IDT、PIC、PIT 和 Keyboard IRQ 后才执行 `sti`；发生异常时进入统一停机处理，避免无提示 triple fault。

M4 完成后的内核初始化顺序为：

```text
kernel_entry
  -> kernel_main
  -> init_idt
  -> init_pic
  -> init_timer
  -> init_keyboard
  -> disable_int
  -> start_first_process（从预构造 STACK_FRAME 执行 iretd）
```

M3 的 IDT 使用 `0x08` 代码选择子，PIC 将 IRQ0/IRQ1 映射到 `0x20/0x21`；Timer 频率为 100 Hz，Keyboard 读取端口 `0x60` 的原始扫描码。M4 在 IRQ0 上使用固定 5 tick 时间片轮转三个 Ring 0 任务。

## M4 调度路径

```text
Timer IRQ0
  -> irq_common 保存当前任务 STACK_FRAME
  -> irq_dispatch(0)
  -> process_timer_tick()
  -> schedule()（每 5 tick 轮转）
  -> 从 p_proc_ready->saved_esp 恢复段寄存器和通用寄存器
  -> iretd 返回下一个任务
```

M4 的三个任务均运行在 Ring 0，共享 Loader 提供的平坦代码段和数据段；任务函数不返回，暂不使用 LDT、用户栈或用户态权限。

## M5 输入输出路径

```text
Keyboard IRQ1
  -> keyboard_irq() 读取 Set 1 扫描码
  -> 翻译 Shift / Caps Lock / 可打印字符
  -> 写入 128 字节键盘环形缓冲区
  -> TaskA 中的 tty_poll() 非阻塞读取
  -> 行编辑与 console_putc() 回显
  -> 回车提交完整输入行
```

控制台使用 VGA 文本模式的第 18 至 24 行，保留上方 M4 调度状态区域。字符写入统一经过 `console_putc()`，由该函数维护硬件光标、自动换行、Tab 展开和区域滚屏。TTY 输入缓冲区为 64 字节，支持可打印 ASCII、退格和回车；键盘中断只翻译和入队，不在 IRQ 上下文执行行处理。

## M6 系统调用与文件系统

```text
lib/syscall.c 封装
  -> int 0x80
  -> syscall_entry 保存与 IRQ 相同的 64 字节 STACK_FRAME
  -> syscall_dispatch() 按 EAX 调用号分发 EBX/ECX/EDX 参数
  -> fs/ 或 mm/ 服务
  -> 将返回值写入保存的 EAX
  -> iretd 返回调用者或调度后的进程
```

系统调用号 0 至 5 依次为 `write/open/read/close/stat/unlink`。RAM FS 最多保存 8 个命名文件，每个文件上限 512 字节；文件描述符从 3 开始，记录所有者、文件位置和打开标志。系统启动时提供 `readme.txt` 与 `hello.txt`，内容不写回 FAT12 启动盘。

调用号 6 至 9 依次为 `fork/exec/wait/exit`。进程表有 8 个槽位，其中前三个保留 M4 常驻任务。`fork` 复制当前 8 KiB 任务栈和系统调用现场，并重定位保存的 EBP 调用帧链；`exec` 将 IRET 返回地址替换为注册程序入口；`wait` 将父进程置为阻塞态，子进程 `exit` 后写回状态、唤醒父进程并回收槽位。

## M7 Shell 与命令

```text
TTY 回车提交
  -> shell_execute() 分离命令名与单个文件参数
  -> help / clear 在 Shell 进程内执行
  -> cat / stat / rm 执行 fork()
       -> 子进程 exec() 到注册入口
       -> 命令通过 open/read/write/stat/unlink 系统调用工作
       -> exit() 唤醒 wait() 中的 Shell
  -> 输出下一条 OrangeS> 提示符
```

`command/shell.c` 只负责解析、内建命令和进程启动，`command/commands.c` 不访问 FS 内部表。`cat` 分块读取并写到标准输出，`stat` 展示 inode 与字节数，`rm` 报告删除结果；缺少参数和文件不存在都有可见提示。

## M8 进程快照

`ps` 与其他外部命令一样经 fork/exec/wait 启动。命令使用调用号 10 请求最多 `NR_PROCS` 条 `PROCESS_INFO`，MM 只复制非空槽位的 PID、PPID、状态和名称。该只读快照避免命令层依赖 `proc_table` 布局，也不会把内部栈地址、等待指针等字段暴露给调用者。

## 模块边界

- `boot/` 负责 FAT12 文件装载、早期硬件状态、保护模式切换和内核交接。
- `kernel/` 管理内核入口、中断、调度、TTY、控制台和硬件驱动。
- `mm/` 管理进程生命周期和可执行程序装载，不直接处理 Shell 命令语义。
- `fs/` 管理磁盘文件、文件描述符和文件系统消息。
- `lib/` 提供公共运行库和用户态系统调用封装。
- `command/` 包含 Shell 及独立命令，不直接访问内核内部数据结构。
- `include/` 只保存跨模块共享的类型、常量和接口声明。

## 设计约束

- 目标平台为 32 位 x86，构建参数必须显式指定目标架构并禁用不适合裸机环境的宿主特性。
- 生成磁盘镜像时使用 mtools 或普通文件操作，避免依赖 `sudo mount`。
- 当前镜像为标准 1.44 MB FAT12，根目录包含 `LOADER.BIN` 和 `KERNEL.BIN`。
- 构建产物统一写入 `build/`，不提交镜像、目标文件和模拟器日志。
- QEMU 是默认自动验证环境；涉及指令级或硬件状态调试时可以补充 Bochs 配置。
- 新增系统调用必须同时说明调用号、内核处理路径、用户态封装、错误行为和测试场景。
