#include "const.h"
#include "global.h"
#include "proto.h"

void keyboard_irq(u32 irq)
{
    (void)irq;
    last_scan_code = in_byte(KB_DATA);
    keyboard_irq_count++;
    screen_put_u32(9, 0, "Keyboard IRQ: ", keyboard_irq_count, 0x0f);
    if (keyboard_irq_count == 1) {
        debug_puts("KEYBOARD IRQ OK\r\n");
    }
}

void init_keyboard(void)
{
    irq_table[1] = keyboard_irq;
}
