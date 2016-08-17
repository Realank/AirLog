//
//  ViewController.m
//  AirLogClientDemo
//
//  Created by Realank on 16/8/17.
//  Copyright © 2016年 Realank. All rights reserved.
//

#import "ViewController.h"
#import "AirLogClientLib.h"

@interface ViewController () <AirLogReadyDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[AirLogClientLib client] holdForServerWithPort:9000];
    [AirLogClientLib client].delegate = self;
}

- (IBAction)sendAirLog:(id)sender {
    AirLog(@"Hello World");
}

- (void)AirLogIsReady:(BOOL)isReady{
    NSLog(@"AirLog is Ready:%d",isReady);
}

@end
