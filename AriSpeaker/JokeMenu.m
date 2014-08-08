//
//  JokeMenu.m
//  AriSpeaker
//
//  Created by Ariel Elkin on 06/08/2014.
//  Copyright (c) 2014 Saffron Digital. All rights reserved.
//

#import "JokeMenu.h"

@implementation JokeMenu {
    UIButton *rapidFireButton;
    UIButton *shareJokeOnFacebookButton;
    UIButton *shareOnTwitterButton;
    UIButton *closeMenuButton;

    UIDynamicAnimator *animator;
    UICollisionBehavior *collisionBehavior;

    NSArray *buttonArray;
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
    self.shareOnFacebookBlock();
}

- (void)shareOnTwitter {
    self.shareOnTwitterBlock();
}

#pragma mark -
#pragma mark Setup

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        rapidFireButton = [UIButton buttonWithType:UIButtonTypeSystem];
        rapidFireButton.backgroundColor = [UIColor redColor];
        [rapidFireButton addTarget:self action:@selector(toggleRapidFire) forControlEvents:UIControlEventTouchUpInside];

        BOOL currentSetting = [[NSUserDefaults standardUserDefaults] boolForKey:kShouldRapidFire];

        NSString *rapidFireButtonTitle = [NSString stringWithFormat:@"Rapid Fire Mode %@", currentSetting ? @"ON" : @"OFF"];
        [rapidFireButton setTitle:rapidFireButtonTitle forState:UIControlStateNormal];

        shareJokeOnFacebookButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [shareJokeOnFacebookButton setTitle:@"Share Joke On Facebook" forState:UIControlStateNormal];
        shareJokeOnFacebookButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [shareJokeOnFacebookButton addTarget:self action:@selector(shareOnFacebook) forControlEvents:UIControlEventTouchUpInside];
        shareJokeOnFacebookButton.backgroundColor = [UIColor colorWithRed:0.29 green:0.40 blue:0.63 alpha:0.9];

        shareOnTwitterButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [shareOnTwitterButton setTitle:@"Share Joke On Twitter" forState:UIControlStateNormal];
        shareOnTwitterButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        shareOnTwitterButton.backgroundColor = [UIColor colorWithRed:0.33 green:0.67 blue:0.93 alpha:0.8];

        closeMenuButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [closeMenuButton setTitle:@"Close This Menu" forState:UIControlStateNormal];
        [closeMenuButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
        closeMenuButton.backgroundColor = [UIColor orangeColor];

        buttonArray = @[rapidFireButton, shareJokeOnFacebookButton, shareOnTwitterButton, closeMenuButton];

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
        [button sizeToFit];
    }
    rapidFireButton.frame = CGRectMake(0, 100, 150, 50);
    shareJokeOnFacebookButton.frame = CGRectMake(20+(arc4random()%50), 0, 100, 50);
    shareOnTwitterButton.frame = CGRectMake(140+(arc4random()%50), (arc4random()%50), 140, 50);
    closeMenuButton.frame = CGRectMake(70+(arc4random()%50), 150, 140, 50);


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