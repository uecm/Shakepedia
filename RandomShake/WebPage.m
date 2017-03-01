//
//  WebPage.m
//  RandomShake
//
//  Created by Egor on 3/2/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import "WebPage.h"

@implementation WebPage

@synthesize next;
@synthesize previous;
@synthesize url;

-(instancetype)init{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

@end
