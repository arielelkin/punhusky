//
//  JokeMenu.h
//  AriSpeaker
//
//  Created by Ariel Elkin on 06/08/2014.
//  Copyright (c) 2014 Saffron Digital. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kShouldRapidFire;

@interface JokeMenu : UIView

+ (instancetype)jokeMenu;

@property (nonatomic, copy) void (^rapidFireModeChangedBlock)(BOOL isRapidFire);
@property (nonatomic, copy) void (^shareOnSocialNetworkBlock)(NSString *serviceType);
@property (nonatomic, copy) void (^shareViaSMSBLock)();

@end
