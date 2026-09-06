#include "fs.h"
#include "global.h"
#include "proc.h"
#include "proto.h"
#include "syscall.h"

static u8 syscall_reported;

void syscall_dispatch(STACK_FRAME *frame)
{
    int result;
    u32 owner = p_proc_ready->pid;

    if (!syscall_reported) {
        syscall_reported = 1;
        debug_puts("SYSCALL INT OK\r\n");
    }

    switch (frame->eax) {
    case SYS_WRITE:
        if ((int)frame->ebx == FS_STDOUT) {
            u32 index;
            const char *buffer = (const char *)frame->ecx;

            for (index = 0; index < frame->edx; index++) {
                console_putc(buffer[index]);
            }
            result = (int)frame->edx;
        } else {
            result = fs_write(owner, (int)frame->ebx, (const char *)frame->ecx, frame->edx);
        }
        break;
    case SYS_OPEN:
        result = fs_open(owner, (const char *)frame->ebx, frame->ecx);
        break;
    case SYS_READ:
        result = fs_read(owner, (int)frame->ebx, (char *)frame->ecx, frame->edx);
        break;
    case SYS_CLOSE:
        result = fs_close(owner, (int)frame->ebx);
        break;
    case SYS_STAT:
        result = fs_stat((const char *)frame->ebx, (FILE_STAT *)frame->ecx);
        break;
    case SYS_UNLINK:
        result = fs_unlink((const char *)frame->ebx);
        break;
    case SYS_FORK:
        result = process_fork(frame);
        break;
    case SYS_EXEC:
        result = process_exec(frame, (const char *)frame->ebx, (const char *)frame->ecx);
        break;
    case SYS_WAIT:
        result = process_wait(frame->ebx, (int *)frame->ecx);
        break;
    case SYS_EXIT:
        process_exit((int)frame->ebx);
        result = 0;
        break;
    case SYS_PROCESS_LIST:
        result = process_list((PROCESS_INFO *)frame->ebx, frame->ecx);
        break;
    default:
        result = SYS_ERR_INVAL;
        break;
    }

    frame->eax = (u32)result;
}
