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

#define LLDB_SETUP_FILE "/tmp/ds_lldbinit_setup"
#define LLDB_SETUP_CONTENT "# "

int debug_application(AMDeviceRef d, NSDictionary* options) {
  
  NSDictionary *dict = nil;
  AMDeviceLookupApplications(d, @{@"ReturnAttributes": @[@"ProfileValidated", @"CFBundleIdentifier", @"Path"], @"ShowLaunchProhibitedApps" : @YES}, &dict);
  AMDServiceConnectionRef connection = NULL;
  NSDictionary *params = @{@"CloseOnInvalidate" : @YES, @"InvalidateOnDetach" : @YES};
  AMDeviceSecureStartService(d, @"com.apple.debugserver", params, &connection);
  int socket = (int)AMDServiceConnectionGetSocket(connection);
  
  void * handle = dlopen("/Applications/Xcode.app/Contents/SharedFrameworks/LLDBRPC.framework/Versions/A/LLDBRPC", RTLD_NOW);

  void *socketHandle = NULL;
  int (*ConnectToRPCServer)(void *, const char *) = dlsym(handle, "_ZN3rpc10Connection18ConnectToRPCServerEPKc");
  int (*SendFileDescriptor)(void *, int) = dlsym(handle, "_ZNK3rpc10Connection18SendFileDescriptorEi");
  assert(ConnectToRPCServer && SendFileDescriptor);
  
  NSString* xcodePath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Xcode"];
  if (!xcodePath) {
    dsprintf(stderr, "Make sure Xcode is installed to debug, use \"xcode-select -p\" to verify");
    exit(1);
  }
  xcodePath = [xcodePath stringByAppendingPathComponent:@"Contents/SharedFrameworks"];
  
  ConnectToRPCServer(&socketHandle, [xcodePath UTF8String]);
  int remoteFD = SendFileDescriptor(&socketHandle, socket);
  
  printf("fd://%d, socket %d", remoteFD, socket);
//  write(remoteFD, <#const void *__buf#>, <#size_t __nbyte#>)
  CFRunLoopRun();

  return 0;
}
