//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "install_application.h"


NSString * const kInstallApplicationPath = @"com.selander.installapplication.path";

int install_application(AMDeviceRef d, NSDictionary *options) {
  // Get path to generated file
  NSString *path = (NSString *)[options objectForKey:kInstallApplicationPath];
  NSURL *local_app_url = [NSURL fileURLWithPath:path isDirectory:TRUE];
  NSDictionary *params = @{@"PackageType" : @"Developer"};
  NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
  
  // Get a secure path
  assert(!AMDeviceSecureTransferPath(0, d, local_app_url, options, NULL, 0));
  
  int error = AMDeviceSecureInstallApplication(0, d, local_app_url, params, NULL, 0);
  if (error) {
    dsprintf(stderr, "Error: \"%s\" was unable to install on \"%s\"\n", [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String], [deviceName UTF8String]);
    return 1;
  } else {
    dsprintf(stdout, "Success: \"%s\" app successfully installed on \"%s\"\n", [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String], [deviceName UTF8String]);
  }
  
  return 0;
}
