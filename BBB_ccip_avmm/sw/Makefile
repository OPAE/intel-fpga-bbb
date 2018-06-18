############################################################
# Makefile setting required to comply with SDL
############################################################

# stack execution protection
LDFLAGS +=-z noexecstack

# data relocation and projection
LDFLAGS +=-z relro -z now

# stack buffer overrun detection
# Note that CentOS 7 has gcc 4.8 by default.  When we switch
# to a system with gcc 4.9 or newer this should be changed to
# CFLAGS="-fstack-protector-strong"
CFLAGS +=-fstack-protector

# Position independent execution
CFLAGS +=-fPIE -fPIC
LDFLAGS +=-pie

# fortify source
CFLAGS+=-O2 -D_FORTIFY_SOURCE=2

# format string vulnerabilities
CFLAGS+=-Wformat -Wformat-security

# More optimizations - dump unused code, spatial locality
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -freorder-functions -freorder-blocks-and-partition
CFLAGS += -Wl,--gc-sections

# Use native memcpy()
#CFLAGS += -DUSE_MEMCPY

# Compile for ASE
#CFLAGS += -DUSE_ASE

# Expose and report poll and buffer full wait counts
#CFLAGS += -DCHECK_DELAYS

############################################################

CFLAGS += -Werror -Wunused-variable

CFLAGS += -g

ifdef prefix
CFLAGS += -I$(prefix)/include
LDFLAGS += -L$(prefix)/lib -L$(prefix)/lib64
endif

#CFLAGS += -Wall -Werror -Wno-unknown-pragmas
LDFLAGS += -luuid
#LDFLAGS += -lsafestr
LDFLAGS += -lrt

ifeq ($(USE_ASE),1)
	LDFLAGS += -lopae-c-ase
	CFLAGS += -DUSE_ASE
else
	LDFLAGS += -ljson-c
	LDFLAGS += -lopae-c
	LDFLAGS += -pthread
	LDFLAGS += -lhwloc
endif

all: fpga_dma_test

# FPGA DMA Driver
fpga_dma_test: fpga_dma_test.o fpga_dma.so
	gcc -o $@ $^ $(LDFLAGS)

fpga_dma_test.o: fpga_dma_test.c
	gcc $(CFLAGS) -o $@ -c $^

fpga_dma.so: fpga_dma.o x86-sse2.o
	gcc $(CFLAGS)  -o $@ $^ $(LDFLAGS) -shared

fpga_dma.o: fpga_dma.c
	gcc $(CFLAGS) -c -o $@ $^

x86-sse2.o: x86-sse2.S
	gcc $(CFLAGS) -c -o $@ $^

clean:
	$(RM) fpga_dma_test *.o *.so

.PHONY:all clean
