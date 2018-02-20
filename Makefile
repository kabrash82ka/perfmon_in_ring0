obj-m := testz.o
testz-y := testo.o funcs.o

KDIR := /lib/modules/3.5.0-54-generic/build
PWD := $(shell pwd)
default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules
