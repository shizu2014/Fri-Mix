//
//  NSDate+TimeZone.m
//  YHCommon
//
//  Created by gxd on 2018/1/19.
//  Copyright © 2018年 Go Brother. All rights reserved.
//

#import "NSDate+TimeZone.h"

@implementation NSDate (TimeZone)

- (NSDateComponents *)dateComponentsWithGMT8 {
    
    return [self dateComponentsWithTimeZone:@"Asia/Shanghai"];
}

- (NSDateComponents *)dateComponentsWithTimeZone:(NSString *)timeZomeString {
    
    NSDateFormatter *strToDataFormatter = [[NSDateFormatter alloc] init];
    [strToDataFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    
    [strToDataFormatter setTimeZone:[NSTimeZone timeZoneWithName:timeZomeString]];
    NSString *GMT8DateString = [strToDataFormatter stringFromDate:self];
    NSArray *timeList = [GMT8DateString componentsSeparatedByString:@"-"];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    @try {
        dateComponents.timeZone = [NSTimeZone timeZoneWithName:timeZomeString];
        dateComponents.year = [timeList[0] integerValue];
        dateComponents.month = [timeList[1] integerValue];
        dateComponents.day = [timeList[2] integerValue];
        dateComponents.hour = [timeList[3] integerValue];
        dateComponents.minute = [timeList[4] integerValue];
        dateComponents.second = [timeList[5] integerValue];
    } @catch (NSException *exception) {
        
    }
    
    return dateComponents;
}

+ (NSDate *)dateWithGMT8DateComponents:(NSDateComponents *)dateComponents {
    
    return [self dateWithDateComponents:dateComponents withTimeZone:@"Asia/Shanghai"];
}

+ (NSDate *)dateWithDateComponents:(NSDateComponents *)dateComponents withTimeZone:(NSString *)timeZomeString {
    
    NSDateFormatter *strToDataFormatter = [[NSDateFormatter alloc] init];
    
    [strToDataFormatter setTimeZone:[NSTimeZone timeZoneWithName:timeZomeString]];
    [strToDataFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [strToDataFormatter dateFromString:[NSString stringWithFormat:@"%td-%02td-%02td %02td:%02td:%02td", dateComponents.year, dateComponents.month, dateComponents.day, dateComponents.hour, dateComponents.minute, dateComponents.second]];
    
    return date;
}

@end