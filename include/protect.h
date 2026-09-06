#ifndef ORANGES_PROTECT_H
#define ORANGES_PROTECT_H

#include "type.h"

struct gate {
    u16 offset_low;
    u16 selector;
    u8 dcount;
    u8 attr;
    u16 offset_high;
};

#define SELECTOR_KERNEL_CS 0x08
#define SELECTOR_KERNEL_DS 0x10

#define DA_386IGATE 0x8e
#define DA_386IGATE_USER 0xee
#define PRIVILEGE_KERNEL 0

#endif
