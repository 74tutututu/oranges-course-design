#include "const.h"
#include "global.h"
#include "proto.h"

void timer_irq(u32 irq)
{
    (void)irq;
    ticks++;
    process_timer_tick();
    screen_put_u32(8, 0, "Timer ticks: ", ticks, 0x0f);
    screen_put_u32(16, 0, "Context switches: ", schedule_count, 0x0f);
    if (ticks == 10) {
        debug_puts("TIMER IRQ OK\r\n");
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
