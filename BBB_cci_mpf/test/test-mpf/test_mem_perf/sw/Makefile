include ../../base/sw/base_include.mk

# Build directory
OBJDIR = obj

# Files and folders
SRCS = test_mem_perf_common.cpp $(BASE_FILE_SRC)
OBJS = $(addprefix $(OBJDIR)/,$(patsubst %.cpp,%.o,$(SRCS)))

CFLAGS += -DVCMAP_ENABLE_DEFAULT=false

all: test_mem_perf test_mem_perf_ase test_mem_latency test_mem_latency_ase \
	compute_latency_qos_params compute_latency_qos_params_ase \
	compute_vc_map_params compute_vc_map_params_ase

test_mem_perf: obj/test_mem_perf.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(FPGA_LIBS)
test_mem_perf_ase: obj/test_mem_perf.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(ASE_LIBS)

test_mem_latency: obj/test_mem_latency.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(FPGA_LIBS)
test_mem_latency_ase: obj/test_mem_latency.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(ASE_LIBS)

compute_latency_qos_params: obj/compute_latency_qos_params.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(FPGA_LIBS)
compute_latency_qos_params_ase: obj/compute_latency_qos_params.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(ASE_LIBS)

compute_vc_map_params: obj/compute_vc_map_params.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(FPGA_LIBS)
compute_vc_map_params_ase: obj/compute_vc_map_params.o $(OBJS)
	$(CXX) -o $@ $^ $(LDFLAGS) $(ASE_LIBS)

$(OBJDIR)/%.o: %.cpp | objdir
	$(CXX) $(CPPFLAGS) $(CFLAGS) $(OPTS) -c $< -o $@

clean:
	rm -rf test_mem_perf test_mem_latency compute_latency_qos_params compute_vc_map_params *_ase $(OBJDIR)

objdir:
	@mkdir -p $(OBJDIR)

.PHONY: all clean
