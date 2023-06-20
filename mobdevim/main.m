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
#import "install_ddi.h"
#import "process.h"
#import "wifie_connect.h"
#import "process/process.h"

static NSOperation *timeoutOperation = nil; // kill proc if nothing happens in 30 sec
static NSString *optionalArgument = nil;
static NSString *requiredArgument = nil;
static NSString *ideviceName = nil;
static int return_error = 0;
struct am_device_service_connection *GDeviceConnection = NULL;
struct am_device_notification *notify_handle = NULL;

static int (*actionFunc)(AMDeviceRef, id) = nil; // the callback func for whatever action
static BOOL disableTimeout = YES;
static NSMutableDictionary *getopt_options;


static amd_err connect_and_handle_device(AMDeviceRef device);

__unused static void subscription_connect_callback(AMDeviceCallBackDevice *callback, void* context) {
    AMDeviceRef d = callback->device;
    
    // Cancel the warning timer that it can't find a device
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [timeoutOperation cancel];
        timeoutOperation = nil;
    });
    
    // AMDeviceNotificationUnsubscribe sends another notification with
    // DeviceConnectionStatusStopped, we'll ignore this and return;
    if (callback->status == DeviceConnectionStatusStopped) {
        return;
    }
    
    if (callback->status != DeviceConnectionStatusConnect) {
        dprint("(status: %d for %s)\n", callback->status, AMDeviceGetName(callback->device));
        return;
    }
    
    if (connect_and_handle_device(d) != AMD_SUCCESS) {
        derror("Error connecting to device\n");
        goto end;
    }
    
    if (actionFunc != &debug_application) {
        CFRunLoopStop(CFRunLoopGetMain());
        return;
    }
    
end:
    AMDeviceNotificationUnsubscribe(callback->notification);
    AMDeviceStopSession(callback->device);
    
}

static amd_err connect_and_handle_device(AMDeviceRef device) {
    
    // Connect
    mach_error_t status = 0;
    HANDLE_ERR_RET(AMDeviceConnect(device));
    
    // Is Paired
    if (!AMDeviceIsPaired(device)) {
        NSDictionary *outDict = nil;
        HANDLE_ERR_RET(AMDevicePairWithCallback(device, ^(AMDeviceRef device, uint64_t options, uint64_t dunno, AMDevicePairAnotherCallback anothercallback) {
            
            printf("test\n");
            
        }, nil, &outDict));
//        int er = AMDevicePair(device);
//        if (er != 0) {
//            derror("Error: %s\n", AMDErrorString(er));
//        }
    }
    
    NSString *deviceUDID = AMDeviceCopyValue(device, nil, @"DeviceName", 0);
    // Validate Pairing
    if (AMDeviceValidatePairing(device)) {
        dsprintf(stderr, "The device \"%s\" might not have been paired yet, Trust this computer on the device\n", [deviceUDID UTF8String]);
        exit(1);
    }
    
    // Start Session
    if ((status = AMDeviceStartSession(device))) {
        if (status != AMDSessionActiveError ) { // we're already active, ignore
            dsprintf(stderr, "Error: %s %d\n", AMDErrorString(status), status);
            exit(1);
        }
    }
        
    NSString *deviceName = AMDeviceCopyValue(device, nil, @"DeviceName", 0);
    
    if (deviceName) {
        ideviceName = deviceName;
        char *interface_type = NULL;
        String4Interface( AMDeviceGetInterfaceType(device), &interface_type);
        dprint("%sConnected to: \"%s\" (%s)%s %s%s%s\n", dcolor("cyan"), [deviceName UTF8String], [AMDeviceGetName(device) UTF8String], colorEnd(), dcolor("yellow"), interface_type, colorEnd() );
    }
    
    if (actionFunc) {
        return_error = actionFunc(device, getopt_options);
    }
    
    return AMD_SUCCESS;
}


//*****************************************************************************/
#pragma mark - MAIN

