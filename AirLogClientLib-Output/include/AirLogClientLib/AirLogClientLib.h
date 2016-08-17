//
//  AirLogClientLib.h
//  AirLogClientLib
//
//  Created by Realank on 16/8/17.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AirLogReadyDelegate <NSObject>

- (void)AirLogIsReady:(BOOL)isReady;

@end

extern void _AirLog(NSString *format, ...);
//#define AirLog(...) _AirLog(__VA_ARGS__)
#define AirLog(fmt, ...) _AirLog((@"%s:" fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);

@interface AirLogClientLib : NSObject

@property(nonatomic, weak) id<AirLogReadyDelegate> delegate;

+ (instancetype)client;
- (void)holdForServerWithPort:(NSInteger)port;
- (void)send:(NSString *)string;

@end
