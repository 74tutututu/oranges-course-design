#include "proto.h"
#include "type.h"

u32 string_length(const char *text)
{
    u32 length = 0;

    while (text[length] != 0) {
        length++;
    }
    return length;
}

int string_compare(const char *left, const char *right)
{
    while (*left != 0 && *left == *right) {
        left++;
        right++;
    }
    return (u8)*left - (u8)*right;
}

void string_copy(char *destination, const char *source, u32 capacity)
{
    u32 index = 0;

    while (index + 1 < capacity && source[index] != 0) {
        destination[index] = source[index];
        index++;
    }
    destination[index] = 0;
}
