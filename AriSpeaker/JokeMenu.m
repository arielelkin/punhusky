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
    UIButton *buttonTwo;
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

#pragma mark -
#pragma mark Setup

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        rapidFireButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        rapidFireButton.backgroundColor = [UIColor redColor];
        [rapidFireButton addTarget:self action:@selector(toggleRapidFire) forControlEvents:UIControlEventTouchUpInside];

        BOOL currentSetting = [[NSUserDefaults standardUserDefaults] boolForKey:kShouldRapidFire];

        NSString *rapidFireButtonTitle = [NSString stringWithFormat:@"Rapid Fire Mode %@", currentSetting ? @"ON" : @"OFF"];
        [rapidFireButton setTitle:rapidFireButtonTitle forState:UIControlStateNormal];

        buttonTwo = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [buttonTwo setTitle:@"Share Joke" forState:UIControlStateNormal];
        buttonTwo.backgroundColor = [UIColor greenColor];

        closeMenuButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [closeMenuButton setTitle:@"Close This Menu" forState:UIControlStateNormal];
        [closeMenuButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
        closeMenuButton.backgroundColor = [UIColor orangeColor];

        buttonArray = @[rapidFireButton, buttonTwo, closeMenuButton];

        for (UIButton *button in buttonArray) {
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
    buttonTwo.frame = CGRectMake(20+(arc4random()%50), 0, 100, 50);
    closeMenuButton.frame = CGRectMake(70+(arc4random()%50), 150, 140, 50);


    for (UIButton *button in buttonArray) {
        CGAffineTransform transform;
        CGFloat scale = (arc4random()%3)/10.0;
        transform = CGAffineTransformScale(transform, scale, scale);
        button.transform = transform;
        button.alpha = 0;
    }

    [UIView animateKeyframesWithDuration:0.7
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionCalculationModePaced
                              animations:^{

                                  [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0 animations:^{
                                      rapidFireButton.transform = CGAffineTransformMakeScale(1, 1);
                                      rapidFireButton.alpha = 1;
                                      [self layoutIfNeeded];
                                  }];
                                  [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0 animations:^{
                                      buttonTwo.transform = CGAffineTransformMakeScale(1, 1);
                                      buttonTwo.alpha = 1;
                                      [self layoutIfNeeded];
                                  }];
                                  [UIView addKeyframeWithRelativeStartTime:0.75 relativeDuration:0 animations:^{
                                      closeMenuButton.transform = CGAffineTransformMakeScale(1, 1);
                                      closeMenuButton.alpha = 1;
                                      [self layoutIfNeeded];
                                  }];


                              } completion:^(BOOL finished) {
                                  [self addAnimator];
                              }];
}

- (void)addAnimator {
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];

    UIGravityBehavior *gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[rapidFireButton, buttonTwo, closeMenuButton]];
    gravityBeahvior.magnitude = 1.4;
    [animator addBehavior:gravityBeahvior];

    collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[rapidFireButton, buttonTwo, closeMenuButton]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior:collisionBehavior];
}



@end