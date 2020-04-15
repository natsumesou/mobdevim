//
//  springboardservices.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "springboardservices.h"
#include <time.h>
#include <utime.h>
#include <sys/stat.h>


//NSString * const kSBSFileBundleID = @"com.selander.springboard_services.bundleid";

//NSString * const kSBCommand = @"com.selander.springboard_services.command";

//
//  open_program.m
//  mobdevim
//
//  Created by Derek Selander on 3/9/20.
//  Copyright © 2020 Selander. All rights reserved.
//

#import "open_program.h"
#import "../misc/InstrumentsPlugin.h"
#import "../Debug Application/debug_application.h"
#import <dlfcn.h>

static void preload() {
    XRUniqueIssueAccumulator *responder = [XRUniqueIssueAccumulator new];
    XRPackageConflictErrorAccumulator *accumulator = [[XRPackageConflictErrorAccumulator alloc] initWithNextResponder:responder];
    [DVTDeveloperPaths initializeApplicationDirectoryName:@"Instruments"];
    
    void (*PFTLoadPlugin)(id, id) = dlsym(RTLD_DEFAULT, "PFTLoadPlugins");
    PFTLoadPlugin(nil, accumulator);
}

static NSDictionary* handleNoFilepathGiven() {
    if (global_options.pushNotificationPayloadPath) {
        NSDictionary* payload = [NSDictionary dictionaryWithContentsOfFile:global_options.pushNotificationPayloadPath];
        if (!payload) {
            printf("Invalid payload from \"%s\"\n", global_options.pushNotificationPayloadPath.UTF8String);
            exit(1);
        }
        return payload;
    }
    NSString *path = @"/tmp/apns_payload.plist";
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary * tmpDictionary = @{@"aps" :
                                        @{@"alert" : @"This is a test alert",
                                          @"badge" : @1,
                                          @"sound" : @"bingbong.aiff" }};
                              
        [tmpDictionary writeToFile:path atomically:YES];
        printf("No payload dictionary given! Created one at \"%s\", see https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html\n", path.UTF8String);
    } else {
        printf("No payload dictionary given! See https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html\n");
    }
    exit(1);
}

int notification_proxy(AMDeviceRef d, NSDictionary *options) {
   
    return 0;
}
