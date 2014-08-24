//
//  JokeMenu.m
//  AriSpeaker
//
//  Created by Ariel Elkin on 06/08/2014.
//  Copyright (c) 2014 Saffron Digital. All rights reserved.
//

#import "JokeMenu.h"

@import Social;
@import MessageUI;

@implementation JokeMenu {
    UIButton *rapidFireButton;
    UIButton *shareJokeOnFacebookButton;
    UIButton *shareJokeOnTwitterButton;
    UIButton *shareJokeOnSMSButton;
    UIButton *closeMenuButton;

    UIDynamicAnimator *animator;
    UICollisionBehavior *collisionBehavior;

    NSMutableArray *buttonArray;
}

NSString *const kShouldRapidFire = @"kShouldRapidFire";

+ (instancetype)jokeMenu {
    JokeMenu *jokeMenu = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    return jokeMenu;
}

#pragma mark -
#pragma mark Actions

- (void)closeMenu {

    [animator removeBehavior:collisionBehavior];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        for (UIButton *button in buttonArray) {
            [button removeFromSuperview];
        }
        [self removeFromSuperview];
    });
}

- (void)toggleRapidFire {
    BOOL currentSetting = [[NSUserDefaults standardUserDefaults] boolForKey:kShouldRapidFire];

    NSString *rapidFireButtonTitle = [NSString stringWithFormat:@"Rapid Fire Mode %@", !currentSetting ? @"ON" : @"OFF"];
    [rapidFireButton setTitle:rapidFireButtonTitle forState:UIControlStateNormal];

    self.rapidFireModeChangedBlock(!currentSetting);

    [[NSUserDefaults standardUserDefaults] setBool:!currentSetting forKey:kShouldRapidFire];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)shareOnFacebook {
    self.shareOnSocialNetworkBlock(SLServiceTypeFacebook);
}

- (void)shareOnTwitter {
    self.shareOnSocialNetworkBlock(SLServiceTypeTwitter);
}

- (void)shareViaSMS {
    self.shareViaSMSBLock();
}

#pragma mark -
#pragma mark Setup

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        buttonArray = [NSMutableArray array];

        rapidFireButton = [UIButton buttonWithType:UIButtonTypeSystem];
        rapidFireButton.backgroundColor = [UIColor redColor];
        [rapidFireButton addTarget:self action:@selector(toggleRapidFire) forControlEvents:UIControlEventTouchUpInside];

        BOOL currentSetting = [[NSUserDefaults standardUserDefaults] boolForKey:kShouldRapidFire];
        BOOL canShareOnFacebook = [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
        BOOL canShareOnTwitter = [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
        BOOL canShareViaSMS = [MFMessageComposeViewController canSendText];


        NSString *rapidFireButtonTitle = [NSString stringWithFormat:@"Rapid Fire Mode %@", currentSetting ? @"ON" : @"OFF"];
        [rapidFireButton setTitle:rapidFireButtonTitle forState:UIControlStateNormal];

        [buttonArray addObject:rapidFireButton];


        if (canShareOnFacebook) {
            shareJokeOnFacebookButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [shareJokeOnFacebookButton setTitle:@"Share Joke On Facebook" forState:UIControlStateNormal];
            shareJokeOnFacebookButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            [shareJokeOnFacebookButton addTarget:self action:@selector(shareOnFacebook) forControlEvents:UIControlEventTouchUpInside];
            shareJokeOnFacebookButton.backgroundColor = [UIColor colorWithRed:0.29 green:0.40 blue:0.63 alpha:0.9];

            [buttonArray addObject:shareJokeOnFacebookButton];
        }

        if (canShareOnTwitter) {
            shareJokeOnTwitterButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [shareJokeOnTwitterButton setTitle:@"Share Joke On Twitter" forState:UIControlStateNormal];
            shareJokeOnTwitterButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            shareJokeOnTwitterButton.backgroundColor = [UIColor colorWithRed:0.33 green:0.67 blue:0.93 alpha:0.8];
            [shareJokeOnTwitterButton addTarget:self action:@selector(shareOnTwitter) forControlEvents:UIControlEventTouchUpInside];

            [buttonArray addObject:shareJokeOnTwitterButton];
        }

        if (canShareViaSMS) {
            shareJokeOnSMSButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [shareJokeOnSMSButton setTitle:@"Share Joke via SMS" forState:UIControlStateNormal];
            shareJokeOnSMSButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            shareJokeOnSMSButton.backgroundColor = [UIColor colorWithRed:0.84 green:0.67 blue:0.49 alpha:1];
            [shareJokeOnSMSButton addTarget:self action:@selector(shareViaSMS) forControlEvents:UIControlEventTouchUpInside];

            [buttonArray addObject:shareJokeOnSMSButton];

        }

        closeMenuButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [closeMenuButton setTitle:@"Close This Menu" forState:UIControlStateNormal];
        [closeMenuButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
        closeMenuButton.backgroundColor = [UIColor orangeColor];

        [buttonArray addObject:closeMenuButton];


        for (UIButton *button in buttonArray) {

            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self addSubview:button];
        }
    }
    return self;
}


- (void)didMoveToSuperview {
    [super didMoveToSuperview];

    if (self.superview == nil) return;

    for (UIButton *button in buttonArray) {
        [self addSubview:button];
    }
    rapidFireButton.frame = CGRectMake(0, 100, 150, 50);
    shareJokeOnFacebookButton.frame = CGRectMake(20+(arc4random()%50), 0, 100, 50);
    shareJokeOnTwitterButton.frame = CGRectMake(150+(arc4random()%50), 40+(arc4random()%50), 120, 50);
    closeMenuButton.frame = CGRectMake(70+(arc4random()%50), 150, 140, 50);
    shareJokeOnSMSButton.frame = CGRectMake(150+(arc4random()%50), 0, 70, 50);


    for (UIButton *button in buttonArray) {
        CGAffineTransform transform;
        CGFloat scale = (arc4random()%3)/10.0;
        transform = CGAffineTransformScale(transform, scale, scale);
        button.transform = transform;
        button.alpha = 0;
    }

    [UIView animateWithDuration:0.7
                     animations:^{
                         for (UIButton *button in buttonArray) {
                             button.transform = CGAffineTransformMakeScale(1, 1);
                             button.alpha = 1;
                         }


                     } completion:^(BOOL finished) {
                         [self addAnimator];
                     }];
}

- (void)addAnimator {
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];

    UIGravityBehavior *gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:buttonArray];
    gravityBeahvior.magnitude = 1.4;
    [animator addBehavior:gravityBeahvior];

    collisionBehavior = [[UICollisionBehavior alloc] initWithItems:buttonArray];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior:collisionBehavior];
}



@end