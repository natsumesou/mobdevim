//
//  main.m
//  YOYO
//
//  
//  Copyright © 2020 Selander. All rights reserved.
//

@import MachO;
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <dlfcn.h>
#import <sys/socket.h>

#import "ExternalDeclarations.h"
#import "helpers.h"
#import "debug_application.h"
#import "console.h"
#import "get_provisioning_profiles.h"
#import "list_applications.h"
#import "get_device_info.h"
#import "install_application.h"
#import "yoink.h"
#import "remove_file.h"
#import "send_files.h"
#import "get_logs.h"
#import "delete_application.h"
#import "instruments.h"
#import "sim_location.h"
#import "springboardservices.h"
#import "open_program.h"
#import "notifications.h"
#import "misc/InstrumentsPlugin.h"

static NSOperation *timeoutOperation = nil; // kill proc if nothing happens in 30 sec
static NSString *optionalArgument = nil;
static NSString *requiredArgument = nil;
static NSString *ideviceName = nil;
static int return_error = 0;
static void * __n = nil; // device_notification_struct
static int (*actionFunc)(AMDeviceRef, id) = nil; // the callback func for whatever action
static BOOL shouldDisableTimeout = YES;
static NSMutableDictionary *getopt_options;


static BOOL isCurrentlyRunning = NO;
static NSMutableSet *connectedDevices;

__unused static void connect_callback(AMDeviceCallBackDevice *device_callback, int cookie) {
    
    [timeoutOperation cancel];
    timeoutOperation = nil;
    
    // only monitor for connection callbacks
    if (device_callback->status != DeviceConnectionStatusConnect) {
        return;
    }
    
    NSDictionary *connectionDetails = ((__bridge NSDictionary *)(device_callback->connectionDeets));
    if ([connectionDetails isKindOfClass:[NSDictionary class]]) {
        NSString *connectionType = connectionDetails[@"Properties"][@"ConnectionType"];
        dsdebug("Found device %s (DeviceID %d) with ConnectionType: %s\n", [connectionDetails[@"SerialNumber"] UTF8String], [connectionDetails[@"DeviceID"] intValue], [connectionType UTF8String]);
    }
    
    AMDeviceRef d = device_callback->device;
    
    // Connect
    AMDeviceConnect(d);
    
    // Is Paired
    assert((AMDeviceIsPaired(device_callback) == ERR_SUCCESS));
    
    NSString *deviceUDID = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
    // Validate Pairing
    if (AMDeviceValidatePairing(d)) {
        dsprintf(stderr, "The device \"%s\" might not have been paired yet, Trust this computer on the device\n", [deviceUDID UTF8String]);
        exit(1);
    }
    
    // Start Session
    assert(!AMDeviceStartSession(d));
    [connectedDevices addObject:connectionDetails[@"DeviceID"]];
    
    NSString *deviceName = AMDeviceCopyValue(d, nil, @"DeviceName", 0);
    if (deviceName) {
        ideviceName = deviceName;
        dsprintf(stdout, "%sConnected to: \"%s\" (%s)%s\n", dcolor("cyan"), [deviceName UTF8String], [AMDeviceGetName(d) UTF8String], colorEnd());
    }
    
    if (actionFunc) {
        isCurrentlyRunning = YES;
        return_error = actionFunc(d, getopt_options);
    }
    
    if (actionFunc != &debug_application) {
        AMDeviceNotificationUnsubscribe(device_callback);
        CFRunLoopStop(CFRunLoopGetMain());
    }
}


//*****************************************************************************/
#pragma mark - MAIN

// If one USB, choose that, otherwise
static BOOL checkIfMultipleDevicesAndQueryIfNeeded(DeviceSelection *selection) {
    NSArray * devices = AMDCreateDeviceList();
    BOOL alreadyFoundUSB = NO;
    for (int i = 0; i < devices.count; i++) {
        AMDeviceRef _d = (__bridge AMDeviceRef)([devices objectAtIndex:i]);
        if (AMDeviceConnect(_d)) {
            continue;
        }
        
        NSString *deviceUDID = AMDeviceCopyValue(_d, nil, @"DeviceName", 0);
        InterfaceType type = AMDeviceGetInterfaceType(_d);
        if (type == InterfaceTypeUSB) {
            
        }
        if (selection) {
            selection->type = AMDeviceGetInterfaceType(_d);
        }
        
        char *typeStr  = InterfaceTypeString(AMDeviceGetInterfaceType(_d));
        printf("[%2d] %s (\"%s\") %s\n", i + 1, [AMDeviceGetName(_d) UTF8String], [deviceUDID UTF8String], typeStr);
        if (AMDeviceDisconnect(_d)) {
            continue;
        }
    }
    return YES;
//    }
}

