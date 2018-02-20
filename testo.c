/*
The purpose of this program is to read perfmon events for
IO.

To build:
	make

To load/remove:
	sudo insmod testz.ko
	sudo rmmod testz
*/
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kthread.h>
#include <linux/err.h>
#include <linux/irqflags.h>
#include <linux/string.h>

extern void _dxtestpm1(unsigned int * results);

static struct task_struct *dx_mon_task;

/*local kthread*/
static int dx_run(void *arg)
{
	unsigned int perfmon_results[10];
	memset(perfmon_results, 0, (10*sizeof(unsigned int)));

	local_irq_disable(); //disable all interrupts
	_dxtestpm1(perfmon_results);
	local_irq_enable();

	/*print the count results*/
	printk(KERN_ALERT "hello: rdmsr prev PERFEVTSEL0:edx=0x%X:eax=0x%X",
			perfmon_results[2],
			perfmon_results[1]);
	printk(KERN_ALERT "hello: local apic id=0x%X\n", perfmon_results[0]);
	printk(KERN_ALERT "hello: pmc0[0]:eax=%d\n", perfmon_results[5]);
	printk(KERN_ALERT "hello: pmc0[1]:eax=%d, %d\n", perfmon_results[6], (perfmon_results[6] - perfmon_results[5]));
	printk(KERN_ALERT "hello: i/o val read=0x%X\n", perfmon_results[7]);

	return 0;
}

static int hello_init(void)
{

	printk(KERN_ALERT "hello_init\n");

	dx_mon_task = kthread_run(dx_run, /*function to run*/
			0, /*data ptr for args*/
			"dx_mon");
	if(IS_ERR(dx_mon_task))
	{
		printk(KERN_ALERT "hello: kthread_run() fail.\n");
		return 0;
	}

	return 0;
}

static void hello_exit(void)
{
	printk(KERN_ALERT "hello_exit\n");
}

module_init(hello_init);
module_exit(hello_exit);
