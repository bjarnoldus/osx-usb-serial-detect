//
//  Model.m
//  Serial Detect
//
//  Created by Jeroen Arnoldus on 07-02-15.
//  Copyright (c) 2015 Repleo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@implementation Personality

- (id)initWithPersonality:(NSNumber *)aIdVendor idProduct:(NSNumber *)aIdProduct {
    self = [super init];
    
    if (self) {
        _idProduct = aIdProduct;
        _idVendor = aIdVendor;
    }
    
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToPersonality:other];
}

- (BOOL)isEqualToPersonality:(Personality *)aPersonality {
    if (self == aPersonality)
        return YES;
    if ([self idVendor] != [aPersonality idVendor])
        return NO;
    if ((id)[self idProduct] != [aPersonality idProduct])
        return NO;

    return YES;
}

@end

