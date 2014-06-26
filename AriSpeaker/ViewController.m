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

    JokeEngineState jokeEngineState;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    synth = [AVSpeechSynthesizer new];
    [synth setDelegate:self];

    [self buildUI];
    [self fetchJokes];

    jokeEngineState = JokeEngineStateSetup;

    isRapidFire = YES;
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
    [jokeLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:30]];
    [jokeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [labelView addSubview:jokeLabel];

    punchlineLabel = [UILabel new];
    [punchlineLabel setNumberOfLines:0];
    [punchlineLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:30]];
    [punchlineLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [labelView addSubview:punchlineLabel];

    NSDictionary *viewsDicts = NSDictionaryOfVariableBindings(labelView, jokeLabel, punchlineLabel);

    NSArray *labelViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[labelView]|" options:0 metrics:nil views:viewsDicts];
    [self.view addConstraints:labelViewConstraints];

    labelViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[labelView(200)]" options:0 metrics:nil views:viewsDicts];
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

    jokeTellerImageView.transform = CGAffineTransformRotate(jokeTellerImageView.transform, M_PI/(xTranslation-10));

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:((double)(20 + arc4random()%60)/100.0)
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

        if(velocity.x < 0) {

            [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@""];
            [synth speakUtterance:utterance];
            [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];

            currentJoke++;
            jokeEngineState = JokeEngineStateSetup;
            [self saySetup];


        }
        else
        {
            //swiped right
        }
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

    NSURL *redditFrontPageJSON = [NSURL URLWithString:@"http://www.reddit.com/r/3amjokes.json"];

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
                if (isRapidFire) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self saySetup];
                    }];

                }
            }
            else NSLog(@"JSON parsing Error: %@", jsonParsingError);
        }
    }];

    [jokeFetcher resume];

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

    int laughterType = arc4random()%1;

    if (laughterType == 0) {
        laughterString = @"Huehuehuehuehuehuehuehuehue";
    }
    else if (laughterType == 1) {
        laughterString = @"Mwahahahaahahahahaha";
    }


    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:laughterString];

    AVSpeechSynthesisVoice *randomVoice = [AVSpeechSynthesisVoice speechVoices][arc4random()%[AVSpeechSynthesisVoice speechVoices].count];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:randomVoice.language]];
    utterance.rate = 0.5;
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

@end
