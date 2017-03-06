//
//  ViewController.m
//  GemKindsOfLock
//
//  Created by GemShi on 2017/3/5.
//  Copyright © 2017年 GemShi. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"%@",[NSThread mainThread]);
    
    //自旋锁
//    [self OSSpinLock];
    
    //信号量
//    [self semaphore];
    
    //pthread_mutex互斥锁
//    [self pthreadMutex];
    
    //递归锁
//    [self pthreadMutexattr];
    
    //普通锁
    [self Lock];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [lock unlock];
        NSLog(@"unlocked---1");
    });
    dispatch_async(queue, ^{
        //尝试在指定时间内加锁
        NSLog(@"locking---2");
        BOOL isLocked = [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:3]];
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
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"wait---1");
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"线程1执行");
        dispatch_semaphore_signal(sema);
        NSLog(@"signal---1");
    });
    dispatch_async(queue, ^{
        NSLog(@"wait---2");
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSLog(@"线程2执行");
        dispatch_semaphore_signal(sema);
        NSLog(@"signal---2");
    });
}

#pragma mark - 自旋锁
-(void)OSSpinLock
{
    
}

@end
