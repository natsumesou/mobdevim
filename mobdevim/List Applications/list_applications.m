//
//  list_applications.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "list_applications.h"

NSString *const kListApplicationsName = @"com.selander.listapplications.appname";
NSString *const kListApplicationsKey = @"com.selander.listapplications.key";

int list_applications(AMDeviceRef d, NSDictionary *options) {
  
  NSDictionary *dict;
  AMDeviceLookupApplications(d, @{@"ReturnAttributes": @YES}, &dict);
  
  NSString *name = [options objectForKey:kListApplicationsName];
  if (name) {
    
    if (![dict objectForKey:name]) {
      dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor("yellow"), [name UTF8String], colorEnd(), dcolor("bold"), colorEnd());
      return 1;
    }
    
    NSString *key = [options objectForKey:kListApplicationsKey];
    
      if (key) {
          dsprintf(stdout, "%sDumping info for \"%s\"%s with key: \"%s\"\n\n%s\n", dcolor("red"), [name UTF8String], colorEnd(), [key UTF8String],  [[[[dict objectForKey:name] objectForKey:key] debugDescription] UTF8String]);
      }
      else {
          dsprintf(stdout, "%sDumping info for \"%s\"%s\n\n%s\n", dcolor("red"), [name UTF8String], colorEnd(),  [[[dict objectForKey:name] debugDescription] UTF8String]);
      }
  } else {
    NSMutableString *output = [NSMutableString string];
    for (NSString *key in [dict allKeys]) {
      [output appendString:[NSString stringWithFormat:@"%@\n", key]];
    }
    
    dsprintf(stdout, "%sDumping bundleIDs for all apps%s\n\n%s\n\n", dcolor("red"), colorEnd(), [output UTF8String]);
  }
  
  return 0;
}
