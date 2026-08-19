#include "const.h"
#include "global.h"
#include "proto.h"

void timer_irq(u32 irq)
{
    (void)irq;
    ticks++;
    screen_put_u32(8, 0, "Timer ticks: ", ticks, 0x0f);
    if (ticks == 10) {
        debug_puts("TIMER IRQ OK\r\n");
    }
    if (ticks >= 10 && keyboard_irq_count != 0) {
        test_complete = 1;
    }
}

void init_timer(void)
{
    u16 divisor = (u16)(TIMER_FREQ / HZ);

    out_byte(TIMER_MODE, 0x34);
    out_byte(TIMER0, (u8)(divisor & 0xff));
    out_byte(TIMER0, (u8)((divisor >> 8) & 0xff));
    irq_table[0] = timer_irq;
}
