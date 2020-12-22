//
//  ViewController.m
//  AMessageThrottle
//
//  Created by DoZhui on 2020/12/22.
//  Copyright © 2020 DoZhui. All rights reserved.
//

#import "ViewController.h"
#import "AMessageThrottle.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(test) userInfo:nil repeats:YES];
    // Do any additional setup after loading the view.
}

- (void)test {
    
    /**
        在需要截流的方法中加上该宏即可
        arg1为截流模式
        arg2为时间间隔
     */
    
    AMessageThrottleRule(ARulePerformModeLast,2);
    
    NSLog(@"---currentTime:%f",[[NSDate date] timeIntervalSince1970]);
}


@end
