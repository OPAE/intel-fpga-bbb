include ../../base/sw/base_include.mk

# Primary test name
TEST = test_random

# Build directory, including generated .h files
OBJDIR = obj
CFLAGS += -I./$(OBJDIR)
CPPFLAGS += -I./$(OBJDIR)

# Files and folders
SRCS = $(TEST).cpp $(BASE_FILE_SRC)
OBJS = $(addprefix $(OBJDIR)/,$(patsubst %.cpp,%.o,$(SRCS)))

# Targets
all: $(TEST)

# AFU info from JSON file, including AFU UUID
AFU_JSON_INFO = $(OBJDIR)/afu_json_info.h
$(AFU_JSON_INFO): ../hw/rtl/test_random.json | objdir
	afu_json_mgr json-info --afu-json=$^ --c-hdr=$@
$(OBJS): $(AFU_JSON_INFO)

$(TEST): $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(FPGA_LIBS)

$(OBJDIR)/%.o: %.cpp | objdir
	$(CXX) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(TEST) $(OBJDIR)

objdir:
	@mkdir -p $(OBJDIR)

.PHONY: all clean
