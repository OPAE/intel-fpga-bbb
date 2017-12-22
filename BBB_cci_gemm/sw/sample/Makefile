include ../../base/sw/base_include.mk

ifeq (,$(mkl))
CXXF      = g++
else ifeq (0,$(mkl))
CXXF      = g++
else
CXXF      = icc
CPPFLAGS += -DMKL
LDFLAGS  += -mkl
endif
LDFLAGS += -L../lib/
LDFLAGS += -L../../../../BBB_cci_mpf/sw/build
LDFLAGS += -L../../base/sw
# Primary test name
TEST = gemm

# Build Directory

OBJDIR = obj

# Files and folders
SRCS = $(TEST).cpp $(BASE_FILE_SRC)
OBJS = $(addprefix $(OBJDIR)/,$(patsubst %.cpp,%.o,$(SRCS)))

.PHONY:all clean updateld mpf re

all: $(TEST) $(TEST)_ase

re: clean all

	
OBJ = gemm.o

gemm: lib svc_wrapper $(OBJ)
	$(CXXF) -o gemm gemm.o $(FPGA_LIBS) $(LDFLAGS) 

gemm_ase: lib svc_wrapper $(OBJ)
	$(CXXF) -o gemm_ase gemm.o  $(LDFLAGS) $(ASE_LIBS)
gemm.o : gemm.cpp gemm.h Makefile 

ifneq (,$(DESTDIR))
lib:
	cd ../lib && make DESTDIR=${DESTDIR} mkl=${mkl} re
svc_wrapper:
	cd ../../base/sw && make DESTDIR=${DESTDIR)} mkl=${mkl} re
else
lib:
	cd ../lib && make prefix=${prefix} mkl=${mkl} re
svc_wrapper:
	cd ../../base/sw && make prefix=${prefix} mkl=${mkl} re
endif

install:
	cp ../lib/libGemm.so ${prefix}/lib/
	cp ../../base/sw/libsvcwrapper.so ${prefix}/lib/
clean:
	cd ../lib && make fclean
	cd ../../base/sw && make fclean
	$(RM) ../../../../../opae/myinst/lib/libsvcwrapper.so
	$(RM) ../../../../../opae/myinst/lib/libGemm.so
	rm -rf $(TEST) $(TEST)_ase *.o $(OBJDIR)

