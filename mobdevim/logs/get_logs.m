//
//  send_files.m
//  mobdevim
//
//  Created by Derek Selander on 12/4/17.
//  Copyright © 2017 Selander. All rights reserved.
//

#import "send_files.h"

NSString * const kGetLogsFilePath = @"com.selander.get_logs.sendfilepath";

NSString * const kGetLogsAppBundle = @"com.selander.get_logs.appbundle";

int get_logs(AMDeviceRef d, NSDictionary *options) {
    
//    NSString *writingFromDirectory = [options objectForKey:kSendFilePath];
//    if ([writingFromDirectory hasSuffix:@"xcappdata"]) {
//        writingFromDirectory = [writingFromDirectory stringByAppendingPathComponent:@"AppData"];
//    }
//
//    NSURL *localFileURL = [NSURL fileURLWithPath:writingFromDirectory];
//    if (!localFileURL) {
//        dsprintf(stderr, "Couldn't find directory \"%s\"\nExiting", [[localFileURL description] UTF8String]);
//        return EACCES;
//    }
//
//    NSFileManager* manager = [NSFileManager defaultManager];
//
//    NSDirectoryEnumerator *dirEnumerator = [manager enumeratorAtURL:localFileURL includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
//
//
//        if (error) {
//            dsprintf(stderr, "Couldn't enumerate directory\n%s", [[error localizedDescription] UTF8String]);
//            exit(EACCES);
//        }
//
//        return YES;
//    }];
    
    // At this point, we are good on the local OS X, search for appID now
    
//    NSDictionary *dict;
//    NSString *appBundle = [options objectForKey:kSendAppBundle];
//    NSDictionary *opts = @{ @"ApplicationType" : @"Any",
//                            @"ReturnAttributes" : @[@"ApplicationDSID",
//                                                    @"ApplicationType",
//                                                    @"CFBundleDisplayName",
//                                                    @"CFBundleExecutable",
//                                                    @"CFBundleIdentifier",
//                                                    @"CFBundleName",
//                                                    @"CFBundleShortVersionString",
//                                                    @"CFBundleVersion",
//                                                    @"Container",
//                                                    @"Entitlements",
//                                                    @"EnvironmentVariables",
//                                                    @"MinimumOSVersion",
//                                                    @"Path",
//                                                    @"ProfileValidated",
//                                                    @"SBAppTags",
//                                                    @"SignerIdentity",
//                                                    @"UIDeviceFamily",
//                                                    @"UIRequiredDeviceCapabilities"]};
    
//    AMDeviceLookupApplications(d, opts, &dict);
//    NSString *appPath = [[dict objectForKey:appBundle] objectForKey:@"Path"];
//    
//    if (!appPath) {
//        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor("yellow"), [appBundle UTF8String], colorEnd(), dcolor("bold"), colorEnd());
//        return 1;
//    }
    
    AMDServiceConnectionRef serviceConnection = nil;
    NSDictionary *inputDict = @{@"CloseOnInvalidate" : @NO, @"UnlockEscrowBag": @YES};
    AMDeviceSecureStartService(d, @"com.apple.crashreportmover", inputDict, &serviceConnection);
    if (!serviceConnection) {
        return EACCES;
    }
    
//    NSDictionary *inputDictionary = @{ @"Command" : @"VendContainer", @"Identifier" : appBundle };
//    if (AMDServiceConnectionSendMessage(serviceConnection, inputDictionary, kCFPropertyListXMLFormat_v1_0)) {
//        return EACCES;
//    }
    
    void *info = nil;
//    AMDServiceConnectionReceiveMessage(serviceConnection, &info, nil);
    if (AMDServiceConnectionReceive(serviceConnection, &info, 5) <= 4) {
        return EACCES;
    }
    assert(strcmp("ping", (char *)&info) == 0);
    AMDServiceConnectionInvalidate(serviceConnection);
    serviceConnection = nil;
    // if we got the ping, we're all good, start querying crash logs

    
    AMDeviceSecureStartService(d, @"com.apple.crashreportcopymobile", inputDict, &serviceConnection);
    if (!serviceConnection) {
        return EACCES;
    }
    long socket = AMDServiceConnectionGetSocket(serviceConnection);
    id context = AMDServiceConnectionGetSecureIOContext(serviceConnection);
    if (context) {
        // TODO Implement this if it's ever valid
        assert(0);
    }
    
    AFCConnectionRef connectionRef = AFCConnectionCreate(0, (int)socket, 1, 0, 0);
    if (!connectionRef) {
        dsprintf(stderr, "%sCould not obtain a valid connection. Aborting%s\n", dcolor("yellow"), colorEnd());
        return EACCES;
    }
    
    
//    uint8_t *buffer = malloc(0x1000);
//    id a = [dirEnumerator fileAttributes];
    
//    for (NSURL *fileURL in [dirEnumerator fileAttributes]) {
//
//        NSString *basePath = [NSString stringWithUTF8String:[fileURL fileSystemRepresentation]];
//        NSRange range = [basePath rangeOfString:writingFromDirectory];
//
////        NSInteger location = range.location;
//        range.location = range.length;
//        range.length = [basePath length] - range.location;
//        assert(range.length != 0);
//
//        NSString *remotePath = [basePath substringWithRange:range];
//
//        NSInputStream *stream = [NSInputStream inputStreamWithURL:fileURL];
//        if (!stream) {
//            dsprintf(stderr, "Invalid directory to write from: %s\n", [fileURL fileSystemRepresentation]);
//            return EACCES;
//        }
//
//
        AFCFileDescriptorRef fileDescriptor = NULL;
//
//        [@"hi" containsString:@"Low"];
//        AFCFileRefOpen(connectionRef, [remotePath fileSystemRepresentation], 0x3, &fileDescriptor);
//
//        if (!fileDescriptor) {
//            dsprintf(stderr, "Couldn't open file \"%s\" on the device side\n", [remotePath fileSystemRepresentation]);
//        }
//
//        uint32_t bytesWritten = (uint32_t)[stream read:buffer maxLength:0x1000];
//
//        while(bytesWritten) {
//            AFCFileRefWrite(connectionRef, fileDescriptor, buffer, bytesWritten);
//            bytesWritten = (uint32_t)[stream read:buffer maxLength:0x1000];
//        }
//        AFCFileRefClose(connectionRef, fileDescriptor);
//
//    }
//    free(buffer);

    
    return 0;
}
