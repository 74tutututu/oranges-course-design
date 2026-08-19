#ifndef ORANGES_GLOBAL_H
#define ORANGES_GLOBAL_H

#include "const.h"
#include "protect.h"
#include "type.h"

extern volatile u32 ticks;
extern volatile u32 keyboard_irq_count;
extern volatile u8 last_scan_code;
extern volatile u32 test_complete;
extern struct gate idt[IDT_SIZE];
extern u8 idt_ptr[6];
extern irq_handler irq_table[NR_IRQ];

#endif
