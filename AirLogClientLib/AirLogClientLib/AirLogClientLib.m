//
//  AirLogClientLib.m
//  AirLogClientLib
//
//  Created by Realank on 16/8/17.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "AirLogClientLib.h"
#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"

@interface AirLogClientLib ()
{
    GCDAsyncSocket *tcpSocket;
    GCDAsyncUdpSocket *udpSocket;
    
    NSInteger userPort;
    
    BOOL tcpConnected;
    BOOL shouldSendPool;
    NSMutableString *writePool;
    
    NSTimeInterval sendTimeStamp; // use for judge if connection is alive
}
@end

void _AirLog(NSString *format, ...)
{
    va_list list;
    va_start(list, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:list];
    va_end(list);
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"[MM/dd HH:mm:ss.SSS] "];
    string = [[formatter stringFromDate:[NSDate date]] stringByAppendingString:string];
    [[AirLogClientLib client] send:string];
}



@implementation AirLogClientLib

static AirLogClientLib *instance = nil;

+ (instancetype)client
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
        NSError *error = nil;
        
        writePool = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)heartBeat
{
    // send a empty string
    if ([tcpSocket isConnected]) {
        // don't use @"" instead !!!
        NSData *data = [@"\0" dataUsingEncoding:NSUTF8StringEncoding];
        [tcpSocket writeData:data withTimeout:10 tag:0];
    }
}

- (void)send:(NSString *)string
{
    string = [string stringByAppendingString:@"\n"];
    
    if ([tcpSocket isConnected]) {
        if (shouldSendPool) {
            string = [NSString stringWithFormat:@"%@%@", writePool, string];
            [writePool setString:@""];
            shouldSendPool = NO;
        }
        
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [tcpSocket writeData:data withTimeout:10 tag:0];
        
        sendTimeStamp = [[NSDate date] timeIntervalSince1970];
    } else {
        // append into queue
        shouldSendPool = YES;
        [writePool appendString:string];
    }
}

- (void)startToSendLog
{
    [self send:[NSString stringWithFormat:@"%@ 已连接",[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]]];
}

#pragma mark - UDP
- (void)holdForServerWithPort:(NSInteger)port{
//    NSLog(@"Wait BroadCast");
    userPort = port;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error1 = nil;
        BOOL result1 = [udpSocket bindToPort:userPort > 0 ? userPort : 9000 error:&error1];
        if (!result1) {
            NSLog(@"%@", [error1 localizedDescription]);
            return;
        }
    });

    NSError *error = nil;
    BOOL result = [udpSocket beginReceiving:&error];
    if (!result) {
        NSLog(@"%@", [error localizedDescription]);
    }
}

#pragma mark GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
//    NSLog(@"UDP Received");
    [udpSocket pauseReceiving];
    
    if (!tcpConnected) {
        NSString *host = [self ipv4HostFromAddress:address];
        NSError *error = nil;
        BOOL result = [tcpSocket connectToHost:host onPort:userPort > 0 ? userPort : 9000 error:&error];
        if (!result) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            tcpConnected = YES;
        }
    }
}

- (NSString *)ipv4HostFromAddress:(NSData *)address
{
    NSString *host = [GCDAsyncUdpSocket hostFromAddress:address];
    return host;
}

#pragma mark - TCP

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(heartBeat) object:nil];
    [self performSelector:@selector(heartBeat) withObject:nil afterDelay:9];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [tcpSocket readDataWithTimeout:10 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
//    NSLog(@"TCP Connected");
    
    [self startToSendLog];
    if (_delegate) {
        [_delegate AirLogIsReady:YES];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
//    NSLog(@"TCP Disconnected:%@", [err localizedDescription]);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(heartBeat) object:nil];
    tcpConnected = NO;
    [sock disconnect];
    
    [self holdForServerWithPort:userPort];
    if (_delegate) {
        [_delegate AirLogIsReady:NO];
    }
}

@end
