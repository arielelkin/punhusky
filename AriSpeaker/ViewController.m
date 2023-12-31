//
//  ViewController.m
//  AriSpeaker
//
//  Created by Ariel Elkin on 15/01/2014.
//  Copyright (c) 2014 MyCompanyName. All rights reserved.
//

#import "ViewController.h"
#import "Joke.h"
#import "JokeMenu.h"

@import AVFoundation;
@import Social;
@import MessageUI;

typedef NS_ENUM(NSUInteger, JokeEngineState){
    JokeEngineStateIdle,
    JokeEngineStateSetup,
    JokeEngineStatePunchline,
    JokeEngineStateLaughing
};

@interface ViewController ()<AVSpeechSynthesizerDelegate, MFMessageComposeViewControllerDelegate>
@end

NSString *const kDateJokesLastFetched = @"kDateJokesLastFetched";

@implementation ViewController {
    AVSpeechSynthesizer *synth;

    NSURLSessionDataTask *jokeFetcher;

    NSMutableArray *jokeArray;
    NSInteger currentJoke;

    UIImageView *jokeTellerImageView;
    UIView *whiteView;

    BOOL isRapidFire;

    UIDynamicAnimator *animator;

    UIView *labelView;
    UILabel *jokeLabel;
    UILabel *punchlineLabel;

    UIImageView *curtainImageView;
    NSMutableArray *curtainConstraints;

    JokeEngineState jokeEngineState;

    AVAudioPlayer *woohPlayer;

    NSString *currentCharacter;
    MFMessageComposeViewController *messageController;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //delegate will be set in
    synth = [AVSpeechSynthesizer new];

    [self buildUI];
    [self addCurtain];

    labelView.alpha = 1;
    jokeTellerImageView.alpha = 0.7;

    NSURL *woohURL = [[NSBundle mainBundle] URLForResource:@"wooh" withExtension:@"caf"];
    woohPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:woohURL error:nil];
    [woohPlayer prepareToPlay];

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
    if ([[NSUserDefaults standardUserDefaults] valueForKey:kShouldRapidFire] != nil) {
        isRapidFire = [[NSUserDefaults standardUserDefaults] boolForKey:kShouldRapidFire];
    } else {
        isRapidFire = true;
    }

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

    self.view.backgroundColor = [UIColor blackColor];

    whiteView = [[UIView alloc] init];
    whiteView.frame = self.view.frame;
    whiteView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:whiteView];

    jokeTellerImageView = [UIImageView new];
    jokeTellerImageView.frame = self.view.frame;
    [jokeTellerImageView setContentMode:UIViewContentModeScaleAspectFill];
    [jokeTellerImageView setImage:[UIImage imageNamed:@"HuskyAsks.jpg"]];
    [self.view addSubview:jokeTellerImageView];

    labelView = [UIView new];
    [labelView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:labelView];

    jokeLabel = [UILabel new];
    [jokeLabel setNumberOfLines:0];
    [jokeLabel setFont:[UIFont fontWithName:@"GillSans-Bold" size:30]];
    [jokeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [labelView addSubview:jokeLabel];

    punchlineLabel = [UILabel new];
    [punchlineLabel setNumberOfLines:0];
    [punchlineLabel setFont:[UIFont fontWithName:@"GillSans-Bold" size:30]];
    [punchlineLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [labelView addSubview:punchlineLabel];

    UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    menuButton.tintColor = [UIColor blackColor];
    [menuButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    menuButton.translatesAutoresizingMaskIntoConstraints = NO;
    [labelView addSubview:menuButton];

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

    NSArray *menuButtonConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[menuButton]-|" options:0 metrics:nil views:@{@"menuButton": menuButton}];
    [labelView addConstraints:menuButtonConstraintsH];

    NSArray *menuButtonConstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[menuButton]-|" options:0 metrics:nil views:@{@"menuButton": menuButton}];
    [labelView addConstraints:menuButtonConstraintsV];


    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.view addGestureRecognizer:tapGesture];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.view addGestureRecognizer:panGesture];
}

