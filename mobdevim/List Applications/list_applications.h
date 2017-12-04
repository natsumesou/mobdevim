//
//  list_applications.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// List detailed information about a specific application bundle
extern NSString *const kListApplicationsName;

/// List applications
int list_applications(AMDeviceRef d, NSDictionary *options);
