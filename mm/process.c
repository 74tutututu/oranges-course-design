#include "global.h"
#include "proc.h"
#include "proto.h"
#include "syscall.h"
#include "type.h"

typedef struct process_program {
    u8 used;
    char name[PROCESS_NAME_SIZE];
    void (*entry)(void);
} PROCESS_PROGRAM;

static PROCESS_PROGRAM program_table[PROCESS_MAX_PROGRAMS];

void init_process_service(void)
{
    u32 index;

    for (index = 0; index < PROCESS_MAX_PROGRAMS; index++) {
        program_table[index].used = 0;
    }
}

int process_register_program(const char *name, void (*entry)(void))
{
    u32 index;

    for (index = 0; index < PROCESS_MAX_PROGRAMS; index++) {
        if (!program_table[index].used) {
            program_table[index].used = 1;
            string_copy(program_table[index].name, name, PROCESS_NAME_SIZE);
            program_table[index].entry = entry;
            return 0;
        }
    }
    return SYS_ERR_NOSPC;
}

static void (*find_program(const char *name))(void)
{
    u32 index;

    for (index = 0; index < PROCESS_MAX_PROGRAMS; index++) {
        if (program_table[index].used && string_compare(program_table[index].name, name) == 0) {
            return program_table[index].entry;
        }
    }
    return 0;
}

static void relocate_frame_chain(STACK_FRAME *child_frame, u32 parent_bottom, u32 child_bottom)
{
    u32 parent_frame_pointer = child_frame->ebp;
    u32 parent_top = parent_bottom + TASK_STACK_SIZE;
    u32 stack_delta = child_bottom - parent_bottom;

    if (parent_frame_pointer < parent_bottom || parent_frame_pointer >= parent_top) {
        return;
    }
    child_frame->ebp = parent_frame_pointer + stack_delta;

    while (parent_frame_pointer >= parent_bottom && parent_frame_pointer < parent_top) {
        u32 saved_frame_pointer = *(u32 *)parent_frame_pointer;
        u32 *child_frame_pointer = (u32 *)(parent_frame_pointer + stack_delta);

        if (saved_frame_pointer >= parent_bottom && saved_frame_pointer < parent_top) {
            *child_frame_pointer = saved_frame_pointer + stack_delta;
        }
        parent_frame_pointer = saved_frame_pointer;
    }
}

int process_fork(STACK_FRAME *frame)
{
    PROCESS *parent = p_proc_ready;
    PROCESS *child = 0;
    STACK_FRAME *child_frame;
    u32 *parent_stack;
    u32 *child_stack;
    u32 frame_offset;
    u32 index;

    for (index = NR_BOOT_PROCS; index < NR_PROCS; index++) {
        if (proc_table[index].state == PROCESS_STATE_UNUSED) {
            child = &proc_table[index];
            break;
        }
    }
    if (child == 0) {
        return SYS_ERR_NOSPC;
    }

    parent_stack = (u32 *)((u32)task_stacks + parent->pid * TASK_STACK_SIZE);
    child_stack = (u32 *)((u32)task_stacks + child->pid * TASK_STACK_SIZE);
    for (index = 0; index < TASK_STACK_SIZE / sizeof(u32); index++) {
        child_stack[index] = parent_stack[index];
    }

    frame_offset = (u32)frame - (u32)parent_stack;
    child_frame = (STACK_FRAME *)((u32)child_stack + frame_offset);
    child_frame->eax = 0;
    relocate_frame_chain(child_frame, (u32)parent_stack, (u32)child_stack);

    child->saved_esp = (u32)child_frame;
    child->ppid = parent->pid;
    child->ticks = PROCESS_QUANTUM;
    child->priority = PROCESS_QUANTUM;
    child->run_count = 0;
    child->state = PROCESS_STATE_RUNNABLE;
    child->exit_status = 0;
    child->wait_pid = 0;
    child->wait_status = 0;
    string_copy(child->name, "forked", PROCESS_NAME_SIZE);
    child->argument[0] = 0;
    child->initial_frame = *child_frame;

    return (int)child->pid;
}

int process_exec(STACK_FRAME *frame, const char *name, const char *argument)
{
    void (*entry)(void) = find_program(name);

    if (entry == 0) {
        return SYS_ERR_NOENT;
    }

    string_copy(p_proc_ready->name, name, PROCESS_NAME_SIZE);
    string_copy(p_proc_ready->argument, argument, PROCESS_ARGUMENT_SIZE);
    frame->eip = (u32)entry;
    return 0;
}

int process_wait(u32 pid, int *status)
{
    PROCESS *child;

    if (pid >= NR_PROCS) {
        return SYS_ERR_CHILD;
    }
    child = &proc_table[pid];
    if (child->state == PROCESS_STATE_UNUSED || child->ppid != p_proc_ready->pid) {
        return SYS_ERR_CHILD;
    }

    if (child->state == PROCESS_STATE_ZOMBIE) {
        *status = child->exit_status;
        child->state = PROCESS_STATE_UNUSED;
        return (int)pid;
    }

    p_proc_ready->state = PROCESS_STATE_BLOCKED;
    p_proc_ready->wait_pid = pid;
    p_proc_ready->wait_status = status;
    schedule();
    return (int)pid;
}

void process_exit(int status)
{
    PROCESS *exiting = p_proc_ready;
    PROCESS *parent = &proc_table[exiting->ppid];

    fs_close_process(exiting->pid);
    exiting->exit_status = status;
    exiting->state = PROCESS_STATE_ZOMBIE;

    if (parent->state == PROCESS_STATE_BLOCKED && parent->wait_pid == exiting->pid) {
        *parent->wait_status = status;
        parent->state = PROCESS_STATE_RUNNABLE;
        exiting->state = PROCESS_STATE_UNUSED;
    }
    schedule();
}

const char *process_argument(void)
{
    return p_proc_ready->argument;
}
