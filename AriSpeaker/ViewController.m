//
//  ViewController.m
//  AriSpeaker
//
//  Created by Ariel Elkin on 15/01/2014.
//  Copyright (c) 2014 MyCompanyName. All rights reserved.
//

#import "ViewController.h"
#import "Joke.h"

@import AVFoundation;

typedef NS_ENUM(NSUInteger, JokeEngineState){
    JokeEngineStateIdle,
    JokeEngineStateSetup,
    JokeEngineStatePunchline,
    JokeEngineStateLaughing
};

@interface ViewController ()<AVSpeechSynthesizerDelegate>
@end

NSString *const kDateJokesLastFetched = @"kDateJokesLastFetched";

@implementation ViewController {
    AVSpeechSynthesizer *synth;

    NSURLSessionDataTask *jokeFetcher;

    NSMutableArray *jokeArray;
    NSInteger currentJoke;

    UIImageView *jokeTellerImageView;

    BOOL isRapidFire;

    UIDynamicAnimator *animator;

    UIView *labelView;
    UILabel *jokeLabel;
    UILabel *punchlineLabel;

    UIImageView *curtainImageView;
    NSMutableArray *curtainConstraints;

    JokeEngineState jokeEngineState;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    synth = [AVSpeechSynthesizer new];
    [synth setDelegate:self];

    [self buildUI];
    [self addCurtain];

    isRapidFire = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self removeCurtain];
}

- (void)addCurtain {
    curtainImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"curtain"]];
    curtainImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:curtainImageView];

    NSArray *curtainConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[curtain]" options:0 metrics:nil views:@{@"curtain": curtainImageView}];
    NSArray *curtainConstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[curtain]|" options:0 metrics:nil views:@{@"curtain": curtainImageView}];

    curtainConstraints = [NSMutableArray array];
    [curtainConstraints addObjectsFromArray:curtainConstraintsH];
    [curtainConstraints addObjectsFromArray:curtainConstraintsV];

    [self.view addConstraints:curtainConstraints];
}

- (void)removeCurtain {

    [self.view removeConstraints:curtainConstraints];
    curtainImageView.translatesAutoresizingMaskIntoConstraints = YES;

    [UIView animateWithDuration:5
                          delay:0.2
         usingSpringWithDamping:0.7
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         CGAffineTransform translate = CGAffineTransformMakeTranslation(-700, 0);
                         CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI/15);
                         CGAffineTransform transform = CGAffineTransformConcat(translate, rotate);

                         curtainImageView.transform = transform;

                     }
                     completion:^(BOOL finished) {

                         [UIView animateWithDuration:1 animations:^{
                             curtainImageView.center = CGPointMake(curtainImageView.center.x-150, curtainImageView.center.y);
                         } completion:^(BOOL finished) {

                                              [curtainImageView removeFromSuperview];
                                          }];
                     }
     ];
}

- (void)applicationDidBecomeActive {

    NSDate *dateJokesLastFetched = [[NSUserDefaults standardUserDefaults] valueForKey:kDateJokesLastFetched];

    BOOL noJokes = (jokeArray == nil);
    BOOL itsBeenMoreThan24HoursSinceWeFetchedJokes = [dateJokesLastFetched timeIntervalSinceNow] > (60 * 60 * 24);
    BOOL lastTimeWeFetchedJokesThereWasNoInternet = [((Joke *)jokeArray[2]).question isEqualToString:@"I need"];

    if (noJokes ||
        itsBeenMoreThan24HoursSinceWeFetchedJokes ||
        lastTimeWeFetchedJokesThereWasNoInternet)
    {
        [self fetchJokes];
    }
}


- (void)buildUI {

    jokeTellerImageView = [UIImageView new];
    jokeTellerImageView.frame = self.view.frame;
    [jokeTellerImageView setContentMode:UIViewContentModeScaleAspectFit];
    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];
    [self.view addSubview:jokeTellerImageView];

    labelView = [UIView new];
    [labelView setAlpha:0];
    [labelView setBackgroundColor:[UIColor clearColor]];
    labelView.layer.cornerRadius = 10;
    [labelView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:labelView];

    jokeLabel = [UILabel new];
    [jokeLabel setNumberOfLines:0];
