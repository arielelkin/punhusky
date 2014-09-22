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

    UITextView *aboutTextView;

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

    [UIView animateWithDuration:0.3
                     animations:^{
                         aboutTextView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [aboutTextView removeFromSuperview];
                         aboutTextView.alpha = 1;
                     }
     ];

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

- (void)aboutButtonPressed {

    if (!aboutTextView) {

        aboutTextView = [[UITextView alloc] init];
        aboutTextView.backgroundColor = [UIColor colorWithRed:105/255.0 green:95/255.0 blue:90/255.0 alpha:1];
        aboutTextView.editable = NO;
        aboutTextView.attributedText = [self aboutLabelString];
        aboutTextView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.superview addSubview:aboutTextView];

        NSArray *aboutViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[aboutViewTextField]-|" options:0 metrics:nil views:@{@"aboutViewTextField": aboutTextView}];
        [self.superview addConstraints:aboutViewConstraints];

        aboutViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[aboutViewTextField(200)]" options:0 metrics:nil views:@{@"aboutViewTextField": aboutTextView}];
        [self.superview addConstraints:aboutViewConstraints];
    }

    [self.superview addSubview:aboutTextView];

}

- (NSAttributedString *)aboutLabelString {

    NSDictionary *regularAttributes = @{
                                 NSForegroundColorAttributeName: [UIColor blackColor],
                                 NSKernAttributeName: @0.7,
                                 NSFontAttributeName : [UIFont fontWithName:@"GillSans" size:14]
                                 };
    NSDictionary *boldAttributes =  @{
                                      NSForegroundColorAttributeName: [UIColor blackColor],
                                      NSKernAttributeName: @0.7,
                                      NSFontAttributeName : [UIFont fontWithName:@"GillSans-Bold" size:14]
                                      };

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@"" attributes:regularAttributes];


    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"This app offers three virtual comedians telling jokes.\n\n" attributes:regularAttributes];
    [result appendAttributedString:string];

    string = [[NSAttributedString alloc] initWithString:@"What kind of jokes are these?\n" attributes:boldAttributes];
    [result appendAttributedString:string];
    string = [[NSAttributedString alloc] initWithString:@"Puns, plays on words, far-fetched, stupid; in a good way. They're also known as jokes that are only funny at 3am.\n\n" attributes:regularAttributes];
    [result appendAttributedString:string];

    string = [[NSAttributedString alloc] initWithString:@"Aren't you ashamed?\n" attributes:boldAttributes];
    [result appendAttributedString:string];
    string = [[NSAttributedString alloc] initWithString:@"No.\n\n" attributes:regularAttributes];
    [result appendAttributedString:string];

    string = [[NSAttributedString alloc] initWithString:@"Where do the jokes come from?\n" attributes:boldAttributes];
    [result appendAttributedString:string];
    string = [[NSAttributedString alloc] initWithString:@"The jokes come straight from a webpage dedicated to these kinds of jokes: " attributes:regularAttributes];
    [result appendAttributedString:string];
    NSMutableAttributedString *lineWithLink = [[NSMutableAttributedString alloc] initWithString:@"www.reddit.com/r/3amjokes" attributes:regularAttributes];
    [lineWithLink addAttribute:NSLinkAttributeName value:@"http://www.reddit.com/r/3amjokes" range:NSMakeRange(0, lineWithLink.length)];
    [result appendAttributedString:lineWithLink];
    string = [[NSAttributedString alloc] initWithString:@". All these jokes have been submitted and voted on by the page's users.\n\n" attributes:regularAttributes];
    [result appendAttributedString:string];

    string = [[NSAttributedString alloc] initWithString:@"Can I submit a joke?.\n" attributes:boldAttributes];
    [result appendAttributedString:string];
    lineWithLink = [[NSMutableAttributedString alloc] initWithString:@"Sure. Sign up or login to www.reddit.com, and submit it to www.reddit.com/r/3amjokes\n\n" attributes:regularAttributes];
    [lineWithLink addAttribute:NSLinkAttributeName value:@"http://www.reddit.com/r/3amjokes" range:NSMakeRange(lineWithLink.length-27, 25)];
    [result appendAttributedString:lineWithLink];

    string = [[NSAttributedString alloc] initWithString:@"Can I share a joke on Facebook/Twitter?\n" attributes:boldAttributes];
    [result appendAttributedString:string];
    string = [[NSAttributedString alloc] initWithString:@"Sure. If these options are not available to you on the app's menu, open your device's Settings and log in to Facebook and/or Twitter.\n\n" attributes:regularAttributes];
    [result appendAttributedString:string];


    string = [[NSAttributedString alloc] initWithString:@"Acknowledgements\n" attributes:boldAttributes];
    [result appendAttributedString:string];
    string = [[NSAttributedString alloc] initWithString:@"The following people tested the early versions of this app, provided very useful suggestions, and encouraged me all along:\nAlejandro J.\nBrian H.\nGal M.\nJavier E.\nHari K.S.\nMonika K.\nMorel N.\nMary R.\n\nMuch love to the /r/3amjokes community.\n\n" attributes:regularAttributes];
    [result appendAttributedString:string];

    string = [[NSAttributedString alloc] initWithString:@"Ariel Elkin\n" attributes:boldAttributes];
    [result appendAttributedString:string];
    lineWithLink = [[NSMutableAttributedString alloc] initWithString:@"http://arielelkin.github.io\n" attributes:regularAttributes];
    [lineWithLink addAttribute:NSLinkAttributeName value:@"http://arielelkin.github.io" range:NSMakeRange(0, lineWithLink.length)];
    [result appendAttributedString:lineWithLink];
    lineWithLink = [[NSMutableAttributedString alloc] initWithString:@"ariel@arivibes.com" attributes:regularAttributes];
    [lineWithLink addAttribute:NSLinkAttributeName value:@"mailto:ariel@arivibes.com" range:NSMakeRange(0, lineWithLink.length)];
    [result appendAttributedString:lineWithLink];

    string = [[NSAttributedString alloc] initWithString:@" ← Drop me a line!\n" attributes:regularAttributes];
    [result appendAttributedString:string];





    return result;
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


        UIButton *aboutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *aboutButtonImage = [UIImage imageNamed:@"info_button"];
        [aboutButton setImage:aboutButtonImage forState:UIControlStateNormal];
        [aboutButton addTarget:self action:@selector(aboutButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        aboutButton.frame = CGRectMake(0, 0, aboutButtonImage.size.width, aboutButtonImage.size.height);
        aboutButton.layer.cornerRadius = aboutButtonImage.size.width/4;
        aboutButton.center = CGPointMake(aboutButtonImage.size.width, 20);

        [self addSubview:aboutButton];

        [buttonArray addObject:aboutButton];



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


    rapidFireButton.frame = CGRectMake(0, 100, 150, 50);
    shareJokeOnFacebookButton.frame = CGRectMake(60+(arc4random()%50), 0, 100, 50);
    shareJokeOnTwitterButton.frame = CGRectMake(150+(arc4random()%50), 40+(arc4random()%50), 120, 50);
    closeMenuButton.frame = CGRectMake(70+(arc4random()%50), 150, 140, 50);
    shareJokeOnSMSButton.frame = CGRectMake(150+(arc4random()%50), 0, 70, 50);


    for (UIButton *button in buttonArray) {
        CGAffineTransform transform;
        CGFloat scale = 0.3;
        transform = CGAffineTransformScale(transform, scale, scale);
        button.transform = transform;
        button.alpha = 0;
    }

    for (UIButton *button in buttonArray) {
        [self addSubview:button];
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