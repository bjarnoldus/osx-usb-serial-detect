//
//  Model.h
//  Serial Detect
//
//  Created by Jeroen Arnoldus on 07-02-15.
//  Copyright (c) 2015 Repleo. All rights reserved.
//

#ifndef Serial_Detect_Model_h
#define Serial_Detect_Model_h

@interface Personality : NSObject {
 NSNumber *idVendor;
 NSNumber *idProduct;
}


- (id)initWithPersonality:(NSNumber *)aIdVendor idProduct:(NSNumber *)idProduct;
- (NSNumber *) idVendor;
- (NSNumber *) idProduct;
- (BOOL)isEqualToPersonality:(Personality *)aPersonality;
- (BOOL)isEqual:(id)other;

@end


#endif