//    [jokeLabel setPreferredMaxLayoutWidth:[UIScreen mainScreen].bounds.size.width];
//    [jokeLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [jokeLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:30]];
    [jokeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [labelView addSubview:jokeLabel];

    punchlineLabel = [UILabel new];
    [punchlineLabel setNumberOfLines:0];
//    [punchlineLabel setPreferredMaxLayoutWidth:[UIScreen mainScreen].bounds.size.width];
//    [punchlineLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [punchlineLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:30]];
    [punchlineLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [labelView addSubview:punchlineLabel];

    NSDictionary *viewsDicts = NSDictionaryOfVariableBindings(labelView, jokeLabel, punchlineLabel);

    NSArray *labelViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[labelView]|" options:0 metrics:nil views:viewsDicts];
    [self.view addConstraints:labelViewConstraints];

    labelViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[labelView]|" options:0 metrics:nil views:viewsDicts];
    [self.view addConstraints:labelViewConstraints];

    NSArray *jokeLabelConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[jokeLabel]-|" options:0 metrics:nil views:viewsDicts];
    [labelView addConstraints:jokeLabelConstraints];

    NSArray *punchlineLabelConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[punchlineLabel]-|" options:0 metrics:nil views:viewsDicts];
    [labelView addConstraints:punchlineLabelConstraints];

    NSArray *labelConstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[jokeLabel]-[punchlineLabel]" options:0 metrics:nil views:viewsDicts];
    [labelView addConstraints:labelConstraintsV];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.view addGestureRecognizer:tapGesture];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.view addGestureRecognizer:panGesture];
}

- (void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer {

    CGFloat xTranslation = [gestureRecognizer translationInView:self.view].x;

    jokeTellerImageView.transform = CGAffineTransformRotate(jokeTellerImageView.transform, xTranslation/4000);

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.2
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             jokeTellerImageView.transform = CGAffineTransformMakeScale(1.8, 1.6);
                         }
                         completion:nil
         ];

        [punchlineLabel setText:@" "];
    }

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {

        [UIView animateWithDuration:((double)(20 + arc4random()%40)/100.0)
                              delay:0
             usingSpringWithDamping:0.4
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             jokeTellerImageView.transform = CGAffineTransformIdentity;
                         }
                         completion:nil
         ];

        if (fabs(xTranslation) < 5) return;

        CGPoint velocity = [gestureRecognizer velocityInView:self.view];

        [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@""];
        [synth speakUtterance:utterance];
        [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];

        if(velocity.x < 0) {
            //swiped left
            currentJoke++;
        }
        else {
            //swiped right
            if (currentJoke > 0) {
                currentJoke--;
            }
        }

        jokeEngineState = JokeEngineStateSetup;
        [self saySetup];
    }
}

- (void)tapped:(UITapGestureRecognizer *)gestureRecognizer {

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self toggleLabels];
    }
}

#pragma mark -
#pragma mark UI Updates

- (void)toggleLabels {
    if (jokeTellerImageView.alpha == 1) {
        jokeTellerImageView.alpha = 0.7;
        labelView.alpha = 1;
    }
    else {
        labelView.alpha = 0;
        jokeTellerImageView.alpha = 1;
    }
}

- (void)fetchJokes {

    NSURL *redditFrontPageJSON = [NSURL URLWithString:@"http://www.reddit.com/r/3amjokes/.json?limit=100"];

    jokeFetcher = [[NSURLSession sharedSession] dataTaskWithURL:redditFrontPageJSON completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        if (error == nil) {
            NSError *jsonParsingError = nil;
            NSDictionary *redditJSON = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParsingError];

            if (jsonParsingError == nil) {

                jokeArray = [NSMutableArray array];

                NSArray *redditJSONPosts = redditJSON[@"data"][@"children"];

                for (NSDictionary *post in redditJSONPosts) {
                    NSString *question = post[@"data"][@"title"];
                    NSString *answer = post[@"data"][@"selftext"];
                    [jokeArray addObject:[Joke jokeWithQuestion:question answer:answer]];
                }

                [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kDateJokesLastFetched];
                [[NSUserDefaults standardUserDefaults] synchronize];

                if (isRapidFire) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                        jokeEngineState = JokeEngineStateSetup;
                        [self saySetup];

                    }];
                }
            }
            else NSLog(@"JSON parsing Error: %@", jsonParsingError);
        }
        else {
            if ([error.domain isEqualToString:NSURLErrorDomain]) {

                jokeArray = [NSMutableArray array];

                for (int i = 0; i < 100; i++) {
                    [jokeArray addObject:[Joke jokeWithQuestion:@"I need" answer:@"Internet"]];
                }
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self sayShouldConnectToInternet];
                }];
            }
        }
    }];

    [jokeFetcher resume];

}