//*****************************************************************************/

int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        int option = -1;
        char *addr;
        
        if (argc == 1) {
            print_manpage();
            exit(EXIT_SUCCESS);
        }
        
        getopt_options = [NSMutableDictionary new];
        connectedDevices = [NSMutableSet new];
        while ((option = getopt (argc, (char **)argv, ":Qn:o:WA:UV:D:d::Rr:fFqS::s:zd:u:hv::g::l::i:Cc::p::y::L:")) != -1) {
            switch (option) {
                case 'R': // Use color
                    setenv("DSCOLOR", "1", 1);
                    break;
                case 'Q': // Use color
                    global_options.quiet = YES;
                    break;
                case 'A': // Arguments, open_program
                    global_options.programArguments = [NSString stringWithUTF8String:optarg];
                    break;
                case 'o': // open application
                    assertArg();
                    actionFunc = &open_program;
                    global_options.programBundleID = [NSString stringWithUTF8String:optarg];
                    break;
                case 'W': // Prefer Use WIFI
                    global_options.deviceSelection.type = InterfaceTypeWIFI;
                    break;
                case 'U': // Prefer Use USB
                    global_options.deviceSelection.type = InterfaceTypeUSB;
                    break;
                case 'v': { // version if by itself, environment variables if other args
                    if (argc == 2) {
                        printf("%s v%s\n", program_name, version_string);
                        exit(EXIT_SUCCESS);
                    }
                    
                    assertArg();
                    NSMutableArray *arr = nil;
                    if (getopt_options[kProcessEnvVars]) {
                        arr = getopt_options[kProcessEnvVars];
                    } else {
                        arr = [NSMutableArray array];
                    }
                    
                    [arr addObject:[NSString stringWithUTF8String:optarg]];
                    [getopt_options setObject:arr forKey:kProcessEnvVars];
                    break;
                }
                case 'r':
                    assertArg();
                    actionFunc = &remove_file;
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kRemoveFileBundleID];
                    
                    if (argc > optind) {
                        [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kRemoveFileRemotePath];
                    }
                    break;
                case 'n': // push notifications
                    global_options.programBundleID = [NSString stringWithUTF8String:optarg];
                    actionFunc = notification_proxy;
                    if (argc > optind) {
                        global_options.pushNotificationPayloadPath = [NSString stringWithUTF8String:argv[optind]];
                    }
                    break;
                case 'V':
                    
                    break; // TODO old version
                case 'g':
                    assertArg();
                    actionFunc = &get_logs;
                    if (strcmp("__delete", optarg) == 0) {
                        [getopt_options setObject:@YES forKey:kGetLogsDelete];
                    } else {
                        [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kGetLogsAppBundle];
                    }
                    
                    if (argc > optind) {
                        [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kGetLogsFilePath];
                    }
                    break;
                case 'f':
                    actionFunc = &get_device_info;
                    break;
                case 'F':
//                    actionFunc = &instruments;
                    checkIfMultipleDevicesAndQueryIfNeeded(NULL);
                    exit(0);
                    break;
                case 'l':
                    //          assertArg();
                    actionFunc = &list_applications;
                    addr = strdup(optarg);
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kListApplicationsName];
                    if (argc > optind) {
                        [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kListApplicationsKey];
                    }
                    break;
                case 'u':
                    assertArg();
                    actionFunc = &delete_application;
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDeleteApplicationIdentifier];
                    break;
                case 's':
                    assertArg();
                    if(argc != 4) {
                        dsprintf(stderr, "Err: mobdevim -s BundleIdentifier /path/to/directories\n");
                        exit(1);
                    }
                    actionFunc = &send_files;
                    [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kSendFilePath];
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSendAppBundle];
                    break;
                case 'S':
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSBCommand];
                    actionFunc = &springboard_services;
                    break;
                case 'i':
                    assertArg();
                    shouldDisableTimeout = NO;
                    actionFunc = &install_application;
                    addr = strdup(optarg);
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kInstallApplicationPath];
                    requiredArgument = [NSString stringWithUTF8String:addr];
                    break;
                case 'L':
                    assertArg();
                    shouldDisableTimeout = NO;
                    actionFunc = &sim_location;
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kSimLocationLat];
                    [getopt_options setObject:[NSString stringWithUTF8String:argv[optind]] forKey:kSimLocationLon];
                    optind++;
                    break;
                case 'h':
                    print_manpage();
                    exit(EXIT_SUCCESS);
                    break;
                case 'D':
                    [getopt_options setObject:@YES forKey:kDebugQuickLaunch];
                    // drops through to debug
                case 'd':
                    assertArg();
                    shouldDisableTimeout = NO;
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDebugApplicationIdentifier];
                    actionFunc = debug_application;
                    break;
                case 'c':
                    assertArg();
                    shouldDisableTimeout = NO;
                    actionFunc = console;
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kConsoleProcessName];
                    break;
                case 'C':
                    actionFunc = &get_provisioning_profiles;
                    [getopt_options setObject:@YES forKey:kProvisioningProfilesCopyDeveloperCertificates];
                    break;
                case '?': // TODO fix this
                    goto MEH_IM_DONE;
                    break;
                case 'p':
                    assertArg();
                    actionFunc = &get_provisioning_profiles;
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kProvisioningProfilesFilteredByDevice];
                    break;
                case 'y':
                    assertArg();
                    actionFunc = &yoink_app;
                    [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kYoinkBundleIDContents];
                    break;
                case ':': // cases for optional non argument
                    switch (optopt)
                    {
                        case 'g':
                            actionFunc = &get_logs;
                            break;
                        case 'S':
                            actionFunc = &springboard_services;
                            break;
                        case 'n':
                            actionFunc = &notification_proxy;
                            break;
                        case 'p':
                            actionFunc = &get_provisioning_profiles;
                            break;
                        case 'c':
                            shouldDisableTimeout = NO;
                            actionFunc = console;
                            break;
                        case 'l':
                            actionFunc = &list_applications;
                            break;
                        case 'd':
                            shouldDisableTimeout = NO;
                            actionFunc = &debug_application;
                            break;
                        case 'y':
                            dsprintf(stderr, "%sList a BundleIdentifier to yoink it's contents%s\n\n", dcolor("yellow"), colorEnd());
                            actionFunc = &list_applications;
                            break;
                        case 'L':
                            assertArg();
                            shouldDisableTimeout = NO;
                            actionFunc = &sim_location;
                            break;
                        case 'v': {
                            if (argc == 2) {
                                printf("%s v%s\n", program_name, version_string);
                                exit(EXIT_SUCCESS);
                            }
                            
                            assertArg();
                            NSMutableArray *arr = nil;
                            if (getopt_options[kProcessEnvVars]) {
                                arr = getopt_options[kProcessEnvVars];
                            } else {
                                arr = [NSMutableArray array];
                            }
                            break;
                        }
                        case '?':
                            break;
                        default:
                            dsprintf(stderr, "option -%c is missing a required argument\n", optopt);
                            return EXIT_FAILURE;
                    }
                    break;
                default:
                    dsprintf(stderr, "%s\n", usage);
                    exit(EXIT_FAILURE);
                    break;
            }
        }
        
    MEH_IM_DONE:
        
        
        
        if (!isatty(fileno(stdout))) {
            unsetenv("DSCOLOR");
        }
        
        
