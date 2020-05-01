obj-m += fpga_vtp_mapper.o

modules:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

install:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules_install
	echo fpga_vtp_mapper > /etc/modules-load.d/fpga_vtp_mapper.conf

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
