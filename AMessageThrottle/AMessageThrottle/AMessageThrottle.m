//
//  AMessageThrottle.m
//  AMessageThrottle
//
//  Created by DoZhui on 2020/12/22.
//  Copyright © 2020 DoZhui. All rights reserved.
//

#import "AMessageThrottle.h"

/**
 当前方法状态
 ARuleRequestStateFree 空闲
 ARuleRequestStateWatting 延迟中
 ARuleRequestStateFinish 任务执行完成
 */
typedef NS_ENUM(NSUInteger, ARuleRequestState) {
    ARuleRequestStateFree,
    ARuleRequestStateWatting,
    ARuleRequestStateFinish,
};

@interface ARule:NSObject
/*
 target, 可以为实例，类，元类(可以使用 mt_metaClass 函数获取元类）
 */
@property (nonatomic, weak) id target;
/**
 消息节流模式
 */
@property (nonatomic, assign) ARulePerformMode mode;
/**
 消息节流模式
 */
@property (nonatomic, assign) ARuleRequestState requestState;
/**
 消息节流时间的阈值，单位：秒
 */
@property (nonatomic) NSTimeInterval durationThreshold;
/**
 消息节流方法名
 */
@property (nonatomic) SEL aliasSelector;
/**
 方法最后一次执行时间
 */
@property (nonatomic) NSTimeInterval lastTimeRequest;

@end

@implementation ARule

static NSTimeInterval rule_currentTime() {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if ([AMessageThrottle shareInstace].isStrict) {
        now += AMessageThrottle.shareInstace.correctionForSystemTime;
    }
    return now;
}


static BOOL isMoreThanDurationThreshold(ARule *rule) {
    NSTimeInterval nowTime = rule_currentTime();
    NSTimeInterval interval;
    
    if ([AMessageThrottle shareInstace].isStrict) {
        interval = nowTime - rule.lastTimeRequest;
    } else {
        interval = fabs(nowTime - rule.lastTimeRequest);
    }
    
    return (interval >= rule.durationThreshold);
}


- (BOOL)rule_vailadation {
    
    ARule *rule = self;
    
    if (!rule) {
        return YES;
    }
    
    if (rule.durationThreshold <= 0) {
        return YES;
    }
    
    id target = rule.target;
    SEL selector = rule.aliasSelector;
    
    BOOL isStrict = NO;
    if ([AMessageThrottle shareInstace].isStrict) {
        isStrict = YES;
    }
    
    NSTimeInterval now = rule_currentTime();
    
    switch (rule.mode) {
        case ARulePerformModeFirstly: {
            if (isMoreThanDurationThreshold(rule)) {
                rule.lastTimeRequest = now;
                return YES;
            } else {
                return NO;
            }
            break;
        }
        case ARulePerformModeLast: {
            if (rule.requestState == ARuleRequestStateFree) {
                rule.requestState = ARuleRequestStateWatting;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(rule.durationThreshold * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    rule.requestState = ARuleRequestStateFinish;
                    if ([target respondsToSelector:selector]) {
                        // 屏蔽performSelector-leak警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [target performSelector:selector withObject:nil];
                    }
                });
                return NO;
            } else if (rule.requestState == ARuleRequestStateWatting){
                return NO;
            } else if (rule.requestState == ARuleRequestStateFinish) {
                rule.lastTimeRequest = now;
                rule.requestState = ARuleRequestStateFree;
                return YES;
            }
            
            break;
        }
        case ARulePerformModeDebounce: {
            rule.lastTimeRequest = now;
            if (rule.requestState == ARuleRequestStateFree) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(rule.durationThreshold * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //当前时间大于要求时间间隔
                    if (isMoreThanDurationThreshold(rule)) {
                        rule.requestState = ARuleRequestStateFinish;
                        if ([target respondsToSelector:selector]) {
                            [target performSelector:selector withObject:nil];
                        }
                    }
                });
            }
            if (rule.requestState == ARuleRequestStateFinish) {
                rule.requestState = ARuleRequestStateFree;
                return YES;
            }
            break;
        }
    }
    return NO;
}



@end


static AMessageThrottle *messageThrottle = nil;

@interface AMessageThrottle ()

@property (nonatomic, strong) NSMapTable *mapTable;

@end

@implementation AMessageThrottle

+ (instancetype)shareInstace {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        messageThrottle = [[AMessageThrottle alloc] init];
    });
    return messageThrottle;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mapTable = [[NSMapTable alloc] initWithKeyOptions:(NSPointerFunctionsWeakMemory) valueOptions:(NSPointerFunctionsStrongMemory) capacity:100];
    }
    return self;
}

- (ARule *)messageThrottleRule:(id)instance sel:(SEL)selector mode:(ARulePerformMode)mode durationThreshold:(NSTimeInterval)durationThreshold {
    
    NSMutableDictionary *rulesDictionary;
    
    rulesDictionary = [self.mapTable objectForKey:instance];
    if (!rulesDictionary) {
        rulesDictionary = [NSMutableDictionary dictionary];
    }
    
    ARule *rule = rulesDictionary[NSStringFromSelector(selector)];
    if (!rule) {
        ARule *rule = [[ARule alloc] init];
        rule.target = instance;
        rule.aliasSelector = selector;
        rule.mode = mode;
        rule.durationThreshold = durationThreshold;
        [rulesDictionary setObject:rule forKey:NSStringFromSelector(selector)];
        [self.mapTable setObject:rulesDictionary forKey:instance];
    }
    return rule;
}

+ (BOOL)messageThrottle_validatoin:(id)target sel:(SEL)selector mode:(ARulePerformMode)mode durationThreshold:(NSTimeInterval)durationThreshold {
    ARule *rule = [[AMessageThrottle shareInstace] messageThrottleRule:target sel:selector mode:mode durationThreshold:durationThreshold];
    if (rule) {
        return [rule rule_vailadation];
    }
    return NO;
}

@end
