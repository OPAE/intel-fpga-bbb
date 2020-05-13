CFLAGS+=-g -I.. -std=c11

all: test_basic

test_basic: test_basic.o
	$(CC) -o $@ $^ $(LDFLAGS) -pthread

clean:
	rm -rf test_basic *.o