- (void)panGesture:(UIPanGestureRecognizer *)gestureRecognizer {

    CGFloat xTranslation = [gestureRecognizer translationInView:self.view].x;

    jokeTellerImageView.transform = CGAffineTransformRotate(jokeTellerImageView.transform, xTranslation/4000);
    whiteView.transform = jokeTellerImageView.transform;

    //kill the synth to avoid race conditions:
    [synth setDelegate:nil];
    [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    synth = [AVSpeechSynthesizer new];


    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {

        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.2
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             jokeTellerImageView.transform = CGAffineTransformMakeScale(1.8, 1.6);
                             whiteView.transform = jokeTellerImageView.transform;
                         }
                         completion:nil
         ];

        [punchlineLabel setText:@" "];

        [woohPlayer play];
    }

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {

        [UIView animateWithDuration:((double)(20 + arc4random()%40)/100.0)
                              delay:0
             usingSpringWithDamping:0.4
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             jokeTellerImageView.transform = CGAffineTransformIdentity;
                             whiteView.transform = jokeTellerImageView.transform;
                         }
                         completion:nil
         ];

        if (jokeArray.count == 0) return;

        CGPoint velocity = [gestureRecognizer velocityInView:self.view];

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

        [self changeCharacter];

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
#pragma mark Menu

- (void)toggleMenu {
    static JokeMenu *menu;

    if (menu.superview != nil) return;

    else {
        menu = [JokeMenu jokeMenu];
        [self.view addSubview:menu];

        menu.rapidFireModeChangedBlock = ^(BOOL newSetting) {
            [NSUserDefaults.standardUserDefaults setBool:newSetting forKey:kShouldRapidFire];
            isRapidFire = newSetting;
        };

        menu.shareOnSocialNetworkBlock = ^(NSString *serviceType){

            SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:serviceType];
            vc.completionHandler = ^(SLComposeViewControllerResult result){
                if (result == SLComposeViewControllerResultDone) {
                    if (serviceType == SLServiceTypeTwitter) {
                    }
                    else if (serviceType == SLServiceTypeFacebook){
                    }
                }
            };

            Joke *joke = jokeArray[currentJoke];
            NSString *postText = [NSString stringWithFormat:@"%@\n\n%@", joke.question, joke.answer];

            [vc setInitialText:postText];

            [self presentViewController:vc animated:YES completion:nil];
        };
        menu.shareViaSMSBLock = ^{
            messageController = [[MFMessageComposeViewController alloc] init];
            messageController.messageComposeDelegate = self;

            Joke *joke = jokeArray[currentJoke];
            NSString *postText = [NSString stringWithFormat:@"%@\n\n%@", joke.question, joke.answer];

            [messageController setBody:postText];

            [self.view addSubview:messageController.view];
        };
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;

        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"Crap." otherButtonTitles:nil];
            [warningAlert show];
            break;
        }

        case MessageComposeResultSent:
        {
            break;
        }

        default:
            break;
    }

    [messageController.view removeFromSuperview];
}

#pragma mark -
#pragma mark UI Updates

- (void)toggleLabels {
    if (labelView.alpha == 0) {
        labelView.alpha = 1;
        jokeTellerImageView.alpha = 0.7;
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

                    BOOL goodToRead = (([answer rangeOfString:@"http://" options:NSCaseInsensitiveSearch].length == 0) &&
                                       ((answer.length + question.length) < 170));

                    if (goodToRead) {
                        [jokeArray addObject:[Joke jokeWithQuestion:question answer:answer]];
                    }
                }

                [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kDateJokesLastFetched];
                [[NSUserDefaults standardUserDefaults] synchronize];

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                    jokeEngineState = JokeEngineStateSetup;
                    currentCharacter = @"husky";
                    [self saySetup];

                }];
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
                    currentCharacter = @"husky";
                    [self sayShouldConnectToInternet];
                }];
            }
        }
    }];

    [jokeFetcher resume];

}

- (void)sayShouldConnectToInternet {

    NSString *line = @"Hi. Sorry, but I need internet. Please connect and open the app again!";

    [jokeTellerImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_laughs.jpg", currentCharacter]]];
    [jokeLabel setText:line];

    jokeEngineState = JokeEngineStatePunchline;

    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:line];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-AU"]];
    utterance.pitchMultiplier = 0.2;
    utterance.rate = 0.3;

    [synth speakUtterance:utterance];

}

