#include "const.h"
#include "proto.h"
#include "type.h"

static char input_line[TTY_LINE_SIZE];
static u32 input_length;
static u8 tty_reported;

static void print_prompt(void)
{
    console_write("OrangeS> ");
}

static void finish_line(void)
{
    input_line[input_length] = 0;
    console_putc('\n');
    debug_puts("TTY LINE ");
    debug_puts(input_line);
    debug_puts("\r\n");

    if (!tty_reported) {
        tty_reported = 1;
        debug_puts("TTY OK\r\n");
    }

    shell_execute(input_line);
    input_length = 0;
    print_prompt();
}

void tty_init(void)
{
    input_length = 0;
    tty_reported = 0;
    console_init();
    console_write("TTY ready. Type and press Enter.\n");
    print_prompt();
    debug_puts("TTY READY\r\n");
}

void tty_poll(void)
{
    int character;

    while ((character = keyboard_getchar()) >= 0) {
        if (character == '\n') {
            finish_line();
        } else if (character == '\b') {
            if (input_length != 0) {
                input_length--;
                console_putc('\b');
            }
        } else if (character >= ' ' && character <= '~' && input_length + 1 < TTY_LINE_SIZE) {
            input_line[input_length++] = (char)character;
            console_putc((char)character);
        }
    }
}
