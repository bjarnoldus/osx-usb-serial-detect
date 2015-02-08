//
//  Model.h
//  Serial Detect
//
//  Created by Jeroen Arnoldus on 07-02-15.
//  Copyright (c) 2015 Repleo. All rights reserved.
//

#ifndef Serial_Detect_Model_h
#define Serial_Detect_Model_h

@interface Personality : NSObject
@property NSNumber *idVendor;
@property NSNumber *idProduct;

- (id)initWithPersonality:(NSNumber *)aIdVendor idProduct:(NSNumber *)idProduct;



@end


#endif
