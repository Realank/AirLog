# AirLog
Print Log Via LAN

###Introduce
A tool that can show iOS app log in Mac via LAN

###Background
We often use `NSLog()` to print log to show some usefull information of our app

but sometimes, we can't debug our app online(with a USB cable connected to Mac)

Eg.: 
 
1. Our iDevice need to connect to Dock (MFI External Accessory)
2. Use our iDevice to measure GPS/Accelerator, we need move our iDevice

###How to use it

#####1. This tool has 2 part

1) iOS app static lib (as a client)

2) mac app (as a server)

the mac app will listen a port and the iOS app sends log to that port

#####2. import libAirLogClientLib.a and AirLogClientLib.h to your project

you can pull the contents in AirLogClientLib-Output Directory into your project directly
Or you can compile the project in AirLogClientLib
And you can refer to AirLogClientDemo project to see how to use the lib

In your code, you should:

1) import the header:

```
#import "AirLogClientLib.h"
```

2)comply the AirLogReadyDelegate protocol

```
@interface ViewController () <AirLogReadyDelegate>

@end

```

3) init the AirLogClientLib instant, assign a port and set the delegate

```
[[AirLogClientLib client] holdForServerWithPort:8001];
    [AirLogClientLib client].delegate = self;
```

4) finally, implement the delegate method.

This method can tell you whether the air log is ready.
```
- (void)AirLogIsReady:(BOOL)isReady{
    NSLog(@"AirLog is Ready:%d",isReady);
}
```



#####3. and enjoy it :)

Open the Mac app AirLogServer.app, 
and run your iOS app to send log (eg. `AirLog(@"Hello World");`)

#####4 copyleft & copyright

This project is inspired by http://www.oschina.net/code/snippet_260122_35359
And this project is under GPL2.0 lisence;