// If one USB, choose that, otherwise
static BOOL checkIfMultipleDevicesAndQueryIfNeeded(DeviceSelection *selection) {
    NSArray * devices = AMDCreateDeviceList();
    for (int i = 0; i < devices.count; i++) {
        AMDeviceRef device = (__bridge AMDeviceRef)([devices objectAtIndex:i]);
        AMDeviceConnect(device);
        NSString *deviceUDID = AMDeviceGetName(device);
        InterfaceType type = AMDeviceGetInterfaceType(device);
//        if (type == InterfaceTypeUSB) {
//
//        }
        
        
//        if (selection) {
//            selection->type = AMDeviceGetInterfaceType(device);
//        }
        // If we have a selection, match UUID first, followed by interface type
        if (selection) {
            
            if ([deviceUDID containsString:global_options.expectedPartialUDID]) {
                // udid && type
                if (selection->type == type) {
                    selection->device = device;
                    return YES;
                } else {    // udid only
                    selection->device = device;
                    return YES;
                }
                
            } else {
                // type only
                if (selection->type == type) {
                    selection->device = device;
                    return YES;
                }
            }
            continue;
        }
        // Don't print out the devices if a UDID was specified

        char *typeStr  = InterfaceTypeString(AMDeviceGetInterfaceType(device));
        printf("[%2d] %s (\"%s\") %s\n", i + 1, [AMDeviceGetName(device) UTF8String], [deviceUDID UTF8String], typeStr);
        AMDeviceDisconnect(device);
        
    }
    return YES;
    

    //    }
}


__attribute__((destructor))
void exit_handler(void) {
    AMDeviceRef device = global_options.deviceSelection.device;
    if (AMDeviceIsPaired(device)) {
        AMDeviceDisconnect(device);
        AMDeviceStopSession(device);
    }
    
    if (GDeviceConnection) {
        AMDeviceNotificationUnsubscribe(GDeviceConnection);
        GDeviceConnection = NULL;
    }
    
}

__attribute__((constructor))
static void init(void) {
    atexit(exit_handler);
}

//*****************************************************************************/

