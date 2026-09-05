#ifndef ORANGES_PROC_H
#define ORANGES_PROC_H

#include "type.h"

/* The layout matches kernel/kernel.asm's IRQ save/restore sequence. */
typedef struct stack_frame {
    u32 gs;
    u32 fs;
    u32 es;
    u32 ds;
    u32 edi;
    u32 esi;
    u32 ebp;
    u32 esp_ignored;
    u32 ebx;
    u32 edx;
    u32 ecx;
    u32 eax;
    u32 irq;
    u32 eip;
    u32 cs;
    u32 eflags;
} STACK_FRAME;

typedef char stack_frame_size_must_be_64_bytes[
    sizeof(STACK_FRAME) == 64 ? 1 : -1];

typedef struct process {
    u32 saved_esp;
    u32 pid;
    u32 ticks;
    u32 priority;
    u32 run_count;
    u32 state;
    char name[16];
    STACK_FRAME initial_frame;
} PROCESS;

#define NR_PROCS 3
#define PROCESS_STATE_RUNNABLE 0
#define PROCESS_QUANTUM 5

#define TASK_STACK_SIZE 0x2000
#define TASK_STACK_TOTAL (NR_PROCS * TASK_STACK_SIZE)

#endif
