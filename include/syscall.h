#ifndef ORANGES_SYSCALL_H
#define ORANGES_SYSCALL_H

#include "fs.h"
#include "proc.h"
#include "type.h"

#define SYS_WRITE 0
#define SYS_OPEN 1
#define SYS_READ 2
#define SYS_CLOSE 3
#define SYS_STAT 4
#define SYS_UNLINK 5
#define SYS_FORK 6
#define SYS_EXEC 7
#define SYS_WAIT 8
#define SYS_EXIT 9
#define SYS_PROCESS_LIST 10

#define SYS_ERR_NOENT -2
#define SYS_ERR_BADF -9
#define SYS_ERR_CHILD -10
#define SYS_ERR_BUSY -16
#define SYS_ERR_INVAL -22
#define SYS_ERR_NOSPC -28

int sys_write(int fd, const char *buffer, u32 count);
int sys_open(const char *path, u32 flags);
int sys_read(int fd, char *buffer, u32 count);
int sys_close(int fd);
int sys_stat(const char *path, FILE_STAT *stat);
int sys_unlink(const char *path);
int sys_fork(void);
int sys_exec(const char *name, const char *argument);
int sys_wait(u32 pid, int *status);
void sys_exit(int status);
int sys_process_list(PROCESS_INFO *buffer, u32 capacity);

#endif
