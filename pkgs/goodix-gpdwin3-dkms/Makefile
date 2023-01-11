BASE_NAME := goodix

obj-m := goodix-gpdwin3.o
goodix-gpdwin3-objs := $(BASE_NAME).o $(BASE_NAME)_fwupload.o

all: modules

clean modules modules_install:
	$(MAKE) -C $(KERNEL_SOURCE_DIR) M=$(PWD) $@

install: modules_install

