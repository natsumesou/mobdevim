//
//  NSArray+Output.h
//  mobdevim
//
//  Created by Derek Selander on 4/2/18.
//  Copyright © 2018 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Output)
- (const char *)dsformattedOutput;
@end

@interface NSDictionary (Output)
- (const char *)dsformattedOutput;
@end

@interface NSObject (Output)
@property (nonatomic, strong) NSNumber* dsIndentOffset;
@end


