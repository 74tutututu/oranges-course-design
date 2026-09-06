#include "fs.h"
#include "proto.h"
#include "syscall.h"
#include "type.h"

static u8 selftest_started;

void init_system_selftest(void)
{
    selftest_started = 0;
}

void run_system_selftest(void)
{
    static const char contents[] = "temporary";
    static const char console_message[] = "M6 file syscalls ready.\n";
    char buffer[16];
    FILE_STAT stat;
    int fd;
    int result;

    if (selftest_started) {
        return;
    }
    selftest_started = 1;

    fd = sys_open("temp.txt", FS_O_WRITE | FS_O_CREATE);
    if (fd < 0 || sys_write(fd, contents, sizeof(contents) - 1) != (int)(sizeof(contents) - 1) ||
        sys_close(fd) != 0) {
        debug_puts("FS SYSCALLS FAIL\r\n");
        return;
    }

    if (sys_stat("temp.txt", &stat) != 0 || stat.size != sizeof(contents) - 1) {
        debug_puts("FS SYSCALLS FAIL\r\n");
        return;
    }

    fd = sys_open("readme.txt", FS_O_READ);
    result = sys_read(fd, buffer, sizeof(buffer));
    if (fd < 0 || result != (int)sizeof(buffer) || buffer[0] != 'O' || sys_close(fd) != 0) {
        debug_puts("FS SYSCALLS FAIL\r\n");
        return;
    }

    if (sys_unlink("temp.txt") != 0 || sys_stat("temp.txt", &stat) != SYS_ERR_NOENT) {
        debug_puts("FS SYSCALLS FAIL\r\n");
        return;
    }

    sys_write(FS_STDOUT, console_message, sizeof(console_message) - 1);
    debug_puts("FS SYSCALLS OK\r\n");
}
