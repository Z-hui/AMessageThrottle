//
//  AMessageThrottle.h
//  AMessageThrottle
//
//  Created by DoZhui on 2020/12/22.
//  Copyright © 2020 DoZhui. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AMessageThrottleRule(ruleMode,threshold) \
if(![AMessageThrottle \
messageThrottle_validatoin:self \
sel:_cmd \
mode:ruleMode \
durationThreshold:threshold]) {\
return;\
}

NS_ASSUME_NONNULL_BEGIN

/**
 消息节流模式
 
 - MTPerformModeFirstly: Throttle 模式：执行最靠前发送的消息，后面发送的消息会被忽略
 - MTPerformModeLast: Throttle 模式：执行最靠后发送的消息，前面发送的消息会被忽略，执行时间会有延时
 - MTPerformModeDebounce: Debounce 模式：消息发送后延迟一段时间执行，如果在这段时间内继续发送消息，则重新计时
 */
typedef NS_ENUM(NSUInteger, ARulePerformMode) {
    ARulePerformModeFirstly,
    ARulePerformModeLast,
    ARulePerformModeDebounce,
};


@interface AMessageThrottle : NSObject

+ (instancetype)shareInstace;

/**
  是否使用严谨模式（用户修改了系统时间）
  YES:使用严谨模式需要实现correctionForSystemTime校准当前时间
  NO只要当前时间与上次请求时间绝对值大于时间间隔即可（默认NO）
  ！！！如果APP启动后修改系统时间使用严谨模式但是未校准时间会导致当前方法一直被截流
 */
@property (nonatomic,assign)BOOL isStrict;

/**
 校正系统时间所需的差值。用户可能手动修改系统时间，此时可以计算服务器时间与系统时间的差值进行修正。
 单位：秒
 */
@property (nonatomic) NSTimeInterval correctionForSystemTime;


+ (BOOL)messageThrottle_validatoin:(id)instance sel:(SEL)selector mode:(ARulePerformMode)mode durationThreshold:(NSTimeInterval)durationThreshold;


@end

NS_ASSUME_NONNULL_END
