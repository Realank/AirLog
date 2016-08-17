//
//  AirLogServer.h
//  AirLogServer
//
//  Created by Realank on 16/8/17.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AirLogServerDelegate <NSObject>
- (void)didReceiveData:(NSData *)data;
@end

@interface AirLogServer : NSObject
@property (nonatomic, weak)id<AirLogServerDelegate> delegate;
+ (instancetype)server;
- (void)startBroadCastWithPort:(NSInteger)port;
- (void)stopBroadCast;
@end
