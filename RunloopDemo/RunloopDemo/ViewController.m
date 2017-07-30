//
//  ViewController.m
//  RunloopDemo
//
//  Created by 王化强 on 2017/7/22.
//  Copyright © 2017年 whqfor. All rights reserved.
//

#import "ViewController.h"

// 监听runloop循环，让runloop循环一次加载一张
// 创建一个数组，装任务（代码--block）


typedef void(^RunloopBlock)();
@interface ViewController () <UITableViewDataSource>

@property (nonatomic, assign) BOOL finished;
@property (nonatomic, strong) NSMutableArray *taskes; // 任务数组
@property (nonatomic, assign) NSInteger maxQueueLength; // 最大任务量

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _finished = NO;
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        
        
        /*
         
         runloop运行循环（死循环）
         目的：保证runloop所在线程不退出
         负责监听事件iOS触摸、时钟、网络
         
         Source事件源：按照函数调用栈
         Source0：非Source1事件
         Source1：系统内核事件
         
         
         NSDefaultRunLoopMode   一般处理timer/网络事件
         UITrackingRunLoopMode   UI事件
         NSRunLoopCommonModes    转为模式
         initial初始化
         内部时钟事件
         
         */
        
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        // 开启runloop保住线程生命
//        [[NSRunLoop currentRunLoop] run]; // 每个线程都有一个runloop但是默认不开启
        
        while (!_finished) {
           [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
        }
        
        NSLog(@"run"); // runloop是个死循环这里不会走
        
    }];
    
    [thread start];
    
//    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, <#dispatchQueue#>);
//    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, <#intervalInSeconds#> * NSEC_PER_SEC, <#leewayInSeconds#> * NSEC_PER_SEC);
//    dispatch_source_set_event_handler(timer, ^{
//        <#code to be executed when timer fires#>
//    });
//    dispatch_resume(timer);
    
    [NSTimer scheduledTimerWithTimeInterval:0.0001 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
    
    _maxQueueLength = 18;
    _taskes = [[NSMutableArray alloc] init];
    
    // runloop优化tableview方法
    [self addRunloopObserver];
}

- (void)timerMethod{
    // 什么都不做，保持runloop运行
}

- (void)timerAction{
    NSLog(@"timerAction");
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _finished = YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
//     耗时操作1
//     耗时操作2
//     耗时操作3
    
    [self addTask:^{
        // 耗时操作1
    }];
    [self addTask:^{
        // 耗时操作2
    }];
    [self addTask:^{
        // 耗时操作3
    }];
    
    
    return cell;
}

- (void)addRunloopObserver{
    // 获取runloop
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    // 定义观察者
    static CFRunLoopObserverRef defaultrunloopModel;
    // 创建上下文
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    
    // 创建
    defaultrunloopModel = CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, YES, 0, &Callback, &context);
    // 添加到当前runloop中
    CFRunLoopAddObserver(runloop, defaultrunloopModel, kCFRunLoopCommonModes);
    
}


/*
 typedef struct {
 CFIndex	version;
 void *	info;
 const void *(*retain)(const void *info);
 void	(*release)(const void *info);
 CFStringRef	(*copyDescription)(const void *info);
 } CFRunLoopObserverContext;
 
 */

static void Callback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
//    NSLog(@"回调");
    // 取出任务执行
    NSLog(@"context info %@", info);
    ViewController *VC = (__bridge ViewController *)info;
    
    if (VC.taskes.count == 0) {
        return;
    }
    RunloopBlock task = VC.taskes.firstObject;
    task();
    [VC.taskes removeObjectAtIndex:0];
}

- (void)addTask:(RunloopBlock)task{
    [self.taskes addObject:task];
    // 保证数组里只放18个任务
    if (self.taskes.count > self.maxQueueLength) {
        [self.taskes removeObjectAtIndex:0];
    }
}

@end