- (void)sayShouldConnectToInternet {

    NSString *line = @"Hi. Sorry, but I need internet. Please connect and open the app again!";

    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];
    [jokeLabel setText:line];

    jokeEngineState = JokeEngineStatePunchline;

    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:line];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-AU"]];
    utterance.pitchMultiplier = 0.2;
    utterance.rate = 0.2;

    [synth speakUtterance:utterance];

}

- (void)saySetup {

    Joke *joke = jokeArray[currentJoke];

    NSString *line;

    line = [joke question];
    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];
    [jokeLabel setText:line];


    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:line];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-AU"]];
    utterance.pitchMultiplier = 0.4;
    utterance.rate = 0.2;

    [synth speakUtterance:utterance];
}

- (void)sayPunchline {

    Joke *joke = jokeArray[currentJoke];

    NSString *line;

    line = [joke answer];
    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyTells.jpg"]];
    [punchlineLabel setText:line];


    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:line];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-AU"]];
    utterance.pitchMultiplier = 0.3;
    utterance.rate = 0.1;

    [synth speakUtterance:utterance];
}

- (void)laugh {

    NSString *laughterString;

    int laughterType = arc4random()%2;

    if (laughterType == 0) {
        laughterString = @"Huehuehuehuehuehuehuehuehue";
    }
    else if (laughterType == 1) {
        laughterString = @"Mwahahahaahahahahaha";
    }


    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:laughterString];

    AVSpeechSynthesisVoice *randomVoice = [AVSpeechSynthesisVoice speechVoices][arc4random()%[AVSpeechSynthesisVoice speechVoices].count];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:randomVoice.language]];
    utterance.rate = 0.3;
    utterance.pitchMultiplier = 0.3;
    [synth speakUtterance:utterance];

    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyLaughs.jpg"]];


    [jokeLabel setText:laughterString];
    [punchlineLabel setText:@" "];

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)lastUtterance {

    if (currentJoke >= jokeArray.count) {
        return;
    }

    if (jokeEngineState == JokeEngineStateSetup) {
        jokeEngineState = JokeEngineStatePunchline;
        [self sayPunchline];
    }

    else if (jokeEngineState == JokeEngineStatePunchline) {
        jokeEngineState = JokeEngineStateLaughing;
        [self laugh];
        currentJoke++;
    }

    else if (jokeEngineState == JokeEngineStateLaughing) {
        jokeEngineState = JokeEngineStateSetup;
        [self saySetup];
    }
}

#pragma mark -
#pragma mark Orientation

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark -
#pragma mark View disappears

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (jokeFetcher.state == NSURLSessionTaskStateRunning || jokeFetcher.state == NSURLSessionTaskStateSuspended) {
        [jokeFetcher cancel];
    }
}

#pragma mark -
#pragma mark Offline Tests

- (void)fetchTestJokes {

    NSData *localJSONData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"test_jokes" withExtension:@"json"]];

    NSError *jsonParsingError = nil;
    NSDictionary *redditJSON = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:localJSONData options:kNilOptions error:&jsonParsingError];

    if (jsonParsingError == nil) {

        jokeArray = [NSMutableArray array];
        
        NSArray *redditJSONPosts = redditJSON[@"data"][@"children"];
        
        for (NSDictionary *post in redditJSONPosts) {
            NSString *question = post[@"data"][@"title"];
            NSString *answer = post[@"data"][@"selftext"];
            [jokeArray addObject:[Joke jokeWithQuestion:question answer:answer]];
        }
        if (isRapidFire) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self saySetup];
            }];
            
        }
    }
    else NSLog(@"JSON parsing Error: %@", jsonParsingError);
}

@end
