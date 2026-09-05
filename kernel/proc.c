#include "const.h"
#include "global.h"
#include "proc.h"
#include "proto.h"

PROCESS proc_table[NR_PROCS];
PROCESS *p_proc_ready;
volatile u32 schedule_count;
volatile u32 task_run_count[NR_PROCS];

static u32 task_stacks[TASK_STACK_TOTAL / sizeof(u32)];
static u32 scheduler_reported;

static void copy_name(char *dst, const char *src)
{
    u32 i;

    for (i = 0; i < 15 && src[i] != 0; i++) {
        dst[i] = src[i];
    }
    dst[i] = 0;
}

static void init_process(u32 index, u32 entry, const char *name)
{
    STACK_FRAME *frame;
    u32 stack_top = (u32)task_stacks + (index + 1) * TASK_STACK_SIZE;

    frame = (STACK_FRAME *)(stack_top - sizeof(STACK_FRAME));
    frame->gs = SELECTOR_KERNEL_DS;
    frame->fs = SELECTOR_KERNEL_DS;
    frame->es = SELECTOR_KERNEL_DS;
    frame->ds = SELECTOR_KERNEL_DS;
    frame->edi = 0;
    frame->esi = 0;
    frame->ebp = 0;
    frame->esp_ignored = 0;
    frame->ebx = 0;
    frame->edx = 0;
    frame->ecx = 0;
    frame->eax = 0;
    frame->irq = 0;
    frame->eip = entry;
    frame->cs = SELECTOR_KERNEL_CS;
    frame->eflags = 0x202;

    proc_table[index].saved_esp = (u32)frame;
    proc_table[index].pid = index;
    proc_table[index].ticks = PROCESS_QUANTUM;
    proc_table[index].priority = PROCESS_QUANTUM;
    proc_table[index].run_count = 0;
    proc_table[index].state = PROCESS_STATE_RUNNABLE;
    copy_name(proc_table[index].name, name);
    proc_table[index].initial_frame = *frame;
    task_run_count[index] = 0;
}

void init_processes(void)
{
    schedule_count = 0;
    scheduler_reported = 0;
    init_process(0, (u32)task_a, "TaskA");
    init_process(1, (u32)task_b, "TaskB");
    init_process(2, (u32)task_c, "TaskC");
    p_proc_ready = &proc_table[0];
}

void schedule(void)
{
    u32 current = p_proc_ready->pid;
    u32 next = (current + 1) % NR_PROCS;

    p_proc_ready = &proc_table[next];
    p_proc_ready->ticks = PROCESS_QUANTUM;
    schedule_count++;

    screen_puts(10, 0, "Current task: ", 0x0f);
    screen_puts(10, 14, p_proc_ready->name, 0x0f);

    debug_puts("SCHEDULE ");
    debug_puts(p_proc_ready->name);
    debug_puts("\r\n");

    if (!scheduler_reported && schedule_count >= 3 &&
        task_run_count[0] != 0 && task_run_count[1] != 0 && task_run_count[2] != 0) {
        scheduler_reported = 1;
        debug_puts("SCHEDULER OK\r\n");
    }
}

void process_timer_tick(void)
{
    p_proc_ready->ticks--;
    if (p_proc_ready->ticks == 0) {
        schedule();
    }
}

static void task_step(u32 index, char marker)
{
    u32 count = ++task_run_count[index];

    proc_table[index].run_count = count;
    if (count == 1) {
        debug_puts("TASK ");
        out_byte(DEBUG_PORT, (u8)marker);
        debug_puts(" OK\r\n");
    }
    if (count == 1 || (count & 0x3fff) == 0) {
        if (index == 0) {
            screen_put_u32(12, 0, "TaskA runs: ", count, 0x0f);
        } else if (index == 1) {
            screen_put_u32(13, 0, "TaskB runs: ", count, 0x0f);
        } else {
            screen_put_u32(14, 0, "TaskC runs: ", count, 0x0f);
        }
    }
}

void task_a(void)
{
    while (1) {
        task_step(0, 'A');
    }
}

void task_b(void)
{
    while (1) {
        task_step(1, 'B');
    }
}

void task_c(void)
{
    while (1) {
        task_step(2, 'C');
    }
}
