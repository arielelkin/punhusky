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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    synth = [AVSpeechSynthesizer new];
    [synth setDelegate:self];

    [self buildUI];
    [self fetchJokes];

    isRapidFire = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)buildUI {

    jokeTellerImageView = [UIImageView new];
    [jokeTellerImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [jokeTellerImageView setContentMode:UIViewContentModeScaleAspectFit];
    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];
    [self.view addSubview:jokeTellerImageView];

    NSArray *jokeTellerImageViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[image]|" options:0 metrics:nil views:@{@"image": jokeTellerImageView}];
    [self.view addConstraints:jokeTellerImageViewConstraints];

    jokeTellerImageViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[image]|" options:0 metrics:nil views:@{@"image": jokeTellerImageView}];
    [self.view addConstraints:jokeTellerImageViewConstraints];

    labelView = [UIView new];
    [labelView setAlpha:0];
    [labelView setBackgroundColor:[UIColor whiteColor]];
    labelView.layer.cornerRadius = 10;
    [labelView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:labelView];

    jokeLabel = [UILabel new];
    [jokeLabel setNumberOfLines:0];
    [jokeLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:20]];
    [jokeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [labelView addSubview:jokeLabel];

    punchlineLabel = [UILabel new];
    [punchlineLabel setNumberOfLines:0];
    [punchlineLabel setFont:[UIFont fontWithName:@"ArialRoundedMTBold" size:20]];
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
}


#pragma mark -
#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self toggleLabels];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self toggleLabels];
}

#pragma mark -
#pragma mark UI Updates

- (void)toggleLabels {
    if (labelView.alpha == 0) {
        labelView.alpha = 0.7;
    }
    else labelView.alpha = 0;
}


#pragma mark -
#pragma mark Joke Engine

- (void)changeState {
    if (isRapidFire) {
        isRapidFire = NO;
    }
    else {
        isRapidFire = YES;
        [self sayNextLine];
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
                        [self sayNextLine];
                    }];

                }
            }
            else NSLog(@"JSON parsing Error: %@", jsonParsingError);
        }
    }];

    [jokeFetcher resume];

}

- (void)sayNextLine {

    if ([synth isSpeaking]) return;

    static BOOL askedQuestion;

    Joke *joke = jokeArray[currentJoke];

    NSString *line;

    if (!askedQuestion) {
        line = [joke question];
        [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];
        [jokeLabel setText:line];
    }
    else {
        line = [joke answer];
        [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyTells.jpg"]];
        [punchlineLabel setText:line];

        if (currentJoke == jokeArray.count) {
            line = @"OK, I'm done";
        }
        currentJoke++;
    }

    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:line];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-AU"]];
    utterance.pitchMultiplier = 0.3;
    utterance.rate = 0.1;

    [synth speakUtterance:utterance];

    askedQuestion = !askedQuestion;
}

- (void)laugh {
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:@"Mwahahahaahahahahaha"];

    AVSpeechSynthesisVoice *randomVoice = [AVSpeechSynthesisVoice speechVoices][arc4random()%[AVSpeechSynthesisVoice speechVoices].count];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:randomVoice.language]];
    utterance.rate = 0.5;
    utterance.pitchMultiplier = 0.3;
    [synth speakUtterance:utterance];

    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyLaughs.jpg"]];

    [jokeLabel setText:@"Mwahahahaahahahahaha"];
    [punchlineLabel setText:@" "];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)lastUtterance {

    if (currentJoke == 0) {
        if (isRapidFire) {
            [self sayNextLine];
        }
        return;
    }

    if (currentJoke == jokeArray.count) {
        return;
    }

    Joke *joke = jokeArray[currentJoke-1];
    BOOL justFinishedTellingJoke = [lastUtterance.speechString isEqualToString:[joke answer]];
    if (justFinishedTellingJoke) {
        [self laugh];
    }
    else {
        if (isRapidFire) {
            [self sayNextLine];
        }
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
