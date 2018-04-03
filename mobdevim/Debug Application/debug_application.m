//
//  DebugServer.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "debug_application.h"
#import "helpers.h"
#import <dlfcn.h>
@import Cocoa;
@import Darwin;
@import AppKit;

#define LLDB_SCRIPT_PATH @"/tmp/mobdevim_setupscript"

NSString * const kDebugApplicationIdentifier = @"com.selander.debug.bundleidentifier";

void generateSetupScript(const char * executablePath, int port) {
    NSString *setupScript =
@"platform select remote-ios\n\
target create /Users/derekselander/Library/Developer/Xcode/DerivedData/HackPOC-cuhifwlfgzrqercndqlcpfrreyyc/Build/Products/Debug-iphoneos/HackPOC.app\n\
script lldb.target.module[0].SetPlatformFileSpec(lldb.SBFileSpec(\"%s\"))\n\
process connect connect://localhost:%d\n\
";
    NSError *error = nil;
    
    NSString *script = [NSString stringWithFormat:setupScript, executablePath, port];
    
    [script writeToFile:LLDB_SCRIPT_PATH atomically:YES encoding:NSUTF8StringEncoding error:&error];
    dsprintf(stderr, "%s\n", [script UTF8String]);
    if (error) {
        dsprintf(stderr, "Couldn't write script to file: %s", [[error localizedDescription] UTF8String]);
        exit(1);
    }
    
    dsprintf(stdout, "Execute the following in a new Terminal window\nlldb -s %s\n", [LLDB_SCRIPT_PATH UTF8String]);
}


static NSString *appPath;
/********************************************************************************
 Source start https://github.com/phonegap/ios-deploy GPL v3 license
********************************************************************************/
static int lldbfd = 0;
static CFSocketRef server_socket;
static CFSocketRef lldb_socket;
static CFSocketRef fdvendor;
static int port = 0;

void lldb_callback(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dsprintf(stdout, "Connected!\n");
    });
    if (CFDataGetLength (data) == 0) {
        // close the socket on which we've got end-of-file, the lldb_socket.
        CFSocketInvalidate(s);
        CFRelease(s);
        dsprintf(stdout, "Connection terminated\n");
        CFRunLoopStop(CFRunLoopGetMain());
        return;
    }
    write(lldbfd, CFDataGetBytePtr (data), CFDataGetLength (data));
}

int kill_ptree(pid_t root, int signum);
void
server_callback (CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    ssize_t res;
//    NSLog(@"server_callback");
    if (CFDataGetLength (data) == 0) {
        // close the socket on which we've got end-of-file, the server_socket.
        CFSocketInvalidate(s);
        CFRelease(s);

        return;
    }
    res = write (CFSocketGetNative (lldb_socket), CFDataGetBytePtr (data), CFDataGetLength (data));
}

void fdvendor_callback(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
    CFSocketNativeHandle socket = (CFSocketNativeHandle)(*((CFSocketNativeHandle *)data));

    dsprintf(stdout, "Connecting to debugserver...\n");
    assert (callbackType == kCFSocketAcceptCallBack);

    lldb_socket  = CFSocketCreateWithNative(NULL, socket, kCFSocketDataCallBack, &lldb_callback, NULL);
    int flag = 1;
    int res = setsockopt(socket, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(flag));
    assert(res == 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), CFSocketCreateRunLoopSource(NULL, lldb_socket, 0), kCFRunLoopCommonModes);
    
    CFSocketInvalidate(s);
    CFRelease(s);
}


/********************************************************************************
 Source end https://github.com/phonegap/ios-deploy GPL v3 license
********************************************************************************/

int debug_application(AMDeviceRef d, NSDictionary* options) {

    NSDictionary *dict = nil;
    AMDeviceLookupApplications(d, @{@"ReturnAttributes": @[@"ProfileValidated", @"CFBundleIdentifier", @"Path"], @"ShowLaunchProhibitedApps" : @YES}, &dict);
    NSString *applicationIdentifier =  options[kDebugApplicationIdentifier];
    if (!applicationIdentifier) {
        dsprintf(stderr, "Invalid application identifier\n");
        exit(1);
    }
    NSDictionary *appDict = dict[applicationIdentifier];
    if (!appDict) {
        dsprintf(stderr, "Invalid application identifier \"%s\", use mobdevim -l to see application identifiers\n", [applicationIdentifier UTF8String]);
        exit(1);
    }
    appPath = appDict[@"Path"];
    if (!appPath) {
        dsprintf(stderr, "Couldn't find app path for \"%s\"\n", [applicationIdentifier UTF8String]);
        exit(1);
    }
    
    // At this point, we have a valid path for the app, let's continue
    AMDServiceConnectionRef connection = NULL;
    NSDictionary *params = @{@"CloseOnInvalidate" : @YES, @"InvalidateOnDetach" : @YES};
    AMDeviceSecureStartService(d, @"com.apple.debugserver", params, &connection);
    if (!connection) {
        dsprintf(stderr, "Unable to create a debugserver connection\n");
        exit(1);
    }
    lldbfd = (int)AMDServiceConnectionGetSocket(connection);
    if (lldbfd == -1) {
        dsprintf(stderr, "Invalid socket\n");
        exit(1);
    }
    
/********************************************************************************
 Source end https://github.com/phonegap/ios-deploy GPL v3 license
 ********************************************************************************/
    
    server_socket = CFSocketCreateWithNative (NULL, lldbfd, kCFSocketDataCallBack, &server_callback, NULL);
    CFRunLoopAddSource(CFRunLoopGetMain(), CFSocketCreateRunLoopSource(NULL, server_socket, 0), kCFRunLoopCommonModes);
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    
    fdvendor = CFSocketCreate(NULL, PF_INET, 0, 0, kCFSocketAcceptCallBack, &fdvendor_callback, NULL);
    
    if (port) {
        int yes = 1;
        setsockopt(CFSocketGetNative(fdvendor), SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    }
    
    CFDataRef address_data = CFDataCreate(NULL, (const UInt8 *)&addr, sizeof(addr));
    
    CFSocketSetAddress(fdvendor, address_data);
    CFRelease(address_data);
    socklen_t addrlen = sizeof(addr);
    int res = getsockname(CFSocketGetNative(fdvendor),(struct sockaddr *)&addr,&addrlen);
    assert(res == 0);
    port = ntohs(addr.sin_port);
    
    if (port == 0) {
        dsprintf(stderr, "Unable to bind port, exiting\n");
        exit(1);
    }
    NSString *lldbString = [NSString stringWithFormat:@"process connect connect://127.0.0.1:%d", port];
    NSLog(@"%@", lldbString);
    CFRunLoopSourceRef runLoopSourceRef = CFSocketCreateRunLoopSource(NULL, fdvendor, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSourceRef, kCFRunLoopCommonModes);
    
/********************************************************************************
 Source end https://github.com/phonegap/ios-deploy GPL v3 license
********************************************************************************/
    
    // The connection has yet to be established, but everything is good, generate the setup script
    generateSetupScript([appPath UTF8String], port);
    
    system("echo \"lldb -s /tmp/mobdevim_setupscript\" | pbcopy");
    dsprintf(stdout, "Connection setup, paste script: \"%slldb -s %s%s\" (copied to cliboard)\n%sMake sure device is not locked%s\n\n", dcolor("cyan"), [LLDB_SCRIPT_PATH UTF8String], colorEnd(), dcolor("red"), colorEnd());
    
    return 0;
}

