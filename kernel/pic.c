#include "const.h"
#include "global.h"
#include "proto.h"

void init_pic(void)
{
    out_byte(INT_M_CTL, 0x11);
    out_byte(INT_S_CTL, 0x11);
    out_byte(INT_M_CTLMASK, INT_VECTOR_IRQ0);
    out_byte(INT_S_CTLMASK, INT_VECTOR_IRQ8);
    out_byte(INT_M_CTLMASK, 0x04);
    out_byte(INT_S_CTLMASK, 0x02);
    out_byte(INT_M_CTLMASK, 0x01);
    out_byte(INT_S_CTLMASK, 0x01);

    /* Only the timer and keyboard IRQs are enabled in M3. */
    out_byte(INT_M_CTLMASK, 0xfc);
    out_byte(INT_S_CTLMASK, 0xff);
}

void spurious_irq(u32 irq)
{
    (void)irq;
}

void irq_dispatch(u32 irq)
{
    if (irq < NR_IRQ && irq_table[irq] != 0) {
        irq_table[irq](irq);
    }
}
