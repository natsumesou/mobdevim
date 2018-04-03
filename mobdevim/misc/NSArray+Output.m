//
//  NSArray+Output.m
//  mobdevim
//
//  Created by Derek Selander on 4/2/18.
//  Copyright © 2018 Selander. All rights reserved.
//

#import "NSArray+Output.h"
#import "helpers.h"
@import ObjectiveC.runtime;

@implementation NSObject (Output)

@dynamic dsIndentOffset;

- (void)setDsIndentOffset:(NSNumber*)object {
    objc_setAssociatedObject(self, @selector(dsIndentOffset), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber*)dsIndentOffset {
    return objc_getAssociatedObject(self, @selector(dsIndentOffset));
}

- (const char *)dsformattedOutput {
    return [[self description] UTF8String];
}
@end

@implementation NSArray (Output)

- (const char *)dsformattedOutput {
    NSMutableString *outputString = [NSMutableString string];
    
    NSNumber *currentOffset = [self dsIndentOffset];
    if (!currentOffset) {
        currentOffset = @1;
    }
    
    if ([self count] == 0 || [self count] == 1) {
        [outputString appendFormat:@"%s[ ]%s", dcolor("bold"), colorEnd()];
        return [outputString UTF8String];
    }
    [outputString appendFormat:@"\n%*s%s[%s\n",  ([currentOffset intValue]-1) * 4 , "", dcolor("bold"), colorEnd()];
    for (id itemObject in self) {
        [itemObject setDsIndentOffset:@([currentOffset intValue] + 1)];

        if ([itemObject respondsToSelector:@selector(dsformattedOutput)]) {
            [outputString appendFormat:@"%*s%s\n", [currentOffset intValue] * 4 , "",  [itemObject dsformattedOutput]];
        } else {
            [outputString appendFormat:@"%*s%@\n", [currentOffset intValue] * 4 , "", itemObject];
        }
    }
    [outputString appendFormat:@"%*s%s]%s\n", ([currentOffset intValue]-1) * 4 , "",  dcolor("bold"), colorEnd()];
    
    return [outputString UTF8String];
    
}

@end

@implementation NSDictionary (Output)

- (const char *)dsformattedOutput {
    NSMutableString *outputString = [NSMutableString string];
    
    NSNumber *currentOffset = [self dsIndentOffset];
    if (!currentOffset) {
        currentOffset = @1;
    }
    [outputString appendFormat:@"%s{%s\n",  dcolor("bold"), colorEnd()];
    for (id key in self) {
        id itemObject = [self objectForKey:key];
        [itemObject setDsIndentOffset:@([currentOffset integerValue] + 1)];
        if ([itemObject respondsToSelector:@selector(dsformattedOutput)]) {
            
            [outputString appendFormat:@"%*s%s%@%s: %s\n", [currentOffset intValue] * 4 , "", dcolor("cyan"), key, colorEnd(), [itemObject dsformattedOutput]];
        } else {
            [outputString appendFormat:@"%*s%s%@%s: %@\n", [currentOffset intValue] * 4 , "", dcolor("cyan"), key, colorEnd(), itemObject];
        }
    }
    [outputString appendFormat:@"%*s%s}%s\n", ([currentOffset intValue] -1)  * 4 , "",   dcolor("bold"), colorEnd()];
    
    return [outputString UTF8String];
}

@end


@implementation NSDate (Output)

- (const char *)dsformattedOutput {
    NSMutableString *outputString = [NSMutableString string];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, yyyy h:mm a"];
    [outputString appendFormat:@"%@ (%@)", self, [formatter stringFromDate:self] ];
    return [outputString UTF8String];
}

@end
