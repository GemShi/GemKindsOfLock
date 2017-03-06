//
//  ViewController.m
//  GemKindsOfLock
//
//  Created by GemShi on 2017/3/5.
//  Copyright © 2017年 GemShi. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import <os/lock.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"%@",[NSThread mainThread]);
    
    //自旋锁
    [self OSSpinLock];
    
    //信号量
//    [self semaphore];
    
    //pthread_mutex互斥锁
//    [self pthreadMutex];
    
    //递归锁
//    [self pthreadMutexattr];
    
    //普通锁
//    [self Lock];
    
//    [self Condition];
    
    //NSRecursiveLock递归锁
//    [self RecursiveLock];
    
    //条件锁
//    [self Synchronized];
    
    //条件锁：可以添加依赖，通过控制condition的值
//    [self ConditionLock];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - condition条件锁
-(void)ConditionLock
{
    NSConditionLock *conLock = [[NSConditionLock alloc]initWithCondition:0];
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        if ([conLock tryLockWhenCondition:0]) {
            NSLog(@"线程1执行");
            [conLock unlockWithCondition:1];
        }else{
            NSLog(@"lockfailed");
        }
    });
    dispatch_async(queue, ^{
        [conLock lockWhenCondition:2];
        NSLog(@"线程2执行");
        [conLock unlockWithCondition:3];
    });
    dispatch_async(queue, ^{
        [conLock lockWhenCondition:1];
        NSLog(@"线程3执行");
        [conLock unlockWithCondition:2];
    });
}

#pragma mark - 条件锁
-(void)Synchronized
{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        @synchronized (self) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"线程1");
        }
    });
    dispatch_async(queue, ^{
        @synchronized (self) {
            NSLog(@"线程2");
        }
    });
}

#pragma mark - 递归锁
-(void)RecursiveLock
{
    NSLock *rLock = [[NSLock alloc]init];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value) {
            [rLock lock];
            if (value > 0) {
                NSLog(@"线程%d", value);
                RecursiveBlock(value - 1);
            }
            [rLock unlock];
        };
        RecursiveBlock(4);
    });
}

#pragma mark - condition锁
-(void)Condition
{
    NSCondition *condition = [[NSCondition alloc]init];
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        [condition lock];
        NSLog(@"locked---1");
        //让一个线程等待一定时间
        [condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        [condition wait];
        NSLog(@"线程1执行");
        [condition unlock];
        NSLog(@"unlocked---1");
    });
    dispatch_async(queue, ^{
        [condition lock];
        NSLog(@"locked---2");
        [condition wait];
        NSLog(@"线程2执行");
        [condition unlock];
        NSLog(@"unlocked---2");
    });
    dispatch_async(queue, ^{
        sleep(2);
        //唤醒所有等待线程
//        NSLog(@"唤醒所有线程");
//        [condition broadcast];
        //唤醒一个等待线程
        NSLog(@"等待唤醒线程");
        [condition signal];
    });
}

#pragma mark - 普通锁
-(void)Lock
{
    NSLock *lock = [[NSLock alloc]init];
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"locking---1");
        [lock lock];
        NSLog(@"线程1执行");
        [NSThread sleepForTimeInterval:5];
        [lock unlock];
        NSLog(@"unlocked---1");
    });
    dispatch_async(queue, ^{
        NSLog(@"locking---2");
        //尝试在指定时间内加锁
        BOOL isLocked = [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        if (isLocked) {
            NSLog(@"线程2执行");
            [lock unlock];
            NSLog(@"unlocked---2");
        }else{
            NSLog(@"lockfailed");
        }
    });
}

#pragma mark - 递归锁
-(void)pthreadMutexattr
{
    static pthread_mutex_t pLock;
    pthread_mutexattr_t attr;
    //初始化attr并且给它赋予默认
    pthread_mutexattr_init(&attr);
    //设置锁类型，这边是设置为递归锁
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&pLock, &attr);
    //销毁一个属性对象，在重新进行初始化之前该结构不能重新使用
    pthread_mutexattr_destroy(&attr);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        static void (^RecursiveBlock)(int);
        RecursiveBlock = ^(int value){
            pthread_mutex_lock(&pLock);
            if (value > 0) {
                NSLog(@"value: %d", value);
                RecursiveBlock(value - 1);
            }
            pthread_mutex_unlock(&pLock);
        };
        RecursiveBlock(5);
    });
}

#pragma mark - 互斥锁
-(void)pthreadMutex
{
    static pthread_mutex_t pLock;
    pthread_mutex_init(&pLock, NULL);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"lock---1");
        pthread_mutex_lock(&pLock);
        NSLog(@"线程1执行");
        pthread_mutex_unlock(&pLock);
        NSLog(@"unlock---1");
    });
    dispatch_async(queue, ^{
        NSLog(@"lock---2");
        pthread_mutex_lock(&pLock);
        NSLog(@"线程2执行");
        pthread_mutex_unlock(&pLock);
        NSLog(@"unlock---2");
    });
}

#pragma mark - 信号量
-(void)semaphore
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"wait---1");
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, 3.0f * NSEC_PER_SEC));
        NSLog(@"线程1执行");
        dispatch_semaphore_signal(sema);
        NSLog(@"signal---1");
    });
    dispatch_async(queue, ^{
        NSLog(@"wait---2");
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, 3.0f * NSEC_PER_SEC));
        NSLog(@"线程2执行");
        dispatch_semaphore_signal(sema);
        NSLog(@"signal---2");
    });
}

#pragma mark - 自旋锁
-(void)OSSpinLock
{
    __block OSSpinLock oslock = OS_SPINLOCK_INIT;
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"locking---1");
        OSSpinLockLock(&oslock);
        sleep(5);
        NSLog(@"线程1执行");
        OSSpinLockUnlock(&oslock);
        NSLog(@"unlock---1");
    });
    dispatch_async(queue, ^{
        NSLog(@"locking---2");
        OSSpinLockLock(&oslock);
        NSLog(@"线程2执行");
        OSSpinLockUnlock(&oslock);
        NSLog(@"unlock---2");
    });
}

@end
