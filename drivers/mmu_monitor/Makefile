obj-m += mmu_monitor.o

modules:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

install:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules_install
	echo mmu_monitor > /etc/modules-load.d/mmu_monitor.conf

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
