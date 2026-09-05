#ifndef ORANGES_PROTO_H
#define ORANGES_PROTO_H

#include "type.h"
#include "proc.h"

void kernel_main(void);
void init_idt(void);
void init_pic(void);
void init_timer(void);
void init_keyboard(void);
void irq_dispatch(u32 irq);
void exception_dispatch(u32 vector);
void spurious_irq(u32 irq);
void timer_irq(u32 irq);
void keyboard_irq(u32 irq);
void init_processes(void);
void schedule(void);
void process_timer_tick(void);
void task_a(void);
void task_b(void);
void task_c(void);

void screen_clear(void);
void screen_puts(u32 row, u32 column, const char *text, u8 color);
void screen_put_u32(u32 row, u32 column, const char *label, u32 value, u8 color);
void debug_puts(const char *text);

void out_byte(u16 port, u8 value);
u8 in_byte(u16 port);
void enable_int(void);
void disable_int(void);

extern void exception0(void);
extern void exception1(void);
extern void exception2(void);
extern void exception3(void);
extern void exception4(void);
extern void exception5(void);
extern void exception6(void);
extern void exception7(void);
extern void exception8(void);
extern void exception9(void);
extern void exception10(void);
extern void exception11(void);
extern void exception12(void);
extern void exception13(void);
extern void exception14(void);
extern void exception15(void);
extern void exception16(void);
extern void exception17(void);
extern void exception18(void);
extern void exception19(void);
extern void exception20(void);
extern void exception21(void);
extern void exception22(void);
extern void exception23(void);
extern void exception24(void);
extern void exception25(void);
extern void exception26(void);
extern void exception27(void);
extern void exception28(void);
extern void exception29(void);
extern void exception30(void);
extern void exception31(void);
extern void irq0(void);
extern void irq1(void);
extern void irq_default(void);
extern void start_first_process(void);

#endif
