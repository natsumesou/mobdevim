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
extern NSString * const kSendFilePath;


/// The path to send up the files
extern NSString * const kSendAppBundle;

int send_files(AMDeviceRef d, NSDictionary *options);
