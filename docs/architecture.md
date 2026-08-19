# 计划架构

本文件描述目标结构、当前启动链和模块责任。M3 已形成可验证的 C 内核、IDT、PIC、PIT 和键盘中断基础。

## 启动与运行链路

```text
BIOS
  -> Boot Sector（FAT12 查找 LOADER.BIN）
  -> Loader（加载 KERNEL.BIN、A20、GDT、保护模式）
  -> 32 位 Kernel 入口
  -> C 内核、IDT、PIC、PIT 和键盘 IRQ
  -> 进程调度
  -> TTY / 控制台
  -> MM 与 FS 服务
  -> 系统调用与用户态库
  -> Shell 和命令程序
```

## M2 内存布局

| 物理地址 | 用途 |
| --- | --- |
| `0x07c00` | BIOS 加载的 512 字节 Boot Sector |
| `0x10000` | Loader 装载的平坦 32 位 Kernel |
| `0x70000` | Loader 的 FAT12 根目录和 FAT 临时缓冲区 |
| `0x80000` | Boot Sector 的 FAT 临时缓冲区 |
| `0x90100` | Boot Sector 装载的 `LOADER.BIN` |
| `0x9f000` | 保护模式临时栈顶 |
| `0xb8000` | VGA 文本显存 |

## 启动交接契约

- Boot Sector 通过 `DL` 向 Loader 传递 BIOS 启动驱动器号，Loader 入口为 `0x9000:0x0100`。
- Loader 使用 `0x08` 平坦代码段和 `0x10` 平坦数据段，开启 A20 后设置 `CR0.PE`。
- Kernel 入口为线性地址 `0x10000`；进入时 CPU 已处于 32 位保护模式，`ESP=0x9f000`，中断关闭。
- M3 的 Kernel 在安装 IDT、PIC、PIT 和 Keyboard IRQ 后才执行 `sti`；发生异常时进入统一停机处理，避免无提示 triple fault。

M3 完成后的内核初始化顺序为：

```text
kernel_entry
  -> kernel_main
  -> init_idt
  -> init_pic
  -> init_timer
  -> init_keyboard
  -> sti
  -> hlt idle loop
```

M3 的 IDT 使用 `0x08` 代码选择子，PIC 将 IRQ0/IRQ1 映射到 `0x20/0x21`；Timer 频率为 100 Hz，Keyboard 读取端口 `0x60` 的原始扫描码。

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
