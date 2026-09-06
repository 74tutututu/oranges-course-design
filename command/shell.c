#include "proto.h"
#include "syscall.h"
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
    process_register_program("cat", command_cat);
    process_register_program("stat", command_stat);
    process_register_program("rm", command_rm);
    process_register_program("ps", command_ps);
    debug_puts("SHELL READY\r\n");
}

static void run_external(const char *command, const char *argument)
{
    int pid = sys_fork();
    int status;

    if (pid == 0) {
        if (sys_exec(command, argument) < 0) {
            sys_exit(127);
        }
    }
    if (pid < 0) {
        console_write("shell: fork failed\n");
        return;
    }
    sys_wait((u32)pid, &status);
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
        console_write("Commands: cat stat rm ps\n");
        debug_puts("SHELL HELP OK\r\n");
    } else if (string_compare(command, "clear") == 0) {
        console_clear();
        debug_puts("SHELL CLEAR OK\r\n");
    } else if (string_compare(command, "cat") == 0 || string_compare(command, "stat") == 0 ||
               string_compare(command, "rm") == 0 || string_compare(command, "ps") == 0) {
        run_external(command, argument);
    } else {
        console_write("Unknown command: ");
        console_write(command);
        console_putc('\n');
        debug_puts("SHELL UNKNOWN OK\r\n");
    }
}
