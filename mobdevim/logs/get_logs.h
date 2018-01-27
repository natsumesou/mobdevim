//
//  send_files.h
//  mobdevim
//
//  Created by Derek Selander on 12/4/17.
//  Copyright © 2017 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"


/// The path to send up the files
extern NSString * const kGetLogsFilePath;


/// The path to send up the files
extern NSString * const kGetLogsAppBundle;

/// gets the device logs -g list all, -g bundleIdentifier all crashes for app,
/// -g bundleIdentifier path all crashes written to path
int get_logs(AMDeviceRef d, NSDictionary *options);
