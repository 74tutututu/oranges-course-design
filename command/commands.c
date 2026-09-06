#include "fs.h"
#include "proto.h"
#include "syscall.h"
#include "type.h"

static void write_text(const char *text)
{
    sys_write(FS_STDOUT, text, string_length(text));
}

static void write_number(u32 value)
{
    char digits[11];
    char output[11];
    u32 length = 0;
    u32 index;

    if (value == 0) {
        digits[length++] = '0';
    } else {
        while (value != 0) {
            digits[length++] = (char)('0' + value % 10);
            value /= 10;
        }
    }
    for (index = 0; index < length; index++) {
        output[index] = digits[length - index - 1];
    }
    sys_write(FS_STDOUT, output, length);
}

void command_cat(void)
{
    const char *path = process_argument();
    char buffer[64];
    int fd;
    int count;

    if (path[0] == 0) {
        write_text("usage: cat FILE\n");
        sys_exit(2);
    }
    fd = sys_open(path, FS_O_READ);
    if (fd < 0) {
        write_text("cat: file not found\n");
        debug_puts("COMMAND CAT NOENT\r\n");
        sys_exit(1);
    }
    while ((count = sys_read(fd, buffer, sizeof(buffer))) > 0) {
        sys_write(FS_STDOUT, buffer, (u32)count);
    }
    sys_close(fd);
    debug_puts("COMMAND CAT OK\r\n");
    sys_exit(0);
}

void command_stat(void)
{
    const char *path = process_argument();
    FILE_STAT stat;

    if (path[0] == 0) {
        write_text("usage: stat FILE\n");
        sys_exit(2);
    }
    if (sys_stat(path, &stat) < 0) {
        write_text("stat: file not found\n");
        debug_puts("COMMAND STAT NOENT\r\n");
        sys_exit(1);
    }

    write_text(path);
    write_text(": inode=");
    write_number(stat.inode);
    write_text(" size=");
    write_number(stat.size);
    write_text("\n");
    debug_puts("COMMAND STAT OK\r\n");
    sys_exit(0);
}

void command_rm(void)
{
    const char *path = process_argument();

    if (path[0] == 0) {
        write_text("usage: rm FILE\n");
        sys_exit(2);
    }
    if (sys_unlink(path) < 0) {
        write_text("rm: file not found or busy\n");
        debug_puts("COMMAND RM FAIL\r\n");
        sys_exit(1);
    }

    write_text("Removed ");
    write_text(path);
    write_text("\n");
    debug_puts("COMMAND RM OK\r\n");
    sys_exit(0);
}
