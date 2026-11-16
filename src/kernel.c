#include "kernel.h"
#include <stddef.h>
#include <stdint.h>
#include "idt/idt.h"
#include "io/io.h"
#include "memory/heap/kheap.h"
#include "memory/paging/paging.h"
#include "disk/disk.h"
#include "disk/streamer.h"
#include "fs/pparser.h"
#include "string/string.h"

uint16_t* video_mem = 0;
uint16_t terminal_row = 0;
uint16_t terminal_col = 0;

uint16_t terminal_make_char(char c, char colour)
{
    return (colour << 8) | c;
}

void terminal_putchar(int x, int y, char c, char colour)
{
    video_mem[(y * VGA_WIDTH) + x] = terminal_make_char(c, colour);
}

void terminal_writechar(char c, char colour)
{
    if (c == '\n')
    {
        terminal_row += 1;
        terminal_col = 0;
        return;
    }

    terminal_putchar(terminal_col, terminal_row, c, colour);
    terminal_col += 1;

    if (terminal_col >= VGA_WIDTH)
    {
        terminal_col = 0;
        terminal_row += 1;
    }
}

void terminal_initialize()
{
    video_mem = (uint16_t*)(0xB8000);
    terminal_row = 0;
    terminal_col = 0;

    for (int y = 0; y < VGA_HEIGHT; y++)
    {
        for (int x = 0; x < VGA_WIDTH; x++)
        {
            terminal_putchar(x, y, ' ', 0);
        }
    }
}

void print(const char* str)
{
    int len = strlen(str);
    for (int i = 0; i < len; i++)
    {
        terminal_writechar(str[i], 15);
    }
}

static struct paging_4gb_chunk* kernel_chunk = 0;

void kernel_main()
{
    terminal_initialize();
    print("Hello world!\n");

    // Initialize the heap
    kheap_init();

    // Search and initialize the disks
    disk_search_and_init();

    // Initialize the interrupt descriptor table
    idt_init();

    // Set up paging: identity map all 4 GiB
    kernel_chunk = paging_new_4gb(PAGING_IS_WRITEABLE | PAGING_IS_PRESENT | PAGING_ACCESS_FROM_ALL);
    paging_switch(paging_4gb_chunk_get_directory(kernel_chunk));
    enable_paging();

    // Enable the system interrupts
    enable_interrupts();

#if 0
    // ---- Milestone self-tests (flip to #if 1 to run, inspect in gdb) ----

    // M6 heap: expect 0x01000000, 0x01001000, 0x01003000, then p4 == p1
    void* p1 = kmalloc(50);
    void* p2 = kmalloc(5000);
    void* p3 = kmalloc(5600);
    kfree(p1);
    void* p4 = kmalloc(50);
    (void)p2; (void)p3; (void)p4;

    // M7 paging remap: screen shows "ABAB"
    char* ptr = kzalloc(4096);
    paging_set(paging_4gb_chunk_get_directory(kernel_chunk), (void*)0x1000,
               (uint32_t)ptr | PAGING_ACCESS_FROM_ALL | PAGING_IS_PRESENT | PAGING_IS_WRITEABLE);
    char* ptr2 = (char*)0x1000;
    ptr2[0] = 'A';
    ptr2[1] = 'B';
    print(ptr2);
    print(ptr);
    print("\n");

    // M8 disk: buf[510] == 0x55, buf[511] == 0xAA
    unsigned char buf[512];
    disk_read_block(disk_get(0), 0, 1, buf);
    if (buf[510] == 0x55 && buf[511] == 0xAA)
        print("disk: boot signature OK\n");

    // M9 path parser
    struct path_root* root = pathparser_parse("0:/bin/shell.exe", NULL);
    if (root && root->drive_no == 0 && root->first && root->first->next
        && root->first->next->next == 0)
        print("pparser: OK\n");
    pathparser_free(root);
    if (pathparser_parse("A:/x", NULL) == 0 && pathparser_parse("0x/x", NULL) == 0)
        print("pparser: bad paths rejected\n");

    // M10 streamer: cross-sector read at 0x1FE, first two bytes 55 AA
    struct disk_stream* stream = diskstreamer_new(0);
    unsigned char c[4];
    diskstreamer_seek(stream, 0x1FE);
    diskstreamer_read(stream, c, 4);
    if (c[0] == 0x55 && c[1] == 0xAA)
        print("streamer: cross-sector read OK\n");
    diskstreamer_close(stream);
#endif
}
