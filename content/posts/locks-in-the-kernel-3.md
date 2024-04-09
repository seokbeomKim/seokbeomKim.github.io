---
draft: true
title: "리눅스 커널 락 종류 (3/5)"
date: 2019-06-04T11:40:12+09:00
categories:
- Computer Science
tags:
- semaphore
keywords:
- tech
---

이번 포스팅에서는 리눅스 커널 락의 세 번째인 세마포어에 대해
기술한다. 리눅스의 세마포어(semaphore)는 휴면하는 락이라고 생각하면
된다. 태스크가 이미 사용 중인 세마포어를 얻으려고 하면, 세마포어는
해당 태스크를 대기큐에 넣고 휴면 상태로 만든다. 그 다음 프로세서는
자유롭게 다른 코드를 실행한다. 세마포어가 다시 사용 가능해지면
대기큐의 태스크 하나를 깨우고 이 태스크가 세마포어를 사용하게 된다.

세마포어는 아래와 같은 경우에 적합하다.


태스크, 즉 프로세스의 상태는 TASK_RUNNING, TASK_INTERRUPTIBLE,
TASK_UNINTERRUPTIBLE 로 나눌 수 있으며, 이 중 TASK_INTERRUPTIBLE
상태가 프로세스가 휴면에 진입한 상태로 프로세스를 깨우면 다시
TASK_RUNNING(실행 대기) 상태로 변경된다. 실행 대기 중인 프로세스는
CPU에 attach 되면 실행되며 이 때의 상태값 또한 TASK_RUNNING이라는 점에
유의하자.

# 세마포어 특징


* 락을 기다리는 태스크가 휴면 상태(TASK_INTERRUPTIBLE)로 전환되므로,
  세마포어는 오랫동안 락을 사용하는 경우에 적합하다.
* 반대로 락 사용 시간이 짧은 경우에는 휴면 상태 전환 및 대기큐 관리,
  태스크 깨우기 등의 부가 작업을 처리하는 시간이 락 사용을 넘어설 수
  있기 때문에 세마포어 사용이 적절하지 않다.
* 락이 사용 중이면 실행 스레드가 휴면 상태로 전환되기 때문에
  스케쥴링이 불가능한 인터럽트 컨텍스트가 아닌 프로세스 컨텍스트에서만
  세마포어를 사용할 수 있다.
* 다른 프로세스가 같은 세마포어를 얻으려 하는 경우라도 데드락에 빠지는
  일이 발생하지 않으므로 락을 잡으려는 다른 프로세스도 휴면 상태로
  전환되므로 결국은 실행이 계속된다.
* 세마포어를 얻기 위해서는 휴면 상태로 전환될 수 있는데, 스핀락이 걸린
  상태에서는 휴면 상태가 될 수 없으므로 세마포어를 얻으려고 할 때에는
  스핀락이 걸려 있으면 안된다.

즉, 간단하게 정리하면, 세마포어를 사용하는 대부분의 경우는 다른 락을
사용할 수 없는 상황이다. 동기화를 사용하는 사용자 공간 코드와
마찬가지로 휴면이 필요한 상황이라면, 사용할 수 있는 방법은 세마포어
뿐이다. 만일, 세마포어와 스핀락 사이에서 선택을 해야하는 상황이라면
락을 쥐고 있는 시간으로 결정해야 하며, 스핀락과 달리 세마포어는 커널
선점을 비활성화시키지 않기 때문에 세마포어를 잡고 있는 코드 또한
선점될 수 있다.

# 세마포어 종류

세마포어는 아래와 같은 종류가 있다.

* 카운팅 세마포어
* 바이너리 세마포어: 카운트 값이 최대 1이 되는 카운팅 세마포어
* 리더-라이터 세마포어

## 리더-라이터 세마포어
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <asm/uaccess.h>
#include <linux/semaphore.h>
#include <linux/sched.h>
#include <linux/delay.h>

#define FIRST_MINOR 0
#define MINOR_CNT 1

static dev_t dev;
static struct cdev c_dev;
static struct class *cl;
static struct task_struct *task;
static struct rw_semaphore rwsem;

int open(struct inode *inode, struct file *filp)
{
    printk(KERN_INFO "Inside open\n");
    task = current;
    return 0;
}

int release(struct inode *inode, struct file *filp)
{
    printk(KERN_INFO "Inside close\n");
    return 0;
}

ssize_t read(struct file *filp, char *buff, size_t count, loff_t *offp)
{
    printk("Inside read\n");
    down_read(&rwsem);
    printk(KERN_INFO "Got the Semaphore in Read\n");
    printk("Going to Sleep\n");
    ssleep(30);
    up_read(&rwsem);
    return 0;
}

ssize_t write(struct file *filp, const char *buff, size_t count, loff_t *offp)
{
    printk(KERN_INFO "Inside write. Waiting for Semaphore...\n");
    down_write(&rwsem);
    printk(KERN_INFO "Got the Semaphore in Write\n");
    up_write(&rwsem);
    return count;
}


struct file_operations fops = {
read: read,
write: write,
open: open,
release: release
};


int rw_sem_init(void) {
    int ret;
    struct device *dev_ret;

    if ((ret = alloc_chrdev_region(&dev, FIRST_MINOR, MINOR_CNT, "rws")) < 0) {
        return ret;
    }
    printk("Major Nr: %d\n", MAJOR(dev));

    cdev_init(&c_dev, &fops);

    if ((ret = cdev_add(&c_dev, dev, MINOR_CNT)) < 0) {
        unregister_chrdev_region(dev, MINOR_CNT);
        return ret;
    }

    if (IS_ERR(cl = class_create(THIS_MODULE, "chardrv"))) {
        cdev_del(&c_dev);
        unregister_chrdev_region(dev, MINOR_CNT);
        return PTR_ERR(cl);
    }

    if (IS_ERR(dev_ret = device_create(cl, NULL, dev, NULL, "mychar%d", 0))) {
        class_destroy(cl);
        cdev_del(&c_dev);
        unregister_chrdev_region(dev, MINOR_CNT);
        return PTR_ERR(dev_ret);
    }

    init_rwsem(&rwsem);

    return 0;
}

void rw_sem_cleanup(void) {
    printk("Clean up semaphores...\n");

    device_destroy(cl, dev);
    class_destroy(cl);
    cdev_del(&c_dev);
    unregister_chrdev_region(dev, MINOR_CNT);
}

module_init(rw_sem_init);
module_exit(rw_sem_cleanup);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Sukbeom Kim - code from SysPlay Workshops");
MODULE_DESCRIPTION("Reader Writer Semaphore Demo");

