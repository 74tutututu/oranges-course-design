#ifndef ORANGES_PROTO_H
#define ORANGES_PROTO_H

#include "type.h"
#include "fs.h"
#include "proc.h"

void kernel_main(void);
void init_idt(void);
void init_pic(void);
void init_timer(void);
void init_keyboard(void);
int keyboard_getchar(void);
void irq_dispatch(u32 irq);
void exception_dispatch(u32 vector);
void spurious_irq(u32 irq);
void timer_irq(u32 irq);
void keyboard_irq(u32 irq);
void init_processes(void);
void init_process_service(void);
void schedule(void);
void process_timer_tick(void);
int process_register_program(const char *name, void (*entry)(void));
int process_fork(STACK_FRAME *frame);
int process_exec(STACK_FRAME *frame, const char *name, const char *argument);
int process_wait(u32 pid, int *status);
void process_exit(int status);
const char *process_argument(void);
void task_a(void);
void task_b(void);
void task_c(void);
void tty_init(void);
void tty_poll(void);
void init_system_selftest(void);
void run_system_selftest(void);

void fs_init(void);
int fs_open(u32 owner, const char *path, u32 flags);
int fs_read(u32 owner, int fd, char *buffer, u32 count);
int fs_write(u32 owner, int fd, const char *buffer, u32 count);
int fs_close(u32 owner, int fd);
int fs_stat(const char *path, FILE_STAT *stat);
int fs_unlink(const char *path);
void fs_close_process(u32 owner);

void syscall_dispatch(STACK_FRAME *frame);

void screen_clear(void);
void screen_puts(u32 row, u32 column, const char *text, u8 color);
void screen_put_u32(u32 row, u32 column, const char *label, u32 value, u8 color);
void console_init(void);
void console_clear(void);
void console_putc(char character);
void console_write(const char *text);
void debug_puts(const char *text);

u32 string_length(const char *text);
int string_compare(const char *left, const char *right);
void string_copy(char *destination, const char *source, u32 capacity);

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
extern void syscall_entry(void);
extern void start_first_process(void);

#endif
