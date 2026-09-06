#include "fs.h"
#include "syscall.h"
#include "type.h"

static int invoke_syscall(u32 number, u32 first, u32 second, u32 third)
{
    int result;

    __asm__ volatile("int $0x80"
                     : "=a"(result)
                     : "a"(number), "b"(first), "c"(second), "d"(third)
                     : "memory");
    return result;
}

int sys_write(int fd, const char *buffer, u32 count)
{
    return invoke_syscall(SYS_WRITE, (u32)fd, (u32)buffer, count);
}

int sys_open(const char *path, u32 flags)
{
    return invoke_syscall(SYS_OPEN, (u32)path, flags, 0);
}

int sys_read(int fd, char *buffer, u32 count)
{
    return invoke_syscall(SYS_READ, (u32)fd, (u32)buffer, count);
}

int sys_close(int fd)
{
    return invoke_syscall(SYS_CLOSE, (u32)fd, 0, 0);
}

int sys_stat(const char *path, FILE_STAT *stat)
{
    return invoke_syscall(SYS_STAT, (u32)path, (u32)stat, 0);
}

int sys_unlink(const char *path)
{
    return invoke_syscall(SYS_UNLINK, (u32)path, 0, 0);
}

int sys_fork(void)
{
    return invoke_syscall(SYS_FORK, 0, 0, 0);
}

int sys_exec(const char *name, const char *argument)
{
    return invoke_syscall(SYS_EXEC, (u32)name, (u32)argument, 0);
}

int sys_wait(u32 pid, int *status)
{
    return invoke_syscall(SYS_WAIT, pid, (u32)status, 0);
}

void sys_exit(int status)
{
    invoke_syscall(SYS_EXIT, (u32)status, 0, 0);
}

int sys_process_list(PROCESS_INFO *buffer, u32 capacity)
{
    return invoke_syscall(SYS_PROCESS_LIST, (u32)buffer, capacity, 0);
}
