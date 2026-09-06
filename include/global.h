#ifndef ORANGES_GLOBAL_H
#define ORANGES_GLOBAL_H

#include "const.h"
#include "protect.h"
#include "proc.h"
#include "type.h"

extern volatile u32 ticks;
extern volatile u32 keyboard_irq_count;
extern volatile u8 last_scan_code;
extern struct gate idt[IDT_SIZE];
extern u8 idt_ptr[6];
extern irq_handler irq_table[NR_IRQ];
extern PROCESS proc_table[NR_PROCS];
extern PROCESS *p_proc_ready;
extern u32 task_stacks[TASK_STACK_TOTAL / sizeof(u32)];
extern volatile u32 schedule_count;
extern volatile u32 task_run_count[NR_BOOT_PROCS];

#endif
