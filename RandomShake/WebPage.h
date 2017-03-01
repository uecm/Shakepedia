//
//  WebPage.h
//  RandomShake
//
//  Created by Egor on 3/2/17.
//  Copyright © 2017 egor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebPage : NSObject

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) WebPage *previous;
@property (nonatomic, retain) WebPage *next;


@end
