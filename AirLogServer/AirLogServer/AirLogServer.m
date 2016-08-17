//
//  AirLogServer.m
//  AirLogServer
//
//  Created by Realank on 16/8/17.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "AirLogServer.h"
#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"

@implementation AirLogServer
{
    NSTimer *broadCastTimer;
    GCDAsyncUdpSocket *udpSocket;
    GCDAsyncSocket *tcpSocket;
    GCDAsyncSocket *handleSocket;
    NSInteger userPort;
    BOOL isForceDisconnect;
}

static AirLogServer *instance = nil;

+ (instancetype)server
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)showInnerLog:(NSString *)string
{
    string = [NSString stringWithFormat:@">>>%@\n", string];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self showLog:data];
}

- (void)showLog:(NSData *)data
{
    if ([_delegate conformsToProtocol:@protocol(AirLogServerDelegate)]) {
        [_delegate didReceiveData:data];
    }
}

#pragma mark - UDP

- (void)stopBroadCast{
    isForceDisconnect = YES;
    [tcpSocket disconnect];
}

- (void)startBroadCastWithPort:(NSInteger)port
{
    userPort = port;

    
    NSError *error = nil;
    NSLog(@"TCP Bind");
    BOOL result = [tcpSocket acceptOnPort:userPort>0?userPort:9000 error:&error];
    if (!result) {
        NSLog(@"%@", [error localizedDescription]);
    }
    NSLog(@"UDP Set Broadcast Enable");
    result = [udpSocket enableBroadcast:YES error:&error];
    if (!result) {
        NSLog(@"%@", [error localizedDescription]);
    }
    isForceDisconnect = NO;
    
    [broadCastTimer invalidate];
    broadCastTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(sendBroadCast) userInfo:nil repeats:YES];
    [broadCastTimer fire];
}


- (void)sendBroadCast
{
    [self showInnerLog:@"UDP发送广播"];
    NSData *data = [@"\0" dataUsingEncoding:NSUTF8StringEncoding];
    [udpSocket sendData:data toHost:@"255.255.255.255" port:userPort>0?userPort:9000 withTimeout:9 tag:0];
}

#pragma mark - TCP
#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [broadCastTimer invalidate];
    handleSocket = newSocket;
    [self showInnerLog:@"TCP请求接受"];
    
    [handleSocket readDataWithTimeout:10 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [handleSocket readDataWithTimeout:10 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self showLog:data];
    
    NSData *emptyData = [@"\0" dataUsingEncoding:NSUTF8StringEncoding];
    [handleSocket writeData:emptyData withTimeout:10 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [self showInnerLog:[NSString stringWithFormat:@"TCP断开:%@", err]];
    [sock disconnect];
    
    handleSocket = nil;
    if (!isForceDisconnect) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startBroadCastWithPort:userPort];
        });
        
    }
}

@end
