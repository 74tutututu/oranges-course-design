#include "const.h"
#include "proto.h"
#include "type.h"

static u32 cursor_row;
static u32 cursor_column;

static void update_cursor(void)
{
    u16 position = (u16)(cursor_row * VGA_COLUMNS + cursor_column);

    out_byte(CRTC_ADDR_REG, CRTC_CURSOR_HIGH);
    out_byte(CRTC_DATA_REG, (u8)(position >> 8));
    out_byte(CRTC_ADDR_REG, CRTC_CURSOR_LOW);
    out_byte(CRTC_DATA_REG, (u8)(position & 0xff));
}

static void clear_row(u32 row)
{
    volatile u16 *video = (volatile u16 *)V_MEM_BASE;
    u32 column;

    for (column = 0; column < VGA_COLUMNS; column++) {
        video[row * VGA_COLUMNS + column] = 0x0700 | ' ';
    }
}

static void scroll_if_needed(void)
{
    volatile u16 *video = (volatile u16 *)V_MEM_BASE;
    u32 row;
    u32 column;

    if (cursor_row < VGA_ROWS) {
        return;
    }

    for (row = CONSOLE_FIRST_ROW + 1; row < VGA_ROWS; row++) {
        for (column = 0; column < VGA_COLUMNS; column++) {
            video[(row - 1) * VGA_COLUMNS + column] = video[row * VGA_COLUMNS + column];
        }
    }
    clear_row(VGA_ROWS - 1);
    cursor_row = VGA_ROWS - 1;
}

void console_clear(void)
{
    u32 row;

    for (row = CONSOLE_FIRST_ROW; row < VGA_ROWS; row++) {
        clear_row(row);
    }
    cursor_row = CONSOLE_FIRST_ROW;
    cursor_column = 0;
    update_cursor();
}

void console_init(void)
{
    console_clear();
}

void console_putc(char character)
{
    volatile u16 *video = (volatile u16 *)V_MEM_BASE;

    if (character == '\n') {
        cursor_column = 0;
        cursor_row++;
    } else if (character == '\b') {
        if (cursor_column != 0) {
            cursor_column--;
            video[cursor_row * VGA_COLUMNS + cursor_column] = 0x0700 | ' ';
        }
    } else if (character == '\t') {
        do {
            console_putc(' ');
        } while ((cursor_column & 3) != 0);
        return;
    } else {
        video[cursor_row * VGA_COLUMNS + cursor_column] = 0x0700 | (u8)character;
        cursor_column++;
        if (cursor_column == VGA_COLUMNS) {
            cursor_column = 0;
            cursor_row++;
        }
    }

    scroll_if_needed();
    update_cursor();
}

void console_write(const char *text)
{
    while (*text != 0) {
        console_putc(*text++);
    }
}
