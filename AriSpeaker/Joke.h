//
//  Joke.h
//  AriSpeaker
//
//  Created by Ariel Elkin on 25/06/2014.
//  Copyright (c) 2014 Saffron Digital. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Joke : NSObject

@property (readonly) NSString *question;
@property (readonly) NSString *answer;

+ (instancetype)jokeWithQuestion:(NSString *)question answer:(NSString *)answer;

@end

