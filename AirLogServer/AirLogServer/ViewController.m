//
//  ViewController.m
//  AirLogServer
//
//  Created by Realank on 16/8/17.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "ViewController.h"
#import "AirLogServer.h"

@interface ViewController ()<AirLogServerDelegate>
@property (weak) IBOutlet NSTextField *portTextField;
@property (weak) IBOutlet NSButton *listenButton;
@property (nonatomic,strong) AirLogServer *server;
@property (unsafe_unretained) IBOutlet NSTextView *logTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _server = [AirLogServer server];
    [_server setDelegate:self];
    
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)didReceiveData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",string);
    NSAttributedString *atstring = [[NSAttributedString alloc] initWithString:string];
    [[_logTextView textStorage] appendAttributedString:atstring];
    [_logTextView scrollRangeToVisible:NSMakeRange(_logTextView.string.length, 0)];
}
- (IBAction)listenAction:(id)sender {
    static BOOL isListening = NO;
    isListening = !isListening;
    if (isListening) {
        [_listenButton setTitle:@"正在监听"];
        [_server startBroadCastWithPort:[_portTextField.stringValue integerValue]];
    }else{
        [_listenButton setTitle:@"开始监听"];
        [_server stopBroadCast];
    }
}

@end
