//
//  install_application.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExternalDeclarations.h"
#import "helpers.h"

/// The path to the IPA file
extern NSString *const kWifiConnectUUID;
/// Install an application over toe the device. Expects a path to an IPA in options
int wifi_connect(AMDeviceRef d, NSDictionary *options);

//void *AMDeviceMountImage(AMDeviceRef d, NSString* imagePath, NSDictionary *options, void (*callback)(NSDictionary *status, id deviceToken), id deviceToken, NSError **error);
//
//
//void *AMDeviceUnmountImage(AMDeviceRef d, NSString *imagePath);
