OFS_PLATFORM_AFU_BBB = ../../../../ofs-platform-afu-bbb

COMMON_PATH = $(OFS_PLATFORM_AFU_BBB)/plat_if_tests/common/sw
include $(COMMON_PATH)/common_include.mk

# Primary test name
TEST = host_chan_vtp

# Build directory
OBJDIR = obj
CFLAGS += -I./$(OBJDIR)
CPPFLAGS += -I./$(OBJDIR)

# Files and folders
SRCS = main.c test_host_chan_vtp.c $(COMMON_SRCS)
OBJS = $(addprefix $(OBJDIR)/,$(patsubst %.c,%.o,$(SRCS)))

all: $(TEST)

# AFU info from JSON file, including AFU UUID
AFU_JSON_INFO = $(OBJDIR)/afu_json_info.h
$(AFU_JSON_INFO): ../hw/rtl/common/$(TEST).json | objdir
	afu_json_mgr json-info --afu-json=$^ --c-hdr=$@
$(OBJS): $(AFU_JSON_INFO)

$(TEST): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS) $(FPGA_LIBS) -lMPF

$(OBJDIR)/%.o: %.c | objdir
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(TEST) $(OBJDIR)

objdir:
	@mkdir -p $(OBJDIR)

# Debugging. Print Makefile variables with "make print-<VARIABLE NAME>"
print-%:
	@echo $* = $($*)

.PHONY: all clean
