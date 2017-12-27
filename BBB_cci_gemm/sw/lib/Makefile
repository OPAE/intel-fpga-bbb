include ../../base/sw/base_include.mk
NAME     := libGemm
SNAME    := $(NAME).a
DNAME    := $(NAME).so
SRC      := $(wildcard *.cpp)
OBJ      := $(SRC:.cpp=.o)
CPPFLAGS := -g3 -fPIC -I. -I$(BASE_FILE_PATH)
LDFLAGS  := -L.
LDLIBS   := -lopae-c -ljson-c
#LDLIBS   := -fopenmp

ifeq (,$(mkl))
CXXF      = g++
else ifeq (0,$(mkl))
CXXF      = g++
else
CXXF      = icc
CPPFLAGS += -DMKL
LDFLAGS  += -mkl
endif

ifneq (,$(ndebug))
else
CPPFLAGS += -DENABLE_DEBUG=1
endif
ifneq (,$(nassert))
else
CPPFLAGS += -DENABLE_ASSERT=1
endif

ifeq (,$(DESTDIR))
ifneq (,$(prefix))
CPPFLAGS += -I$(prefix)/include 
LDFLAGS  += -L$(prefix)/lib -Wl,-rpath-link -Wl,$(prefix)/lib -Wl,-rpath -Wl,$(prefix)/lib \
            -L$(prefix)/lib64 -Wl,-rpath-link -Wl,$(prefix)/lib64 -Wl,-rpath -Wl,$(prefix)/lib64 \
            
endif
else
ifeq (,$(prefix))
prefix = /usr/local
endif
CPPFLAGS += -I$(DESTDIR)$(prefix)/include
LDFLAGS  += -L$(DESTDIR)$(prefix)/lib -Wl,-rpath-link -Wl,$(prefix)/lib -Wl,-rpath -Wl,$(DESTDIR)$(prefix)/lib \
            -L$(DESTDIR)$(prefix)/lib64 -Wl,-rpath-link -Wl,$(prefix)/lib64 -Wl,-rpath -Wl,$(DESTDIR)$(prefix)/lib64 \
            
endif

.PHONY: all clean fclean re

all: $(SNAME) $(DNAME) install

$(SNAME): $(OBJ)
	$(AR) $(ARFLAGS) $@ $^

$(DNAME): LDFLAGS += -shared
$(DNAME): $(OBJ)
	$(CXXF) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(OBJ): %.o : %.cpp
	$(CXXF) $(CPPFLAGS) -c $< $(LDFLAGS) $(LDLIBS)
install:
	cp *.so $(prefix)/lib
clean:
	$(RM) $(OBJ)

fclean: clean
	$(RM) $(SNAME) $(DNAME)

re: fclean all
