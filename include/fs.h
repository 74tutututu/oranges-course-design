#ifndef ORANGES_FS_H
#define ORANGES_FS_H

#include "type.h"

#define FS_MAX_FILES 8
#define FS_NAME_SIZE 16
#define FS_FILE_SIZE 512
#define FS_MAX_OPEN_FILES 8

#define FS_O_READ 0x00
#define FS_O_WRITE 0x01
#define FS_O_CREATE 0x02

#define FS_STDIN 0
#define FS_STDOUT 1

typedef struct file_stat {
    u32 inode;
    u32 size;
} FILE_STAT;

#endif
