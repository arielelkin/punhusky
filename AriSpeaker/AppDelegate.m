//
//  AppDelegate.m
//  AriSpeaker
//
//  Created by Ariel Elkin on 15/01/2014.
//  Copyright (c) 2014 MyCompanyName. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "Flurry.h"

@import AVFoundation;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    [self ignoreMuteSwitch];

    ViewController *vc = [ViewController new];
    [self.window setRootViewController:vc];

#if !DEBUG
    [Flurry setCrashReportingEnabled:YES];
    [Flurry startSession:@"VGXYJ2QPV4BDFBD6FJ4Z"];
#endif

    return YES;
}

- (void) ignoreMuteSwitch {

    AVAudioSession *mySession = [AVAudioSession sharedInstance];

    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback
                     error: &audioSessionError];

    if (audioSessionError != nil) {
        NSLog (@"Error setting audio session category.");
        return;
    }
}

@end
