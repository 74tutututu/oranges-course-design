#include "const.h"
#include "global.h"
#include "proto.h"

static volatile char keyboard_buffer[KEYBOARD_BUFFER_SIZE];
static volatile u32 keyboard_head;
static volatile u32 keyboard_tail;
static u8 shift_pressed;
static u8 caps_lock;

static const char scan_code_map[128] = {
    [0x02] = '1', [0x03] = '2', [0x04] = '3', [0x05] = '4',
    [0x06] = '5', [0x07] = '6', [0x08] = '7', [0x09] = '8',
    [0x0a] = '9', [0x0b] = '0', [0x0c] = '-', [0x0d] = '=',
    [0x0e] = '\b', [0x0f] = '\t', [0x10] = 'q', [0x11] = 'w',
    [0x12] = 'e', [0x13] = 'r', [0x14] = 't', [0x15] = 'y',
    [0x16] = 'u', [0x17] = 'i', [0x18] = 'o', [0x19] = 'p',
    [0x1a] = '[', [0x1b] = ']', [0x1c] = '\n', [0x1e] = 'a',
    [0x1f] = 's', [0x20] = 'd', [0x21] = 'f', [0x22] = 'g',
    [0x23] = 'h', [0x24] = 'j', [0x25] = 'k', [0x26] = 'l',
    [0x27] = ';', [0x28] = '\'', [0x29] = '`', [0x2b] = '\\',
    [0x2c] = 'z', [0x2d] = 'x', [0x2e] = 'c', [0x2f] = 'v',
    [0x30] = 'b', [0x31] = 'n', [0x32] = 'm', [0x33] = ',',
    [0x34] = '.', [0x35] = '/', [0x39] = ' '
};

static const char shifted_number_map[10] = {
    ')', '!', '@', '#', '$', '%', '^', '&', '*', '('
};

static char translate_scan_code(u8 scan_code)
{
    char character = scan_code_map[scan_code];

    if (character >= 'a' && character <= 'z') {
        if (shift_pressed != caps_lock) {
            character -= 'a' - 'A';
        }
    } else if (shift_pressed && character >= '0' && character <= '9') {
        character = shifted_number_map[character - '0'];
    } else if (shift_pressed) {
        if (character == '-') {
            character = '_';
        } else if (character == '=') {
            character = '+';
        } else if (character == '[') {
            character = '{';
        } else if (character == ']') {
            character = '}';
        } else if (character == ';') {
            character = ':';
        } else if (character == '\'') {
            character = '"';
        } else if (character == '`') {
            character = '~';
        } else if (character == '\\') {
            character = '|';
        } else if (character == ',') {
            character = '<';
        } else if (character == '.') {
            character = '>';
        } else if (character == '/') {
            character = '?';
        }
    }

    return character;
}

static void buffer_character(char character)
{
    u32 next = (keyboard_head + 1) % KEYBOARD_BUFFER_SIZE;

    if (next != keyboard_tail) {
        keyboard_buffer[keyboard_head] = character;
        keyboard_head = next;
    }
}

void keyboard_irq(u32 irq)
{
    char character;

    (void)irq;
    last_scan_code = in_byte(KB_DATA);
    keyboard_irq_count++;
    screen_put_u32(9, 0, "Keyboard IRQ: ", keyboard_irq_count, 0x0f);
    if (keyboard_irq_count == 1) {
        debug_puts("KEYBOARD IRQ OK\r\n");
    }

    if (last_scan_code == 0x2a || last_scan_code == 0x36) {
        shift_pressed = 1;
        return;
    }
    if (last_scan_code == 0xaa || last_scan_code == 0xb6) {
        shift_pressed = 0;
        return;
    }
    if (last_scan_code == 0x3a) {
        caps_lock = !caps_lock;
        return;
    }
    if ((last_scan_code & 0x80) != 0) {
        return;
    }

    character = translate_scan_code(last_scan_code);
    if (character != 0) {
        buffer_character(character);
        debug_puts("KEY ");
        out_byte(DEBUG_PORT, (u8)character);
        debug_puts("\r\n");
    }
}

void init_keyboard(void)
{
    keyboard_head = 0;
    keyboard_tail = 0;
    shift_pressed = 0;
    caps_lock = 0;
    irq_table[1] = keyboard_irq;
}

int keyboard_getchar(void)
{
    char character;

    if (keyboard_head == keyboard_tail) {
        return -1;
    }

    character = keyboard_buffer[keyboard_tail];
    keyboard_tail = (keyboard_tail + 1) % KEYBOARD_BUFFER_SIZE;
    return character;
}