- (void)saySetup {

    Joke *joke = jokeArray[currentJoke];

    NSString *line;

    line = [joke question];
    [jokeTellerImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_asks.jpg", currentCharacter]]];
    [jokeLabel setText:line];


    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:line];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-AU"]];

    float preUtteranceDelay = (arc4random()%10) / 100.0; //0.0 - 0.1
    [utterance setPreUtteranceDelay:preUtteranceDelay];

    float setupPitch = (30 + (arc4random()%10)) / 100.0; //0.3 - 0.4
    utterance.pitchMultiplier = setupPitch;
    utterance.rate = 0.4;

    if ([currentCharacter isEqual:@"mona"]) {
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"it-IT"];
        utterance.pitchMultiplier = 1.2;
        utterance.rate = 0.3;
    }
    else if([currentCharacter isEqual:@"teddy"]) {
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
        utterance.pitchMultiplier = 0.05;
        utterance.rate = 0.4;
    }




    [synth speakUtterance:utterance];

    //should be declared here to avoid race conditions
    [synth setDelegate:self];
}

- (void)sayPunchline {

    Joke *joke = jokeArray[currentJoke];

    NSString *line;

    line = [joke answer];
    [jokeTellerImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_tells.jpg", currentCharacter]]];
    [punchlineLabel setText:line];


    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:line];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-AU"]];

    //Punchline pitch:
    float punchlinePitch = (30 + (arc4random()%10)) / 100.0; //0.3 - 0.4
    utterance.pitchMultiplier = punchlinePitch;

    utterance.rate = 0.4;

    if ([currentCharacter isEqual:@"mona"]) {
        utterance.pitchMultiplier = 1.1;
        utterance.rate = 0.3;
        utterance.preUtteranceDelay = 0.3;
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"it-IT"];
    }
    else if([currentCharacter isEqual:@"teddy"]) {
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
        utterance.pitchMultiplier = 0.5;
    }

    [synth speakUtterance:utterance];
}

- (void)laugh {

    NSString *laughterString;

    int laughterType = arc4random()%2;

    if (laughterType == 0) {
        laughterString = @"hahahahahahahahaha";
    }

    else if (laughterType == 1 || [currentCharacter isEqual:@"teddy"]) {
        laughterString = @"Huehuehuehuehuehuehuehuehue";
    }

    if ([currentCharacter isEqual:@"mona"]){
        laughterString = @"waaaahaa... há... há... há... há... há... há... há... há... há... há... há...";
    }


    //funny laughs:
    //zh-HK
    //pitch = 0.5;
    //rate = 0.25;


    //ru-RU
    //zh-CN
    //en-IE

    //zh-TW

    //IF

    //BAN:
    //ro-RO
    //ja-JP


    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:laughterString];

    AVSpeechSynthesisVoice *randomVoice = [AVSpeechSynthesisVoice speechVoices][arc4random()%[AVSpeechSynthesisVoice speechVoices].count];
    [utterance setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:randomVoice.language]];

    float laughterRate = (20 + (arc4random()%20)) / 100.0; //0.20 - 0.40
    utterance.rate = laughterRate;

    float laughterPitch = (20 + (arc4random()%180)) / 100.0; //0.20 - 0.40
    utterance.pitchMultiplier = laughterPitch;

    if ([currentCharacter isEqual:@"husky"]) {
        utterance.pitchMultiplier = 0.1;
        utterance.rate = 0.3;
    }


    else if ([currentCharacter isEqual:@"mona"]) {
        utterance.pitchMultiplier = 0.9;
        utterance.rate = 0.4;
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"it-IT"];
    }

    else if([currentCharacter isEqual:@"teddy"]) {
        utterance.pitchMultiplier = 0.1;
        utterance.rate = 0.3;
        utterance.volume = 0.7;
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"de-DE"];
    }

    [synth speakUtterance:utterance];

    [jokeTellerImageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_laughs.jpg", currentCharacter]]];


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
    }

    else if (jokeEngineState == JokeEngineStateLaughing) {
        if (isRapidFire) {

            currentJoke++;

            [self changeCharacter];

            jokeEngineState = JokeEngineStateSetup;
            [self saySetup];
        }
    }
}

-(void)changeCharacter {

    int i = arc4random()%20;

    if (i < 10) {
        currentCharacter = @"husky";
    }
    else if (i > 9 && i <= 15) {
        currentCharacter = @"teddy";
    }
    else {
        currentCharacter = @"mona";
    }

    //mona can't pronounce "you" properly
    Joke *nextJoke = jokeArray[currentJoke];
    if ([currentCharacter isEqual:@"mona"]) {
        if ([nextJoke.question rangeOfString:@"you"].length > 0 ||
            [nextJoke.answer rangeOfString:@"you"].length > 0) {
            [self changeCharacter];
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
        currentCharacter = @"husky";
        [self saySetup];

    }
    else NSLog(@"JSON parsing Error: %@", jsonParsingError);
}

@end
