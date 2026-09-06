#include "proto.h"
#include "type.h"

static void parse_command(const char *line, char *command, char *argument)
{
    u32 input = 0;
    u32 output = 0;

    while (line[input] == ' ') {
        input++;
    }
    while (line[input] != 0 && line[input] != ' ' && output + 1 < PROCESS_NAME_SIZE) {
        command[output++] = line[input++];
    }
    command[output] = 0;

    while (line[input] == ' ') {
        input++;
    }
    output = 0;
    while (line[input] != 0 && output + 1 < PROCESS_ARGUMENT_SIZE) {
        argument[output++] = line[input++];
    }
    while (output != 0 && argument[output - 1] == ' ') {
        output--;
    }
    argument[output] = 0;
}

void shell_init(void)
{
    debug_puts("SHELL READY\r\n");
}

void shell_execute(const char *line)
{
    char command[PROCESS_NAME_SIZE];
    char argument[PROCESS_ARGUMENT_SIZE];

    parse_command(line, command, argument);
    if (command[0] == 0) {
        return;
    }

    if (string_compare(command, "help") == 0) {
        console_write("Built-ins: help clear\n");
        console_write("Commands: cat stat rm\n");
        debug_puts("SHELL HELP OK\r\n");
    } else if (string_compare(command, "clear") == 0) {
        console_clear();
        debug_puts("SHELL CLEAR OK\r\n");
    } else {
        console_write("Unknown command: ");
        console_write(command);
        console_putc('\n');
        debug_puts("SHELL UNKNOWN OK\r\n");
    }
}