int main(int argc, const char * argv[]) {
    
    int option = -1;
    char *addr;
    
    if (argc == 1) {
        print_manpage();
        exit(EXIT_SUCCESS);
    }
    
    getopt_options = [NSMutableDictionary new];
    while ((option = getopt (argc, (char **)argv, ":QNn:o:w::WA:k:UV:D:d::Rr:fF:qS::s:zd:u:hv::g::l::I:i:Cc::pP::y::L:")) != -1) {
        switch (option) {
            case 'R': // Use color
                setenv("DSCOLOR", "1", 1);
                break;
            case 'Q': // quiet
                global_options.quiet = YES;
                break;
            case 'A': // Arguments, open_program
                global_options.programArguments = [NSString stringWithUTF8String:optarg];
                break;
            case 'o': // open application
                assert_opt_arg();
                actionFunc = &open_program;
                global_options.programBundleID = [NSString stringWithUTF8String:optarg];
                break;
            case 'W': // Prefer Use WIFI
                global_options.deviceSelection.type = InterfaceTypeWIFI;
                break;
                
            case 'w': {
                assert_opt_arg();
                actionFunc = &wifi_connect;
                disableTimeout = NO;
                NSString *str = [NSString stringWithUTF8String:optarg];
                if ([str containsString:@"?"]) {
                    dsprintf(stdout, "%s\n", GetHostUUID().UTF8String);
                    exit(0);
                }
                
                [getopt_options setObject:str forKey:kWifiConnectUUID];
                break;
            }
            case 'U': // Prefer Use USB
                global_options.deviceSelection.type = InterfaceTypeUSB;
                break;
            case 'k': {
                NSString *str = [NSString stringWithUTF8String:optarg];
                actionFunc = kill_process;
                
                [getopt_options setObject:str forKey:kProcessKillPID];
                break;
            }
            case 'V':
                
                // fallthrough
            case 'v': { // version if by itself, environment variables if other args
                if (argc == 2) {
                    printf("%s v%s\n", program_name, version_string);
                    exit(EXIT_SUCCESS);
                }
                
                assert_opt_arg();
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
                assert_opt_arg();
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
            case 'p':
                actionFunc = &running_processes;
                break;

            case 'g':
                assert_opt_arg();
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
                disableTimeout = NO;
                global_options.choose_specific_device = YES;
                global_options.expectedPartialUDID = [NSString stringWithUTF8String:optarg];
                if ([global_options.expectedPartialUDID containsString:@"?"]) {
                    checkIfMultipleDevicesAndQueryIfNeeded(NULL);
                    exit(0);
                } else {
                    checkIfMultipleDevicesAndQueryIfNeeded(&global_options.deviceSelection);
                }
                
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
                assert_opt_arg();
                actionFunc = &delete_application;
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDeleteApplicationIdentifier];
                break;
            case 's':
                assert_opt_arg();
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
                assert_opt_arg();
                disableTimeout = NO;
                actionFunc = &install_application;
                addr = strdup(optarg);
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kInstallApplicationPath];
                requiredArgument = [NSString stringWithUTF8String:addr];
                break;
            case 'I': {
                assert_opt_arg();
                global_options.ddiInstallPath = [NSString stringWithUTF8String:optarg];
                
                global_options.ddiSignatureInstallPath = [NSString stringWithUTF8String:argv[optind - 1]];
                actionFunc = &install_ddi;
                
                break;
            }
            case 'L':
                assert_opt_arg();
                disableTimeout = NO;
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
                assert_opt_arg();
                disableTimeout = NO;
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kDebugApplicationIdentifier];
                actionFunc = debug_application;
                break;
            case 'c':
                assert_opt_arg();
                disableTimeout = NO;
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
            case 'P':
                assert_opt_arg();
                actionFunc = &get_provisioning_profiles;
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kProvisioningProfilesFilteredByDevice];
                break;
            case 'y':
                assert_opt_arg();
                actionFunc = &yoink_app;
                [getopt_options setObject:[NSString stringWithUTF8String:optarg] forKey:kYoinkBundleIDContents];
                break;
            case ':': // cases for optional non argument
                switch (optopt) {
                    case 'g':
                        actionFunc = &get_logs;
                        break;
                    case 'S':
                        actionFunc = &springboard_services;
                        break;
                    case 'n':
                        actionFunc = &notification_proxy;
                        break;
                    case 'P':
                        actionFunc = &get_provisioning_profiles;
                        break;
                    case 'c':
                        disableTimeout = NO;
                        actionFunc = console;
                        break;
                    case 'l':
                        actionFunc = &list_applications;
                        break;
                    case 'd':
                        disableTimeout = NO;
                        actionFunc = &debug_application;
                        break;
                    case 'w':
                        disableTimeout = NO;
                        actionFunc = &wifi_connect;
                        break;
                    case 'y':
                        dsprintf(stderr, "%sList a BundleIdentifier to yoink it's contents%s\n\n", dcolor("yellow"), colorEnd());
                        actionFunc = &list_applications;
                        break;
                    case 'L':
                        assert_opt_arg();
                        disableTimeout = NO;
                        actionFunc = &sim_location;
                        break;
                    case 'F':
                        disableTimeout = NO;
                        checkIfMultipleDevicesAndQueryIfNeeded(NULL);
                        break;
                    case 'v': {
                        if (argc == 2) {
                            printf("%s v%s\n", program_name, version_string);
                            exit(EXIT_SUCCESS);
                        }
                        
                        assert_opt_arg();
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
        
        
    MEH_IM_DONE:
        
        
        
//        if (!isatty(fileno(stdout))) {
//            unsetenv("DSCOLOR");
//        }
        
        ;
        //        checkIfMultipleDevicesAndQueryIfNeeded(&deviceSelection);
        
//        @{@"MatchUDID" :@"}
        
        
        
        
    }
//    return return_error;
    
    // If we have a specific device, look for it, else monitor with NotificationSubscribe
    if (global_options.choose_specific_device) {
        if (global_options.deviceSelection.device) {
            connect_and_handle_device(global_options.deviceSelection.device);
        } else {
            char *type_str = NULL;
            String4Interface(global_options.deviceSelection.type, &type_str);
            dsprintf(stderr, "Couldn't find device query: (%s)-%s\n", global_options.expectedPartialUDID.UTF8String, type_str);
            exit(1);
        }
    } else {
        
        
        AMDeviceNotificationSubscribeWithOptions(subscription_connect_callback, 0, global_options.deviceSelection.type, NULL /* arg passed into callback */, &GDeviceConnection, nil);
        
        /* @{@"NotificationOptionSearchForPairedDevices" : @(UseUSBToConnect), @"NotificationOptionSearchForWiFiPairableDevices" : @(UseWifiToConnect) }*/
        
        timeoutOperation = [NSBlockOperation blockOperationWithBlock:^{
            dsprintf(stderr, "Your device might not be connected. You've got about 25 seconds to connect your device before the timeout gets fired or you can start fresh with a ctrl-c. Choose wisely... dun dun\n");
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSOperationQueue mainQueue] addOperation:timeoutOperation];
        });
        
        if (disableTimeout) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                if (GDeviceConnection) {
                    AMDeviceNotificationUnsubscribe(GDeviceConnection);
                    GDeviceConnection = NULL;
//                    AMDeviceDisconnect(GDeviceConnection);
                }
                derror("Script timed out, exiting now.\n");
                exit(EXIT_FAILURE);
                
            });
        }
        // we expect to get an exit call before this event happens
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 20, false);
        CFRunLoopRun();
        
    }
}


/*
 /System/Library/PrivateFrameworks/CommerceKit.framework/Versions/A/CommerceKit
 po [[CKAccountStore sharedAccountStore] primaryAccount]
 <ISStoreAccount: 0x6080000d8f70>: dereks@somoioiu.com (127741183) isSignedIn=1 managedStudent=0
 */
