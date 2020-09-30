##
## Define base source files
##

include ../../../common/sw/common_include.mk

BASE_FILE_PATH = ../../base/sw
BASE_FILE_SRC = opae_svc_wrapper.cpp
BASE_FILE_INC = $(BASE_FILE_PATH)/opae_svc_wrapper.h $(BASE_FILE_PATH)/csr_mgr.h

VPATH = .:$(BASE_FILE_PATH)

CPPFLAGS += -I../../base/sw
LDFLAGS += -lboost_program_options -lMPF-cxx -lMPF -lopae-cxx-core
