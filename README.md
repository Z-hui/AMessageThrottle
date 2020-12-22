# AMessageThrottle
消息截流

```
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
```
  
!!!目前只能对不含参数的方法截流
