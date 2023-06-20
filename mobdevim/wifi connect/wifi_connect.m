//
//  install_application.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "wifie_connect.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

#define CURRENT_DMG @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/14.2/DeveloperDiskImage.dmg"

#define CURRENT_DMG_SIG @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/14.2/DeveloperDiskImage.dmg.signature"

//#define CURRENT_DMG_SIG @"/Users/lolgrep/Desktop/yolo.sig"
//NSString * const kInstallApplicationPath = @"com.selander.installapplication.path";
//static progressbar *progress = nil;
//


NSString *const kWifiConnectUUID = @"com.selander.wificonnect.uuid";



void image_callback(NSDictionary *progress, id something) {
        
    NSLog(@"%@ %@", something, progress );
    printf("");
}



//void * _runWakeupOperation(void *);
int wifi_connect(AMDeviceRef d, NSDictionary *options) {
 
    NSString *uuid_param = [options objectForKey:kWifiConnectUUID];
    if (uuid_param) {
        CFUUIDRef ref = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef)uuid_param);
        
        NSString *resolved_uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, ref));
        if ([resolved_uuid isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
            derror("Couldn't resolve UUID: \"%s\"\n", uuid_param.UTF8String);
            exit(1);
        }
        uuid_param = resolved_uuid;
    } else {
        uuid_param = GetHostUUID();
    }
    
    if (isWIFIConnected(d, uuid_param)) {
        printf("Already WIFI enabled to %s!\n", uuid_param.UTF8String);
        exit(0);
    }
    
    long flags;
    AMDeviceGetWirelessBuddyFlags(d, &flags);
    AMDeviceSetWirelessBuddyFlags(d, flags | 1);
    
    NSArray *hosts = AMDeviceCopyValue(d, @"com.apple.xcode.developerdomain", @"WirelessHosts", 0);
    if (!hosts) {
        hosts = @[];
    }
    id ret;
    NSString *host = uuid_param;
    if (![hosts containsObject:host]) {
        NSMutableArray *mutableHosts = [hosts mutableCopy];
        [mutableHosts addObject:host];
        ret = AMDeviceSetValue(d, @"com.apple.xcode.developerdomain", @"WirelessHosts", mutableHosts);
    }
    
    ret = AMDeviceSetValue(d, @"com.apple.mobile.wireless_lockdown", @"EnableWifiDebugging", @YES);
    
    printf("Enabled WIFI debugging on host \"%s\"\n", host.UTF8String);
    return 0;
//    char *buffer = malloc(0x14uLL);
//    CC_SHA1_CTX context = {};
//    CC_SHA1_Init(&context);
////    CC_SHA384_Init(&context);
//    NSData *bufferData = nil;
//    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:CURRENT_DMG];
//    do {
//        bufferData = [handle readDataOfLength:1024LL];
//        CC_SHA1_Update(&context, [bufferData bytes], [bufferData length]);
//    } while ([bufferData length]);
//
//    CC_SHA1_Final(buffer, &context);
//    NSData *realizedBuffer = [NSData dataWithBytes:buffer length:20LL];
//    free(buffer);
//
//    long h = AMDeviceUnmountImage(d, @"/Developer");
////
//    char *umountError = AMDErrorString(h);
//    if (h == 0x00000000e8003ffe) {
//        printf("There's no mount for /Developer");
//    }
//    if (h == 0) {
//        printf("unmount success!\n");
//        sleep(3);
//    }
//////    return 0;
////    return 1;
//
//    NSError *err = nil;
//    NSError *f = nil;
//    NSDictionary *outDictionary = @{};
//    long token = AMDeviceCreateWakeupToken(d, @{}, &outDictionary, &f);
//
//
////    _runWakeupOperation((__bridge void *)(outDictionary[@""]));
//    long jj = AMDeviceWakeupUsingToken(outDictionary, d);
    
//    CFRunLoopRun();

////    NSString *signaturePath = [CURRENT_DMG  stringByAppendingPathExtension:@"signature"];
//    NSData *data = [NSData dataWithContentsOfFile:CURRENT_DMG_SIG options:NSDataReadingMappedIfSafe error:&err];
//    if (err) {
//        NSLog(@"%@", err);
//    }
//
////    NSDictionary *op = @{@"ImageSignature" :  data, @"ImageType": @"Personalized", @"ImageInfoPlist" : data, @"ImageDigest" : data};
//    // MountPath
//    /*
//     v20 = v19;
//     if ( (unsigned __int64)objc_msgSend(v19, "hasPrefix:", CFSTR("/private/var/personalized_automation")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/private/var/personalized_debug")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/Developer")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/private/var/personalized_demo")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/private/var/personalized_factory")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/Developer")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/System/Developer")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/private/var/run/com.apple.security.cryptexd/mnt")) & 1
//       || (unsigned __int64)objc_msgSend(v20, "hasPrefix:", CFSTR("/System/Volumes/FieldService")) & 1 )
//     */
//    NSDictionary *op = @{@"ImageSignature" :  data, @"ImageType": @"Developer", @"DiskImage" : @"/Developer"};
//    void* suc = AMDeviceMountImage(d, CURRENT_DMG, op, image_callback, @"hello world", &err);
//    AMDeviceStopSession(d);
//    char *r = AMDErrorString(suc);
//
//
//    if (err) {
//        NSLog(@"%@", err);
//    }
//
//
//    printf("hi");
    
    return 0;
}
