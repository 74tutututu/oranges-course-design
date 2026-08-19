#ifndef ORANGES_CONST_H
#define ORANGES_CONST_H

#define IDT_SIZE 256
#define NR_IRQ 16

#define INT_VECTOR_IRQ0 0x20
#define INT_VECTOR_IRQ8 0x28

#define INT_M_CTL 0x20
#define INT_M_CTLMASK 0x21
#define INT_S_CTL 0xa0
#define INT_S_CTLMASK 0xa1

#define TIMER0 0x40
#define TIMER_MODE 0x43
#define TIMER_FREQ 1193182L
#define HZ 100

#define KB_DATA 0x60

#define V_MEM_BASE 0xb8000
#define VGA_COLUMNS 80
#define VGA_ROWS 25

#define DEBUG_PORT 0xe9
#define EXIT_PORT 0xf4

#endif
