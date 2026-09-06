#include "const.h"
#include "global.h"
#include "protect.h"
#include "proto.h"

volatile u32 ticks;
volatile u32 keyboard_irq_count;
volatile u8 last_scan_code;
struct gate idt[IDT_SIZE];
u8 idt_ptr[6];
irq_handler irq_table[NR_IRQ];

extern u32 exception_stub_table[32];
extern u32 irq_stub_table[16];

static void set_idt_gate(u32 vector, u32 handler)
{
    idt[vector].offset_low = (u16)(handler & 0xffff);
    idt[vector].selector = SELECTOR_KERNEL_CS;
    idt[vector].dcount = 0;
    idt[vector].attr = DA_386IGATE;
    idt[vector].offset_high = (u16)((handler >> 16) & 0xffff);
}

static void write_u32_decimal(u32 value, u32 row, u32 column, u8 color)
{
    char digits[11];
    u32 length = 0;

    if (value == 0) {
        digits[length++] = '0';
    } else {
        while (value != 0) {
            digits[length++] = (char)('0' + value % 10);
            value /= 10;
        }
    }

    while (length != 0) {
        volatile u16 *video = (volatile u16 *)V_MEM_BASE;
        u32 index = row * VGA_COLUMNS + column++;
        video[index] = (u16)(color << 8) | (u8)digits[--length];
    }
}

void screen_clear(void)
{
    volatile u16 *video = (volatile u16 *)V_MEM_BASE;
    u32 i;

    for (i = 0; i < VGA_COLUMNS * VGA_ROWS; i++) {
        video[i] = 0x0700 | ' ';
    }
}

void screen_puts(u32 row, u32 column, const char *text, u8 color)
{
    volatile u16 *video = (volatile u16 *)V_MEM_BASE;

    while (*text != 0 && column < VGA_COLUMNS) {
        video[row * VGA_COLUMNS + column++] = (u16)(color << 8) | (u8)*text++;
    }
}

void screen_put_u32(u32 row, u32 column, const char *label, u32 value, u8 color)
{
    screen_puts(row, column, label, color);
    column += 0;
    while (*label != 0) {
        label++;
        column++;
    }
    write_u32_decimal(value, row, column, color);
}

void debug_puts(const char *text)
{
    while (*text != 0) {
        out_byte(DEBUG_PORT, (u8)*text++);
    }
}

void init_idt(void)
{
    u32 i;
    u32 base = (u32)idt;

    for (i = 0; i < IDT_SIZE; i++) {
        set_idt_gate(i, (u32)irq_default);
    }
    for (i = 0; i < 32; i++) {
        set_idt_gate(i, exception_stub_table[i]);
    }
    for (i = 0; i < NR_IRQ; i++) {
        set_idt_gate(INT_VECTOR_IRQ0 + i, irq_stub_table[i]);
    }
    set_idt_gate(INT_VECTOR_SYS_CALL, (u32)syscall_entry);
    idt[INT_VECTOR_SYS_CALL].attr = DA_386IGATE_USER;

    idt_ptr[0] = (u8)((sizeof(idt) - 1) & 0xff);
    idt_ptr[1] = (u8)(((sizeof(idt) - 1) >> 8) & 0xff);
    idt_ptr[2] = (u8)(base & 0xff);
    idt_ptr[3] = (u8)((base >> 8) & 0xff);
    idt_ptr[4] = (u8)((base >> 16) & 0xff);
    idt_ptr[5] = (u8)((base >> 24) & 0xff);

    __asm__ volatile("lidtl %0" : : "m"(idt_ptr));
}

void kernel_main(void)
{
    u32 i;

    ticks = 0;
    keyboard_irq_count = 0;
    last_scan_code = 0;
    init_processes();
    init_process_service();
    fs_init();
    init_system_selftest();
    shell_init();
    for (i = 0; i < NR_IRQ; i++) {
        irq_table[i] = spurious_irq;
    }

    screen_puts(4, 0, "Kernel OK", 0x0f);
    debug_puts("Kernel OK\r\n");
    screen_puts(5, 0, "Kernel C OK", 0x0f);
    debug_puts("Kernel C OK\r\n");

    init_idt();
    screen_puts(6, 0, "IDT OK", 0x0f);
    debug_puts("IDT OK\r\n");

    init_pic();
    screen_puts(7, 0, "PIC OK", 0x0f);
    debug_puts("PIC OK\r\n");

    init_timer();
    init_keyboard();
    tty_init();
    screen_puts(10, 0, "Current task: TaskA", 0x0f);
    screen_put_u32(12, 0, "TaskA runs: ", 0, 0x0f);
    screen_put_u32(13, 0, "TaskB runs: ", 0, 0x0f);
    screen_put_u32(14, 0, "TaskC runs: ", 0, 0x0f);
    disable_int();
    start_first_process();
}
