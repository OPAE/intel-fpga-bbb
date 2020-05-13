obj-m += fpga_near_mem_map.o

modules:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

install:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules_install
	echo fpga_near_mem_map > /etc/modules-load.d/fpga_near_mem_map.conf

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
