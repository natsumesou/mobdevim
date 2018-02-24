//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "install_application.h"
#import "progressbar.h"


NSString * const kInstallApplicationPath = @"com.selander.installapplication.path";


static progressbar *progress = nil;
void installCallback(CFDictionaryRef d) {

//    if (arg == 0) {
//        return;
//    }
    if (progress) {
        NSDictionary *dict = (__bridge NSDictionary *)(d);
        NSNumber *complete = dict[@"PercentComplete"];
        if (complete) {
            unsigned long value = [complete unsignedIntegerValue];
            progressbar_update(progress, value);
        }
    }
}

int install_application(AMDeviceRef d, NSDictionary *options) {
    // Get path to generated file
    NSString *path = [(NSString *)[options objectForKey:kInstallApplicationPath] stringByExpandingTildeInPath];
    NSURL *local_app_url = [NSURL fileURLWithPath:path isDirectory:TRUE];
    NSDictionary *params = @{@"PackageType" : @"Customer"};
    NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
    
    // Get a secure path
    assert(!AMDeviceSecureTransferPath(0, d, local_app_url, params, NULL, 0));
    int error = 0;
    
    if (quiet_mode) {
        error = AMDeviceSecureInstallApplication(0, d, local_app_url, params, NULL, 0);
    } else {
        progress = progressbar_new("Installing... ", 100);
        error = AMDeviceSecureInstallApplication(0, d, local_app_url, params, installCallback, 0);
        progressbar_update(progress, 100);
        if (error) {
            progressbar_update_label(progress, "Error:");
            progressbar_update(progress, 0);
            progressbar_finish(progress);
            dsprintf(stderr, "Error: \"%s\" was unable to install on \"%s\"\n", [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String], [deviceName UTF8String]);
            return 1;
        } else {
            progressbar_update_label(progress, "Installed!");
            progressbar_finish(progress);
            dsprintf(stdout, "Success: \"%s\" app successfully installed on \"%s\"\n", [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String], [deviceName UTF8String]);
        }
    }
    
    return 0;
}
