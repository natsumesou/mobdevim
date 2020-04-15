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

int open_program(AMDeviceRef d, NSDictionary *options) {
   
    NSString *name = global_options.programBundleID;
    NSDictionary *dict = nil;
    mach_error_t err = AMDeviceLookupApplications(d, @{ @"ReturnAttributes": @YES, @"ShowLaunchProhibitedApps" : @YES }, &dict);
    if (err) {
        dsprintf(stderr, "Err looking up application, exiting...\n");
        exit(1);
    }
    
    if (!name) {
        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor("yellow"), [name UTF8String], colorEnd(), dcolor("bold"), colorEnd());
        return 1;
    }
    
    NSDictionary *appParams = [dict objectForKey:name];
    NSString *path = appParams[@"Path"];
    if (!path) {
        dsprintf(stderr, "couldn't get the path\n");
        return 1;
    }
    NSString *bundleID = appParams[@"CFBundleIdentifier"];
    if (!bundleID) {
        dsprintf(stderr, "couldn't get the bundleID\n");
        return 1;
    }
    
    preload();
    XRMobileDevice* device  = [[NSClassFromString(@"XRMobileDevice") alloc] initWithDevice:d];
    if (!device) {
        dsprintf(stderr, "couldn't maintain a device connection\n");
        return 1;
    }
    // ___lldb_unnamed_symbol79$$XRMobileDeviceDiscoveryPlugIn
    // AMDCopyArrayOfDevicesMatchingQuery

//    NSString *arguments = @"-NSAccentuateLocalizedStrings YES";
//    NSDictionary *environment = @{};
    NSString *arguments = global_options.programArguments;
    NSArray *environment = options[kProcessEnvVars];
    
    NSMutableDictionary *dictionaryEnvironment = [NSMutableDictionary new];
    for (NSString *val in environment) {
        NSArray *components = [val componentsSeparatedByString:@"="];;
        if ([components count] != 2) {
            dsprintf(stderr, "Couldn't process \"%s\"\n", val.UTF8String);
            continue;
        }
        NSString *key = components.firstObject;
        NSString *object = components.lastObject;
        [dictionaryEnvironment setObject:object forKey:key];
    }
    
    PFTProcess *process = [[PFTProcess alloc] initWithDevice:device path:path bundleIdentifier:bundleID arguments:arguments environment:dictionaryEnvironment launchOptions:nil];
    
    NSError *error = nil;
    int pid = [device launchProcess:process suspended:NO error:&error];
    if (error) {
        printf("%s\n", error.localizedDescription.UTF8String);
    }

    printf("pid: %d\n", pid);
    return 0;
}
