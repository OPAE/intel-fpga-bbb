include common_include.mk

# Primary test name
TESTS = test_vtp_sw test_vtp_refcnt

# Build directory
OBJDIR = obj
CFLAGS += -I./$(OBJDIR)
CPPFLAGS += -I./$(OBJDIR)

# Files and folders
SRCS = $(addsuffix .c,$(TESTS))
OBJS = $(addprefix $(OBJDIR)/,$(patsubst %.c,%.o,$(SRCS)))

all: $(TESTS)

$(TESTS): $(OBJS)
	$(CC) -o $@ $(OBJDIR)/$@.o $(LDFLAGS) $(FPGA_LIBS) -lMPF

$(OBJDIR)/%.o: %.c | objdir
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(TESTS) $(OBJDIR)

objdir:
	@mkdir -p $(OBJDIR)

.PHONY: all clean