//        checkIfMultipleDevicesAndQueryIfNeeded(&deviceSelection);
        
        
        
        AMDeviceNotificationSubscribeWithOptions(connect_callback, 0, global_options.deviceSelection.type,0,&__n, nil /* @{@"NotificationOptionSearchForPairedDevices" : @(UseUSBToConnect), @"NotificationOptionSearchForWiFiPairableDevices" : @(UseWifiToConnect) }*/ ) ;
        
        timeoutOperation = [NSBlockOperation blockOperationWithBlock:^{
            dsprintf(stderr, "Your device might not be connected. You've got about 25 seconds to connect your device before the timeout gets fired or you can start fresh with a ctrl-c. Choose wisely... dun dun\n");
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSOperationQueue mainQueue] addOperation:timeoutOperation];
        });
        
        if (shouldDisableTimeout) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CFRunLoopStop(CFRunLoopGetMain());
                dsprintf(stderr, "Script timed out, exiting now.\n");
                exit(EXIT_FAILURE);
                
            });
        }
        
        CFRunLoopRun();
        
    }
    return return_error;
}


/*
 /System/Library/PrivateFrameworks/CommerceKit.framework/Versions/A/CommerceKit
 po [[CKAccountStore sharedAccountStore] primaryAccount]
 <ISStoreAccount: 0x6080000d8f70>: dereks@somoioiu.com (127741183) isSignedIn=1 managedStudent=0
 */
