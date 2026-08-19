#include "global.h"
#include "proto.h"

void exception_dispatch(u32 vector)
{
    disable_int();
    screen_put_u32(12, 0, "Exception vector: ", vector, 0x4f);
    debug_puts("EXCEPTION\r\n");
    while (1) {
        __asm__ volatile("hlt");
    }
}
