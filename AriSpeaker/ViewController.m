//
//  ViewController.m
//  AriSpeaker
//
//  Created by Ariel Elkin on 15/01/2014.
//  Copyright (c) 2014 MyCompanyName. All rights reserved.
//

#import "ViewController.h"

@import AVFoundation;

@interface Joke : NSObject
@property (readonly) NSString *question;
@property (readonly) NSString *answer;
+ (instancetype)jokeWithQuestion:(NSString *)question answer:(NSString *)answer;
@end

@interface Joke ()
@property NSString *question;
@property NSString *answer;
@end

@implementation Joke
+ (instancetype)jokeWithQuestion:(NSString *)question answer:(NSString *)answer {
    Joke *joke = [[self alloc] init];
    [joke setQuestion:question];
    [joke setAnswer:answer];
    return joke;
}
@end

@interface ViewController ()<AVSpeechSynthesizerDelegate>

@end

@implementation ViewController {
    AVSpeechSynthesizer *synth;
    NSMutableArray *posts;
    NSInteger currentJoke;

    UIImageView *jokeTellerImageView;

    BOOL isRapidFire;

    UIButton *rapidFireButton;

    UIDynamicAnimator *animator;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    synth = [AVSpeechSynthesizer new];
    [synth setDelegate:self];

    jokeTellerImageView = [UIImageView new];
    [jokeTellerImageView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.view addSubview:jokeTellerImageView];
    [jokeTellerImageView setContentMode:UIViewContentModeScaleAspectFit];
    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];

    NSArray *jokeTellerImageViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[image]|" options:0 metrics:nil views:@{@"image": jokeTellerImageView}];
    [self.view addConstraints:jokeTellerImageViewConstraints];

    jokeTellerImageViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[image]|" options:0 metrics:nil views:@{@"image": jokeTellerImageView}];
    [self.view addConstraints:jokeTellerImageViewConstraints];

    rapidFireButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rapidFireButton setImage:[UIImage imageNamed:@"rapidfire_on"] forState:UIControlStateNormal];
    [rapidFireButton setContentMode:UIViewContentModeCenter];
    [rapidFireButton addTarget:self action:@selector(changeState) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:rapidFireButton];
    [rapidFireButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    NSArray *buttonConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[rapidFireButton]|" options:0 metrics:nil views:@{@"rapidFireButton": rapidFireButton}];
    [self.view addConstraints:buttonConstraintsH];

    NSArray *buttonConstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[rapidFireButton]|" options:0 metrics:nil views:@{@"rapidFireButton": rapidFireButton}];
    [self.view addConstraints:buttonConstraintsV];

    isRapidFire = YES;
}

- (void)changeState {
    if (isRapidFire) {
        isRapidFire = NO;
        [rapidFireButton setImage:[UIImage imageNamed:@"rapidfire_off"] forState:UIControlStateNormal];

        [rapidFireButton.layer removeAllAnimations];

    }
    else {
        isRapidFire = YES;
        [rapidFireButton setImage:[UIImage imageNamed:@"rapidfire_on"] forState:UIControlStateNormal];

        [self animateRapidFire];

        [self sayNextLine];
    }
}

- (void)animateRapidFire {
    [UIView animateWithDuration:0.1
                          delay:0
         usingSpringWithDamping:0.2
          initialSpringVelocity:0
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         rapidFireButton.center = CGPointMake(rapidFireButton.center.x, rapidFireButton.center.y-5);
                     }
                     completion:nil
     ];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSURL *redditFrontPageJSON = [NSURL URLWithString:@"http://www.reddit.com/r/3amjokes.json"];

    NSURLSessionDataTask *jokeFetcher = [[NSURLSession sharedSession] dataTaskWithURL:redditFrontPageJSON completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        if (error == nil) {
            NSError *jsonParsingError = nil;
            NSDictionary *redditJSON = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonParsingError];

            if (jsonParsingError == nil) {

                posts = [NSMutableArray array];

                NSArray *redditJSONPosts = redditJSON[@"data"][@"children"];

                for (NSDictionary *post in redditJSONPosts) {
                    NSString *question = post[@"data"][@"title"];
                    NSString *answer = post[@"data"][@"selftext"];
                    [posts addObject:[Joke jokeWithQuestion:question answer:answer]];
                }
                if (isRapidFire) [self sayNextLine];
            }
            else NSLog(@"JSON parsing Error: %@", jsonParsingError);
        }
    }];

    [jokeFetcher resume];

    [self animateRapidFire];

}

- (void)sayNextLine {

    if ([synth isSpeaking]) return;

    static BOOL askedQuestion;

    Joke *joke = posts[currentJoke];

    NSString *line;

    if (!askedQuestion) {
        line = [joke question];
        [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];
    }
    else {
        line = [joke answer];
        [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyTells.jpg"]];

        if (currentJoke == posts.count) {
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

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)lastUtterance {

    if (currentJoke == 0) {
        if (isRapidFire) {
            [self sayNextLine];
        }
        return;
    }

    if (currentJoke == posts.count) {
        return;
    }

    Joke *joke = posts[currentJoke-1];
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

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
