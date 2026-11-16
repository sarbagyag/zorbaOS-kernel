#include "streamer.h"
#include "config.h"
#include "memory/heap/kheap.h"

struct disk_stream* diskstreamer_new(int disk_id)
{
    struct disk* disk = disk_get(disk_id);
    if (!disk)
    {
        return 0;
    }

    struct disk_stream* streamer = kzalloc(sizeof(struct disk_stream));
    if (!streamer)
    {
        return 0;
    }

    streamer->pos = 0;
    streamer->disk = disk;
    return streamer;
}

int diskstreamer_seek(struct disk_stream* stream, int pos)
{
    stream->pos = pos;
    return 0;
}

// FIX: the course copies min(total, 512) bytes from buf + offset, which
// over-reads buf whenever offset != 0. Here each step copies at most up to
// the end of the current sector, and it loops instead of recursing.
int diskstreamer_read(struct disk_stream* stream, void* out, int total)
{
    char* o = (char*)out;

    while (total > 0)
    {
        int sector = stream->pos / PEACHOS_SECTOR_SIZE;
        int offset = stream->pos % PEACHOS_SECTOR_SIZE;
        char buf[PEACHOS_SECTOR_SIZE];

        int res = disk_read_block(stream->disk, sector, 1, buf);
        if (res < 0)
        {
            return res;
        }

        int total_to_read = PEACHOS_SECTOR_SIZE - offset;
        if (total < total_to_read)
        {
            total_to_read = total;
        }

        for (int i = 0; i < total_to_read; i++)
        {
            *o++ = buf[offset + i];
        }

        stream->pos += total_to_read;
        total -= total_to_read;
    }

    return 0;
}

void diskstreamer_close(struct disk_stream* stream)
{
    kfree(stream);
}
