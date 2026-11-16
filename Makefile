FILES = ./build/kernel.asm.o ./build/kernel.o ./build/idt/idt.asm.o ./build/idt/idt.o ./build/memory/memory.o ./build/io/io.asm.o ./build/memory/heap/heap.o ./build/memory/heap/kheap.o ./build/memory/paging/paging.o ./build/memory/paging/paging.asm.o ./build/disk/disk.o ./build/disk/streamer.o ./build/fs/pparser.o ./build/string/string.o

INCLUDES = -I./src

FLAGS = -g -ffreestanding -falign-jumps -falign-functions -falign-labels -falign-loops -fstrength-reduce -fomit-frame-pointer -finline-functions -Wno-unused-function -fno-builtin -Werror -Wno-unused-label -Wno-cpp -Wno-unused-parameter -nostdlib -nostartfiles -nodefaultlibs -Wall -O0 -Iinc

all: ./bin/boot.bin ./bin/kernel.bin
	rm -rf ./bin/os.bin
	dd if=./bin/boot.bin >> ./bin/os.bin
	dd if=./bin/kernel.bin >> ./bin/os.bin
	dd if=/dev/zero bs=1048576 count=16 >> ./bin/os.bin
	# Copy hello.txt into the FAT16 image (mtools, works on macOS and Linux, no sudo)
	MTOOLS_SKIP_CHECK=1 mcopy -o -i ./bin/os.bin ./hello.txt ::hello.txt
	# Course way (Linux only, needs /mnt/d):
	#   sudo mount -t vfat ./bin/os.bin /mnt/d
	#   sudo cp ./hello.txt /mnt/d
	#   sudo umount /mnt/d

./bin/kernel.bin: $(FILES)
	@mkdir -p ./bin
	i686-elf-ld -g -relocatable $(FILES) -o ./build/kernelfull.o
	i686-elf-gcc $(FLAGS) -T ./src/linker.ld -o ./bin/kernel.bin -ffreestanding -O0 -nostdlib ./build/kernelfull.o

./bin/boot.bin: ./src/boot/boot.asm
	@mkdir -p ./bin
	nasm -f bin ./src/boot/boot.asm -o ./bin/boot.bin

./build/kernel.asm.o: ./src/kernel.asm
	@mkdir -p $(dir $@)
	nasm -f elf -g ./src/kernel.asm -o ./build/kernel.asm.o

./build/kernel.o: ./src/kernel.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) $(FLAGS) -std=gnu99 -c ./src/kernel.c -o ./build/kernel.o

./build/idt/idt.asm.o: ./src/idt/idt.asm
	@mkdir -p $(dir $@)
	nasm -f elf -g ./src/idt/idt.asm -o ./build/idt/idt.asm.o

./build/idt/idt.o: ./src/idt/idt.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/idt $(FLAGS) -std=gnu99 -c ./src/idt/idt.c -o ./build/idt/idt.o

./build/memory/memory.o: ./src/memory/memory.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/memory $(FLAGS) -std=gnu99 -c ./src/memory/memory.c -o ./build/memory/memory.o

./build/io/io.asm.o: ./src/io/io.asm
	@mkdir -p $(dir $@)
	nasm -f elf -g ./src/io/io.asm -o ./build/io/io.asm.o

./build/memory/heap/heap.o: ./src/memory/heap/heap.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/memory/heap $(FLAGS) -std=gnu99 -c ./src/memory/heap/heap.c -o ./build/memory/heap/heap.o

./build/memory/heap/kheap.o: ./src/memory/heap/kheap.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/memory/heap $(FLAGS) -std=gnu99 -c ./src/memory/heap/kheap.c -o ./build/memory/heap/kheap.o

./build/memory/paging/paging.o: ./src/memory/paging/paging.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/memory/paging $(FLAGS) -std=gnu99 -c ./src/memory/paging/paging.c -o ./build/memory/paging/paging.o

./build/memory/paging/paging.asm.o: ./src/memory/paging/paging.asm
	@mkdir -p $(dir $@)
	nasm -f elf -g ./src/memory/paging/paging.asm -o ./build/memory/paging/paging.asm.o

./build/disk/disk.o: ./src/disk/disk.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/disk $(FLAGS) -std=gnu99 -c ./src/disk/disk.c -o ./build/disk/disk.o

./build/disk/streamer.o: ./src/disk/streamer.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/disk $(FLAGS) -std=gnu99 -c ./src/disk/streamer.c -o ./build/disk/streamer.o

./build/fs/pparser.o: ./src/fs/pparser.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/fs $(FLAGS) -std=gnu99 -c ./src/fs/pparser.c -o ./build/fs/pparser.o

./build/string/string.o: ./src/string/string.c
	@mkdir -p $(dir $@)
	i686-elf-gcc $(INCLUDES) -I./src/string $(FLAGS) -std=gnu99 -c ./src/string/string.c -o ./build/string/string.o

run: all
	qemu-system-i386 -hda ./bin/os.bin

clean:
	rm -rf ./bin/boot.bin
	rm -rf ./bin/kernel.bin
	rm -rf ./bin/os.bin
	rm -rf ${FILES}
	rm -rf ./build/kernelfull.o

.PHONY: all run clean
