#include "fs.h"
#include "proto.h"
#include "syscall.h"
#include "type.h"

typedef struct ram_file {
    u8 used;
    u32 inode;
    u32 size;
    char name[FS_NAME_SIZE];
    char data[FS_FILE_SIZE];
} RAM_FILE;

typedef struct file_handle {
    u8 used;
    u32 owner;
    u32 file_index;
    u32 offset;
    u32 flags;
} FILE_HANDLE;

static RAM_FILE file_table[FS_MAX_FILES];
static FILE_HANDLE handle_table[FS_MAX_OPEN_FILES];
static u32 next_inode;

static int find_file(const char *path)
{
    u32 index;

    for (index = 0; index < FS_MAX_FILES; index++) {
        if (file_table[index].used && string_compare(file_table[index].name, path) == 0) {
            return (int)index;
        }
    }
    return SYS_ERR_NOENT;
}

static int create_file(const char *path)
{
    u32 index;

    for (index = 0; index < FS_MAX_FILES; index++) {
        if (!file_table[index].used) {
            file_table[index].used = 1;
            file_table[index].inode = next_inode++;
            file_table[index].size = 0;
            string_copy(file_table[index].name, path, FS_NAME_SIZE);
            return (int)index;
        }
    }
    return SYS_ERR_NOSPC;
}

static void seed_file(const char *path, const char *contents)
{
    int file_index = create_file(path);
    u32 length = string_length(contents);
    u32 offset;

    for (offset = 0; offset < length; offset++) {
        file_table[file_index].data[offset] = contents[offset];
    }
    file_table[file_index].size = length;
}

static FILE_HANDLE *get_handle(u32 owner, int fd)
{
    u32 index;

    if (fd < 3) {
        return 0;
    }
    index = (u32)(fd - 3);
    if (index >= FS_MAX_OPEN_FILES || !handle_table[index].used || handle_table[index].owner != owner) {
        return 0;
    }
    return &handle_table[index];
}

void fs_init(void)
{
    u32 index;

    next_inode = 1;
    for (index = 0; index < FS_MAX_FILES; index++) {
        file_table[index].used = 0;
    }
    for (index = 0; index < FS_MAX_OPEN_FILES; index++) {
        handle_table[index].used = 0;
    }

    seed_file("readme.txt", "OrangeS RAM file system\nUse cat, stat and rm from the shell.\n");
    seed_file("hello.txt", "Hello from OrangeS.\n");
}

int fs_open(u32 owner, const char *path, u32 flags)
{
    int file_index = find_file(path);
    u32 handle_index;

    if (file_index < 0) {
        if ((flags & FS_O_CREATE) == 0) {
            return file_index;
        }
        file_index = create_file(path);
        if (file_index < 0) {
            return file_index;
        }
    }

    for (handle_index = 0; handle_index < FS_MAX_OPEN_FILES; handle_index++) {
        if (!handle_table[handle_index].used) {
            handle_table[handle_index].used = 1;
            handle_table[handle_index].owner = owner;
            handle_table[handle_index].file_index = (u32)file_index;
            handle_table[handle_index].offset = 0;
            handle_table[handle_index].flags = flags;
            return (int)handle_index + 3;
        }
    }
    return SYS_ERR_NOSPC;
}

int fs_read(u32 owner, int fd, char *buffer, u32 count)
{
    FILE_HANDLE *handle = get_handle(owner, fd);
    RAM_FILE *file;
    u32 bytes_read = 0;

    if (handle == 0) {
        return SYS_ERR_BADF;
    }
    file = &file_table[handle->file_index];
    while (bytes_read < count && handle->offset < file->size) {
        buffer[bytes_read++] = file->data[handle->offset++];
    }
    return (int)bytes_read;
}

int fs_write(u32 owner, int fd, const char *buffer, u32 count)
{
    FILE_HANDLE *handle = get_handle(owner, fd);
    RAM_FILE *file;
    u32 bytes_written = 0;

    if (handle == 0) {
        return SYS_ERR_BADF;
    }
    if ((handle->flags & FS_O_WRITE) == 0) {
        return SYS_ERR_INVAL;
    }

    file = &file_table[handle->file_index];
    while (bytes_written < count && handle->offset < FS_FILE_SIZE) {
        file->data[handle->offset++] = buffer[bytes_written++];
    }
    if (handle->offset > file->size) {
        file->size = handle->offset;
    }
    return (int)bytes_written;
}

int fs_close(u32 owner, int fd)
{
    FILE_HANDLE *handle = get_handle(owner, fd);

    if (handle == 0) {
        return SYS_ERR_BADF;
    }
    handle->used = 0;
    return 0;
}

int fs_stat(const char *path, FILE_STAT *stat)
{
    int file_index = find_file(path);

    if (file_index < 0) {
        return file_index;
    }
    stat->inode = file_table[file_index].inode;
    stat->size = file_table[file_index].size;
    return 0;
}

int fs_unlink(const char *path)
{
    int file_index = find_file(path);
    u32 index;

    if (file_index < 0) {
        return file_index;
    }
    for (index = 0; index < FS_MAX_OPEN_FILES; index++) {
        if (handle_table[index].used && handle_table[index].file_index == (u32)file_index) {
            return SYS_ERR_BUSY;
        }
    }
    file_table[file_index].used = 0;
    return 0;
}

void fs_close_process(u32 owner)
{
    u32 index;

    for (index = 0; index < FS_MAX_OPEN_FILES; index++) {
        if (handle_table[index].used && handle_table[index].owner == owner) {
            handle_table[index].used = 0;
        }
    }
}
