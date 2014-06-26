//
//  Joke.m
//  AriSpeaker
//
//  Created by Ariel Elkin on 25/06/2014.
//  Copyright (c) 2014 Saffron Digital. All rights reserved.
//

#import "Joke.h"

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
