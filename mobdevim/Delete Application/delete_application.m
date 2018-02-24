//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "install_application.h"


NSString * const kDeleteApplicationPath = @"com.selander.delete.path";

int delete_application(AMDeviceRef d, NSDictionary *options) {
    
    NSDictionary *dict;
    NSString *name = [options objectForKey:kDeleteApplicationPath];
    
    if (!name) {
        dsprintf(stderr, "You must provide a bundleIdentifier to delete\n");
        return 1;
    }
    
    AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
    if (![dict objectForKey:name]) {
        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor("yellow"), [name UTF8String], colorEnd(), dcolor("bold"), colorEnd());
        return 1;
    }

    if (!quiet_mode) {
        dsprintf(stdout, "Are you sure you want to delete \"%s\"? [Y]", name);
        if (getchar() != 89) {
            return 0;
        }
    }
//    AMDeviceSecureUninstallApplicatio
//    AMDeviceSecureRemoveApplicationArchive(<#AMDServiceConnectionRef#>, <#AMDeviceRef#>, <#NSString *#>, <#void *#>, <#void *#>, <#void *#>)
    
//  // Get path to generated file
//  NSString *path = (NSString *)[options objectForKey:kInstallApplicationPath];
//  NSURL *local_app_url = [NSURL fileURLWithPath:path isDirectory:TRUE];
//  NSDictionary *params = @{@"PackageType" : @"Developer"};
//  NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
//
//  // Get a secure path
//  assert(!AMDeviceSecureTransferPath(0, d, local_app_url, options, NULL, 0));
//
//  int error = AMDeviceSecureInstallApplication(0, d, local_app_url, params, NULL, 0);
//  if (error) {
//    dsprintf(stderr, "Error: \"%s\" was unable to install on \"%s\"\n", [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String], [deviceName UTF8String]);
//    return 1;
//  } else {
//    dsprintf(stdout, "Success: \"%s\" app successfully installed on \"%s\"\n", [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String], [deviceName UTF8String]);
//  }
//
  return 0;
}
